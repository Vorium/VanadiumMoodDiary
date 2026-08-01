# Round 74 - AppStore 视角审计

**审计时间**: 2026-08-01
**项目**: chroniccare(精神心理患者吃药打卡 App)
**版本**: 0.27.0+64(`pubspec.yaml:5`)/ working tree 干净 / R73 commit `98b041a` 完结 / 当前 `6e9f07e` (R74 P0-1 vent i18n 紧急)
**视角**: Apple App Store 上架合规
**审计模式**: 增量(对照 R69 `reports/audit/round69-appstore.md` 9 P0 + 9 P1 + 5 P2 + R70/R71/R72/R73 实际变更)
**基线**: R69 9 P0 / R67 11 项 P0 已修 / R70-R73 修了 P0-5/8/9 + 3 P1 + 1 P2 / R74 实际剩 12 P0 + 7 P1 + 3 P2

**项目基线**: 1283 tests pass / 0 fail / 0 analyzer error / 0 warning / 0 info / 16 守护脚本全绿(R73 9 analyzer info 清零后)

---

## 0. 总览

**上架就绪度评分**: **2 / 10**

**关键发现数**:
- 🔴 **P0 阻塞**: 12 项(其中 7 项从 R69 继承,2 项 R73 加重,3 项 R74 新增)
- 🟡 **P1 警告**: 7 项(其中 4 项 R69 继承,3 项 R74 新增)
- 🟢 **P2 建议**: 3 项(R69 继承)

**整体感觉**:

R69 报告指出 9 P0 阻塞后,R67/R68/R69 集中修复了 3 项(法律 md 顶部 TODO 移到末尾 / 8 元文案加注脚 / 失联通知 dormant wording),但**还有 6 项 P0 完全没动** — 包括 33 张 67 字节占位截图(1232×720 不是任何 Apple 截图尺寸)、3 张 67 字节 app_icon 占位、`fastlane/Appfile` 3 个 TODO ID 仍是占位、`app_identifier` 跟 pbxproj 不一致(`com.chroniccare.chroniccare` vs `com.chroniccare.app`)、`support@chroniccare.app` 邮箱占位、`https://chroniccare.app/privacy` 域名未注册。

R73 commit `98b041a` message 说"5 iPhone 6.5 + 3 5.5 + 3 iPad 截图已就位"但**实际所有 33 张仍是 67 字节透明占位 PNG**(1232×720,IDAT 块仅 10 字节 ≈ 全空白)。`README_PLACEHOLDER.txt` 删了但占位图原封未动 — commit message 跟实际状态不符,是 R73 audit 失察。

R74 新增 P0:
- iOS 端缺 `Podfile` + `Podfile.lock`,`.flutter-plugins-dependencies` 显示 `swift_package_manager_enabled: false`(用 CocoaPods 路径),但 `ios/` 目录**没有 Podfile** → `flutter pub get` 后才会生成,fastlane `build_app(workspace: ...)` 会**直接 build 失败**
- `info_plist.strings` 在 `ios/Runner/{zh-Hans,zh-Hant}.lproj/` 加了 R70,但 `pbxproj` 的 `knownRegions` 只声明 `en` + `Base` → zh-Hans/zh-Hant InfoPlist.strings **不会被 iOS 识别**,简体/繁体 locale fallback 到 CFBundleName=chroniccare(R70 的"修复"被 pbxproj 阻碍)
- `ITSAppUsesNonExemptEncryption=false` 跟 SQLCipher AES-256 真实使用**矛盾** — Apple 2024 起要求**真接 APNs / 真用加密**就如实声明,`false` 是自认"零加密",跟 `assets/legal/privacy_policy.md` 声明的 AES-256 字段级加密直接冲突

P0 量级:12 项 / 修复总工作量 ~15-25 工程人天 + **律师 1-2 周(不可压缩)** + **截图 1-2 天(等真机 / Mockup)** + **域名注册 + 邮箱注册 0.5 天**

---

## 1. 顶层架构审视 (iOS 端)

### 1.1 工程结构

**现状**: 标准 Flutter iOS 模板结构,代码层组织良好。

```
ios/
├── Runner.xcodeproj/        # Xcode 工程(project.pbxproj + xcschemes)
├── Runner.xcworkspace/      # Xcode workspace(contents.xcworkspacedata,不含 Pods/)
├── Runner/
│   ├── AppDelegate.swift    # @main + FlutterAppDelegate + BGTaskScheduler
│   ├── SceneDelegate.swift  # R62 引入,继承 FlutterSceneDelegate
│   ├── Info.plist           # 隐私描述 / Background / Scene / Category
│   ├── Runner.entitlements  # R70 删 aps-environment,当前几乎空
│   ├── PrivacyInfo.xcprivacy  # R67 建 + R71 加 4 字段
│   ├── Assets.xcassets/     # AppIcon 完整 15 尺寸 + LaunchImage
│   ├── Base.lproj/          # Main.storyboard + LaunchScreen.storyboard
│   ├── zh-Hans.lproj/       # InfoPlist.strings(R70 加 CFBundleDisplayName)
│   └── zh-Hant.lproj/       # InfoPlist.strings(R70 加 CFBundleDisplayName)
├── RunnerTests/             # RunnerTests.swift
└── Flutter/                 # Debug/Release/Generated.xcconfig + AppFrameworkInfo.plist
```

**✅ 通过项**:
- 工程组织符合 Apple 标准(`Runner.xcodeproj` + `Runner.xcworkspace` 双轨)
- `AppDelegate.swift:7` `@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate` 模式正确(R62 引入的 Scene-aware Flutter 3.41 模板)
- `pbxproj:155-159` Runner target buildPhases 5 个齐全(Run Script / Sources / Frameworks / Resources / Embed Frameworks / Thin Binary)
- `AppIcon.appiconset/Contents.json` 15 尺寸完整(20/29/40/60/76/83.5/1024,iPhone+iPad+ios-marketing 全 idiom 覆盖),`Icon-App-1024x1024@1x.png` 10932 bytes 真实图
- `LaunchImage.imageset/Contents.json` 3 scale(1x/2x/3x)universal idiom,LaunchScreen.storyboard 引用 image="LaunchImage" 正确

**🟡 警告项**:
- ⚠️ `pbxproj:193-196` `knownRegions = (en, Base)` **只声明 en + Base**,zh-Hans/zh-Hant 没注册 → `ios/Runner/zh-Hans.lproj/InfoPlist.strings` + `ios/Runner/zh-Hant.lproj/InfoPlist.strings` **不会被 iOS 识别**。R70 修复 CFBundleDisplayName per-locale 的代码改对了,但 pbxproj 这一行没改,简体/繁体 locale 仍 fallback 到 CFBundleName=chroniccare(英文),中文用户看英文名 = 病耻感反向(R69 NEW-2 已警示,**R70 漏改 pbxproj 配套**)
- ⚠️ iOS 端**缺 `Podfile` 和 `Podfile.lock`**(`.flutter-plugins-dependencies:100` `swift_package_manager_enabled: {"ios":false,"macos":false}` = 走 CocoaPods 路径),`Runner.xcworkspace/contents.xcworkspacedata` 也**只引用 Runner.xcodeproj 不引用 Pods/**。`flutter pub get` 后会生成 Podfile,但**当前 git 仓库 ios/ 目录里没有**。这意味着 `bundle exec fastlane ios beta` 第一次跑会失败(workspace 没 Pods)

**🔴 阻塞项**:
- 🔴 `ios/Runner.xcodeproj/project.pbxproj:193-196` `knownRegions` 未注册 zh-Hans/zh-Hant → per-locale InfoPlist.strings 失效(R70 修复半成品) — 难度 XS

### 1.2 SceneDelegate 模式 (R62 引入)

**现状**: `SceneDelegate.swift` 完整继承 `FlutterSceneDelegate`,4 行代码,完全标准。

```swift
// ios/Runner/SceneDelegate.swift:1-5
import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

}
```

**Info.plist 配套**:
```xml
<!-- ios/Runner/Info.plist:76-96 -->
<key>UIApplicationSceneManifest</key>
<dict>
    <key>UIApplicationSupportsMultipleScenes</key>
    <true/>
    <key>UISceneConfigurations</key>
    <dict>
        <key>UIWindowSceneSessionRoleApplication</key>
        <array>
            <dict>
                <key>UISceneClassName</key>
                <string>UIWindowScene</string>
                <key>UISceneConfigurationName</key>
                <string>flutter</string>
                <key>UISceneDelegateClassName</key>
                <string>$(PRODUCT_MODULE_NAME).SceneDelegate</string>
                <key>UISceneStoryboardFile</key>
                <string>Main</string>
            </dict>
        </array>
    </dict>
</dict>
```

**✅ 通过项**:
- Scene 模式接入正确(UISceneStoryboardFile=Main 接管启动,SceneDelegate 负责 FlutterViewController 生命周期)
- `UIApplicationSupportsMultipleScenes=true`(iPad 多任务支持)
- `Info.plist:74-75` `UIRequiresFullScreen=false` iPad Split View 允许
- `Main.storyboard` 用 `customClass="FlutterViewController"`(iOS 标准 Flutter 集成)

**🟡 警告项**:
- ⚠️ `Info.plist:91-92` `UISceneStoryboardFile=Main` 跟 `Main.storyboard` 引用 — Main.storyboard 实际是空壳(只一个 FlutterViewController),SceneDelegate 接管后它基本没用,但**不是 P0**

### 1.3 BGTaskScheduler (com.chroniccare.safety-check)

**现状**: `AppDelegate.swift:26-31` 注册了 BGTaskScheduler,但 `handleSafetyCheckTask` 是空壳(`setTaskCompleted(success: true)`)。

```swift
// ios/Runner/AppDelegate.swift:26-31
BGTaskScheduler.shared.register(
  forTaskWithIdentifier: "com.chroniccare.safety-check",
  using: nil
) { task in
  self.handleSafetyCheckTask(task: task as! BGProcessingTask)
}
```

**Info.plist 配套**:
```xml
<!-- ios/Runner/Info.plist:144-156 -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>processing</string>
</array>
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.chroniccare.safety-check</string>
</array>
```

**✅ 通过项**:
- BGTaskScheduler identifier 跟 Info.plist `BGTaskSchedulerPermittedIdentifiers` 一致(`com.chroniccare.safety-check`)
- `processing` 模式声明(失联检测长任务 → 实际业务暂停,R67 留 capability)
- `audio` 模式声明(树洞/情绪日记录音时切后台继续,跟 `pubspec.yaml:56-57` `record 5.2.0` + `audioplayers 6.1.0` 对应)

**🟡 警告项**:
- ⚠️ **P1-5**(R69 NEW-7 加重): `UIBackgroundModes=processing` 声明但实际**不触发**(`FeatureFlags.emergencyContactEnabled=false`,R66 业务整体暂停,R68 修代码)→ App Store Connect 后台 App Privacy 描述如不加 "Lost-contact safety net: currently disabled" 醒目声明,审核员会认为项目**声明了 capability 但不实际使用 = dormant**。当前 fastlane/metadata/ios/*/description.txt 已有"coming soon — currently disabled" 段(各 locale line 13-16),但跟 entitlement 声明仍**需在 ASC 提交时勾选对应** App Privacy 复选框
- ⚠️ **P1-6**(R69 NEW-6 续): `UIBackgroundModes=audio` 真实使用(录音中切后台不中断),但 vent 录音 dialog 顶部**没有"录音时切到后台会继续录制"提示** → Apple 4.0 Background audio 建议 visible purpose 提示(`lib/presentation/pages/vent/vent_compose_page.dart` 录音 UI 顶部加 1 行 caption)

**🔴 阻塞项**:
- 无

### 1.4 第三方 plugin 集成

**现状**: 12 个 plugin 走 Flutter `native_build=true` 模式,无 CocoaPods/SPM 冲突。

| Plugin | 版本 | PrivacyInfo | iOS API | 备注 |
|---|---|---|---|---|
| audioplayers_darwin | 6.4.0 | 自带 | AVAudioPlayer | 树洞 audio 播放 |
| flutter_local_notifications | 17.2.4 | 自带 | UNUserNotificationCenter | 本地通知 |
| flutter_secure_storage | 9.2.4 | 自带 | Keychain | SQLCipher key 存 |
| flutter_timezone | 3.0.1 | 自带 | NSTimeZone | 时区 |
| in_app_purchase_storekit | 0.4.11 | 自带 | StoreKit | **8 元买断(IAP 业务整体暂停)** |
| path_provider_foundation | 2.6.0 | 自带 | FileManager | DB path |
| permission_handler_apple | 9.4.10 | 自带 | AVCaptureDevice | 麦克风权限 |
| printing | 5.14.3 | 自带 | UIPrintInteractionController | PDF 报告打印 |
| record_darwin | 1.2.2 | 自带 | AVAudioRecorder | 树洞录音 |
| share_plus | 10.1.4 | 自带 | UIActivityViewController | PDF 分享 |
| shared_preferences_foundation | 2.5.6 | 自带 | UserDefaults | assessment 提醒 |
| speech_to_text | 7.4.0 | 自带 | SFSpeechRecognizer | 语音转文字 |
| sqlcipher_flutter_libs | 0.6.8 | 自带 | SQLCipher C ext | DB 加密 |

**✅ 通过项**:
- 12 个 plugin 都有 `native_build=true` / `shared_darwin_source=true` 标识
- 隐私 manifest 全部 `plugin` 端自带(无需项目级补)
- 关键 permission plugin 全部对应 Info.plist 描述:`NSMicrophoneUsageDescription`(record)、`NSSpeechRecognitionUsageDescription`(speech_to_text)、`NSPhotoLibraryUsageDescription`(share_plus + printing)

**🟡 警告项**:
- ⚠️ **P1-7**(R69 NEW-8 续): 项目自身 `PrivacyInfo.xcprivacy` 已声明 4 类 CollectedDataType + 5 类 AccessedAPI,但 `pod install` + build 后**未验证** Pods/<plugin>.framework/PrivacyInfo.xcprivacy 是否完整(Apple 2024-05 强制) — `pod install` 没跑过,Podfile 不存在,**无法 build 后验证**
- ⚠️ `in_app_purchase_storekit 0.4.11` 引入但 `FeatureFlags._prodIapEnabled=false`(R68 d691551 决策)+ App description 仍提 8 元 — R69 P0-8 已警示,代码层 R68 修,文档层 R69 加注脚,但 **App Store Connect 后台 IAP 列表需保持空**(不能创建 productId,否则 ASC 提示"unreferenced IAP")

**🔴 阻塞项**:
- 无直接 P0,但 Podfile 缺失导致整个 iOS build 失败(见 1.1 P0)

---

## 2. 底层逐行排查 (iOS 端)

### 2.1 Info.plist (157 行)

**位置**: `ios/Runner/Info.plist`

**✅ 通过项**:
- `:5-6` `CADisableMinimumFrameDurationOnPhone=true` — 120Hz 刷新率支持
- `:33-34` `LSRequiresIPhoneOS=true` — 强制 iOS 设备
- `:42-43` `NSMicrophoneUsageDescription` "用于情绪日记的语音录入" — 跟 `record 5.2.0` 对应
- `:44-45` `NSSpeechRecognitionUsageDescription` "用于情绪日记的语音转文字" — 跟 `speech_to_text 7.0.0` 对应
- `:51-52` `NSPhotoLibraryAddUsageDescription` "用于保存用药报告 PDF 到相册" — R62 加,share_plus + printing 用
- `:61-62` `NSPhotoLibraryUsageDescription` "用于分享用药报告 PDF 时选择保存位置" — R67 Sprint 1 加
- `:67-68` `NSUserTrackingUsageDescription` "本应用不收集任何追踪数据" — R61 防御性加(项目无 IDFA)
- `:103-104` `ITSAppUsesNonExemptEncryption=false` — Apple 2024 export compliance 声明
- `:116-128` iPhone + iPad orientation 全 4 方向
- `:136-137` `LSApplicationCategoryType=healthcare-fitness` — R66 加,跟 App Store Connect Health & Fitness 分类对应
- `:144-148` `UIBackgroundModes=[audio, processing]` — BGTaskScheduler 配套
- `:153-156` `BGTaskSchedulerPermittedIdentifiers=[com.chroniccare.safety-check]` — 跟 AppDelegate.swift:26-31 一致

**🟡 警告项**:
- ⚠️ **P1-1**(R69 P1-4 续): `Info.plist:103-104` `ITSAppUsesNonExemptEncryption=false` 跟代码层 SQLCipher AES-256 + Keychain 真实使用**矛盾**。R70 没改,文件注释 `ios/Runner/Info.plist:97-102` 写"标 false"是因为 SQLCipher 走标准库加密(自审豁免),但 `assets/legal/privacy_policy.md` 公开声明"AES-256 字段级加密" — Apple reviewer 看到这两份文件会**真接问"你声明零加密但隐私政策说 AES-256,你是不是在撒谎"**。建议: 改 `true` + 准备 self-classification report(CCATS 编号),或反向把 `privacy_policy.md` 措辞改为"标准库 SQLCipher 加密,符合 Apple export compliance 豁免"
- ⚠️ **P1-2**(R69 P1-7 续): `Info.plist:144-148` `UIBackgroundModes=processing` 实际**不触发**(`FeatureFlags.emergencyContactEnabled=false`,R66 业务整体暂停)→ App Store Connect 提交时如不在 App Privacy 描述勾选"暂不启用"会被判 dormant。Fastlane 已配 `metadata/ios/*/description.txt` 都有"coming soon"段,但需手动勾选 App Privacy 标签
- ⚠️ **P1-3**(R74 NEW): `Info.plist:15-16` `CFBundleDisplayName=ChronicCare`(英文单值) + `ios/Runner/{zh-Hans,zh-Hant}.lproj/InfoPlist.strings` per-locale 覆盖 "慢病管家" — R70 修复但**`pbxproj:193-196` knownRegions 未注册 zh-Hans/zh-Hant**,per-locale 失效

**🔴 阻塞项**:
- 无新增 P0(R70/R71/R72 已修 5 项:NSUserNotificationUsageDescription 删、InfoPlist.strings 加、UIMainStoryboardFile 删、aps-environment 删、EXCLUDED_ARCHS 删)

### 2.2 Runner.entitlements (13 行)

**位置**: `ios/Runner/Runner.entitlements`

```xml
<!-- ios/Runner/Runner.entitlements:1-13 -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!--
        v0.27 R70: 删 aps-environment
        原因: 项目无 APNs 远程推送, 只用 flutter_local_notifications 17.x 本地通知
        保留 aps-environment 会让 App Store Connect 误判"项目声明走 APNs 远程推送",
        后台 'Push Notifications' 标签必须填 (Yes = 走真接 APNs / No = 跟 entitlement 矛盾)
        直接删此 key 即声明"项目不使用 APNs 远程推送", App Store Connect 自动推断 No
    -->
</dict>
</plist>
```

**✅ 通过项**:
- R70 删 `aps-environment=development` 正确(项目无 APNs 远程推送,误导审核员)
- 注释清楚解释为什么删

**🟡 警告项**:
- 无(entitlements 几乎空 = 正确,项目无 IAP 真接 / HealthKit / NetworkExtension)

**🔴 阻塞项**:
- 无

### 2.3 PrivacyInfo.xcprivacy (148 行)

**位置**: `ios/Runner/PrivacyInfo.xcprivacy`

**✅ 通过项**:
- `:22-23` `NSPrivacyTracking=false` — 正确(项目零追踪)
- `:24-25` `NSPrivacyTrackingDomains=[]` — 正确
- `:42-92` `NSPrivacyCollectedDataTypes` 4 类(HealthAndFitness / AudioData / ContactInfo / UserContent),每类 Linked=false/Tracking=false/Purpose=AppFunctionality — R67 加,合规
- `:97-108` `NSPrivacyAccessedAPICategoryUserDefaults` + CA92.1 + CA92.2 — R71 P2-1 加 CA92.2 防御性
- `:110-116` `NSPrivacyAccessedAPICategoryFileTimestamp` + C617.1 — 正确
- `:118-124` `NSPrivacyAccessedAPICategorySystemBootTime` + 35F9.1 — 正确
- `:126-132` `NSPrivacyAccessedAPICategoryDiskSpace` + 85F4.1 — 正确
- `:134-146` `NSPrivacyAccessedAPICategoryProcessInfo` + AC67.1 — R71 P2-1 加,flutter_local_notifications 17.x 配套

**🟡 警告项**:
- ⚠️ 缺 `NSPrivacyAccessedAPICategoryActiveKeyboards` / `NSPrivacyAccessedAPICategoryUserDefaults`-CA92.2 之外的 reason (CA92.1 only) — 当前声明的 5 类 + 4 reason 已覆盖 Apple 强制 required reason API(2024-05 政策),但第三方 plugin 内部的 API 调用未覆盖(见 1.4 P1-7)

**🔴 阻塞项**:
- 无(项目自身声明完整)

### 2.4 SceneDelegate / AppDelegate (52 行)

**位置**: `ios/Runner/SceneDelegate.swift` + `ios/Runner/AppDelegate.swift`

**SceneDelegate.swift** (`ios/Runner/SceneDelegate.swift`):
```swift
// 1-5
import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

}
```
- ✅ 4 行标准继承,无业务代码

**AppDelegate.swift** (`ios/Runner/AppDelegate.swift`):
```swift
// 7-52
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(...) -> Bool {
    // iOS 10+ foreground 通知
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    // BGTaskScheduler 注册
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: "com.chroniccare.safety-check",
      using: nil
    ) { task in
      self.handleSafetyCheckTask(task: task as! BGProcessingTask)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  // BGTaskScheduler handler 空壳
  private func handleSafetyCheckTask(task: BGProcessingTask) {
    task.setTaskCompleted(success: true)
  }
}
```

**✅ 通过项**:
- `:15-17` iOS 10+ foreground 通知 delegate 设置(R67 Sprint 1 C-P0-8 修)
- `:26-31` BGTaskScheduler 注册 + identifier 跟 Info.plist 一致
- `:36-38` `didInitializeImplicitFlutterEngine` 注册 plugin(Flutter 3.41 Implicit Engine 模式)
- `:49-51` `handleSafetyCheckTask` 空壳 + `setTaskCompleted(success: true)` 防止 iOS 后台资源浪费(失联通知业务暂停,占位)

**🟡 警告项**:
- ⚠️ `:16` `UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate` — `as?` 强制转换如果 AppDelegate 不真正实现 UNUserNotificationCenterDelegate 方法,delegate 设置会**静默失败**。FlutterAppDelegate 已实现,但 `as?` 转换需检查 return 值。当前 AppDelegate 未实现 `userNotificationCenter(_:willPresent:withCompletionHandler:)`,foreground 通知 banner **可能不显示**。R67 注释说"iOS 14+ foreground 通知不弹,用户体验断档"但**修复只是设 delegate,没实现方法**

**🔴 阻塞项**:
- 🔴 **P0-3**(R74 NEW): `:16` UNUserNotificationCenter delegate 设置但**未实现 foreground 通知展示方法** → 用户用 app 时通知不弹(精神心理患者提醒吃药关键场景) — 难度 XS(在 AppDelegate 加 `userNotificationCenter(_:willPresent:withCompletionHandler:)` 返回 `[.banner, .sound]`)

### 2.5 InfoPlist.strings (多语)

**位置**: `ios/Runner/zh-Hans.lproj/InfoPlist.strings` + `ios/Runner/zh-Hant.lproj/InfoPlist.strings`

**zh-Hans** (`ios/Runner/zh-Hans.lproj/InfoPlist.strings`):
```
/* v0.27 R70 (NEW-2 appstore P1-2): per-locale CFBundleDisplayName */
"CFBundleDisplayName" = "慢病管家";
```

**zh-Hant** (`ios/Runner/zh-Hant.lproj/InfoPlist.strings`):
```
/* v0.27 R70 (NEW-2 appstore P1-2): per-locale CFBundleDisplayName */
"CFBundleDisplayName" = "慢病管家";
```

**🟡 警告项**:
- ⚠️ **P1-3**(R74 NEW): 2 个 InfoPlist.strings 都有正确的字符串,但** `pbxproj:193-196` `knownRegions` 没注册 zh-Hans/zh-Hant** → iOS 不会读这些文件,中文 locale fallback 到 CFBundleName=chroniccare(英文)。R70 修复"看起来改对了"但 pbxproj 漏改,简体/繁体用户看英文名 = 病耻感反向

**🔴 阻塞项**:
- 🔴 **P0-4**(R74 NEW): `ios/Runner.xcodeproj/project.pbxproj:193-196` `knownRegions = (en, Base)` 需改为 `(en, Base, zh-Hans, zh-Hant)` — 难度 XS(改 1 行)

### 2.6 Podfile

**位置**: `ios/Podfile` (不存在) + `ios/Podfile.lock` (不存在)

**现状**:
- `Test-Path 'D:\Batch\chroniccare\ios\Podfile'` 返回 False
- `Test-Path 'D:\Batch\chroniccare\ios\Podfile.lock'` 返回 False
- `.flutter-plugins-dependencies:100` `swift_package_manager_enabled: {"ios":false,"macos":false}` → 走 CocoaPods 路径
- `ios/Runner.xcworkspace/contents.xcworkspacedata` 只引用 `Runner.xcodeproj`,**不引用 Pods/**

**🔴 阻塞项**:
- 🔴 **P0-5**(R74 NEW): iOS 端缺 `Podfile` + `Podfile.lock` — `flutter pub get` 后才会生成,但 git 仓库**不跟踪**这 2 个文件(标准 Flutter 实践),意味着:
  1. 第一次 `bundle exec fastlane ios beta` 跑会** build 失败**(workspace 找不到 Pods)
  2. 修复路径: 用户在本地跑 `cd ios && pod install`(或 `flutter pub get` 自动生成),然后 commit Podfile.lock 锁版本
  3. 但项目根 `pubspec.lock` 锁 plugin 版本后,`flutter pub get` 重新生成 Podfile.lock 应该一致 — 风险:12 个 plugin 中如果有 1 个 plugin 强制依赖某 pod 版本,Podfile.lock 内容会因 `pod install` 缓存的 master spec repo 状态不同而漂移
- 难度: M(`flutter pub get` + `pod install` + commit Podfile.lock + 验证 build)

### 2.7 pbxproj (625 行)

**位置**: `ios/Runner.xcodeproj/project.pbxproj`

**✅ 通过项**:
- `:6` `objectVersion = 54` — Xcode 14+ 现代格式
- `:176` `LastUpgradeCheck = 1510` — Xcode 15.1
- `:341, 462, 519` `CODE_SIGN_IDENTITY[sdk=iphoneos*] = "iPhone Developer"` — 自动签名
- `:355, 482, 533` `IPHONEOS_DEPLOYMENT_TARGET = 14.0` — iOS 14+ 最低
- `:359, 486, 539` `TARGETED_DEVICE_FAMILY = "1,2"` — iPhone + iPad
- `:378, 558, 581` `PRODUCT_BUNDLE_IDENTIFIER = com.chroniccare.app` — 3 个 build configuration (Profile/Debug/Release) 一致
- `:153-159` Runner target buildPhases 5 个齐全

**🟡 警告项**:
- ⚠️ `:193-196` `knownRegions = (en, Base)` **缺 zh-Hans/zh-Hant**(见 2.5 P0-4)
- ⚠️ R70 删 3 处 `EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64` 已修(R69 NEW-3)
- ⚠️ R70 pbxproj diff stat 1253 +++++++++++++++--------------- — R70 大改 pbxproj 需 verify 没引入其他 diff
- ⚠️ `:583` RunnerTests.PRODUCT_BUNDLE_IDENTIFIER = `com.chroniccare.chroniccare.RunnerTests` — 跟 Runner target `com.chroniccare.app` **不一致**(但 test bundle ID 不一致是正常的)
- ⚠️ `:14` SceneDelegate.swift file ref `7884E8672EC3CC0400C636F2` 已加(R62 引入)

**🔴 阻塞项**:
- 🔴 **P0-1**(R69 P0-1 续, R74 加重): `:378, 558, 581` `PRODUCT_BUNDLE_IDENTIFIER = com.chroniccare.app` 跟 `fastlane/Appfile:19` `app_identifier("com.chroniccare.chroniccare")` **不一致** → fastlane 上传会因 bundle id 不在 App Store Connect 创建列表而**直接拒** — 难度 XS(改 1 行)
- 🔴 **P0-2**(R69 P0-2 续): `fastlane/Appfile:21, 23, 25` 3 个 TODO ID 仍是占位(`your-apple-id@example.com` / `YOUR_TEAM_ID` / `YOUR_ITC_TEAM_ID`) — 难度 XS(替换为真实值)
- 🔴 **P0-4**(R74 NEW): `:193-196` `knownRegions` 缺 zh-Hans/zh-Hant(见 2.5)

### 2.8 Fastfile (151 行)

**位置**: `fastlane/Fastfile`

**✅ 通过项**:
- `platform :ios do ... end` 块完整
- `:29-40` `lane :beta` — build_app + upload_to_testflight
- `:43-68` `lane :release` — build_app + upload_to_app_store (含 `submit_for_review: true` + `automatic_release: false`)
- `:71-77` `lane :metadata` — 只同步 metadata 不 build
- `platform :android do ... end` R70 + R71 完整(跟 iOS 平行)
- `:65-66` 注释明确 IAP 业务暂停,`precheck_include_in_app_purchases: false`

**🟡 警告项**:
- ⚠️ `:19` `Appfile` 安全注释说"敏感 apple_id 写到这前先确保 fastlane/Appfile 已被 .gitignore 排除" — 实际 `fastlane/Appfile` **被 git 跟踪**(R67 commit 556d454),3 个 TODO ID 是占位字符串,但若用户直接替换为真实值会** commit 真实 Apple ID 到 git**。建议走 ENV 模式 `apple_id(ENV["APPLE_ID"])`(R67 注释已提"后续挪到 ENV"但 R73 没动)
- ⚠️ `:30-36, 45-51` `build_app(workspace: "Runner.xcworkspace", ...)` — 依赖 Podfile/Pods 存在(见 2.6 P0-5),首次跑会失败

**🔴 阻塞项**:
- 无 Fastfile 自身 P0,所有 iOS 上架 P0 都从 `Appfile` / Podfile 衍生

### 2.9 fastlane/metadata/ios (3 locale)

**位置**: `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/`

**✅ 通过项 (3 locale 都齐)**:
- 9 个 metadata 文件(`app_icon.png` / `name.txt` / `subtitle.txt` / `description.txt` / `keywords.txt` / `promotional_text.txt` / `support_url.txt` / `privacy_url.txt` / `copyright.txt`)
- 3 个截图子目录(`iphone_6_5_screenshots` / `iphone_5_5_screenshots` / `ipad_12_9_screenshots`)

**字符数合规** (Apple 上限):

| 字段 | en-US | zh-Hans | zh-Hant | Apple 上限 | 状态 |
|---|---|---|---|---|---|
| name.txt | 11 | 6 | 6 | 30 | ✅ |
| subtitle.txt | 25 | 28 | 27 | 30 | ✅ |
| keywords.txt | 54 | 27 | 27 | 100 | ✅ |
| promotional_text.txt | 136 | 69 | 69 | 170 | ✅ |
| description.txt | 2913 | 1359 | 1324 | 4000 | ✅ |

**🟡 警告项**:
- ⚠️ 3 locale 描述都用"我今天吃了药"开篇情绪化叙事 + 详细隐私承诺 + 紧急电话 + Medical disclaimer — 文案质量高
- ⚠️ `en-US/description.txt:14-17` 失联通知 "Lost-contact safety net (coming soon — currently disabled)" + 解释为什么暂停 — R69 P0-9 修了
- ⚠️ 3 locale 都有 PHQ-9/GAD-7 + 树洞 + 紧急电话声明 — Medical 类必备
- ⚠️ `zh-Hans/description.txt:36-41` 北京 010-82951332 / 全国 400-161-9995 / 上海 021-12320-5 / findahelpline.com
- ⚠️ `zh-Hant/description.txt:37-40` 台湾 1925 / 香港 2389 2222 / findahelpline.com
- ⚠️ `en-US/description.txt:48-50` US 988 / UK 116 123 / findahelpline.com
- ⚠️ 3 locale 都声明 "ChronicCare is NOT a medical device and does not provide medical advice, diagnosis, or treatment" — Medical 类合规

**🔴 阻塞项**:
- 🔴 **P0-6**(R69 P0-3 续, R73 加重): **33 张截图全 67 字节透明占位 PNG**(`1232×720` 不是任何 Apple 截图尺寸,IDAT 块仅 10 字节 ≈ 空白):
  - en-US / zh-Hans / zh-Hant × `iphone_6_5_screenshots/0[1-5]_home.png` = 5 × 3 = 15 张
  - en-US / zh-Hans / zh-Hant × `iphone_5_5_screenshots/0[1-3]_home.png` = 3 × 3 = 9 张
  - en-US / zh-Hans / zh-Hant × `ipad_12_9_screenshots/0[1-3]_home.png` = 3 × 3 = 9 张
  - 15 + 9 + 9 = 33 张,全 67 字节
  - R73 commit `98b041a` 删了 `README_PLACEHOLDER.txt` 警示文件,commit message 写"5 iPhone 6.5 + 3 5.5 + 3 iPad 截图已就位" — **commit message 跟实际状态不符**,33 张仍全部占位
  - 实际应分辨率:
    - iPhone 6.5" = 1242×2688 px
    - iPhone 5.5" = 1242×2208 px
    - iPad 12.9" = 2048×2732 px
  - 难度: L(1-2 天 Simulator 截图 + 1-2 天 design polish)
- 🔴 **P0-7**(R69 P0-4 续): 3 张 `app_icon.png` 全 67 字节占位(`1232×720`,不符合 Apple 1024×1024 不透明 PNG 要求)
  - 实际 AppIcon 资产(`ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`) 10932 bytes 真实 — 但 fastlane 上传的 `app_icon.png` 是另一份(从 AppIcon 复制或重导出),当前是占位
  - 难度: XS(从 AppIcon 复制 + 校验 1024×1024 + 不透明)
- 🔴 **P0-8**(R69 P0-7 续): 6 个 URL 文件 `privacy_url.txt` / `support_url.txt` × 3 locale 全是 `https://chroniccare.app/privacy` + `https://chroniccare.app/support` — 域名**未注册未验证**,Apple reviewer 点 URL 验真伪时 404 = **直接拒**
  - 难度: M(注册 chroniccare.app 域名 + 部署 privacy / support 页面 + HTTPS 证书)

### 2.10 法律文件 3 份

**位置**: `assets/legal/{privacy_policy.md, user_agreement.md, sensitive_data_consent.md}`

**✅ 通过项**:
- 3 份 md 文件完整(R69 P0-5 顶部 TODO 移到末尾"修订历史"段)
- `user_agreement.md:11` 失联通知标"规划中,本版本未启用"(R69 CC-7 修)
- `user_agreement.md:24-28` 8 元买断段加 v0.28 注脚(R69 CC-3 修)
- `privacy_policy.md:0.5` 紧急联系人告知完整 (PIPL §23 单独同意)
- `sensitive_data_consent.md` 4.5 KB,PIPL §28-29 敏感个人信息处理依据

**🟡 警告项**:
- ⚠️ 3 份 md **都只有中文版**,**无英文版 / 繁体版**:
  - `user_agreement.md` zh 3785 字 / en 0 / zh-Hant 0
  - `privacy_policy.md` zh 13160 字 / en 0 / zh-Hant 0
  - `sensitive_data_consent.md` zh 4024 字 / en 0 / zh-Hant 0
  - en-US 走 App Store 时 consent 3 份 md 都是中文 → **Apple 1.4.3 + PIPL 双重 fail**(Apple 5.1.1 透明性 + PIPL 知情同意语种)
  - R69 CC-8 5 视角共识 P0,R73 仍未修
  - 建议: 走 OpenCC s2tw 简体→繁体 转换 + 翻译英文版(L 难度,1-2 周)
- ⚠️ `user_agreement.md:60-61` `support@chroniccare.app` 邮箱占位 + `https://github.com/example/chroniccare/issues` 仓库占位(R69 P0-6 续)
- ⚠️ `privacy_policy.md:0.5` 引用 `docs/SPRINT1_LEGAL_TODO.md` / `docs/LEGACY_API_NOTES.md` 但这 2 个文件**实际不存在**:
  - `Test-Path 'D:\Batch\chroniccare\docs\SPRINT1_LEGAL_TODO.md'` → False
  - `Test-Path 'D:\Batch\chroniccare\docs\LEGACY_API_NOTES.md'` → False
  - 隐私政策引用不存在的文件 = 文档不一致 = Apple 5.1.1 透明性 fail

**🔴 阻塞项**:
- 🔴 **P0-9**(R69 P0-6 续, R74 加发现): `user_agreement.md:60-61` 邮箱 + GitHub 仓库占位 — 难度 S(注册邮箱 + 创建/确认 GitHub 仓库)
- 🔴 **P0-10**(R69 CC-8, R74 加重): 3 份法律 md 无英文版 / 繁体版 — 难度 L(翻译 1-2 周)
- 🔴 **P0-11**(R74 NEW): `privacy_policy.md:0.5` + `user_agreement.md:60-61` 引用不存在的 `docs/SPRINT1_LEGAL_TODO.md` + `docs/LEGACY_API_NOTES.md` — 难度 XS(创建 2 占位文件 OR 删除引用)

---

## 3. App Store 审核重点

### 3.1 Medical 类 (1.4.1) — 精神心理患者属 medical,需 disclaimer

**位置**: `fastlane/metadata/ios/*/description.txt` + `assets/legal/*.md`

**✅ 通过项**:
- 3 locale 描述都有 "ChronicCare is NOT a medical device and does not provide medical advice, diagnosis, or treatment" disclaimer
- 3 locale 都有 PHQ-9 (depression) / GAD-7 (anxiety) 评估量表标注 + 跟踪用途
- 3 locale 紧急电话全:
  - en-US: 988 (US) / 116 123 (UK) / findahelpline.com
  - zh-Hans: 010-82951332 (北京) / 400-161-9995 (全国) / 021-12320-5 (上海)
  - zh-Hant: 1925 (台湾) / 2389 2222 (香港) / findahelpline.com
- `LSApplicationCategoryType=healthcare-fitness` 跟 App Store Connect Primary Category 对应
- 树洞独立表隐私边界(不进任何分析/通知/关怀)由 `lib/` 多处守门员保证

**🟡 警告项**:
- ⚠️ **P1-4**(R69 P1-6 续): PHQ-9 / GAD-7 量表 32 题 + 严重度 + 危机电话**未走 ARB 全 i18n** — `lib/domain/logic/phq9.dart` / `lib/domain/logic/gad7.dart` 仍是 hardcode 中文(项目惯例 `FeatureFlags.phqGad7I18nEnabled=false`, R65b 默认关闭)。Apple 1.4.1 明确要求"apps must clearly disclose data and methodology to support accuracy claims" — 跨语种量表 = 准确性受质疑
- ⚠️ **P1-5**(R69 P1-8 续): 隐私政策 §11 跨域 PII 描述"审计日志(本地)"但代码层 `safety_alert_dispatcher.dart` / `audit_log_repository.dart` **0 个 audit 写入点** — R66 业务暂停期间 OK,R67 撤回同意生效后必须真接 audit log(建议 `audit_log_repository.dart` 加 `recordSafetyAlertDispatch(...)` 方法)
- ⚠️ **P1-6**(R69 P1-9 续): 隐私政策 §192 表格"紧急联系人回复 Y 确认" 列勾 ☒ v0.25 TODO,但 R66 起业务暂停,应改 ☑ 已暂停(R66 决策)。当前未改

**🔴 阻塞项**:
- 🔴 **P0-12**(R74 NEW,综合 P0-9/10/11): Medical 类需要 en-US 走 App Store,**英文版 3 法律 md 不存在** + support@ 占位 + 引用不存在文件 — 合并为 1 大 P0,所有都需在审核前修

### 3.2 Privacy (5.1.1)

**位置**: `assets/legal/privacy_policy.md` + `ios/Runner/PrivacyInfo.xcprivacy`

**✅ 通过项**:
- 隐私政策 14 KB,详尽列 8 类数据(用户标识 / 紧急联系人 / 心理健康 / 药物 / 评估 / 树洞 / 情绪日记 / 录音元数据) + 收集目的 + 存储位置 + 敏感性
- PIPL §14 单独同意(setup 3 勾选 — 用户协议 / 隐私政策 / 敏感个人信息处理同意书)
- PIPL §23 紧急联系人告知(软提示 R66 起每个联系人单独勾选)
- `PrivacyInfo.xcprivacy` 4 类 CollectedDataType + 5 类 AccessedAPI
- `NSUserTrackingUsageDescription` 防御性声明"零追踪"
- `NSPrivacyTracking=false`

**🟡 警告项**:
- ⚠️ 3 份法律 md 缺英文版/繁体版(见 3.1 P0-12)
- ⚠️ 隐私政策 §11 引用不存在文件(见 2.10 P0-11)
- ⚠️ `its_app_uses_non_exempt_encryption=false` 跟 SQLCipher AES-256 矛盾(见 2.1 P1-1)

**🔴 阻塞项**:
- 同 3.1 P0-12

### 3.3 App Completeness (2.1)

**位置**: 整体 App 功能

**✅ 通过项**:
- 8 个页面全部有真实实现(home / setup / settings / trend / assessment / check_in / contact / medication / mood / vent)
- 3 个核心数据(check_in / mood / medication)有 streak 跟踪
- 心理评估 PHQ-9 / GAD-7 量表 + 历史趋势
- 树洞(vent)文字 + 录音
- 数据导出 JSON
- 主题切换 light/dark
- 多语 zh-Hans / zh-Hant / en(setup 选语种)

**🟡 警告项**:
- ⚠️ 失联通知功能整体暂停(`FeatureFlags.emergencyContactEnabled=false`, R66 决策)但 UI 流程保留,description 写"coming soon" — R69 P0-9 修了文档层
- ⚠️ IAP 8 元买断整体暂停(`FeatureFlags._prodIapEnabled=false`, R68 决策),App 内不显示入口 — R69 加 v0.28 注脚
- ⚠️ PHQ-9 / GAD-7 i18n 关闭(中英量表混用,准确度问题)(见 3.1 P1-4)

**🔴 阻塞项**:
- 无 App Completeness 直接 P0(失联通知 / IAP 已在 description 声明暂停 + 代码层 FeatureFlags 双重防御)

### 3.4 Privacy Manifest (2.3.1)

**位置**: `ios/Runner/PrivacyInfo.xcprivacy` + 12 个 plugin 自带

**✅ 通过项**:
- `PrivacyInfo.xcprivacy` 完整 5 类 AccessedAPI(CA92.1/CA92.2/C617.1/35F9.1/85F4.1/AC67.1)+ 4 类 CollectedDataType(HealthAndFitness/AudioData/ContactInfo/UserContent) — Apple 2024-05 强制
- 12 个 plugin 都有 `native_build=true` 标识,各自带 PrivacyInfo(但 `pod install` 跑过后才能 verify,见 1.4 P1-7)
- `NSPrivacyTracking=false` / `NSPrivacyTrackingDomains=[]`

**🟡 警告项**:
- ⚠️ 第三方 plugin 自带 PrivacyInfo 完整性**未 verify**(见 1.4 P1-7)

**🔴 阻塞项**:
- 无直接 P0(项目自身 PrivacyInfo 完整)

### 3.5 Background Mode

**位置**: `ios/Runner/Info.plist:144-148` + `ios/Runner/AppDelegate.swift:26-51`

**✅ 通过项**:
- `UIBackgroundModes=[audio, processing]` 声明齐全
- `BGTaskSchedulerPermittedIdentifiers=[com.chroniccare.safety-check]` 跟 AppDelegate 一致
- `audio` 真实使用(树洞/情绪日记录音)
- `processing` 占位(失联通知业务暂停,R66 决策)

**🟡 警告项**:
- ⚠️ `processing` 模式声明但**不触发**(R66 业务暂停),App Store Connect App Privacy 需手动声明 (见 1.3 P1-5)
- ⚠️ `audio` 真实使用但 vent 录音 dialog **缺"切到后台会继续录制"提示**(见 1.3 P1-6)

**🔴 阻塞项**:
- 无

### 3.6 IAP (4.0 — 强制 IAP)

**位置**: `lib/core/data/feature_flags.dart:38` + `pubspec.yaml:63` `in_app_purchase: ^3.3.0`

**✅ 通过项**:
- `FeatureFlags._prodIapEnabled=false`(R68 d691551 决策),App 内不显示入口
- `in_app_purchase` plugin 已集成但 dev 模式走 kDebugMode 直接返 true
- 3 locale description 都有 8 元买断注脚("v0.28 真接 productId 后启用")
- Fastfile `precheck_include_in_app_purchases: false` 显式声明无 IAP

**🟡 警告项**:
- ⚠️ `in_app_purchase_storekit 0.4.11` 引用了 StoreKit 框架但**未真接 productId** — Apple 4.0 不强制声明 IAP 存在(描述里写"8 元买断"但代码层不接 = R69 P0-8 已警示,R69 加注脚修了文档层)
- ⚠️ v0.28 真接时需在 App Store Connect 创建 NonConsumable product,Fastfile `precheck_include_in_app_purchases: true` 同步改

**🔴 阻塞项**:
- 无 IAP P0(已通过 FeatureFlags 隔离)

---

## 4. App Store Connect 表单必填项

| # | 字段 | 当前值 | 阻塞状态 |
|---|---|---|---|
| 1 | App 名称 (App Name) | "慢病管家" (per-locale) | 🔴 P0-1 (bundle ID 不一致) + P0-4 (knownRegions 缺 zh) |
| 2 | Bundle ID | `com.chroniccare.chroniccare` (fastlane) vs `com.chroniccare.app` (pbxproj) | 🔴 P0-1 (不一致, ASC 必拒) |
| 3 | SKU | 未设 | 🟢 P2-1(可任意字符串) |
| 4 | Primary Language | 英文 (en-US) | ✅ |
| 5 | Primary Category | Health & Fitness | ✅(Info.plist `LSApplicationCategoryType=healthcare-fitness` 匹配) |
| 6 | Secondary Category (可选) | 未设 | 🟢 P2-2(建议 Medical 二次分类) |
| 7 | Price / 售价 | 未设 | 🟡 P1-7(8 元文案 vs 不接 IAP 矛盾, 建议 App 标 Free 或同价) |
| 8 | App 描述 (Description) | en-US 2913 chars / zh-Hans 1359 / zh-Hant 1324 | ✅(Apple 上限 4000) |
| 9 | 关键词 (Keywords) | en-US 54 / zh-Hans 27 / zh-Hant 27 | ✅(Apple 上限 100) |
| 10 | 副标题 (Subtitle) | en-US 25 / zh-Hans 28 / zh-Hant 27 | ✅(Apple 上限 30) |
| 11 | 宣传文本 (Promotional Text) | en-US 136 / zh-Hans 69 / zh-Hant 69 | ✅(Apple 上限 170) |
| 12 | 隐私 URL | `https://chroniccare.app/privacy` (3 locale) | 🔴 P0-8(域名未注册) |
| 13 | 支持 URL | `https://chroniccare.app/support` (3 locale) | 🔴 P0-8(域名未注册) |
| 14 | 营销 URL (可选) | 未设 | 🟢 P2-3 |
| 15 | 版权 (Copyright) | "© 2026 chroniccare" / "© 2026 慢病管家" | ✅ |
| 16 | App Icon 1024×1024 | 67 字节占位 | 🔴 P0-7(实际用 AppIcon 资产 10932 bytes 真实,需重导出) |
| 17 | iPhone 6.5" 截图 (1242×2688) | 67 字节占位 × 5 = 5 张 | 🔴 P0-6 |
| 18 | iPhone 5.5" 截图 (1242×2208) | 67 字节占位 × 3 = 3 张 | 🔴 P0-6 |
| 19 | iPad 12.9" 截图 (2048×2732) | 67 字节占位 × 3 = 3 张 | 🔴 P0-6 |
| 20 | iPhone 6.7" 截图 (1290×2796, 2024 新要求) | **不存在** | 🟡 P1-8(R74 加重 — 1232×720 不是 6.5/6.7/6.9 任一尺寸) |
| 21 | App Privacy 数据收集声明 | 需在 ASC 后台手动勾选 | 🟡 P1-5(对应 `UIBackgroundModes=processing` dormant 声明) |
| 22 | App Privacy 跟踪声明 | `NSPrivacyTracking=false` | ✅(对应) |
| 23 | Export Compliance | `ITSAppUsesNonExemptEncryption=false` | 🟡 P1-1(跟 SQLCipher 矛盾) |
| 24 | App Review 信息(测试账号 / 备注) | 0 个 IAP 0 个测试账号 | ✅(0 业务无需) |
| 25 | 审核员联系邮箱 | `support@chroniccare.app`(占位) | 🔴 P0-9(邮箱未注册) |
| 26 | 版本号 (Version) | 0.27.0+64 | 🟡 P1-9(< 1.0.0, 上架前 bump 1.0.0+1) |
| 27 | Copyright © 文本 | 已填 | ✅ |
| 28 | 推送通知 (Push Notifications) | NO(代码无 APNs,R70 删 aps-environment) | ✅ |
| 29 | Sign in with Apple | NO(无第三方登录) | ✅ |
| 30 | Apple Pay | NO | ✅ |
| 31 | In-App Purchase | 0 productId 声明 | ✅(Fastfile `precheck_include_in_app_purchases: false` 同步) |
| 32 | App 内购产品列表 (IAP) | 0 个(暂停业务) | ✅ |

**🔴 阻塞 8 项**: 1, 2, 12, 13, 16, 17, 18, 19, 25
**🟡 警告 4 项**: 7, 20, 21, 23, 26
**✅ 通过 20 项**

---

## 5. 上架阻塞清单

### 🔴 P0 阻塞 (12 项)

| # | 类别 | 难度 | 位置 | 问题 | Guideline 引用 | 估时 | 谁来做 |
|---|---|---|---|---|---|---|---|
| **P0-1** | 底层 | XS | `ios/Runner.xcodeproj/project.pbxproj:378,558,581` + `fastlane/Appfile:19` | `PRODUCT_BUNDLE_IDENTIFIER=com.chroniccare.app` 跟 `app_identifier("com.chroniccare.chroniccare")` **不一致** → fastlane upload 直接拒 | **2.1 App Completeness (a)**: final version metadata 必填 | 0.5h | 工程 |
| **P0-2** | 底层 | XS | `fastlane/Appfile:21, 23, 25` | 3 个 TODO ID 占位(`your-apple-id@example.com` / `YOUR_TEAM_ID` / `YOUR_ITC_TEAM_ID`) | **2.1 + 5.6.2 Developer Identity**: 信息必 truthful + verifiable | 0.5h | 用户(需真实 Apple ID + Team ID) |
| **P0-3** | 底层 | XS | `ios/Runner/AppDelegate.swift:15-17` | UNUserNotificationCenter delegate 设置但**未实现 `userNotificationCenter(_:willPresent:withCompletionHandler:)` 方法** → foreground 通知 banner 不显示,精神心理患者吃药提醒关键场景失效 | **2.5.1 Software Requirements**: foreground 通知必须可见 | 1h | 工程 |
| **P0-4** | 底层 | XS | `ios/Runner.xcodeproj/project.pbxproj:193-196` | `knownRegions = (en, Base)` 缺 zh-Hans/zh-Hant → `ios/Runner/{zh-Hans,zh-Hant}.lproj/InfoPlist.strings` 失效,中文用户看英文名 | **2.3.7 App Names**: 30 字符 + 必 localized correctly | 0.5h | 工程 |
| **P0-5** | 底层 | M | `ios/Podfile`(不存在) + `ios/Podfile.lock`(不存在) | iOS 端缺 `Podfile` + `Podfile.lock` (`.flutter-plugins-dependencies:100` 走 CocoaPods 路径) → `bundle exec fastlane ios beta` 首次 build 失败 | **2.1 App Completeness (c)**: build 必须能跑通 | 2-4h(等 `flutter pub get` + `pod install` + 验证) | 工程 |
| **P0-6** | 底层 | L | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/{iphone_6_5,iphone_5_5,ipad_12_9}_screenshots/0[1-5]_home.png` 33 张 | **全 67 字节透明占位 PNG**(`1232×720` 不是任何 Apple 尺寸,IDAT 块仅 10 字节 ≈ 空白) → ASC 校验分辨率直接拒 | **2.3.3 Screenshots**: "should show the app in use" — 67 字节占位 not in use | 1-2 天(Simulator 截图 + 5 主页面 × 3 device × 3 locale) | 工程(需真机或 Simulator) |
| **P0-7** | 底层 | XS | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/app_icon.png` 3 张 | **67 字节占位** → 必须替换 1024×1024 不透明 PNG(Apple 强制,asc 校验) | **2.3.9 App Icons**: 1024×1024 opaque PNG | 1h(从 `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` 复制) | 工程 |
| **P0-8** | 底层 | M | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/{privacy_url,support_url}.txt` 6 文件 | 全是 `https://chroniccare.app/privacy` + `https://chroniccare.app/support` → 域名**未注册未验证** → reviewer 点 URL 404 直接拒 | **1.5 + 5.1.1 (i)**: privacy URL 必实际可达 | 0.5-1 天(注册 chroniccare.app 域名 + 部署页面 + HTTPS 证书) | 用户(法务 / 运营) |
| **P0-9** | 底层 | S | `assets/legal/user_agreement.md:60-61` | `support@chroniccare.app` 邮箱占位 + `https://github.com/example/chroniccare/issues` 仓库占位 | **1.5 Developer Information**: Support URL 必可联系 | 0.5h(注册邮箱 + 创建/确认 GitHub 仓库) | 用户 |
| **P0-10** | 底层 | L | `assets/legal/{privacy_policy,user_agreement,sensitive_data_consent}.md` 0 英文 / 0 繁体版 | 3 份 md 全中文 → en-US 走 App Store 时 consent 3 份都是中文,**Apple 1.4.3 + PIPL 知情同意语种双重 fail** | **1.4.3 + 5.1.1 (iii)**: 知情同意语种必用户语种一致 | 1-2 周(翻译 3 份 md × 2 locale) | 用户(法务 / 翻译) |
| **P0-11** | 底层 | XS | `assets/legal/privacy_policy.md:0.5` + `user_agreement.md:60-61` | 引用不存在文件 `docs/SPRINT1_LEGAL_TODO.md` + `docs/LEGACY_API_NOTES.md` → 文档不一致,ASC 透明性 fail | **5.1.1 (i) Privacy Policies**: 必"easily accessible" + 引用必真实 | 0.5h(创建占位文件 OR 删除引用) | 工程 |
| **P0-12** | 顶层 | M | 综合 (P0-1 + P0-2 + P0-6 + P0-7 + P0-8 + P0-9 + P0-10 + P0-11) | Medical 类 (1.4.1) en-US 上架时缺英文法律 + 占位邮箱 + 占位 URL + 占位截图 + bundle ID 不一致 → **Apple 审核员**看到这些会**直接打回**(medical + 占位) | **1.4.1 + 2.1 + 2.3 + 5.1.1** 多重 fail | 1-2 周(综合 7 项) | 多方协调 |

**P0 总工时**: ~15-25 工程人天 + 用户配合 1-2 周(域名 / 邮箱 / 翻译)

### 🟡 P1 警告 (7 项)

| # | 类别 | 难度 | 位置 | 问题 | 修复建议 |
|---|---|---|---|---|---|
| **P1-1** | 底层 | S | `ios/Runner/Info.plist:103-104` | `ITSAppUsesNonExemptEncryption=false` 跟 SQLCipher AES-256 + 隐私政策"字段级加密"声明矛盾 | 改 `true` + 准备 self-classification report (CCATS),或反向把 `privacy_policy.md` 措辞改"标准库 SQLCipher 加密,符合 Apple export compliance 豁免" |
| **P1-2** | 底层 | S | `ios/Runner/Info.plist:144-148` + ASC App Privacy 勾选 | `UIBackgroundModes=processing` 声明但失联通知业务整体暂停(`FeatureFlags.emergencyContactEnabled=false`) → ASC 提交时需在 App Privacy 描述加醒目声明 "Lost-contact safety net: currently disabled, capability reserved for v1.0" | 手动勾选 ASC App Privacy 对应标签,加 capability reserved 描述 |
| **P1-3** | 底层 | XS | `ios/Runner.xcodeproj/project.pbxproj:193-196` | `knownRegions` 缺 zh-Hans/zh-Hant(同 P0-4) | 已在 P0-4 列 |
| **P1-4** | 底层 | S | `lib/domain/logic/phq9.dart` + `gad7.dart` + `lib/l10n/app_en.arb` | PHQ-9 / GAD-7 32 题 + 严重度 + 危机电话**未走 ARB 全 i18n**(`FeatureFlags.phqGad7I18nEnabled=false` R65b 默认关闭) → en-US 用户看到中文量表 = 准确性受质疑(Apple 1.4.1) | 翻译量表 + 打开 FeatureFlag |
| **P1-5** | 底层 | XS | ASC App Privacy 提交勾选 | `processing` 后台模式 dormant 需 ASC 手动声明 | 同 P1-2 |
| **P1-6** | 底层 | S | `lib/presentation/pages/vent/vent_compose_page.dart` 录音 dialog | vent 录音 dialog 顶部**缺"录音时切到后台会继续录制"提示** → Apple 4.0 Background audio 建议 visible purpose 提示 | 录音 dialog 顶部加 1 行 caption |
| **P1-7** | 底层 | S | `ios/Pods/...(未生成)` | 第三方 plugin 12 个自带 PrivacyInfo **未 verify** (`pod install` 跑后 grep `<App>.app/Frameworks/*.framework/PrivacyInfo.xcprivacy`) | 跑 `pod install` + grep 校验 + 缺则修 plugin 版本 |
| **P1-8** | 底层 | M | `fastlane/metadata/ios/*/iphone_6_7_screenshots/` 不存在 | Apple 2024 起新提交要求 6.5" (1242×2688) 或 6.7" (1290×2796) 二选一;项目当前是 `1232×720` 占位,**不是任一尺寸**,需重做 | 跑 `flutter run -d "iPhone 15 Pro"` Simulator + Screenshot,存 6.5 + 6.7 两套 |
| **P1-9** | 底层 | XS | `pubspec.yaml:4` | 版本号 `0.27.0+64` < 1.0.0 → 上架前 bump `1.0.0+1`(表达"正式版",避免 Apple 4.3 Spam 自动标 pre-release) | bump 1.0.0+1 |

**P1 总工时**: ~5-8 工程人天

### 🟢 P2 建议 (3 项)

| # | 类别 | 难度 | 位置 | 问题 | 建议 |
|---|---|---|---|---|---|
| **P2-1** | 顶层 | XS | ASC App 信息 | SKU 未设(可任意字符串) | 填 `chroniccare-001` 或类似 |
| **P2-2** | 顶层 | XS | ASC App 信息 | 未设 Secondary Category | 加 Medical 二次分类(精神心理患者属 medical) |
| **P2-3** | 顶层 | XS | ASC App 信息 | 未设 Marketing URL | 填 `https://chroniccare.app` 主域名(配合 P0-8) |

**P2 总工时**: < 1h

---

## 附录: 已修项确认 (R70/R71/R72/R73 增量)

| R | 修了什么 | 现状 |
|---|---|---|
| R70 (986814a) | `Runner.entitlements` 删 aps-environment | ✅ `ios/Runner/Runner.entitlements:1-13` 已空 |
| R70 | `Info.plist` 删 NSUserNotificationUsageDescription 老 key | ✅ |
| R70 | `Info.plist` CFBundleDisplayName 改单值 + 走 InfoPlist.strings | ⚠️ 代码改对但 pbxproj knownRegions 没改(P0-4) |
| R70 | `ios/Runner/{zh-Hans,zh-Hant}.lproj/InfoPlist.strings` 新建 CFBundleDisplayName | ✅ 文件存在但 pbxproj 未注册 |
| R70 | `pbxproj` 删 3 处 EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64 | ✅ Apple Silicon Mac 兼容修复 |
| R70 | Android abiFilters 改 64-bit | ✅ (跟 iOS 端无关) |
| R70 | metadata subtitle wording 改"失联通知" → "情绪关怀" | ✅ |
| R71 (42ac12b) | `PrivacyInfo.xcprivacy` 加 CA92.2 (UserDefaults cross-app) | ✅ |
| R71 | `PrivacyInfo.xcprivacy` 加 ProcessInfo AC67.1 | ✅ |
| R71 | `Info.plist` 删 UIMainStoryboardFile | ✅ (R70 实际做的,R71 写在了 Info.plist 注释) |
| R71 | `Fastfile` 加 platform :android 块 + 3 lane | ✅ |
| R73 (98b041a) | `README_PLACEHOLDER.txt` 删除 + commit message 说"截图已就位" | ❌ **实际 33 张占位图原封未动,commit message 跟实际不符** |
| R73 (b5796ce) | CHANGELOG R73 段 + 4 commit 收尾 | ✅ |
| R74 (6e9f07e) | R65 vent i18n 漏 3 ARB key 紧急修 | ✅(但跟 iOS 上架无关) |

---

## 审计总结

**项目当前状态**:
- 代码层: 12 守护脚本全绿,1283 tests pass,0 error / 0 warning / 0 info(R73 9 analyzer info 清零后)
- iOS 端技术债: 5 P0(代码 / 工程配置)+ 4 P1(技术债)
- iOS 端上架材料: 7 P0(metadata / 法律 / 域名)+ 2 P1(metadata)+ 1 P2
- 上架就绪度: **2 / 10**(技术基本就位,材料 90% 缺)

**M1 上架前必修路径**:
1. **工程 1 天**: 修 P0-1(bundle ID 一致)+ P0-3(UNUserNotificationCenter 通知方法)+ P0-4(pbxproj knownRegions)+ P0-5(Podfile/Podfile.lock 补)+ P0-7(app_icon 复制)
2. **运营 1 天**: 修 P0-2(Appfile 3 ID 真实值)+ P0-8(chroniccare.app 域名注册 + 部署)+ P0-9(邮箱注册 + GitHub 仓库)
3. **设计 1-2 天**: 修 P0-6(33 张截图真实化)
4. **法务 1-2 周**: 修 P0-10(3 法律 md 英文版 + 繁体版)+ P0-11(删引用不存在文件)
5. **工程 0.5 天**: 修 P1-1/2/4/5/6/7/8/9(综合 P1)

**最快上架时间**: 假设用户配合 1 周内(域名 + 邮箱 + 截图 + 法务),工程 1 周内 — 2-3 周后可提交 App Store 审核,审核周期 1-3 天

**最大风险**:
1. **P0-10 法务翻译** — 1-2 周,可能因 R66 业务暂停 + 3 法律 md 协同问题更长
2. **P0-6 截图** — 需真机或 Simulator 跑 + 5 主页面 × 3 device × 3 locale = 45 张图,设计 polish 1-2 天
3. **P0-8 域名** — 域名注册 + DNS 解析 + HTTPS 证书 + 部署静态页面 = 0.5-1 天(用户层面)
4. **Podfile 漂移** — `flutter pub get` + `pod install` 在不同 master spec repo 状态可能产生不同 Podfile.lock,需锁版本 + 严格 CI 验证

**最后建议**: R74 audit 后建议立即启动 M1 上架 Sprint,优先 P0-1/2/3/4/5/7(工程 1 天可全修),P0-6/8/9(用户层面 1 周),P0-10/11(法务 1-2 周)。**总 2-3 周可提交审核**
