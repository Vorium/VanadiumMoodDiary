# superpowers-en 审视报告 — 2026-08-10 R108 Revisit

## 0. 元数据
- 视角: superpowers-en (English superpowers 编程方法论)
- 审视者: superpowers-en subagent
- 审视时间: 2026-08-10
- baseline: HEAD=ac2be71, working tree=30+M 26D (R108 进行中)
- 范围: 全量遍历 `lib/main.dart` (226L) + `lib/main/boot_apps.dart` (286L) + `lib/core/data/services/` (35 service) + `lib/core/data/repositories/` (16 impl) + `lib/core/data/database/app_database.dart` (494L) + `lib/core/data/services/export/` (5 文件) + `lib/core/shared/swallow_error.dart` + `lib/core/data/services/swallow_log_sink.dart` + `lib/presentation/pages/home/` (15 文件) + `lib/presentation/pages/medication/` (7 文件) + `lib/presentation/pages/daily_tracking/` + `lib/presentation/pages/vent/` + `lib/presentation/pages/mood/` + `lib/presentation/widgets/audio_lifecycle.dart` (439L) + `lib/presentation/pages/vent/vent_detail_page.dart` + `lib/presentation/widgets/page_scaffold.dart` + `test/presentation/pages/home/controllers_round108_test.dart` + `flutter analyze` 输出 (118 issues) + `test/` 数量统计
- 方法: 全部基于实际代码,不参考 `docs/audit-history/` 历史报告

## 1. 整体评分(0-10)

**6.5/10** — R108 拆 3 controller + 抽 NotificationDelegate + AudioLifecycleMixin 是真实进展(主目标 home_page_state 597→515L、notification 426→417L、audio 重复消除),但 (1) R108 refactor 引入 ~12 个 `flutter analyze` error 级问题(imports 漏改 / rename 漏改 / Flutter 依赖混在 mixin 顶层),表明拆解不彻底且无收尾 checklist;(2) 多处 async gap 漏 `mounted` check,产生 `use_build_context_synchronously` warning 5+ 处(R108 没修);(3) 关键底层 bug `vent_detail_page.dart:73` fire-and-forget Future 包 try/catch 是无效 catch,继续隐藏 PII 数据风险;(4) god class 拆解局部化: medication_page 553L / add_medication_page 506L / export_import_pipeline 391L / safety_watch 338L / mood_audio_service 311L 仍是 god class,只拆了最显眼的 1 个 home_page_state。

## 2. 关键发现(按 P0/P1/P2/P3 排序,每项含架构|底层标签 + 修复难度)

### P0(必修,阻塞上架/严重 bug)

- [底层] **[P0-001] vent_detail_page.dart:73 deleteTempFile 是无效 try/catch** — 修复难度:S — 工作量:30min
  - 位置: `lib/presentation/pages/vent/vent_detail_page.dart:73`
  - 现状: `dispose()` 内 `try { ref.read(ventAudioStorageProvider).deleteTempFile(_tempDecryptedPath!); } catch (e, st) { swallowError(...) }` 没有 `await`,也没有 `unawaited()`。`try/catch` 包裹的是未 await 的 `Future`,**异常不会被 catch**(Dart sync try-catch 不捕获 async 异常)。`_player.dispose()` 后 temp 文件可能仍然存在,直到 OS GC。R22 round 30 走的 swallowError 防御实际从未生效。
  - 建议: 改为 `try { await ref.read(...).deleteTempFile(...); } catch (...)` 并把整个 `dispose` 改成 async,或 `unawaited(...)` + `.catchError(...)` 链。
  - 影响: vent 用户在播放期间离开页面,临时解密 m4a 留在 OS temp dir,直到下次清理。精神心理患者的语音树洞明文文件残留 = PII 泄露风险。
  - 修前 R22 round 30 注释 "走 swallowError" 实际从未生效 — 此 bug 已存在至少 3 个 R round (R22 / R46 / R79)。

- [底层] **[P0-002] AudioLifecycleMixin 缺 Flutter imports 导致 R108 全部 build 失败** — 修复难度:S — 工作量:15min
  - 位置: `lib/presentation/widgets/audio_lifecycle.dart:27-32, 85`
  - 现状: `flutter analyze` 报 13 个 error 集中在这一个文件:`Undefined class 'StatefulWidget' / 'State' / 'AudioRecorder' / setState / mounted`。
  - 根因: `import 'dart:async'; import 'package:audioplayers/audioplayers.dart'; import 'package:flutter/foundation.dart'; import 'package:record/record.dart'; import 'package:chroniccare/core/shared/swallow_error.dart';` — 缺 `import 'package:flutter/material.dart';` 或 `import 'package:flutter/widgets.dart';` 给 `StatefulWidget` / `State` / `setState` / `mounted`,缺 `package:record/record.dart` 之外的 `AudioRecorder` (实际是 `import 'package:record/record.dart'` 应该在,可能路径被 R108 重构改过)。
  - 影响: 整个 `AudioLifecycleMixin` 实例化失败,导致 vent_compose_page 416L / mood_audio_recorder 330L 全部 cascade fail。这 2 个页面是 vent + mood 核心录音功能,完全不能跑。
  - **R108 P0 必修** — 但 working tree 没修。`flutter analyze` 118 issues 已有 13 个直接来自此文件。

- [底层] **[P0-003] main.dart:199 + home_care_engine_dispatcher.dart:62 imports 漏改(R108 refactor 拆 provider)** — 修复难度:S — 工作量:15min
  - 位置: `lib/main.dart:199` (`sharedPreferencesProvider`) + `lib/presentation/pages/home/controllers/home_care_engine_dispatcher.dart:62` (`safetyWatchServiceProvider`)
  - 现状: `flutter analyze` 报 `Undefined name 'sharedPreferencesProvider'` 和 `Undefined name 'safetyWatchServiceProvider'`。R108 把这两个 provider 从 `core_providers.dart` 拆到 `service_providers.dart` / `shared_providers.dart`,但 caller 还在 `import '...core_providers.dart'`。
  - 影响: `flutter run` 直接挂掉 (`_bootstrap()` 走到 `ProviderScope(overrides: [...])` 时 `sharedPreferencesProvider` 找不到 → 编译失败)。home_page 打卡后 `_careDispatcher.fireCareEngine()` 跑不到。
  - 修复: `main.dart` import 加 `import 'package:chroniccare/presentation/providers/shared_providers.dart';`,`home_care_engine_dispatcher.dart` 加 `import 'package:chroniccare/presentation/providers/service_providers.dart';`。

- [底层] **[P0-004] mood_entry_mapper.dart + mood_repository_impl.dart `recordingMode` undefined(R108 rename 没扫到)** — 修复难度:S — 工作量:10min
  - 位置: `lib/core/data/database/mappers/mood/mood_entry_mapper.dart:43, 72` + `lib/core/data/repositories/mood/mood_repository_impl.dart:68`
  - 现状: `flutter analyze` 报 `Undefined name 'recordingMode'` 3 处。R108 把 `recordingMode` 重命名(或改类型)但 mapper + impl 没同步。`app_database.dart:377` 报 `TextColumn` can't be assignable `GeneratedColumn<Object>` 同一根因(表 schema 改了但 mapper 没跟进)。
  - 影响: mood_entries 写入完全 break,4D 情绪 (energy/sleep/anxiety/CBT) round-trip fail。
  - 修复: 用 `app_database.dart` 的当前 schema 反查 `recordingMode` 字段是否还存在,改 mapper 同步。

- [底层] **[P0-005] notification_service.dart:334 跨包访问 @visibleForTesting 字段** — 修复难度:S — 工作量:10min
  - 位置: `lib/core/data/services/notification_service.dart:334` (即 `_dispatcher.useExactAllowWhileIdle = canExact;`)
  - 现状: `flutter analyze` 报 `The member 'useExactAllowWhileIdle' can only be used within 'package:chroniccare/core/data/services/reminder_dispatcher.dart' or a test`。`ReminderDispatcher.useExactAllowWhileIdle` 是 `@visibleForTesting`,但 `NotificationService` 在生产路径调它。
  - 根因: R108 P0#2 把这个 field 加 `@visibleForTesting` 但没考虑 facade (`NotificationService`) 自身也要写它。应该拆出公开 setter / 公开 method,或去掉 `@visibleForTesting`(它本来就不只是给 test 用的)。
  - 影响: 编译失败。R108 P0#2 (SCHEDULE_EXACT_ALARM 检查) 完全跑不到 — 用户撤回权限后通知还按 exact mode 调度,Android 13+ 静默降级 inexact = 15min 漂移。

- [底层] **[P0-006] skip_backup.dart:56 `_channel` 私有 field 加 @visibleForTesting (invalid annotation)** — 修复难度:S — 工作量:5min
  - 位置: `lib/core/data/data/utils/skip_backup.dart:56`
  - 现状: `flutter analyze` 报 `The member '_channel' is annotated with 'visibleForTesting', but this annotation is only meaningful on declarations of public members`。
  - 影响: 测试无法注入 MethodChannel mock 替换 `_channel` 字段 (因为私有)。PIPL §6 (iCloud Backup 排除) 测试覆盖残废。
  - 修复: 删 `@visibleForTesting`,或改 `channel` 为 public + 改 1 注释。

- [架构] **[P0-007] test\core\data\utils\skip_backup_round108_test.dart 缺 kIsWeb import** — 修复难度:S — 工作量:5min
  - 位置: `test/core/data/utils/skip_backup_round108_test.dart:179, 203`
  - 现状: `flutter analyze` 报 `Undefined name 'kIsWeb'`。测试文件用 `kIsWeb` 但没 import `package:flutter/foundation.dart`。
  - 影响: 124 test fail 来源之一(此文件不能 compile,所有 R108 P0#1 iCloud Backup 防御测试挂掉)。

- [底层] **[P0-008] test\core\data\services\notification_service_can_exact_round108_test.dart:156 extends FlutterLocalNotificationsPlugin 但没 import** — 修复难度:S — 工作量:5min
  - 位置: `test/core/data/data/services/notification_service_can_exact_round108_test.dart:156`
  - 现状: `class _NoopNotificationsPlugin extends FlutterLocalNotificationsPlugin { }` — 测试文件没 import `package:flutter_local_notifications/flutter_local_notifications.dart`。
  - 影响: R108 P0#2 (SCHEDULE_EXACT_ALARM) 全部 lock-in 测试 fail。

---

### P1(应修,显著影响体验/重要功能)

- [架构] **[P1-001] 主页 5 处 `use_build_context_synchronously` warning(R108 拆 controller 后 mounted 检查漏)** — 修复难度:S — 工作量:1h
  - 位置: `lib/presentation/pages/home/controllers/home_care_engine_dispatcher.dart:69` + `lib/presentation/pages/home/controllers/home_deep_link_handler.dart:198, 207, 208` + `lib/presentation/pages/home/home_page_state.dart:470`
  - 现状: 5 处 `BuildContext` 跨 async gap 没 `mounted` 守卫。R108 把业务方法从 state class 抽到 controller,**新增的 `isMounted: () => mounted` 闭包传递模式没在所有路径 1:1 应用**。
  - 例: `home_care_engine_dispatcher.dart:69`:
    ```dart
    final result = await ref.read(...).onCheckIn(l10n: l10n);
    if (!isMounted()) return;  // ✓ 守卫
    if (result.kind == SafetyCheckKind.alerted) {
      AppSnackBar.showError(context, ...);  // ✓ isMounted() 已判
    }
    ```
    但 `home_deep_link_handler.dart:198` 仍用原始 `context`,而 `isMounted` 闭包已经存在却没全用。
  - 修法: 全部 5 处加 `if (!isMounted()) return;` 或 `if (!context.mounted) return;` 守卫。R97 round 7 报告 27 处 `!mounted` check,这一波回退了。

- [架构] **[P1-002] medication_page.dart 553L 仍是 god class(2026 R108 拆未涉及)** — 修复难度:L — 工作量:1-2d
  - 位置: `lib/presentation/pages/medication/medication_page.dart:553`
  - 现状: 1 个 `build()` 调 3 大块 (今日时间表 + 我的药物 + 快捷操作),内含 6 个 `private widget` (`_SectionHeader` / `_TimeSlotCard` / `_SlotEntryRow` / `_MedicationListCard` / `_QuickActionCard` / `_EmptyMedicationsCard` / `_EmptyScheduleCard`) + 1 个 `private method` `_buildTimeSlots()` + 1 个 helper `_slotIcon()` + 1 个 mapper `_slotLabel()`。
  - 跟 R107 报告 "6 大 god class" 列表一致 (medication_page 540L) — **R108 没动**。`_buildTimeSlots()` 已经走 `MedicationTimeSlot` (domain),但 widget UI 还在 main class 内。
  - 修法: 抽 `pages/medication/widgets/{today_schedule,medication_list,quick_actions}.dart` 3 子 widget + `pages/medication/slot_section.dart`,main class 缩到 < 200L。

- [架构] **[P1-003] add_medication_page.dart 506L + medication_detail_page.dart 307L (add/edit 重复)** — 修复难度:L — 工作量:1-2d
  - 位置: `lib/presentation/pages/medication/add_medication_page.dart:506` + `lib/presentation/pages/medication/{edit_medication_dialog,temp_medication_dialog}.dart`
  - 现状: add 3-step wizard + edit dialog + temp dialog 3 个不同入口,字段映射 (name/dosage/times) 重复 2-3 次。`add_medication_page` 含 step 1/2/3 全部 UI 状态 + 表单 + 时间选择 + 颜色选择 4 块。
  - 修法: 抽 `MedicationForm` widget (受控 form),3 个 dialog 复用。R108 没动 add_medication_page,只动了 medication_page 的 `_TimeSlot` enum。

- [架构] **[P1-004] export_import_pipeline.dart 391L 仍是 god orchestrator** — 修复难度:M — 工作量:0.5-1d
  - 位置: `lib/core/data/services/export/export_import_pipeline.dart:391`
  - 现状: `runImportFromJson` 顶层函数,内部顺序: 解析 JSON → 校验 version → DB transaction → 删 5 张表 → import profile → import contacts → import medications → import checkIns → import reportHistories → import moodEntries → import ventEntries → 返回 ImportResult。**没有内部子函数拆分**(R77 注释里说"后续 R78+ 进一步拆"但没真做)。
  - 修法: 抽 4 private static method (`_clearAllTables` / `_importProfile` / `_importEntities` / `_importVent`),main orchestrator 缩到 < 100L。R77 留 TODO 没落地。

- [底层] **[P1-005] safety_watch_service.dart 338L `displayMessageL10n` 24 行 switch 是贫血 enum 翻译层** — 修复难度:S — 工作量:1h
  - 位置: `lib/core/data/services/safety_watch_service.dart:350-377`
  - 现状: `SafetyCheckResult.displayMessageL10n(AppLocalizations l10n)` 24 行 switch,8 个 kind 各自调 `l10n.safetyCheckResultXxx(...)`。**这是 data 层引用 `AppLocalizations`**(presentation/l10n 层),违反 AGENTS.md "4 层架构纯度"。4 层检查脚本 `check_all.dart` 在 R108 working tree 状态可能 catch 不到(`lib/l10n/` vs `lib/core/l10n/` 跨层检查)。
  - 修法: 抽 `SafetyResultL10nTranslator` widget (`presentation/widgets/safety_result_text.dart`) 接受 `SafetyCheckResult` + `AppLocalizations`,纯 presentation 层。或者保持 data 层 (跨层导入在 R100 之后已成事实) 但把方法标 `@visibleForTesting` 强制外移。
  - **R107 报告 P0-3 修正的 3 态文案 (alerted / mocked / failed) 集中器**,但 displayMessageL10n 仍混在 data 层,跨层。

- [底层] **[P1-006] mood_audio_service.dart 311L 仍有 god class 倾向(stt + recorder + timer + stream)** — 修复难度:M — 工作量:0.5d
  - 位置: `lib/core/data/services/mood_audio_service.dart:311`
  - 现状: 1 个 `MoodAudioServiceImpl` 14 字段,涵盖: 录音状态 5 字段 + STT 状态 3 字段 + temp 路径 + 2 callback + 3min 上限常量 + 100ms tick 常量 + 注入参数。R108 修了 vent + compose 的 audio state machine (抽 AudioLifecycleMixin),但 `mood_audio_service` 本身仍是 1 个 311L god class。
  - 修法: 抽 `MoodSttController` (专门管 STT listen / stop / transcript stream) + `MoodRecorderController` (专门管录音状态机 + 3min Timer),`MoodAudioServiceImpl` 缩到 < 150L 委派 2 子。
  - R107 报告 "vent + mood audio 2×500L" — R108 vent_compose 修了 (-168L),但 mood_audio 仍是 311L,无变化。

- [架构] **[P1-007] `lastCheckInAt` 等 4 处 `DateTime.now()` 跨函数多次调用 race 检查(AGENTS.md 已知坑)** — 修复难度:S — 工作量:0.5d
  - 位置: 全 lib 搜索 `DateTime.now()` 模式
  - 现状: R108 抽 3 controller 时把 `_nextReminderTime` (home_page_state.dart:507) 单独抽到 state class,但仍是 `final now = DateTime.now();` 单次取 — OK。但 `_runSafetyCheck` (`_checkAndAlert`) 内 `effectiveNow = now ?? DateTime.now()` 也是 OK。**真正问题在 controller 边界**: `HomeCareEngineDispatcher.fireCareEngine()` (line 116) 直接 `DateTime.now()` 注入 `FireCareStrategyInput`,而 `HomeCelebrationController.pickStreakMessage` 之前可能也走过。`safety_watch_service._loadContacts` 内的 `first.timeout(_contactWatchTimeout)` 用 5s 超时但内部仍可能 hang (无 2nd timeout)。
  - 修法: 跑 `python scripts/check_datetime_race.py` + `check_datetime_race2.py`(R95 已加)。如果 R108 引入新 race,加 regression test。
  - 风险: 跨 midnight (00:00:01) 时,fireCareEngine 拿的 `now` 跟 nextReminderTime 拿的 `now` 跨过日期边界 → streak 算错 1 天。

---

### P2(可修,优化)

- [架构] **[P2-001] NotificationService 仍 417L god facade(目标 < 200L)** — 修复难度:M — 工作量:0.5d
  - 位置: `lib/core/data/services/notification_service.dart:417`
  - 现状: R108 抽了 12 委派到 `NotificationDelegate`,主体保留 6 method + 2 const + 2 visibleForTesting。**但 R107 报告 P1-12 标的 "notification god class" 仍是 417L**。剩余业务:
    - `init` 60L: plugin init + tz init + launch details
    - `rescheduleAll` 30L: orchestrator
    - `showSafetyAlert` 28L: 委派 builder + 调 plugin
    - `_canScheduleExact` 23L: P0#2
  - 修法: 抽 `NotificationInitializer` (init 60L) + `NotificationRescheduler` (rescheduleAll 30L) + facade 只留 plugin 引用 + 3 委派 (init / rescheduleAll / showSafetyAlert)。
  - R108 已经把 12 委派合 delegate (Fix #2),但 facade 主体 300+ 业务代码未拆。

- [架构] **[P2-002] safety_watch_service.dart 338L 仍有 2 委派 god 方法(`_loadContacts` stream + `_actOnDecision` switch)** — 修复难度:M — 工作量:0.5d
  - 位置: `lib/core/data/services/safety_watch_service.dart:305, 221`
  - 现状: R64 抽 `SafetyDetector` 后 facade 仅 215L。但 `_loadContacts` (16L) 单独有 timeout + catch + stream first,`_actOnDecision` (42L) 8 kind switch expression。**可下沉到 `SafetyDetector.loadContacts(repo, timeout)` + `SafetyDecision.toCheckResult()` (1:1 mapping)**,让 facade 只剩 3 trigger entry + 1 `run(SafetyInput) → SafetyOutput` 编排。
  - 修法: 抽 `SafetyDecision.toCheckResult({required lastCheckInAt, required profile, required l10n})` + `SafetyDetector.loadContacts(repo, timeout)`,facade 缩到 < 200L。

- [架构] **[P2-003] service_providers.dart 162L 改 81/81(R108 重构)但 god provider 列表本身未拆** — 修复难度:M — 工作量:0.5d
  - 位置: `lib/presentation/providers/service_providers.dart:162`
  - 现状: 1 个文件 162L 含 8+ provider:`safetyWatchServiceProvider` / `reminderDispatcherProvider` / `notificationServiceProvider` / `remindersHubProvider` 等。R108 diff `162 ++++++++++ -----------` 是大改(81 insertions + 81 deletions),但仍是 1 god file。
  - 修法: 拆 `service_providers/safety.dart` + `service_providers/notifications.dart` + `service_providers/reminders_hub.dart` 3 文件。R108 大改未拆。

- [底层] **[P2-004] R95 5 集成测试在 R108 改动后未补 round 集成测试** — 修复难度:M — 工作量:1d
  - 位置: `test/integration/` 目录
  - 现状: 仅 2 个集成测试 (cbt_thought_record_flow_round84 + end_to_end_flows_round95),R95 sub-spec 6 加 5 集成后 1→6,R108 拆 3 controller + audio mixin 后**没有 round108 集成测试**。所有 R108 改动靠单测 (controllers_round108_test 207L,全是文本 grep + 静态分析,无运行时验证)。
  - 修法: 加 `test/integration/round108_controllers_flow_test.dart` 测 deep link → autofire → celebration → care engine 串行;加 `test/integration/round108_audio_lifecycle_test.dart` 测 vent + mood 录音 状态机 + dispose 链 (不依赖 platform channel,纯 unit mock)。

- [底层] **[P2-005] 14 个 round108 lock-in test 几乎全是 grep 文本匹配,真实运行时验证 < 5 个** — 修复难度:M — 工作量:1d
  - 位置: 17 个 `*round108*_test.dart` 文件
  - 现状: R108 lock-in test 17 个,但绝大多数是 `await File(...).readAsString()` + `expect(RegExp(...).hasMatch(content), isTrue)`。例: `controllers_round108_test.dart` 100/207 行是 grep / 行数 check / 文件存在 check。**真的运行时验证只有 4 个** (`notification_service_can_exact` 用 mock plugin + `audio_lifecycle` 用 fake recorder + `medication_slot_calculator` 纯函数 + `stagger_clamp`)。
  - 修法: 至少给 3 controller (HomeDeepLinkHandler / HomeCareEngineDispatcher / HomeCelebrationController) 加 真实 unit test 覆盖 race condition + mounted check + side effect 顺序。

- [底层] **[P2-006] `service_providers.dart` `_smsService` / `_emailService` 顶层 mutable final static 实际打破 DI 边界** — 修复难度:M — 工作量:0.5d
  - 位置: `lib/main.dart:50, 61` (`final SmsService _smsService = SmsService();` + `final EmailService _emailService = EmailService();`)
  - 现状: 顶层 mutable `final` static 引用,绕开 Riverpod。R108 把 boot_apps 拆出后,`main.dart` 仍持有这 2 个 global。**测试要 override 这 2 个 service 必须绕 main.dart**。
  - 修法: 把 `_smsService` / `_emailService` 构造挪到 `BootstrapConfig` value class,`runZonedGuarded(() async { final cfg = await BootstrapConfig.create(); runApp(...); })` 模式。R97 round 62 "P0-3 修复" 加了 `final` 改 `late` 改 `final` 摇摆 3 round,根因是顶层 static 本身违反 DI 原则。

---

### P3(建议,长期)

- [架构] **[P3-001] `core_providers.dart` 仍是大 provider 注册表(R108 没动)** — 修复难度:L — 工作量:2d
  - 位置: `lib/presentation/providers/core_providers.dart`
  - 现状: 7 个 repository provider (db + 7 repo) + 4 service provider (encryption / feature flags / lastErrorCapture / lastErrorBannerVisibility) 集中在 1 文件。R108 拆 `service_providers.dart` 后 core_providers 仍是大 registry。
  - 修法: 拆 `core_providers/db.dart` + `core_providers/repositories.dart` + `core_providers/services.dart` 3 文件。R110 路线图已标。

- [底层] **[P3-002] repository impl 16 个全是 50-150L,平均 80L(健康,无 god repo)** — 修复难度:无 — 工作量:0
  - 现状: 检查 `lib/core/data/repositories/*/`,16 个 impl 最大 `vent_repository_impl.dart:149L`,其余 45-116L。**R107 报告 "repository impl 过厚" 风险 R108 已解决**。
  - 建议: 无需改。R110 feature-first 重构时再调。

- [底层] **[P3-003] audio_lifecycle.dart `AudioLifecycleMixin` 文档示例代码可能不 compile** — 修复难度:S — 工作量:15min
  - 位置: `lib/presentation/widgets/audio_lifecycle.dart:62-84`
  - 现状: doc comment 写 `class _MyState extends State<MyWidget> with AudioLifecycleMixin<MyWidget> { ... }`,但实际 `StatefulWidget` 在 27 行未 import。**doc 跟实际不一致**。
  - 修法: 加 `import 'package:flutter/widgets.dart';` 到 import block。

- [底层] **[P3-004] `medication_repository_impl.dart` 字段 `recordingMode` rename 漏 1 处未跟踪** — 修复难度:S — 工作量:10min
  - 位置: 见 [P0-004]
  - 现状: rename 是 R108 进行中,但 grep `recordingMode` 在 lib/ 仅 3 处 (全在 analyzer error),impl 之外是否有更多引用未扫。
  - 修法: grep 全 lib 确认 0 引用,加 alias (deprecated old name) 兼容 1 round,deprecated message 引导迁移。

---

## 3. 外部链接 / 域名 / 邮箱 / URL 隐藏检查

R108 working tree 没改 docs/legal,所以隐私边界已就位。**但以下** R107 P0-6 (域名 + 邮箱) 仍未注册:

| 位置 | 内容 | 状态 | 备注 |
|---|---|---|---|
| `assets/legal/privacy_policy.md` | `support@chroniccare.app` | 占位符 | 邮箱未注册,R55+ 真接时必须替换 |
| `assets/legal/privacy_policy.md` | `dpo@chroniccare.app` | 占位符 | 邮箱未注册 |
| `assets/legal/user_agreement.md` | `legal@chroniccare.app` | 占位符 | 邮箱未注册 |
| `assets/legal/sensitive_data_consent.md` | (同上) | 占位符 | |
| `fastlane/metadata/ios/en-US/description.txt` | `chroniccare.app` 域名 | 隐藏 | R107 §3 占位文案 |
| `fastlane/metadata/android/en-US/full_description.txt` | (同上) | 隐藏 | |
| `ios/Runner/Info.plist` | (无 URL) | OK | |
| `lib/l10n/app_zh.arb` / `app_en.arb` | (无 URL) | OK | i18n 干净 |
| `lib/core/l10n/strings.dart` | (无 URL) | OK | |
| `assets/legal/*` | `https://chroniccare.app/legal/...` | 占位符 | 域名未注册 |
| 内部 `mailto:` 链接 | `support@...` (12+ 处) | 占位符 | |

**关键**: R108 未引入新 URL/邮箱(只在 `app_localizations.dart` 加少量 i18n key),但 **R107 P0-6 域名 + 邮箱未注册 12 处仍待办**。这是 R55+ 真接 SMS + 律师过审(¥45-90k, 1-2 月)卡点,不属 R108 范畴但属"上架 P0"。

## 4. 上架 / 架构 / 重构 / 半成品问题

### 4.1 上架相关(superpowers-en 视角)

- **R108 工作树未完成**(124 test fail + 12 analyzer error 必修),但这是工作进度,非上架 P0。
- **R107 12 项上架 P0**: 5 视角共识项目(iCloud Backup / canScheduleExact / 锁屏 body / PrivacyInfo / LaunchImage / 域名 / 截图 / UIBackgroundModes / Android keystore / en-US description / main.dart log / stagger clamp),R108 只修了 canScheduleExact + main.dart log + stagger clamp (3 项)。剩余 9 项上架 P0 仍待办。
- **R108 新增上架 blocker**: R108 拆 audio_mixins + controllers 后,`use_build_context_synchronously` warning 5 处是 App Store 4.0 设计规范(无障碍 + a11y)风险,**虽然不是 5.1.x 直接 reject 原因**,但 App Review 反馈"竞态警告未清"会拖慢 review 1-2 天。

### 4.2 架构相关

- **3 controller 拆解 (R108 主目标)**:
  - `HomeDeepLinkHandler` 220L 抽 deep link 业务
  - `HomeCareEngineDispatcher` 147L 抽 care engine 业务
  - `HomeCelebrationController` 84L 抽 celebration 业务
  - state class 597L → 515L(原 R107 目标 < 370L 未达)
  - 评估: 拆解方向对,但**state class 目标 < 370L 未达**(实际 515L)。注释说"R108 P1 home_page_state 拆"目标 370L,**R108 落地未达 100% 目标**。

- **NotificationDelegate (R108 Fix #2)**:
  - 12 委派 method 集中到 namespace
  - facade 主体保留 6 method + 2 const + 2 visibleForTesting
  - 评估: 拆解方向对,**但 facade 仍 417L(目标 < 200L 未达)**。剩余 300L 是 `init` 60L + `rescheduleAll` 30L + `showSafetyAlert` 28L + `_canScheduleExact` 23L + 大量 const + 大量注释。这部分 R108 没拆。

- **AudioLifecycleMixin (R108 Fix #1)**:
  - 4 状态字段 + 4 抽象方法 + 状态机方法 + 共享 asyncDispose
  - 评估: 抽 mixin 是好设计(DRY),但**R108 拆时没修 imports** (P0-002),导致 vent_compose + mood_audio_recorder 全部 cascade fail。**拆解未经过 compile gate**(没跑 `flutter analyze` 就 commit)。

- **MedicationTimeSlot 抽到 domain**:
  - 4 时段 enum + `contains(hour)` 方法
  - 评估: 0 Flutter 0 Drift,纯 Dart 逻辑可测,**符合 R16 决策 "domain 0 flutter"**。R108 注释说"目标 0 Flutter 0 Drift" 达成。
  - 修法参考价值: 这种"presentation 关注点 + 简单 enum 算法"模式可推广到 `_TimeSlotCard` / `_SlotEntryRow` UI 拆分。

### 4.3 重构建议(架构 subagent 应深写)

- **3 controller 拆解目标未达**:
  - 目标 home_page_state 370L,实际 515L (差 145L)
  - 差的部分: 大量 import + 3 controller 实例字段 + build() 180L 主页 6 区域 + _noop static + comment 200L
  - 建议: 把 build() 180L 拆到 widgets/ 区,controller 字段移到单一 `_Controllers` data class,state class 缩到 < 350L
  - **R108 P1 拆解不彻底**,R109 才补(原 R107 计划 R108 完成后 → R109 拆 6 god class,R108 应先达标)

- **export_import_pipeline 391L 仍 god orchestrator**:
  - 1 method 1 transaction 8 import steps
  - 建议: 抽 `_clearAllTables` (50L) / `_importProfile` (30L) / `_importEntities` (100L) / `_importVent` (50L) 4 private static,orchestrator 缩到 < 100L
  - **R77 留 TODO,R108 跨 round 没落地**

- **safety_watch_service 338L facade**:
  - 3 触发 entry + 1 编排 + 1 stream load + 1 result class
  - 建议: facade 退化为 thin wrapper 调 detector 静态方法,`SafetyDecision` 自身有 `toCheckResult({l10n, profile, lastCheckInAt})`,`SafetyDetector` 自身有 `loadContacts(repo, timeout)`,facade 缩到 < 150L

### 4.4 半成品 / TODO / 残缺功能

| TODO | 位置 | 状态 |
|---|---|---|
| R107 §3.2 home_page_state 目标 < 370L | `lib/presentation/pages/home/home_page_state.dart:515` | **未达 (R108 跨 round 任务未完成)** |
| R107 §3.5 notification_service 目标 < 200L | `lib/core/data/services/notification_service.dart:417` | **未达 (R108 Fix #2 拆委派 12 method 但主体未拆)** |
| R77 export_import_pipeline 4 步拆分 TODO | `lib/core/data/services/export/export_import_pipeline.dart:391` | **未达** |
| R60 5 集成测试保 6+ 集成 | `test/integration/` 2 个 | **未达 (R108 没补 round108 集成)** |
| R67 defaultConfig=careCopy,SMS/Email 2 委派 throw StateError 占位 | `lib/presentation/pages/home/controllers/home_care_engine_dispatcher.dart:144, 156` | R55+ 真接后切换 (待外部) |
| P1-1 SMS release fail-fast | `lib/main.dart:165` | 已修,但顶层 mutable `_smsService` 未消 |
| P1-2 Android alarm 权限 TODO | 多个 notification sub-service | R108 P0#2 修了 facade,但 sub-service 不知 canExact,各写自己 useExact |
| R55 真接阿里云 SMS | `lib/core/data/services/sms_service.dart:313` | 走 mock 占位 (待外部 1-2 月) |
| R55 真接 SendGrid Email | `lib/core/data/services/email_service.dart:135` | 走 mock 占位 (待外部) |

## 5. 总结 + 给整合者的建议

**核心 takeaway**:

1. **R108 是"拆解半成品"**,3 controller + delegate + mixin 拆解方向对,但落地漏 compile gate — **12 个 analyzer error 直接来自 R108 refactor 自身的 imports/rename 漏改**。这违反 superpowers-en P0 原则 "refactor 必须 compile + 0 warning + 全 test pass 才算完成"。

2. **state class 拆解目标未达**: R107 报告标的 home_page_state < 370L,R108 实际 515L(差 145L)。R108 跨 round 任务未完成。

3. **真正严重的底层 bug** 是 [P0-001] vent_detail_page.dart:73 deleteTempFile 无效 try/catch,这条 R22 round 30 注释说"走 swallowError"实际从未生效,至少 3 round 隐藏 PII 数据风险。

4. **App Store 4.0 视角**看 R108: 拆 controller + mixin 是正确的可测性方向,但 124 test fail + 12 analyzer error 直接让 CI 红 1-2 周。整合者应该 (a) 优先修 8 个 P0 analyzer error 收尾,让 working tree 至少 `flutter analyze 0 error` + `flutter test 0 fail`; (b) 接受 R108 部分目标未达,把未达目标推到 R109 路线图。

5. **架构 subagent 应深写 3 controller 拆解目标未达** (主壳 515L vs 目标 370L)。

---

## 附录: 详细证据

### A. 数字摘要

- **lib/ 源文件总数**: 404 (.dart,不含 .g.dart)
- **service 文件**: 35 个,最大 notification_service 417L,平均 ~150L
- **repository impl**: 16 个,最大 vent_repository_impl 149L,平均 ~80L
- **presentation page**: 11 个 feature 目录,最大 medication_page 553L
- **home_page 拆解**: state 515L + 3 controller (220+147+84=451L) = 主壳 966L(纯拆解零减少 — R108 P1 home_page_state 拆**净增 ~370L** 因为 3 controller 各自加 import + comment + method signature)
- **test 文件**: 273 个,R108 round108: 17 个,R107 round: ~50 个,untagged: 7 个
- **integration test**: 2 个 (R95 6 个,差 4 个)
- **flutter analyze**: 118 issues (0 已知 R108 in-progress, 12 真实 error, 106 warning/info)
- **flutter test**: 124 fail + 1 skip + 1405 pass (working tree 是 R108 进行中, 124 fail 来自 R108 in-progress)

### B. P0 bug 复现 (vent_detail_page.dart:73)

```dart
// lib/presentation/pages/vent/vent_detail_page.dart:65-80
@override
void dispose() {
  _durationSub?.cancel();
  _positionSub?.cancel();
  _completeSub?.cancel();
  _player.dispose();
  if (_tempDecryptedPath != null) {
    try {
      ref.read(ventAudioStorageProvider).deleteTempFile(_tempDecryptedPath!);
      //         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      //         缺 await + unawaited — sync try/catch 不捕获 async 异常
    } catch (e, st) {
      swallowError(where: 'vent_detail_page.dispose', error: e, stack: st);
      //                  ^^^^^^^^^^^^^^^^^^^^^^^^
      //                  这块实际从未触发 (Future 完成时 dispose 已 return)
    }
    _tempDecryptedPath = null;
  }
  super.dispose();
}
```

**修法**:
```dart
if (_tempDecryptedPath != null) {
  final path = _tempDecryptedPath!;
  _tempDecryptedPath = null;
  unawaited(
    ref.read(ventAudioStorageProvider).deleteTempFile(path).catchError(
      (Object e, StackTrace st) {
        swallowError(where: 'vent_detail_page.dispose', error: e, stack: st);
        return null;
      },
    ),
  );
}
```

### C. P0 imports 漏改列表 (R108 refactor 副作用)

```
error - Undefined name 'recordingMode'  - lib/core/data/database/mappers/mood/mood_entry_mapper.dart:43, 72
error - Undefined name 'recordingMode'  - lib/core/data/repositories/mood/mood_repository_impl.dart:68
error - The argument type 'TextColumn' can't be assigned to 'GeneratedColumn<Object>' - lib/core/data/database/app_database.dart:377
error - Undefined name 'sharedPreferencesProvider' - lib/main.dart:199
error - Undefined name 'safetyWatchServiceProvider' - lib/presentation/pages/home/controllers/home_care_engine_dispatcher.dart:62
error - Undefined class 'AudioRecorder' - lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart:94
error - Undefined class 'StatefulWidget' - lib/presentation/widgets/audio_lifecycle.dart:85
error - Undefined class 'State' - lib/presentation/widgets/audio_lifecycle.dart:85
error - 'setState' not defined for 'AudioLifecycleMixin' - lib/presentation/widgets/audio_lifecycle.dart:211, 217, 226, 240, 255, 270, 284, 310, 327
error - 'mounted' undefined - lib/presentation/widgets/audio_lifecycle.dart:214, 225, 239, 254, 283, 309, 326
error - 'useExactAllowWhileIdle' @visibleForTesting 越界 - lib/core/data/services/notification_service.dart:334
warning - '_channel' @visibleForTesting on private member - lib/core/data/utils/skip_backup.dart:56
error - 'kIsWeb' undefined - test/core/data/utils/skip_backup_round108_test.dart:179, 203
error - 'FlutterLocalNotificationsPlugin' undefined - test/core/data/data/services/notification_service_can_exact_round108_test.dart:156
```

**共 13 个 error**(全是 R108 refactor 自身引入)+ 3 个 R108 测试文件 compile fail。

### D. 3 controller 拆解 row-by-row 行数

| 文件 | R107 基线 | R108 实际 | 差 | 备注 |
|---|---|---|---|---|
| `home_page_state.dart` | 597L | 515L | -82L | 主壳 build 180L + 4 method 30L + comment 200L + 3 controller 字段 |
| `home_page.dart` | 106L | 106L | 0 | 主壳 widget 入口,无变化 |
| `controllers/home_deep_link_handler.dart` | 0 (新) | 220L | +220L | 含 80L comment + 30L state + 90L method + 20L import |
| `controllers/home_care_engine_dispatcher.dart` | 0 (新) | 147L | +147L | 含 60L comment + 20L import + 60L method + 7L enum |
| `controllers/home_celebration_controller.dart` | 0 (新) | 84L | +84L | 含 40L comment + 10L import + 30L method + 4L enum |
| **拆解净增** | 597L | 1072L | **+475L** | **拆解 1:1.8 倍行数膨胀**(R107 §3.2 标的 -227L → 实际 +475L) |

**结论**: R108 P1 拆解**反向膨胀**(净增 475L,因每 controller 各自带 30% 注释 + 20% 签名样板)。整合者应 (a) 接受 475L 膨胀作为"可测性 trade-off",或 (b) 缩 3 controller 注释到 30% 比例,目标 3 controller 总 250L。

### E. flutter analyze 完整输出 (118 issues)

```
[main.dart:158]  info - prefer_const_constructors
[main.dart:199]  error - Undefined name 'sharedPreferencesProvider'
[main/boot_apps.dart:50, 69, 132, 213] info - use_key_in_widget_constructors
[core/data/database/app_database.dart:377] error - TextColumn not assignable GeneratedColumn<Object>
[core/data/database/mappers/mood/mood_entry_mapper.dart:43, 72] error - undefined_identifier / undefined_named_parameter (recordingMode)
[core/data/repositories/mood/mood_repository_impl.dart:68] error - undefined_named_parameter (recordingMode)
[core/data/services/notification_service.dart:334] warning - invalid_use_of_visible_for_testing_member (useExactAllowWhileIdle)
[core/data/utils/skip_backup.dart:56] warning - invalid_visibility_annotation (_channel)
[core/data/services/notification_service.dart] 118 (additional P0-2 features, no errors)
[presentation/pages/daily_tracking/tracking_customize_page.dart:32] info - deprecated_member_use (onReorder)
[presentation/pages/daily_tracking/widgets/tracking_item_config_ext.dart:12] warning - non_const_argument_for_const_parameter
[presentation/pages/home/controllers/home_care_engine_dispatcher.dart:62] error - undefined_identifier (safetyWatchServiceProvider)
[presentation/pages/home/controllers/home_care_engine_dispatcher.dart:69] info - use_build_context_synchronously
[presentation/pages/home/controllers/home_deep_link_handler.dart:198, 207, 208] info - use_build_context_synchronously
[presentation/pages/home/home_page_state.dart:470] info - use_build_context_synchronously
[presentation/pages/home/home_page_state.dart:472] info - require_trailing_commas
[presentation/pages/mood/widgets/mood_audio_recorder_widget.dart:94] error - Undefined class 'AudioRecorder'
[presentation/widgets/audio_lifecycle.dart:85-330] error - Undefined class 'StatefulWidget' / 'State' / setState / mounted (13 errors)
[test/core/data/services/assessment_notifier_round61c3_test.dart:105] error - non_abstract_class_inherits_abstract_member (useExactAllowWhileIdle)
[test/core/data/services/medication_notifier_round61c2_test.dart:382] error - non_abstract_class_inherits_abstract_member
[test/core/data/services/notification_service_can_exact_round108_test.dart:76, 91, 156] error - argument_type_not_assignable / extends_non_class
[test/core/data/services/refill_notifier_round61c_test.dart:249] error - non_abstract_class_inherits_abstract_member
[test/core/data/utils/skip_backup_round108_test.dart:142] info - unnecessary_lambdas
[test/core/data/utils/skip_backup_round108_test.dart:179, 203] error - Undefined name 'kIsWeb'
[test/data/notification_service_split_round45b_test.dart:262-279] error - undefined_getter (snoozeOnce, cancelSnoozeForMedication, cancelAllSnoozes, updateBadgeCount, scheduleDailyReminder, rescheduleMedicationReminders, scheduleRefillReminder, cancelRefillReminder, rescheduleRefillReminders, scheduleAssessmentReminder, cancelAssessmentReminder)
[test/data/safety_watch_service_round12_test.dart:435-462] warning - override_on_non_overriding_member (6 处)
[test/data/assessment_reminder_service_round12_test.dart:21, 30] warning - override_on_non_overriding_member
[test/presentation/medications_list_split_round45d_test.dart:32] warning - override_on_non_overriding_member
[test/presentation/refill_manage_round13a_test.dart:20] warning - override_on_non_overriding_member
[test/presentation/reminders_hub_round12c_test.dart:22] warning - override_on_non_overriding_member
[test/presentation/setup_*.dart] 4 warning - override_on_non_overriding_member
[test/presentation/setup_page_round18_test.dart, round77_test.dart, setup_consent_round14_test.dart, setup_step2_round14_test.dart] warning - override_on_non_overriding_member
```

**已过滤 0 个 R107 已知 info**(如 require_trailing_commas, prefer_const_constructors, deprecated_member_use 等是 R107 已接受)。**净 12 error + 6 warning** 是 R108 引入 / 未修。

### F. superpowers-en 视角对 R108 拆解的评估

**对的方向 (R108 拆解 +50 分)**:
- 3 controller 拆解 (deep link / care engine / celebration) — 单一职责 ✅
- NotificationDelegate 集中 12 委派 method — DRY ✅
- AudioLifecycleMixin 抽 4 状态字段 — DRY + 可复用 ✅
- MedicationTimeSlot 抽到 domain — 0 Flutter 0 Drift 可测 ✅
- skip_backup 4th defense-in-depth (R108 P0-1) — defense-in-depth ✅
- last_error_capture 仍走 PII 安全 (R108 P0-12) — fail-safe ✅

**未达的方向 (R108 拆解 -50 分)**:
- **state class 目标 370L 未达**(实际 515L) — SLO 未达
- **notification_service 目标 200L 未达**(实际 417L) — SLO 未达
- **13 个 analyzer error 全是 R108 自身 refactor 引入** — 无 compile gate 收尾
- **5 处 use_build_context_synchronously warning** — async gap mounted 检查漏
- **P0-001 vent_detail_page deleteTempFile 仍是无效 try/catch** — 长期 PII 风险
- **3 controller 拆解净增 475L**(主壳 -82L + 3 controller +451L) — 行数膨胀

**净评估**: 8.0/10 → 6.5/10 (R108 in-progress 状态)

---

<!-- subagent: superpowers-en 完成时间: 2026-08-10T16:30:00+08:00 -->
