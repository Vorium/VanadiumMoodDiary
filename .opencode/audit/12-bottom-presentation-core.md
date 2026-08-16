# 批次 3 — 底层逐行 bug-hunt: providers + widgets + main/app

范围: `lib/presentation/providers/` (17) + `lib/presentation/widgets/` (43, 含 animations/ + charts/) + `lib/main.dart` + `lib/app.dart`。共 ~70 文件全部读完。

## 发现表

| # | 文件:行号 | 严重性 | 修复难度 | 优先级 | 类型 | 描述 | 建议 |
|---|---|---|---|---|---|---|---|
| 1 | `widgets/mood_quick_button.dart:20` | 低 | 低 | P3 | 架构 | `MoodQuickButton` 0 caller (lib 全库实锤); 连带 `shared_providers.dart:101 todayMoodProvider` 唯一 caller 就是它 → 两者皆死代码 | 删除 2 处, 或 homepage 重接 |
| 2 | `providers/core_providers.dart:80` | 低 | 低 | P3 | 架构 | `encryptionServiceProvider` 0 caller; vent provider 自己 `EncryptionService()` (impl 内 `?? EncryptionService()`) → 全局单例形同虚设 | 删除 provider, 或 vent_providers 改注入它 |
| 3 | `providers/assessment_providers.dart:46` | 低 | 低 | P3 | 架构 | `latestEntryByScaleProvider` 0 caller; 且是 keepAlive family — 一旦启用, 每个 scaleId 缓存永不失效 (新 entry 后 stale) | 删除, 或启用时改 autoDispose + invalidate 策略 |
| 4 | `providers/assessment_providers.dart:53` | 低 | 低 | P3 | 架构 | `scaleAvailableProvider` 0 caller | 删除 |
| 5 | `providers/legal_consent_provider.dart:59` | 低 | 低 | P3 | 架构 | `legalConsentWithdrawnAtProvider` 0 caller | 删除 |
| 6 | `providers/cbt_rerated_entries_provider.dart:28` | 中 | 低 | P2 | 底层 | `allMoodProvider.value ?? const []` 把 error 态吞成空 list — mood 列表 / 趋势 / 日常追踪图表 / 整合页在 DB 读取失败时静默显示"0 条", `ErrorState` 永不出现。同款模式: `worry_section.dart:21-22`、`worry_selector_field.dart:58`、`daily_tracking_providers.dart` 6 个 latestXxx | `.value` 前判 `hasError` 或改 `when` 上抛错误态 |
| 7 | `widgets/page_scaffold.dart:69` | 低 | 低 | P3 | 底层 | `final translucentBar = AppBar(title: Text(title!), ...)` 无条件构建 — 未来任一 caller 漏传 title 即 runtime null-check 崩溃 (当前 43 处全带 title, 潜伏) | 移到 `title != null && !isWide` 分支内, 或 `title ?? ''` |
| 8 | `widgets/loading_text_button.dart:114,144` | 低 | 低 | P3 | 底层 | `_ChildStack` spinner 颜色硬编码 `fgOnPrimary` — outlined/text/tonal variant + isLoading 时白 spinner 叠浅底不可见。当前 isLoading 的 caller 恰好都是 filled, 潜伏 | spinner 颜色按 variant 映射 (跟 leadingIcon 同款 switch) |
| 9 | `widgets/audio_lifecycle.dart:520-534` | 中 | 中 | P2 | 底层 | 录音中 (recording/paused) 离开页面 → dispose 链 `recorder.stop()` 落盘录音**明文 temp 文件**, 但链只删 `tempDecryptedPath` (播放临时明文); 录音 temp 路径归 subclass 管理, mixin 不删 → 疑似明文残留 (PIPL §28) | 核实 vent_compose / mood_audio_recorder 的 `cleanupTempFile` override 是否含录音 temp; 不含则 mixin 增删录音 temp 步骤 |
| 10 | `widgets/consent_dialog.dart:78` | 低 | 低 | P3 | 底层 | dialog builder 闭包内用**外层** `context` (`AppTokens.textStyleCaptionHint(context)`) 而非 `ctx` — caller 已 dispose 而 dialog 仍挂时 rebuild 会用 defunct element 崩 (极端时序) | 改用 `ctx` |
| 11 | `widgets/worry_selector_field.dart:59-65` | 低 | 低 | P3 | 底层 | `initialThreadId` 指向已 resolved / 不存在的 thread 时, label 显示"不关联"但 `_selection.threadId` 仍绑定 → 显示与保存不一致 | 检测不在 open 列表时降级为 none 并回传 onChanged |
| 12 | `lib/main.dart:100-105` | 低 | 低 | P3 | 底层 | `FlutterError.onError` 在 debug 模式只 `developer.log`, 不 `presentError` — dev 控制台无完整 ErrorWidget/框架 dump (release 不受影响, 是 dev 体验退化) | debug 分支加 `FlutterError.presentError(details)` |
| 13 | `widgets/error_state.dart:86` | 低 | 低 | P3 | 架构 | 全 lib 唯一残留裸 `ElevatedButton.icon` (v0.27 9 处迁 PrimaryButton 漏网) | 换 PrimaryButton |
| 14 | `widgets/last_med_info.dart:70-78` | 低 | 低 | P3 | 架构 | 手写 `_formatDateTime` 绕开 `core/shared/formatters.dart` intl DateFormat 集中器 (locale 不敏感) | 走 Formatters |
| 15 | `widgets/dimension_row.dart:90-115` | 低 | 低 | P3 | 底层 | `AnimatedDefaultTextStyle` 对 emoji 字形动画 color/fontWeight — emoji 不随 text color 变, 动画无效 (纯浪费) | 去掉 AnimatedDefaultTextStyle, 选中态只靠底色 |
| 16 | `widgets/loading_skeleton.dart:152-161` | 低 | 低 | P3 | 底层 | `LoadingScrim` 内 `Row(mainAxisSize.min)` + Text(message) 无 Flexible — 窄屏 + 长文案溢出条纹 | Text 包 Flexible + ellipsis |
| 17 | `widgets/apple_health_tile.dart:168-169` | 低 | 低 | P3 | 架构 | `'contact'` metric 映射残留 (1.1.0 已整删 contact feature) — 死分支 + 文档漂移 | 删除 case 与注释 |
| 18 | `providers/notification_init_provider.dart:23` | 低 | 低 | P3 | 架构 | 注释引用已不存在的 `AppInitializer.run` (实际 main.dart override 注入) — 文档漂移 | 修注释 |
| 19 | `widgets/worry_section.dart:64` | 低 | 低 | P3 | 底层 | `'🎉'` 硬编码 emoji (check_strings 不管 emoji, 但 a11y/风格越界) | 走 ARB 或删 |
| 20 | `providers/cbt_providers.dart:143-145` | 低 | 低 | P3 | 底层 | `setStep` 对 `three` 档 maxStep=6 (UI 恒 0, 无害但语义错) | maxStep 按档位显式三分 |
| 21 | `providers/check_in_notifier.dart:15` | 低 | 低 | P3 | 底层 | CheckInNotifier keepAlive — 打卡失败后 `AsyncError` 跨页面残留, 回主页每次显示 error 态直到下次成功 (R113 已修"误庆祝", 但 error 持久性仍在) | 入口 reset 或错误态加过期 |
| 22 | `lib/app.dart:130` | 低 | 低 | P3 | 底层 | `_scheduleDailyReminderOnStart` 硬编码 `hour:20, minute:0` — 与 settings 配置无联动 (若产品约定固定 20:00 则无害) | 确认产品意图 |
| 23 | `lib/main.dart:133` | 低 | 低 | P3 | 底层 | `_markAppDocsExcludedFromBackup` fire-and-forget 在 `runApp(AppRoot)` 前启动, 与后续 audio 首次写入竞态 (仅影响新文件首写窗口) | 可接受, 记录即可 |
| 24 | `widgets/app_snack_bar.dart:70-75` | 低 | 低 | P3 | 底层 | `undo`/`withAction` 的 `onUndo`/`onAction` fire-and-forget 无统一 catch — 依赖 caller 自觉 (文档已声明) | 可选: 包 swallowError |

## 已核实无问题的点 (防误报)

- `PageScaffold` 43 处 caller 全带 title; `_canRouterPop` 优雅降级 OK。
- `mood_dao` / `sleep_dao` watchAll 均显式 orderBy desc → `latestMoodEntryProvider.first` / `latestSleepEntryProvider.firstOrNull` 时序假设成立。
- `AudioLifecycleMixin` reduce-motion / mounted / dispose 链 4 步齐全; `_elapsedTimer` / `playbackTimer` / `playerCompleteSub` 全有 cancel。
- 所有 5 个动画集中器 (FadeIn / SlideUp / CelebrationBounce / TweenNumber / PageTransitionSwitcher) + `_EntrySpring` + `_Shimmer` 均有 reduce-motion 分支, 无 Motion 未包场景。
- `PressFeedback` disabled 态原样渲染 (EM-14 系列) — PrimaryButton / CheckInButton / AppListTile / PressFeedbackIconButton 四处接线正确。
- widgets/ 与 providers/ 内 `ref.read` 只出现在注释里, 无 ref.read-after-unmount 残留。
- provider 无 ref.read 循环依赖; Notifier 均有 `ref.mounted` 或 sync 方法。
- main.dart 启动顺序 (env/时区/迁移/通知/SP 并行 + 迁移确认 + 单实例 override) 无新发现; 3 处 kReleaseMode/kDebugMode 守卫齐全。

## Top 10 bugs

1. **#6** (P2 · 低) `cbt_rerated_entries_provider.dart:28` — `.value ?? const []` 吞 error, mood/趋势/追踪多处静默空列表, ErrorState 永不出现
2. **#9** (P2 · 中) `audio_lifecycle.dart:520-534` — dispose 链只删播放明文 temp, 录音明文 temp 疑似残留 (PIPL §28)
3. **#7** (P3 · 低) `page_scaffold.dart:69` — `title!` 无条件求值, 漏传 title 即崩 (潜伏)
4. **#1** (P3 · 低) `mood_quick_button.dart:20` — MoodQuickButton + todayMoodProvider 双死代码
5. **#2** (P3 · 低) `core_providers.dart:80` — encryptionServiceProvider 0 caller 死代码
6. **#8** (P3 · 低) `loading_text_button.dart:114` — spinner 色硬编码 fgOnPrimary, 非 filled variant loading 不可见 (潜伏)
7. **#11** (P3 · 低) `worry_selector_field.dart:59` — initialThreadId 失效时显示"不关联"但 draft 仍绑定 (显示/保存不一致)
8. **#10** (P3 · 低) `consent_dialog.dart:78` — dialog builder 用外层 context (defunct context 崩, 极端时序)
9. **#3** (P3 · 低) `assessment_providers.dart:46` — latestEntryByScaleProvider 死 + keepAlive family stale 风险
10. **#21** (P3 · 低) `check_in_notifier.dart:15` — 打卡 AsyncError 跨页面残留, 主页持续显示失败态

## 批次结论

无 P0 / P1 级新 bug。R113 修复战役后本批次 (providers/widgets/main/app) 健康度良好: dispose 33/33、reduce-motion 全覆盖、ref.read-after-unmount 0 残留均属实。主要问题是 **5 处死代码** + **2 个 P2 潜伏问题** (error 吞没 / 录音明文 temp) + 一批 P3 风格/文档漂移。修复建议: 死代码一次性删 (5 分钟), #6/#9 各 1-2h, 其余 P3 可随手带。
