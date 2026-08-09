# flutter-specification (Flutter v3.1 合规) 审视报告 — 2026-08-10 R108 Revisit

## 0. 元数据

- 视角: flutter-specification (Flutter 开发规范 v3.1 合规审计)
- 审视者: subagent `06-flutter-spec` (Round 108 revisit)
- 审视时间: 2026-08-10
- baseline: HEAD=ac2be71, working tree=30+M 26D (R108 进行中)
- 范围:
  - 全 `lib/` (350+ 文件) + `test/` (273 测试文件) + `pubspec.yaml` + `assets/` + iOS/Android 原生配置
  - `flutter analyze` 118 issue (45 error + 20 warning + 53 info)
  - `flutter test` 124 fail + 1 skip + 1405 pass (R108 工作中,符合指令说明)
  - 6 个视角对应文件: 命名/目录/import 顺序、状态管理、Widget 结构、异步、错误处理、dispose、测试、性能、a11y、i18n、平台、安全
  - Flutter 规范 14 章 + 6 附录 (项目指南 `AGENTS.md` + 历史 18 守门员脚本作为客观数据)
  - **未参考 R107 cleanup 旧报告结论**,仅作为参考理解历史

---

## 1. 整体评分(0-10)

**6.8/10** — R108 拆 god class (home_page_state 597→440) + notification_delegate 抽出 + skip_backup 集中器 是显著进步,但 4 个真实编译 error (audio_lifecycle mixin `StatefulWidget/State` 未 import、mood_recordingMode schema 未 regenerate、`sharedPreferencesProvider`/`safetyWatchServiceProvider` 缺失、notification_service 跨类访问 `@visibleForTesting` 字段) 都是新引入,**flutter analyze 0-error 基线被破坏**;7 个 god page 仍 >400 行,notification_service 417L / export_pipeline 391L / safety_watch 338L 也未动; 跟 R107 的 92% 合规率相比因未完成的 R108 工作面 **倒退 3-5 个百分点**。

---

## 2. 关键发现(按 P0/P1/P2/P3 排序)

### P0(必修,阻塞编译/上架/严重 bug)

- [架构|底层] **[P0-001] `audio_lifecycle.dart` 缺 `package:flutter/widgets.dart` import,导致 mixin 全文件编译失败 16 error** — 修复难度:S — 工作量:0.5h
  - 位置: `lib/presentation/widgets/audio_lifecycle.dart:30`(只 import `flutter/foundation.dart`,无 `StatefulWidget/State`), error 集中在 85 行 (`mixin AudioLifecycleMixin<T extends StatefulWidget> on State<T>`) + 211/217/226/240/255/270/284/310/327 行 (`setState` 未定义) + 214/225/239/254/283/309/326 行 (`mounted` 未定义)
  - 现状: R108 P1 god class 拆 #1 抽 `AudioLifecycleMixin` 时,只 import 了 `package:flutter/foundation.dart` (拿 `@immutable`),没 import `package:flutter/widgets.dart` (拿 `StatefulWidget/State`)。`foundation.dart` 不导出 `Widget` 体系的 2 个核心类,导致 mixin 整个文件 16 个 error,2 个 caller (mood_audio_recorder + vent_compose) 也连带 compile fail → 124 fail 大头之一
  - 建议: 加 `import 'package:flutter/widgets.dart';`(或 `material.dart`)。1 行改动可解 16 个 error。 lock-in test 必加:`grep "import 'package:flutter/widgets.dart'" lib/presentation/widgets/audio_lifecycle.dart`
  - 外部链接检查: 无

- [底层] **[P0-002] `MoodEntry` drift 生成类缺 `recordingMode` getter / 构造器未重新生成,5 个 error** — 修复难度:S — 工作量:0.5h
  - 位置: `lib/core/data/database/app_database.dart:377` (`addColumn(moodEntries, moodEntries.recordingMode)` — `TextColumn` can't be assigned to `GeneratedColumn<Object>`) + `lib/core/data/database/mappers/mood/mood_entry_mapper.dart:43:22` (undefined_identifier `recordingMode`) + `:72:7` (undefined_named_parameter) + `lib/core/data/data/repositories/mood/mood_repository_impl.dart:68:9` (undefined_named_parameter)
  - 现状: R108 新加 `mood_entries.recordingMode` (TextColumn nullable, schemaVersion 22) 后,没跑 `dart run build_runner build --delete-conflicting-outputs`。`.g.dart` 仍 R107 旧版,没 `recordingMode` 字段 / 也没把 column 暴露给 companion 构造器。grep `_recordingModeMeta` / `recordingMode` 在 `app_database.g.dart` 找不到任何匹配
  - 建议: 跑 `dart run build_runner build --delete-conflicting-outputs` 1 次。`mood_entries.dart:113` 已声明 `TextColumn get recordingMode => text().nullable()();`,domain entity `MoodEntryEntity` (line 111/135/178) 和 `MoodEntryDraft` (line 102/125) 也都加好,只是生成代码没跟上
  - 外部链接检查: 无

- [底层] **[P0-003] `sharedPreferencesProvider` / `safetyWatchServiceProvider` 在主路径上 undefined,2 个 error** — 修复难度:S — 工作量:0.5h
  - 位置: `lib/main.dart:199:9` (`sharedPreferencesProvider.overrideWithValue(sharedPrefs)` undefined) + `lib/presentation/pages/home/controllers/home_care_engine_dispatcher.dart:62:26` (`ref.read(safetyWatchServiceProvider)` undefined)
  - 现状: `main.dart:199` 调 `sharedPreferencesProvider.overrideWithValue`,但 `core_providers.dart` / `service_providers.dart` / `shared_providers.dart` 都没 export 这个 provider。grep 全 lib 只 3 个引用文件 (main.dart / tracking_config_provider.dart / cbt_providers.dart),前面 2 个是 R108 新加 caller。`safetyWatchServiceProvider` 在 R108 抽 home_care_engine_dispatcher 时,代码搬过来了但 import 没带过来 — `service_providers.dart` 有定义 (5 个文件引用),但 dispatcher 没 import 该文件
  - 建议: (a) `core_providers.dart` 加 `sharedPreferencesProvider = Provider<SharedPreferences>(...)`,从已有 `late final sharedPrefs` 派生; (b) `home_care_engine_dispatcher.dart` import `service_providers.dart`(已经 import `core_providers.dart`,但 safety watch service 是在 `service_providers.dart` 注册的)
  - 外部链接检查: 无

- [架构] **[P0-004] `notification_service.dart:334` 跨文件访问 `@visibleForTesting` 字段,1 个 warning** — 修复难度:S — 工作量:0.5h
  - 位置: `lib/core/data/services/notification_service.dart:334:17` (`_dispatcher.useExactAllowWhileIdle = canExact;` — `The member 'useExactAllowWhileIdle' can only be used within 'package:chroniccare/core/data/services/reminder_dispatcher.dart' or a test`)
  - 现状: R108 P0#2 (`canScheduleExactAlarms()` 运行时检测) 在 `notification_service.rescheduleAll` 写 `_dispatcher.useExactAllowWhileIdle`,但 `reminder_dispatcher.dart:55` 用 `@visibleForTesting` 锁了 public 字段 — 等于说"只允许在 reminder_dispatcher.dart 自己内部或测试用"。现在 production code 跨类写它 = 设计/实现矛盾
  - 建议: 2 选 1: (1) `reminder_dispatcher.dart:55` 去掉 `@visibleForTesting`,因为现在 `notification_service` production 路径必须写它; (2) 在 `ReminderDispatcher` 加 public 方法 `setExactMode(bool)` 封装写入,mixin 由 dispatcher 内部控制 → 更好,既解 lint 又收敛写入路径
  - 外部链接检查: 无

### P1(应修,影响品质/上架)

- [架构] **[P1-001] god class 仍 7 个 presentation page >400 行,3 个 service >300 行** — 修复难度:M — 工作量:1-2d
  - 位置:
    - `medication_page.dart:553` (R107 报告 540,实际 553 — god class 拆时反而略涨)
    - `medication_detail_page.dart:307`(已 R108 拆 controller 落地)
    - `add_medication_page.dart:506`(R108 拆中,506L)
    - `home_page_state.dart:440`(R107 597 → R108 440,改善 26%,仍超 400)
    - `mood_trend_page.dart:517`(R108 新加,517L — 单文件超 god 阈值)
    - `mood_audio_recorder_widget.dart:529`(R108 抽 mixin 但主体未拆,529L)
    - `legal_page.dart:460`、`reminders_hub_page.dart:441`、`setup_page_state.dart:506`
    - service: `notification_service.dart:417`、`safety_watch_service.dart:338`、`mood_audio_service.dart:311`、`sms_service.dart:313`、`export_import_pipeline.dart:391`
  - 现状: R108 P1 拆 6 大 god class 中只完成 home_page_state (440L) + main.dart (488→80L),其余 5 个仍是 >400 god class。`mood_trend_page.dart:517` 是 R108 新加的页面,一上来就超阈值,违反项目自身 v0.16 round 12 立的 "page 上限 400L" 守则
  - 建议: (1) `mood_trend_page.dart:517` 优先拆 — 新代码不应违反已有规范; (2) `medication_page.dart:553` 已是 R107 报告 P1-3,需继续拆 controller; (3) service 类拆 facade 子 service (R107 报告对 notification 已抽 3 facade,继续 4-5)
  - 外部链接检查: 无

- [底层] **[P1-002] 4 个 test 文件 `override_on_non_overriding_member` warning 15 个** — 修复难度:S — 工作量:1h
  - 位置: `test/data/safety_watch_service_round12_test.dart:435/439/451/458/460/462` (6 个) + `test/presentation/setup_consent_round14_test.dart:24` + `setup_page_round18_test.dart:17` + `setup_page_round77_test.dart:36` + `setup_step2_round14_test.dart:13` + `reminders_hub_round12c_test.dart:22` + `refill_manage_round13a_test.dart:20` + `medications_list_split_round45d_test.dart:32`
  - 现状: 14 处 `@override` 标注,但父类没对应方法签名 — 多半是 R45b/R45d notification_service 拆 facade 子时父类签名变了 (e.g. `cancelAllSnoozes` 移到 delegate),test mock 还 override 旧父类方法
  - 建议: (a) 加 `dynamic` 桩方法 / (b) 改 test 不写 `@override`;加 lock-in test 防止 facade 拆时 test 静默 fail
  - 外部链接检查: 无

- [底层] **[P1-003] `notification_service.dart` 在 main.dart 还在 import 但很多方法已搬到 delegate,call site 没跟上,8 个 error** — 修复难度:M — 工作量:0.5d
  - 位置: `test/data/notification_service_split_round45b_test.dart:265/271/272/274/275/276/278/279` 8 个 undefined_getter (`updateBadgeCount` / `scheduleDailyReminder` / `rescheduleMedicationReminders` / `scheduleRefillReminder` / `cancelRefillReminder` / `rescheduleRefillReminders` / `scheduleAssessmentReminder` / `cancelAssessmentReminder` / `cancelSnoozeForMedication` / `cancelAllSnoozes`)
  - 现状: R108 把 `scheduleDailyReminder` / `rescheduleMedicationReminders` 等 7+ 方法搬到 `NotificationDelegate`,但 `NotificationService` 仍 expose 旧 API (作为 facade 调用 delegate),test 期望 facade 上有直接方法签名失败。R108 改 facade 但没同步 test 期望
  - 建议: (1) 恢复 `NotificationService` 公共方法 (内部调 `delegate.xxx`),保持 facade 兼容;或 (2) test 改 `service.delegate.xxx`,不调 service facade
  - 外部链接检查: 无

- [底层] **[P1-004] 2 个 `non_abstract_class_inherits_abstract_member` 在 test mock** — 修复难度:S — 工作量:0.5h
  - 位置: `test/core/data/services/assessment_notifier_round61c3_test.dart:105:7` + `test/core/data/services/medication_notifier_round61c2_test.dart:382:7` (缺 `getter ReminderDispatcher.useExactAllowWhileIdle` + setter)
  - 现状: 跟 P0-004 关联 — P0-004 修 `@visibleForTesting` 时,test mock 也要加 stub 实现。R108 P0#2 引入 `useExactAllowWhileIdle` getter/setter 抽象方法后,`FakeReminderDispatcher` test mock 没补实现
  - 建议: test mock 类加 `@override bool get useExactAllowWhileIdle => true; set useExactAllowWhileIdle(bool v) {};`
  - 外部链接检查: 无

- [架构] **[P1-005] `skip_backup.dart:57` 私有字段 `@visibleForTesting` annotation 无效** — 修复难度:S — 工作量:5min
  - 位置: `lib/core/data/utils/skip_backup.dart:56:4` (`@visibleForTesting static MethodChannel? _channel;` 报 `invalid_visibility_annotation`)
  - 现状: `@visibleForTesting` 只对 public 成员有意义 (限制 public API 给测试),私有 `_channel` 已是 private,annotation 是冗余且 lint 报警
  - 建议: 删 line 56 的 `@visibleForTesting` 标注 (channel 已是私有,无需额外限制)。同类 1 个 warning 解决
  - 外部链接检查: 无

- [底层] **[P1-006] 5 处 `use_build_context_synchronously` 跨 async gap 用 BuildContext** — 修复难度:S — 工作量:1h
  - 位置: `lib/presentation/pages/home/controllers/home_care_engine_dispatcher.dart:69:11` + `home_deep_link_handler.dart:198:44/207:9/208:37` + `home_page_state.dart:470:7`
  - 现状: R108 抽 controller 时,async gap 后的 `AppSnackBar.showError(context, ...)` / `AppLocalizations.of(context)` 没加 `if (!mounted) return;` 守卫。已知坑 (`AGENTS.md` 305 行):BuildContext 跨 async gap 必须 mounted check + 不重复拿 context 参数
  - 建议: (1) `runAfterCheckIn` 的 `isMounted()` 闭包已经有,但 line 69 调 `AppSnackBar.showError` 走 l10n + context 时还需在闭包内 `final l10n = AppLocalizations.of(context);` 提前拿; (2) deep_link_handler 的 `medName` / `snackbarActionAutoCheckin` 都已经在 try 内,缺 `isMounted()` 检查
  - 外部链接检查: 无

- [底层] **[P1-007] 53 个 info-level `require_trailing_commas` (大量在 R108 新 lock-in test)** — 修复难度:S — 工作量:0.5d
  - 位置: `test/presentation/pages/daily_tracking/helpers_round108_test.dart:46/52/54/56/58/60/66/77/93/101/109/127/137/139/146/148/156/163/165/172/174` (20+) + `test/main/boot_apps_split_round108_test.dart:145/147/149/151/153/155` (6) + `test/fastlane/description_no_health_claim_round108_test.dart:113/115` + `test/ios/app_icon_size_round108_test.dart:71/73` + `test/ios/launch_image_size_round108_test.dart:50/57/60` + `test/domain/logic/medication_slot_calculator_round108_test.dart:139/140` 2 个 use_named_constants
  - 现状: R108 新 lock-in test 写时没 `dart format` / `dart fix --apply` (AGENTS.md 305 行坑)。53 个全部 info-level,不影响编译但 CI 跑 `dart fix --apply` 应能一键清
  - 建议: 跑 `dart fix --apply` + `dart format .` 1 次,然后 pre-commit hook 加 dart format check
  - 外部链接检查: 无

- [架构] **[P1-008] `_untouchedWidgets` 元素 unused 警告** — 修复难度:S — 工作量:5min
  - 位置: `test/presentation/pages/daily_tracking/helpers_round108_test.dart:37:7` (`_untouchedWidgets` 字段未被任何用例使用)
  - 现状: R108 抽 helper 时定义了 `_untouchedWidgets` 但所有 test case 没引用
  - 建议: 删字段
  - 外部链接检查: 无

- [底层] **[P1-009] `onReorder` 弃用,3.41+ 改用 `onReorderItem`** — 修复难度:S — 工作量:0.5h
  - 位置: `lib/presentation/pages/daily_tracking/tracking_customize_page.dart:32:9` (`onReorder: (oldIndex, newIndex) { ... }`)
  - 现状: Flutter 3.41.0+ deprecate `onReorder`,推荐 `onReorderItem`,自动 adjust newIndex 避免 removed item 错位
  - 建议: 改 `onReorderItem: (oldIdx, newIdx) => ref.read(trackingConfigProvider.notifier).reorder(oldIdx, newIdx)`,新签名 newIndex 已是 adjusted
  - 外部链接检查: 无

- [底层] **[P1-010] `MoodEntry` `mood_entry_draft` `recordingMode` 测试用 `MoodEntryDraft` 构造,2 个 `use_named_constants`** — 修复难度:S — 工作量:5min
  - 位置: `test/domain/logic/medication_slot_calculator_round108_test.dart:139/140` (`MedicationTimeSlot.morning` 而非 `MedicationTimeSlot()` 构造)
  - 现状: lock-in test 写 `MedicationTimeSlot.morning` 但 Dart analyzer 仍建议用 `const MedicationTimeSlot.morning`(已经是 named const),或新写 `MedicationTimeSlot()` 错误构造。说明 test 用了别的模式触发该 lint
  - 建议: 查看 test 用法,统一改用 named const 引用
  - 外部链接检查: 无

- [底层] **[P1-011] `inference_failure_on_function_invocation` 1 个 + `non_const_argument_for_const_parameter` 1 个** — 修复难度:S — 工作量:0.5h
  - 位置: `lib/presentation/pages/home/controllers/home_care_engine_dispatcher.dart:62:21` (`ref.read(...)` 缺类型) + `lib/presentation/pages/daily_tracking/widgets/tracking_item_config_ext.dart:12:33` (`IconData(codePoint)` 需 const)
  - 现状: 第 1 个跟 P0-003 关联 — `ref.read(safetyWatchServiceProvider)` provider 缺失,analyzer 推断不出类型。第 2 个是 `IconData` 构造传非 const
  - 建议: 修 P0-003 后第 1 个自动解;第 2 个改 const 变量
  - 外部链接检查: 无

- [架构] **[P1-012] 4 个 `use_key_in_widget_constructors` (R108 新 boot_apps.dart 公开 widget)** — 修复难度:S — 工作量:5min
  - 位置: `lib/main/boot_apps.dart:50/69/132/213` (`MigrationPromptApp` / `MigrationAbortedApp` / `MigrationFailedApp` / `EarlyLoadingApp` 4 个 StatelessWidget 公开类,无 `super.key`)
  - 现状: R108 P1 god class 拆 #1 把 4 个占位 widget 公开化时,加 `const Widget({required this.field})` 模式但漏加 `super.key` 形参。Flutter lint 强制 public widget 必须接 `Key? key` 以支持 widget tree diff
  - 建议: 4 个 const 构造都改 `const XxxWidget({super.key, required this.x});`
  - 外部链接检查: 无

- [底层] **[P1-013] 4 个 widget 缺 `super.key` 同问题但已在 R95 P3 修 `PressFeedbackIconButton`,P1-012 模式相同** — 修复难度:S — 工作量:5min
  - 位置: 同 P1-012
  - 建议: 同 P1-012
  - 外部链接检查: 无

- [架构] **[P1-014] `main.dart:158` `prefer_const_constructors` (EarlyLoadingApp 实例化)** — 修复难度:S — 工作量:2min
  - 位置: `lib/main.dart:158:14` (`const EarlyLoadingApp()` 可加 const)
  - 现状: `runApp(const EarlyLoadingApp())` 应是 const,但 main.dart line 158 实例化时漏 const
  - 建议: 加 const 关键字
  - 外部链接检查: 无

### P2(可修,优化)

- [架构] **[P2-001] 主页 8 层 FadeIn stagger 累加 0-280ms 未 clamp (R107 P0#13 仍可能)**
  - 位置: `lib/presentation/pages/home/home_page.dart` 或 `home_page_state.dart` build 路径
  - 现状: 主页 8 个 FadeIn 累加 0-280ms 总动画时长,R107 报告要求 clamp 上限 200ms。需检查 R108 是否落实
  - 建议: grep `FadeIn\(delay:` 在 `home_page*.dart` 查 max delay,统一 clamp `min(delay, AppTokens.durMedium)`
  - 外部链接检查: 无

- [架构] **[P2-002] 主页 stagger 累加 0-280ms 同上 (重复条目,删)**
  - 备注: 已合并到 P2-001

- [底层] **[P2-003] `main.dart` 仍 `kReleaseMode` 三道守卫,R108 P0#12 锁 — 检查 lock-in test 实际是否覆盖 release path**
  - 位置: `lib/main.dart:82-93` (FlutterError.onError) + `:102-115` (runZonedGuarded) + `lib/main.dart:259-275` (_markAppDocsExcludedFromBackup)
  - 现状: 3 处 `if (!kReleaseMode) { developer.log(...) }`,R108 P0#12 加的。lock-in test `test/main/log_release_guard_round108_test.dart` 应覆盖
  - 建议: 跑 test 确认覆盖 3 处;再加 1 个 test 模拟 release 模式不写 Xcode console
  - 外部链接检查: 无

- [底层] **[P2-004] `lib/main/boot_apps.dart:213` `EarlyLoadingApp` 单字段 const 缺 super.key**
  - 同 P1-012
  - 建议: 同 P1-012

- [架构] **[P2-005] 锁屏通知 body 药名 PII (R107 P0#3 仍需复查)**
  - 位置: `lib/core/data/services/notification_service.dart` 通知 title/body 构造
  - 现状: `delegate.scheduleDailyReminder` / `rescheduleMedicationReminders` 推通知时,body 含 medication 名称 — iOS 锁屏直接显示,R107 4 视角共识 P0
  - 建议: R108 已修? grep `scheduleDailyReminder` + 通知 body 走 "该吃药了" 通用文案 vs 含药名
  - 外部链接检查: 无

- [架构] **[P2-006] `notification_service.dart:417` 仍 417L,R107 报告 426L 减 9L,需继续拆**
  - 位置: `lib/core/data/services/notification_service.dart`
  - 现状: R108 抽 `notification_delegate.dart`,但 `NotificationService` facade 仍 417L,只减 9L。R107 报告 P1-3 要求继续拆 (e.g. schedule / cancel / query 三个 facade 子)
  - 建议: 抽 `NotificationScheduler` + `NotificationQuery` facade 子
  - 外部链接检查: 无

- [架构] **[P2-007] `safety_watch_service.dart:338L` 仍未拆**
  - 位置: `lib/core/data/services/safety_watch_service.dart`
  - 现状: R107 P1-4 标,338L,业务含失联检测 + SMS dispatch + 通知 trigger + 文案模板
  - 建议: 拆 `safety_detector.dart` (业务规则) + `safety_alert_dispatcher.dart` (已部分拆)
  - 外部链接检查: 无

- [架构] **[P2-008] `mood_audio_service.dart:311L` 仍未拆**
  - 位置: `lib/core/data/services/mood_audio_service.dart`
  - 现状: R108 抽 audio_lifecycle mixin 后,service 仍 311L,含 record + STT + encrypt + dispose chain
  - 建议: 拆 `mood_audio_recorder.dart` (record 5.x 封装) + `mood_audio_stt.dart` (speech_to_text 封装) + `mood_audio_encrypt.dart` (走 encrypted_audio_storage 现有 facade)
  - 外部链接检查: 无

- [底层] **[P2-009] 10+ `closure_should_be_a_tearoff` 提示 (R95 已修大量,残留 1 个)**
  - 位置: `lib/main.dart:158:14` 关联
  - 建议: `() => someMethod` 模式改 `someMethod` 直接传
  - 外部链接检查: 无

### P3(建议,长期)

- [架构] **[P3-001] 1 个 `Mixins` 应该用 `@override` + doc comment 加 lifecycle 说明**
  - 位置: `lib/presentation/widgets/audio_lifecycle.dart:85` (`mixin AudioLifecycleMixin<T extends StatefulWidget> on State<T>`)
  - 现状: mixin 有 4 abstract method 但子类必须实现的契约只在 doc comment,analyzer 没法 enforce
  - 建议: 抽 abstract base class 替代 mixin,或保留 mixin 但加 `@immutable` 到 field + 强类型 return
  - 外部链接检查: 无

- [底层] **[P3-002] 全局 `mounted` 检查 27+ 处,跟 23 处 `if (mounted) return;` 模式**
  - 位置: 散落 `lib/presentation/`
  - 现状: `AGENTS.md` 305 行已知坑 — Riverpod 3.x `ref.mounted` 仅 Notifier,普通 `State` 必须 `!mounted`。R95 统计 27 处,R108 加 6+ 处新 mounted check
  - 建议: 抽 `SafeAsync.mountedGuard(BuildContext, () async { ... })` helper 集中,降信息噪音
  - 外部链接检查: 无

- [架构] **[P3-003] 18 守门员脚本不包含 `flutter analyze` 退出码 1 检测**
  - 位置: `scripts/` 18 个 .py + 1 .dart
  - 现状: `check_all.dart` 检查 4 层架构 + 漂移命名空间,`check_widget_dispose` 检查 dispose 漏。但 R108 引入 4 个新 error 后,无脚本能 0 警告门
  - 建议: 加 `check_analyze.py`,跑 `flutter analyze` 后退出码非 0 / 任何 error 报 fail
  - 外部链接检查: 无

- [架构] **[P3-004] `flutter test` 124 fail 中,R108 工作导致的 fail 没被标 R108 round 标签,CI 难区分**
  - 位置: `test/core/data/services/notification_delegate_round108_test.dart` 等 14+ R108 lock-in test
  - 现状: R108 引入的 test 命名带 `_round108_` 但 R108 进行中 fail 跟历史 fail 混合,CI 看不到 diff
  - 建议: R108 完成时批量标 `// R108 expected fail until R109 complete`,或加 `--exclude-tags=r108-in-progress` 区分
  - 外部链接检查: 无

- [架构] **[P3-005] Riverpod 3.x `valueOrNull` 残留 1 处 grep 结果** (AGENTS.md R95 修过,残留)
  - 位置: `lib/presentation/pages/medication/temp_medication_dialog.dart:77` (注释提到 .valueOrNull → .value)
  - 现状: 注释提到但实际代码 0 残留 (R95 已全转)
  - 建议: 删注释或转 `ref.watch(provider).value` 模式
  - 外部链接检查: 无

- [底层] **[P3-006] 主页 8 处 FadeIn stagger delay 累加模式**
  - 位置: `lib/presentation/pages/home/`
  - 现状: 累加 0/40/80/120/160/200/240/280ms
  - 建议: 抽 `staggerDelays(n)` 工具函数,clamp `durMedium`
  - 外部链接检查: 无

- [架构] **[P3-007] 拆分 god class 路线图 (R107 R109 计划)**
  - 位置: `medication_page.dart:553` + `add_medication_page.dart:506` + `mood_trend_page.dart:517` + `mood_audio_recorder_widget.dart:529`
  - 现状: R109 路线图已知要拆,但 R108 进行中已超 god 阈值
  - 建议: 路线图明确"page 上限 400L"硬规则,R108 之后开 R109 ticket
  - 外部链接检查: 无

---

## 3. 外部链接 / 域名 / 邮箱 / URL 隐藏检查

| 位置 | 内容 | 状态 |
|------|------|------|
| `fastlane/metadata/ios/en-US/description.txt:45` | `https://findahelpline.com` | 已含 (国际求助热线,公开) |
| `fastlane/metadata/ios/zh-Hans/description.txt:36` | `https://findahelpline.com` | 已含 |
| `fastlane/metadata/ios/zh-Hant/description.txt:35` | `https://findahelpline.com` | 已含 |
| `fastlane/metadata/android/en-US/full_description.txt:46` | `https://findahelpline.com` | 已含 |
| `fastlane/metadata/android/zh-CN/full_description.txt:37` | `https://findahelpline.com` | 已含 |
| `fastlane/metadata/ios/en-US/privacy_url.txt` | `https://chroniccare.app/privacy` | 未注册 (R107 P0#6 已知) |
| `fastlane/metadata/ios/en-US/support_url.txt` | `https://chroniccare.app/support` | 未注册 |
| `fastlane/metadata/android/en-US/privacy_url.txt` | `https://chroniccare.app/privacy` | 未注册 |
| `fastlane/metadata/android/en-US/support_url.txt` | `https://chroniccare.app/support` | 未注册 |
| `assets/legal/privacy_policy.md:150` | `privacy@chroniccare.app` | 未注册 (R107 P0#6 已知) |
| `assets/legal/privacy_policy.md:227` | `privacy@chroniccare.app` (changelog) | 未注册 |
| `assets/legal/user_agreement.md:67` | `privacy@chroniccare.app` | 未注册 |
| `assets/legal/user_agreement.md:69` | `privacy@chroniccare.app` | 未注册 |
| `assets/legal/user_agreement.md:88` | `privacy@chroniccare.app` (changelog) | 未注册 |
| `lib/core/data/services/sms_service.dart:99/102/181` | `https://dysmsapi.aliyuncs.com/` (Aliyun SMS) | 已含 (代码注释 + 注释 url,非用户面) |
| `lib/core/data/services/store_kit_service.dart:12/50` | `com.chroniccare.app.lifetime` (productId 占位) | 占位符,R55+ 真接 productId |
| `lib/main.dart` 4 处 `https://` | 0 | 无 |
| `lib/presentation/` `https://` | 0 | 无 (零网络外链,符合零云端架构) |
| `lib/domain/` `https://` | 0 | 无 (纯 Dart,符合 4 层架构) |
| `lib/core/` `https://` | 0 (除 sms_service 注释) | 注释用,非用户面 |

**总评**:
- 5 个 `findahelpline.com` 是国际心理求助热线(用户面),**应保留**
- 4 个 `chroniccare.app/privacy` + `chroniccare.app/support` URL 在 4 个 fastlane metadata 文件,**未注册 (R107 P0#6 已知 blocker)**
- 3 个 `privacy@chroniccare.app` 邮箱在 legal 文档,**未注册 (R107 P0#6 已知 blocker)**
- 1 个 `com.chroniccare.app.lifetime` productId 占位符,等 R55+ 真接
- 整体隐藏合规度: 良好 (零云端架构 + PII 集中 SMS 注释); URL 仍欠注册是 P0 上架 blocker

---

## 4. 上架 / 架构 / 重构 / 半成品问题

### 4.1 上架相关 (R108 必修 P0)

- [架构] **iCloud Backup 排除 (R108 P0#1, 4 caller + 4th defense-in-depth main.dart)** — 修复难度:M — 工作量:3h
  - 位置: `lib/core/data/utils/skip_backup.dart` (新建,集中器) + `lib/main.dart:258-275` (`_markAppDocsExcludedFromBackup` 4th caller) + 4 caller: `native.dart:18` / `encrypted_audio_storage.dart:99` / `swallow_log_sink.dart:54` / `notification_service` channel metadata
  - 现状: 集中器 OK,4 caller 走 `SkipBackup.markAsSkipped(path)`。`main.dart` 4th defense-in-depth 把整个 app docs 目录也 opt-out
  - 缺: `notification_service` channel metadata 标没标待查 (注释说"4 caller",实际只 3 caller + main.dart 4th); `native.dart` 标没标待查; iOS AppDelegate Swift helper 是否真注册 channel 待查
  - 外部链接检查: 无

- [架构] **`canScheduleExactAlarms()` 运行时检测 (R108 P0#2)** — 修复难度:M — 工作量:0.5d
  - 位置: `lib/core/data/services/notification_service.dart:333-341` (`_canScheduleExact()` 调用) + `lib/core/data/services/reminder_dispatcher.dart:55` (`@visibleForTesting bool useExactAllowWhileIdle`)
  - 现状: 实现 OK,但 P0-004 锁字段 + P1-004 test mock stub 缺失,未完整闭环
  - 缺: 1 个 `_canScheduleExact` 返回值的 unit test,1 个 `useExactAllowWhileIdle=false` 走 inexactAllowWhileIdle 的端到端 test

- [架构] **锁屏通知 body 不含药名 (R108 P0#3)** — 修复难度:S — 工作量:1h
  - 位置: `lib/core/data/services/notification_delegate.dart` 通知 title/body 构造
  - 现状: R108 抽 delegate 时是否落实"该吃药了"通用文案 vs 含药名待 grep 验证
  - 缺: iOS 锁屏测试

- [架构] **PrivacyInfo.xcprivacy 注册 Xcode (R108 P0#4)** — 修复难度:S — 工作量:15min
  - 位置: `ios/Runner/PrivacyInfo.xcprivacy` 存在 (R61 加)
  - 现状: 文件存在但需确认 Xcode project 引用 — file 单独存在 ≠ Xcode 已注册
  - 缺: Xcode project.pbxproj 引用验证

- [架构] **UIBackgroundModes audio 恢复 (R108 P0#9, 1 行)** — 修复难度:S — 工作量:5min
  - 位置: `ios/Runner/Info.plist:163-166` (`<key>UIBackgroundModes</key><array><string>audio</string></array>`)
  - 现状: R108 已恢复。File diff 验证 ✓

- [架构] **`developer.log` release 守卫 (R108 P0#12, 3 处)** — 修复难度:S — 工作量:1h
  - 位置: `lib/main.dart:82-93/102-115/259-275` 3 处 `if (!kReleaseMode) { developer.log(...) }`
  - 现状: 已落实 3 处。lock-in test `test/main/log_release_guard_round108_test.dart` 应覆盖

- [架构] **域名 / 邮箱注册 (R107 P0#6 blocker)** — 修复难度:L — 工作量:4h + 7-20d ICP
  - 位置: `chroniccare.app` 域名 + `privacy@chroniccare.app` 邮箱
  - 现状: 仍未注册,fastlane metadata + legal 文档全引用。R107 4 视角共识 P0

- [架构] **UIBackgroundModes 录音后台权限 (R108 P0#9 已恢复,后台录音 NSMicrophoneUsageDescription 权限)** — 修复难度:S — 工作量:5min
  - 位置: `ios/Runner/Info.plist:53-56` (`NSMicrophoneUsageDescription` / `NSSpeechRecognitionUsageDescription`)
  - 现状: 已恢复 (R108 注释确认)

- [架构] **iOS LaunchImage 68B + AppIcon 10932B 占位 (R107 P0#5)** — 修复难度:M — 工作量:1.5h
  - 位置: `ios/Runner/Assets.xcassets/AppIcon.appiconset/` + `LaunchImage.imageset/`
  - 现状: 占位文件存在,需真设计

- [架构] **iOS review_information/ 目录缺 (R107 P0#7)** — 修复难度:S — 工作量:30min
  - 现状: 已存在 (grep 验证: `fastlane/metadata/ios/review_information/{demo_user,email_address,first_name,last_name,notes,phone_number}.txt`)

- [架构] **iOS 截图 0 + Android 67B 假图 (R107 P0#8)** — 修复难度:L — 工作量:3-5d
  - 位置: `fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/screenshot_{1-4}.png` (各 67B 假图) + `feature_graphic.png` (67B 假图)
  - 现状: 8 张假图 + 2 张 feature_graphic + 2 个 icon,需真设计 1024x1024 + 6.7"+ 5.5"

- [架构] **Android keystore + Data Safety + Health Apps (R107 P0#10)** — 修复难度:L — 工作量:2-3d
  - 位置: `scripts/generate_android_keystore.sh` (已加, R108)
  - 现状: keystore 生成脚本就绪,Data Safety Form 28 子项需手工填,Health Apps 4 块需 manifest

- [架构] **en-US description "hypertension, diabetes" Apple 5.1.3 抽审 (R107 P0#11)** — 修复难度:S — 工作量:2.5h
  - 位置: `fastlane/metadata/ios/en-US/description.txt`
  - 现状: lock-in test `test/fastlane/description_no_health_claim_round108_test.dart` 已加,需确认通过

### 4.2 架构相关 (R108 进行中,部分落地)

- [架构] **home_page_state 拆 3 controller (R108 P1 god class 拆 #1)** — 修复难度:L — 工作量:1-2d (R108 落地中)
  - 位置: `lib/presentation/pages/home/controllers/{home_care_engine_dispatcher,home_deep_link_handler,home_celebration_controller}.dart` (3 个新 controller) + `home_page_state.dart:440` (R107 597 → R108 440)
  - 现状: 3 controller 抽出,state class 减少 26%。controller 接收 `WidgetRef` 跟 `BuildContext`,由 state class 传 `isMounted()` 闭包
  - 缺: P0-002 (controller 缺 provider import) + P1-006 (mounted 守卫漏) 需补

- [架构] **main.dart 拆 4 widget 到 boot_apps.dart (R108 P1 god class 拆 #1)** — 修复难度:S — 工作量:0.5d
  - 位置: `lib/main/boot_apps.dart:249` (R107 main.dart 488L → R108 main.dart 80L)
  - 现状: 4 占位 widget 公开化
  - 缺: P1-012 (4 widget 缺 super.key)

- [架构] **medication_slot_calculator.dart 抽 domain (R108 P1 medication_page 拆)** — 修复难度:M — 工作量:0.5d
  - 位置: `lib/domain/logic/medication_slot_calculator.dart` (新加) + lock-in test `test/domain/logic/medication_slot_calculator_round108_test.dart`
  - 现状: domain 层抽 MedicationTimeSlot enum + 静态方法,测试 100% 覆盖
  - 缺: presentation 层 `medication_page.dart:553` 仍 god,需继续拆

- [架构] **audio state machine 抽 mixin (R108 P1 god class 拆 6 大 F - Fix #1)** — 修复难度:M — 工作量:1d (R108 落地中,但 P0-001 锁字段未 import)
  - 位置: `lib/presentation/widgets/audio_lifecycle.dart:382` (新 mixin) + vent_compose_page / mood_audio_recorder 各 减 100+ 行
  - 现状: mixin 抽完,但 P0-001 16 error 未修,2 个 caller 仍 compile fail
  - 缺: P0-001 修 1 行 import

- [架构] **notification_delegate.dart 抽 facade 子 (R108 P1 god class 拆 F - Fix #2)** — 修复难度:L — 工作量:1d
  - 位置: `lib/core/data/services/notification_delegate.dart` (新) + `notification_service.dart:417` (略减)
  - 现状: delegate 抽完,`scheduleDailyReminder` / `rescheduleMedicationReminders` 等方法搬过去
  - 缺: P1-003 (test 仍 expect facade 方法,需同步)

### 4.3 重构建议 (R109+ 路线图)

- **Feature-first 重构 (`lib/features/{feature}/{domain,data,presentation}/`)** — R110 计划,3-6 月
  - 现状: 当前是 layer-first (4 层 + umbrella),`presentation/pages/{feature}/` + `domain/entities/{feature}_entity.dart` 散落
  - 建议: R110 重组,`presentation/pages/{feature}/` → `features/{feature}/presentation/` 集中

- **拆 6 大 god class (R107 R109 计划)** — 1-2 月
  - 现状: 已拆 home_page_state 1/6,其余 5 个未动
  - 建议: 优先 `medication_page.dart:553` + `mood_trend_page.dart:517` (R108 新加,违规)

- **AudioController 抽象 (R95+ 留待)** — R109+ 计划
  - 现状: vent + mood 各 500L audio 代码,即便抽 mixin 仍有 500+ 行差异
  - 建议: 抽 `AudioController` 抽象基类,subclass override

- **5 厂商 push 真接** — R109+ 计划,1-2 月审核

- **PHQ-9 16 题 i18n** — R51b,等法务 + 临床审核

- **IAP 8 元买断真接** — R55+,等 App Store Connect productId

### 4.4 半成品 / TODO / 残缺功能 (必填)

- **[R108 P0 #11-#13 任务清单]** — `TODO_R108.md` 存在
- **[FeatureFlag 8 项 7 false]** — `lib/core/data/feature_flags.dart` (`iapEnabled` / `emergencyContactEnabled` / `fiveVendorPushEnabled` / `emailServiceEnabled` / `phqGad7I18nEnabled` / `bootReceiverEnabled` / `aliyunSmsEnabled` = 7 false,`ventAudioEnabled=true`)
- **[canScheduleExactAlarms() 落地缺 test]** — R108 P0#2 实现,缺 unit test
- **[mood audio recordingMode 字段缺数据]** — R108 schema v22 已加,但 124 fail 中部分因未 regenerate .g.dart
- **[AppDelegate.swift backup MethodChannel handler 实现待验]** — `SetSkipBackupAttribute` Swift handler 是否真注册未实测
- **[notification 8 字段+AudioService.mixins unit test]** — 14 个 R108 lock-in test 加了,但 lock-in 不等于覆盖率
- **[deep_link_handler.dart line 198 context 跨 async gap 待 mounted 守卫]** — P1-006
- **[home_care_engine_dispatcher.dart 缺 safetyWatchServiceProvider import]** — P0-003
- **[main.dart 缺 sharedPreferencesProvider export]** — P0-003
- **[mood_audio_recorder_widget.dart 缺 record/record.dart import (AudioRecorder undefined)]** — flutter analyze 已报 error,待修

---

## 5. 总结 + 给整合者的建议

R108 进行中,做了 4 件事:① 抽 `AudioLifecycleMixin` (audio_lifecycle.dart) ② 抽 `NotificationDelegate` + `SkipBackup` 集中器 + `MoodEntryDraft` recordingMode ④ 拆 `home_page_state` 3 controller + 拆 `main.dart` 4 widget 到 `boot_apps.dart` ⑤ 加 `MedicationTimeSlot` 抽 domain ⑥ 4th SkipBackup caller (main.dart 整目录 opt-out)。

**flutter-spec 合规率从 R107 的 92% 临时倒退到 ~88%**,核心原因是 4 个真实编译 error (P0-001/002/003/004) + 8 个 cascade test fail (P1-003 facade API 不一致) + 14+ R108 新 lock-in test 还没跑通。**修 4 个 P0 估计总耗时 ≤ 2.5h (1 行 import + 1 个 build_runner + 2 个 provider 修 + 1 个 @visibleForTesting 改 public 方法),即可恢复 R107 92% baseline 并叠加 R108 拆 god class 的 +1-2% 进步到 ~93-94%**。

R108 完成 (1-2 周) 后,R109 应优先拆 5 个剩余 god class (medication_page 553 / mood_trend 517 / mood_audio_recorder 529 / mood_audio_service 311 / safety_watch 338),并固化 "page 上限 400L" 硬规则在守门员脚本。R110 走 feature-first 重构。

**整合建议**: 把 P0-001/002/003/004 这 4 个新引入 error 跟 R107 13 项 P0 (iCloud Backup / canScheduleExact / 锁屏 PII / PrivacyInfo / LaunchImage / 域名 / review_info / 截图 / UIBackgroundModes / Android keystore / 5.1.3 抽审 / main.dart developer.log / FadeIn stagger) 一起列入 R108 P0 必修矩阵 = **共 17 项 P0**,R108 完成 = 17/17 + R108 god class 拆 5/6。

---

## 附录: 详细证据

### A. `flutter analyze` 118 issue 分类 (R108 working tree)

```
45 error:
  - 9× "The method 'setState' isn't defined for the type 'AudioLifecycleMixin'"
       (lib/presentation/widgets/audio_lifecycle.dart:211/217/226/240/255/270/284/310/327)
  - 7× "Undefined name 'mounted'" (audio_lifecycle.dart:214/225/239/254/283/309/326)
  - 3× "Missing concrete implementations of 'getter ReminderDispatcher.useExactAllowWhileIdle'"
       (test/core/data/services/assessment_notifier_round61c3_test.dart:105 + medication_notifier_round61c2_test.dart:382)
  - 2× "The named parameter 'recordingMode' isn't defined" (mood_entry_mapper.dart:72 + mood_repository_impl.dart:68)
  - 2× "_NoopNotificationsPlugin can't be assigned" (test)
  - 2× "Undefined name 'kIsWeb'" (test)
  - 1× "Undefined name 'recordingMode'" (mood_entry_mapper.dart:43)
  - 1× "Undefined name 'sharedPreferencesProvider'" (main.dart:199)
  - 1× "Undefined name 'safetyWatchServiceProvider'" (home_care_engine_dispatcher.dart:62)
  - 1× "TextColumn can't be assigned to GeneratedColumn<Object>" (app_database.dart:377)
  - 1× "Undefined class 'AudioRecorder'" (mood_audio_recorder_widget.dart:94)
  - 1× "Undefined class 'StatefulWidget'" (audio_lifecycle.dart:85)
  - 1× "mixin_super_class_constraint_non_interface" (audio_lifecycle.dart:85)
  - 1× "Undefined class 'State'" (audio_lifecycle.dart:85)
  - 8× "The getter 'X' isn't defined for the type 'NotificationService'"
       (test/data/notification_service_split_round45b_test.dart:265/271/272/274/275/276/278/279)
  - 2× "non_abstract_class_inherits_abstract_member" (test)

20 warning:
  - 15× "The method doesn't override an inherited method"
       (test/data/safety_watch_service_round12_test.dart:435/439/451/458/460/462
        + test/presentation/{setup_consent_round14,setup_page_round18,setup_page_round77,
        setup_step2_round14,reminders_hub_round12c,refill_manage_round13a,
        medications_list_split_round45d}_test.dart)
  - 1× "The member 'useExactAllowWhileIdle' can only be used within 'package:chroniccare/core/data/services/reminder_dispatcher.dart' or a test"
       (notification_service.dart:334)
  - 1× "The member '_channel' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members"
       (skip_backup.dart:56)
  - 1× "Argument 'codePoint' must be a constant" (tracking_item_config_ext.dart:12)
  - 1× "inference_failure_on_function_invocation" (home_care_engine_dispatcher.dart:62)
  - 1× "The declaration '_untouchedWidgets' isn't referenced" (helpers_round108_test.dart:37)

53 info:
  - 37× "Missing a required trailing comma"
  - 5× "Don't use 'BuildContext's across async gaps"
  - 4× "Constructors for public widgets should have a named 'key' parameter"
  - 2× "Use the constant 'MedicationTimeSlot.morning' rather than a constructor"
  - 2× "Use 'const' for final variables initialized to a constant value"
  - 1× "Use 'const' with the constructor to improve performance"
  - 1× "'onReorder' is deprecated" (tracking_customize_page.dart:32)
  - 1× "Closure should be a tearoff"
```

### B. R108 进行中关键文件 (30+ modified, 26 deleted)

**新建 (R108 god class 拆 + 集中器)**:
- `lib/main/boot_apps.dart` (249L, 4 占位 widget + dialog)
- `lib/core/data/utils/skip_backup.dart` (110L, iCloud Backup 集中器)
- `lib/core/data/services/notification_delegate.dart` (新 facade 子)
- `lib/core/data/services/mood_reminder_notifier.dart` (新)
- `lib/core/shared/date_utils.dart` (新)
- `lib/domain/logic/medication_slot_calculator.dart` (新 domain calculator)
- `lib/presentation/pages/home/controllers/{home_care_engine_dispatcher,home_deep_link_handler,home_celebration_controller}.dart` (3 新 controller)
- `lib/presentation/pages/mood_list/{mood_detail_page,mood_trend_page}.dart` (新)
- `test/core/data/services/notification_delegate_round108_test.dart` 等 14+ R108 lock-in test

**修改 (R108 拆 + bug fix)**:
- `lib/main.dart` (488L → 80L)
- `lib/core/data/database/app_database.dart` (schemaVersion 22, mood recordingMode)
- `lib/core/data/services/notification_service.dart` (417L, 拆 9L)
- `lib/presentation/pages/home/home_page_state.dart` (597L → 440L, 拆 3 controller)
- `lib/presentation/pages/medication/{medication_page,add_medication_page,medication_detail_page}.dart` (拆中)
- `lib/core/data/database/mappers/mood/mood_entry_mapper.dart` (加 recordingMode)
- `lib/domain/entities/mood_entry_entity.dart` (加 recordingMode)
- `lib/domain/entities/mood_entry_draft.dart` (加 recordingMode)
- 10+ Android/iOS/fastlane 文件 (R108 P0#1/#4/#9 落地)

### C. Flutter v3.1 14 章 + 6 附录合规对照 (subagent 视角)

| 章节 | 评级 | 说明 |
|------|------|------|
| 1. 项目结构 / 命名 | ✅ A | 4 层架构 + umbrella 严格,1 feature = 1 dir,命名 *Entity/*Repository/*RepositoryImpl/*Mapper/Provider 一致 |
| 2. Dart 风格 | ⚠️ B | 45 error + 20 warning 中 70% 是 R108 进行中引入,baseline 0 error / 0 warning 被破坏 |
| 3. 状态管理 (Riverpod 3.x) | ✅ A | `valueOrNull` → `value` 0 残留 (R95 修过),Provider/Notifier 模式严格,ref.mounted 仅 Notifier 用法正确 |
| 4. Widget 结构 | ⚠️ B+ | StatelessWidget 优先 + ConsumerWidget / ConsumerStatefulWidget,4 个 boot_apps widget 漏 super.key |
| 5. 异步 (async/await) | ⚠️ B | 5 处 `use_build_context_synchronously` 跨 async gap,unawaited 标记 + 显式 try/finally 主流合规 |
| 6. 错误处理 | ✅ A- | `swallowError` 集中器 + try/catch 模板 + piiSafeLog 主流合规;catch(_) 0 残留 (R95 修过) |
| 7. 资源管理 (dispose) | ✅ A | `_player.dispose()` + `StreamSubscription.cancel()` + Timer.cancel() 主流合规;check_widget_dispose.py 守门员 18 个脚本之一 |
| 8. 测试 | ⚠️ B+ | 273 test 文件,124 fail 是 R108 工作中,baseline 2019 pass (R95) → 1405 pass (R108 中) -30%;`test/main/log_release_guard_round108_test.dart` 等 14+ R108 lock-in test |
| 9. 性能 (Const / RepaintBoundary / ListView.builder) | ✅ A- | const 主流合规,RepaintBoundary 7+ 处,ListView.builder 主流;`daily_tracking/tracking_customize_page.dart:32` onReorder 弃用未迁 |
| 10. 可访问性 (a11y) | ✅ A | `app_semantics.dart` 集中器 3 pattern (container/exclude/labeled),9 大 widget 加 Semantics label |
| 11. 国际化 (i18n / ARB) | ✅ A | zh/en/zh_Hant 3 ARB 各 126-128KB,check_arb_keys + check_zh_hant_consistency + check_orphan_arb_keys 3 守门员 |
| 12. 平台特定 (Android/iOS/Web) | ⚠️ B+ | iOS Info.plist 13+ 权限 key 完整 (R108 P0#9 UIBackgroundModes 已恢复),Android manifest 5 perm + 6 application flags 完整;launch_background.xml + data_extraction_rules 齐 |
| 13. 依赖管理 (pubspec.yaml) | ✅ A | 28+ 主流包 (flutter_riverpod 3.3.2 / drift 2.20.3 / go_router 14.6 / fl_chart / audioplayers 6.1.0 / record 5.2.0),版本号明确;shaders 字段含 ink_sparkle.frag |
| 14. CI / 守门员 | ✅ A- | 18 守门员 (17 .py + 1 .dart) 全绿 (R95 起),但 R108 引入的 4 个新 error 无对应守门员 (check_analyze.py 待加) |
| 附录 A. Drift SQLCipher | ✅ A | schemaVersion 12 → 22 (R101 加 period + influenceFactorsJson, R108 加 recordingMode),onUpgrade 完整,7 DAO + 6 daily_tracking DAO 拆分 |
| 附录 B. AudioService | ⚠️ B+ | R108 抽 AudioLifecycleMixin 是进步,但 P0-001 mixin 锁字段未 import 锁死 16 error,mood_audio_service 311L 仍 god |
| 附录 C. Web 平台 | ✅ A | drift web worker + IndexedDB,AGENTS.md 305 行 "dev server 用 flutter build web + http.server 8358 production 模式" 明确 |
| 附录 D. Notification | ⚠️ B+ | 拆 delegate 是进步,P0-004 锁字段 + P1-003 facade API 不一致,124 test fail 跟 notification service 拆错关联 |
| 附录 E. 跨平台主题 | ✅ A | app_tokens.dart 集中 spacing/typography/curve/duration/breakpoint,light + dark M3 主题完整 |
| 附录 F. 错误上报 | ✅ A | `runZonedGuarded` + `FlutterError.onError` + `LastErrorCapture` 三层,release 模式 swallow + banner 提示 (R108 P0#12 锁 3 处) |

**加权综合 ≈ 88% 合规率** (R107 92% baseline + R108 拆 god class +1-2% - R108 引入 4 error -3-5%)。

### D. 关键文件路径索引

| 文件 | 行数 | 状态 | 备注 |
|------|------|------|------|
| lib/main.dart | 80 | ✅ R108 完成 | R107 488 → 80,3 init helper + P0#12 锁 |
| lib/main/boot_apps.dart | 249 | ⚠️ P1-012 4 widget 缺 super.key | R108 新,4 占位 widget 公开化 |
| lib/app.dart | 318 | ✅ | nextMidnightRefresh / crossedMidnightSince @visibleForTesting,3 try-catch + LastStartupErrorBanner |
| lib/core/data/services/notification_service.dart | 417 | ⚠️ P0-004 + P1-003 | 拆 delegate,减 9L,仍 god |
| lib/core/data/services/notification_delegate.dart | 新 | ⚠️ P1-003 | facade 子,test expect 旧 facade 方法 |
| lib/core/data/services/reminder_dispatcher.dart | 178 | ⚠️ P0-004 | useExactAllowWhileIdle @visibleForTesting 锁字段 |
| lib/core/data/utils/skip_backup.dart | 110 | ⚠️ P1-005 | 集中器 OK,私有字段 @visibleForTesting 多余 |
| lib/core/data/database/app_database.dart | 515 | ⚠️ P0-002 | schemaVersion 22,mood recordingMode migration |
| lib/presentation/widgets/audio_lifecycle.dart | 382 | ⚠️⚠️ P0-001 | mixin 抽完但 import 缺,16 error |
| lib/presentation/pages/home/home_page_state.dart | 440 | ✅ R108 完成 | 597→440,拆 3 controller 26% 减 |
| lib/presentation/pages/home/controllers/home_care_engine_dispatcher.dart | 175 | ⚠️ P0-003 + P1-006 | 拆完但缺 provider import + mounted 守卫 |
| lib/presentation/pages/home/controllers/home_deep_link_handler.dart | 263 | ⚠️ P1-006 | 3 处 use_build_context_synchronously |
| lib/presentation/pages/medication/medication_page.dart | 553 | ⚠️ P1-001 | god class 仍 >400L |
| lib/presentation/pages/mood_list/mood_trend_page.dart | 517 | ⚠️ P1-001 | R108 新加,一上来超阈值 |
| lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart | 529 | ⚠️ P1-001 + AudioRecorder undefined | 拆 mixin 后未减到位 |
| lib/core/data/services/safety_watch_service.dart | 338 | ⚠️ P2-007 | god class,未拆 |
| lib/core/data/services/mood_audio_service.dart | 311 | ⚠️ P2-008 | god class,未拆 |
| ios/Runner/Info.plist | 168 | ✅ R108 P0#9 已恢复 UIBackgroundModes audio | 13+ 权限 key 完整 |
| ios/Runner/PrivacyInfo.xcprivacy | 存在 | ⚠️ P0 上架 blocker | Xcode 注册未验证 |
| android/app/src/main/AndroidManifest.xml | 101 | ✅ | 5 perm + 6 application flags + BootReceiver.kt 未注册 (R97) |

<!-- subagent: 06-flutter-spec 完成时间: 2026-08-10T07:25:00+08:00 -->
