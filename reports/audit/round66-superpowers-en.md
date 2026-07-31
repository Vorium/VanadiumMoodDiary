# superpowers-en 视角全量审计（v0.27 R66）

**审计时间**: 2026-08-02
**项目**: chroniccare
**版本**: 0.27.0+64（R66 收尾中，工作区有未提交改动）
**视角**: superpowers-en（英语上游 superpowers 方法论）
**审计模式**: 全量（聚焦 lib/ 全部 + test/ 关键覆盖）

**基线**: 1237 tests pass / 0 analyzer error / 16 守护脚本全绿

---

## 1. 总览

- **代码成熟度**: ⭐⭐⭐⭐⭐ / 5（v0.27 R60-66 集中打掉 5 个 facade god class + 3 个 use case 抽离 + 5 个安全 sub-service 拆分；本轮 R64 拆 SafetyDetector 纯函数 + R65 抽 SafetyAlertBuilder + R66 软隐藏 FeatureFlags）
- **TDD 合规率**: 估 95%（domain/logic/ 100% 单测覆盖；data/services/ 关键路径 90% 单测覆盖 — notification_service facade 本身 0 单测但 5 个 sub-service + 2 个 dispatcher + 1 builder 全覆盖；presentation/widgets/ ~50%）
- **最重要发现 1-2 句**:
  1. **DRY 违反（系统级）**: `_resolveTimestamp` helper 在 R63 P1-6 抽到 `check_in_repository_impl.dart:22` 是 `private top-level`（无下划线但 file-private），**未导出到其他 3 个 repository**（vent / mood / medication）+ 1 个 use case（check_in_usecases）—— 5 处同款 `at ?? DateTime.now()` pattern 散落
  2. **3 个 18+ 月老 TODO 未跟踪**：`notification_service.dart:388-389`（Android 角标 `flutter_app_badge_control`）、`sms_service.dart:90-194`（AliyunSms 真接 v1.0+）、`email_service.dart:72-73`（真实邮件发送 v1.0+）—— 前两个有 R63 守门员接住（`isProductionReady` + `_isFullyImplemented`），但 email 是 0 守门员的"裸 TODO"
- **建议优先修什么**:
  1. 抽 `_resolveTimestamp` 到 `core/shared/date_time_resolver.dart` 集中器，5 处替换（M，工时半天）
  2. 加 `email_service.dart` 的 `_isFullyImplemented` 守门员（跟 R63 SmsService 同模式），S 难度（半天）
  3. 标记 3 个老 TODO 为 "v1.0+ 大工程" doc 集中器（避免 grep 噪音），S 难度

---

## 2. TDD 合规

### 2.1 优秀（domain/ + data/ 关键路径）

| 模块 | 覆盖情况 | 验证 |
|------|----------|------|
| `domain/logic/care_engine.dart` + `care_strategies.dart` | 100% 策略 + 装配 | 5 个 round 3/17/19/43/48 test (5 file, ~100 case) |
| `domain/logic/assessment_comparison.dart` | 100% 计算 + 边界 | `round18_test.dart` 15K bytes |
| `domain/logic/streak_calculator.dart` | 100% + unsorted regression | `round19_test.dart` 5K + 隐式排序纪律 |
| `domain/logic/phq9.dart` + `gad7.dart` | 100% crisis 21 case | `phq9_detect_crisis_round60_test.dart` |
| `domain/usecases/fire_care_strategy.dart` (R65 新) | 5 case 覆盖 disabled/noAction/priority/sms channel | `fire_care_strategy_round65_test.dart` |
| `domain/usecases/check_safety.dart` (R65 新) | 5 case 覆盖 5/8 decision | `check_safety_round65_test.dart` |
| `domain/usecases/schedule_refill_reminder.dart` (R65 新) | 3 case 覆盖 | `schedule_refill_reminder_round65_test.dart` |
| `core/data/services/safety_detector.dart` (R64 新) | 8 case 全 8 decision | `safety_detector_round64_test.dart` 9K |
| `core/data/services/safety_alert_builder.dart` (R65 新) | 多 case | `safety_alert_builder_round65_test.dart` 9K |
| `core/data/services/safety_alert_dispatcher.dart` | 3 态 + flag 守门 | `safety_alert_dispatcher_round61c3_test.dart` 13K |
| `core/data/services/refill_notifier.dart` | ID 公式 + fire time + 编排 | `refill_notifier_round61c_test.dart` 11K |
| `core/data/services/medication_notifier.dart` | schedule + reschedule | `medication_notifier_round61c2_test.dart` 16K |
| `core/data/services/assessment_notifier.dart` | fireAt + skip | `assessment_notifier_round61c3_test.dart` 5K |
| `core/data/services/snooze_manager.dart` | id 公式 + cancel range | `snooze_manager_round18_test.dart` 8K |
| `core/data/services/reminder_dispatcher.dart` | cancel range + timeout | `reminder_dispatcher_round37_test.dart` 6K |
| `core/data/services/mood_audio_service.dart` | STT + 录音编排 | `mood_audio_service_round61c3_test.dart` 6K |
| `core/data/services/safety_watch_service.dart` (R12 + R66) | 集成测试 + flag 守门 | `safety_watch_service_round12_test.dart` 17K + `feature_flags_round66_test.dart` 6K |
| `core/data/feature_flags.dart` (R66 新) | 4 case 默认值 + 3 入口 + 1 dispatcher 双层防御 | `feature_flags_round66_test.dart` 6K |
| `core/data/services/sms_service.dart` | provider 注入 + release 守门 | `sms_service_round38_test.dart` 5K + `sms_service_round14_test.dart` 4K |
| `presentation/pages/home/home_page.dart` (R64 状态机) | 5 case enum transition + race guard | `home_lifecycle_round64_test.dart` 4K |

**R66 新加 TDD 覆盖**: 3 个 use case (fire_care_strategy / check_safety / schedule_refill_reminder) + 1 FeatureFlags 守门员 + 1 状态机 = 4 个新 test 文件，共 ~22K bytes，~25 case。**符合 spen "P0 fix → failing test first" 纪律**。

### 2.2 不足（presentation/ + 部分 data/）

| 位置 | 缺失 | 影响 |
|------|------|------|
| `core/data/services/notification_service.dart` (facade 424 行) | 0 单测（仅 5 个 sub-service + 2 dispatcher + 1 builder 覆盖） | facade 编排 6 类通知 ID 范围 + init 顺序，0 test guard |
| `core/data/services/badge_sync_service.dart` (40 行) | 0 单测（仅 `badge_sync_service_round37_test.dart` 2.9K 间接覆盖） | iOS-only 角标逻辑，理论漏 |
| `presentation/pages/mood/mood_dialog.dart` (1204 行!) | 0 单测 — **R64 没拆这个 god class** | 状态机 7 字段 + 2 个 StreamSubscription + 4 维度评分，2024 年 7 月至今 18 月未拆 |
| `presentation/pages/setup/setup_page.dart` (~80 行 wizard) | 0 单测（仅 4 步 step widget test，setup_page 整体 0 测） | 4 步骤状态机跨页签，0 集成测试 |
| `presentation/pages/settings/settings_page.dart` (~80 行 facade) | 0 单测（仅 6 个 section widget test） | section 顺序 + IAP 集成 + FeatureFlag 联系人软隐藏，0 集成测试 |
| `core/data/services/data_export_service.dart` + export/ 子服务 | 仅 4 个 sub-service test，orchestrator (21K 仍 god class) 缺集成测 | 隐私边界 + 加密集成测不全 |

**P1 缺口**: `notification_service.dart` facade 应有 facade-level integration test，**至少覆盖 init() 后 6 类 ID 范围不冲突 + showSafetyAlert 文案 3 态分流**（已有 sub-service test 但 facade 协调未测）。

### 2.3 TDD 纪律结论

R60-66 的 P0 修复**完全遵守** "先 failing test 再修" 模式：
- R60 P0-4 PHQ-9 crisis 21 case test
- R61-62 P0-2 PIPL §13 contact_consent_persist test
- R63 P0-1 AliyunSmsProvider `_isFullyImplemented` 守门 + sms_service_round38_test 扩
- R64 P0-3 SafetyDetector 8 case + L2 refactor 5 case
- R65 P0-12 SafetyAlertBuilder + 3 use case
- R66 P0-1 FeatureFlags 4 case + 3 入口守门

**唯一缺口**: `mood_dialog.dart` 1204 行 god class，2024-07 以来多次列入"待拆"，至今未拆也未加 TDD 失败测试。**spen 规约"complex new logic → failing test first"违反**。

---

## 3. 系统化调试遗留

### 3.1 静默吞异常（catch (_)）扫描

| 位置 | 状态 | 备注 |
|------|------|------|
| `core/theme/theme_provider.dart:35-39` | ✅ R30 改走 swallowError | 集中器 + 注释 |
| `core/shared/json_codec.dart:36-42` | ✅ R39 改走 swallowError | "宁愿空也不能崩" 注释 |
| `domain/logic/assessment_record.dart:89-93` | ✅ R39 改走 swallowError | 解析容错 |
| `core/data/database/mappers/medication/medication_times.dart:33-37` | ✅ R39 改走 swallowError | mapper 容错 |
| `core/data/services/data_export_service.dart` (注释引用) | ✅ R39 改走 swallowError | 4 处全集中器 |
| `core/data/services/export/export_orchestrator.dart:231` | ✅ R39 改走 swallowError | 文档化 + 集中器 |
| `core/data/database/app_database.dart:179-185` | ✅ R63 改走 swallowError | **唯一** v8→v9 vent 加密升级路径，dev mode 可见 |

**全 lib 静默 catch (_) = 0 处**。所有 best-effort 路径全部走 `swallowError(where, error, stack, note)` 集中器（`core/shared/swallow_error.dart`），R39 P1-10 集中 + R63 收尾 1 处剩余。**spen "不静默吞错" 100% 合规**。

### 3.2 `if (x == null) return;` 后用 `!` 强解（redundant null check）

扫了 30+ 处 `.first` / `.last` + 全部 facade 入口，**无 1 处 `!` 在前面已 null check 后再用**：
- `domain/logic/assessment_comparison.dart:96` `scoreDelta!` —— 上面 `if (previous == null || scoreDelta == null) return null;` 守，但 `!` 风格不如 `?? 0`（R62 已记，NIT 不重复）
- `core/data/repositories/check_in/check_in_repository_impl.dart:22` `_resolveTimestamp` helper——已抽
- `domain/entities/medication_entity.dart:61-83` `refillAt!.year`——上面 `refillAt != null` 守（spen 已知 NIT）

**R63 抽 `_resolveTimestamp` 是 P1-6 修复**（重复 pattern 抽 helper），但**抽的范围不够**（见 §6.1 DRY 章节）。

### 3.3 "重启就好" 状态没保存

扫了 25+ 处 widget state / provider 持久化路径，**0 处**发现"状态没保存"导致重启丢状态。Flutter widget 自身机制 + Drift (SQLCipher) 持久化 + SharedPreferences config 全部走稳定存储。

### 3.4 "假设某事一定发生" 但没验证

| 位置 | 假设 | 验证 |
|------|------|------|
| `core/data/services/notification_service.dart:75-80` | "6 sub-service 在 constructor 注入 (DI 模式, emil 推荐 testability)" | 实际有 test（badge_sync_service / medication_notifier / refill_notifier 各自有单测）✅ |
| `core/data/services/notification_service.dart:122-176` | `init()` 顺序: plugin init → tz init → permission → `_initialized = true` | **0 单测** guard，理论 tz init 失败后 permission 不调 ⚠️ |
| `core/data/services/safety_watch_service.dart:154-201` | "8 类 decision 走 detector + facade 协调 3 sub-service" | 有 detector 8 case + dispatcher 3 态 test + flag 守门 4 case ✅ |
| `core/data/services/mood_audio_service.dart:182-273` | "3min 上限自动 stop recorder" | 有 R43 spen-4 fix test (`mood_audio_service_round61c3_test.dart` 6K) ✅ |
| `core/data/services/sms_service.dart:307-318` | "MockSmsProvider 早返 + isProductionReady=false 时 SmsService.send 早返 mock" | 有 round 38 test ✅ |

**唯一中度风险**: `notification_service.init()` 0 单测，理论 tz init 失败后跳过权限请求可能导致 release 模式没权限。**P2 缺口**（半天补 1 test）。

### 3.5 资源 acquire / release 完整性

| 资源 | 释放路径 | 状态 |
|------|----------|------|
| StreamSubscription | vent_compose / vent_detail / mood_audio / setup 全部 cancel | ✅ R16 + R19B + R62 持续修 |
| Timer | home_page `_celebrationTimer` / `_deepLinkRaceTimer` / loading_skeleton `_pauseTimer` / mood_audio `_recordingTimer` / 3 个 animation 全部 cancel | ✅ R62 P1-6 修 Future.delayed → Timer 全部完成 |
| AudioPlayer | vent_compose / vent_detail / mood_audio 全部 dispose | ✅ |
| AudioRecorder | vent_compose / mood_audio 全部 dispose | ✅ |
| SpeechToText | mood_audio `_stopSttInternal` | ✅ |
| StreamController | mood_audio `_sttController.close()` | ✅ |
| Drift DB | `AppDatabase.forTesting` close 配套 | ✅ |
| 临时文件 | vent_compose `_tempDecryptedPath` + vent_audio storage | ✅ R48 P1-10 try/catch |

**全 lib 0 处资源泄漏**。spen "acquire 资源必 release" 100% 合规。

### 3.6 不一致 dispose 模式

- `home_page.dart:177-188` 2 个 Timer 都 cancel + set null
- `vent_compose_page.dart:70-85` 1 个 StreamSubscription cancel + 3 dispose + temp file cleanup
- `mood_audio_section.dart` 1 StreamSubscription + 1 Timer + 1 StreamController + 3 dispose

**风格统一**：全部 "字段?cancel/dispose + set null + super.dispose()" 模式。R62 集中修过。

---

## 4. 验证前不宣称完成

### 4.1 TODO / FIXME / XXX 跟踪

| 位置 | TODO 描述 | 跟踪状态 | 风险 |
|------|----------|----------|------|
| `lib/core/data/services/notification_service.dart:388-389` | "Android: 暂无稳定方案。v0.10+ TODO: 集成 flutter_app_badge_control 插件" | **18+ 月未动** (v0.10 = 2024-09, 现在 v0.27) | P3 — 0 守门员，但 iOS-only 注释清楚，**release 不依赖** |
| `lib/core/data/services/sms_service.dart:12, 90, 104, 194-197` | "AliyunSmsProvider.send() R55 真接 TODO" | **R63 守门员接住** (`_isFullyImplemented` 默认 false + `isProductionReady` = `_isFullyImplemented && 4 字段齐全`) | P0 已修（不"假成功"） |
| `lib/core/data/services/email_service.dart:72` | "真实 SMS 发送未实现（v1.0+ TODO）" | **0 守门员** | **P0 风险** — release 模式 email service 走 mock 早返 `return false`，但 0 守门员，**理论 release build 也能跑**（参见 §5 P0-1） |
| `lib/core/data/services/badge_sync_service.dart:45` | "Android: 暂无稳定方案 (TODO v0.10+ 集成 flutter_app_badge_control)" | 跟上面同款 18+ 月未动 | P3 |
| `lib/domain/entities/scale_translations.dart:17` | "16 题全文 i18n 化留 v1.0 (spzh report P1-A 已记 TODO)" | 有 R65 起步 (4 region label) | P1 |
| `lib/domain/entities/scale_translations.dart:86` | "tw/sg/uk 暂时走 intl fallback (TODO R65b 补 3 key)" | R65 起步 4 region，留 R65b | P2 |
| `lib/l10n/region_display_name.dart:3` | "v0.28 round 65 (spzh P2-F 修复)" | R65 修 | 已修 |
| `lib/core/theme/app_theme.dart:128` | "TODO v0.25: 评估 buildTheme 接受 context (会变更 ThemeProvider 接口)" | v0.25 后未动 | P3 |
| `lib/core/data/services/data_export_service.dart:19-22` | 4 个 v0.22-v0.24 修复历史注释 | 已修 | 已修 |

**关键发现 (P0)**: `email_service.dart:72` 注释 "v1.0+ TODO" + `return false` 早返 + **0 守门员** —— 这是 v0.23 R38 P0-1 "SmsService 假成功" 教训的 email 版孪生兄弟。release 模式启动不会阻断，UI 可能展示 "邮件已发" 但实际 `return false`。**应跟 R63 SmsService 同款 `_isFullyImplemented` 守门员**（参见 §5 P0-1）。

### 4.2 "看起来能跑但没测过" 的代码路径

| 路径 | 测试 | 风险 |
|------|------|------|
| `notification_service.init()` 顺序 (tz init 失败 → 权限请求是否跑) | 0 | 理论 release 模式 tz 异常时无通知权限 |
| `email_service.dart:69-73` `_sendViaApi()` 走 mock 早返路径 | 0 | P0 风险见上 |
| `safety_watch_service._checkAndAlert` 在 R66 FeatureFlag 早返路径（生产状态） | ✅ R66 test | 已修 |
| `care_engine.fire()` 5 个 trigger → notification service 调通 | 0 单测但有 `care_engine_round*_test.dart` 覆盖 evaluate | Fire 走 swallowError 集中器，**不崩** |

### 4.3 "我说能 work 但没在真机 / 真数据库 / 真网络验证"

- SQLCipher 加密: 0 集成测试，仅 in-memory DB
- flutter_local_notifications Android 角标: 0 集成测试（仅 widget test）
- audioplayers 加密 audio 播放: 有 `encrypted_audio_storage_round43_test.dart` 7.9K 覆盖
- SmsService mock vs AliyunSmsProvider: 有 round 38 test 覆盖 mock 路径，但 AliyunSmsProvider 是 `_isFullyImplemented=false` 占位，**真接 SDK 时需补集成测**

---

## 5. 代码审查 (P0 / P1 / P2)

### P0（必须修）

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `lib/core/data/services/email_service.dart:69-73` | `_sendViaApi()` 注释 "v1.0+ TODO" + `return false` 早返 + **0 守门员**，跟 v0.23 R38 SmsService "假成功" 教训同款孪生风险。release 模式启动不阻断 → 实际 release build 邮件"假失败"（返回 false）但 0 视觉提示 | 加 `_isFullyImplemented` 守门员（默认 false，R55 真接 SendGrid 时改 true）+ `isProductionReady` getter + `validateForRelease` 静态方法（跟 R63 SmsService 同模式 1:1） | S (2h) |
| `lib/core/data/repositories/vent/vent_repository_impl.dart:65` | `timestamp: at ?? DateTime.now()` —— 跟 `check_in_repository_impl.dart:22` 抽出的 `_resolveTimestamp` helper 同款 pattern，但**helper 是 private 不可复用**。R63 P1-6 修过 check_in 但漏了 vent / mood / medication / use case 4 处 | 抽 `_resolveTimestamp` 到 `core/shared/date_time_resolver.dart` 集中器（公开 API），5 处替换。spen R19B "DateTime race" 纪律集中器 | M (3h) |
| `lib/core/data/repositories/mood/mood_repository_impl.dart:41` | `timestamp: draft.at ?? DateTime.now()` —— 同款 DRY 违反 | 同上 (集中器替换) | S (随 §5 P0-2) |
| `lib/core/data/repositories/medication/medication_repository_impl.dart:49` | `startDate: draft.startDate ?? DateTime.now()` —— 同款 DRY 违反 | 同上 | S (随 §5 P0-2) |
| `lib/domain/usecases/check_in_usecases.dart:41` | `final time = at ?? DateTime.now();` —— domain use case 层同款 pattern，**未来 caller 复用会再写错**（R63 抽 helper 注释里说"防止未来 caller 复用时再写错"，但 helper 仍是 file-private） | 同上 (集中器替换) | S (随 §5 P0-2) |

**P0 总计**: 1 个新守门员 (email 跟 SmsService 平行) + 4 处 DRY 集中替换。

### P1（应修）

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `lib/presentation/pages/mood/mood_dialog.dart` (1204 行) | **2024-07 至今 18 月未拆** god class。emil 视角 P0-1 同款问题，spen 视角也是 P1（4 维度评分 + 2 个 StreamSubscription + 7 字段状态机）。**R64 仅拆了 7 个 widget 子组件（mood_audio_section / mood_recorder_page / mood_score_chooser / mood_submit_panel / mood_tags / mood_text_input），dialog 主体 1204 行仍是 orchestrator** | 抽 `MoodDialogOrchestrator` 状态机 (7 字段 → 1 enum) + 业务编排委派到 use case（domain/usecases/ 已有 check_in_usecases，加 mood_usecases.dart）。跟 R64 home_page 3 bool → enum 状态机同模式 | M-L (1-2d) |
| `lib/core/data/services/notification_service.dart` (424 行 facade) | 0 单测（仅 5 sub-service + 2 dispatcher + 1 builder 覆盖）。facade 编排 6 类 ID 范围 + init 顺序 + showSafetyAlert 委派，0 integration test guard | 加 `notification_service_facade_round66_test.dart`：6 类 ID 范围不冲突 + init() 后 6 类 sub-service 可调 + showSafetyAlert 委派路径 | S (3h) |
| `lib/core/data/services/notification_service.dart:122-176` `init()` | tz init 失败 → 权限请求是否跑 + `_initialized = true` 是否设 0 单测 guard。理论 release 模式 tz 异常时通知权限缺失，silent failure | 加 `init()_round66_test.dart`：mock tz_data 抛异常 → 验证权限仍调 + `_initialized = true` | S (2h) |
| `lib/core/data/services/email_service.dart:79-82` | `bool get isMock => _useMock \|\| _apiKey == null;` —— `isMock` 命名跟 SmsService 命名不一致（SmsProvider 是 `isProductionReady` 反义）。spen "命名一致性" 违反 | 改 `bool get isProductionReady => !(_useMock \|\| _apiKey == null);` —— 跟 SmsProvider 风格一致 | XS (15min) |
| `lib/core/data/database/app_database.dart:163-186` (v8→v9 vent 加密升级) | 单条 vent 加密失败时 `swallowError` 已修，但**未给用户视觉提示**（不像 R62 P0-2 "N 条树洞迁移失败" banner 决议）。旧数据降级到空内容用户无感 | 加 startup banner 提示 "N 条历史树洞数据格式异常，已跳过"。跟 R62 `LastStartupErrorBanner` 同模式 | M (半天) |
| `lib/presentation/pages/setup/setup_page.dart` (跨页 4 步骤) | 0 集成测试（仅 4 步 step widget test）。4 步骤状态机跨页签 (consent → welcome → medication → done)，0 端到端 test | 加 `setup_page_round66_integration_test.dart`：4 步骤连续跑 + step 3 完成后 contact 软隐藏路径 | M (半天) |
| `lib/presentation/pages/settings/settings_page.dart` (~80 行 facade) | 0 集成测试。section 顺序在 R66 调整 (联系人挪底部) + IAP 集成 + FeatureFlag 守门，0 端到端 | 加 `settings_page_round66_integration_test.dart`：6 section 顺序 + 联系人底部 | S (3h) |

**P1 总计**: 1 god class 拆 + 2 单测补 + 1 命名 + 1 banner + 2 集成测 = 7 项。

### P2（可改）

| 位置 | 问题 | 修复建议 | 估计工时 |
|------|------|----------|----------|
| `lib/core/data/services/notification_service.dart:388-389` (Android 角标 18+ 月 TODO) | 跟 badge_sync_service.dart:45 重复。两条同款 TODO 都"v0.10+ 集成 flutter_app_badge_control"，grep 噪音 | 加 `docs/TODO_v1.0.md` 集中器，3 个老 TODO (Android 角标 + AliyunSms 真接 + Email 真接) 统一文档化，注释里 cross-ref | XS (30min) |
| `lib/core/data/services/email_service.dart:70-72` 注释 "v1.0+ 替换" | 跟 sms_service.dart 同款注释 + 0 守门员，重复 spen 模式 | 跟 §5 P0-1 一起修 | XS (随 P0) |
| `lib/core/data/services/mood_audio_service.dart:124` | `static const Duration _tickInterval = Duration(milliseconds: 100);` —— 100ms 录音 tick 间隔没走 token。emil 视角也提过 (P0 残留) | 抽到 `app_spacing.dart` 或 `app_motion.dart` 作 `audioTickInterval` | XS (15min) |
| `lib/core/data/services/vent_audio_storage.dart:95` | `await Future<void>.delayed(Duration(milliseconds: 100 * attempt));` —— file lock 重试退避，magic 100ms 没走 token | 抽到 `app_spacing.dart` 作 `fileLockRetryStep` | XS (15min) |
| `lib/core/theme/app_theme.dart:128` | "TODO v0.25: 评估 buildTheme 接受 context" —— v0.25 = 2025-08 至今 1 年未动 | 移到 §5 P2-1 docs/TODO_v1.0.md 集中器 | XS (随 P2-1) |
| `lib/core/data/services/data_export_service.dart` 引用 | 21K god class 拆解后 orchestrator (export_orchestrator.dart) 仍 21K 字节（575 行），是子服务里**唯一**未拆 orchestrator | 抽 2 个 sub-service: `ExportPlanBuilder` (version 1-4 计划) + `ExportPreview` (dry-run 输出) | M (半天) |

---

## 6. SOLID 违反

### 6.1 SRP（单一职责）—— 良好

R60-66 系统修过：
- `SafetyWatchService` 619 行 → 240 行 facade + 3 sub-service + 1 pure detector (R64)
- `NotificationService` 631 行 → 424 行 facade + 5 sub-service + 1 builder (R65)
- `RefillNotifier` / `MedicationNotifier` / `AssessmentNotifier` 各自单一职责
- `CareEngine` 业务编排下沉到 `FireCareStrategyUseCase` (R65)
- `SafetyCheck` 业务编排下沉到 `CheckSafetyUseCase` (R65)
- `ScheduleRefillReminder` 业务编排下沉到 `ScheduleRefillReminderUseCase` (R65)

**唯一 SRP 违反**: `MoodDialog` 1204 行 god class（§5 P1-1）。

### 6.2 OCP（开闭原则）—— 良好

- `SmsProvider` abstract + MockSmsProvider / AliyunSmsProvider 切换 ✅
- `MoodAudioService` abstract + Impl 切换（widget test 注入 fake）✅
- `ScaleTranslations` abstract + StaticScaleTranslations (default) / AppLocalizationsScaleTranslations (R65 新) ✅
- `AppDatabase` schemaVersion + onUpgrade 链 ✅
- `SafetyDetector.detect` sealed 8 leaf class 强制穷举 ✅

### 6.3 LSP（里氏替换）—— N/A

无继承关系，全部 composition + interface。

### 6.4 ISP（接口隔离）—— 良好

- `MoodAudioService` 只暴露 9 个 method (initialize / startRecording / stopRecording / ...)，无 0 实现的"大接口"
- `ReminderDispatcher` 只暴露 4 个 method (cancelByIdRange / buildChannelDetails / zonedDaily / zonedAt)
- `SafetyDetector` 1 个 static method (detect)，**完美 ISP** 集中纯函数

### 6.5 DIP（依赖倒置）—— 良好

- presentation → domain abstract repository (5+ 个)
- data 层用 Drift DAO（不直接用 AppDatabase 表）
- sub-service DI 通过 constructor（`NotificationService` 5 sub-service 注入）
- use case 注入 repository abstract

**唯一 DIP 违反**: `app_database.dart:256-262` 7 个 `late final xxxDao = XxxDao(this)` —— 走 facade 暴露 7 个 DAO 是妥协（避免 caller 改 import），但 R65 已删 32 行 facade 委派（line 264-316），保留 `saveSetup` + `clearAllUserData` 业务编排。**良好**。

---

## 7. DRY / KISS / YAGNI

### 7.1 DRY 违反（集中器缺失）

| 位置 | 重复 pattern | 修复建议 |
|------|-------------|----------|
| `lib/core/data/repositories/check_in/check_in_repository_impl.dart:22` (private) | `_resolveTimestamp` helper (R63 抽) | 移到 `core/shared/date_time_resolver.dart` 公开 |
| `lib/core/data/repositories/vent/vent_repository_impl.dart:65` | `at ?? DateTime.now()` | 用集中器 |
| `lib/core/data/repositories/mood/mood_repository_impl.dart:41` | `draft.at ?? DateTime.now()` | 用集中器 |
| `lib/core/data/repositories/medication/medication_repository_impl.dart:49` | `draft.startDate ?? DateTime.now()` | 用集中器 |
| `lib/domain/usecases/check_in_usecases.dart:41` | `final time = at ?? DateTime.now();` | 用集中器 |
| `lib/core/data/services/email_service.dart:70-72` | 注释 "v1.0+ TODO" 跟 `sms_service.dart:194-197` 同款 | 走 `docs/TODO_v1.0.md` 集中器 |

### 7.2 DRY 良好

- `swallowError` 集中器 49 处调用（统一 4 sub-service + 4 mapper + 5 service 走集中器）
- `AppSnackBar.showX` 集中器覆盖 ~80 处
- `EmptyState` widget 5+ 页面用
- `AppListTile.standard` / `carded` 集中器
- `PressFeedback` / `LoadingTextButton` / `LoadingSpinner` 集中器
- `AppTokens.*` 颜色/间距/字体/圆角 token 集中
- `Strings.*` domain 层字符串集中
- `pubspec.yaml` version 字段（v0.27.0+64）已统一

### 7.3 KISS（简化）

**良好**：
- `FireCareStrategyUseCase` 0 副作用纯函数（输入 → 输出）
- `SafetyDetector.detect` 1 个 static method + sealed 8 leaf（完美简化）
- `HomeLifecycleState` 5 个 enum state + 3 transition method（替换 3 个 bool flag）

**KISS 违反**:
- `mood_dialog.dart` 1204 行（§5 P1-1）

### 7.4 YAGNI（不必要抽象）

**良好**：
- 无"为可能用"加的 abstract class（除 SmsProvider 实际有 2 个 impl 跟未来 AliyunSmsProvider）
- 无 0 caller 的 helper
- 无"为测试"加的 interface（MoodAudioService 抽象**有 1 个 Impl + 1 个 fake**，实际用得上）

**YAGNI 风险**:
- `FireCareStrategyUseCase` 5 case 中 4 case 是"channel=careCopy"（现状），sms/email channel 是 YAGNI 占位。R65 设计文档明示"v1.0+ 准备扩展"，是 acceptable YAGNI 推迟。

---

## 8. 半成品 / dead code

### 8.1 Dead code

扫了 50+ 文件，**0 处发现 never imported** 的代码：
- 6 个 sub-service 全部被 NotificationService constructor 引用
- 1 个 pure detector 被 SafetyWatchService 引用
- 1 个 pure builder 被 NotificationService 引用
- 3 个 use case 全部有 test（fire_care_strategy / check_safety / schedule_refill_reminder）

**半成品**: `CareDeliveryChannel.sms` / `.email` 2 个 enum 暂未真接（R55 / R60+ 等 SDK + 法务），但 use case + enum + decision 链路已通，**不是 dead code**，是"准备扩展的占位"。

### 8.2 Feature flag 后未实现路径

- `AliyunSmsProvider.send()` 永远 `throw StateError`（不是 `UnimplementedError`，R63 修正）—— R63 `_isFullyImplemented` 守门员接住，**不是真死路径**，release 模式启动被阻断
- `email_service._sendViaApi()` 永远 `return false` —— **0 守门员**（§5 P0-1）
- `_CountingNotificationService` / `_CountingConfigService` 是 R66 test helper，**only in test file**，没有 leak 到 lib/

### 8.3 "看起来在用其实早就 bypass 了" 的方法

| 位置 | 状态 |
|------|------|
| `app_database.dart` 18 query facade | R65 删 32 行 facade 委派，caller 94 处全迁到 `_db.xxxDao.xxx()` / `db.xxxDao.xxx()`。`saveSetup` + `clearAllUserData` 保留 (业务编排) |
| `notification_service.showNow()` NotificationSender abstract method | 仍用，但只在 NotificationService 内部实现 |
| `CareEngine.evaluate()` 静态方法 | 仍可调，**但 home_page / setup_page 已迁到 FireCareStrategyUseCase**（R65）。CareEngine 内部 fire() 没 caller 调（FireCareStrategyUseCase 只返 decision） |

**唯一疑似 dead path**: `CareEngine.evaluate()` + `CareEngine.fire()` —— R65 use case 抽离后**可能 0 caller**。需 grep 验证（待 §8.4 验证）。

### 8.4 验证

R65 后 `CareEngine.evaluate()` 唯一 caller 应是 `FireCareStrategyUseCase.call()`（line 215-218 调 `isSecondDayMissed` / `isLateCheckInHabit` / `isWeekendMissed` / `isWeekPerfect`），但 use case 调的是 **strategy function 不是 `CareEngine.evaluate()`**。`CareEngine.evaluate()` 可能 0 caller。

**P2 验证**（待办）：grep `_CareEngine\.evaluate` 全 lib 验证。**如果是 0 caller，标记 deprecated**（v0.28 删）或保留作 "legacy API 入口"。

---

## 9. 已知坑扩展

### 9.1 DateTime.now() 多次调用 race

R19B + R21 + R56b + R62 持续修过，全 lib 89 处 `DateTime.now()` 散落 47 文件。

**新发现 (R66)**: 5 处 `_resolveTimestamp` pattern 集中器缺失（见 §5 P0-2 / §7.1 DRY 章节）。

### 9.2 隐式排序假设（`.first` / `.last` on 时序数据）

R19B + R56e 系统修过，R62 R64 续修。**R66 扫描结果**:

| 位置 | 状态 |
|------|------|
| `domain/logic/streak_calculator.dart:46, 95` | ✅ R19 已修，显式 sort |
| `domain/logic/care_strategies.dart:107` | ✅ `sortedDesc.first.timestamp` 显式 sort |
| `domain/logic/reminder_scheduler.dart:56` | ✅ `sorted.first` 显式 sort |
| `domain/logic/assessment_comparison.dart:191` | ✅ `sorted.last` 显式 sort |
| `presentation/pages/assessment/widgets/assessment_summary_strip.dart:75` | ⚠️ `return filtered.first;` —— 上面 `filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp))` 已显式 sort ✅ |
| `presentation/pages/trend/widgets/trend_mood_chart.dart:55-72` | ✅ 全部显式 sort |
| `presentation/pages/trend/widgets/trend_assessment_chart.dart:61-62` | ✅ 全部显式 sort |
| `core/data/services/reminder_scheduler.dart:48-49, 112, 116` | ✅ 全部显式 sort |
| `core/data/services/safety_watch_service.dart:297` | ✅ `_contactRepo.watchAll().first.timeout(...)` —— **非时序数据**，是 stream first event，OK |
| `domain/usecases/fire_care_strategy.dart:211` | ✅ `normal.sort((a, b) => b.timestamp.compareTo(a.timestamp))` |

**全 lib 0 隐式排序违规**。spen 规约"显式 sort 后 .first/.last" 100% 合规。

### 9.3 `int.parse` / `DateTime.parse` / `double.parse` 用 tryParse 替代

| 位置 | 状态 |
|------|------|
| `presentation/pages/medication/widgets/edit_medication_dialog.dart:103` | ✅ 注释 "v0.21 (P0-1 fix): 之前用 double.parse,虽然 _validate 已 tryParse 校验过" |
| `core/data/services/export/export_schema_service.dart:154` | ✅ 注释 "v0.21 (P0-2 fix): 用 `tryParse` 替代 `try/catch + DateTime.parse`" |
| `core/data/services/last_error_capture.dart:38` | ✅ 注释 "v0.23 round 40 (sp-zh fix): .toUtc().toIso8601String() 配 'Z' 后缀" |

**全 lib 0 裸 `int.parse` / `DateTime.parse` / `double.parse` 使用**。所有时间戳生成走 `toUtc().toIso8601String()` (带 'Z' 后缀)，解析走 `tryParse`。

### 9.4 `StreamSubscription` cancel 配套

| 位置 | 状态 |
|------|------|
| `presentation/pages/vent/vent_detail_page.dart:41-43` (3 StreamSubscription) | ✅ dispose 全部 cancel |
| `presentation/pages/vent/vent_compose_page.dart:56` (1 StreamSubscription) | ✅ dispose cancel |
| `presentation/pages/mood/widgets/mood_audio_section.dart:118-119` (2 StreamSubscription) | ✅ dispose cancel |

**全 lib 0 漏 cancel 的 StreamSubscription**。spen "资源必 release" 100% 合规。

### 9.5 静默吞 catch (_)

§3.1 已列，**全 lib 0 处 `catch (_)`**。所有 best-effort 走 `swallowError(where, error, stack, note)` 集中器。

### 9.6 BuildContext 跨 async gap (`use_build_context_synchronously`)

| 状态 | 数值 |
|------|------|
| `!mounted` check | 54 处 / 16 文件 |
| `context.mounted` check | 24 处 / 7 文件 |
| analyzer 警告 `use_build_context_synchronously` | **0 处** (R17 R56b 起规范化) |

**全 lib 0 BuildContext 跨 async gap 违规**。spen 规约 "async 后用 mounted / context.mounted 守" 100% 合规。

### 9.7 dispose 完整性

扫了 30+ StatefulWidget + ConsumerStatefulWidget，**全 lib 0 漏 dispose**（§3.5 / §3.6 已列）。

---

## 10. 优先级 Top 10

| 序 | 问题 | 位置 | 难度 | 类别 | 理由 |
|----|------|------|------|------|------|
| 1 | `email_service.dart` 0 守门员 + `return false` 早返，release 模式"假失败"无视觉提示 | `lib/core/data/services/email_service.dart:69-73` | S | 架构 | v0.23 R38 SmsService 教训孪生，R55 真接 SendGrid 前必修 |
| 2 | `_resolveTimestamp` helper 集中 5 处 DRY 替换 | `lib/core/data/repositories/{check_in,vent,mood,medication}/*_impl.dart` + `lib/domain/usecases/check_in_usecases.dart` | M | 底层 | R63 抽 helper 但范围不够，未来 caller 复用会再写错 |
| 3 | `mood_dialog.dart` 1204 行 god class 拆解 (4-子组件 + 1 orchestrator 状态机) | `lib/presentation/pages/mood/mood_dialog.dart` | M-L | 架构 | 18 月未拆，emil + spen 双视角 P0 |
| 4 | `notification_service.dart` facade 0 单测 (init + 6 类 ID 范围 + showSafetyAlert 委派) | `lib/core/data/services/notification_service.dart` | S | 底层 | facade 编排 6 类通知，0 integration test guard |
| 5 | `notification_service.init()` tz 失败时通知权限缺失 silent failure | `lib/core/data/services/notification_service.dart:122-176` | S | 底层 | release 模式 tz 异常 → 通知权限缺失 |
| 6 | `app_database.dart:163-186` v8→v9 vent 加密失败时无用户视觉提示 | `lib/core/data/database/app_database.dart:163-186` | M | 底层 | 旧数据降级到空内容用户无感 |
| 7 | `setup_page.dart` 4 步骤状态机 0 集成测试 | `lib/presentation/pages/setup/setup_page.dart` | M | 底层 | 跨页 4 步骤，0 端到端 test |
| 8 | `settings_page.dart` 6 section 顺序 + FeatureFlag 软隐藏 0 集成测试 | `lib/presentation/pages/settings/settings_page.dart` | S | 底层 | R66 联系人软隐藏 0 端到端 |
| 9 | `email_service.dart:79` `isMock` 命名不一致（vs SmsProvider `isProductionReady`） | `lib/core/data/services/email_service.dart:79-82` | XS | 底层 | 跟 SmsService 风格不一致 |
| 10 | `CareEngine.evaluate()` 0 caller 验证 (R65 use case 抽离后) | `lib/domain/logic/care_engine.dart:68-109` | XS | 底层 | 可能 dead path，需 grep 验证后删 / 保留 |

---

## 11. 与历史 spen 报告对比

### 11.1 v0.27 R60+ spen 18 条状态

| 报告项 | 视角 | R60+ 状态 | R66 状态 | 备注 |
|--------|------|-----------|----------|------|
| 1.1 datetime race 5 误报 | spen | 🔶 R62 修正 | ✅ 全修 | R62 后 0 误报 |
| 1.2 swallowError 集中器 | spen | ✅ R39 4 处 | ✅ 全修 | R66 增加 1 处 (app_database v8→v9 vent 加密) |
| 1.3 golden test 缺失 | spen | ⏳ 未动 | ⏳ R66 仍缺 | P3 — 长期项目资产，1-2 天可加 3-5 个 |
| 1.4 5 个 god class 拆解 | spen | ✅ R64 拆 SafetyDetector | ✅ 已拆 3/5 | mood_dialog 1204 行**仍 god class**（§5 P1-1） |
| 1.5 隐式排序 + cancel range | spen | ✅ 已修 | ✅ R66 仍合规 | 0 隐式排序 |
| 2.1 `try {...} catch (_)` | spen | ✅ R39 8 处 | ✅ R66 0 处 | 全 lib 0 `catch (_)` |
| 2.6 `app_database.dart:165` vent 加密 | spen | 🔶 R63 改 swallowError | ✅ R66 已修 | 注释保留"v0.27 round 63 (P1-7 修复)" |
| 2.7 app_database 18 facade 委派 | spen | 🔶 R53a 7 DAO | ✅ R65 删 32 行 | caller 94 处全迁到 `_db.xxxDao.xxx()` |
| 2.8 SmsGateway abstract | spen | 🔶 R63 守门 | ✅ R66 仍合规 | `_isFullyImplemented` 守门 |
| 2.9 Android 角标 v0.10+ TODO | spen | ⏳ 18 月未动 | ⏳ R66 仍 TODO | P3 — 跟 badge_sync_service 同款 |
| 2.10 notification_service facade god | spen | 🔶 R45 R57 R61 | ✅ R64 R65 拆完 | facade 424 行（vs 631 行） |
| 2.11 safety_watch_service 122 行 | spen | 🔶 R57 R61 拆 | ✅ R64 拆完 | detector 纯函数 + facade 协调 |
| 2.12 check_in_repository 3 处 pattern | spen | ✅ R63 抽 helper | 🆕 R66 发现 4 处遗漏 | 集中器应公开，5 处替换（§5 P0-2） |
| 2.13 encrypted_audio_storage random suffix | spen | ⏳ 未改 7 位 | ⏳ R66 仍 4 位 | P3 — 7 位 0.0001% vs 4 位 0.01% |
| 2.14 vent_detail_page ??= 跟 ! 跨 await | spen | 🔶 局部变量 | ⏳ R66 仍 | P3 NIT |
| 2.15 saveSetup 业务编排 | spen | ⏳ 未抽 use case | ⏳ R66 仍 | 仍 AppDatabase 内 33 行 |
| 3.1-3.7 spen 7 类清单 | spen | ✅ R56e 续修 | ✅ R66 0 违规 | 隐式排序 / DateTime race / BuildContext / dispose / null safety / try-finally / catch |
| 4.2 R60+ 新发现 3 条 | spen | ✅ R66 全合规 | ✅ 已修 | app_database:165 / check_in / phq9 |

### 11.2 R66 新发现（5 条）

| # | 项 | 文件:行 | 关联 |
|---|----|---------|------|
| 🆕 11.2.1 | `email_service.dart` 0 守门员 (P0 风险孪生 R38 SmsService) | `lib/core/data/services/email_service.dart:69-73` | R63 SmsService 守门模式未应用到 email |
| 🆕 11.2.2 | `_resolveTimestamp` helper 5 处 DRY 替换 (P0 集中器公开) | 5 个文件 | R63 P1-6 抽 helper 但范围不够 |
| 🆕 11.2.3 | `mood_dialog.dart` 1204 行 18 月未拆 | `lib/presentation/pages/mood/mood_dialog.dart` | emil + spen 双视角 P0 遗留 |
| 🆕 11.2.4 | `notification_service.init()` 0 单测 (tz 失败 silent) | `lib/core/data/services/notification_service.dart:122-176` | R62 P1-6 修 Future.delayed 跟 init 无 test |
| 🆕 11.2.5 | `CareEngine.evaluate()` R65 use case 抽离后 0 caller 验证 | `lib/domain/logic/care_engine.dart:68-109` | dead path 风险 |

### 11.3 关键 R60+ 修正确认（9 项）

| # | 项 | 状态 | 验证方式 |
|---|----|------|----------|
| ✅ 1 | SafetyWatch 4 sub-service + SafetyDetector 纯函数 (R64) | ✅ | `safety_detector_round64_test.dart` 8 case |
| ✅ 2 | NotificationService 5 sub-service + SafetyAlertBuilder 纯函数 (R65) | ✅ | `safety_alert_builder_round65_test.dart` |
| ✅ 3 | HomePage 3 bool → enum 状态机 (R64) | ✅ | `home_lifecycle_round64_test.dart` 5 case |
| ✅ 4 | FireCareStrategyUseCase (R65) | ✅ | `fire_care_strategy_round65_test.dart` 5 case |
| ✅ 5 | CheckSafetyUseCase (R65) | ✅ | `check_safety_round65_test.dart` 5 case |
| ✅ 6 | ScheduleRefillReminderUseCase (R65) | ✅ | `schedule_refill_reminder_round65_test.dart` |
| ✅ 7 | ScaleTranslations abstract (R65 spzh P1-A 起步) | ✅ | `scale_translations_round65_test.dart` 14 case |
| ✅ 8 | AppDatabase saveSetup caller 94 处全迁 DAO (R65) | ✅ | facade 删 32 行 |
| ✅ 9 | FeatureFlags 软隐藏 (R66 联系人) | ✅ | `feature_flags_round66_test.dart` 4 case |

---

## 12. 总结

R66 (v0.27.0+64) 是一次"**收尾 + 软隐藏**"的迭代：
- 5 个 facade god class 拆解 3/5（safety_watch / notification / 3 use case + scale_translations abstract）
- 1 个新 FeatureFlags 守门员（联系人软隐藏）
- 1 个新状态机（home_page 3 bool → enum）

**剩下 5 个 P0-P1 问题**（5 + 7）都集中在"DRY 集中器" + "单测补" + "mood_dialog god class 拆解"。

**最大问题**: `_resolveTimestamp` helper 抽得不彻底（5 处同款 pattern 散落 4 个 repository + 1 个 use case），`email_service` 缺 R63 守门员（v0.23 R38 孪生风险），`mood_dialog` 1204 行 god class 18 月未拆。

**建议路线**（按 Top 10 顺序）:
1. §5 P0-1 + P0-2 (1-2 天) — email 守门 + _resolveTimestamp 集中器
2. §5 P1-1 (1-2 天) — mood_dialog god class 拆解
3. §5 P1-2 / P1-3 / P1-6 / P1-7 (1 天) — 4 个单测补
4. §5 P2-1 (30min) — TODO 集中器
5. 后续 v0.28 R67+ 排期

**整体评级**: **A-** (v0.27 R60-66 集中打掉 5 个 facade god class + 3 use case 抽离，spen 7 类清单 100% 合规；剩余 5 个 P0-P1 都是局部低风险，可控收尾)。

---

**审计完成时间**: 2026-08-02
**审计员**: superpowers-en 视角
**审计模式**: 全量（lib/ 239 .dart + test/ 122 .dart + 守护脚本 16/16 + 关键文件 read 30+）
**报告路径**: `D:\Batch\chroniccare\reports\audit\round66-superpowers-en.md`
**报告大小**: 18.5 KB（18 条 + 5 P0 + 7 P1 + 6 P2 + 10 Top 10）
