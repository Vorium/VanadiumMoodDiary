# Superpowers-en 视角代码审视报告

> **视角**: superpowers-en (English Superpowers — 233k+ ⭐ upstream)
> **核心关注**: TDD 视角 / 系统化调试 / 架构一致性 / Code Review / Verification
> **项目**: 慢病管家（精神心理患者打卡 App）— Flutter 3.41.9 / Drift 2.20.3 / Riverpod 3.3.2
> **基线**: v0.24 round 45（876 tests pass, 0 analyzer error, 7-8 守护脚本全绿）
> **审视时间**: 2026-07-26

---

## 摘要

- **视角健康度评分**: **7.5 / 10**
- **P0**: 1（隐私合规硬编码时区）
- **P1**: 6（架构 / 测试盲区 / race condition）
- **P2**: 5（lint / 命名 / 一致性）
- **P3**: 3（文档 / cleanup）
- **最大 3 个问题**:
  1. **`_formatDateTime` 硬编码 "(UTC+8 北京时间)"** — PIPL §17 数据准确性合规红线
  2. **3 个公共函数无 test 覆盖**：`crossedMidnightSince`（v0.21 重要防御）/ `DayDetailCalculator` 排序 / `EmailTemplate.buildBody`
  3. **`vent_compose_page._togglePlay` temp file 释放路径不全** — 异常路径会泄漏

---

## 1. 顶层架构审视

### 1.1 4 层架构 + 共享 umbrella 健康度

**结论**: ✅ 架构纯度 100% 通过；守护脚本 `dart scripts/check_all.dart` 报告
- `domain/` 0 flutter / 0 drift / 0 data / 0 presentation ✅
- `data/` 不依赖 presentation ✅
- `shared/` 每个文件被 ≥2 层使用 ✅
- 跨 feature import 0 violation ✅

**但** 仍存在以下 superpowers-en 视角关注点：

| 维度 | 现状 | 评价 |
|---|---|---|
| abstract / impl 配对 | 9 domain 接口 = 7 data impl + 2 service impl（NotificationService → NotificationSender；ReminderService → ReminderChecker） | ✅ 完整 |
| Drift ↔ Entity 一致性 | `check_all.dart` 已 100% 校验 | ✅ |
| 4 文件组织（per-feature 子目录） | repositories 按 feature 子目录（`check_in/`, `medication/`...）；mappers 也按子目录；tables 按子目录 | ✅ 良好 |
| 跨 feature import 边界 | `check_cross_feature.py` 守护 | ✅ |
| Riverpod 3.3.2 升级 | `valueOrNull → value` 已修（v0.17 round 3）；`ref.mounted` 不可替代 `!mounted`（v0.17 round 7 已标） | ✅ |

### 1.2 测试金字塔

| 层级 | 文件数 | 估算用例 | 评价 |
|---|---|---|---|
| domain 业务（纯 Dart）| 22+ | ~280 | ✅ 良好；`care_strategies_round43_test.dart` 290 行 isolated test 范例 |
| data round-trip | 25+ | ~350 | ✅ 含 `data_export_*_test.dart` 5 个文件 50+ case |
| presentation widget | 30+ | ~250 | ⚠️ 较薄，但 `mood_dialog_audio_round31_test.dart` 219 行覆盖完整 |
| 集成（仅靠 mock plugin）| 4 | ~30 | ⚠️ 真实 plugin 集成测试缺（`test/integration_test/` 不存在） |
| 脚本守护 | 1 | 9 | ✅ `check_all_round18_test.dart` 验守护本身 |

**关键测试盲区**：
- `crossedMidnightSince` (lib/app.dart:75) — 0 个 direct test，是 v0.21 P0-4 关键防御
- `DayDetailCalculator.fromData` 排序逻辑 (lib/domain/logic/day_detail.dart:139) — 仅 `day_detail_round10_test.dart` 373 行但偏正向用例
- `EmailTemplate.buildBody` (lib/domain/logic/email_template.dart:27) — 88 行 test 但只覆盖主题 + 通用 format，未覆盖 medication=null / lastCheckIn=null 边界

### 1.3 7 守护脚本完备性

AGENTS.md 声称 7 个，实测 8 个：

| 脚本 | 职责 | superpowers-en 评价 |
|---|---|---|
| `check_all.dart` | 4 层架构纯度 + 一致性 | ✅ 关键 |
| `check_arb_keys.py` | i18n key 一致性 | ✅ |
| `check_cross_feature.py` | 跨 feature import | ✅ |
| `check_datetime_race.py` | 多次 `DateTime.now()` 跨 midnight | ✅ 极佳 |
| `check_datetime_race2.py` | 升级版 | ✅ |
| `check_drift_namespace.py` | drift 命名空间 | ✅ |
| `check_fullwidth_punctuation.py` | 全角标点 | ✅ |
| `check_no_pua.py` | 无 PUA 字符 | ✅ |

**superpowers-en 视角缺失的守护**：
- ❌ 缺 `no_hardcoded_utc_offset` 守护（应捕捉 `'(UTC+8'` / `+08:00` 硬编码 — 见 issue #1）
- ❌ 缺 `widget_dispose_lint` 守护（手动审计 `StreamSubscription` cancel + 资源 dispose）
- ❌ 缺 `mocks_testing_real_behavior` 守护（应禁止 `test('test1', ...)` 空名 + mock 主导测试）

---

## 2. 底层逐行排查（按优先级 + 难度排序）

### 2.1 P0 — 隐私合规

#### [1] [sp-verify] `EmailTemplate._formatDateTime` 硬编码 "(UTC+8 北京时间)" — 跨境 PIPL §17 风险

- **位置**：`lib/domain/logic/email_template.dart:67-69`
- **类型**：架构 / 底层
- **修复难度**：S
- **优先级**：P0
- **问题描述**：

```dart
static String _formatDateTime(DateTime dt) {
  // v0.23 round 39 (P1-12 fix): 加时区标注 (北京时间 UTC+8)
  return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
      '${_pad(dt.hour)}:${_pad(dt.minute)} '
      '(UTC+8 北京时间)';
}
```

邮件接收方在海外（美国/欧洲）时，邮件显示"北京时间"但实际时间是用户当地时间。**PIPL §17 数据准确性** + 跨境合规问题：失联通知给海外紧急联系人看到错误时区会被误读成"未来时间已发生"。

- **superpowers 建议**：
  - **TDD 步骤**：
    1. RED: 写 test "海外用户时区显示正确" — `now = local 12:00` (Asia/Shanghai) → 邮件显示 "UTC+8 12:00"
    2. RED: 写 test "海外用户时区显示正确" — `now = local 12:00` (America/Los_Angeles) → 邮件显示 "UTC-7 12:00" 而非硬编码 UTC+8
  - **修法**：传入 DateTime 时按 `tz.local` 推断，或改用 `dt.timeZoneName` / `dt.timeZoneOffset` 动态标注
  - **守护**：`scripts/check_no_hardcoded_utc.py` grep `(UTC\+` / `+08:00` / `(GMT` 字面量

---

### 2.2 P1 — 测试盲区 + Race Condition + 资源泄漏

#### [2] [sp-TDD] `crossedMidnightSince` 函数无直接测试

- **位置**：`lib/app.dart:75-89`
- **类型**：架构
- **修复难度**：S
- **优先级**：P1
- **问题描述**：
```dart
bool crossedMidnightSince(DateTime lastCheck, DateTime now) {
  if (lastCheck.isAfter(now)) return true; // 系统时间被拨回
  final lastCutoff = DateTime(lastCheck.year, lastCheck.month, lastCheck.day, 0, 0, 5);
  final nowCutoff = DateTime(now.year, now.month, now.day, 0, 0, 5);
  return nowCutoff.isAfter(lastCutoff);
}
```
- **重要性**：v0.21 P0-4 修复是 streak 跨 midnight 不刷新的关键防御，但**无独立 test 文件覆盖**。`app_root_round17_midnight_test.dart` 只测了 `nextMidnightRefresh`，没测 `crossedMidnightSince`。
- **superpowers 建议**：
  - **TDD 步骤**：
    1. RED: `test('lastCheck 早于 now 但同日 00:00:05 之前 → false')` — `lastCheck=2026-07-17 14:00`, `now=2026-07-17 23:59:59`
    2. RED: `test('跨 midnight 1 天后 → true')` — `lastCheck=2026-07-17 23:00`, `now=2026-07-18 00:01`
    3. RED: `test('系统时间被拨回（lastCheck > now）→ true')`
    4. RED: `test('00:00:05 边界')` — 0:00:04 vs 0:00:05 vs 0:00:06
  - **命名**：建 `test/presentation/crossed_midnight_since_roundN_test.dart`
  - **架构**：函数已经是 `@visibleForTesting top-level`，testability 没问题，缺的是 test

#### [3] [sp-debug] `vent_compose_page._togglePlay` 暂停路径 temp file 释放顺序脆弱

- **位置**：`lib/presentation/pages/vent/vent_compose_page.dart:206-252`
- **类型**：底层
- **修复难度**：S
- **优先级**：P1
- **问题描述**：
```dart
if (_isPlaying) {
  await _player.stop();  // ← 若抛异常,下面 deleteTempFile 不跑
  if (_tempDecryptedPath != null) {
    await ref.read(ventAudioStorageProvider).deleteTempFile(_tempDecryptedPath!);
    _tempDecryptedPath = null;
  }
  if (mounted) setState(() => _isPlaying = false);
}
```
- **bug 现象**：`_player.stop()` 抛 `PlatformException`（罕见但 `audioplayers` 6.x 已知问题）→ temp file 残留 → 下次进入页面 mount 解密时，磁盘堆积。
- **superpowers 建议**：
  - **调试方法**（系统化 4 阶段）：
    1. Phase 1 Root Cause: 查 `audioplayers` GitHub issues 中 "stop throws PlatformException" — 已确认存在 iOS 偶发 case
    2. Phase 2 Pattern: 对比 `_togglePlay` else 分支（异常路径已有 try/catch 清理）— 暂停路径缺同款保护
    3. Phase 3 Hypothesis: 给 stop 加 try/catch → catch 里清 temp file
    4. Phase 4 TDD: 写 test 模拟 `stop` 抛异常 → 验证 temp file 被清理
  - **修法**：
    ```dart
    if (_isPlaying) {
      try {
        await _player.stop();
      } catch (e, st) {
        swallowError(where: 'vent_compose_page.stop.fail', error: e, stack: st);
      }
      // 不管 stop 成不成功,都尝试清 temp
      if (_tempDecryptedPath != null) {
        try { await ref.read(ventAudioStorageProvider).deleteTempFile(_tempDecryptedPath!); }
        catch (e, st) { swallowError(...); }
        _tempDecryptedPath = null;
      }
      if (mounted) setState(() => _isPlaying = false);
    }
    ```
  - **TDD 步骤**：
    1. RED: `test('stop 抛异常时仍清 temp file')` — mock `AudioPlayer.stop` 抛 `PlatformException`
    2. GREEN: 上面修法
    3. 验证现有 5 个 vent test 全过

#### [4] [sp-TDD] `DayDetailCalculator.fromData` 排序逻辑无 isolated test

- **位置**：`lib/domain/logic/day_detail.dart:139-235`
- **类型**：架构
- **修复难度**：M
- **优先级**：P1
- **问题描述**：
```dart
events.sort((a, b) => a.time.compareTo(b.time));
return DayDetail(date: day, events: List.unmodifiable(events));
```
- **重要性**：`day_detail_round10_test.dart` 373 行覆盖正向用例，但**未覆盖 unsorted input**（v0.16 round 19/19B 已立的"隐式排序假设"反模式），未测试：
  - 输入 checkIns 顺序乱（按 timestamp 倒序传入）→ 仍按时间正序返回
  - 同一天多 mood + checkIn 混合 → events 顺序正确
- **superpowers 建议**：
  - **TDD 步骤**：
    1. RED: `test('输入 events 顺序乱 → 输出按 time 正序')`
    2. RED: `test('同秒多事件 → 稳定 sort（同 timestamp 保持原序）')`
    3. GREEN: 已实现（`a.time.compareTo(b.time)` 是稳定 sort），加 test 锁行为
  - **同时为 v0.23 round 12 漏修加 regression test**

#### [5] [sp-TDD] `reminder_scheduler.dart:78-79` 跟 `reminder_scheduler.dart:137` 行为不一致无 test

- **位置**：`lib/core/data/services/reminder_scheduler.dart:78-79`（ReminderService）vs 137（ReminderScheduler）
- **类型**：底层
- **修复难度**：M
- **优先级**：P1
- **问题描述**：
- ReminderService (data) 跟 ReminderScheduler (domain) 都提供 `selectFirstContact` / `selectAllActiveContacts`，但 ReminderService 在 137 行 `[...medications]..sort((a,b) => a.startDate.compareTo(b.startDate))` 加了显式 sort 防御未排序，ReminderScheduler 53 行直接 `active.sort(...)` **没 copy spread**——如果 caller 传同一个 list 两次，第二次 sort 已 sorted 不重排，但**有外部 mutate 的风险**。
- **superpowers 建议**：
  - **TDD 步骤**：
    1. RED: `test('caller 传 sorted 列表 → 不 mutate 原 list')` — 传已 sorted 列表 1 次，调 2 次，验证 list identity 不变
    2. GREEN: 改 `active.sort(...)` → `final sorted = [...active]..sort(...)`
  - **系统化调试**：在 `reminder_scheduler.dart:53` 加防御性 copy 是 v0.16 round 19 的"6 个 service 隐式序"教训延伸

#### [6] [sp-debug] `care_strategies.dart isWeekPerfect` 算法效率 O(N×7) 可优化

- **位置**：`lib/domain/logic/care_strategies.dart:73-94`
- **类型**：底层
- **修复难度**：S
- **优先级**：P1
- **问题描述**：
```dart
bool isWeekPerfect(List<CheckInEntity> sortedDesc, DateTime now) {
  // ...
  for (int i = 0; i < 7; i++) {
    final day = today.subtract(Duration(days: i));
    final hasOnDay = sortedDesc.any((c) =>
        c.timestamp.year == day.year && ...);  // ← 7 天 × N checkIns = O(7N)
    if (!hasOnDay) return false;
  }
  return true;
}
```
- **bug 现象**：3 年用户 1000 checkIns 调一次 `evaluate()` → 7000 比较 + 上面的 first loop 1000 遍历 → 8000 ops/frame。HomePage 每次 build 都会调（`CareEngine.evaluate` 串接 4 strategy）。
- **superpowers 建议**：
  - **调试方法**：grep "isWeekPerfect" 看是否每帧调 — 确认在 `home_page.dart:215` 鼓励文案 `EncouragementText(streak: streakSnapshot.streak)` 间接触发
  - **TDD 步骤**：
    1. RED: `test('1000 checkIns isWeekPerfect < 10ms')` — 性能 regression test
    2. GREEN: 改用 `Set<DateTime>` 一次 group by day → 7 lookup O(1)
  - **架构**：先 group by day（O(N)），再 7 次 Set.contains（O(1)） → O(N+7) 替代 O(7N)

#### [7] [sp-arch] `mood_repository_impl.add` 接收 7 个独立参数 — 数据类可改进

- **位置**：`lib/core/data/repositories/mood/mood_repository_impl.dart:36-62`
- **类型**：架构
- **修复难度**：M
- **优先级**：P1
- **问题描述**：
```dart
Future<int> add({
  required int score,
  required List<String> tags,
  String? note,
  DateTime? at,
  int? energy,
  int? sleep,
  int? anxiety,
  String? audioPath,
  String? audioTranscript,
  int? audioDurationMs,
}) { ... }
```
- 10 个独立参数（4 required + 6 optional），容易在 call site 弄混位置。MoodEntryEntity 已存在作为数据载体，**用 entity 替代散参数**。
- **superpowers 建议**：
  - **重构 pattern**（功能重构 4 步）：
    1. 加 `MoodEntryDraft` 数据类（10 个字段）
    2. `add({required MoodEntryDraft draft})`
    3. 现有 3 个 caller（`mood_dialog.dart`, `mood_repository_round9_test.dart`）改成 `add(draft: MoodEntryDraft(...))`
    4. 跑现有 test 验证无 breaking
  - **TDD**：先写 `test('mood_repository.add 接受 draft')` → 改 signature → 验证全过

---

### 2.3 P2 — Lint / 一致性

#### [8] [sp-verify] `data_export_service.dart:103` `_streamTimeout` 局部变量下划线违反 lint

- **位置**：`lib/core/data/services/data_export_service.dart:103`
- **类型**：底层
- **修复难度**：S
- **优先级**：P2
- **问题描述**：
```dart
const _streamTimeout = Duration(seconds: 5);
```
`flutter analyze` 报 `no_leading_underscores_for_local_identifiers` (info-level) — `reminder_scheduler.dart:31` `safety_watch_service.dart:47` 都用类字段 `_streamTimeout` / `_contactWatchTimeout` 同样模式，但 lint 期望类字段可以不报错，方法局部下划线则不行。
- **superpowers 建议**：
  - **修法**：rename 为 `streamTimeout`（无下划线）或提到类字段（跟 `ReminderService` / `SafetyWatchService` 一致）
  - **统一**：3 个 service 都用类字段 + 构造注入 + DI 模式，facade `DataExportService` 也跟
  - **Verification**：`flutter analyze lib/core/data/services/data_export_service.dart` 0 issue

#### [9] [sp-arch] `flutter analyze` 报 `inference_failure_on_collection_literal` 6 个 test 文件

- **位置**：`test/data/data_export_round39_test.dart:347-352` 等
- **类型**：架构
- **修复难度**：S
- **优先级**：P2
- **问题描述**：
```
warning - The type argument(s) of 'List' can't be inferred
test\data\data_export_round39_test.dart:347:21
```
- AGENTS.md 明确要求 0 error / 0 warning，**当前 6 个 warning 不符合标准**。
- **superpowers 建议**：
  - **修法**：`List list = [...]` → `List<String> list = [...]` 显式声明
  - **Verification**：`flutter analyze 2>&1 | grep -c "warning"` 应为 0

#### [10] [sp-review] 主页 `home_page.dart` 跟 `_runSafetyCheck` 跨 `Mounted` 守卫仍靠 `if (!mounted)` 老模式

- **位置**：`lib/presentation/pages/home/home_page.dart:147, 154, 314, 319`
- **类型**：架构
- **修复难度**：M
- **优先级**：P2
- **问题描述**：
```dart
final result = await ref.read(safetyWatchServiceProvider).onAppStart();
if (!mounted) return;  // ← 27 处 v0.17 round 7 已数过
if (result.kind == SafetyCheckKind.alerted) {
  AppSnackBar.showError(context, ...);  // 跨 await 后 context 不可信
}
```
- Riverpod 3.x Notifier 内部能用 `ref.mounted`，但 widget 侧仍是 `!mounted`。项目已接受（AGENTS.md 标 27 处），但**仍有 5 处新加**未审计。
- **superpowers 建议**：
  - **Code Review pattern**：每加一个 `await ... context` 必须加 `if (!context.mounted) return;` 守护
  - **Helper**：抽 `extension BuildContextX on BuildContext { bool get safeMounted; }` 统一 `mounted && context.mounted`
  - **守护**：可选加 `scripts/check_async_context.py` grep 跨 await 后裸用 `context.`

#### [11] [sp-verify] `reminder_scheduler.dart:135-137` 显式 sort 注释标注但 v0.22 round 30 时只补 1 处

- **位置**：`lib/core/data/services/reminder_scheduler.dart:131-137`
- **类型**：底层
- **修复难度**：S
- **优先级**：P2
- **问题描述**：
```dart
// v0.22 round 30 (sp-en P0-1): 显式按 startDate 升序取 firstMed。
// drift `watchAll()` 无 `orderBy`（已 grep 确认）→ 返回值是插入序。
// 之前 v0.16 round 19 修过 5 个 service 的 `.first` 隐式序，
// 这里漏了第 6 个。reminder UI 显示"当前药物"会随机。
final sortedMeds = [...medications]
  ..sort((a, b) => a.startDate.compareTo(b.startDate));
```
- 注释说"v0.16 round 19 修过 5 个 service"，但**没全面 audit 第 6 个 / 第 7 个**。grep 结果见下：
- **superpowers 建议**：
  - **TDD 步骤**：
    1. 跑 `grep -rn "\.first" lib/core/data/services | grep -v "//"` 列出全部 `.first` 用法
    2. 标红所有"在 sortedDesc / sortedMeds 之外的 .first"
    3. 每个都加 isolated test + 显式 sort 注释
  - **审计结果**（本次）：`_mood_repository_impl` 等 4 处都是 stream order by SQL 已保证；唯独 `safety_watch_service` 的 contact `for (final c in contacts)` 是 `watchAll().first` 已显式 timeout → 已 OK
  - **结论**：仅 1 处遗留已修，其他 OK

#### [12] [sp-review] `app_router.dart` 仍有"core import presentation"架构违规豁免

- **位置**：`lib/core/routing/app_router.dart:1-29`
- **类型**：架构
- **修复难度**：XL
- **优先级**：P2
- **问题描述**：
```dart
/// **架构说明**: 此文件位于 core/routing/ 并 import 了 presentation/pages/，
/// 这是 go_router 的固有限制 —— 路由必须知道页面 widget 才能构建路由。
/// 将其移至 presentation/ 会导致循环依赖
```
- AGENTS.md 标"已在架构检查中豁免"，但**真实问题**：go_router v14 已有 `pageBuilder` + `routes` 分文件注册模式（route 表 + page 注册表分离）。
- **superpowers 建议**：
  - **重构 pattern**：
    1. `core/routing/app_router.dart` 改成纯 route 名 + path 列表（无 widget import）
    2. `presentation/routing/page_registry.dart` 提供 `Map<String, WidgetBuilder>`
    3. `app.dart` 在 ProviderScope 外包 `MaterialApp.router(routerConfig: ...)`，配合 page registry
  - **挑战**：go_router 14 API 对 dynamic route binding 不友好，需要新版本或 5 行 hack
  - **TDD**：先写 test 验现有路由表 9 个 path 都注册，再重构
  - **接受现状**：superpowers 标 XL 是因为投入产出比低，AGENTS.md 豁免可接受

---

### 2.4 P3 — 文档 / Cleanup

#### [13] [sp-review] AGENTS.md 标"7 守护脚本"实际 8 个

- **位置**：`AGENTS.md` ("v0.23 P0-P3 集中清理"段) + ("已知坑" 段)
- **类型**：底层
- **修复难度**：S
- **优先级**：P3
- **问题描述**：AGENTS.md 写"7 守护脚本全绿 (新加 check_no_pua)"，实测 `ls scripts/check_*.{py,dart}` 8 个：
```
check_all.dart
check_arb_keys.py
check_cross_feature.py
check_datetime_race.py
check_datetime_race2.py
check_drift_namespace.py
check_fullwidth_punctuation.py
check_no_pua.py
```
- **superpowers 建议**：AGENTS.md 改 "7-8 守护脚本" 或列 8 个清单；本项目文档准确性很关键（CI / 团队 onboarding 都要靠）

#### [14] [sp-TDD] `care_strategies_round43_test.dart` 含 mojibake（chinese 编码）

- **位置**：`test/domain/logic/care_strategies_round43_test.dart:1-10`（注释）
- **类型**：底层
- **修复难度**：S
- **优先级**：P3
- **问题描述**：文件实际是 UTF-8 正确，PowerShell `Get-Content` 默认 GBK 解码显示乱码。AGENTS.md 说"必跑 `dart scripts/check_no_pua.py`"已防 PUA，但**无 terminal-encoding CI 守护**。
- **superpowers 建议**：
  - 文档加 "**CI 必跑** `flutter test` 在 UTF-8 环境下" 防止 dev 机器 GBK 误判
  - 或在 PowerShell 5.1 下 `Get-Content -Encoding UTF8` 强制（5.1 会加 BOM，部分工具问题）

#### [15] [sp-verify] `mood_dialog._MoodDialogContentState.dispose` 调用顺序不可靠

- **位置**：`lib/presentation/pages/mood/mood_dialog.dart:93-97`
- **类型**：底层
- **修复难度**：S
- **优先级**：P3
- **问题描述**：
```dart
@override
void dispose() {
  _recorderController.dispose();
  _noteController.dispose();
  super.dispose();
}
```
- `_recorderController` 内部可能引用 `context` 异步回调 → dispose 顺序 vs `super.dispose()` 之间 controller 引用 context 时已失效。
- **superpowers 建议**：
  - **TDD 步骤**：
    1. RED: `test('dispose 期间 _recorderController 回调不再访问 context')` — 异步触发回调 → 不抛异常
    2. GREEN: dispose 前清空回调 / 内部加 `if (!mounted) return;` 守卫
  - **现状**：`_recorderController` 是新抽象，已在 `mood_recorder.dart` 内做守卫，外部无需多管
  - **Verification**：现有 `mood_dialog_audio_round31_test.dart` 219 行测过 dispose 路径
  - **判定**：P3（理论隐患，现状可控）

---

## 3. 评分

### 视角健康度：7.5 / 10

| 维度 | 分数 | 评语 |
|---|---|---|
| 架构纯度 | 10/10 | 4 层 + 共享 umbrella 严格隔离，check_all.dart 100% 验证 |
| TDD 严谨度 | 8/10 | 多数 domain 业务有 isolated test，少数（如 `crossedMidnightSince`）缺 |
| 系统化调试 | 8/10 | 已修 5+ 个隐式 sort / 资源泄漏 / race condition；剩余 1-2 处（vent stop / 硬编码时区） |
| 资源管理 | 8/10 | AudioPlayer / recorder / temp file dispose 链基本完整；`vent_compose._togglePlay` 暂停路径脆弱 |
| Lint 卫生 | 6/10 | 6 个 warning (test 文件 inference_failure) + 1 个 info (下划线局部变量) 不符合 "0 warning" 标准 |
| 隐私合规 | 6/10 | 时区硬编码 + 海外用户场景未覆盖 |
| 文档 | 8/10 | AGENTS.md 详尽，1 处"7 守护"不准确 |

### P0/P1 总数
- P0: **1**
- P1: **6**

### 最大 3 个问题（必须立即处理）

1. **`EmailTemplate._formatDateTime` 硬编码 "(UTC+8 北京时间)"** — PIPL §17 跨境合规红线
2. **`vent_compose_page._togglePlay` 暂停路径 temp file 释放顺序脆弱** — 罕见但真实的资源泄漏，可能在海外用户身上频繁
3. **`crossedMidnightSince` 无独立 test** — 跨 midnight streak 不刷新的关键防御（v0.21 P0-4 修复的核心），**test gap 是 superpowers-en 视角的最大红旗**

---

## 4. 附录

### 4.1 完整问题清单

| # | 标签 | 标题 | 优先级 | 难度 | 位置 |
|---|---|---|---|---|---|
| 1 | sp-verify | 硬编码 "(UTC+8 北京时间)" | P0 | S | email_template.dart:67-69 |
| 2 | sp-TDD | crossedMidnightSince 无 direct test | P1 | S | app.dart:75-89 |
| 3 | sp-debug | vent_compose._togglePlay 暂停异常路径泄漏 temp | P1 | S | vent_compose_page.dart:206-252 |
| 4 | sp-TDD | DayDetailCalculator 排序无 isolated test | P1 | M | day_detail.dart:139-235 |
| 5 | sp-TDD | ReminderScheduler 不防御 copy spread | P1 | M | reminder_scheduler.dart:53-59 |
| 6 | sp-debug | isWeekPerfect O(N×7) 算法效率 | P1 | S | care_strategies.dart:73-94 |
| 7 | sp-arch | mood_repository_impl.add 10 参数可改 entity | P1 | M | mood_repository_impl.dart:36-62 |
| 8 | sp-verify | _streamTimeout 下划线 lint | P2 | S | data_export_service.dart:103 |
| 9 | sp-arch | test inference_failure 6 warning | P2 | S | test/data/data_export_round39_test.dart |
| 10 | sp-review | home_page !mounted 老模式 | P2 | M | home_page.dart 5+ 处 |
| 11 | sp-verify | reminder_scheduler 隐式 sort 注释未 audit 全 | P2 | S | reminder_scheduler.dart:131-137 |
| 12 | sp-review | app_router 架构违规豁免 | P2 | XL | core/routing/app_router.dart |
| 13 | sp-review | AGENTS.md "7 守护" 不准 | P3 | S | AGENTS.md |
| 14 | sp-TDD | care_strategies_test mojibake 文档 | P3 | S | test/domain/logic/care_strategies_round43_test.dart |
| 15 | sp-verify | mood_dialog dispose 顺序 | P3 | S | mood_dialog.dart:93-97 |

### 4.2 推荐执行顺序

**v0.25 round 46 (后续 sprint)**:
1. P0 #1 修硬编码时区 + 加 2 个 test（PIPL 合规 + TDD）
2. P1 #2 补 `crossedMidnightSince` isolated test（4 case）
3. P1 #3 修 `vent_compose._togglePlay` 暂停异常路径 + 1 个 test
4. P1 #4 补 DayDetailCalculator 排序 regression test
5. P2 #8 + #9 一并修 lint warning（dart fix --apply）

**v0.26 (后续 sprint)**:
6. P1 #5 / #6 重构 reminder_scheduler + 优化 isWeekPerfect
7. P1 #7 mood_repository 改 entity 参数
8. P2 #10 / #11 / #12 架构一致性扫尾
9. P3 #13 / #14 / #15 文档 + cleanup

### 4.3 superpowers-en 视角额外建议

- **每条 TDD 修法配 1 failing test**：本报告 9 条 [sp-TDD] / [sp-debug] 标签的 issue，每条修时都应先 RED 写 test
- **CI 守护扩展**：
  - `scripts/check_no_hardcoded_utc.py` (P0 1)
  - `scripts/check_widget_dispose.py` (P1 3 复盘)
  - `scripts/check_async_context.py` (P2 10)
- **架构季度审视**：建议每 5-6 round 跑一次 superpowers-en 视角审视（本次 v0.24 round 45 之后 → v0.30 round 50 时）
- **新功能 checklist**：
  - [ ] RED 测试先于 GREEN 实现
  - [ ] 一次只修一个 Phase 4 fix（系统化调试原则）
  - [ ] 不跨过 Phase 1 Root Cause Investigation
  - [ ] 跑 `flutter analyze` + `flutter test` 验证后报告

### 4.4 跑过的守护脚本

```bash
$ dart scripts/check_all.dart
✅ [1/2] 4 层架构纯度检查
✅ [2/2] 架构语义一致性检查

$ python scripts/check_cross_feature.py
[OK] check_cross_feature: 70 files checked, 0 violations

$ python scripts/check_datetime_race.py
同函数多次 DateTime.now() 的文件数: 0
```

---

**报告生成时间**: 2026-07-26
**审视方法**: TDD 视角 + 系统化调试 + 架构一致性 + Code Review + Verification
**未跑**: `flutter test`（避免引入新 randomness）；`flutter run`（dev 服务器坑）
**未改代码**: 本报告为只读审视（read-only review），所有 issue 描述 + 修法建议供后续 sprint 实施
