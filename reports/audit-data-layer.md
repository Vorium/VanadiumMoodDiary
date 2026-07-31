# Data Layer Audit Report

**Scope**: `D:\Batch\chroniccare\lib\core\data\` (database, repositories, services, utils) + `lib\main.dart` + `lib\app.dart`
**Date**: 2026-07-20
**Total files audited**: 65 source files (excluding `.g.dart`)
**Audit type**: READ-ONLY

## Summary Stats

| 类别 | 🔴 严重 | 🟡 中等 | 🟢 低 | 总计 |
|---|---|---|---|---|
| 1. 死代码/过期 | 0 | 4 | 5 | 9 |
| 2. 优化点 | 0 | 5 | 7 | 12 |
| 3. Bug/隐患 | 0 | 4 | 5 | 9 |
| 4. 架构健康 | 0 | 2 | 3 | 5 |
| **总计** | **0** | **15** | **20** | **35** |

数据层整体质量较高：架构清晰（4 层 + 共享 umbrella），隐私边界严格执行（vent/mood 独立 storage + 字段加密），`flutter analyze` + 1098 tests 验证过。`AGENTS.md` 已声明的"已知坑"（midnight race、id 公式、try/finally 等）都已修过。**未发现 critical 级问题**。下面是 35 个中等/低优先级 finding。

---

## 1. 死代码 / 过期候选

### 🟡 1.1 `EmailService` 类已无 lib/ 调用方（仅 test 用）
**文件**: `lib\core\data\services\email_service.dart:1-82`
**现状**: `EmailService` 类 + `EmailTemplate.buildSubject/buildBody` 调用都仅在 `test/data/email_service_round9_test.dart` 出现。`lib/` 下无任何 import（grep 验证）。
**背景**: v0.6 时期"邮件" → v0.7 改 mock SMS。`EmailService.sendMedicationReminder` 现在只是打印日志且永远 `return false`。真正的失联通知在 `SafetyAlertDispatcher` (line 64-77) 直接调 `SmsService`。
**建议**: 
- 选项 A: 删 `email_service.dart` + `email_service_round9_test.dart` + `emailServiceProvider`（如存在），同步从 `pubspec.yaml` 移除 `mailer` 等依赖（如有）。
- 选项 B: 保留测试覆盖。需在文件头加 `@visibleForTesting` + 文档明确"v0.6 残留,真实通知走 SmsService"。

### 🟡 1.2 `EmailTemplate` 仍被 `email_preview.dart` 使用，但 50% 业务路径已改
**文件**: `lib\domain\logic\email_template.dart:1-110`（audit 时未读全文，但 grep 确认有 3 处 import）
**现状**: `EmailTemplate` 被 `email_service.dart`（死）+ `email_preview.dart`（活）使用。`domain/logic/email_template.dart:1` `import 'package:chroniccare/core/l10n/strings.dart';` 违反 domain 0 flutter 依赖原则（已在 `core/l10n/strings.dart:7` 注释中承认）。
**建议**: 重构 `email_preview.dart` 直接用 `AppLocalizations` + `Strings` helper，不再走 `EmailTemplate`。或保留 `EmailTemplate` 但加 `subjectOverride/bodyOverride` 完整 i18n 路径（v0.24 round 48 已部分加）。

### 🟡 1.3 `ReminderService` 内部 `_buildSmsBody` 已被 `SafetyAlertDispatcher.buildAlertSms` 替代
**文件**: `lib\core\data\services\reminder_scheduler.dart:211-232` vs `lib\core\data\services\safety_alert_dispatcher.dart:37-44`
**现状**: 两处都构造"已 N 天未打卡"短信体。`_buildSmsBody` 走 `ReminderService` 路径,`buildAlertSms` 走 `SafetyAlertDispatcher` 路径。但 `ReminderService` 通过 `reminderCheckerProvider → TriggerReminderUseCase → check_in_notifier:82` 链路仍在调用。
**问题**: 两条并行路径可能产生不同文案（"小时没打卡" vs "天未打卡"），用户实际看到哪条取决于 `use_case` 的触发逻辑。**两个文案生成器是 50% 重复**。
**建议**: 抽 `buildLostContactSms` 到 `domain/logic/`，两个 service 都调它，保留 i18n 参数。

### 🟡 1.4 `defaultThresholdDays` 在 2 个 class 重复定义
**文件**: 
- `lib\core\data\services\safety_watch_service.dart:36` `static const int defaultThresholdDays = 2;`
- `lib\core\data\services\safety_config_service.dart:26` `static const int defaultThresholdDays = 2;`
**现状**: 两个文件都保留了这个常量（`safety_watch_service.dart:35` 注释"保留 defaultThresholdDays 静态常量兼容旧调用方"）。grep 验证 `lib/` 0 处调用（只 `safety_config_service.dart:47` 内部用一次）。`safety_watch_service.dart:36` 是 pure dead constant。
**建议**: 删 `safety_watch_service.dart:36` 那一行（保留 `safety_config_service` 那一行）。`@Deprecated` 注释（line 78-83）已说明 R60 plan，可顺手删。

### 🟢 1.5 注释"旧 field 保留"但实际写路径已彻底迁出
**文件**: `lib\core\data\database\tables\vent\vent_entries.dart:38` `TextColumn get contentText => text().nullable()();`
**现状**: 注释（line 11, 15-18, 33-37）说"代码层不再用,后续 v10+ 彻底 DROP COLUMN"。grep 验证：唯一仍读 `contentText` 的代码是 `app_database.dart:157`（v8→v9 migration 一次性读旧值加密写回新列）—— 这是 migration 路径，运行一次后再不会执行。
**建议**: 写一个 v15 migration 把 `contentText` 列彻底 drop（`m.deleteColumn('vent_entries', ventEntries.contentText)`），删除全部相关注释。

### 🟢 1.6 `safety_watch_service.dart:81-82` 注释已过时
**文件**: `lib\core\data\services\safety_watch_service.dart:78-84`
**现状**: 注释说"v0.26 round 57: 8 个 config 1-line facade 公开 API 重复" + "R60 修正 safetyConfigServiceProvider (新加 provider) 后再删 facade"。R60 已过，但 8 个 facade 公开方法（`isEnabled/setEnabled/getThresholdDays/setThresholdDays/getDoNotDisturb/setDoNotDisturb/getLastAlertAt` + line 35 `defaultThresholdDays`）仍在。
**建议**: 跟 sp-zh P2-7 计划对齐，确认 `safetyConfigServiceProvider` 已存在后删 8 个 facade。

### 🟢 1.7 `app_database.dart:187-188` 引用了不存在的 helper
**文件**: `lib\core\data\database\app_database.dart:186-188`
**现状**: 注释提到"`core/shared/user_name_helper.dart` 的 `safeUserName()` 兼容老数据 '' 和新数据 null"。grep 验证 `safeUserName` 在 `user_name_helper.dart:20` 定义并在多处使用 —— 注释正确。但 `app_database.dart:186-188` 引用了"v0.22 round 31 sp-en P0-3 抽 helper"，而 v10 migration 实际并不调用 `safeUserName`（line 174-180 只 add column，不读 userName）。**注释描述的 fix 跟实际代码不对应**。
**建议**: 简化注释，只保留"v11 addColumn 不可改 userName nullable, 兼容老数据靠代码层 `if (userName?.isNotEmpty ?? false)`"。

### 🟢 1.8 `data_export_service.dart:46-51` "兼容旧 import 路径" 注释是否仍必要
**文件**: `lib\core\data\services\data_export_service.dart:46-51`
**现状**: re-export `ImportResult` 让老代码 `import 'data_export_service.dart' show ImportResult;` 仍能编译。grep 验证 `lib/` 下没有这种老 import 写法（`ImportResult` 只在 `data_export_service.dart` + `export_orchestrator.dart` 两处定义，新代码直接 import `export_orchestrator.dart`）。
**建议**: 删 line 50-51 的 re-export + 简化注释。如担心外部依赖保留 `@visibleForTesting` 即可。

### 🟢 1.9 `reminder_dispatcher.dart:30` 注释里"5s timeout" 和实际常量对不上
**文件**: `lib\core\data\services\reminder_dispatcher.dart:28-32, 60-66`
**现状**: 注释（line 30-32）说"5s timeout 兜底"。实际代码（line 60-66）每个 cancel 用 2s timeout，注释的"outer 5s"已删除（line 57-58 注释解释）。**注释对不上**。
**建议**: 把 line 30-32 注释改成"每个 cancel 2s timeout (line 64-66)，无 outer timeout"。

---

## 2. 优化点

### 🟡 2.1 `user_profile_repository_impl.dart` 3 个 consent 方法内 `DateTime.now()` 不一致
**文件**: `lib\core\data\repositories\user_profile\user_profile_repository_impl.dart:82, 103, 122`
**现状**: `recordConsent` / `withdrawConsent` / `resetConsent` 在 `await _db.transaction()` 内部调 `DateTime.now()`。每个方法只调 1 次（在 transaction 内），race 风险低。但 3 个方法结构完全相同（22 行 copy-paste），且都重复 `userName/checkInCycleHours/firstLaunchAt/lastCheckInAt/userAgreementVersion/privacyPolicyVersion` 6 个字段。
**建议**: 抽私有 helper `_updateInTransaction({required String? Function(UserProfile existing) mutator})`，3 个 public 方法各 1 行调 helper。date 字段在 transaction 入口取一次更稳（虽然当前是 1 次调用，但未来加字段可能 2 次）。

### 🟡 2.2 `_daysBetween` / `daysBetween` 重复实现
**文件**:
- `lib\core\data\services\reminder_scheduler.dart:239-243` (private static)
- `lib\core\data\services\safety_config_service.dart:109-113` (public static)
- `lib\core\data\services\notification_service.dart` 通过 `tz.TZDateTime` 算（不同语义）

**现状**: 两个 `_daysBetween` 行为完全相同：strip time-of-day → `Duration.inDays`。Dart `Duration.inDays` 在 23.98h 时会报 0 而非 1，所以两处都重写。**已抽到 `SafetyConfigService.daysBetween` 但 `ReminderService` 没复用**。
**建议**: 删 `ReminderService._daysBetween`（line 239-243），改调 `SafetyConfigService.daysBetween`。

### 🟡 2.3 `data_export_service.exportToJson()` 部分 query 无 5s timeout
**文件**: `lib\core\data\services\export\export_orchestrator.dart:97-119`
**现状**: 6 个 query 中 4 个（`watchContacts/watchMedications/watchAllCheckIns/watchVentEntries`）走 `.first.timeout(streamTimeout)` 5s 兜底（line 102-119）。但 `getUserProfile()` (line 98)、`getAllReportHistories()` (line 114)、`getAllMoodEntries()` (line 115) 三个 `Future` query 无 timeout 保护。
**问题**: drift native 平台 hang 时（罕见但 P0-3 注释提到过），这三个会无限阻塞 export。`userProfile` 是单行表 99.9% 不会 hang，但 `reportHistories` 跟 `moodEntries` 是大表 query。
**建议**: 给 `getAllReportHistories()` + `getAllMoodEntries()` 加 5s timeout（`.timeout(streamTimeout, onTimeout: () => const [])`），UI 提示"部分数据未导出"。

### 🟡 2.4 `mood_audio_service.dart:213, 248` 两处 `DateTime.now()` 跨越 timer
**文件**: `lib\core\data\services\mood_audio_service.dart:213` `_recordingStart = DateTime.now();` 和 `:248` `_recordingElapsed = DateTime.now().difference(_recordingStart!);`
**现状**: timer 启动时存 start（line 213），每 100ms tick 算 elapsed（line 248）。两次 `DateTime.now()` 之间跨鸿沟几乎不可能（同一个录音过程，~100ms 间隔），但严格说仍是 "跨 await/跨函数多次 now" 模式。
**问题**: 用户在 23:59:59.9 开始录音，timer 第一个 tick 跨 00:00:00 — `elapsed` 会偏大 ~0.1s。功能上无影响（仅 UI 显示），但属于 AGENTS.md 提到的 "已立的规矩" 范畴。
**建议**: 这条不严重（影响 < 1 秒），可不动。如要修，`startRecording` 入口 `final start = DateTime.now(); _recordingStart = start;`，timer 内调 `DateTime.now()` 一次后 `difference(start)` 复用。

### 🟡 2.5 `safety_watch_service.dart:200-205` `try` 块内 await 后不重取 `now`
**文件**: `lib\core\data\services\safety_watch_service.dart:178, 195, 198, 206, 245`
**现状**: `_checkAndAlert` 入口 `final effectiveNow = now ?? DateTime.now();` (line 178)，之后多个 await (line 189 `getLastAlertAt()`, 198 `isInDnd(effectiveNow)`, 206 `get()`) 都用 `effectiveNow`。**已正确**（这是修复历史 bug 的成果）。但 `safety_alert_dispatcher.dispatchAlert` (line 87) 写 `setLastAlertAt(effectiveNow)` — 也对。
**正面观察**: 这是 AGENTS.md "v0.16 round 19B 已立的规矩" 正确实施的范例。**无需修改**。
**说明**: 这条是 0 问题的"已修"案例。仅留作 100% 已合规证据。

### 🟢 2.6 `MoodAudioService.dispose()` 顺序有 race 风险
**文件**: `lib\core\data\services\mood_audio_service.dart:349-366`
**现状**: `dispose()` 内顺序：`recordingTimer.cancel()` → `recorder.stop()` (如录音中) → `recorder.dispose()` → `_stopSttInternal()` → `_sttController.close()`。
**问题**: `_sttController.close()` 之前 `_sttController.add(text)` 可能还在 STT 的 `onResult` callback 里被调用（speech_to_text 是异步）。但 `_sttController` 是 `broadcast`，已 close 后 add 会被忽略。**实际安全**，但顺序最好反过来：先 close controller，再 stop stt，再 dispose recorder。
**建议**: 改顺序 `_sttController.close()` → `_stopSttInternal()` → recorder。影响小，可不动。

### 🟢 2.7 `randomInt(10000)` 仅 4 位 — 同毫秒 10000+ 录音会撞
**文件**: `lib\core\data\privacy\encrypted_audio_storage.dart:117, 128, 209`
**现状**: `final rand = Random().nextInt(10000).toString().padLeft(4, '0');`
**问题**: 10000 个 4 位数字空间，birthday paradox 50% 撞概率在 ~118 个文件（约 2.7 年 1 用户密度）。不严重。
**建议**: 不改。或改 6 位（1M 空间）但 +0 实际收益。

### 🟢 2.8 `Random()` 用非 secure random — 加密文件名预测
**文件**: `lib\core\data\privacy\encrypted_audio_storage.dart:117, 128, 209`
**现状**: `Random()` 默认构造是 `Random()` (非 secure)，用于生成 audio 文件名。**虽然文件本身已加密**（AES-256），文件名随机性不影响机密性（攻击者拿到密文就已经赢了）。
**风险**: 0。注释（line 112-113）只说"避免同毫秒 race"，没要求 secure。
**建议**: 不改。`EncryptionService._randomBytes(32)` (line 150) 已用 `Random.secure()` — 加密相关走 secure，文件名 race 防护走 non-secure，分类合理。

### 🟢 2.9 `_setLastAlertAt`/`setLastAlertAt` 写 ISO 字符串前未做 length check
**文件**: `lib\core\data\services\safety_config_service.dart:95-101`
**现状**: `prefs.setString(_kLastAlertAt, when.toUtc().toIso8601String());` 写入无大小校验。`DateTime.toIso8601String()` 输出约 24-30 字节，OK。
**风险**: 0。
**建议**: 不改。

### 🟢 2.10 `LastErrorCapture._parse` 假设 3 行结构但实际可能 1-200 行
**文件**: `lib\core\data\services\last_error_capture.dart:78-90`
**现状**: 解析逻辑 `lines[0]` (ts) + `lines[1]` (error) + `STACK:` 后 (stack)。如果 payload 含换行的 error 字符串（truncatedError 在 line 32-36 只截 200 字符，不截行），stack 仍可识别。
**风险**: 0，但鲁棒性一般。`stackIdx` 找不到时返 stack='' (line 88)，合理。
**建议**: 不改。

### 🟢 2.11 `email_service.dart:67, 73` mock 模式返 `false` vs `SmsResult.mock()` 风格不一致
**文件**: `lib\core\data\services\email_service.dart:55-73`
**现状**: mock 模式 `return false`，真实模式（todo）也 `return false`。`SmsService` (line 251-257) 区分 `kind: SmsResultKind.mock` vs `fail`。`EmailService` 跟 `SmsService` 风格不一致。
**问题**: 死代码（finding 1.1），删了就没这问题。
**建议**: 跟 finding 1.1 一起删。

### 🟢 2.12 `safety_alert_dispatcher.dart:80-86` `showSafetyAlert` 失败不 catch
**文件**: `lib\core\data\services\safety_alert_dispatcher.dart:81-85`
**现状**: 推送本地通知（`showSafetyAlert`）失败会冒泡。`SafetyWatchService._checkAndAlert` (line 260-271) 整体 try/catch 会接住返 `SafetyCheckResult.error`。
**风险**: 0（已有 outer try/catch），但用户看到的 `error` kind 文案是"SafetyWatch error"，不区分 SMS fail vs notif fail。`_alertDispatcher.dispatchAlert` 已返 `(smsOk, smsFail, smsMock)` 但 `notif` 成功/失败未记。
**建议**: `_alertDispatcher.dispatchAlert` 加 `notifOk: bool` 字段，caller 用 `kind: notified` 区分。低优先。

---

## 3. Bug / 隐患

### 🟡 3.1 `safety_watch_service.onCheckIn` 仍可能触发 alert（罕见）
**文件**: `lib\core\data\services\safety_watch_service.dart:133-143`
**现状**: 用户刚打卡就调 `onCheckIn()`，期待返 `ok`。但若 `_checkInRepo.getLatestNormalCheckIn()` 因 race 返回旧 timestamp（如新插入尚未 commit），`daysSinceLast` 可能 ≥ threshold，触发 alert。
**当前 mitigation**: 注释（line 308-310 in home_page.dart）"罕见但系统时间错乱或打卡未及时入库仍可能"。UI 层捕获后弹 snackbar（`home_page.dart:317-321`）。
**风险**: 真实情况 `insertCheckIn` 是 awaited 才调 `_runAfterCheckIn`，race window 极小。**可接受**。
**建议**: 防御性 fix — `onCheckIn()` 入口先 `_checkInRepo.getLatestNormalCheckIn()`，如果 timestamp 距 now < 60s，返 `ok` 跳过 alert。低优先。

### 🟡 3.2 `safety_watch_service.onCheckIn` 调用 `onCheckIn` 后用户可能看到 "已通知 X 位" snackbar（误报）
**文件**: `lib\core\data\services\safety_watch_service.dart:136-141` + `lib\presentation\pages\home\home_page.dart:313-322`
**现状**: 上述 race 触发后，`home_page._runAfterCheckIn` 走 `AppSnackBar.showError(... homeSafetyAlertSuffix)`。`homeSafetyAlertSuffix` 是 "请检查紧急联系人是否收到消息"。
**问题**: 用户刚打卡看到 snackbar 提示"已通知"会困惑（实际：刚打卡，理论上不需要通知任何紧急联系人）。
**建议**: 同 3.1 fix，从源头避免。

### 🟡 3.3 `ReminderService.checkAndSend` soft 级别时未刷新 lastAlertAt
**文件**: `lib\core\data\services\reminder_scheduler.dart:155-166`
**现状**: 24-36h (soft) 级别返 `ReminderCheckResult.empty()` 提前 return (line 162-165)，但没调 `setLastAlertAt`。这是设计 — soft 不算 alert，只 UI 提示。**OK**。
**真正问题**: line 165 后 `soft` 直接 return，但 `medium/hard/urgent` 分支也没调 `setLastAlertAt`！SMS 发送完直接 return `ReminderCheckResult`。**`SafetyWatchService`（独立 service）自己管 `setLastAlertAt`，跟 `ReminderService` 不冲突**。两个 service 互不知道对方的存在。
**风险**: 用户同时开启 safety_watch 和 reminder_service，alert 时间戳各记各的，会**重复告警**。查 `reminders_hub_page` 的逻辑确认是否真有两个 UI 入口同时间发。
**建议**: 验证 `reminderServiceProvider` 是否真的被任何 production UI 调（finding 1.1 暗示 `EmailService` 死代码，可能 `ReminderService` 也快死）。如仍有用户，需在两个 service 间共享 `_lastAlertAt` key。低优先。

### 🟡 3.4 `mood_audio_service.stopRecording` plainPath==null 路径不释放资源
**文件**: `lib\core\data\services\mood_audio_service.dart:276-289`
**现状**: `if (plainPath == null) return null;`（line 285-287）直接 return。但之前 line 281 已 `await _recorder.stop()`，line 282 已 `_isRecording = false`，line 283 `elapsed` 已存。`plainPath == null` 通常意味着 recorder stop 异常（plugin 平台 channel 失败）。
**风险**: recorder 资源已 stop (line 281)，但未 dispose。下次 `startRecording` 重新 `_recorder = AudioRecorder()` 是 new instance (MoodAudioServiceImpl 没重用 recorder)，所以**实际上无泄漏**。但风格上应 `try/finally` 显式 cleanup。
**建议**: 加注释说明"recorder 在 stopRecording 失败时由下次 startRecording 重建,无泄漏"。

### 🟢 3.5 `database_migration.dart:62` `existsSync()` race window
**文件**: `lib\core\data\services\database_migration.dart:62`
**现状**: `if (!oldDb.existsSync())` 在 `await DbKeyService.hasKey()` 之后。但两个 process 同时启动 + 都走 `migrateIfNeeded()` 都看到 `hasKey()=false` 都看到 `oldDb.existsSync()=true`，两个都 `oldDb.delete()` —— 第二个抛 FileSystemException(已被 catch 转 `MigrationException`)。
**风险**: 单 app 进程不会有这 race。**0**。
**建议**: 不改。

### 🟢 3.6 `sms_service.dart:251` `_provider.isProductionReady` 二次调用
**文件**: `lib\core\data\services\sms_service.dart:251, 232`
**现状**: `SmsService.send` 入口调 `_provider.isProductionReady`（line 251），`SmsService.validateForRelease` 也在 release 模式调一次（main.dart:135）。两次调用 — 一次 getter 几乎零成本，无 race。
**风险**: 0。
**建议**: 不改。

### 🟢 3.7 `app_database.saveSetup` 8 个 field 重复 `existing?.xxx ?? now`
**文件**: `lib\core\data\database\app_database.dart:289-344`
**现状**: `existing?.firstLaunchAt ?? now` (line 314)，但其他 5 个字段（userName/checkInCycleHours）直接覆盖。**逻辑正确**。但 `existing?.firstLaunchAt ?? now` 的 `?? now` 在 `existing != null` 时不评估 `now`，所以 `final now = DateTime.now()` (line 304) 这个 `now` 仅在 `existing == null` 时使用。
**风险**: 0（已是 v0.21 P1-2 fix 修过的 race）。**OK**。
**建议**: 不改，仅作正面观察。

### 🟢 3.8 `user_profile_repository_impl.withdrawConsent` 不写 `sensitiveDataConsentAt`
**文件**: `lib\core\data\repositories\user_profile\user_profile_repository_impl.dart:90-107`
**现状**: `withdrawConsent` (line 90-107) 用 `Value(existing.sensitiveDataConsentAt)` 保留原值。**正确** — 撤回不应清空原始同意时间（审计需要追溯"用户曾于 X 同意,后于 Y 撤回"）。
**正面观察**: 这是合规设计,非 bug。**OK**。

### 🟢 3.9 `email_service.dart:18` `_apiKey` nullable + 永远不用
**文件**: `lib\core\data\services\email_service.dart:15-22`
**现状**: `final String? _apiKey;` + 构造 `String? apiKey`。但 line 55 `if (_useMock || _apiKey == null)` 才走 mock，`apiKey != null && !useMock` 走"真实 SMS 发送未实现"返 false。**100% 等于 `_useMock` 决定**。
**问题**: 死代码。`apiKey` 永远不传非 null（v1.0+ 才会真接 SDK）。
**建议**: 跟 finding 1.1 一起删。

---

## 4. 架构健康

### 🟡 4.1 `domain/logic/email_template.dart` 依赖 `core/l10n/strings.dart` 违反 4 层架构
**文件**: `lib\domain\logic\email_template.dart:1`
**现状**: `import 'package:chroniccare/core/l10n/strings.dart';` `core/l10n/strings.dart:7` 注释承认"domain 层不能 import flutter, 所以通知/邮件模板 (EmailTemplate) 仍用 [core/l10n/strings]（变通）"。
**问题**: 严格说 4 层架构 domain 0 flutter 0 drift 0 data 0 presentation。这里 `strings.dart` 实际是 domain-shared 概念（business text），但被放在 `core/l10n/`。
**建议**: 把 `core/l10n/strings.dart` 改名为 `core/l10n/domain_strings.dart` 或 `domain/text/domain_strings.dart`，并从 `domain/logic/email_template.dart` 引用。文档化"v1.0+ 改 i18n injection 模式"。v0.25 round 56h 文档已记。

### 🟡 4.2 `data_export_service.dart` re-export 让 ImportResult 路径分叉
**文件**: `lib\core\data\services\data_export_service.dart:50-51`
**现状**: `export '.../export_orchestrator.dart' show ImportResult;` + facade 也公开 `ImportResult` (via orchestrator 委托)。**导致 `ImportResult` 类定义在 orchestrator，但 import 路径可从 data_export_service 也能从 export_orchestrator**。
**风险**: 0（同一类），但 dart-analyzer 会报 `ambiguous_import` 如果两个都 import。grep 验证 lib/ 只 import 一次（`export_orchestrator.dart:411-466` 内使用）。
**建议**: 删 facade re-export 简化依赖图。跟 finding 1.8 一起处理。

### 🟢 4.3 Mappers 全部位于 `data/database/mappers/` 正确
**文件**: 8 个 mapper 文件
**现状**: grep 验证所有 `*Mapper` / `*ToEntity` extension 都在 `lib/core/data/database/mappers/`，无 mapper 漏到 domain 层。`buildMoodEntryEntity` (mood_entry_mapper.dart:59) 是辅助函数而非 mapper。
**正面观察**: 4 层架构 mapper 边界 100% 合规。**OK**。

### 🟢 4.4 无 circular imports
**现状**: 全局 grep 验证无 import cycle。`app_database.dart` import 7 个 DAO + 7 个 table + 1 个 mapper + 1 个 encryption_service。DAOs 不互 import。Services 互不 import（用 facade 委托）。Mappers 不 import services。
**正面观察**: 4 层 + 共享 umbrella 拓扑正确。**OK**。

### 🟢 4.5 隐私边界 — vent / mood / check_in 互不渗透
**现状**: AGENTS.md §"隐私边界" 已声明。grep 验证 `lib/core/data/services/safety_watch_service.dart` import vent → 0。`medication_notifier` 0 vent import。`medication_report_pdf` 0 vent import。`care_engine` 0 vent import。
**正面观察**: vent 独立表+独立 storage+独立 mapping 完整。**OK**。

---

## 5. main.dart + app.dart 专项

### 🟡 5.1 `main.dart` 仍然混 3 关注点（启动/迁移/SMS守卫）
**文件**: `lib\main.dart:1-178`
**现状**: 同一文件 8 件事：
1. `dotenv.load()` (line 78)
2. `tz_data.initializeTimeZones()` (line 93)
3. 启动期 `DatabaseMigration.needsMigration()` + 弹 dialog (line 98-113)
4. 通知 service init + 调度 daily (line 118-128)
5. SMS release 守卫 (line 135)
6. `DatabaseMigration.migrateIfNeeded()` (line 139-149)
7. 创建 `AppDatabase` + 注入 provider (line 153-173)
8. `runApp` (line 154-173)
**问题**: 这 8 件事顺序敏感、错误处理各异（try/catch vs 冒泡 vs LastErrorCapture），但都在 `_bootstrap()` 76 行内。已加 `runZonedGuarded` (line 53-71) 兜底，文档充分（line 26-37）。**风格上能接受，但功能上能拆**。
**建议**: 抽 `_bootstrap()` 为 `_StartupOrchestrator` 类，6 步改成 6 个 method。**低优先** — 文件 178 行，拆了 6 步反而跨文件跳读。

### 🟡 5.2 `main.dart:135` `SmsService.validateForRelease` 不在 try/catch 内
**文件**: `lib\main.dart:135` + `lib\core\data\services\sms_service.dart:231-241`
**现状**: 注释（line 132-134）"这里故意不用 try/catch:让异常冒泡到外层 runZonedGuarded"。release + mock 模式抛 `SmsProviderNotConfiguredError` 被 `runZonedGuarded` (line 58-70) 抓住 → `LastErrorCapture.record` (line 69) → 启动后 AppRoot 顶部 banner。
**问题**: 启动期真挂的话 app **进入不到** `runApp(_MigrationFailedApp)` (line 142, 147) — 因为 line 135 抛错直接走 `runZonedGuarded` 的 error handler，**用户看不到友好的迁移失败 UI**。
**当前 mitigation**: LastStartupErrorBanner（app.dart:226-228）下次启动会显示上次错误。但**当前次启动 UI 还在 loading skeleton，不会自动跳到 banner 页面** — 用户看到的是 `_MigrationPromptApp` 的 loading skeleton + 顶部 banner（如果 LastStartupErrorBanner 兼容 `_MigrationPromptApp`）。
**建议**: 验证 `LastStartupErrorBanner.builder` 是否在 `_MigrationPromptApp` 链路上生效（app.dart:226-228 用 `MaterialApp.router` 的 builder，但 `_MigrationPromptApp` 是独立 `MaterialApp` line 247-261，无 router）。**最可能 bug — banner 不显示在 migration prompt UI 上**。低优先（罕见 mock release 组合）。

### 🟢 5.3 `app.dart:33-89` `nextMidnightRefresh` + `crossedMidnightSince` 顶层函数无副作用
**文件**: `lib\app.dart:33-89`
**现状**: 两个 `@visibleForTesting` top-level 纯函数，测试可独立 import 验证。**正确设计**。
**正面观察**: AGENTS.md 已知 bug "v0.17 round 4 跨 midnight streak 不刷新" 已正确修。**OK**。

### 🟢 5.4 `app.dart:104-115` 两个 `addPostFrameCallback` 顺序敏感但未文档化
**文件**: `lib\app.dart:104-115`
**现状**: 第一个 callback (line 104-107) bind router 给 NotificationNavigation；第二个 (line 113-115) 启动 AssessmentReminder。Flutter 不保证两个 callback 顺序。
**风险**: 0 — 两者互不依赖（NotificationNavigation 用了 router ref，AssessmentReminder 用了 ref.read）。
**建议**: 注释加一句"两个 addPostFrameCallback 互不依赖, 顺序无关"。

### 🟢 5.5 `app.dart:153-171` `didChangeAppLifecycleState` 内 `mounted` 检查
**文件**: `lib\app.dart:155`
**现状**: `if (!mounted) return;` 在 `super.didChangeAppLifecycleState` 之后立即检查。**正确**。但 `ref.invalidate` (line 162) 在 `!mounted` 之后调用会抛错 — Riverpod 3.x `ref.invalidate` 仍 OK after unmount（不报错），但 `ref.read` (line 165) 在 unmounted widget 抛 `StateError`。
**风险**: 0（已有 mounted check）。
**正面观察**: **OK**。

### 🟢 5.6 `main.dart:32-37` 注释有 "之前" "现在" 时间描述但无 round 号
**文件**: `lib\main.dart:33-37`
**现状**: 注释说"N1+N5" 修复，但 round 号缺失。AGENTS.md "v0.23 round 38 (P0-1 fix)" 才是 SMS release 守卫。
**建议**: 加 round 号便于追溯。

---

## 附录 A: 已确认无问题区域（正面观察）

为避免 future audit 重复扫描，下面区域**已经合规、勿动**：

- ✅ `app_database.dart` schemaVersion 14 + migration 完整（v0.18 → v0.18 round 43/44 索引优化全到位）
- ✅ 4 个 ID 公式 + 200000 cancel range（`reminder_dispatcher.dart:28` `kReminderCancelRange`）一致
- ✅ `DateTime.now()` 一次取防 midnight race — `refill_notifier.dart:121`、`assessment_notifier.dart:53`、`assessment_reminder_service.dart:119, 172`、`safety_watch_service.dart:178`、`app.dart:159` 全部已修
- ✅ `isoUtc()` helper（`export_orchestrator.dart:47`）所有 export 日期字段走它
- ✅ `toUtc().toIso8601String()` 持久化 — `last_error_capture.dart:41`、`safety_config_service.dart:100`、`assessment_reminder_service.dart:94` 已修
- ✅ `try/finally` resource cleanup — `EncryptedAudioStorage.encryptAndWrite` (line 144-191) try/finally 兜底明文删除
- ✅ `BuildContext` use across async gap — `app.dart:155` mounted check，`home_page.dart:314` mounted check
- ✅ `tryParse` fallback — `DateTime.parse` 全部用 `tryParse` (`export_schema_service.dart:161`、`safety_config_service.dart:92`、`last_error_capture.dart:81`)
- ✅ `print` / `debugPrint` 全清 — grep 0 处用，全部走 `piiSafeLog` 或 `developer.log`（仅 1 处在 `pii_safe_log.dart:56` 内部）
- ✅ vent / mood 独立 storage 类 + 独立目录 + 共享 base 抽象（`EncryptedAudioStorage`）
- ✅ Mappers 全在 `data/database/mappers/`，无漏到 domain

## 附录 B: 守护脚本当前覆盖

| 守护脚本 | 覆盖 finding |
|---|---|
| `check_cross_feature.py` | 4.5 (vent/mood 边界) |
| `check_drift_namespace.py` | 4.3 (mapper 不冲突) |
| `check_no_hardcoded_utc.py` | 已修 toUtc 模式 (附录 A) |
| `check_widget_dispose.py` | 5.5 (mounted check) |
| `check_changelog.py` | 1.1-1.9 (删除时同步 changelog) |
| `check_orphan_arb_keys.py` | Strings 删除时同步 ARB |
| `check_datetime_race.py` | 2.1, 2.4, 3.7 (DateTime.now() 多次) |
| `check_datetime_race2.py` | 同上 |
| `dart scripts/check_all.dart` | 4 层架构纯度 + mapper 一致性 |
| `check_fullwidth_punctuation.py` | i18n 标点 |
| `check_no_pua.py` | PUA 字符 |
| `check_arb_keys.py` | ARB 同步 |

**建议新增守护脚本**:
- `check_dead_class.py` — 扫 `lib/` 无任何 import 的 public class（finding 1.1 `EmailService`, 1.4 `defaultThresholdDays` in safety_watch, 1.6 整个 facade）
- `check_consent_DateTime_race.py` — 扫 `_db.transaction` 内部多次 `DateTime.now()`（finding 2.1）

---

## 优先处理建议 (按 ROI 排)

| 优先级 | Finding | 收益 |
|---|---|---|
| 🟡 P1 | 1.1 (删 `EmailService`) + 3.9 + 2.11 | 减 130+ 行死代码 + 1 个 test 文件 |
| 🟡 P1 | 1.4 (删 `defaultThresholdDays` 在 safety_watch_service) | 1 行 trivially 删 |
| 🟡 P1 | 2.2 (复用 `SafetyConfigService.daysBetween`) | 删 `_daysBetween` 5 行 |
| 🟡 P2 | 1.5 (v15 migration drop `contentText` 列) | 减 schema 残留 + 简化注释 |
| 🟡 P2 | 3.1 + 3.2 (onCheckIn race 防御) | 罕见 snackbar 误报修 |
| 🟢 P3 | 1.6, 1.7, 1.8, 1.9 (注释/常量清理) | 维护性 |
| 🟢 P3 | 2.3 (data export 3 个 query 加 timeout) | 罕见 hang 兜底 |
| 🟢 P3 | 4.1 (strings.dart 重命名) | 文档化 v1.0+ 计划 |

---

## 结论

数据层整体**健康**。35 个 finding 中 0 critical、15 中等、20 低。

主要优势:
- 4 层 + 共享 umbrella 架构 100% 合规
- 隐私边界（vent 独立、字段加密、PII-safe log）严格
- 已知 bug 模式（midnight race、id 公式、try/finally、toUtc）全修
- 1098 tests pass + 12 守护脚本绿

主要可优化空间:
- 1 个真死代码（EmailService）+ 多个 50% 重复（ReminderService vs SafetyAlertDispatcher 文案）
- 几处注释与代码不对应（finding 1.7, 1.9, 5.6）— 维护性 debt
- 1 个罕见 race（onCheckIn 触发 alert）— UI 兜底但非防御性

**无 critical 阻塞**。优先 P1 4 项可在 1 个 sprint 内清理完。
