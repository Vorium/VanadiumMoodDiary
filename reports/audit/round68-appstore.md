# AppStore 视角全量审计（v0.27 R68）

**审计时间**: 2026-08-04
**项目**: chroniccare
**版本**: 0.27.0+64（R67 收尾后，工作区有未提交改动）
**视角**: Apple App Store 上架合规
**审计模式**: 全量（聚焦 `ios/` + `lib/main.dart` + `fastlane/` + `pubspec.yaml` + `assets/legal/`）
**基线**: R66 报告 11 P0 + 9 P1 + 7 P2 + R67 B-1/B-2 修复落地
**参考基线**: Apple App Store Review Guidelines（2024-05 强制 Privacy Manifest + 2024-09 ATT 强化）

**项目基线**: 1237 tests pass / 0 analyzer error / 16 守护脚本全绿
**R67 修过的 iOS / 上架相关项**（核对 `reports/audit/round67-arch-changes.md` + `round67-sprint1-changes.md`）：
- ✅ `ios/Runner/Info.plist:66-67` R67 Sprint 1 C-P0-7 加 `NSPhotoLibraryUsageDescription`
- ✅ `ios/Runner/AppDelegate.swift:15-17` R67 Sprint 1 C-P0-8 设 `UNUserNotificationCenter.current().delegate`
- ✅ `ios/Runner/AppDelegate.swift:26-31` R67 Sprint 1 C-P0-8 注册 `BGTaskScheduler.shared.register(forTaskWithIdentifier:using:launchHandler:)`（R66 之前 0 调用，致命 P0 已修）
- ✅ `ios/Runner/PrivacyInfo.xcprivacy:42-92` R67 Sprint 1 C-P0-10 补全 4 类 `NSPrivacyCollectedDataTypes`（HealthAndFitness / AudioData / ContactInfo / UserContent）
- ✅ `fastlane/Fastfile` + `fastlane/Appfile` R67 Sprint 1 C-P0-11 新建（之前整个 iOS 提交流程无法启动，已修）
- ✅ `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/` 目录 + 全套元数据字段（description / keywords / subtitle / name / privacy_url / support_url / promotional_text / copyright / app_icon）R67 落地
- ✅ `lib/main.dart:52, 179` R67 B-1 顶层 static `_emailService` + `EmailService.validateForRelease` 守卫（跟 R62 SMS 守卫 1:1 平行）
- ✅ R67 Sprint 1 隐私邮箱 `privacy@chroniccare.app` 软隐藏（`user_agreement.md:62-64` + `privacy_policy.md:121-123`）

---

## 1. 顶层架构审视（iOS 集成架构）

| 维度 | 评估 | 备注 |
|------|------|------|
| iOS 平台特定代码边界 | ✅ 清晰 | `ios/Runner/AppDelegate.swift` 52 行（51 行是注册 + 1 行 handler）+ `SceneDelegate.swift` 4 行（继承 `FlutterSceneDelegate`） |
| Apple 平台限制处理 | ⚠️ 部分 | PHPhotoLibrary ✅ / BGTaskScheduler ✅（R67 修）/ UNUserNotificationCenter ✅（R67 修）/ ATT ❌ 未集成（项目零 IDFA，可不申请 ATT，但需 ATT label = "No"）|
| IAP / 通知 / 隐私 lifecycle | ✅ 合理 | `main.dart:148` 通知 init → `:170` SMS 守卫 → `:179` Email 守卫 → `:187-191` IAP warmup（FeatureFlags 门卫）→ `:209` DB 注入 → `:210` runApp。release 模式 4 个守门员按依赖顺序串行检查 |
| Medical 类"NOT a medical device"声明 | ✅ 完整 | `fastlane/metadata/ios/en-US/description.txt:38` + `:47-50` (crisis hotline) + `assets/legal/user_agreement.md:23-24` (本 App 不提供医疗建议) + `privacy_policy.md` 全文 disclaimer |
| "NOT an emergency service"声明 | ✅ 完整 | `en-US/description.txt:38` + `user_agreement.md:24` (失联通知不是紧急救援) + `privacy_policy.md:70-72` (失联通知暂停说明) |
| PIPL 单独同意 / 撤回同意 | ✅ 完整 | R67 Sprint 1 业务层生效（`VentRepository.add` 拒写 / `CareEngine.fire` early return / `trend_page` 占位）|
| 危机热线 i18n | ✅ 完整 | en-US/description.txt 给 988 + 116 123 + findahelpline.com / zh-Hans 给北京 010-82951332 / 全国 400-161-9995 / 上海 021-12320-5 / zh-Hant 给台灣 1925 + 香港 2389 2222 |
| 跨境 PII（PIPL §38）| ⚠️ 占位 | `privacy_policy.md:138-178` 描述了跨境方案但 release 模式 SMS 未接通，**业务暂停期间不实际跨境** |
| 3rd-party SDK 暴露 | ✅ 极小 | 全 Dart 库 + Flutter plugin（flutter_local_notifications / record / audioplayers / share_plus / in_app_purchase / flutter_secure_storage / sqlcipher_flutter_libs / speech_to_text / permission_handler / path_provider / pdf / printing / intl / uuid / fl_chart / go_router / flutter_dotenv / pointycastle / drift）— 零广告 / 零统计 / 零社交 SDK |

**架构层结论**：iOS 集成已从 R66 的"几乎全裸"状态提升到 R67 的"基本完整"。**剩 3 个致命 P0**（截图 / 邮箱 / bundle id 不匹配）+ 4 个上架阻塞 P0（3 份法律 md 占位 + 邮箱注册 + 真实 Apple ID）+ 8 个 P1 警告 + 6 个 P2 建议。

---

## 2. 底层逐行排查

### A. Info.plist 缺失 key

| 状态 | Key | 位置 / 备注 |
|------|-----|------------|
| ✅ 已加 R67 | `NSPhotoLibraryUsageDescription` | `ios/Runner/Info.plist:66-67` "用于分享用药报告 PDF 时选择保存位置" |
| ✅ R66 已加 | `NSPhotoLibraryAddUsageDescription` | `ios/Runner/Info.plist:56-57` |
| ✅ R62 已加 | `NSMicrophoneUsageDescription` | `ios/Runner/Info.plist:47-48` |
| ✅ R62 已加 | `NSSpeechRecognitionUsageDescription` | `ios/Runner/Info.plist:49-50` |
| ✅ R61 已加 | `NSUserTrackingUsageDescription` | `ios/Runner/Info.plist:72-73`（项目零 IDFA，防御性声明）|
| ✅ R62 已加 | `ITSAppUsesNonExemptEncryption` | `ios/Runner/Info.plist:108-109`（`false`，SQLCipher 走标准加密）|
| ✅ R62 已加 | `UIBackgroundModes` | `ios/Runner/Info.plist:144-148` `["audio", "processing"]` |
| ✅ R62 已加 | `BGTaskSchedulerPermittedIdentifiers` | `ios/Runner/Info.plist:153-156` `["com.chroniccare.safety-check"]` |
| ✅ R66 已加 | `LSApplicationCategoryType` | `ios/Runner/Info.plist:136-137` `healthcare-fitness` |
| ⚠️ P2 | `UISceneStoryboardFile=Main` + `UIMainStoryboardFile=Main` 双 storyboard | `ios/Runner/Info.plist:96-97` + `:114-115`（Main.storyboard 是空 FlutterViewController，SceneDelegate 接管，逻辑 OK 但语义冗余） |
| ⚠️ P2 | `NSUserNotificationUsageDescription` 老 key | `ios/Runner/Info.plist:45-46`（iOS 10+ 弃用，`flutter_local_notifications` 17.x 走 `UNUserNotificationCenter` 不读此 key，dead code 误导审核）|
| ⚠️ P1 | `CFBundleDisplayName` per-locale dict 写法 iOS 不支持 | `ios/Runner/Info.plist:14-22` 内嵌 dict，Apple iOS Info.plist 是单值，per-locale 必须走 `InfoPlist.strings`（`.lproj/`）。**当前 dict 形式被 iOS 忽略，所有 locale 都 fallback 到 `CFBundleName=chroniccare`** |
| ℹ️ 缺则 OK | `NSCameraUsageDescription` | 无 image_picker / camera 依赖，可不填 |
| ℹ️ 缺则 OK | `NSContactsUsageDescription` | 无 Contacts framework 依赖（自建 contacts 表） |
| ℹ️ 缺则 OK | `NSHealthShareUsageDescription` | 无 HealthKit |

### B. AppDelegate 缺处理

| 状态 | 处理 | 位置 / 备注 |
|------|------|------------|
| ✅ R67 已修 | `UNUserNotificationCenter.current().delegate = self` | `ios/Runner/AppDelegate.swift:15-17`（`if #available(iOS 10.0, *)`）|
| ✅ R67 已修 | `BGTaskScheduler.shared.register(forTaskWithIdentifier:using:launchHandler:)` | `ios/Runner/AppDelegate.swift:26-31`（handler 是 `handleSafetyCheckTask` 占位，line:49-51 直接 `task.setTaskCompleted(success: true)`，跟 R66 FeatureFlags.emergencyContactEnabled=false 一致）|
| ⚠️ P2 | SceneDelegate 双 storyboard | `ios/Runner/SceneDelegate.swift:1-5`（继承 `FlutterSceneDelegate`，OK；`Main.storyboard` 是空 FlutterViewController 占位）|

### C. PrivacyInfo.xcprivacy 不实

| 状态 | 项 | 位置 / 备注 |
|------|-----|------------|
| ✅ R67 已修 | `NSPrivacyCollectedDataTypes` 4 类 | `ios/Runner/PrivacyInfo.xcprivacy:42-92`（HealthAndFitness / AudioData / ContactInfo / UserContent，每类 `Linked=false` / `Tracking=false` / `Purposes=AppFunctionality`）|
| ✅ 已加 R61 | `NSPrivacyAccessedAPITypes` 4 类 | `ios/Runner/PrivacyInfo.xcprivacy:94-128`（UserDefaults CA92.1 / FileTimestamp C617.1 / SystemBootTime 35F9.1 / DiskSpace 85F4.1）|
| ⚠️ P2 | `NSPrivacyAccessedAPICategoryProcessInfo` 缺 | `flutter_local_notifications` 17.x 内部可能调 `ProcessInfo.processInfo` 取 thermalState / uptime，建议加 reason `AC67.1` |
| ⚠️ P2 | `UserDefaults` 只 1 个 reason | 当前只有 `CA92.1`（same app per documentation），若 `shared_preferences` 走 cross-app 共享需补 `CA92.2`（防御性补全）|
| ⚠️ P2 | 第三方 plugin 自带 PrivacyInfo 核 | `record 5.2.0` / `share_plus 10.1.4` / `speech_to_text 7.0.0` 需 `pod install` 后 grep `<App>.app/Frameworks/*.framework/PrivacyInfo.xcprivacy` 确认 2024-05 manifest 完整 |
| ⚠️ P1 | 实际数据 vs Manifest 不一致 | `lib/domain/logic/phq9.dart` 16 题题目 + `lib/domain/logic/gad7.dart` 16 题题目 当前 **未** i18n 化（hardcode 中文），en-US 用户看到中文 = 量表无效，但 Manifest 已声明 HealthAndFitness。Apple 5.1.1 透明度风险 |

### D. fastlane metadata 缺失

| 状态 | 项 | 位置 / 备注 |
|------|-----|------------|
| ✅ R67 已建 | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/` 目录 + 9 个文本字段 + 3 个 screenshot 子目录 | 见 `fastlane/metadata/ios/` 文件清单（每个 locale 9 个 .txt + 3 个 screenshot 子目录 = 27 个文件）|
| ✅ 已填 | `description.txt` 3 个 locale | en-US 52 行 / zh-Hans 42 行 / zh-Hant 42 行（含 重要声明 + 危机热线）|
| ✅ 已填 | `keywords.txt` 3 个 locale | en-US 55 字符 / zh-Hans 49 字符 / zh-Hant 49 字符（Apple 限制 100 字符）|
| ✅ 已填 | `subtitle.txt` 3 个 locale | en-US "Medication + Mood Tracker" / zh-Hans "吃药打卡 + 失联通知" / zh-Hant 同步 |
| ✅ 已填 | `name.txt` 3 个 locale | "ChronicCare" / "慢病管家" / "慢病管家" |
| ✅ 已填 | `promotional_text.txt` 3 个 locale | 137 / 129 / 129 字符（Apple 限制 170）|
| ✅ 已填 | `privacy_url.txt` 3 个 locale | `https://chroniccare.app/privacy`（**注：URL 假设已注册，R66 之前无此 URL 真实性证据**）|
| ✅ 已填 | `support_url.txt` 3 个 locale | `https://chroniccare.app/support`（同上）|
| ✅ 已填 | `copyright.txt` 3 个 locale | "© 2026 chroniccare" / "© 2026 慢病管家" / "© 2026 慢病管家" |
| ✅ 已填 | `app_icon.png` 3 个 locale | 67 字节占位（**P0：未替换为真实 1024×1024**）|
| 🚨 **P0** | 全部 screenshot 是 67 字节占位 | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/iphone_6_5_screenshots/0[1-5]_home.png` 15 张 + `iphone_5_5_screenshots/0[1-3]_home.png` 9 张 + `ipad_12_9_screenshots/0[1-3]_home.png` 9 张 = 33 张 67 字节透明占位。**App Store Connect 强校验真截图（1242×2688 / 1242×2208 / 2048×2732），缺则提交拒** |

### E. 法律文档占位

| 状态 | 文件 / 行 | 备注 |
|------|-----------|------|
| 🚨 **P0** | `assets/legal/user_agreement.md:3` | `> **TODO (上 store 前必须由专业律师过审)**: 本协议当前为 v0.24 草稿, 未经律师过审。` |
| 🚨 **P0** | `assets/legal/user_agreement.md:60` | `- 开发者邮箱: support@chroniccare.app(**TODO 占位 — 上 store 前必须注册并替换为真实邮箱**)` |
| 🚨 **P0** | `assets/legal/user_agreement.md:61` | `- GitHub Issues: https://github.com/example/chroniccare/issues(**TODO 占位, 需确认或替换为真实项目仓库**)` |
| 🚨 **P0** | `assets/legal/user_agreement.md:25, 28` | "本 App 售价人民币 8 元" + "一次性买断" — **但 release 模式 `StoreKitService.buyLifetime()` 返 false（R67 已 IAP enabled=false 隐藏按钮），description 与代码不一致** |
| 🚨 **P0** | `assets/legal/privacy_policy.md:3-4` | `> **TODO (上 store 前必须由专业律师过审)**: 本政策当前为 v0.22 草稿, 未经律师过审。` |
| 🚨 **P0** | `assets/legal/sensitive_data_consent.md:3-4` | `> **TODO (上 store 前必须由专业律师过审)**: 本同意书当前为 v0.24 草稿, 未经律师过审。` |
| ⚠️ P1 | `assets/legal/user_agreement.md:17, 24` | 失联通知仍写"自动通知预设的紧急联系人" + "失联通知功能不是紧急救援服务"，但 R66 起业务整体暂停 + R67 Sprint 1 撤回同意生效。**description 改"coming soon"，agreement 仍按"正常功能"描述 = 用户认知错位** |
| ⚠️ P1 | `assets/legal/privacy_policy.md:34, 72, 87` | 多处引用"FeatureFlags.emergencyContactEnabled = false"，但**用户协议 / 描述没同步此状态**，需要明确写"失联通知 v0.27 起暂停，预计 v1.0 启用" |
| ⚠️ P1 | `assets/legal/privacy_policy.md:165` | "跨境 PII 传输审计日志(本地)" — 但代码层 `safety_alert_dispatcher.dart` / `audit_log_repository.dart` 0 个 audit 写（业务暂停期间不实际触发，但文档承诺"本地审计" = 文档与代码不一致）|
| ⚠️ P1 | `assets/legal/privacy_policy.md:192` | 表格 "紧急联系人回复 Y 确认" 标 ❌ TODO，但 R66 起业务暂停，此行**应该改为 ⏸ 暂停（R66 决策）**，而非 ❌ TODO |

### F. IAP 与声明不一致

| 状态 | 项 | 位置 / 备注 |
|------|-----|------------|
| ✅ 已加 R65 | `in_app_purchase: ^3.3.0` | `pubspec.yaml:62` |
| ✅ R67 C-7 隐藏 | `FeatureFlags.iapEnabled=false` | `lib/core/data/feature_flags.dart:62` 默认 false，release 模式用户看不到"立即买断"按钮 |
| ✅ R67 C-7 早返 | `StoreKitService.buyLifetime()` 入口 `if (!FeatureFlags.iapEnabled) return false;` | `lib/core/data/services/store_kit_service.dart:108-110` |
| ✅ R65 warmup | `main.dart:187-191` `if (FeatureFlags.iapEnabled) await StoreKitService.warmup();` | release 模式跳过 warmup |
| 🚨 **P0** | `user_agreement.md:25, 28` 仍写 "本 App 售价人民币 8 元" / "一次性买断" | **Apple 2.1 完整性 + 4.3 误导：用户协议承诺 8 元买断，但 App 内找不到购买入口**（R67 FeatureFlags 软隐藏）。要么改 agreement 删 8 元条款，要么 v0.28 真接 IAP 二选一 |
| ⚠️ P2 | `fastlane/metadata/ios/*/description.txt` 全文 0 处提"售价 8 元" | en-US/zh-Hans/zh-Hant description 完全不提 IAP 8 元（一致性 OK，但 App Store Connect Price tier 还是"Free + IAP"？需要 App Store Connect 后台决定）|

### G. 通知权限文案

| 状态 | Key | 位置 / 备注 |
|------|-----|------------|
| ⚠️ P2 | `NSUserNotificationUsageDescription` 老 key + 文案 | `ios/Runner/Info.plist:45-46` "用于在到点提醒你吃药打卡，所有通知本地处理，不上传任何数据" — iOS 10+ 已弃用，`flutter_localifications` 17.x 不读。dead code 误导审核，删 |
| ✅ R65 已配 | `DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true)` | `lib/core/data/services/notification_service.dart:128-132`（iOS 走 `UNUserNotificationCenter` 弹权限弹窗）|
| ✅ 已注 | `IOSFlutterLocalNotificationsPlugin().requestPermissions(alert: true, badge: true, sound: true)` | `lib/core/data/services/notification_service.dart:167-170` |
| ⚠️ P1 | "通知本地处理，不上传" 描述与"全数据本地"承诺的"不收集通知权限" | App Privacy 标签"Notifications" 默认是 Yes（用户必须同意才能用），但 `NSUserNotificationUsageDescription` 是 iOS 9 时代文案，建议删此 key 避免审核疑问 |

### H. 紧急联系人 / 失联通知 / 录音（敏感数据）

| 状态 | 项 | 位置 / 备注 |
|------|-----|------------|
| ✅ R66 业务暂停 | `FeatureFlags.emergencyContactEnabled=false` | `lib/core/data/feature_flags.dart:52` |
| ✅ R67 撤回生效 | 3 类 ConsentGate 业务层拦截 | `VentRepository.add` 拒写 / `CareEngine.fire` early return / `trend_page` 占位 |
| ✅ 已声明 | `NSPrivacyCollectedDataTypeContactInfo` | `ios/Runner/PrivacyInfo.xcprivacy:68-79`（`Linked=false` / `Tracking=false` / `Purpose=AppFunctionality`）|
| ✅ 已声明 | `NSPrivacyCollectedDataTypeAudioData` | `ios/Runner/PrivacyInfo.xcprivacy:56-67`（树洞 / 情绪语音）|
| ⚠️ P1 | 录音时 UI 提示未明确"切后台会继续" | `Info.plist:144-148` `UIBackgroundModes=["audio"]` 意味着 vent 录音时切后台会继续录。Apple 4.0 Background audio 必须有 visible purpose，建议在录音 dialog 顶部加 "录音时切到后台会继续录制" 文案 |
| ⚠️ P1 | 紧急联系人"已告知"软提示但 R55 SMS 未接 | `privacy_policy.md:34` "联系人本人未回复 Y 确认（R55 TODO — 依赖 SMS provider 真接）" — 业务暂停期间 OK，但**用户协议仍按"正常功能"写**（见 E）|
| ⚠️ P2 | 紧急联系人"删除后跨境传输停止" | `privacy_policy.md:164` 描述但 `contact_repository.dart` 删除联系人是否清除 audit log 未核 |

---

## 3. 上架阻断清单

按 P0 提交必拒 / P1 警告 / P2 建议 排序，每条标 **XS(< 15min) / S(< 1h) / M(1-4h) / L(> 4h)** 难度

### 3.1 P0 提交必拒（10 项）

| # | 问题 | file:line | 难度 | 修复建议 |
|---|------|-----------|------|----------|
| 1 | **fastlane Appfile 中 `app_identifier` 是 `com.chroniccare.chroniccare` 但 pbxproj 是 `com.chroniccare.app`** | `fastlane/Appfile:19` vs `ios/Runner.xcodeproj/project.pbxproj:379, 561, 584` | XS | 改 `app_identifier("com.chroniccare.app")`（跟 pbxproj / Info.plist / Android build.gradle.kts 一致）|
| 2 | **fastlane Appfile 中 `apple_id` / `team_id` / `itc_team_id` 全是占位** | `fastlane/Appfile:21, 23, 25` | XS | 替换为真实 Apple ID + Team ID（10 字符）+ ITC Team ID（从 Apple Developer 后台 Membership / App Store Connect Users and Access 拿）|
| 3 | **iOS 33 张截图全是 67 字节占位 PNG** | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/{iphone_6_5,iphone_5_5,ipad_12_9}_screenshots/0[1-5]_home.png` | L | 跑 `flutter run -d "iPhone 15 Pro Max"` 截 5 张主页面（主页 / 打卡 / 趋势 / 心理评估 / 树洞 / 设置 / IAP），存 3 个 locale 3 种尺寸（最少 27 张）|
| 4 | **`app_icon.png` 3 个 locale 都是 67 字节占位** | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/app_icon.png` | XS | 替换为 1024×1024 不透明 PNG（Apple 规定无 alpha channel）|
| 5 | **`assets/legal/user_agreement.md` 第 1 行 "未经律师过审" TODO + 邮箱 `support@chroniccare.app` 是占位 + GitHub URL 是 example 占位** | `user_agreement.md:3, 60, 61` | L | 律师过审（1-2 周）+ 注册 `support@chroniccare.app` 邮箱 + 决定是否开源改 GitHub URL 或删此行 + 移除文件顶部 TODO banner |
| 6 | **`assets/legal/privacy_policy.md` 第 1 行 "未经律师过审" TODO** | `privacy_policy.md:3-4` | L | 律师过审（PIPL 专项 1-2 周）+ 移除 TODO banner + 同步到 `https://chroniccare.app/privacy` |
| 7 | **`assets/legal/sensitive_data_consent.md` 第 1 行 "未经律师过审" TODO** | `sensitive_data_consent.md:3-4` | L | 律师过审 + 移除 TODO banner + 重新走用户同意流程刷 `sensitiveDataConsentAt` 时间戳 |
| 8 | **`user_agreement.md:25, 28` 写 "本 App 售价人民币 8 元" / "一次性买断" 但 release 模式 `StoreKitService.buyLifetime()` 返 false + IAP 入口被 FeatureFlags 隐藏** | `user_agreement.md:25, 28` vs `lib/core/data/services/store_kit_service.dart:105-120` + `lib/core/data/feature_flags.dart:62` | S | 二选一：(a) 删 user_agreement.md §3 付费规则段（v0.27 期间 App 完全免费）+ (b) v0.28 真接阿里云 IAP（依赖法务 1-2 月 + App Store Connect 创建 productId）|
| 9 | **`privacy_url.txt` 3 个 locale 写 `https://chroniccare.app/privacy`，但 `chroniccare.app` 域名所有权 / `https` 证书 / 真实可访问性未验证** | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt` | M | 注册 `chroniccare.app` 域名 + 部署 HTTPS 站点 + 把 `assets/legal/privacy_policy.md` 同步到 `https://chroniccare.app/privacy`（Apple 审核员会点 URL 验真，404/未注册域名 = 拒）|
| 10 | **`support_url.txt` 3 个 locale 写 `https://chroniccare.app/support`，同上** | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/support_url.txt` | M | 同上注册域名 + 部署 `https://chroniccare.app/support`（客服邮箱 / FAQ / 联系方式页）|

### 3.2 P1 警告（10 项）

| # | 问题 | file:line | 难度 | 修复建议 |
|---|------|-----------|------|----------|
| 11 | **`aps-environment=development` 误导** | `ios/Runner/Runner.entitlements:5-6` | XS | 删 `aps-environment`（项目无 APNs 远程推送，仅用 `flutter_local_notifications` 本地通知），App Store Connect Push Notifications 标签 = No |
| 12 | **`CFBundleDisplayName` per-locale dict iOS 不支持** | `ios/Runner/Info.plist:14-22` | S | 方案 A：删 dict，单值 `CFBundleDisplayName=慢病管家`（中文用户基线）；方案 B：建 `ios/Runner/zh-Hans.lproj/InfoPlist.strings` + `zh-Hant.lproj/InfoPlist.strings` |
| 13 | **`NSUserNotificationUsageDescription` 老 key dead code** | `ios/Runner/Info.plist:45-46` | XS | 删（iOS 10+ 弃用，`flutter_local_notifications` 17.x 走 `UNUserNotificationCenter`）|
| 14 | **`ITSAppUsesNonExemptEncryption=false` 与 SQLCipher AES-256 矛盾** | `ios/Runner/Info.plist:108-109` | S | 方案 A（保守）：改 `true` + 准备 self-classification report；方案 B：保持 `false` 等被拒再补（低概率被审时追问）|
| 15 | **`EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64` 影响 Apple Silicon 开发** | `ios/Runner.xcodeproj/project.pbxproj:358, 487, 538` | XS | 删 3 处（Xcode 15+ 默认 arm64 simulator）|
| 16 | **`user_agreement.md` 把失联通知当"正常功能"写，R66 起业务暂停** | `user_agreement.md:17, 24` | S | 同步 description 改 "失联通知 v0.27 起暂停，预计 v1.0 启用"，3 态分流（暂停中 / 用户已配置联系人 / 启用后行为）|
| 17 | **`privacy_policy.md` 第 11 章跨境 PII "审计日志"承诺但代码层 0 实现** | `privacy_policy.md:165` vs `safety_alert_dispatcher.dart` 0 audit 写 | M | R66 业务暂停期间 OK，但 R67 撤回同意生效后必须真接 audit log（建议 `audit_log_repository.dart` 加 `recordSafetyAlertDispatch(...)`）|
| 18 | **PHQ-9 / GAD-7 16 题题目未 i18n 化** | `lib/domain/logic/phq9.dart` + `lib/domain/logic/gad7.dart` + `lib/domain/entities/scale_translations.dart` (R65 新) | L | R66 上架前补全 16 题英译（48-72h 工作量）；或英文区显示"中文 only"提示强制用户切中文 |
| 19 | **`UIBackgroundModes=audio` 录音时切后台会继续** | `ios/Runner/Info.plist:144-148` | S | 在 vent 录音 dialog 顶部加 "录音时切到后台会继续录制" 提示文案（Apple 4.0 Background audio visible purpose）|
| 20 | **隐私 / 邮件邮箱软隐藏但 `support@chroniccare.app` 仍占位** | `user_agreement.md:60` + `privacy_policy.md:121` + `appfile:21` | S | 注册 `support@chroniccare.app` 真实邮箱 + 移除所有 "TODO 占位" 标注（privacy@ 已软隐藏 OK）|

### 3.3 P2 建议（6 项）

| # | 问题 | file:line | 难度 | 修复建议 |
|---|------|-----------|------|----------|
| 21 | **`NSPrivacyAccessedAPICategoryProcessInfo` 缺 + `UserDefaults` 只 1 reason** | `ios/Runner/PrivacyInfo.xcprivacy:94-128` | XS | 加 `NSPrivacyAccessedAPICategoryProcessInfo` reason `AC67.1` + `UserDefaults` 补 `CA92.2`（防御性）|
| 22 | **第三方 plugin 自带 PrivacyInfo 核** | `pubspec.yaml:33-67` | S | `pod install` 后 grep `<App>.app/Frameworks/*.framework/PrivacyInfo.xcprivacy` 确认 `record 5.2.0` / `share_plus 10.1.4` / `speech_to_text 7.0.0` 自带 |
| 23 | **`UISceneStoryboardFile=Main` + `UIMainStoryboardFile=Main` 双 storyboard 语义冗余** | `ios/Runner/Info.plist:96-97, 114-115` + `Base.lproj/Main.storyboard` | S | 删 `Main.storyboard` + `UISceneStoryboardFile` + `UIMainStoryboardFile` keys，仅留 `UILaunchStoryboardName=LaunchScreen` + `SceneDelegate` |
| 24 | **`LaunchImage.png` 是 68 字节占位 + `LaunchImage.imageset` 仍保留** | `ios/Runner/Assets.xcassets/LaunchImage.imageset/{LaunchImage,LaunchImage@2x,LaunchImage@3x}.png` (68 bytes each) | XS | 删 `LaunchImage.imageset`（已用 `LaunchScreen.storyboard` 替代）|
| 25 | **`pubspec.yaml:4` 版本号 `0.27.0+64` < 1.0.0** | `pubspec.yaml:4` | XS | 提 store 前 bump 到 `1.0.0+1`（表达"正式版"，避免 Apple 4.3 Spam 自动标记）|
| 26 | **失联通知 v0.27 暂停但 App Store Connect 不可设置 "功能未启用" 标签** | （运营配置）| S | App Store Connect 后台 App Privacy / App Info 描述里加 "Lost-contact safety net: coming in v1.0, currently disabled" 醒目声明 |

---

## 4. 截图 / 描述 / 关键词现状

| 项 | 现状 | 评估 |
|----|------|------|
| `fastlane/metadata/ios/en-US/iphone_6_5_screenshots/0[1-5]_home.png` | 67 字节透明占位 | 🚨 P0 拒审 |
| `fastlane/metadata/ios/en-US/iphone_5_5_screenshots/0[1-3]_home.png` | 67 字节透明占位 | 🚨 P0 拒审 |
| `fastlane/metadata/ios/en-US/ipad_12_9_screenshots/0[1-3]_home.png` | 67 字节透明占位 | 🚨 P0 拒审 |
| `fastlane/metadata/ios/zh-Hans/*_screenshots/*.png` | 67 字节透明占位 × 15 | 🚨 P0 拒审 |
| `fastlane/metadata/ios/zh-Hant/*_screenshots/*.png` | 67 字节透明占位 × 15 | 🚨 P0 拒审 |
| `description.txt` (en-US, 52 行, 2958 字节) | 完整含 "ChronicCare is NOT a medical device" + 危机热线 (988 / 116 123) | ✅ Apple 1.4.3 合规 |
| `description.txt` (zh-Hans, 42 行, 2512 字节) | 完整含 "本 App 不提供医疗建议" + 危机热线 (北京 010-82951332 / 全国 400-161-9995 / 上海 021-12320-5) | ✅ |
| `description.txt` (zh-Hant, 42 行, 2449 字节) | 完整含 危机热线 (台灣 1925 / 香港 2389 2222) | ✅ |
| `keywords.txt` (3 locale, 49-55 字符) | 含 medication/reminder/mood/mental/health/chronic/tracker | ✅ Apple 100 字符限内 |
| `subtitle.txt` (3 locale) | "Medication + Mood Tracker" / "吃药打卡 + 失联通知" | ✅ Apple 30 字符限内 |
| `name.txt` (3 locale) | "ChronicCare" / "慢病管家" / "慢病管家" | ✅ Apple 30 字符限内 |
| `promotional_text.txt` (3 locale, 129-137 字符) | 含 "Private, encrypted" / "100% on-device, zero cloud" | ✅ Apple 170 字符限内 |
| `privacy_url.txt` (3 locale) | `https://chroniccare.app/privacy` | 🚨 P0 域名真实性未验证 |
| `support_url.txt` (3 locale) | `https://chroniccare.app/support` | 🚨 P0 同上 |
| `copyright.txt` (3 locale) | "© 2026 chroniccare" / "© 2026 慢病管家" / "© 2026 慢病管家" | ✅ |
| `app_icon.png` (3 locale) | 67 字节占位 | 🚨 P0 |

**R66 → R67 进步**：R66 时 `fastlane/metadata/ios/` 整个目录不存在，R67 Sprint 1 落地 27 个 .txt + 33 个占位图 + README_PLACEHOLDER.txt 说明。**文本字段全部填好，截图仍 67 字节占位**。

---

## 5. 半成品 / TODO

### 5.1 `ios/` 目录

```
ios/Runner/AppDelegate.swift:24:    // 等 v1.0 接阿里云 SMS provider 后启用。本 register 占位, 让 iOS 审核
ios/Runner/AppDelegate.swift:40:  // v0.27 round 67: BGTaskScheduler handler 占位实现
ios/Runner/Base.lproj/Main.storyboard:22:                <placeholder placeholderIdentifier="IBFirstResponder" id="dkx-z0-nzr" sceneMemberID="firstResponder"/>
ios/Runner/Base.lproj/LaunchScreen.storyboard:29:                <placeholder placeholderIdentifier="IBFirstResponder" id="iYj-Kq-Ea1" userLabel="First Responder" sceneMemberID="firstResponder"/>
```

> 4 处全是注释 / storyboard XML 标识符，**0 处代码 TODO**。AppDelegate.swift:24 + :40 是注释说明"占位但 iOS 审核可见"，OK。

### 5.2 `fastlane/` 目录

```
fastlane/Appfile:11:  #   或用 ENV (R67 暂用 hardcode TODO, 后续挪到 ENV)
fastlane/Appfile:20:  # TODO (上 store 前必须替换为真实 Apple ID): 用真实登录邮箱
fastlane/Appfile:22:  # TODO (上 store 前必须替换): Apple Developer Team ID (10 字符, 后台 Membership 页)
fastlane/Appfile:24:  # TODO (上 store 前必须替换): App Store Connect Team ID (ITC 前缀, 后台 Users and Access 页)
fastlane/Fastfile:16:  # 安全注意: Appfile 不要 commit 真实 apple_id (R67 暂留 TODO, 用户替换)
fastlane/metadata/android/zh-CN/video.txt:1:  https://www.youtube.com/watch?v=PLACEHOLDER_APP_DEMO_VIDEO
fastlane/metadata/android/en-US/video.txt:1:  https://www.youtube.com/watch?v=PLACEHOLDER_APP_DEMO_VIDEO
fastlane/metadata/ios/en-US/README_PLACEHOLDER.txt:1-10:  README 说明占位原因 + 替换指南
```

> **3 处代码 TODO** 在 Appfile（apple_id / team_id / itc_team_id 占位）。**1 处元数据 TODO** 在 Android video.txt（不影响 iOS 上架）。**1 处 README** 在 iOS 元数据（解释占位 PNG 原因，OK）。

### 5.3 `assets/legal/` 目录

```
user_agreement.md:3:   > **TODO (上 store 前必须由专业律师过审)**: 本协议当前为 v0.24 草稿, 未经律师过审。
user_agreement.md:4:   > 上 store 前必须: (1) 注册 support@chroniccare.app 邮箱 (1 处 TODO) 并替换为本协议里的邮箱; ...
user_agreement.md:6:   > 集中器见 docs/SPRINT1_LEGAL_TODO.md。
user_agreement.md:60:  - 开发者邮箱: support@chroniccare.app(**TODO 占位 — 上 store 前必须注册并替换为真实邮箱**)
user_agreement.md:61:  - GitHub Issues: https://github.com/example/chroniccare/issues(**TODO 占位, 需确认或替换为真实项目仓库**)
sensitive_data_consent.md:3-4:  > **TODO (上 store 前必须由专业律师过审)**: 本同意书当前为 v0.24 草稿, 未经律师过审。
sensitive_data_consent.md:6:    > 最后更新:2026-07-31 (v0.27 round 67 Sprint 1 — TODO 集中标注)
privacy_policy.md:3-4:  > **TODO (上 store 前必须由专业律师过审)**: 本政策当前为 v0.22 草稿, 未经律师过审。
privacy_policy.md:7:    > 集中器见 docs/SPRINT1_LEGAL_TODO.md。
privacy_policy.md:34:   > ...联系人本人未回复 Y 确认 (R55 TODO — 依赖 SMS provider 真接) 期间, 失联通知整体业务暂停 ...
privacy_policy.md:192:  | 紧急联系人回复 Y 确认 | 短信回复确认机制 | ❌ v0.25 TODO (依赖 SMS provider 真接,见 R55) |
```

> **3 份法律 md 顶部均有"未经律师过审"TODO banner**（P0 必修）。**2 处邮箱占位**（support@ + GitHub URL）。**2 处 R55 SMS 真接 TODO**（业务暂停期间可接受，但应标 ⏸ 暂停而非 ❌ TODO）。

---

## 6. 修复优先级 + 难度

按 P0 提交后必拒 / P0 提交前必做 / P1 警告 / P2 建议 排序：

### 6.1 提交前必做（最小可上架路径）

| 序 | 修复 | 难度 | 阻塞 |
|----|------|------|------|
| 1 | 注册 `support@chroniccare.app` 真实邮箱 | XS | 法务依赖 + 域名注册 |
| 2 | 注册 `chroniccare.app` 域名 + 部署 HTTPS 站点（privacy + support 2 页）| M | 域名注册 + 部署 |
| 3 | 替换 fastlane Appfile 4 个 TODO（apple_id / team_id / itc_team_id / app_identifier 改 `com.chroniccare.app`）| XS | Apple Developer 账号 + App Store Connect 创建 App |
| 4 | 替换 33 张 iOS 截图 + 3 张 app_icon 为真截图 | L | 需 `flutter run` + 模拟器截图脚本（推荐 Screenshot.pro mockup）|
| 5 | 律师过审 3 份法律 md + 移除 TODO banner | L | **最大拦路虎 — 中国执业律师 PIPL 专项 1-2 周** |
| 6 | 删 `user_agreement.md:25, 28` "本 App 售价人民币 8 元" 段（v0.27 期间 App 完全免费）| XS | 或 v0.28 真接 IAP |
| 7 | bump `pubspec.yaml` 版本号到 `1.0.0+1` | XS | — |
| 8 | 跑 `flutter pub get` + `cd ios && pod install` + `flutter build ios --release` 验真 | S | — |
| 9 | 跑 16 守护脚本 + `flutter analyze` + `flutter test` 验绿 | S | — |
| 10 | 跑 `fastlane ios release`（自动 build + 上传 + 提交审核）| S | — |

**总工作量估算**：代码侧 ~6-8h，**法务 review 1-2 周**（不可压缩）。

### 6.2 提交后可能被拒 / 警告

| 序 | 修复 | 难度 | 备注 |
|----|------|------|------|
| 11 | 删 `aps-environment` entitlement（无 APNs）| XS | P1 警告 |
| 12 | 删 `NSUserNotificationUsageDescription` 老 key | XS | P2 建议 |
| 13 | 删 `Main.storyboard` + `UISceneStoryboardFile` + `UIMainStoryboardFile` | S | P2 建议 |
| 14 | 删 `EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64` 3 处 | XS | P2 建议 |
| 15 | `CFBundleDisplayName` per-locale 改 `InfoPlist.strings` | S | P1 警告 |
| 16 | PHQ-9 / GAD-7 16 题英译 | L | P1 警告 |

### 6.3 长期优化（v0.28+）

- ITSAppUsesNonExemptEncryption self-classification 文档
- v0.28 真接阿里云 SMS / SendGrid（恢复失联通知 + Email 关怀）
- v0.28 真接 IAP 8 元 NonConsumablePurchase（需 App Store Connect 创建 productId `com.chroniccare.app.lifetime`）
- v1.0 启用失联通知（阿里云 AccessKey + SendGrid API key + 短信签名模板审核 + 跨境 SMS provider PIPL 评估）

---

## 7. 给开发者的精炼建议

**最快上架最小路径**：① 注册 `chroniccare.app` 域名 + 部署 privacy/support HTTPS 页；② 注册 `support@chroniccare.app` 邮箱；③ 替换 fastlane Appfile 4 个 TODO；④ 截 33 张 iOS 真截图（3 设备 × 3 locale × 3-5 张）；⑤ **律师过审 3 份法律 md**（最大拦路虎 1-2 周）；⑥ 删 `user_agreement.md` "8 元买断"段 + bump 版本到 1.0.0。

**最大拦路虎**：法务 review。Apple 1.4.3 Medical 类 + 中国 PIPL 双重审查，3 份法律 md 含"未经律师过审"TODO banner + `github.com/example/...` 占位 URL = 提交必拒，1-2 周不可压缩。

**R67 进步**：iOS P0 从 11 项降到 **3 项**（截图 + 邮箱 + bundle id 不匹配）；Info.plist 完整；AppDelegate BGTaskScheduler + UNUserNotificationCenter 齐；Privacy Manifest 4 类齐；fastlane 元数据 27 个文本字段全填。R68 剩 ~10 项 P0 主要是**外部依赖**（域名 / 邮箱 / 律师 / 截图），不是代码问题。
