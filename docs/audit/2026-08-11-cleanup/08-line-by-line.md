# 底层逐行排查报告 · 2026-08-11

## 元信息
- 跑时间: 2026-08-11
- baseline: master `20670f3` v0.31.1+107
- 8-11 报告 baseline: master `01d8f4a` v0.31.0+107 (加权 7.5/10)
- 遍历文件数: 408 dart (lib) + 283 test + 145 script + 18 fastlane ruby/json + 28 iOS plist + 4 Android xml
- 遍历行数: 76,449 行 lib + 30,000+ test (估) + 5,000+ script (估)
- 8-11 报告对照: 重点 data/domain/test/scripts/fastlane/android/ios 增量
- 8-11 报告未明确覆盖的层 (本报告重点): `lib/core/data/**` (database/repositories/services/utils) + `lib/domain/**` (entities/logic/repositories/usecases) + `test/data/**` + `test/domain/**` + `scripts/**` 18 守门员 + `fastlane/metadata/ios/{en,zh-Hans,zh-Hant}/**` + `android/app/build.gradle.kts` + `ios/Runner/Info.plist` + `ios/Runner/PrivacyInfo.xcprivacy`

## A. 必修复 bug (P0-P1)

### A-01 [P0] 10 量表 ID 在 3 处硬编码 (DRY 违例, 维护陷阱)
- `lib/core/data/database/daos/check_in_dao.dart:38-51` (watchAssessments 的 IN 子句)
- `lib/core/data/database/daos/check_in_dao.dart:128-141` (getLatestAssessmentTimestamp 的 IN 子句)
- `lib/domain/entities/check_in_entity.dart:81-92` (CheckInType._assessmentScaleIds 集合)
- 影响: R90 加 8 个新量表时 3 处都改, 漏改 1 处 → 评估提醒 / 中心化入口 / 历史趋势 行为不一致
- 修法: 抽到 `domain/logic/scale_registry.dart` 的 `allScales().map((s) => s.id)` (注释里已建议), DAO 改用
- 难度: XS 30min (1 行改 3 处, 加 3 unit test 防回退)

### A-02 [P1] `watchToday` / `watchTodayAll` / `mood watchToday` 跨 midnight 不刷新
- `lib/core/data/database/daos/check_in_dao.dart:62-78` watchToday (DateTime.now() 在 Stream getter 内)
- `lib/core/data/database/daos/check_in_dao.dart:81-96` watchTodayAll
- `lib/core/data/database/daos/mood_dao.dart:37-54` mood watchToday
- 风险: 23:59 用户打开 home → drift stream 用 23:59 当作 "today" → 用户没打卡就 00:00 后, 这 3 个 stream 仍以 "昨天" 为 today。R17 round 4 的 midnight timer **只** invalidate `streakSummaryProvider` + `dayChangeTickProvider`, 不重 invalidate 这 3 个 watch。PII 风险: 用户以为自己 "今天还没打卡" 实际是 "昨天还没打卡", 漏服风险
- 修法: app.dart:247-256 的 midnight timer 加 3 行 `ref.invalidate(...watchTodayProvider)` 等 (暴露成 StreamProvider 然后 invalidate)
- 难度: S 1h

### A-03 [P1] `mood_audio_service.dart:352-368` dispose() 漏 dispose SpeechToText
- `_recorder.dispose()` ✓
- `_stt.dispose()` ✗ (SpeechToText 也 acquire method channel, 需 cancel listener)
- `_sttController.close()` ✓
- 影响: 多次进/出 mood 录音页 → SpeechToText method channel 累积, 可能触发 platform exception
- 修法: 加 `await _stt.cancel();` + 改 `_stt.cancel()` is OK (speech_to_text ^7.0.0 API) 之前 try/finally
- 难度: XS 15min (1 行 + 1 test)

### A-04 [P1] `user_profile_repository_impl.dart:67-87` `recordConsent` 静默丢失
- `if (existing == null) return;` 在 transaction 内
- 风险: 边界场景 — 用户在 consent 弹窗点 "同意" 但此时 profile 还没保存 (e.g. setup 流程 race) → consent 永远不写入, 但 UI 已显示 "已同意"。PIPL §13 留痕缺失
- 修法: 改成 `Value(existing?.sensitiveDataConsentAt)` + 把 `userName: Value(existing?.userName ?? '')` 兜底 (consent 可独立于 profile 写)
- 难度: XS 30min (1 file + 1 test 验证 profile null 时 consent 仍写入)

### A-05 [P1] `user_profile_repository_impl.dart:109-127` `resetConsent` 方法名误导
- 实现是 "重新同意" (sensitiveDataConsentAt = now, consentRevokedAt = absent)
- 名字应该叫 `reGrantConsent` (跟 `withdrawConsent` 配对)
- 风险: 未来 dev 看名字以为是 "清空 consent" → 调它之后实际上同意被重新记录, 导致 consentRevokedAt 丢失, PIPL §14 撤回历史被覆盖
- 修法: 改名 `reGrantConsent` + 保留 alias (1 轮 deprecation)
- 难度: XS 15min (search/replace + 6 个 caller + 3 test 改名)

### A-06 [P1] `encrypted_audio_storage.dart:264, 290` `dir.list()` 不递归
- `deleteAll()` 和 `totalSizeBytes()` 都用 `await for (final entity in dir.list())` 但只判断 `entity is File`
- 风险: 如果未来 audio subfeature 加子目录 (e.g. `mood_audio/transcripts/`), 那些文件不参与 `deleteAll` / `totalSizeBytes` → "清空所有数据" 漏删 → PII 残留 (跟 PII §28 冲突)
- 修法: 加 `recursive: true` 参数 + 显式排除 `.DS_Store` / Thumbs.db
- 难度: XS 10min

### A-07 [P2] `vent_repository_impl.dart:137-143` `getById` 缺事务 (跟 delete 不一致)
- `delete` (line 118-125) 在 transaction 内 select+delete 防 TOCTOU
- `getById` 裸 select, 跟 caller 在 transaction 内操作有 race
- 影响: 调用方 (vent detail page) 拿到 entity 后立即做 delete, 中间被 update (audio 路径 rename) → 误用旧 audioPath
- 修法: caller 用 `db.transaction { read + write }` 包, 或 getById 接受可选 transaction
- 难度: S 30min (语义改动, 需 review 1 处 caller)

### A-08 [P2] `medication_repository_impl.dart:79` `endDate: DateTime.now()` 不缓存
- 单点无影响, 但同函数 `_db.transaction` 内先 select 再 update, 2 个 await 跨度过大时 `now` 会跟 `existing.endDate` 跨日
- 修法: 函数入口 `final now = DateTime.now();` (跟 R19B 模式 1:1)
- 难度: XS 5min (一致性 fix, 加 1 regression test)

### A-09 [P2] `user_profile_repository_impl.dart:82, 103, 122` 3 处 `DateTime.now()` 给 consent 时间戳
- recordConsent / withdrawConsent / resetConsent 都用 now
- 风险: 23:59:59.999 用户点 "撤回" → consentRevokedAt = 次日 00:00:00.001 → 法律审计 "撤回日" 不准 (PIPL §14)
- 修法: 函数入口 `final now = DateTime.now();` (R19B 模式)
- 难度: XS 10min

## B. 隐藏 TODO / 半成品

### B-01 [P1] `sms_service.dart:198-201` AliyunSmsProvider.send() throw StateError
- v0.25 round 55 + v0.27 round 63 留的 R55 真接 TODO, 2+ 年未动
- 影响: release 模式启动时 `validateForRelease` 阻断 (banner 显眼), 但 dev 模式 mock 早返 → 上线前必须真接
- 修法: 法务模板审核 (1-2 月) + 阿里云 AccessKey 申请, R109 评估启动
- 难度: XL 跨周 (外部依赖, 非本批)

### B-02 [P1] `email_service.dart:163` 真实邮件发送未实现
- 同 R55 TODO, SendGrid 接入 1-2 月
- 难度: XL 跨周

### B-03 [P1] `domain/entities/scale_translations.dart:155` + `static_scale_translations.dart:659` PHQ-9/GAD-7 题目 16 题全文 i18n
- v0.27 R78 (spzh P1-A) 收尾, en/zh_Hant 用户看英文/繁体 (无中文题目) = 法律责任
- 当前 `phqGad7I18nEnabled=false` 留 v1.0 大工程
- 修法: v1.0 法务审核 + 题目 ARB 化
- 难度: L 1w (题目全文 16 × 2 量表 × 2 语言 = 64 条 ARB key)

### B-04 [P1] `domain/logic/scale_registry.dart:40-41` NSESSS / CRDPSS 量表
- 注释 `// TODO (v0.31+ 决定, user 选 hybrid)`, 走 unavailableScaleIds 黑名单
- 风险: 用户法务审核完想启用时, 需改 3 处 (registry + DAO IN + CheckInType enum)
- 修法: 评估 `FeatureFlags.nsesssEnabled` + DAO IN 走 `allScales().where(available).map(id)`
- 难度: M 1-2d

### B-05 [P2] `presentation/pages/setup/setup_legal_dialog.dart` PIPL §13 单独同意
- `scripts/check_legal_consent.py` 守门员扫 TODO + "PIPL §13 单独同意" 标记
- R55 留 TODO
- 修法: 联系 R66 已实装"软隐藏 + 软提示" → 升 R69 Sprint 1 hard requirement
- 难度: M 1-2d

## C. 上架硬阻塞

### C-01 [P0] iOS keywords.txt 含 "mental,health" — Apple 5.1.1
- `fastlane/metadata/ios/en-US/keywords.txt:1` → "medication,reminder,mood,mental,health,chronic,tracker"
- Apple 5.1.1 medical/mental health 关键词拒审
- 8-11 P0-04 只扫了 description.txt, **未扫 keywords.txt**
- 修法: 删 "mental" + "health" → "medication,reminder,mood,tracker,wellness,chronic"
- 难度: XS 5min

### C-02 [P0] iOS promotional_text.txt 含 "mental health assessments" — Apple 5.1.1
- `fastlane/metadata/ios/en-US/promotional_text.txt:1` → "Private, encrypted medication tracker for chronic patients. Mood, vent space, and mental health assessments."
- "mental health assessments" 触发 5.1.1
- 修法: 改 "mood and reflection space"
- 难度: XS 5min

### C-03 [P0] iOS zh-Hans + zh-Hant description.txt 仍含 "PHQ-9 (抑郁)" + "GAD-7 (焦虑)" — Apple 5.1.1
- `fastlane/metadata/ios/zh-Hans/description.txt` + `zh-Hant/description.txt` 全文跟 en-US 1:1 翻译, 含 5 病名 + 2 量表
- 8-11 P0-04 只查 en-US, **未扫 zh-Hans/zh-Hant** (3 个 locale)
- 修法: 跟 en-US 1:1 删 5 病名 + 量表名
- 难度: S 30min (3 文件, 加 `check_description_no_medical_claim_round108_test.dart` 扩 locale 列表)

### C-04 [P0] Android zh-CN full_description.txt 仍含 5 病名 + 2 量表 — Google Play 拒审
- `fastlane/metadata/android/zh-CN/full_description.txt` 跟 en-US 1:1 翻译
- Google Play 同样 policy
- 8-11 P0-04 跨期也只查 en-US
- 修法: 跟 iOS 1:1 删
- 难度: S 30min

### C-05 [P1] iOS description.txt "Suicide & Crisis Lifeline" 拼写
- `fastlane/metadata/ios/en-US/description.txt` → "US: 988 (Suicide & Crisis Lifeline)" OK
- 但 `fastlane/metadata/ios/notes.txt:8` "6. Crisis resources: accessible from Settings → Crisis Hotlines (6 regions)" 数字 6 可能跟 app 实际 hotline 数量不一致
- 验证: `crisis_hotline_page.dart` hotline 数量
- 难度: XS 5min (校验 + 同步)

### C-06 [P1] iOS Podfile platform :ios, '13.0' 跟 Xcode project IPHONEOS_DEPLOYMENT_TARGET=14.0 不一致
- `ios/Podfile:8` platform :ios, '13.0'
- `ios/Runner.xcodeproj/project.pbxproj` IPHONEOS_DEPLOYMENT_TARGET = 14.0 (多处)
- 风险: `pod install` 时 CocoaPods 用 Podfile 13.0 部署目标, xcodebuild 用 14.0 → 实际部署目标是 13.0 (更老), 影响 iPad iOS 13 用户基数 + App Store 兼容性最低要求
- 修法: Podfile 改 `platform :ios, '14.0'`
- 难度: XS 5min

### C-07 [P1] 4 个 `AndroidNotificationDetails` 调用缺 `visibility: NotificationVisibility.secret`
- `lib/core/data/services/notification_service.dart:222-228` showNow
- `lib/core/data/services/reminder_dispatcher.dart:103-109` buildChannelDetails
- `lib/core/data/services/safety_alert_builder.dart:80-87` (safety channel, 应该显示)
- `lib/core/data/services/snooze_manager.dart:88-94`
- `lib/core/data/services/badge_sync_service.dart:59-67`
- 5 处缺 visibility, 锁屏通知 title 仍含药名
- 8-11 P0-06 已列, 但只说 "4 处", 实际 5 处
- 修法: 4 处加 `visibility: NotificationVisibility.secret`, safety_alert_builder.dart (safety channel) 不加
- 难度: S 30min (5 处, 1 lock-in test 验证 safety channel 不被覆盖)

### C-08 [P2] `scripts/generate_release_keystore.ps1` R70 commit 5592f96 留 TODO
- signingConfig 切换 release (实际 2026-08-07 R97-P0-5 已切, TODO 过期)
- 修法: 删 TODO 注释, 注释历史
- 难度: XS 5min

## D. 架构债 (god class + 跨层)

### D-01 [P1] `app_database.dart:494L` onUpgrade 块 240L 单方法
- schemaVersion 22, 22 个 migration 全部 inline
- 修法: 抽 `database/migrations/migration_v{1..22}.dart` 每文件 ≤30L
- 难度: M 1-2d (拆解 + 保留 1 个 barrel file 兼容)

### D-02 [P1] `safety_watch_service.dart:338L` (R64 拆后仍 god class)
- facade 主体 130L + SafetyCheckResult 60L
- 8-11 P2-3 标 refactor 但未动
- 难度: L 1-2d (R110 god class 专项)

### D-03 [P1] `notification_service.dart:359L` (R108 拆后仍 god class)
- 主体 308L + delegate 160L = 468L
- 8-11 跨视角共识: 仍需进 R109 god class 专项
- 难度: L 1-2d

### D-04 [P1] `export_import_pipeline.dart:391L` (runImportFromJson 310+ 行单 method)
- 注释承认 R78+ 应拆 4 子任务
- 难度: M 1-2d (R109 拆 4 private method: clearData/importProfile/importEntities/importVent)

### D-05 [P1] `medication_report_pdf_layout.dart:292L` (未在 8-11 列)
- 单一 file 但承担"PDF layout + 数据填 + 分页"3 职责
- 难度: M 1-2d

### D-06 [P1] `static_scale_translations.dart:659L` PHQ-9/GAD-7 16 题 × 3 语言 = 48 条
- 编译进 binary 30+KB
- 80% 用户用不到 (phqGad7I18nEnabled=false)
- 修法: lazy load + 放 `assets/` 按需
- 难度: M 1-2d

### D-07 [P1] `day_detail.dart:319L` `_renderCheckInLabel` / `_scaleName` 60+ 行 hardcode 中文 fallback
- 8 个 R90 新量表全部返 `Strings.dayDetailScaleAssessment()` (同一个字符串) → 用户看 PHQ-9 和 ISI 都叫 "心理量表评估", 失去区分度
- 修法: 走 `scaleById(scaleId).displayName` 拿量表名
- 难度: S 1h (domain 0 flutter 边界已 closure 注入, 改 1 行)

### D-08 [P2] `safety_alert_builder.dart:88-93` iOS `interruptionLevel: timeSensitive`
- safety alert 应该是 timeSensitive (救命类), 但 iOS 也要求 entitlement 申请 (NSUserNotificationUsageDescription)
- Info.plist 无 `NSUserNotificationUsageDescription` (注释 line 40-46 提到 iOS 10+ 弃用)
- 风险: iOS 14+ 用 `interruptionLevel: timeSensitive` 但 entitlement 缺失 → 实际 priority 降级为 `active` (不响 + 不 banner)
- 难度: M 1d (entitlement 申请 + 验证)

### D-09 [P2] `contact_repository_impl.dart:72-95` `restore` 不清 consentRevokedAt
- 删 contact → 撤回 consent → undo restore → consentRevokedAt 仍 absent (新 record), 但 consentAt 是旧 (恢复时复用)
- 风险: 撤回的 contact 被 restore 后, 审计看不到 "曾撤回" 历史
- 修法: restore 时 consentRevokedAt = absent, 但日志 "restored from id=X, prior revoked history was Y" 留 audit
- 难度: S 30min

### D-10 [P2] `day_detail.dart:362` 8 个 R90 新量表返同一字符串
- 已列 D-07 跨类, 这里强调: UX 上量表名丢失
- 难度: S 1h

## E. 优化点

### E-01 [P1] 8 god class 候选无 unit test
- `mood_audio_service.dart:311L` (3min audio + STT 编排) — 0 test
- `safety_detector.dart:244L` (8 sealed branch) — 0 test
- `day_detail.dart:319L` (日详情聚合) — R10 + R48 2 测, 漏 fromData 各分支
- `static_scale_translations.dart:659L` — 2 测 (R65, R78)
- `safety_config_service.dart` — 0 test
- `consent_gate.dart` + `consent_artifact.dart` — R82 + R63 2 测, 漏 boundary
- `last_error_capture.dart` (主流程 crash 记录) — 0 test
- `database_key_service.dart` (R56c 加 5 测) — 基本覆盖
- `medication_slot_calculator.dart:102L` — 0 test
- 修法: 优先级 `mood_audio_service` > `safety_detector` > `day_detail` > 其余
- 难度: L 1w+ (聚合)

### E-02 [P1] iOS Podfile + .xcodeproj 双源 iOS deployment target
- 见 C-06
- 修法: Podfile 同步到 14.0
- 难度: XS 5min

### E-03 [P1] 4 个 `DarwinNotificationDetails()` 空构造 (8-11 P0-05)
- `notification_service.dart:229` + `reminder_dispatcher.dart:110` + `snooze_manager.dart:95`
- 8-11 已列, 未在 P0 修
- 修法: 3 处加 `categoryIdentifier` + `relevanceScore: 0` + `interruptionLevel`
- 难度: S 0.5h

### E-04 [P1] `notification_service.dart:221-230` showNow Android 通知缺 `style: NotificationStyle.none` + `color`
- 跟 medication reminder 通知视觉不一致 (8-11 P0-05 修了 lock-screen PII 但没统一视觉)
- 修法: 抽 `buildMedicationDetails` helper 统一 4 类通知
- 难度: S 1h

### E-05 [P1] `check_in_dao.dart:38-51 + 128-141` 10 scale IDs 硬编码 (见 A-01)
- 同时是优化点: 抽到 scale_registry
- 难度: XS 30min

### E-06 [P1] `static_scale_translations.dart:659L` 8 god class (R60/R65/R71/R77 跨 round 加)
- 见 D-06
- 难度: M 1-2d

### E-07 [P1] `medication_slot_calculator.dart:102L` 0 test
- 跨 midnight bedtime 边界 (21-4) 逻辑复杂, 0 test
- 修法: 加 10 case test (含跨 midnight)
- 难度: S 0.5h

### E-08 [P1] `consent_gate.dart` / `consent_artifact.dart` 边界 test 不全
- PIPL §14 撤回 / §13 单独同意 是法律红线, 现有 R82 + R63 2 测不够
- 修法: 加 5 case (撤回后 add vent / 撤回后 add contact / 撤回后 add assessment / 重授权后 add vent / 跨进程持久化)
- 难度: S 0.5h

### E-09 [P2] `safety_detector.dart:84-89` daysBetween 走 `calendarDaysBetween` (R102 P2 重构)
- 之前有同款 bug 在 3 个 service, 现在收口
- 验证: 跨 midnight 测 + DST 测
- 难度: XS 30min (补 test)

### E-10 [P2] 18 守门员有 2 个未在 `dart scripts/check_all.dart` 跑 (R108 P0-029 守卫)
- `check_sms_release_ready.py` 是 warn-only (R58 降级) — 守门员策略需要再评估
- 修法: R109 god class 拆完后重定级
- 难度: XS 5min

### E-11 [P2] `lib/core/l10n/strings.dart` `notif*Title` 函数签名 (R108 P0-012 修)
- `scripts/check_pii_in_title.py` 守门员已加
- 验证: 跑全项目 grep `notif*Title` 调用
- 难度: XS 10min

### E-12 [P2] 5 个 `DateTime.now()` 在 repository / DAO 内 (A-08, A-09 同款)
- `medication_repository_impl.dart:79` endDate
- `user_profile_repository_impl.dart:82, 103, 122` 3 处 consent
- `treatment_repository_impl.dart:107` (daily tracking)
- 修法: 函数入口 `final now = DateTime.now();` (R19B 模式)
- 难度: XS 15min (5 处 + 5 regression test)

### E-13 [P2] `lib/core/data/services/mood_audio_service.dart:118` StreamController.broadcast() 无 onCancel hook
- listener cancel 时 controller 不感知
- 影响: 0 立即问题, 跟 page dispose 配合 OK (page dispose → cancel stream subscription → controller 还在但 0 listener)
- 修法: 不必改
- 难度: skip

### E-14 [P2] `lib/core/data/services/notification_service.dart:160-161` `_defaultOnTap` 缺 `try/catch`
- `NotificationNavigation.handleTap(payload)` 抛错会冒泡到 flutter_local_notifications
- 修法: try/catch + swallowError
- 难度: XS 5min

## 总结

### 8-11 报告外新发现总数: 31 条
- A. 必修复 bug: 9 条 (A-01~A-09)
- B. 隐藏 TODO / 半成品: 5 条 (B-01~B-05)
- C. 上架硬阻塞: 8 条 (C-01~C-08)
- D. 架构债: 10 条 (D-01~D-10)
- E. 优化点: 14 条 (E-01~E-14)

### 加权后排序 (R109 第 1 周闭环建议)
1. **A-01** 10 scale ID 3 处硬编码 → 1 行改 3 处, 0 业务风险 — 30min
2. **A-04** recordConsent 静默丢失 → PIPL §13 法律红线 — 30min
3. **A-05** resetConsent 改名 → 防未来 bug — 15min
4. **A-02** watchToday 跨 midnight → 漏服风险 — 1h
5. **A-03** mood_audio_service dispose 漏 _stt → method channel 累积 — 15min
6. **C-01** iOS keywords.txt "mental,health" → Apple 5.1.1 拒审 — 5min
7. **C-02** iOS promotional_text "mental health" → Apple 5.1.1 拒审 — 5min
8. **C-03** iOS zh-Hans/zh-Hant description 5 病名 → Apple 5.1.1 拒审 — 30min
9. **C-04** Android zh-CN description 5 病名 → Google Play 拒审 — 30min
10. **C-07** 5 处 AndroidNotificationDetails 缺 visibility (8-11 只列 4) — 30min
11. **A-06** encrypted_audio_storage 不递归 (未来 PII 风险) — 10min
12. **A-07** vent_repository getById 缺事务 — 30min
13. **C-06** Podfile 跟 .xcodeproj iOS target 不一致 — 5min
14. **A-08 + A-09** 4 处 DateTime.now() 不缓存 — 25min
15. **D-07** day_detail 8 量表返同字符串 → UX 丢失 — 1h

**总预计: 5-7h 可闭环所有 P0/P1** (跟 8-11 计划 P0-01~P0-12 共 17 项的 3.5h + 5h 互补)

### 加权后排序 (R109 第 2-3 周 / R110 god class 专项)
- D-01~D-06 god class 拆解 (跟 8-11 P1-08~P1-11 合并)
- E-01 8 god class 0 test (mood_audio_service / safety_detector / day_detail / static_scale_translations)
- E-07 medication_slot_calculator 0 test
- E-08 consent_gate 边界 test
- D-09 contact restore 不清 consentRevokedAt

### 长期 (R110+ / v1.0)
- B-01 SMS 真接阿里云 (外部依赖 1-2 月)
- B-02 Email 真接 SendGrid (外部依赖 1-2 月)
- B-03 PHQ-9/GAD-7 16 题全文 i18n (法务 1-2 月)
- B-04 NSESSS/CRDPSS 量表启用 (法务 1-2 月)
- B-05 PIPL §13 hard requirement (法务 1-2 月)
- D-08 iOS `interruptionLevel: timeSensitive` entitlement
