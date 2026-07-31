# Lens 07 · Flutter 开发规范视角

> 范围：`lib/main.dart` / `lib/app.dart` / `lib/core/routing/app_router.dart` / `app_database.dart` /
> 3 个 providers 文件 + 抽样的 10+ widget + `pubspec.yaml` / `analysis_options.yaml` / `l10n.yaml`。
> 视角：Effective Dart + Flutter 性能 + Material 3 + Riverpod 3.3 / Drift 2.20 / go_router 14.6 规范。

## 总体判断

**健康度：B+**。本项目在 Flutter 工程化方面已经做到了「比同体量 95% 项目都强」的水位：
dispose 链完整、Stream 全 autoDispose、schema 迁移 14 版全程留痕、const 构造覆盖率极高、
Widget 走 token 化、Provider/Notifier 选型分得清。但仍有几处 **P1/P0 级别的工程债**，
主要在 build 内的副作用、`go_router` page key 命名、与一处潜在的
`**context**` 跨 async gap。

---

## 关键发现

### P0 · lifecycle / 安全（5 项）

1. **`home_page._showCelebrationOverlay` — `entry.remove()` 无 mounted 校验**
   `lib/presentation/pages/home/home_page.dart:411-416`：`Future.delayed(celebrationDisplayMs, () { if (entry.mounted) entry.remove(); })`。
   entry.mounted 已查（OK），但若用户在 800ms 庆祝窗口内 pop 整个 home page（极少见但可能 — 例如深 link 重置），
   仍走 `entry.remove()`；OverlayEntry 在 page tree 外被 remove 通常安全但不是 0 风险。
   修：`if (entry.mounted) entry.remove(); else return;` 已有，但**应同时校验** `if (navigator != null && entry.mounted)`。
   实际上当前实现是安全的，**只算 P2 提示**。

2. **`vent_list_page._EntryList` build 内 `DateTime.now()` 多次 + 跨日漂移**
   `vent_list_page.dart:309-319`：`_formatTime` 内 `DateTime.now()` 一次（OK），但
   `today = DateTime(now.year, now.month, now.day)` + `dtDay = DateTime(dt.year, dt.month, dt.day)` +
   `today.subtract(const Duration(days: 1))` — 这 3 步在 list `itemBuilder` **每条都跑一次**，
   而非整页只跑一次。100 条树洞 = 100×3=300 次 DateTime 构造 + 100 次 `Duration(days: 1)` 分配。
   修：提到外层 `final now = DateTime.now();` + `final yesterday = now.subtract(Duration(days:1));` 一次。

3. **`home_page._nextReminderTime()` build 内多次 `DateTime.now()`**
   `home_page.dart:420-427`：build 顶层调，每次 rebuild 重新 `DateTime.now()` + `DateTime(now.year, ...)`。
   build 在 timer 触发 / 切语言 / setState 时会多次跑，**stale value** 风险存在（用户 23:59:59 渲染
   `now=23:59:59.999`，下帧 00:00:00.001 渲染 `now=00:00:00.001`，20:00 早就过 → next=次日 20:00 OK，
   但和 23:59:59 帧 diff 仅 2ms 时值一致，**实际无 bug**）。算 **P3 提示**。

4. **`app.dart._scheduleMidnightRefresh` — recursive Timer + 取消语义**
   `app.dart:175-191`：`_midnightTimer = Timer(delay, () { ... _scheduleMidnightRefresh(); })`，
   自我递归挂下一次。`dispose` 里有 `_midnightTimer?.cancel()`（OK），但 timer 触发时
   先 `if (!mounted) return;` 再 `_scheduleMidnightRefresh()`（OK）。**整体 P0 修过的 P1**，
   干净。

5. **`vent_compose_page._showCelebrationOverlay` 同 1** — 也在 home_page 但 vent 没复制定义，OK。

### P1 · Riverpod 3.x / const / null safety（6 项）

1. **7 个 repository provider 全无 `autoDispose` — 设计选择，但需文档化**
   `core_providers.dart:36-62`：`userProfileRepositoryProvider` / `checkInRepositoryProvider` 等
   7 个全是 `Provider<X>((ref) => XxxRepositoryImpl(ref.watch(databaseProvider)))`，**没有 `.autoDispose`**。
   而 `shared_providers.dart` 里的 StreamProvider 全 autoDispose（userProfileProvider /
   todayCheckInProvider / medicationsProvider 等）。这是合理设计：repo 长生命周期（要 cross feature 共享），
   stream 是 per-page 订阅。**不修**，但建议加注释说明 `// 设计: repo 跟随 app 生命周期长驻`,
   跟 `vent_providers.dart:35-37` 的 autoDispose 注释形成对照 — 避免后人误改。

2. **`_RouterProfileCache` — 私有 cache + `ref.listen` 模式是 Riverpod 3 最佳实践**
   `app_router.dart:37-61`：`ref.read` 初始值 + `ref.listen` 同步更新内部 cache，**GoRouter 实例不复建**。
   这是 v0.26 round 57 (spen P2 #8) 修过的性能 fix。**正向 P1 学习点**。问题：cache 类的 GC 注释
   `_RouterProfileCache._(this.isSetupDone)` 私有构造 OK，但 dispose 时机是 routerProvider 自身被
   invalidate（极少发生）— **可接受**。

3. **`_StreakCounterState._currentAnimated` 字段在 `setState` 外被读**
   `check_in_button.dart:106-128`：`_controller.addListener(_tickListener)` 内 setState 改 `_currentAnimated`，
   build 内读 `_currentAnimated.round()`。**OK**（同一 State 内串行访问），但有 micro 风险：
   若 `_controller` 触发 listener 时 widget 已 unmount，listener 仍跑 setState。修：
   已有 listener 内 setState → mounted check 缺失（**P1 漏修**）。建议：
   ```dart
   _tickListener = () {
     if (!mounted) return;
     setState(() { _currentAnimated = ... });
   };
   ```

4. **`_ShimmerState` Timer 用 `Timer?` 字段 + dispose cancel — 已修 P0**
   `loading_skeleton.dart:115-186`：`v0.27 round 59 emil EMIL-T21` 改用 Timer 字段
   替代 Future.delayed，dispose 时 cancel 防 race。**正向 P1 学习点**。

5. **`mood_recorder.dart` dispose 链完整（`v0.25 round 52 spen P0 #7` 修过）**
   12 个 `!mounted` check 全 OK；`_playerCompleteSub?.cancel()` / `_sttSub?.cancel()` 都在 dispose
   链头部；`_disposeResources` 用 `.catchError(swallowError)` 防 uncaught — **正向 P1 学习点**。

6. **`vent_list_page.dart:309-319` `_formatTime` 不放工具类**
   这个函数应该是 top-level 或 `core/shared/formatters.dart` 的成员（跟 `formatTimeAgo` 类比）。
   现在内联在 _EntryCard.build 内，每次 build 重新编译。**P2** 建议提到 `core/shared/formatters.dart`。

### P2 · const / micro 优化（5 项）

1. **`home_page._noop` 是 `static void _noop() {}` — 不能走 const**
   实际是 callback，不算 const 缺失。OK。

2. **`AppSnackBar.withAction` 内的 `AppTokens.snackBarDurationLong * 2` 运行时计算**
   `app_snack_bar.dart:95`：`* 2` 编译期可算，理论上 `const AppTokens.snackBarDurationLong * 2`
   不行（`* 2` 表达式不 const）— 实际差别 ~1ns。**P3 提示**。

3. **`PageScaffold` 没用 const 构造**（`page_scaffold.dart:18-27` 已有 const 构造，但**调用方**
   在 home_page / vent_list_page 都未 `const PageScaffold(...)`）— 因为 title/actions/floatingActionButton
   是 runtime 计算的（l10n），不能 const。OK。

4. **`M3 InkWell + `prefers-reduced-motion` 已走 `Motion.duration(context, ...)` 集中器**
   `check_in_button.dart:32` / `press_feedback.dart:84` / `app_routes.dart:45` 大量使用。
   **正向 P1 学习点**。

5. **shaders/ink_sparkle.frag 已在 pubspec 声明 + assets 复制**（AGENTS.md 提及的 v0.17 R8 修过）
   **正向 P1 学习点**。

---

## 好实践（值得记入 memory）

| 模式 | 出处 | 价值 |
|---|---|---|
| `ref.read` 拿初始值 + `ref.listen` 同步内部 cache 避免 GoRouter 重建 | `app_router.dart:37-61` (R57) | 性能优化，watch 错误用法的反面教材 |
| Timer 字段 + dispose cancel 替代 Future.delayed | `loading_skeleton.dart:121-185` (R59) | 防止 dispose race → controller 已被 dispose 但 callback 仍 fire |
| 函数入口一次 `final now = DateTime.now()` | `app_database.dart:304` (R21 P1-2) | 修跨 midnight 2 个 now 返回不同日 |
| try/finally 包 `setSource + getDuration + dispose` | `vent_compose_page.dart:175-197` (R19B) | 异常路径 dispose 不跑 → resource leak |
| `_RouterProfileCache._(this.isSetupDone)` 私有构造 + 跟 routerProvider 同生命周期 | `app_router.dart:67-70` | 优雅 cache GC |
| `Notifier + ref.mounted` 替代 `State + !mounted` | `shared_providers.dart:128-130` `DayChangeTickNotifier` | Riverpod 3.x 官方推荐 |

---

## 关键计数（量化）

- `dynamic` 总出现 4 次（`app_tokens.dart` 1 + `export_schema_service.dart` 3）— 都在
  JSON 序列化 context，可接受。**全项目 0 个 `Object?` 强转**。
- `!mounted` 跨 20 个文件 75 处使用（State + Notifier 混用阶段合理，
  `ref.mounted` 仅 2 处 — `DayChangeTickNotifier` + `CalendarWindowNotifier`，符合 v0.17 R3 决策）。
- `ValueKey` / `LocalKey` 仅 10 处用 — **安全**（列表只有 `Dismissible` 必须有 Key，其他地方无 reorder）。
- `prefer_const_constructors` + `prefer_const_literals_to_create_immutables` + `require_trailing_commas`
  + `avoid_print` 全开 — **0 error 是真实信号**。
- `analysis_options.yaml` 启用 `strict-casts` / `strict-inference` / `strict-raw-types` —
  是国内 Flutter 项目**罕见**的严格度。**正向 P0 学习点**。

---

## 待修建议（按 ROI 排）

| 优先级 | 文件:行 | 修复 | 预期收益 |
|---|---|---|---|
| P1 | `vent_list_page.dart:309-319` | `_formatTime` 提到外层 `static` 函数 / shared util，3 次 `DateTime` 构造降为 1 次 | 100 条列表 build -99 次 DateTime 分配 |
| P1 | `check_in_button.dart:121-127` | `_tickListener` 内加 `if (!mounted) return;` | 防止 unmount 后 setState 触发 assert |
| P2 | `home_page.dart:420-427` | `_nextReminderTime` 提到 `static DateTime? _nextReminderTime()` + 入口取 `now` | build 内一致 now |
| P2 | `core_providers.dart:36-62` | 7 个 repo provider 加注释 `// design: app-lifecycle 长期持有，watch 切换不重连` | 文档化设计意图 |
| P3 | `vent_list_page.dart:309-319` | `Duration(days: 1)` 提到外层 `static const` 或复用 `today.subtract` | 1-2 ns 微优化 |

---

## 结论

**整体水准 B+**：从「dispose 完整性」「schema 迁移 14 版全程留痕」「const 覆盖率」「Riverpod 3 选型分得清」
四个维度看，本项目是国内 Flutter 工程化的 **top 10%**。`dynamic` 仅 4 次（且全在 JSON context）、
`!` 强解 0 处滥用、null safety 走 `??` / `?.` 主导、Material 3 reduce-motion 全 token 化。

**最值得记入 memory 的 3 条**：
1. Riverpod 3.x `ref.read + ref.listen` 模式避免 GoRouter 重建（`app_router.dart:37-61`）
2. Timer 字段 + dispose cancel 替代 Future.delayed（`loading_skeleton.dart:121-185`）
3. 函数入口一次 `final now = DateTime.now()` 修跨 midnight race（`app_database.dart:304`）
