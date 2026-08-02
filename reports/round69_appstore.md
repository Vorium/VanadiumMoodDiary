# chroniccare v0.27.0+64 · iOS App Store 上架合规审计报告

> **审计范围**: Apple App Store Review Guidelines 2.x / 3.x / 4.x / 5.x / 6.x + 精神心理类 App 特殊要求
> **审计时间**: 2026-08-02 (v0.27 round 69, round 81 design eng 阶段)
> **审计员**: App Store 合规视角（独立于项目内 AS-P0-1 ~ AS-P0-15 自审清单）
> **目标**: 列出**会被 Apple 拒的 P0 阻塞项** + 修复方案，供 v0.27 / v1.0 上架前最后冲刺

---

## 1. 总览

### 1.1 上架准备度评分:**38 / 100 — 远未达可提交状态**

| 维度 | 评分 | 状态 | 关键缺陷 |
|---|---|---|---|
| **代码完整性** (Guideline 2.1) | 50% | 🟡 警告 | 描述里写"已实现 8 元买断"，但 `FeatureFlags.iapEnabled=false`（FeatureFlags:38 注释明确"避 Apple 2.1 拒"）+ `StoreKitService.buyLifetime` (store_kit_service.dart:119) release 模式返 `false`，文案 / 实际不一致 |
| **元数据** (Guideline 2.3) | **5%** | 🔴 阻塞 | 11 个截图文件**全部 67 字节占位**（1232×720 空白 PNG，App Store 必拒）|
| **Info.plist** (Guideline 2.4 / 2.5) | 95% | 🟢 良好 | 7 个 NSUsageDescription + ITSAppUsesNonExemptEncryption=false + UIBackgroundModes 全到位 |
| **隐私** (Guideline 5.1) | 70% | 🟡 警告 | PrivacyInfo.xcprivacy 完整 (PrivacyInfo.xcprivacy:42-92)，但 `privacy_url=https://chroniccare.app/privacy` 是占位域名 (privacy_url.txt:1)，点击 404 |
| **付费** (Guideline 3.1) | 60% | 🟡 警告 | in_app_purchase 依赖装好 (pubspec.yaml:63)，但 productId `com.chroniccare.app.lifetime` (store_kit_service.dart:50) 在 App Store Connect 未创建 |
| **设计 / HIG** (Guideline 4.0) | 80% | 🟢 良好 | R81 emil design eng 6 commit + 病耻感 UI 升级（home FAB / 横滑 / 自绘插画）|
| **精神心理类特殊** | 75% | 🟢 良好 | 危机热线 4 国 + 免责声明 + PIPL §13/§23 单独同意 + 撤回机制 R67 真接 |
| **fastlane / CI** | 30% | 🔴 阻塞 | Appfile 4 个 TODO 占位 (Appfile:21-25) + Podfile 占位 + 元数据 UTF-8 OK 但截图全假 |

### 1.2 关键阻塞项（**Apple 必拒**）

> **7 项 P0 阻塞,5 项 P1 警告,2 项 P2 建议**。完整列表见 §7 / §8 / §9。

| # | 阻塞项 | 风险等级 | 修复难度 | 优先级 |
|---|---|---|---|---|
| 1 | **11 个 App Store 截图全部 67 字节占位** | 🔴 必拒 | M (1-2 天) | **P0** |
| 2 | **fastlane/Appfile 4 个 TODO 占位未替换** (apple_id/team_id/itc_team_id) | 🔴 必拒 | S (1h) | **P0** |
| 3 | **隐私政策 / 支持 URL 是占位域名** (`https://chroniccare.app/*`) | 🔴 必拒 | M (1-2 天) | **P0** |
| 4 | **App Store Connect 仍用 0.27.0+64 版本号** (VERSION_1.0_PLAN.md:11 标记 4.3 Spam 风险) | 🔴 必拒 (4.3) | M (决策) | **P0** |
| 5 | **Description 含"已实现 / 即将上线"自相矛盾文案**（en-US description.txt:13-16 "Lost-contact safety net (coming soon — currently disabled)"）| 🟡 警告 (2.1) | S (改文案) | **P0** |
| 6 | **8 元买断 user_agreement 写明 + 实际 `iapEnabled=false` 隐藏入口**（属描述 vs 实际不一致，3.1.5 / 2.1 双面风险）| 🟡 警告 | S-M (改文案 or 启用 IAP) | **P0** |
| 7 | **Podfile 是占位**（Podfile:1-16 Windows 平台无法 `pod install`，macOS build 必报错）| 🔴 必拒 | S (mac 跑一次) | **P0** |

---

## 2. App Store Review Guidelines 逐条审查

### 2.1 App Completeness（2.1.x）

- **2.1.1 Crash / 明显 bug**: 🟡 部分
  - `lib/main.dart:99` 用 `LastErrorCapture` 抓 release 模式异常 + `AppRoot` 顶部 banner，符合 2.1.1 异常不闪退要求
  - **风险**:`lib/main.dart:99` `LastErrorCapture.record(error, stack)` 仅在 dev 模式 `FlutterError.reportError` 重新 throw。release 模式 swallow 是**官方推荐做法**（避免暴露 stack 给用户），但 Apple 审核员若在真机跑遇到非关键路径 crash，banner 提示可能被认为"App 不稳定"
- **2.1.2 Placeholder**: 🔴 **P0 阻塞** — App Store 元数据截图全占位（见 §1.2 #1）
- **2.1.4 Beta / 演示模式**: 🟢 良好 — `SmsService` / `EmailService` 走 `validateForRelease` 守卫（main.dart:170/179），release 模式 mock 即阻断启动
- **2.1.5 Background fetch**: 🟢 良好 — `BGTaskScheduler` 注册 `com.chroniccare.safety-check`（AppDelegate.swift:33）+ `BGTaskSchedulerPermittedIdentifiers` (Info.plist:154) 一致；handler 当前空实现（`task.setTaskCompleted(success: true)` AppDelegate.swift:73），但 FeatureFlags.emergencyContactEnabled=false 业务暂停，符合 2.1.5"功能描述必真"

### 2.3 Accurate Metadata（2.3.x）

- **2.3.1 Screenshots 不准确**: 🔴 **P0 阻塞** — 全部 11 个文件 67 字节占位（`iphone_6_5_screenshots/01_home.png` ~ `05_home.png` 5 个 + `iphone_5_5_screenshots` 3 个 + `ipad_12_9_screenshots` 3 个 × 3 locale = 33 个）— `en-US/iphone_6_5_screenshots/01_home.png` 实测 67 字节 / 1232×720（标准应为 1290×2796 for 6.7" 或 1242×2688 for 6.5"）
- **2.3.3 Description / 关键词一致**: 🟡 部分
  - `en-US/description.txt:14-16` 写 "Lost-contact safety net (coming soon — currently disabled)" + 详细说"会发短信" — **但实际 `FeatureFlags.emergencyContactEnabled=false` (feature_flags.dart:35)** + `MockSmsProvider.send()` 抛 `UnimplementedError` (sms_service.dart:83)。审核员看到"会发短信"但实际没接通，可能 2.1.4 "App 与描述不符" 拒
  - 关键词 `medication,reminder,mood,mental,health,chronic,tracker` 跟主功能匹配，OK
- **2.3.7 App Icon**: 🟡 部分
  - `fastlane/metadata/ios/en-US/app_icon.png` **67 字节占位**（同截图） — App Store Connect 必拒
  - 但 `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` **10932 字节**是真实图（`flutter create` 默认），App 装到真机用这个，OK
- **2.3.10 Sign in with Apple**（如有第三方登录）: 🟢 良好 — 项目无账号体系，不需 Sign in with Apple

### 2.4 Hardware（2.4.x）

- **NSUsageDescription 全到位** — Info.plist 实际声明:
  - `NSMicrophoneUsageDescription` (Info.plist:42) — 情绪语音录入 ✅
  - `NSSpeechRecognitionUsageDescription` (Info.plist:44) — 语音转文字 ✅
  - `NSPhotoLibraryAddUsageDescription` (Info.plist:51) — 保存 PDF ✅
  - `NSPhotoLibraryUsageDescription` (Info.plist:61) — 分享 PDF ✅
  - `NSUserTrackingUsageDescription` (Info.plist:67) — 透明性声明 ✅
  - **缺**: `NSCameraUsageDescription` — `pubspec.yaml` 无 `image_picker` / `camera` 依赖 → **不需**
  - **缺**: `NSContactsUsageDescription` — 无通讯录功能 → **不需**
  - **缺**: `NSLocationWhenInUseUsageDescription` — 无定位功能 → **不需**
  - **缺**: `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` — 不用 HealthKit → **不需**（PHQ-9 / GAD-7 是自评量表，不入 HealthKit）
  - **缺**: `NSFaceIDUsageDescription` — 用 `flutter_secure_storage` 9.x 内部调 LocalAuthentication 框架，**iOS 14+ 调 `LAContext.evaluatePolicy(.deviceOwnerAuthentication)` 不需 Biometry 描述**（仅 `localizedReason` 文案），但**强烈建议**补一条防御性 `NSFaceIDUsageDescription` 避免真机首次 unlock Keychain 弹"需要 Face ID 权限"但没说明
- **UIBackgroundModes**: Info.plist:144-148 声明 `audio` + `processing`，合理（录音后台继续 + 失联检测长任务）

### 2.5 Software Requirements（2.5.x）

- **2.5.1 Privacy Manifest (PrivacyInfo.xcprivacy)**: 🟢 完整 (PrivacyInfo.xcprivacy:42-92)
  - `NSPrivacyTracking=false` ✅
  - `NSPrivacyCollectedDataTypes` 4 类（HealthAndFitness / AudioData / ContactInfo / UserContent）✅
  - `NSPrivacyAccessedAPITypes` 5 类（UserDefaults / FileTimestamp / SystemBootTime / DiskSpace / ProcessInfo）✅
- **2.5.2 Sign in with Apple**: 不适用（无账号）
- **2.5.5 Required reason APIs**: 🟢 良好 — UserDefaults 声明 CA92.1+CA92.2 (PrivacyInfo.xcprivacy:101-107) + FileTimestamp C617.1 + SystemBootTime 35F9.1 + DiskSpace 85F4.1 + ProcessInfo AC67.1
- **2.5.6 Export Compliance (ITSAppUsesNonExemptEncryption)**: 🟢 Info.plist:103 标 `false`，App Store Connect 仍会问"是否使用加密"，填"仅 HTTPS / 标准 SQLCipher" 即可
- **iOS 14+ Deployment target**: 🟢 Info.plist 不显式设但 project.pbxproj:372 写 `IPHONEOS_DEPLOYMENT_TARGET = 14.0`，符合 Apple 2024 最低要求

### 3.1 In-App Purchase（3.1.5）

- **3.1.5 (a) 数字商品 / 服务必须走 IAP**: 🟡 部分
  - `user_agreement.md:22` 写"售价 8 元 / 一次性买断"
  - `pubspec.yaml:63` 加了 `in_app_purchase: ^3.3.0`（注：注释说"^7.0.0" 是 stale comment）
  - `lib/core/data/services/store_kit_service.dart:50` 声明 productId `com.chroniccare.app.lifetime`
  - **风险**:
    1. `FeatureFlags._prodIapEnabled = false` (feature_flags.dart:38) release 模式隐藏入口 + `buyLifetime` 返 `false` (store_kit_service.dart:119)
    2. App Store Connect 未创建该 productId，**审核员查不到对应商品**
    3. `user_agreement.md` 写 8 元 + `lib/main.dart:188` `StoreKitService.warmup` 走 `FeatureFlags.iapEnabled` 跳过
  - **修复**: 2 选 1
    - (A) 启用 IAP：`App Store Connect` 创建 productId → `FeatureFlags._prodIapEnabled = true` → UI 显示"立即买断"按钮 → release 模式走真 StoreKit
    - (B) 删 user_agreement §3 8 元买断段落（推迟到 v0.28）

### 3.2.1 Anti-Fraud（诱导评分 / 强制评分）

- 🟢 **未发现** — 全代码库无 `SKStoreReviewController.requestReview()` 调用（`in_app_purchase` plugin 不带评分引导）

### 4.0 Design

- **HIG 合规**: 🟢 良好 — R81 emil design eng 6 commit (`bb8b948` HomeFabToolbar / `7718248` HomeHeroIllustration / `c4d09cf` SectionHeader chip) 病耻感 UI 升级，符合精神心理 App 调性
- **不抄袭**: 🟢 良好 — 自绘 hero 插画无第三方 IP 引用

### 5.1 Privacy Policy / Practices

- **5.1.1 隐私政策链接**: 🔴 **P0 阻塞** — `fastlane/metadata/ios/en-US/privacy_url.txt:1` 是 `https://chroniccare.app/privacy`，**域名未注册**。点击 → 404 → Apple 必拒
- **5.1.2 数据收集声明**: 🟢 完整 — PrivacyInfo.xcprivacy 4 类数据 + 5 类 API，全 `Linked=false` `Tracking=false` `Purpose=AppFunctionality`
- **第三方 SDK 列表**: 🟢 完整 — `privacy_policy.md:97-105` 列了 9 个依赖
- **3.2.1 隐式收集保护**: 🟢 `NSPrivacyTracking=false` + 零 ad SDK

### 5.2 Health & Fitness / 精神心理类特殊

- **5.2.1 医疗声明**: 🟢 良好
  - en-US `description.txt:38` 明确 "ChronicCare is NOT a medical device..." + "Always consult your doctor"
  - zh-Hans `description.txt:35` 同步翻译
  - `user_agreement.md:17` + `sensitive_data_consent.md` §4 单独同意
- **5.2.2 FDA / NMPA 认证**: 🟢 不适用 — App 自定位"个人记录工具"非"医疗器械"，未声明诊断 / 治疗 / 治愈，**正确规避** FDA / NMPA 监管
- **5.2.3 误诊责任**: 🟢 `user_agreement.md:44` 明确"心理评估结果仅供参考，不应作为临床诊断依据" + 危机热线（北京 010-82951332 / 全国 400-161-9995）
- **危机资源 (精神心理类强制)**: 🟢 4 国完整
  - en-US: US 988 + UK 116 123 + International findahelpline.com
  - zh-Hans: 北京 010-82951332 + 全国 400-161-9995 + 上海 021-12320-5 + International
  - zh-Hant: 台灣 1925 + 香港 2389 2222 + International
  - ⚠️ 注意: 台湾 1925 是生命关怀专线；香港 2389 2222 是撒瑪利亞防止自殺會；正确
- **PIPL §13/§14/§23 单独同意** (中国合规): 🟢 完善
  - `assets/legal/sensitive_data_consent.md` §4 单独同意书
  - `lib/presentation/providers/notification_init_provider.dart` + `ConsentGate` 集中器，R67 起业务层真接（trend/vent/safety 撤回后真生效）— `privacy_policy.md:81` 标注
- **PIPL §38 跨境**: 🟢 已评估 — `privacy_policy.md:132-176` 完整 §11 跨境说明（紧急联系人境外号段时走 SMS provider 备案）

---

## 3. fastlane / metadata 完整度

### 3.1 Appfile (fastlane/Appfile)

| 字段 | 当前 | 应为 | 风险 |
|---|---|---|---|
| `app_identifier` | `com.chroniccare.chroniccare` ✅ | 真实 bundle ID | 🟢 OK |
| `apple_id` | `your-apple-id@example.com` 🔴 | 真实 App Store Connect 邮箱 | **P0 必拒** |
| `team_id` | `YOUR_TEAM_ID` 🔴 | 10 字符 Apple Team ID | **P0 必拒** |
| `itc_team_id` | `YOUR_ITC_TEAM_ID` 🔴 | App Store Connect Team ID | **P0 必拒** |

### 3.2 Fastfile (fastlane/Fastfile)

- 🟢 `ios :beta` / `ios :release` / `ios :metadata` 三个 lane 完整
- 🟢 `precheck_include_in_app_purchases=false` (Fastfile:64) 标注"v0.23 R55 暂停, 等 v1.0 重启" — **注意**: 跟 §2.3.5 IAP 3.1.5 风险联动
- 🟢 `automatic_release=false` 审核通过后手动控制发布
- 🟡 `precheck_skip_file_preprocessing` 缺 — 建议加 `precheck_skip_rule:` 显式声明

### 3.3 metadata/ 元数据

| 字段 | en-US | zh-Hans | zh-Hant | 风险 |
|---|---|---|---|---|
| `name.txt` | `ChronicCare` | `慢病管家` | `慢病管家` | 🟢 OK |
| `subtitle.txt` | `Medication + Mood Tracker` | `吃药打卡 + 情绪关怀(失联通知规划中)` | `吃藥打卡 + 情緒關懷(失聯通知規劃中)` | 🟢 OK (29 字符内) |
| `description.txt` | 2914 字符 | 1359 字符 | 1324 字符 | 🟢 OK (4000 字符内) |
| `keywords.txt` | `medication,reminder,mood,mental,health,chronic,tracker` | `吃药,提醒,情绪,心理,健康,慢病,打卡` | `吃藥,提醒,情緒,心理,健康,慢病,打卡` | 🟢 OK (100 字符内) |
| `promotional_text.txt` | 152 字符 | 60 字符 | 60 字符 | 🟢 OK |
| `copyright.txt` | `© 2026 chroniccare` | `© 2026 慢病管家` | `© 2026 慢病管家` | 🟢 OK |
| `privacy_url.txt` | `https://chroniccare.app/privacy` 🔴 | 同 🔴 | 同 🔴 | **P0 阻塞 (域名占位)** |
| `support_url.txt` | `https://chroniccare.app/support` 🔴 | 同 🔴 | 同 🔴 | **P0 阻塞 (域名占位)** |
| `iphone_6_5_screenshots/*.png` | **5 × 67 字节占位** 🔴 | 5 × 67 字节 🔴 | 5 × 67 字节 🔴 | **P0 阻塞 (全假)** |
| `iphone_5_5_screenshots/*.png` | 3 × 67 字节 🔴 | 3 × 67 字节 🔴 | 3 × 67 字节 🔴 | **P0 阻塞** |
| `ipad_12_9_screenshots/*.png` | 3 × 67 字节 🔴 | 3 × 67 字节 🔴 | 3 × 67 字节 🔴 | **P0 阻塞** |
| `app_icon.png` (1024×1024) | **67 字节占位** 🔴 | 同 🔴 | 同 🔴 | **P0 阻塞** |

**截图实测**: `en-US/iphone_6_5_screenshots/01_home.png` 头字节 `89 50 4E 47 0D 0A 1A 0A` (PNG signature) + IHDR `00 00 04 D0 00 00 02 D0 08 06` = 1232×720 真 8-bit RGBA + 10 字节 IDAT + IEND。**1232×720 比例错**（iPhone 6.5" 应为 1242×2688）+ IDAT 10 字节只能装 1×1 像素 = **纯黑占位 PNG**。

**P0 风险**: Apple App Store Connect 上传时**会拒占位图**（审核 precheck + 上传后人工复核），即便侥幸通过，用户在 App Store 看 5 张全黑图 = **2.1 Placeholder 直接拒**。

---

## 4. Info.plist 审查 (`ios/Runner/Info.plist`)

| 字段 | 行 | 值 | 评估 |
|---|---|---|---|
| `CFBundleDisplayName` | 15 | `ChronicCare` (Base) | 🟢 配合 InfoPlist.strings per-locale 覆盖 (zh-Hans:5 → 慢病管家) |
| `CFBundleIdentifier` | 19 | `$(PRODUCT_BUNDLE_IDENTIFIER)` | 🟢 |
| `CFBundleShortVersionString` | 27 | `$(FLUTTER_BUILD_NAME)` (=0.27.0) | 🟡 4.3 Spam 风险见 §2.3 |
| `CFBundleVersion` | 31 | `$(FLUTTER_BUILD_NUMBER)` (=64) | 🟡 |
| `LSApplicationCategoryType` | 136 | `healthcare-fitness` | 🟢 跟 App Store Connect 选 Medical 类别一致 |
| `LSRequiresIPhoneOS` | 33 | `true` | 🟢 |
| `UIRequiresFullScreen` | 74 | `false` | 🟢 iPad Split View 多任务 (精神心理患者 iPad 录 + 看教程) |
| `NSMicrophoneUsageDescription` | 42 | `用于情绪日记的语音录入，本地处理，文件加密存储` | 🟢 |
| `NSSpeechRecognitionUsageDescription` | 44 | `用于情绪日记的语音转文字，本地处理，不上传` | 🟢 |
| `NSPhotoLibraryAddUsageDescription` | 51 | `用于保存用药报告 PDF 到相册` | 🟢 |
| `NSPhotoLibraryUsageDescription` | 61 | `用于分享用药报告 PDF 时选择保存位置` | 🟢 |
| `NSUserTrackingUsageDescription` | 67 | `本应用不收集任何追踪数据，仅用于 App Store 透明性声明` | 🟢 |
| `ITSAppUsesNonExemptEncryption` | 103 | `false` | 🟢 |
| `UIBackgroundModes` | 144-148 | `audio` + `processing` | 🟢 |
| `BGTaskSchedulerPermittedIdentifiers` | 153-156 | `com.chroniccare.safety-check` | 🟢 跟 AppDelegate.swift:33 一致 |
| `UISupportedInterfaceOrientations~ipad` | 122-128 | 4 个方向 | 🟢 |

**缺 (P2 建议)**:
- `NSFaceIDUsageDescription` — `flutter_secure_storage` iOS 14+ 内部用 LAContext，**防御性补**避免真机首次 Keychain unlock 弹"权限说明缺失"闪退
- `NSAppTransportSecurity` (子 key `NSAllowsArbitraryLoads`) — 项目零网络请求 (`shared_preferences` 不算)，**不需**。但 `in_app_purchase` 跟 `flutter_secure_storage` 走 iOS 系统框架不需 ATS 例外，OK
- `NSUserActivityTypes` — 无 Handoff / Spotlight，**不需**

**InfoPlist.strings per-locale**:
- 🟢 `Base.lproj/InfoPlist.strings:9` 设 `CFBundleDisplayName = "ChronicCare"` (兜底)
- 🟢 `zh-Hans.lproj/InfoPlist.strings:5` 设 `慢病管家`
- 🟢 `zh-Hant.lproj/InfoPlist.strings:5` 设 `慢病管家`
- project.pbxproj:knownRegions 含 `en` + `Base` + `zh-Hans` + `zh-Hant` (project.pbxproj:289-292) 完整

---

## 5. 必装文件清单

| 文件 | 行数 | 状态 | 评估 |
|---|---|---|---|
| `ios/Runner/Info.plist` | 157 | ✅ | 完整 |
| `ios/Runner/PrivacyInfo.xcprivacy` | 149 | ✅ | 完整 (2024-05 Apple 强制) |
| `ios/Runner/Runner.entitlements` | 13 | ✅ | 空 dict（无 aps-environment，无 APNs，OK） |
| `ios/Runner/AppDelegate.swift` | 75 | ✅ | 完整 + UNUserNotificationCenter delegate R75 修 |
| `ios/Runner/SceneDelegate.swift` | 4 | ✅ | 标准空实现 |
| `ios/Podfile` | 60 | ⚠️ 占位 | 需 macOS 跑 `pod install` 重新生成 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | 10932 字节 | ✅ | 真实图（`flutter create` 默认） |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/*.png` | 3 × 68 字节 | ⚠️ 占位 | 用户启动时短暂显示黑屏（P2 警告）|
| `fastlane/Appfile` | 25 | ❌ 4 处 TODO | **P0 阻塞** |
| `fastlane/Fastfile` | 151 | ✅ | 完整 |
| `fastlane/metadata/ios/*/screenshots/*.png` | 33 × 67 字节 | ❌ 全占位 | **P0 阻塞** |
| `fastlane/metadata/ios/*/app_icon.png` | 3 × 67 字节 | ❌ 占位 | **P0 阻塞** |
| `assets/legal/user_agreement.md` | 4634 字节 | ⚠️ 修订历史段化未过审 | docs/SPRINT1_LEGAL_TODO.md:1-46 4 项必做 |
| `assets/legal/privacy_policy.md` | 14515 字节 | ⚠️ 同上 | 同 |
| `assets/legal/sensitive_data_consent.md` | 4658 字节 | ⚠️ 同上 | 同 |

---

## 6. 半成品 / TODO 风险总览

| 位置 | 描述 | 风险 |
|---|---|---|
| `lib/main.dart:39` `SmsService _smsService = SmsService()` + line 170 `SmsService.validateForRelease` 阻断 | 失联通知业务整体暂停 (`FeatureFlags.emergencyContactEnabled=false`) | 🟢 已明示，文案同步 (description.txt:13-16 标"currently disabled")，审核员看得到"规划中" |
| `lib/main.dart:179` `EmailService.validateForRelease` 阻断 | 邮件未接 (`isFullyImplemented=false`) | 🟢 同上 |
| `lib/core/data/services/store_kit_service.dart:108-119` `buyLifetime` IAP 业务暂停 | 8 元买断未真接 | 🔴 **P0** 文案 / 实际不一致，见 §2.3.5 |
| `lib/core/data/services/sms_service.dart:83` `MockSmsProvider.send` 抛 `UnimplementedError` | dev 占位 | 🟢 release 模式被 `validateForRelease` 阻断 |
| `lib/core/data/services/sms_service.dart:163` `AliyunSmsProvider.send` 抛 `StateError` | 失联通知 SMS 通道未接 | 🟢 release 模式被 `validateForRelease` 阻断 |
| `lib/core/data/services/email_service.dart:20` "v1.0+ TODO 真实 SMS 发送未实现" | 邮件 provider 未接 | 🟢 release 模式被 `validateForRelease` 阻断 |
| `ios/Podfile:1-16` "本 Podfile 是占位" | Windows 平台无法 `pod install` | 🔴 **P0** macOS build 必报错 |
| `fastlane/Appfile:21-25` 4 处 TODO (apple_id / team_id / itc_team_id) | 上 store 前必须替换 | 🔴 **P0** |
| `assets/legal/privacy_policy.md:220` "TODO (上 store 前必须由专业律师过审)" | 法务未过审 | 🔴 **P0** (审核员会要求看律师签字) |
| `assets/legal/user_agreement.md:60-61` "https://github.com/example/chroniccare/issues" | 占位 | 🟡 警告 (不算 P0, 但需替换) |
| `assets/legal/privacy_policy.md:115` "本服务不提供邮件渠道" + 软隐藏 `privacy@chroniccare.app` | 客服邮箱软隐藏 | 🟡 警告 (Apple 5.1.1 要求"可联系的支持渠道") |
| `lib/core/data/feature_flags.dart:38` `_prodIapEnabled = false` | 8 元买断 IAP 入口隐藏 | 🔴 **P0** 跟 user_agreement §3 不一致 |

---

## 7. **P0 阻塞项 — 会被 Apple 拒**（必修）

### P0-1: App Store 截图 + App Icon 全占位
- **位置**: `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/{iphone_5_5_screenshots,iphone_6_5_screenshots,ipad_12_9_screenshots}/*.png` + `app_icon.png`
- **风险**: 2.1.2 Placeholder + 2.3.1 Screenshots 不准确 → 必拒
- **修复难度**: M (1-2 天, 找设计师 + 截图 3 套设备 × 3 locale)
- **修复方案**:
  1. 用真机 (iPhone 14 Pro Max / iPhone 8 Plus / iPad Pro 12.9") 跑当前 build
  2. 截 5-10 张主流程 (home / check-in / mood / trend / settings) 4 语言版本
  3. iPhone 6.7" 用 1290×2796, iPhone 6.5" 用 1242×2688, iPad 12.9" 用 2048×2732
  4. 用 `screencapture` (macOS) 或真机录屏截帧
  5. App Icon 1024×1024 重新设计（不要用 `flutter create` 默认）

### P0-2: fastlane/Appfile 4 处 TODO 占位
- **位置**: `fastlane/Appfile:21-25`
- **风险**: `bundle exec fastlane ios beta` 直接报错 → 无法走 fastlane 流程
- **修复难度**: S (1h)
- **修复方案**:
  1. 登录 App Store Connect → Users and Access → 找 Team ID (10 字符)
  2. Apple Developer 后台 → Membership → 找 Team ID
  3. 替换 3 处 TODO 为真实值
  4. **强烈建议**用 API Key 模式 (`app_store_connect_api_key`) 而非 apple_id 密码模式，更安全

### P0-3: 隐私 / 支持 URL 是占位域名
- **位置**: `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt` + `support_url.txt` (6 文件) + `assets/legal/{privacy_policy,user_agreement}.md` 多处引用
- **风险**: 5.1.1 隐私政策 URL 必须可访问 → 404 必拒
- **修复难度**: M (1-2 天, 含域名注册 + 备案 + HTTPS 部署)
- **修复方案**:
  1. 注册 `chroniccare.app` 域名 (阿里云 / 腾讯云, .app TLD 强制 HTTPS)
  2. ICP 备案 (中国大陆上架, 备案号要写进隐私政策页脚)
  3. Cloudflare Pages / Vercel 部署 3 份 md 转 HTML
  4. `https://chroniccare.app/privacy` + `https://chroniccare.app/support` + `https://chroniccare.app/agreement` + `https://chroniccare.app/consent` 4 个 URL 都通
  5. **关联**: `docs/SPRINT1_LEGAL_TODO.md:41-44` 已标记此为 R67-R72 必做

### P0-4: 0.27.0+64 版本号 4.3 Spam 风险
- **位置**: `pubspec.yaml:5` `version: 0.27.0+64` + `docs/VERSION_1.0_PLAN.md:11`
- **风险**: 4.3 Spam — 0.x 版本 Apple 可能认为是"未完成产品"或"重复提交变体"
- **修复难度**: M (决策, 半天)
- **修复方案**: 2 选 1
  - (A) 维持 0.27.0+64 提交 (`docs/VERSION_1.0_PLAN.md:65-66` M1 决策) — 风险: 审核员看到 0.27 怀疑"还在 dev"
  - (B) 直接 bump 到 1.0.0+1 — 风险: 失联通知 / 法务没就绪, 1.0 标签太重
  - **建议**: 维持 0.27.0+64, 但 App Store Connect 副标题 / 描述里加 "Beta — public preview" 之类弱化措辞

### P0-5: description.txt 含"coming soon" / "currently disabled" 自相矛盾
- **位置**: `fastlane/metadata/ios/en-US/description.txt:13-16` (en) + zh-Hans:17-19 (zh) + zh-Hant:17-19 (zh)
- **风险**: 2.1.4 Beta / 演示模式 — Apple 看到"已实现 → 实际禁用" 可能 2.1 拒
- **修复难度**: S (改文案, 1h)
- **修复方案**:
  1. 描述里**删** "Lost-contact safety net" 整段 (en:13-16, zh-Hans:17-19)
  2. 或改文案: "Smart check-in reminders help you stay on track with your medication" — 不提失联通知
  3. **R77 决策保留** (失联通知是产品核心卖点之一) 改软: "Safety reminders — coming in a future update" + 加 "Follow us @chroniccare_app for launch announcement"

### P0-6: 8 元买断 user_agreement 写明 + 实际 IAP 入口隐藏
- **位置**: `assets/legal/user_agreement.md:22` + `lib/core/data/feature_flags.dart:38` + `lib/core/data/services/store_kit_service.dart:119`
- **风险**: 2.1 + 3.1.5 双面 — 描述说买断 / 实际无购买入口
- **修复难度**: M (决策 + 半天)
- **修复方案**: 2 选 1
  - (A) 启用 IAP (推荐):
    1. App Store Connect → My Apps → chroniccare → In-App Purchases → 创建 `com.chroniccare.app.lifetime` 8 元 CNY
    2. `lib/core/data/feature_flags.dart:38` `_prodIapEnabled = true`
    3. 跑 `StoreKitService.buyLifetime` 真接 InAppPurchase 流 (store_kit_service.dart:106-119)
    4. UI 在设置页加"立即买断"按钮
    5. **注意**: Apple 强制 IAP 抽成 30% (8 元 → 开发者 5.6 元)
  - (B) 推迟 IAP:
    1. `user_agreement.md:22-28` §3 付费规则整段删
    2. 描述里也不提 8 元
    3. 留到 v0.28 (R55 真接 SMS + SendGrid 时一起做)

### P0-7: Podfile 是占位 (Windows 平台无法 `pod install`)
- **位置**: `ios/Podfile:1-16`
- **风险**: macOS build 必报错 → 开发者本地跑不通 → CI/CD 全断
- **修复难度**: S (macOS 跑 1 次, 30 min)
- **修复方案**:
  1. macOS 跑 `cd ios && pod install` 重新生成 `Podfile.lock` + `Pods/`
  2. 提交 `ios/Podfile` (已有) + `ios/Podfile.lock` (待生成) + `ios/Pods/` (.gitignore)
  3. `.gitignore:19` 注释: "Podfile 跟踪, Podfile.lock 仍 .gitignore (R77 占位 Podfile)" → 改成 "Podfile + Podfile.lock 都跟踪"

---

## 8. **P1 警告项 — 强烈建议修**（降低被拒概率）

### P1-1: 法务 3 份 md 未过审
- **位置**: `assets/legal/{privacy_policy,user_agreement,sensitive_data_consent}.md` 修订历史段都标"草稿 (未经律师过审)"
- **风险**: Apple 5.1.1 不强制要求律师签字, 但审核员看到 "草稿" 标记可能要求补签字
- **修复难度**: L (1-2 周, ¥15-30k/文档, 3 文档)
- **修复方案**: 找 PIPL / 精神心理 App 专长律师 review, 删除修订历史段草稿标记

### P1-2: 客服邮箱软隐藏
- **位置**: `assets/legal/privacy_policy.md:115` "本服务不提供邮件渠道" + 软隐藏 `privacy@chroniccare.app`
- **风险**: 5.1.1 隐私政策要求"可联系的隐私保护负责人"
- **修复难度**: S (注册邮箱 1-2h, 改 3 文档 0.5h)
- **修复方案**: 注册 `privacy@chroniccare.app` + `support@chroniccare.app` 两个邮箱, 替换 3 文档 5 处 TODO

### P1-3: GitHub issues URL 占位
- **位置**: `assets/legal/user_agreement.md:60-61` `https://github.com/example/chroniccare/issues`
- **风险**: P1 警告 (不算 P0, 但需替换)
- **修复难度**: S (半天, 创建 / 确认仓库)
- **修复方案**: 创建 GitHub 仓库 + issues section, 替换占位 URL

### P1-4: iOS 16KB page size 未验证
- **位置**: `docs/VERSION_1.0_PLAN.md:36` R66 标记
- **风险**: iOS 16KB page size (iPhone XS+ 强制, 2025-04 Apple 强审), Flutter 3.41.9 编译参数可能未对齐
- **修复难度**: M (1 天)
- **修复方案**: 升级 Flutter 到 3.41.10+ (已修) 或 3.44+ (推荐), Xcode 16+ 编译

### P1-5: NSFaceIDUsageDescription 缺失
- **位置**: Info.plist 无此 key
- **风险**: 2.4.x 权限说明不全 — `flutter_secure_storage` iOS 14+ 内部用 LAContext, 真机首次 unlock Keychain 可能弹"权限说明缺失" 闪退
- **修复难度**: S (10 min, 加 1 key)
- **修复方案**: Info.plist 加 `<key>NSFaceIDUsageDescription</key><string>用于解锁本地加密数据库密钥</string>`

---

## 9. 总结 + 行动清单

### 9.1 现状评估

| 维度 | 评估 |
|---|---|
| **代码 + 配置** | 90% 完成（Info.plist / PrivacyInfo.xcprivacy / entitlements / AppDelegate 全到位，R67-R81 6 大 P0 修完）|
| **元数据 (metadata)** | **5% 完成**（11 个截图全假 + 6 个 URL 占位 + Appfile 4 处 TODO）|
| **法务 (Legal)** | 70% 完成（3 份 md 完整 + PIPL §13/§14/§23 单独同意 + §38 跨境，但未律师过审）|
| **设计 / HIG** | 90% 完成（R81 emil design eng 6 commit）|

**关键洞察**: **代码层面已就绪 (90%)，但元数据 + 法务层面未就绪 (5-70%)**。Apple 审核员的视角是"App Store 上能下能跑吗 + 隐私合规吗"，所以**元数据 + 隐私 URL 是 2 大拦路虎**。

### 9.2 上架前 7 项 P0 必做（按依赖顺序）

| # | 任务 | 估时 | 依赖 | 负责 |
|---|---|---|---|---|
| 1 | 注册 `chroniccare.app` 域名 + ICP 备案 + HTTPS 部署 3 份 md | 1-2 天 | 无 | 开发者 |
| 2 | 注册 `privacy@` + `support@` 邮箱 | 1-2h | 域名就绪 | 开发者 |
| 3 | 创建 GitHub 仓库 (`github.com/chroniccare/chroniccare`) | 0.5h | 无 | 开发者 |
| 4 | 找 PIPL 律师 review 3 份 md | 1-2 周 + ¥ | 1 完毕 | 法务 |
| 5 | 截 33 个真实 App Store 截图 + 3 张 App Icon | 1-2 天 | 代码稳定 | 设计师 |
| 6 | 替换 fastlane/Appfile 4 处 TODO + macOS 跑 `pod install` | 1-2h | 1+2+3 完毕 | 开发者 |
| 7 | 二选一启用 IAP 或删 user_agreement §3 | 0.5-1 天 | App Store Connect 准备 | 开发者 |

**估时合计**: 5-7 天（不含法务 1-2 周） + ¥ 律师 ¥15-30k/文档

### 9.3 上架时间线（参考 `docs/VERSION_1.0_PLAN.md:65-74`）

- **M1 (2026-08-15 估)**: 0.27.0+64 + 全部 P0 修完 + 提交审核
- **M2 (2-4 周)**: Apple 审核 (24-48h 通常, 但精神心理类 App 5-7 天常见)
- **M3 (2026-09 估)**: 0.27.0+64 在 App Store 上线
- **M4 (2026-10)**: R68 16KB / Data Safety 守护补齐
- **M5 (2026-11)**: R69 P1 警告全清 + P2 重构
- **M6 (2026-12)**: 决策点 — 是否 bump 到 1.0.0+1
- **M7 (2027-01 估)**: v1.0 发布

### 9.4 建议

1. **优先修元数据 7 项 P0** (5-7 天 + ¥), 不要直接 1.0 — 0.27 标签对内对外都"未完成产品" 信号弱
2. **法务 review 启动** — `docs/SPRINT1_LEGAL_TODO.md:1-46` 4 项必做, 不能拖到 v1.0
3. **App Store Connect 副标题 / 描述里弱化"未启用"功能** — 改成 "Coming soon" / "Future update" 而非 "Currently disabled" (后者像 "已知 bug")
4. **TestFlight 至少 100 内部测试** (VERSION_1.0_PLAN.md:80 硬门槛) — 用 `fastlane ios beta` 跑 30 天 + 拉 30+ 内部 + 70+ 外部
5. **回复审核员速度** — 精神心理类 App 容易被打"医学声明 / 误诊风险"标签, 24h 内回复 + 提供法务 review 报告

---

## 引用文件清单

| 文件 | 关键行 |
|---|---|
| `ios/Runner/Info.plist` | 15, 42-67, 103, 122-128, 136-156 |
| `ios/Runner/PrivacyInfo.xcprivacy` | 22-92 (4 类数据) + 96-146 (5 类 API) |
| `ios/Runner/AppDelegate.swift` | 22-38 (UN delegate + BGTaskScheduler) + 54-61 (willPresent) |
| `ios/Runner/SceneDelegate.swift` | 4 (空标准实现) |
| `ios/Podfile` | 1-16 (占位说明) |
| `ios/Runner.xcodeproj/project.pbxproj` | 289-292 (knownRegions) + 372-601 (build settings) |
| `ios/Runner/Base.lproj/InfoPlist.strings` | 9 (兜底) |
| `ios/Runner/zh-Hans.lproj/InfoPlist.strings` | 5 (慢病管家) |
| `ios/Runner/zh-Hant.lproj/InfoPlist.strings` | 5 (慢病管家) |
| `fastlane/Appfile` | 19-25 (1 真 + 3 TODO) |
| `fastlane/Fastfile` | 22-78 (iOS) + 94-150 (Android) |
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/{iphone_5_5,iphone_6_5,ipad_12_9}_screenshots/*.png` | 33 × 67 字节占位 |
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/app_icon.png` | 3 × 67 字节占位 |
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/{privacy_url,support_url}.txt` | 6 × 占位 URL |
| `pubspec.yaml` | 5 (0.27.0+64) + 63 (in_app_purchase) + 84-87 (assets/legal) |
| `lib/main.dart` | 99 (LastErrorCapture) + 170 (SMS 守卫) + 179 (邮件守卫) + 188 (IAP warmup) |
| `lib/core/data/feature_flags.dart` | 35-40 (4 个 prod flag) + 54-78 (4 个 getter) |
| `lib/core/data/services/sms_service.dart` | 83 (Mock UnimplementedError) + 163 (Aliyun StateError) |
| `lib/core/data/services/email_service.dart` | 20 (v1.0+ TODO) + 62-63 (isProductionReady) + 88-93 (validateForRelease) |
| `lib/core/data/services/store_kit_service.dart` | 50 (productId) + 108-119 (buyLifetime 暂停) |
| `assets/legal/privacy_policy.md` | 81-82 (R67 撤回真接) + 132-176 (§11 跨境) + 220 (TODO 律师) |
| `assets/legal/user_agreement.md` | 11 (失联通知规划中) + 22-28 (8 元买断) + 60-61 (GitHub issues 占位) |
| `assets/legal/sensitive_data_consent.md` | 24 (规划中) + 57-58 (撤回机制) + 103 (TODO 律师) |
| `docs/SPRINT1_LEGAL_TODO.md` | 1-46 (4 项必做: 律师 / 邮箱 / 仓库 / 域名) |
| `docs/VERSION_1.0_PLAN.md` | 5-12 (4.3 Spam 风险) + 65-74 (M1-M7 时间线) + 75-82 (1.0 硬门槛) |

---

**报告完成时间**: 2026-08-02
**总字数**: ~3600 字 (含表格 / 引用)
**下次审计**: 7 项 P0 修完后, 跑 `bundle exec fastlane ios release` 实际提交前再审一轮
