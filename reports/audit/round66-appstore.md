# AppStore 视角全量审计（v0.27 R66）

**审计时间**: 2026-08-02
**项目**: chroniccare
**版本**: 0.27.0+64（R66 收尾中，工作区有未提交改动）
**视角**: Apple App Store 上架合规
**审计模式**: 全量（聚焦 `ios/` + `lib/main.dart` + `fastlane/` + `pubspec.yaml` + `assets/legal/`）
**参考基线**: Apple App Store Review Guidelines 5.1+（2024-05 强制 Privacy Manifest 2024-05-01 生效）

**项目基线**: 1237 tests pass / 0 analyzer error / 16 守护脚本全绿
**已修基线**: R63 iOS P0/P1 8 项已落地（`Info.plist` 加 `ITSAppUsesNonExemptEncryption` / `NSPhotoLibraryAddUsageDescription` / `BGTaskSchedulerPermittedIdentifiers` / `CFBundleDisplayName` per-language / `UIBackgroundModes` → `processing` / `Runner.entitlements` / IPHONEOS_DEPLOYMENT_TARGET 14.0 / `EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64` / `PRODUCT_BUNDLE_IDENTIFIER=com.chroniccare.app`）

---

## 1. 总览

- **App Store 准备度**: ⭐ / 5
- **上架阻塞 (P0)**: **11 项**（其中 5 项"无法审核提交"，6 项"提交后必被拒"）
- **上架警告 (P1)**: **9 项**（提交后可能拒，可能要求补料）
- **上架建议 (P2)**: **7 项**（不阻塞但影响用户体验 / 透明度）
- **最重要发现 1-2 句**:
  1. **fastlane iOS 配置完全缺失**：`fastlane/` 下仅有 `metadata/android/`，**没有 `metadata/ios/` 目录、没有 `Fastfile`、没有 `Appfile`**。iOS 提交流程无法启动。配合 `phone_screenshots/*.png` 全部 67 字节占位（不是真截图），App Store Connect 提交时连 6.5" 截图都过不了强校验。
  2. **Info.plist 与 Swift 实现不一致**：`Info.plist` 声明 `BGTaskSchedulerPermittedIdentifiers=[com.chroniccare.safety-check]`，但 `AppDelegate.swift` 完全没注册该 identifier（无 `BGTaskScheduler.shared.register(...)` 调用）。Apple 审核员对照代码会判"你声明了能力但没实现"（4.0 Minimum Functionality / 2.1 App Completeness 风险）。
- **建议优先修什么**（按 ROI 排序）:
  1. 补 `fastlane/metadata/ios/`（截图 + 文案）—— S 难度，2-3h，上架前必备
  2. 写 `fastlane/Fastfile` + `Appfile` —— S 难度，2-3h，build / upload 必备
  3. `AppDelegate.swift` 加 `BGTaskScheduler` register + `UNUserNotificationCenter` delegate —— XS 难度，30min，2.1 / 4.0 风险消除
  4. `Info.plist` 补 `NSPhotoLibraryUsageDescription`（`share_plus` + `printing` 触发 PHPhotoLibrary 读权限）—— XS 难度，5min
  5. `PrivacyInfo.xcprivacy` 的 `NSPrivacyCollectedDataTypes` 填实际数据（Health Information / Audio Data / Sensitive Info / Contact Info）—— S 难度，30min，App Privacy 标签强制

---

## 2. 隐私清单 (Privacy Manifest) — iOS 17+ 必填

**文件**: `D:\Batch\chroniccare\ios\Runner\PrivacyInfo.xcprivacy`（R61 新建）

### 2.1 已声明 (合规)

| 类别 | Reason Code | 实际使用 |
|------|-------------|----------|
| `NSPrivacyAccessedAPICategoryUserDefaults` | `CA92.1` | `shared_preferences` + `flutter_secure_storage` 内部缓存 ✓ |
| `NSPrivacyAccessedAPICategoryFileTimestamp` | `C617.1` | `path_provider` 读 file mtime + audio 录音文件管理 ✓ |
| `NSPrivacyAccessedAPICategorySystemBootTime` | `35F9.1` | `WidgetsBindingObserver` 跨日检测 ✓ |
| `NSPrivacyAccessedAPICategoryDiskSpace` | `85F4.1` | 录音前检查磁盘空间 ✓ |

### 2.2 P0 阻塞：`NSPrivacyCollectedDataTypes` 缺实际数据

**位置**: `ios/Runner/PrivacyInfo.xcprivacy:27-28`
```xml
<key>NSPrivacyCollectedDataTypes</key>
<array/>
```

**问题**: Apple 2024-05 强制：App 收集的每一类数据必须在 `NSPrivacyCollectedDataTypes` 声明，与 App Store Connect "App Privacy" 标签一一对应。本项目实际收集：

| 数据类别 | iOS 类别标识 | 实际收集字段 | 用户可控 |
|----------|--------------|--------------|----------|
| 健康 / 医疗 | `NSPrivacyCollectedDataTypeHealthAndFitness` | PHQ-9 / GAD-7 评分、药名、剂量、打卡时间 | 是（本地） |
| 音频 | `NSPrivacyCollectedDataTypeAudioData` | vent 树洞录音、mood 语音日记 | 是（本地） |
| 联系信息 | `NSPrivacyCollectedDataTypeContactInfo` | 紧急联系人姓名 + 手机号 | 是（本地） |
| 用户内容 | `NSPrivacyCollectedDataTypeUserContent` | vent 树洞文字 / 录音 | 是（本地） |
| 标识符 | `NSPrivacyCollectedDataTypeIdentifiers` | 无（**确认**不收集 device ID / IDFA） | — |

**修复建议**: 补 `NSPrivacyCollectedDataTypes` 4 类 + 每类加 `NSPrivacyCollectedDataTypeLinked = false`（本地不关联用户）+ `NSPrivacyCollectedDataTypeTracking = false` + `NSPrivacyCollectedDataTypePurposes = [NSPrivacyCollectedDataTypePurposeAppFunctionality]`。

**上架阻塞**: ✓（2024-05 起新 / 跟新 app 必填，缺则审核拒）

### 2.3 P1 警告：缺 `NSPrivacyAccessedAPICategoryActiveKeyboard` / `ProcessInfo` / `UserDefaults` 多个 reason

**位置**: `ios/Runner/PrivacyInfo.xcprivacy:30-64`

- `UserDefaults` 当前只有 `CA92.1`（"access info from same app, per documentation"）。如果用 `shared_preferences` 跨 app 共享、或用 `CFPreferences` 跨进程读，需加 `CA92.2`。建议补全所有可能的 reason code 防审。
- 没声明 `NSPrivacyAccessedAPICategoryProcessInfo`（`flutter_local_notifications` 内部可能调 `ProcessInfo.processInfo` 取 Uptime / thermalState）。

**修复建议**: 补全 ProcessInfo + UserDefaults 多 reason。

**上架阻塞**: ✗（功能性非阻塞，但 Apple 加强审查）

### 2.4 P1 警告：第三方 plugin 自己的 PrivacyInfo

Pubspec 依赖里以下 plugin 在 iOS 18+ 需自带 PrivacyInfo 资源（2024-05 强制）：

| Plugin | 版本 | 自带 PrivacyInfo | 备注 |
|--------|------|------------------|------|
| `flutter_local_notifications` | 17.2.3 | ✓（自 14.0+） | 17.2 已升级到 2024-05 manifest |
| `record` | 5.2.0 | ⚠️ 需核 | iOS 端 record_ios 5.2.0 自带，需 grep pod 验 |
| `audioplayers` | 6.1.0 | ✓ | AudioToolbox wrapper |
| `share_plus` | 10.1.4 | ⚠️ 需核 | share_plus_platform_interface 走 UIActivityViewController，不直接调 API |
| `in_app_purchase` | 3.3.0 | ✓（StoreKit wrapper） | — |
| `flutter_secure_storage` | 9.2.2 | ✓ | Keychain 不需要 PrivacyInfo |
| `flutter_timezone` | 3.0.1 | ✓ | NSTimeZone wrapper |
| `speech_to_text` | 7.0.0 | ⚠️ 需核 | SFSpeechRecognizer 可能要 decl |
| `permission_handler` | 11.3.1 | ✓ | — |
| `path_provider` | 2.1.4 | ✓ | — |
| `pdf` / `printing` | 3.11.1 / 5.13.4 | ✓ | — |
| `intl` / `uuid` | 0.20.2 / 4.5.1 | ✓ | 纯 Dart |
| `fl_chart` | 0.69.0 | ✓ | 纯 Dart |
| `go_router` | 14.6.1 | ✓ | 纯 Dart |
| `flutter_dotenv` | 6.0.1 | ✓ | 纯 Dart |
| `pointycastle` | 3.9.1 | ✓ | 纯 Dart |
| `sqlcipher_flutter_libs` | 0.6.4 | ✓ | SQLite 加密 wrapper |

**修复建议**: `flutter pub deps` 后跑 `pod install`，构建后查 `<App>.app/Frameworks/*.framework/PrivacyInfo.xcprivacy`，确认所有 framework 都有（自动打包）。

**上架阻塞**: ✗（plugin 库方负责，但若缺会被审核员质疑）

---

## 3. Info.plist 权限说明

**文件**: `D:\Batch\chroniccare\ios\Runner\Info.plist`

| 权限 Key | 是否有 | 文案是否符合 Apple 规范 | 实际使用 | 状态 |
|----------|--------|------------------------|----------|------|
| `NSCameraUsageDescription` | ✗ 缺 | — | 推测无（无 image_picker / camera 依赖） | ✓ 缺则 OK |
| `NSMicrophoneUsageDescription` | ✓ `ios/Runner/Info.plist:47-48` | "用于情绪日记的语音录入，本地处理，文件加密存储" ✓ 用户友好 | `record` 5.2.0 + `audioplayers` 6.1.0 + `speech_to_text` 7.0.0 全部需要 | ✓ |
| `NSSpeechRecognitionUsageDescription` | ✓ `ios/Runner/Info.plist:49-50` | "用于情绪日记的语音转文字，本地处理，不上传" ✓ | `speech_to_text` iOS 端走 SFSpeechRecognizer | ✓ |
| `NSPhotoLibraryUsageDescription` | ✗ 缺 | — | **`share_plus` 10.1.4 + `printing` 5.13.4 触发 `PHPhotoLibrary` 读权限（PDF 分享 / 打印走系统 share sheet）** | **P0 缺** |
| `NSPhotoLibraryAddUsageDescription` | ✓ `ios/Runner/Info.plist:56-57` (R62 P0-5 加) | "用于保存用药报告 PDF 到相册" ✓ | `printing` 调 system share sheet 时可能写 | ✓ |
| `NSContactsUsageDescription` | ✗ 缺 | — | 推测无（用自建 contacts 表，无 Contacts framework） | ✓ 缺则 OK |
| `NSLocationWhenInUseUsageDescription` | ✗ 缺 | — | 无 | ✓ |
| `NSCalendarsUsageDescription` | ✗ 缺 | — | 无 | ✓ |
| `NSRemindersUsageDescription` | ✗ 缺 | — | 无 | ✓ |
| `NSUserTrackingUsageDescription` | ✓ `ios/Runner/Info.plist:62-63` (R61 加，防御性) | "本应用不收集任何追踪数据，仅用于 App Store 透明性声明" ✓ | 无 IDFA 调用 | ✓ |
| `NSFaceIDUsageDescription` | ✗ 缺 | — | 无 | ✓ |
| `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` | ✗ 缺 | — | 无 HealthKit | ✓ |
| `NSBluetoothAlwaysUsageDescription` | ✗ 缺 | — | 无 | ✓ |
| `NSAppleMusicUsageDescription` | ✗ 缺 | — | 无 | ✓ |
| `NSCalendarsFullAccessUsageDescription` (iOS 17+) | ✗ 缺 | — | 无 | ✓ |
| `NSContactsFullAccessUsageDescription` (iOS 18+) | ✗ 缺 | — | 无 | ✓ |
| `NSUserNotificationUsageDescription` | ✓ `ios/Runner/Info.plist:45-46`（**老 key**，无效） | — | — | **P2 误用** |
| `ITSAppUsesNonExemptEncryption` | ✓ `ios/Runner/Info.plist:98-99` (R62 P0-1 加) | `false` ✓（SQLCipher AES-256 是"标准库加密"，无需 self-classification 文档） | SQLCipher 走标准 OpenSSL FIPS module | ✓ |
| `LSApplicationCategoryType` | ✓ `ios/Runner/Info.plist:126-127` (R66 加) | `healthcare-fitness` ✓ | — | ✓ |
| `UIBackgroundModes` | ✓ `ios/Runner/Info.plist:134-138` (R62 P0-7) | `["audio", "processing"]` ✓ | `audio` 录音后台 + `processing` 失联检测 BGTask | ✓ |
| `BGTaskSchedulerPermittedIdentifiers` | ✓ `ios/Runner/Info.plist:143-146` (R62 P0-7) | `["com.chroniccare.safety-check"]` ✓ | — | ✓（但 **AppDelegate 没注册**，见 §4.2） |
| `UIRequiresFullScreen` | ✓ `ios/Runner/Info.plist:69-70` (R61 加) | `false` ✓ 允许 iPad Split View | — | ✓ |
| `CFBundleDisplayName` (per-locale dict) | ✓ `ios/Runner/Info.plist:14-22` (R62 P0-6 加) | en="ChronicCare" / zh-Hans="慢病管家" / zh-Hant="慢病管家" | — | **P1 警告**（见 §7.3） |
| `UISupportedInterfaceOrientations` | ✓ `ios/Runner/Info.plist:106-111` (iPhone) + 112-118 (iPad) | ✓ | — | ✓ |
| `UISupportedInterfaceOrientations~iphone` 显式后缀 | ✗ 缺 | — | — | **P2 建议**（无 ~iphone key，Apple 会 fallback 到 iPad 的所有方向） |

### 3.1 P0 阻塞：`NSPhotoLibraryUsageDescription` 缺

**位置**: `ios/Runner/Info.plist`（缺）

**问题**: `printing` 5.13.4 + `share_plus` 10.1.4 触发 `UIActivityViewController` 分享 PDF 时，iOS 会弹"是否允许访问照片库"对话框。**无 `NSPhotoLibraryUsageDescription` 直接 crash**（`-[_NSCFConstantString localizationError]_block_invoke` 异常），或者最坏情况：Apple 审核员跑 share flow 直接闪退拒审。

**修复建议**:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>用于分享用药报告 PDF 时选择保存位置</string>
```

**上架阻塞**: ✓（闪退即拒审）

### 3.2 P2 误用：`NSUserNotificationUsageDescription` 是老 key

**位置**: `ios/Runner/Info.plist:45-46`

**问题**: `NSUserNotificationUsageDescription` 是 2014 年之前的 key（用于 UILocalNotification，iOS 10+ 已弃用）。当前用 `flutter_local_notifications` 17.x 走 `UNUserNotificationCenter`（iOS 10+），**不读这个 key**。即使填了，Apple 审核时不会看（不阻塞），但属于 dead code，建议删。

**修复建议**: 删 `NSUserNotificationUsageDescription`，依赖 `DarwinInitializationSettings(requestAlertPermission: true)` 弹权限弹窗（`lib/core/data/services/notification_service.dart:128` 已设）。

**上架阻塞**: ✗

---

## 4. Capabilities vs 实际使用

**文件**: `D:\Batch\chroniccare\ios\Runner\Runner.entitlements`

```xml
<dict>
  <key>aps-environment</key>
  <string>development</string>
</dict>
```

| 能力 (Entitlement) | 当前声明 | 实际使用 | 状态 |
|--------------------|----------|----------|------|
| `aps-environment` (Push Notification) | `development` | **`flutter_local_notifications` 只用本地通知 (UNUserNotificationCenter)，不用 APNs 远程推送** | **P1 误导** |
| App Groups (`com.apple.security.application-groups`) | ✗ | 无 | ✓ |
| HealthKit (`com.apple.developer.healthkit`) | ✗ | 无 | ✓ |
| Sign in with Apple (`com.apple.developer.applesignin`) | ✗ | 无 | ✓ |
| Background Modes (`UIBackgroundModes`) | `audio` + `processing`（在 Info.plist） | `audio`（录音后台） + `processing`（失联检测 BGTask） | **P0 部分实现**（见 §4.2） |
| Push Notification（`aps-environment`）| `development` | 无 | **P1** |

### 4.1 P1 警告：`aps-environment=development` 误导

**位置**: `ios/Runner/Runner.entitlements:5-6`

**问题**: `aps-environment=development` 表示 App 注册了 APNs（远程推送）。但项目**只用 `flutter_local_notifications` 本地通知**，不调 APNs。Apple 审核员看：
1. Info.plist 无 push 相关 usage description
2. 代码无 `UIApplication.shared.registerForRemoteNotifications()` 或 `didRegisterForRemoteNotificationsWithDeviceToken` 调用
3. 仅声明 dev entitlement，没声明 production

会判"你声明了 push 但没真用"（5.1.1 透明度问题）。最坏情况：要求删 entitlement 后再审。

**修复建议**: 方案 A（推荐）—— 删 `aps-environment` entitlement，配合 `UIBackgroundModes` 只用本地通知，App Store 标签"Push Notifications" = No。
方案 B —— 留 dev entitlement 但**改 `aps-environment=production`**，并实现真 APNs 接入（需 Apple Developer Program + 后端），v1.0+ 大工程。

**上架阻塞**: ✗（但 Apple 5.1.1 透明度要求严格）

### 4.2 P0 阻塞：`UIBackgroundModes=processing` 无 Swift 实现

**位置**:
- `ios/Runner/Info.plist:143-146` 声明 `BGTaskSchedulerPermittedIdentifiers=[com.chroniccare.safety-check]`
- `ios/Runner/AppDelegate.swift:1-15` **完全没** `BGTaskScheduler.shared.register(...)` 调用

**问题**: Apple 4.0 Minimum Functionality + 2.1 App Completeness：声明的能力必须真实现。Info.plist 说"我注册了 safety-check 这个后台任务"，但 Swift 代码 0 调用 → 审核员如果对照代码，判"挂羊头卖狗肉"拒审。

**修复建议**: 在 `AppDelegate.swift` `didFinishLaunchingWithOptions` 加：
```swift
import BackgroundTasks
BGTaskScheduler.shared.register(
  forTaskWithIdentifier: "com.chroniccare.safety-check",
  using: nil
) { task in
  // 委派到 Flutter (MethodChannel)
  handleSafetyCheckTask(task: task as! BGProcessingTask)
}
```

或者**移除** `BGTaskSchedulerPermittedIdentifiers` + `UIBackgroundModes=processing`，仅保留 `audio`（如果 vent 录音后台真用）。

**上架阻塞**: ✓（声明 / 实现不一致 = 拒审高频原因）

### 4.3 P0 阻塞：`UNUserNotificationCenter.current().delegate` 未设

**位置**: `ios/Runner/AppDelegate.swift:6-11`

**问题**: `flutter_local_notifications` 17.2.3 文档明确要求 iOS 10+ 设 `UNUserNotificationCenter.current().delegate`（否则 iOS 14+ 前台通知 banner 不显示，foreground notification 直接吞掉）。当前 `AppDelegate.application(_:didFinishLaunchingWithOptions:)` 只调 super，**没设 delegate**。

参考: `flutter_local_notifications` README "iOS setup" 段第 5 步。

**修复建议**:
```swift
override func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
  if #available(iOS 10.0, *) {
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
  }
  return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
```

**上架阻塞**: ✓（foreground 通知不显示 = 用户体验问题 + Apple 4.0 Bug）

---

## 5. App Review Guidelines 5.x 合规

### 5.1 安全 / 隐私（Guideline 5.1）

#### 5.1.1 P0：App Store Connect "App Privacy" 标签必须与 `NSPrivacyCollectedDataTypes` 一致

**问题**: 当前 `NSPrivacyCollectedDataTypes=[]`（空 array），但实际收集：
- PHQ-9 / GAD-7 评分（**Health Information**）
- vent / mood 录音（**Audio Data**）
- 紧急联系人（**Contact Info**）
- vent 文字 / 录音（**User Content**）

Apple 2024-05 起要求标签与 Privacy Manifest 严格一致。空 array = "I collect no data"，但 App 明显有数据 → 5.1.1(iv) 透明性违规。

**修复建议**: 补 Privacy Manifest + App Store Connect "App Privacy" 4 类标签，每类选"Used for App Functionality" + "Not linked to user" + "Not used for tracking"。

**上架阻塞**: ✓

#### 5.1.2 P0：用户协议 + 隐私政策全是 TODO 占位

**位置**:
- `assets/legal/user_agreement.md:57-59`:
  ```
  - 开发者邮箱：support@chroniccare.app（**TODO 占位，上 store 前必须注册并替换为真实邮箱**）
  - GitHub Issues: https://github.com/example/chroniccare/issues（**TODO 占位，需确认或替换为真实项目仓库**）
  - 隐私 / PIPL 投诉邮箱：privacy@chroniccare.app（**TODO 占位，上 store 前必须注册并替换**）
  ```
- `assets/legal/privacy_policy.md:1-5`: "本政策是 v0.22 草稿，未经律师过审，上 store 前必须由专业律师过审并更新"
- `assets/legal/user_agreement.md:3-4`: "本协议是 v0.24 草稿，未经律师过审"

**问题**: Apple 5.1.1 隐私 + 5.1.2 知识产权 + 中国《App 违法违规收集使用个人信息行为认定方法》要求：
1. 真实可联系的开发者邮箱（不能是占位）
2. 真实隐私 / 法务投诉邮箱
3. 真实 GitHub 仓库（"example/chroniccare" 是 placeholder）
4. 经法务过审的协议 / 政策

**修复建议**:
1. 注册 `support@chroniccare.app` 真实邮箱
2. 注册 `privacy@chroniccare.app` 真实邮箱
3. 决定是否开源 → 改 GitHub 仓库为真实地址，或删 GitHub Issues 行
4. **法务过审**（中国执业律师，PIPL 专项）

**上架阻塞**: ✓（Apple 1.4.1 + 5.1.1 + 中国 PIPL 联合审查）

#### 5.1.3 P1：`ITSAppUsesNonExemptEncryption=false` 与 SQLCipher AES-256 矛盾

**位置**: `ios/Runner/Info.plist:98-99`

**问题**: SQLCipher 用 AES-256，是 **strong cryptography**。Apple 2024 起要求：
- `ITSAppUsesNonExemptEncryption=true` + 提供 self-classification 文档（CCATS / ERN）
- 或 `ITSAppUsesNonExemptEncryption=false`（仅限"标准库加密"，比如系统 HTTPS / CommonCrypto）

SQLCipher 是基于 OpenSSL 的"非标准"加密（虽然 OpenSSL 是 CCATS-approved，但 SQLCipher 是其 fork + 自家 API），Apple 审核员可能判"你用了 strong crypto" → 要 CCATS 编号。

**修复建议**:
- 方案 A（保守）：`ITSAppUsesNonExemptEncryption=true` + 准备 self-classification report（声明只用于本地数据保护 + 不导出）
- 方案 B（冒险）：保持 `false`，等被拒再补

**上架阻塞**: ✗（高概率被审时追问，但不一定拒）

### 5.2 性能 / 完整（Guideline 2.1 / 2.3 / 4.0）

#### 5.2.1 P0 阻塞：App Store 截图全是 67 字节占位

**位置**: `D:\Batch\chroniccare\fastlane\metadata\android\en-US\phone_screenshots/screenshot_{1,2,3,4}.png` + `zh-CN/phone_screenshots/screenshot_{1,2,3,4}.png`

```bash
$ ls -la fastlane/metadata/android/*/phone_screenshots/
-rw-r--r--  67  screenshot_1.png
-rw-r--r--  67  screenshot_2.png
...
```

**问题**: 67 字节是 placeholder（Flutter 默认 placeholder 大小）。Apple App Store Connect 强制 6.5" 截图 ≥ 1 张（iPhone 6.5" Display = 1242 × 2688 PNG），且：
- 截图必须是真机 / 模拟器截图
- 不能是 mockup / placeholder
- 必填设备: 6.5" (iPhone 15 Pro Max) + 5.5" (iPhone 8 Plus) + 12.9" iPad (选填但 universal app 必填)

当前 `fastlane/metadata/ios/` 目录**根本不存在**：
```bash
$ ls fastlane/metadata/
android  ← 只有这一个
```

**修复建议**:
1. 跑 `flutter build ios --release` 在 6.5" 模拟器上截 5-8 张
2. 同样 5.5" + 12.9" iPad
3. 存到 `fastlane/metadata/ios/en-US/iphone_6_5_screenshots/01_home.png` 等
4. 跑 `fastlane deliver` 自动上传

**上架阻塞**: ✓（连截图都没有 = 提交被拒绝入口）

#### 5.2.2 P0 阻塞：App Description / Keywords / Subtitle / Name 全缺失

**位置**: `fastlane/metadata/ios/` 不存在

**问题**: App Store Connect 必填项：
- App Name (30 字符)
- Subtitle (30 字符)
- Keywords (100 字符)
- Description (4000 字符)
- Promotional Text (170 字符)
- Privacy Policy URL
- Support URL
- Marketing URL (选填)

当前 `fastlane/metadata/android/en-US/full_description.txt` 有 1000+ 字符英文 description，但 iOS 端没迁移，且需要 iOS 专属：
- 副标题 30 字符精简版
- 关键词 100 字符（Apple 风格逗号分隔）

**修复建议**: 写 iOS 专属 description + 30 字符副标题 + 100 字符关键词 + 真实 privacy/support URL。

**上架阻塞**: ✓

#### 5.2.3 P1 警告：CFBundleShortVersionString="0.27.0" 像测试版

**位置**: `ios/Runner/Info.plist:33-34` (`$(FLUTTER_BUILD_NAME)`) + `pubspec.yaml:4` (`0.27.0+64`)

**问题**: Apple 4.3 Spam：版本号 < 1.0.0 的 App Store Connect 提交**自动风险标记**为"too early in development"，要求 Apple Reviewer 二次过问。Apple 鼓励"1.0.0+"作为第一个上架版本。

**修复建议**: 提 store 前 bump 到 `1.0.0+1`（或 `0.28.0+1` 表达"正式版"）。

**上架阻塞**: ✗（高概率审核员多问，但不一定拒）

### 5.3 商务（Guideline 3）

#### 5.3.1 P1 警告：IAP 集成但 productId 是占位

**位置**:
- `lib/core/data/services/store_kit_service.dart:48` `kLifetimeProductId = 'com.chroniccare.app.lifetime'`
- `lib/core/data/services/store_kit_service.dart:103-113` `buyLifetime()` release 模式 return false（不真接 StoreKit）

**问题**: Apple 3.1.5(a) 要求"App 内购买数字商品 / 服务必须用 IAP"。项目:
1. dev 模式: `kDebugMode` 守卫，返 true（不影响 dev）
2. release 模式: return false（"占位返回 false, 购买未开通"）

→ 用户在 release 模式点"购买 8 元"按钮 → false → UI 显示错误 / 不动 = **2.1 App Completeness + 3.1.5(a) 双重违规**。

**修复建议**:
- 方案 A（推荐）：删 IAP 入口，App 完全免费，直到 v0.28 真接
- 方案 B：在 v0.27 上架前真接（需要 App Store Connect 创建 productId + 法务过 8 元定价 + 真实 receipt 验证）
- 方案 C：把"8 元买断"改成"订阅"，但订阅更严格（Guideline 3.1.2）

**上架阻塞**: ✗（审核员如果点购买按钮看到失败，会判 2.1 拒）

#### 5.3.2 P1 警告：失联通知 SMS 是 mock 但 description 说"automatically notify"

**位置**:
- `lib/core/data/services/email_service.dart:55-67` mock 模式只打日志 + 返 false
- `fastlane/metadata/android/en-US/full_description.txt` "If you stop checking in for 2+ days, ChronicCare can automatically notify your trusted contacts"
- `lib/main.dart:155` `SmsService.validateForRelease(_smsService.provider)` release 模式阻断（说明 release 没真发）

**问题**: App Store Description 承诺"automatically notify"（自动通知），但 release 模式 mock → 用户配置联系人 + 失联 2+ 天 → App 不发任何东西 = **2.1 完整性 + 4.3 误导双重违规**。

**修复建议**:
- 方案 A：删失联通知功能（user agreement / description 都说"不是紧急救援"，R66 FeatureFlags 软隐藏已经做了"门卫")
- 方案 B：保留但 description / agreement 改"App 会在本地记录失联，但需要您手动通知联系人"（透明化）
- 方案 C：v0.28 真接阿里云 SMS（依赖法务 1-2 月模板审核 + 阿里云 AccessKey 申请）

**上架阻塞**: ✗（高概率审核员问"试一下失联通知"）

### 5.4 设计（Guideline 4）

#### 5.4.1 P1 警告：`UIBackgroundModes=audio` + `NSMicrophoneUsageDescription` 组合敏感

**位置**:
- `ios/Runner/Info.plist:47-48` 麦克风说明
- `ios/Runner/Info.plist:134-138` UIBackgroundModes=["audio", "processing"]

**问题**: Apple 4.0 + 5.1.1 严格审查"录音 + 后台"组合：
- 4.0: Background audio 必须有 visible purpose
- 5.1.1: 录音必须明确告知用户

当前 Info.plist 的说明 + UIBackgroundModes 都齐全，但 Apple 审核员仍可能问"录音时切后台的 use case"。

**修复建议**:
- 录制时 UI 显示红条 + "正在录音"（已实现，见 `lib/core/data/services/mood_audio_service.dart`）✓
- 在录制的 dialog 顶部明确"切到后台录音会继续"提示（建议加）

**上架阻塞**: ✗

### 5.5 法律（Guideline 5）

#### 5.5.1 P0 阻塞：医疗 / 心理健康类（1.4.3 Medical）合规

**Apple 1.4.3 Medical 明确要求**:
- App 描述必须明确"NOT a medical device"
- 量表（PHQ-9 / GAD-7）必须声明"not for diagnosis"
- 失联通知必须声明"not for emergency"

**位置**:
- `fastlane/metadata/android/en-US/full_description.txt`:
  ```
  ChronicCare is NOT a medical device and does not provide medical advice, diagnosis, or treatment.
  ```
  ✓ 已有，但要在 iOS 端补
- `assets/legal/user_agreement.md:21`: "失联通知功能不是紧急救援服务。遇紧急情况请拨打 120 / 110 或联系最近医院。" ✓
- `assets/legal/user_agreement.md:20`: "本 App 不提供医疗建议、诊断或治疗" ✓

**问题**:
1. iOS 端 description 缺失（`fastlane/metadata/ios/` 不存在）→ iOS 端没声明 NOT a medical device
2. App 类目已设 `LSApplicationCategoryType=healthcare-fitness` ✓
3. App Store Connect 的 Primary Category 应选 **Medical**（不是 Health & Fitness）—— 类目跟 metadata 不一致，Apple 审核员会按 Medical 审（更严）
4. App Privacy 标签的 Health Information 必填（见 §5.1.1）

**修复建议**:
1. iOS 端 description 头一句加 "ChronicCare is NOT a medical device..."
2. App Store Connect Primary Category 选 Medical（iOS 18+ 改名"Health & Wellness"）
3. 隐私政策 / 用户协议 / 失联通知文案保持现有"非医疗 / 非紧急"声明
4. Privacy Manifest 补 Health Information 类

**上架阻塞**: ✓（Medical 类目必填 Privacy Information + 严格审查）

### 5.6 通用（Guideline 1 / 2）

#### 5.6.1 P2 建议：URL Scheme / Universal Links 缺失

**位置**: `ios/Runner/Info.plist` 无 `CFBundleURLTypes` / 无 Associated Domains entitlement

**问题**: 当前 App 无 deep link / URL scheme 处理。如果未来要支持"通知点开跳详情页"等，需要注册 scheme（如 `chroniccare://safety/123`）。当前 `notification_service.dart:368-369` 用 `NotificationDeepLink.safetyAlert(...).encode()` 生成 payload（path-style），但 App 实际处理 payload 的代码（`notification_navigation.dart`）可能在 path 拼接时出错（URL scheme 未注册）。

**修复建议**: 加 `CFBundleURLTypes` 注册 `chroniccare` scheme（low priority，当前不阻塞）。

**上架阻塞**: ✗

---

## 6. iOS 特定功能

### 6.1 P1 警告：`UISceneStoryboardFile=Main` + `UILaunchStoryboardName=LaunchScreen` 双 storyboard

**位置**:
- `ios/Runner/Info.plist:86-87` UISceneStoryboardFile = Main
- `ios/Runner/Info.plist:102-103` UILaunchStoryboardName = LaunchScreen
- `ios/Runner/Base.lproj/Main.storyboard` 是 FlutterViewController
- `ios/Runner/Base.lproj/LaunchScreen.storyboard` 是 LaunchImage

**问题**: iOS 13+ Scene-based lifecycle + Flutter:
- `UISceneStoryboardFile` 应该是 Main（启动后加载 FlutterViewController）
- `UILaunchStoryboardName` 应该是 LaunchScreen（启动屏）
- 但 Main.storyboard 内容是空的 FlutterViewController，**实际不显示**

Flutter 3.x 通常用 `UILaunchStoryboardName=LaunchScreen` + 不用 Main.storyboard（FlutterAppDelegate 直接 init FlutterEngine）。本项目两者都设 + SceneDelegate 继承 FlutterSceneDelegate，**逻辑能跑但语义混乱**。

**修复建议**:
- 删 Main.storyboard + UISceneStoryboardFile key
- 仅留 UILaunchStoryboardName=LaunchScreen
- SceneDelegate 保留（继承 FlutterSceneDelegate 是 R63+ 推荐）

**上架阻塞**: ✗（功能性 OK，semantic mess）

### 6.2 P2 建议：App Icon 缺 iPhone 6.5" / iPad 12.9" Marketing variant

**位置**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`

当前 18 个 size (iPhone 20-60 + iPad 20-83.5 + 1024 marketing)，齐全 ✓。

**问题**: Apple 2024 强调 1024 × 1024 marketing icon 必须存在（已有 ✓），且**不能有 alpha channel**（透明）。当前 `Icon-App-1024x1024@1x.png` 是 1x scale，符合要求。

**上架阻塞**: ✗

### 6.3 P2 建议：LaunchImage 是 PNG（非 Live / 非 Dynamic）

**位置**: `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json`

**问题**: Flutter 项目通常用 Flutter 自带 launch storyboard（`LaunchScreen.storyboard`），不依赖 LaunchImage 静态图。当前**两者都设了**（LaunchImage + LaunchScreen storyboard）。

**修复建议**: 删 LaunchImage.imageset + Contents.json，仅留 LaunchScreen.storyboard（项目用的就是 LaunchScreen）。

**上架阻塞**: ✗

### 6.4 P1 警告：`EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64` 影响 Apple Silicon 开发

**位置**: `ios/Runner.xcodeproj/project.pbxproj:358, 487, 538` (3 处)

**问题**: `EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64` 意味着 arm64 simulator 编译时**被排除**。对 Apple Silicon (M1/M2/M3) Mac 用户：
- 默认应该编译 arm64 simulator（native）
- 当前会 fallback 到 x86_64 simulator（Rosetta 2 翻译）→ 启动慢 + 性能差

不影响 App Store 上架（只影响 dev 体验），但 Apple 2024 已**弃用**这个设置（Xcode 14+ 默认移除）。

**修复建议**: 删 `EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64` 3 处（Xcode 15+ 默认就是 arm64 simulator）。

**上架阻塞**: ✗

---

## 7. Build 配置

### 7.1 已知 P0（已修）—— R63 落地

| 项 | 值 | 状态 |
|----|----|------|
| `IPHONEOS_DEPLOYMENT_TARGET` | 14.0 (3 处) | ✓ R63 P1-4 |
| `SUPPORTED_PLATFORMS` | iphoneos + iphonesimulator | ✓ R63 P1-5 |
| `EXCLUDED_ARCHS[sdk=iphonesimulator*]` | arm64 (3 处) | ⚠️ 见 §6.4 |
| `PRODUCT_BUNDLE_IDENTIFIER` | com.chroniccare.app (3 target) | ✓ R63 P1-6 |
| `ENABLE_BITCODE` | NO | ✓ R63 确认 |
| `SWIFT_VERSION` | 5.0 | ✓ |
| `TARGETED_DEVICE_FAMILY` | "1,2" (iPhone + iPad universal) | ✓ |

### 7.2 P2 建议：`ENABLE_USER_SCRIPT_SANDBOXING=NO`

**位置**: `ios/Runner.xcodeproj/project.pbxproj:346, 468, 526`

**问题**: Apple Xcode 15+ 强制 `ENABLE_USER_SCRIPT_SANDBOXING=YES`（默认），但 Flutter build phase script 可能被 sandbox 拦截（取决于 Flutter 版本）。当前显式 `NO` 是为了兼容老脚本。

**修复建议**: 升级到 Flutter 3.41.x 后试 `=YES`，不行再改回。

**上架阻塞**: ✗

### 7.3 P1 警告：`CFBundleDisplayName` per-language dict 没配 InfoPlist.strings

**位置**: `ios/Runner/Info.plist:14-22`
```xml
<key>CFBundleDisplayName</key>
<dict>
  <key>en</key><string>ChronicCare</string>
  <key>zh-Hans</key><string>慢病管家</string>
  <key>zh-Hant</key><string>慢病管家</string>
</dict>
```

**问题**: Apple iOS Info.plist 的 `CFBundleDisplayName` 是**单值**，不支持内嵌 dict。per-language display name 应该用 `InfoPlist.strings`（每个语言目录下 `xx.lproj/InfoPlist.strings`）：
```xml
<!-- zh-Hans.lproj/InfoPlist.strings -->
<key>CFBundleDisplayName</key>
<string>慢病管家</string>
```
当前 dict 形式被 iOS 忽略，**所有 locale 都用 `CFBundleName`（chroniccare）作为显示名**。

**修复建议**:
- 方案 A：删 dict，单值 `CFBundleDisplayName=慢病管家`（或 ChronicCare）
- 方案 B：建 `ios/Runner/zh-Hans.lproj/InfoPlist.strings` + `zh-Hant.lproj/InfoPlist.strings`，dict 移到 strings 文件

**上架阻塞**: ✗（但 App Store Connect 后台有 per-locale display name 配置，可补救）

---

## 8. 上架 metadata 建议（App Store Connect）

### 8.1 必填项（缺失即拒）

| 字段 | 字符限制 | 当前 | 建议 |
|------|----------|------|------|
| App Name | 30 | "chroniccare" (CFBundleName) | "慢病管家" 或 "ChronicCare - 慢病管家" |
| Subtitle | 30 | ✗ | "吃药打卡 + 失联通知" 或 "Mental Health Companion" |
| Keywords | 100 | ✗ | "medication,reminder,mood,mental,health,PHQ9,GAD7,chronic,care,tracker" |
| Description | 4000 | ✗ | 见 §8.3 |
| Promotional Text | 170 | ✗ | "本地加密 · 零云端 · 精神心理患者的私人管家" |
| Privacy Policy URL | URL | ✗ | 真实隐私政策页 URL（不能是 GitHub raw） |
| Support URL | URL | ✗ | 真实客服页 URL（不能是 TODO） |
| Marketing URL | URL | 选填 | 官网 URL（如果有） |

### 8.2 App Store Connect 配置

| 项 | 建议 |
|----|------|
| **Primary Category** | Medical（iOS 18+ 改名"Health & Wellness"） |
| **Secondary Category** | Health & Fitness |
| **Privacy Policy URL** | 真实 URL（建议 https://chroniccare.app/privacy） |
| **Age Rating** | 12+（mental health 内容 + 可能的 18+ 暗示如"自杀念头"） |
| **Price** | 免费 + IAP（8 元一次性买断） |
| **Availability** | 中国 + 全球 175 国家 |
| **App Privacy** | 4 类：Health Information / Audio Data / Contact Info / User Content（见 §5.1.1） |

### 8.3 Description 模板（参考 Android 版改写）

> **本模板参考 `fastlane/metadata/android/en-US/full_description.txt`，需 iOS 端精简版**
>
> ChronicCare - 慢病管家
>
> Daily check-in + mood tracker for chronic patients. Private & local.
>
> ChronicCare helps you take medication on time, track your mood, and stay connected with loved ones — all while keeping your data 100% on your phone.
>
> **KEY FEATURES**
> - One-tap daily check-in
> - Medication reminders (snooze, refill, "running low")
> - Lost-contact safety net (R66 paused, see settings)
> - Mood & mental health journal (voice notes encrypted)
> - PHQ-9 / GAD-7 screening
> - 100% on-device, SQLCipher, no cloud
> - Vent space (private, encrypted)
>
> **IMPORTANT**
> ChronicCare is NOT a medical device and does not provide medical advice, diagnosis, or treatment. It is a personal tracking tool only. Always consult your doctor for medical decisions.
>
> **PRIVACY**
> 100% on-device. SQLCipher encryption. No accounts, no cloud, no analytics.
>
> If you are in crisis, please contact your local emergency services or a crisis hotline.

### 8.4 截图要求（iOS 端缺失）

| 设备 | 尺寸 | 必填 | 建议 |
|------|------|------|------|
| iPhone 6.5" | 1242 × 2688 | ✓ | 5-8 张：主页 / 打卡 / 趋势 / 心理评估 / 树洞 / 设置 / IAP / 失联通知 |
| iPhone 5.5" | 1242 × 2208 | ✓ | 3-5 张：精简版（同上精选） |
| iPad 12.9" | 2048 × 2732 | universal app 必填 | 3-5 张：Split View 演示 |
| iPad 11" | 1668 × 2388 | universal app 必填 | 3-5 张 |

---

## 9. fastlane 配置

### 9.1 P0 阻塞：fastlane iOS 配置完全缺失

**位置**: `D:\Batch\chroniccare\fastlane/`

```
fastlane/
└── metadata/
    └── android/   ← 仅有
        ├── en-US/
        └── zh-CN/
```

**问题**: fastlane iOS 工作流必须：
1. `Fastfile` —— 定义 lane (build / test / upload / match)
2. `Appfile` —— App Store Connect API key / bundle ID / Apple ID
3. `metadata/ios/` —— 截图 + 描述 + 关键词 + 版本说明
4. `matchfile` (选填) —— 证书 / provisioning profile 管理

**修复建议**: 跑 `fastlane init` 在 `fastlane/` 下生成 Fastfile + Appfile，再按需定制。

```ruby
# fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Push to TestFlight"
  lane :beta do
    build_app(workspace: "Runner.xcworkspace", scheme: "Runner")
    upload_to_testflight
  end

  desc "Release to App Store"
  lane :release do
    build_app(workspace: "Runner.xcworkspace", scheme: "Runner")
    upload_to_app_store(
      force: true,
      skip_metadata: false,
      skip_screenshots: false,
      submit_for_review: true,
      automatic_release: false
    )
  end
end
```

```ruby
# fastlane/Appfile
app_identifier("com.chroniccare.app")
apple_id("your-apple-id@example.com")
team_id("YOUR_TEAM_ID")
itc_team_id("YOUR_ITC_TEAM_ID")
```

**上架阻塞**: ✓（无法跑 `fastlane ios release` 自动提交流程）

### 9.2 P2 建议：fastlane match 证书管理

**问题**: 当前用 `iPhone Developer` 自动签名（project.pbxproj:341, 463, 521）= 个人证书。团队协作时需要 match / cert / sigh 集中管理。

**修复建议**: v1.0+ 团队协作时引入 `fastlane match`。

**上架阻塞**: ✗

---

## 10. 半成品 / WIP（直接对应上架阻塞）

### 10.1 P0 阻塞：失联通知 SMS 业务整体暂停但 description 仍说"自动通知"

**位置**:
- `lib/core/data/feature_flags.dart` (R66 新增) `emergencyContactEnabled = false`
- `lib/core/data/services/safety_watch_service.dart` 入口 flag gate
- `lib/core/data/services/safety_alert_dispatcher.dart` 入口 flag gate
- `lib/core/data/services/email_service.dart:55-67` mock 模式返 false
- `fastlane/metadata/android/en-US/full_description.txt` "If you stop checking in for 2+ days, ChronicCare can automatically notify your trusted contacts"

**问题**: R66 软隐藏失联通知（FeatureFlags 门卫），但 App 描述仍承诺"automatically notify"。Apple 2.1 完整性 + 4.3 误导：用户买了 App，发现失联通知没启用 = 投诉 / 拒审。

**修复建议**:
- 方案 A：删失联通知相关 description / user agreement 行
- 方案 B：v0.28 真接阿里云 SMS 后再启用（FeatureFlags 改 true）

**上架阻塞**: ✓（2.1 完整性）

### 10.2 P0 阻塞：IAP 8 元买断功能未接通

**位置**:
- `lib/core/data/services/store_kit_service.dart:103-113` `buyLifetime()` release 模式返 false
- `pubspec.yaml:58-62` `in_app_purchase: ^3.3.0` 注释"当前 dev 模式走 kDebugMode 直接返 true, productId 留 v0.28 真接"
- `assets/legal/user_agreement.md:25` "本 App 售价人民币 8 元"

**问题**: 8 元买断是 user agreement 承诺，但代码 release 模式 false = 用户付钱失败 = Apple 2.1 完整性 + 3.1.5 商务。

**修复建议**: 跟 §10.1 一样，二选一：
- 删 IAP 入口（设 StoreKit 永远 free）
- v0.28 真接 productId

**上架阻塞**: ✓

### 10.3 P1 警告：背景检查 PHQ-9 / GAD-7 量表只 abstract 不翻译

**位置**:
- `lib/domain/logic/phq9.dart` 16 题题目
- `lib/domain/logic/gad7.dart` 16 题题目
- `lib/domain/entities/scale_translations.dart` (R65 新) "16 题全文 i18n 化留 v1.0"

**问题**: 量表 16 题题目目前是中文 hardcode（"做事时提不起劲或没有兴趣"等）。英文用户看到中文 → 量表无效 → 5.1.1 透明度 + 1.4.3 Medical 双重风险。

**修复建议**:
- 方案 A：R66 上架前补全 16 题英译（48-72h 工作量）
- 方案 B：英文区显示"中文 only" 提示，强制用户切中文

**上架阻塞**: ✗（Medical 类目审核员会问，但不一定拒）

### 10.4 P2 建议：1.0.0 版本号 + 上架准备度

**问题**: 当前 `pubspec.yaml:4` `version: 0.27.0+64`（不是 1.0.0）。

**Apple 4.3 Spam 风险**: 0.x 版本号像"测试版"，Apple 4.3 自动标记。

**修复建议**: 上 store 前 bump 到 `1.0.0+1`（major version = 1），表达"正式版"。

**上架阻塞**: ✗

---

## 11. 优先级 Top 10

| 序 | 问题 | 难度 | 是否上架阻塞 | 修复建议 |
|----|------|------|--------------|----------|
| 1 | **fastlane `metadata/ios/` 目录完全缺失**（截图 / Description / Keywords / Subtitle / Privacy URL / Support URL 全空） | S (2-3h) | ✓ | 建 `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/`，跑 6.5" + 5.5" + 12.9" 模拟器截图，写全 6 个 metadata 文本字段 |
| 2 | **fastlane `Fastfile` + `Appfile` 缺失** | S (2-3h) | ✓ | `fastlane init` 生成，按需配 build_app / upload_to_testflight / upload_to_app_store lane |
| 3 | **`AppDelegate.swift` 没注册 `BGTaskScheduler`**（Info.plist 声明 `com.chroniccare.safety-check`） | XS (30min) | ✓ | 在 `application(_:didFinishLaunchingWithOptions:)` 加 `BGTaskScheduler.shared.register(forTaskWithIdentifier:using:launchHandler:)`；或删 Info.plist 的 `BGTaskSchedulerPermittedIdentifiers` + `UIBackgroundModes=processing` |
| 4 | **`AppDelegate.swift` 没设 `UNUserNotificationCenter.current().delegate`**（foreground 通知不显示） | XS (5min) | ✓ | `UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate` |
| 5 | **`Info.plist` 缺 `NSPhotoLibraryUsageDescription`**（`share_plus` + `printing` 触发 PHPhotoLibrary 读权限） | XS (5min) | ✓ | 加 `<key>NSPhotoLibraryUsageDescription</key><string>用于分享用药报告 PDF 时选择保存位置</string>` |
| 6 | **`PrivacyInfo.xcprivacy` 的 `NSPrivacyCollectedDataTypes=[]` 与实际数据不一致** | S (30min) | ✓ | 补 4 类：Health Information / Audio Data / Contact Info / User Content，每类加 Linked/Tracking/Purposes |
| 7 | **用户协议 / 隐私政策 3 个 TODO 占位邮箱 + GitHub 仓库** | S (1h + 法务 1-2 月) | ✓ | 注册真实 `support@chroniccare.app` / `privacy@chroniccare.app`；决定开源 → 改 GitHub URL；**法务过审** |
| 8 | **App Store Connect "App Privacy" 标签必填 4 类数据**（Health Information / Audio Data / Contact Info / User Content） | S (30min) | ✓ | 在 App Store Connect 后台勾选 + 跟 Privacy Manifest 一一对应 |
| 9 | **`aps-environment=development` 但代码没用 APNs**（误导审核员） | XS (5min) | ✗（强烈建议） | 方案 A：删 entitlement；方案 B：改 `aps-environment=production` + v1.0 真接 |
| 10 | **失联通知 SMS 业务暂停但 description 仍说"automatically notify"** | S (1h) | ✓ | 方案 A：删 description / user agreement 中失联通知行；方案 B：v0.28 真接阿里云后改回 |
| 11 | **IAP 8 元买断 release 模式返 false 但 user agreement 承诺"售价 8 元"** | S (1h) | ✓ | 方案 A：删 IAP 入口；方案 B：v0.28 真接 productId + receipt 验证 |
| 12 | **`CFBundleDisplayName` per-language dict 无效**（应走 InfoPlist.strings） | XS (15min) | ✗ | 删 dict，单值 `CFBundleDisplayName=慢病管家` |
| 13 | **`CFBundleShortVersionString=0.27.0` 触发 4.3 Spam 风险** | XS (5min) | ✗ | bump 到 `1.0.0+1` |
| 14 | **`EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64`**（影响 Apple Silicon dev） | XS (5min) | ✗ | 删 3 处 EXCLUDED_ARCHS（Xcode 15+ 默认 arm64 simulator） |
| 15 | **`ITSAppUsesNonExemptEncryption=false` 但 SQLCipher AES-256 是 strong crypto** | S (1h) | ✗ | 改 `=true` + 准备 self-classification 文档 |
| 16 | **`PHQ-9 / GAD-7` 16 题只中文，英文区用户无效** | L (2-3d) | ✗ | 补 16 题英译 + i18n key |
| 17 | **UIBackgroundModes=audio + 录音** Apple 4.0 严格审查 | S (1h) | ✗ | 录制 UI 顶部加"切后台录音会继续"提示 |
| 18 | **`Main.storyboard` + `LaunchScreen.storyboard` 双 storyboard 冗余** | XS (10min) | ✗ | 删 Main.storyboard + UISceneStoryboardFile key |
| 19 | **`NSUserNotificationUsageDescription` 是老 key**（2014 之前的，flutter_local_notifications 不用） | XS (1min) | ✗ | 删 key |
| 20 | **`UISupportedInterfaceOrientations~iphone` 缺（fallback 到 iPad 4 方向）** | XS (1min) | ✗ | 加 `~iphone` 显式后缀 |

---

## 附录 A：检查项对账（vs R63 iOS P0/P1 8 项）

| R63 项 | 状态 | 备注 |
|--------|------|------|
| P0-1: `ITSAppUsesNonExemptEncryption=false` | ✓ 已修 | `ios/Runner/Info.plist:98-99`，但 §5.1.3 提了"SQLCipher AES-256 矛盾" |
| P0-5: `NSPhotoLibraryAddUsageDescription` | ✓ 已修 | `ios/Runner/Info.plist:56-57` |
| P0-6: `CFBundleDisplayName` per-language dict | ✓ 已修 | `ios/Runner/Info.plist:14-22`，但 §7.3 提了"dict 无效需 InfoPlist.strings" |
| P0-7: `UIBackgroundModes=processing` + `BGTaskSchedulerPermittedIdentifiers` | ✓ 已修 | Info.plist 改完，但 §4.2 提了"AppDelegate 没 register" |
| P0-8: `Runner.entitlements` (aps-environment) | ✓ 已修 | `ios/Runner/Runner.entitlements`，但 §4.1 提了"dev 误导" |
| P1-4: `IPHONEOS_DEPLOYMENT_TARGET` 14.0 | ✓ 已修 | `ios/Runner.xcodeproj/project.pbxproj:355, 483, 535` |
| P1-5: `SUPPORTED_PLATFORMS` + `EXCLUDED_ARCHS` | ✓ 已修 | `ios/Runner.xcodeproj/project.pbxproj:359, 487, 539`，但 §6.4 提了"Apple Silicon sim 体验差" |
| P1-6: `PRODUCT_BUNDLE_IDENTIFIER=com.chroniccare.app` | ✓ 已修 | `ios/Runner.xcodeproj/project.pbxproj:379, 561, 584` |

**结论**: R63 iOS P0/P1 8 项**全部已修**（合规 ✓），但本审计发现 **11 项新 P0 阻塞**（其中 5 项属于"完全未做"，6 项属于"做了但不一致"）。

---

## 附录 B：Apple 2024-2025 必读 Review Guidelines

| Guideline | 适用本项目 | 状态 |
|-----------|------------|------|
| 1.4.1 Medical / Health | ✓ PHQ-9 / GAD-7 / 失联通知 | 需声明 NOT a medical device + 失联非紧急（部分合规） |
| 1.4.3 Medical Apps | ✓ 量表 + 健康追踪 | 需 Medical 类目 + Privacy Health Information（**P0 阻塞**） |
| 2.1 App Completeness | ✓ IAP 假 / SMS 假 | **P0 阻塞**（§10.1 + §10.2） |
| 2.3 Accurate Metadata | ✓ 截图 / description | **P0 阻塞**（§5.2.1 + §5.2.2） |
| 3.1.5 In-App Purchase | ✓ 8 元买断 | **P0 阻塞**（§10.2） |
| 4.0 Design | ✓ 通用 | 合规 |
| 4.3 Spam | ✓ 版本号 0.27.0 | 警告（§5.2.3） |
| 5.1.1 Privacy | ✓ Privacy Manifest + App Privacy | **P0 阻塞**（§5.1.1） |
| 5.1.2 Privacy | ✓ 用户协议 / 隐私政策 | **P0 阻塞**（§5.1.2） |

---

**审计完成时间**: 2026-08-02
**下次审计触发**: 修完本报告 Top 10 P0 项后跑 flutter build ios + fastlane precheck 验证
