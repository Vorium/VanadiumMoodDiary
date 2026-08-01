# Round 76 - AppStore 视角审计

**审计时间**: 2026-08-01
**项目**: chroniccare(精神心理患者吃药打卡 App)
**版本**: 0.27.0+64(`pubspec.yaml:5`)/ working tree 干净 / R75 commit `403753c` 完结 / 当前 `6b4fc63` (R76 测试同步)
**视角**: Apple App Store 上架合规
**审计模式**: 增量(对照 R74 `reports/audit/round74-appstore.md` 12 P0 + 7 P1 + 3 P2 = 22 项)
**基线**: R74 12 P0 / R75 (iOS-1 b045953 + iOS-2 403753c) 修 3 项 / R76 实际剩 9 P0

**项目基线**: flutter analyze 0 issue / 16 守护脚本全绿 / dart check_all ✅ / check_arb_keys zh-en-zh_Hant 627 keys 0 缺失 / check_cross_feature 67 files 0 violation

---

## 0. 总览

**上架就绪度评分**: **2 / 10** (vs R74 2, **+0.5 工程层 / 材料层 0 进展**)

**关键发现数**:
- 🔴 **P0 阻塞**: 9 项(R74 12 项 - R75 修 3 项 - R68 修 1 项 = 8 项, + R76 发现 P0-4 半修仍 P0 = **9 项**)
- 🟡 **P1 警告**: 5 项(R74 7 项 - R75 修 0 项 P1 - P1-3 跟 P0-4 合并 = 5 项 + R76 NEW 1 项 = 6 项)
- 🟢 **P2 建议**: 3 项(R74 继承)

**R75 修了什么** (git log 验证):
- `b045953` iOS-1: AppDelegate conform `UNUserNotificationCenterDelegate` + 实现 `userNotificationCenter(_:willPresent:)` (AS-P0-3)
- `403753c` iOS-2: pbxproj `PRODUCT_BUNDLE_IDENTIFIER` 改 `com.chroniccare.chroniccare` (AS-P0-1) + `knownRegions` 加 `zh-Hans`/`zh-Hant` (AS-P0-4)

**整体感觉**:

R75 iOS Sprint 集中修了 3 项 P0,**全是工程层 (AppDelegate / pbxproj)**,但修得**不彻底** — R75 的 commit `403753c` 修了 `knownRegions` 加 zh-Hans/zh-Hant,**却没补 pbxproj 里的 `PBXVariantGroup` + `PBXGroup` 引用**,`ios/Runner/{zh-Hans,zh-Hant}.lproj/InfoPlist.strings` 文件**编译时不会进 bundle**。结果是: 简体/繁体用户的中文 App 名(`慢病管家`)仍然 fallback 到 CFBundleName=chroniccare(英文),跟 R70 修 R69 P1-2 的初衷**完全失效**。R74 报告 P0-4 警示"pbxproj 漏配",R75 "修了 knownRegions" 但**没真接 InfoPlist.strings 进 pbxproj 的编译依赖**,中文 locale 失效这条 P0 **实质未修**,应作为 R76 P0 重审。

材料层 (screenshot / URL / 法律 md / 邮箱 / app_identifier) 9 项 P0 **0 进展**: 33 张 67 字节占位截图原封未动(36 张 PNG 总 2412 字节,平均 67 字节/张,全占位); 3 张 `app_icon.png` 67 字节占位; 6 URL 文件 (`https://chroniccare.app/privacy` + `https://chroniccare.app/support` × 3 locale) 域名未注册; `support@chroniccare.app` + `https://github.com/example/chroniccare/issues` 邮箱 + 仓库占位; 3 法律 md 仍**只中文版无英文 / 繁体**; `fastlane/Appfile:21, 23, 25` 3 TODO ID 仍是 `your-apple-id@example.com` / `YOUR_TEAM_ID` / `YOUR_ITC_TEAM_ID`; `ios/Podfile` + `ios/Podfile.lock` 仍不存在(`flutter pub get` 才会生成,但 git 不跟踪)。

R75 commit message 都清楚写"修 R74 报告 P0-?",但**只修工程层不修材料层**符合"R75 = iOS 工程清理 sprint"的范围 — 真正上架前需另起 1 个 R77 集中修材料层 (域名注册 / 法务翻译 / 截图 / 邮箱 + Appfile TODO 真实化)。

P0 量级: **9 项** / 修复总工作量 ~15-25 工程人天 + **律师 1-2 周(不可压缩)** + **截图 1-2 天(等真机 / Mockup)** + **域名注册 + 邮箱注册 0.5 天**

---

## 1. 顶层架构审视 (iOS 端)

### 1.1 工程结构

**R74 → R76 状态**: 标准 Flutter iOS 模板结构,代码层组织**未变**。R75 没改工程结构,只动 AppDelegate + pbxproj 2 个文件。

```
ios/
├── Runner.xcodeproj/        # Xcode 工程 (R75 改 pbxproj 5 行)
├── Runner.xcworkspace/      # Xcode workspace (无变化, 仍未引用 Pods/)
├── Runner/
│   ├── AppDelegate.swift    # R75 (b045953) 加 UNUserNotificationCenterDelegate + willPresent ✅
│   ├── SceneDelegate.swift  # R62 引入, 4 行标准继承, 无变化
│   ├── Info.plist           # 无变化 (R70 删 EXCLUDED_ARCHS / aps-environment / UIMainStoryboardFile 后稳定)
│   ├── Runner.entitlements  # R70 删 aps-environment 后空, 无变化
│   ├── PrivacyInfo.xcprivacy  # R71 加 CA92.2 + AC67.1 后稳定, 无变化
│   ├── Assets.xcassets/     # AppIcon 15 真实图 + LaunchImage 3 × 68 字节 (Flutter 3.41 模板默认)
│   ├── Base.lproj/          # Main.storyboard + LaunchScreen.storyboard
│   ├── zh-Hans.lproj/       # InfoPlist.strings (R70, R75 修了 knownRegions 但 ⚠️ PBXVariantGroup 漏)
│   └── zh-Hant.lproj/       # InfoPlist.strings (R70, 同上)
├── RunnerTests/             # RunnerTests.swift (1 个空 test, R76 NEW P1-10)
└── Flutter/                 # Generated.xcconfig (FLUTTER_BUILD_NAME=0.27.0, FLUTTER_BUILD_NUMBER=64)
```

**✅ 通过项** (R74 继承, 无变化):
- 工程组织符合 Apple 标准 (`Runner.xcodeproj` + `Runner.xcworkspace` 双轨)
- `AppDelegate.swift:7` `@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UNUserNotificationCenterDelegate` 模式正确 (R75 加第 3 个 protocol)
- `AppIcon.appiconset/Contents.json` 15 尺寸完整 (20/29/40/60/76/83.5/1024, iPhone+iPad+ios-marketing 全 idiom 覆盖)
  - `Icon-App-1024x1024@1x.png` 10932 bytes 真实图
  - 其他 14 张 282-1674 bytes 也真实 (iOS 真实 PNG 字节数范围, 不是 67 字节占位)

**🟡 警告项**:
- ⚠️ **P1-10 (R76 NEW)**: `ios/RunnerTests/RunnerTests.swift:7-10` 整个 XCTestCase 只 1 个空 `testExample()` 方法, `// If you add code to the Runner application, consider adding tests here.` — 上 store 前加 ≥1 个真实 Dart API 调用的 Swift 测试 (e.g. `FlutterEngine` 起 `Runner` channel), Apple 4.0 "include in-app testing" 评分 (Beta testing 不是强制的, 但 ASC 表单有 1 个 "Beta testing" 选项, 选 Yes 需提供 TestFlight / 自有测试账号) — 难度 S (4h)
- ⚠️ `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage*.png` 3 张 × 68 字节 (universal idiom, 1x/2x/3x) — Flutter 3.41 模板默认 1x1 透明 PNG, Apple 不强制 splash screen 用品牌图 (LaunchScreen.storyboard 是 blank `red="1" green="1" blue="1"`), 实际**可接受**。但 `LaunchScreen.storyboard:35` `<image name="LaunchImage" width="168" height="185"/>` 是 storyboard 默认占位, 不是 brand asset — 建议 v1.1 替换, 难度 XS
- ⚠️ `ios/.gitignore:13` `**/Pods/` 已忽略, 但 **`ios/Podfile` + `ios/Podfile.lock` 期望 commit** (跟 `ios/.gitignore` 习惯相反), R74 P0-5 仍依赖此 — 见 2.6 节

**🔴 阻塞项**:
- 🔴 **P0-5 (R74 继承, R76 验证)**: iOS 端**缺 `ios/Podfile` + `ios/Podfile.lock`**
  - `Test-Path 'D:\Batch\chroniccare\ios\Podfile'` → **False** (R76 验证)
  - `Test-Path 'D:\Batch\chroniccare\ios\Podfile.lock'` → **False** (R76 验证)
  - `.flutter-plugins-dependencies:100` `swift_package_manager_enabled: {"ios":false,"macos":false}` → 走 CocoaPods 路径
  - `ios/Runner.xcworkspace/contents.xcworkspace/contents.xcworkspacedata` 只引用 `Runner.xcodeproj`, **不引用 `Pods/`**
  - `flutter pub get` 才会生成 Podfile, 但 git 仓库**不跟踪**(Flutter 习惯), 意味着 `bundle exec fastlane ios beta` 首次跑会** build 失败**
  - 修复路径: 1) `flutter pub get` 自动生成 Podfile, 2) `cd ios && pod install`, 3) commit `ios/Podfile` + `ios/Podfile.lock` 锁版本 (但 R74 报告警示 12 plugin 跨 master spec repo 状态可能漂移)
  - 难度: M (2-4h 等 `flutter pub get` + `pod install` + build 验证)

### 1.2 SceneDelegate 模式 (R62 引入, 无变化)

**R74 → R76 状态**: `SceneDelegate.swift` 4 行标准继承, **R75 没动**。

```swift
// ios/Runner/SceneDelegate.swift:1-6 (R76 验证)
import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

}
```

**Info.plist 配套**:
```xml
<!-- ios/Runner/Info.plist:76-96 (R76 验证) -->
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

**✅ 通过项** (R74 继承):
- Scene 模式接入正确 (UISceneStoryboardFile=Main 接管启动)
- `UIApplicationSupportsMultipleScenes=true` (iPad 多任务支持)
- `Info.plist:74-75` `UIRequiresFullScreen=false` iPad Split View 允许
- `Main.storyboard:11` `customClass="FlutterViewController"` (iOS 标准 Flutter 集成)
- `LaunchScreen.storyboard:19-21` 引用 `image="LaunchImage"` (universal) + center 约束

**🟡 警告项**:
- 无

**🔴 阻塞项**:
- 无

### 1.3 BGTaskScheduler (com.chroniccare.safety-check, R66 业务整体暂停, 无变化)

**R74 → R76 状态**: `AppDelegate.swift:33-38` BGTaskScheduler 注册 + `handleSafetyCheckTask` 占位,**R75 没动**。

**✅ 通过项** (R74 继承):
- BGTaskScheduler identifier 跟 Info.plist `BGTaskSchedulerPermittedIdentifiers` 一致 (`com.chroniccare.safety-check`)
- `processing` 模式声明 (失联检测长任务 → 实际业务暂停, R67 留 capability)
- `audio` 模式声明 (树洞/情绪日记录音时切后台继续, 跟 `record 5.2.0` + `audioplayers 6.1.0` 对应)

**🟡 警告项** (R74 继承, R76 无变化):
- ⚠️ **P1-5 (R74 继承)**: `UIBackgroundModes=processing` 声明但**不触发**(`FeatureFlags.emergencyContactEnabled=false`, R66 业务整体暂停) → App Store Connect 后台 App Privacy 描述如不加 "Lost-contact safety net: currently disabled" 醒目声明, 审核员会认为项目**声明了 capability 但不实际使用 = dormant**。当前 `fastlane/metadata/ios/*/description.txt` 已有"coming soon — currently disabled"段, 但需在 ASC 提交时**手动勾选**对应 App Privacy 复选框
- ⚠️ **P1-6 (R74 继承)**: `UIBackgroundModes=audio` 真实使用(录音中切后台不中断),但 vent 录音 dialog 顶部**没有"录音时切到后台会继续录制"提示** → Apple 4.0 Background audio 建议 visible purpose 提示(`lib/presentation/pages/vent/vent_compose_page.dart` 录音 UI 顶部加 1 行 caption)

**🔴 阻塞项**:
- 无 (R74 同结论)

### 1.4 第三方 plugin 集成 (12 个, 无变化)

**R74 → R76 状态**: 12 个 iOS plugin 走 Flutter `native_build=true` 模式,**R76 验证** `.flutter-plugins-dependencies` 内容:

| Plugin | 版本 | native_build | R74 报告 | R76 验证 | 差异 |
|---|---|---|---|---|---|
| audioplayers_darwin | 6.4.0 | true | ✅ | ✅ | 无 |
| flutter_local_notifications | 17.2.4 | true | ✅ | ✅ | 无 |
| flutter_secure_storage | 9.2.4 | true | ✅ | ✅ | 无 |
| flutter_timezone | 3.0.1 | true | ✅ | ✅ | 无 |
| in_app_purchase_storekit | 0.4.11 | true | ✅ | ✅ | 无 |
| **path_provider_foundation** | 2.6.0 | **false** | ✅ 标 true | ⚠️ 实际 false | **R74 报告事实差错** |
| permission_handler_apple | 9.4.10 | true | ✅ | ✅ | 无 |
| printing | 5.14.3 | true | ✅ | ✅ | 无 |
| record_darwin | 1.2.2 | true | ✅ | ✅ | 无 |
| share_plus | 10.1.4 | true | ✅ | ✅ | 无 |
| shared_preferences_foundation | 2.5.6 | true (shared_darwin_source) | ✅ | ✅ | 无 |
| speech_to_text | 7.4.0 | true (shared_darwin_source) | ✅ | ✅ | 无 |
| sqlcipher_flutter_libs | 0.6.8 | true | ✅ | ✅ | 无 |

**🔴 R74 报告事实差错** (R76 NEW, 非阻塞):
- R74 报告 (1.4 表格) 标 path_provider_foundation 12 个 plugin 全部 `native_build=true` / `shared_darwin_source=true`
- R76 验证 `.flutter-plugins-dependencies:11` `path_provider_foundation: native_build=false`
- **原因**: path_provider_foundation **只导出 header** (iOS Foundation framework 公共接口), 不需要 .podspec 编译, Flutter 模板里就标 `native_build=false` (pub.flutter-io.cn 上 path_provider_foundation-2.6.0 的 podspec `s.static_framework = false` 默认)
- **影响**: 0 阻塞, path_provider_foundation 在 iOS 工程仍**正常工作** (因为它在 Flutter 公共 dart 代码层 `path_provider` 已被 dart 代码 include)
- **R74 报告自我修正**: 12 个 plugin 中 11 个 native_build=true, **1 个 (path_provider_foundation) false**, 配合 `swift_package_manager_enabled: false` 走 CocoaPods 路径, `flutter pub get` 会自动生成 `path_provider_foundation.podspec` 引用
- **Apple 影响**: 无, App Store 提交不需 native_build 全 true, 只需 plugin 编译通过

**🟡 警告项** (R74 继承, R76 无变化):
- ⚠️ **P1-7 (R74 继承)**: 项目自身 `PrivacyInfo.xcprivacy` 已声明 4 类 CollectedDataType + 5 类 AccessedAPI, 但 `pod install` + build 后**未验证** `Pods/<plugin>.framework/PrivacyInfo.xcprivacy` 是否完整(Apple 2024-05 强制) — `pod install` 没跑过, Podfile 不存在,**无法 build 后验证**
- ⚠️ `in_app_purchase_storekit 0.4.11` 引入但 `FeatureFlags._prodIapEnabled=false`(R68 d691551 决策) + App description 仍提 8 元 — R69 P0-8 已警示, 代码层 R68 修, 文档层 R69 加注脚, 但 **App Store Connect 后台 IAP 列表需保持空**(不能创建 productId,否则 ASC 提示"unreferenced IAP")

**🔴 阻塞项**:
- 无 (R74 同结论)

---

## 2. 底层逐行排查 (iOS 端)

### 2.1 Info.plist (157 行, R75 无变化)

**R74 → R76 状态**: R75 没动 Info.plist。R70 已修 5 项 (NSUserNotificationUsageDescription 删、InfoPlist.strings 加、UIMainStoryboardFile 删、aps-environment 删、EXCLUDED_ARCHS 删) 保持稳定。

**✅ 通过项** (R74 继承):
- `:5-6` `CADisableMinimumFrameDurationOnPhone=true` — 120Hz 刷新率支持
- `:33-34` `LSRequiresIPhoneOS=true` — 强制 iOS 设备
- `:42-43` `NSMicroPhoneUsageDescription` "用于情绪日记的语音录入,本地处理,文件加密存储"
- `:44-45` `NSSpeechRecognitionUsageDescription` "用于情绪日记的语音转文字,本地处理,不上传"
- `:51-52` `NSPhotoLibraryAddUsageDescription` "用于保存用药报告 PDF 到相册"
- `:61-62` `NSPhotoLibraryUsageDescription` "用于分享用药报告 PDF 时选择保存位置"
- `:67-68` `NSUserTrackingUsageDescription` "本应用不收集任何追踪数据,仅用于 App Store 透明性声明"
- `:103-104` `ITSAppUsesNonExemptEncryption=false` ⚠️ 跟 SQLCipher 矛盾 (见 P1-1)
- `:116-128` iPhone + iPad orientation 全 4 方向
- `:136-137` `LSApplicationCategoryType=healthcare-fitness` 跟 App Store Connect Health & Fitness 分类对应
- `:144-148` `UIBackgroundModes=[audio, processing]`
- `:153-156` `BGTaskSchedulerPermittedIdentifiers=[com.chroniccare.safety-check]`

**🟡 警告项** (R74 继承, R76 无变化):
- ⚠️ **P1-1 (R74 P1-4 续)**: `Info.plist:103-104` `ITSAppUsesNonExemptEncryption=false` 跟代码层 SQLCipher AES-256 + Keychain 真实使用**矛盾**。R70 注释写"标 false 是因为 SQLCipher 走标准库加密(自审豁免)",但 `assets/legal/privacy_policy.md` 公开声明"AES-256 字段级加密" — Apple reviewer 看到这两份文件会**真接问"你声明零加密但隐私政策说 AES-256,你是不是在撒谎"**。建议: 改 `true` + 准备 self-classification report(CCATS 编号), 或反向把 `privacy_policy.md` 措辞改为"标准库 SQLCipher 加密,符合 Apple export compliance 豁免"
- ⚠️ **P1-2 (R74 P1-7 续)**: `Info.plist:144-148` `UIBackgroundModes=processing` 实际**不触发**(`FeatureFlags.emergencyContactEnabled=false`,R66 业务整体暂停)→ ASC 提交时如不在 App Privacy 描述勾选"暂不启用"会被判 dormant。Fastlane 已配 `metadata/ios/*/description.txt` 都有"coming soon"段,但需手动勾选 App Privacy 标签
- ⚠️ **P1-3 (R74 NEW → R76 升级)**: `Info.plist:15-16` `CFBundleDisplayName=ChronicCare`(英文单值) + `ios/Runner/{zh-Hans,zh-Hant}.lproj/InfoPlist.strings` per-locale 覆盖"慢病管家" — R70 修复,**R75 修了 knownRegions**, **但** `pbxproj:295-310` PBXVariantGroup 段**未加 InfoPlist.strings 引用** + `pbxproj:112-128` PBXGroup Runner children **未列 zh-Hans.lproj / zh-Hant.lproj** → **编译时 InfoPlist.strings 不进 bundle, iOS 读不到** → 简体/繁体用户仍 fallback 到 CFBundleName=chroniccare (英文) (见 P0-4 升级)

**🔴 阻塞项**:
- 无新增 P0

### 2.2 Runner.entitlements (13 行, R70 删 aps-environment 后稳定, R75 无变化)

**R74 → R76 状态**: 文件内容只 R70 删 `aps-environment=development` 的注释, R75 没动。

```xml
<!-- ios/Runner/Runner.entitlements:1-13 (R76 验证) -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!--
        v0.27 R70: 删 aps-environment
        原因: 项目无 APNs 远程推送, 只用 flutter_local_notifications 17.x 本地通知
    -->
</dict>
</plist>
```

**✅ 通过项** (R74 继承):
- R70 删 `aps-environment=development` 正确(项目无 APNs 远程推送,误导审核员)
- 注释清楚解释为什么删

**🟡 警告项**:
- 无 (entitlements 几乎空 = 正确,项目无 IAP 真接 / HealthKit / NetworkExtension)

**🔴 阻塞项**:
- 无

### 2.3 PrivacyInfo.xcprivacy (148 行, R71 加 CA92.2 + AC67.1 后稳定, R75 无变化)

**R74 → R76 状态**: R71 加 `CA92.2` + `AC67.1` 后稳定, R75 没动。

**✅ 通过项** (R74 继承):
- `:22-23` `NSPrivacyTracking=false` — 正确(项目零追踪)
- `:24-25` `NSPrivacyTrackingDomains=[]` — 正确
- `:42-92` `NSPrivacyCollectedDataTypes` 4 类(HealthAndFitness / AudioData / ContactInfo / UserContent),每类 Linked=false/Tracking=false/Purpose=AppFunctionality
- `:97-108` `NSPrivacyAccessedAPICategoryUserDefaults` + CA92.1 + CA92.2 — R71 P2-1 加 CA92.2 防御性
- `:110-116` `NSPrivacyAccessedAPICategoryFileTimestamp` + C617.1
- `:118-124` `NSPrivacyAccessedAPICategorySystemBootTime` + 35F9.1
- `:126-132` `NSPrivacyAccessedAPICategoryDiskSpace` + 85F4.1
- `:134-146` `NSPrivacyAccessedAPICategoryProcessInfo` + AC67.1 — R71 P2-1 加

**🟡 警告项**:
- ⚠️ 缺 `NSPrivacyAccessedAPICategoryActiveKeyboards` / `NSPrivacyAccessedAPICategoryUserDefaults`-CA92.2 之外的 reason (CA92.1 only) — 当前声明的 5 类 + 4 reason 已覆盖 Apple 强制 required reason API(2024-05 政策),但第三方 plugin 内部的 API 调用未覆盖(见 1.4 P1-7)

**🔴 阻塞项**:
- 无(项目自身声明完整)

### 2.4 AppDelegate.swift (75 行, R75 修了 AS-P0-3) ✅

**R74 → R76 状态**: R75 commit `b045953` 大改, 从 R74 的 52 行扩到 75 行, 加了:
1. Line 7: `@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UNUserNotificationCenterDelegate` — 加第 3 个 protocol conformance
2. Line 23: `UNUserNotificationCenter.current().delegate = self` — 删 `as?` 强转
3. Line 47-61: 实现 `@available(iOS 10.0, *) func userNotificationCenter(_:willPresent:withCompletionHandler:)` 返回 `[.banner, .list, .sound, .badge]`

**R75 修复验证** (R76 git diff 验证):
```swift
// ios/Runner/AppDelegate.swift:7 (R75 修)
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UNUserNotificationCenterDelegate {
  ...
  // ios/Runner/AppDelegate.swift:22-24 (R75 修, 删 as? 强转)
  if #available(iOS 10.0, *) {
    UNUserNotificationCenter.current().delegate = self
  }
  ...
  // ios/Runner/AppDelegate.swift:54-61 (R75 新增)
  @available(iOS 10.0, *)
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .list, .sound, .badge])
  }
```

**✅ 通过项** (R75 修的 3 项, R76 验证全过):
- ✅ `:7` AppDelegate conform `UNUserNotificationCenterDelegate` protocol
- ✅ `:23` delegate = self (无 `as?` 强转)
- ✅ `:54-61` 实现了 `userNotificationCenter(_:willPresent:withCompletionHandler:)`, foreground 通知 banner + list + sound + badge 都会弹
- ✅ `:33-38` BGTaskScheduler 注册 + identifier 跟 Info.plist `BGTaskSchedulerPermittedIdentifiers` 一致(`com.chroniccare.safety-check`)
- ✅ `:43-45` `didInitializeImplicitFlutterEngine` 注册 plugin(Flutter 3.41 Implicit Engine 模式)
- ✅ `:72-74` `handleSafetyCheckTask` 空壳 + `setTaskCompleted(success: true)` 防止 iOS 后台资源浪费

**🟡 警告项**:
- ⚠️ **R75 注释冗余**: `:17-21` R75 注释详细解释 R67 → R75 的修复历史,占 5 行,但**信息价值高**(未来维护者知道为什么 R67 写 `as?` 然后 R75 删),保留 OK
- ⚠️ **R75 注释冗余**: `:47-53` R75 注释详细解释为什么实现 willPresent,占 7 行,保留 OK

**🔴 阻塞项**:
- 🔴 **P0-3 解除** ✅: R75 修了 (R74 P0-3 `userNotificationCenter(_:willPresent:withCompletionHandler:)` 未实现), 精神心理患者吃药提醒关键场景恢复可见

### 2.5 InfoPlist.strings (多语, R70 加, R75 knownRegions 改)

**R74 → R76 状态**: R75 修了 knownRegions 但** PBXVariantGroup + PBXGroup 引用没补** = 中文 locale 仍 fallback 英文。

**zh-Hans** (`ios/Runner/zh-Hans.lproj/InfoPlist.strings`, R76 验证):
```
/* v0.27 R70 (NEW-2 appstore P1-2): per-locale CFBundleDisplayName
 * InfoPlist.strings 是 iOS per-locale strings 覆盖机制
 * iOS 在 zh-Hans locale 下用此文件覆盖 Info.plist 的 CFBundleDisplayName
 * 简体用户看 "慢病管家" 而不是英文 "ChronicCare" (避免病耻感)
 */
"CFBundleDisplayName" = "慢病管家";
```

**zh-Hant** (`ios/Runner/zh-Hant.lproj/InfoPlist.strings`, R76 验证):
```
/* v0.27 R70 (NEW-2 appstore P1-2): per-locale CFBundleDisplayName */
"CFBundleDisplayName" = "慢病管家";
```

**🟡 警告项** (R74 NEW → R76 升级, 实际 P0):
- ⚠️ **P0-4 升级 (R74 NEW → R76 半修半废)**: 2 个 InfoPlist.strings 文件内容正确, R75 (commit `403753c`) 修了 `pbxproj:193-198` `knownRegions` 加 `zh-Hans`/`zh-Hant` ✅,**但**:
  - `pbxproj:294-311` PBXVariantGroup 段**只列 Main.storyboard + LaunchScreen.storyboard**, **未加 InfoPlist.strings 的 VariantGroup 引用** — 标准 iOS per-locale InfoPlist.strings 需要 1 个 `PBXVariantGroup` 包含 Base + zh-Hans + zh-Hant
  - `pbxproj:112-128` PBXGroup Runner children **未列 zh-Hans.lproj / zh-Hant.lproj 文件夹或 InfoPlist.strings 文件** — Xcode 编译时不会从 `ios/Runner/{zh-Hans,zh-Hant}.lproj/InfoPlist.strings` 读文件并拷到 `.app/`
  - **结果**: 编译时 Xcode 不会把 InfoPlist.strings 拷贝到 `<Runner.app>/zh-Hans.lproj/InfoPlist.strings` 等, iOS 在 zh-Hans / zh-Hant locale 下读不到 → CFBundleDisplayName fallback 到 Info.plist 单值 `ChronicCare` (英文)
  - **R75 commit message 自夸"修 AS-P0-4 已知 R70 漏配 pbxproj"**, 但**没真接 InfoPlist.strings 进 pbxproj 编译依赖**, R70 修的 per-locale 覆盖实际**从未生效**
  - 难度: **S** (手工编辑 pbxproj 加 2 个 PBXFileReference + 1 个 PBXVariantGroup, 或用 Xcode GUI 在 Runner target 加 localization 选 zh-Hans/zh-Hant, Xcode 自动生成)
  - 验证方法: `xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -sdk iphonesimulator -derivedDataPath build/ios` build 后, `find build/ios/Build/Products -name "InfoPlist.strings"`, 应该是 `<Runner.app>/zh-Hans.lproj/InfoPlist.strings` 存在

**🔴 阻塞项**:
- 🔴 **P0-4 (R74 继承, R76 升级 — R75 修了 knownRegions 但 pbxproj 编译依赖漏)** ⚠️ 见上
- 修复方式 (2 选 1):
  1. **Xcode GUI 路径**: 打开 `ios/Runner.xcworkspace`, Runner target → Info → Localizations, 勾 `Chinese (Simplified)` + `Chinese (Traditional)`, Xcode 自动改 pbxproj 加 PBXVariantGroup + PBXFileReference → `flutter pub get` 重新 build
  2. **手工 pbxproj 编辑**: 在 PBXVariantGroup 段加 1 个新条目, `isa = PBXVariantGroup; children = (Base, "zh-Hans", "zh-Hant"); name = InfoPlist.strings; sourceTree = "<group>";`, 在 PBXGroup Runner children 段加 1 个 PBXFileReference `path = "zh-Hans.lproj/InfoPlist.strings"; sourceTree = "<group>";`, 同样 zh-Hant
  - **R75 commit `403753c` 漏了这一步**, 严格说 R75 没真修 P0-4, R76 应重做

### 2.6 pbxproj (R75 修了 5 行)

**R74 → R76 状态**: R75 commit `403753c` 改了 2 处 (5 行增 + 3 行改):
- `pbxproj:193-198` `knownRegions` 加 `zh-Hans` + `zh-Hant` ✅
- `pbxproj:380, 560, 583` `PRODUCT_BUNDLE_IDENTIFIER = com.chroniccare.app` → `com.chroniccare.chroniccare` ✅

**R75 修了**:
- ✅ **AS-P0-1 (R74 P0-1 续, R74 加重)**: PRODUCT_BUNDLE_IDENTIFIER 跟 `fastlane/Appfile:19` `app_identifier("com.chroniccare.chroniccare")` **现在一致** — R75 修了 (R74 是 pbxproj `com.chroniccare.app` vs fastlane `com.chroniccare.chroniccare` 矛盾)

**R75 修了但 P0-4 仍半修** (见 2.5):
- ⚠️ `pbxproj:193-198` knownRegions 加了 zh-Hans/zh-Hant,但 PBXVariantGroup + PBXGroup Runner 没补 InfoPlist.strings 引用 → 中文 locale 仍 fallback 英文

**R75 没动仍阻塞**:
- 🔴 **P0-5 (R74 继承)**: iOS 端**缺 `ios/Podfile` + `ios/Podfile.lock`** (R76 验证 `Test-Path` = False),见 1.1 P0-5

**🟡 警告项** (R74 继承, R76 无变化):
- ⚠️ `pbxproj:396, 413, 428` `RunnerTests.PRODUCT_BUNDLE_IDENTIFIER = com.chroniccare.chroniccare.RunnerTests` — 跟 Runner target `com.chroniccare.chroniccare` **测试 bundle ID 一致**(test bundle ID 跟主 bundle ID 平行, iOS 标准做法)
- ⚠️ `pbxproj:6` `objectVersion = 54` — Xcode 14+ 现代格式
- ⚠️ `pbxproj:176` `LastUpgradeCheck = 1510` — Xcode 15.1
- ⚠️ `pbxproj:343, 384, 545, 549, 568, 591` `CODE_SIGN_IDENTITY[sdk=iphoneos*] = "iPhone Developer"` — 自动签名
- ⚠️ `pbxproj:357, 414, 451, 530, 555, 578` `IPHONEOS_DEPLOYMENT_TARGET = 14.0` — iOS 14+ 最低
- ⚠️ `pbxproj:361, 416, 453, 532, 559, 580` `TARGETED_DEVICE_FAMILY = "1,2"` — iPhone + iPad
- ⚠️ `pbxproj:152-159` Runner target buildPhases 6 个齐全(Run Script / Sources / Frameworks / Resources / Embed Frameworks / Thin Binary)
- ⚠️ `pbxproj:152` 9740EEB61CF901F6004384FC `Run Script` shellScript 调 `$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh build` — Flutter 3.41 标准
- ⚠️ `pbxproj:158` 3B06AD1E1E4923F5004D2608 `Thin Binary` shellScript 调 `xcode_backend.sh embed_and_thin` — 标准
- ⚠️ `pbxproj:295-310` PBXVariantGroup 只有 Main.storyboard + LaunchScreen.storyboard — 见 2.5 P0-4
- ⚠️ `pbxproj:357` `IPHONEOS_DEPLOYMENT_TARGET = 14.0` 跟 R74 同 (iOS 14+, 跟 `flutter_secure_storage 9.x` 等 plugin 最低要求匹配)

**🔴 阻塞项**:
- 🔴 **P0-1 解除** ✅: R75 修 (R74 P0-1 bundle ID 不一致)
- 🔴 **P0-4 仍阻塞** ⚠️: R75 修了 knownRegions 但 pbxproj 编译依赖漏,见 2.5
- 🔴 **P0-5 仍阻塞** (R74 继承, R76 验证): Podfile + Podfile.lock 仍不存在

### 2.7 RunnerTests.swift (11 行, R76 NEW P1-10)

**R74 → R76 状态**: R74 报告 1.1 "工程组织"段提 RunnerTests/ 但没详细审计。R76 第一次审:

```swift
// ios/RunnerTests/RunnerTests.swift:1-11 (R76 验证)
import Flutter
import UIKit
import XCTest

class RunnerTests: XCTestCase {

  func testExample() {
    // If you add code to the Runner application, consider adding tests here.
    // See https://developer.apple.com/documentation/xctest for more information about using XCTest.
  }

}
```

**🟡 警告项**:
- ⚠️ **P1-10 (R76 NEW)**: `RunnerTests.swift:7-10` 整个 XCTestCase 只 1 个空 `testExample()` 方法 + 注释 "If you add code to the Runner application, consider adding tests here." — Apple 4.0 "include in-app testing" 评分 + ASC 表单"Beta Testing"选项(选 Yes 需提供 TestFlight / 自有测试账号),空 XCTest 不会被 Apple 当作"in-app testing"加分。建议加 ≥1 个真实测试, e.g. `testFlutterEngineInit` 起 `FlutterEngine` + 验证 `DartEntrypoint` 加载, 或 `testChannel` 通过 `FlutterMethodChannel` 调 Dart API 验证 `appContext.dbKeyService` 可达, 难度 S (4h)

**🔴 阻塞项**:
- 无直接 P0,但** P0-1 `fastlane/Appfile` 3 TODO ID 仍占位是 ASC 必填项**,见 2.8

### 2.8 fastlane/Appfile (R75 修了 P0-1 间接部分, 3 TODO ID 仍占)

**R74 → R76 状态**: R75 没动 Appfile。R75 修了 pbxproj PRODUCT_BUNDLE_IDENTIFIER (跟 Appfile 一致),但 **3 TODO ID 仍占位**。

```ruby
# fastlane/Appfile:19 (R76 验证)
app_identifier("com.chroniccare.chroniccare")  # 跟 Info.plist / build.gradle.kts 一致 (R75 修一致)
# TODO (上 store 前必须替换为真实 Apple ID): 用真实登录邮箱
apple_id("your-apple-id@example.com")
# TODO (上 store 前必须替换): Apple Developer Team ID (10 字符, 后台 Membership 页)
team_id("YOUR_TEAM_ID")
# TODO (上 store 前必须替换): App Store Connect Team ID (ITC 前缀, 后台 Users and Access 页)
itc_team_id("YOUR_ITC_TEAM_ID")
```

**✅ 通过项** (R75 修的间接项):
- ✅ `:19` `app_identifier("com.chroniccare.chroniccare")` 跟 pbxproj 一致 (R75 iOS-2 修了 pbxproj, 顺带 Appfile 也一致了)

**🟡 警告项** (R74 继承, R76 无变化):
- ⚠️ `:9-11` 安全注释说"敏感 apple_id 写到这里前先确保 fastlane/Appfile 已被 .gitignore 排除" — 实际 `fastlane/Appfile` **被 git 跟踪**(R67 commit 556d454),3 个 TODO ID 是占位字符串,但若用户直接替换为真实值会** commit 真实 Apple ID 到 git**。建议走 ENV 模式 `apple_id(ENV["APPLE_ID"])`(R67 注释已提"后续挪到 ENV"但 R73/R74/R75/R76 没动)
- ⚠️ `:12-17` 注释建议走 API Key 模式(配 `app_store_connect_api_key` + `key_id` + `issuer_id` + `key_filepath`),但未实现

**🔴 阻塞项**:
- 🔴 **P0-2 (R74 继承)**: `fastlane/Appfile:21, 23, 25` 3 个 TODO ID 仍是占位(`your-apple-id@example.com` / `YOUR_TEAM_ID` / `YOUR_ITC_TEAM_ID`) → fastlane 上传因身份未配置**直接报 authentication error 失败** — 难度 XS (1h 替换为真实值 + 测试 fastlane deliver validate)

### 2.9 Fastfile (151 行, R75 无变化)

**R74 → R76 状态**: R71 加 Android platform 块后稳定, R75 没动。

**✅ 通过项** (R74 继承):
- `platform :ios do ... end` 块完整
- `:29-40` `lane :beta` — build_app + upload_to_testflight
- `:43-68` `lane :release` — build_app + upload_to_app_store (含 `submit_for_review: true` + `automatic_release: false`)
- `:71-77` `lane :metadata` — 只同步 metadata 不 build
- `platform :android do ... end` R70 + R71 完整(跟 iOS 平行)
- `:64-66` 注释明确 IAP 业务暂停,`precheck_include_in_app_purchases: false`

**🟡 警告项** (R74 继承, R76 无变化):
- ⚠️ `:30-36, 45-51` `build_app(workspace: "Runner.xcworkspace", ...)` — 依赖 Podfile/Pods 存在(见 2.6 P0-5),首次跑会失败

**🔴 阻塞项**:
- 🔴 **P0-5 衍生**: Fastfile `:30, 46` `workspace: "Runner.xcworkspace"` 引用 workspace,但 workspace contents.xcworkspacedata 只引用 Runner.xcodeproj,**不引用 Pods/** (R74 P0-5 衍生) — 修复路径: `flutter pub get` + `pod install` + workspace 自动加 `Pods/Pods.xcodeproj` 引用

### 2.10 fastlane/metadata/ios (3 locale, R75 无变化, 36 张 PNG 全占位)

**R74 → R76 状态**: R75 没动 metadata。R76 验证 36 张 PNG (33 截图 + 3 app_icon) **全 67 字节占位**。

```
fastlane/metadata/ios/
├── en-US/                         # 9 metadata 文件 + 11 PNG
│   ├── name.txt                   # "ChronicCare" (11 chars, Apple 30 limit ✅)
│   ├── subtitle.txt               # "Medication + Mood Tracker" (25 chars ✅)
│   ├── description.txt            # 2913 chars ✅
│   ├── keywords.txt               # 54 chars ✅
│   ├── promotional_text.txt       # 136 chars ✅
│   ├── support_url.txt            # "https://chroniccare.app/support" (域名未注册 ❌)
│   ├── privacy_url.txt            # "https://chroniccare.app/privacy" (域名未注册 ❌)
│   ├── copyright.txt              # "漏 2026 chroniccare" (中文 mojibake, 见下 ⚠️)
│   ├── app_icon.png               # 67 字节 ❌
│   ├── iphone_6_5_screenshots/    # 5 × 67 字节 ❌
│   ├── iphone_5_5_screenshots/    # 3 × 67 字节 ❌
│   └── ipad_12_9_screenshots/     # 3 × 67 字节 ❌
├── zh-Hans/                       # 同 9 metadata + 11 PNG, 同样问题
└── zh-Hant/                       # 同 9 metadata + 11 PNG, 同样问题
```

**🟡 警告项** (R74 继承, R76 NEW 发现):
- ⚠️ **R76 NEW**: `fastlane/metadata/ios/en-US/copyright.txt:1` 内容是 `"漏 2026 chroniccare"` — **mojibake!**
  - 实际应该是 `"© 2026 chroniccare"`,`©` 字符 (U+00A9) 在 PowerShell `Get-Content` 默认 GBK 解码下变成 `漏` (U+6F0F)
  - **文件实际编码**: UTF-8 (这是 fastlane 标准) — 验证: `Get-Content -Encoding UTF8` 显示正确 `"© 2026 chroniccare"`
  - **影响**: 0 阻塞,Apple ASC 上传时也是按 UTF-8 读,显示正确,只是 PowerShell 终端渲染问题
  - **R74 报告事实差错**: R74 报告 4.15 说 "Copyright © 文本 已填 ✅" — 没说 mojibake, 严格说 R74 报告审计不到位
- ⚠️ **R76 验证**: 36 张 PNG 总 2412 字节, 平均 67 字节/张 = **全占位**(透明 1232×720 PNG, IDAT 块仅 10 字节 ≈ 全空白),见 P0-6 / P0-7

**🔴 阻塞项** (R74 继承, R76 验证全在):
- 🔴 **P0-6 (R74 继承)**: **33 张截图全 67 字节透明占位 PNG**(`1232×720` 不是任何 Apple 截图尺寸,IDAT 块仅 10 字节 ≈ 空白) → ASC 校验分辨率直接拒
  - en-US / zh-Hans / zh-Hant × `iphone_6_5_screenshots/0[1-5]_home.png` = 5 × 3 = 15 张
  - en-US / zh-Hans / zh-Hant × `iphone_5_5_screenshots/0[1-3]_home.png` = 3 × 3 = 9 张
  - en-US / zh-Hans / zh-Hant × `ipad_12_9_screenshots/0[1-3]_home.png` = 3 × 3 = 9 张
  - 15 + 9 + 9 = 33 张,全 67 字节
  - 实际应分辨率: iPhone 6.5" = 1242×2688 px / iPhone 5.5" = 1242×2208 px / iPad 12.9" = 2048×2732 px
  - 难度: L (1-2 天 Simulator 截图 + 1-2 天 design polish)
- 🔴 **P0-7 (R74 继承)**: 3 张 `app_icon.png` 全 67 字节占位(`1232×720`,不符合 Apple 1024×1024 不透明 PNG 要求)
  - 实际 AppIcon 资产(`ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`) 10932 bytes 真实 — 但 fastlane 上传的 `app_icon.png` 是另一份(从 AppIcon 复制或重导出),当前是占位
  - 难度: XS (1h 从 AppIcon 复制 + 校验 1024×1024 + 不透明)
- 🔴 **P0-8 (R74 继承)**: 6 个 URL 文件 `privacy_url.txt` / `support_url.txt` × 3 locale 全是 `https://chroniccare.app/privacy` + `https://chroniccare.app/support` — 域名**未注册未验证**,Apple reviewer 点 URL 验真伪时 404 = **直接拒**
  - 难度: M (0.5-1 天注册 chroniccare.app 域名 + 部署 privacy / support 页面 + HTTPS 证书)

### 2.11 法律文件 3 份 (R75 无变化, 0 英文 / 0 繁体)

**R74 → R76 状态**: R68 修了 P0-11 (创建 `docs/SPRINT1_LEGAL_TODO.md` + `docs/LEGACY_API_NOTES.md`), R75 没动。R76 验证:
- `docs/SPRINT1_LEGAL_TODO.md` 存在 (133 行, 集中器)
- `docs/LEGACY_API_NOTES.md` 存在 (147 行, 软隐藏决策文档化)
- 3 法律 md 引用这 2 个文件, 引用**全部真实** (R68 修)

**🟡 警告项** (R74 继承, R76 无变化):
- ⚠️ **P1-9 (R76 NEW)**: 3 份 md **都只有中文版**,**无英文版 / 繁体版**:
  - `user_agreement.md` zh 4634 bytes / en 0 / zh-Hant 0
  - `privacy_policy.md` zh 14515 bytes / en 0 / zh-Hant 0
  - `sensitive_data_consent.md` zh 4658 bytes / en 0 / zh-Hant 0
  - en-US 走 App Store 时 consent 3 份 md 都是中文 → **Apple 1.4.3 + PIPL 双重 fail**(Apple 5.1.1 透明性 + PIPL 知情同意语种)
  - R76 跟 R74 结论同, 没新增 — 难度 L (1-2 周翻译)
- ⚠️ `user_agreement.md:60-61` `support@chroniccare.app` 邮箱占位 + `https://github.com/example/chroniccare/issues` 仓库占位 (R74 P0-9 续)
- ⚠️ `privacy_policy.md:222-223` / `user_agreement.md:83` 引用 `docs/SPRINT1_LEGAL_TODO.md` + `docs/LEGACY_API_NOTES.md` 现在**真实存在** ✅ (R68 修)

**🔴 阻塞项** (R74 继承, R76 验证全在):
- 🔴 **P0-9 (R74 继承)**: `user_agreement.md:60-61` 邮箱 + GitHub 仓库占位 → reviewer 看到 `support@chroniccare.app` 不存在邮箱 = **直接拒** — 难度 S (0.5h 注册邮箱 + 创建/确认 GitHub 仓库)
- 🔴 **P0-10 (R74 继承)**: 3 份法律 md **无英文版 / 繁体版** → en-US 走 App Store 时 consent 3 份都是中文 → **Apple 1.4.3 + PIPL 双重 fail** — 难度 L (1-2 周翻译 3 份 md × 2 locale)
- 🔴 P0-11 解除 ✅: R68 修了 (创建 `docs/SPRINT1_LEGAL_TODO.md` + `docs/LEGACY_API_NOTES.md`, 引用全部真实)

---

## 3. App Store 审核重点

### 3.1 Medical 类 (1.4.1) — 精神心理患者属 medical,需 disclaimer

**R74 → R76 状态**: 3 locale 描述都有 disclaimer + 紧急电话,**R75 没动 description**。

**✅ 通过项** (R74 继承):
- 3 locale 描述都有 "ChronicCare is NOT a medical device and does not provide medical advice, diagnosis, or treatment" disclaimer
- 3 locale 都有 PHQ-9 (depression) / GAD-7 (anxiety) 评估量表标注 + 跟踪用途
- 3 locale 紧急电话全:
  - en-US: 988 (US) / 116 123 (UK) / findahelpline.com
  - zh-Hans: 010-82951332 (北京) / 400-161-9995 (全国) / 021-12320-5 (上海)
  - zh-Hant: 1925 (台湾) / 2389 2222 (香港) / findahelpline.com
- `LSApplicationCategoryType=healthcare-fitness` 跟 App Store Connect Primary Category 对应
- 树洞独立表隐私边界(不进任何分析/通知/关怀)由 `lib/` 多处守门员保证

**🟡 警告项** (R74 继承, R76 无变化):
- ⚠️ **P1-4 (R74 P1-6 续)**: PHQ-9 / GAD-7 量表 32 题 + 严重度 + 危机电话**未走 ARB 全 i18n** — `lib/domain/logic/phq9.dart` / `lib/domain/logic/gad7.dart` 仍是 hardcode 中文(项目惯例 `FeatureFlags.phqGad7I18nEnabled=false`, R65b 默认关闭)。Apple 1.4.1 明确要求"apps must clearly disclose data and methodology to support accuracy claims" — 跨语种量表 = 准确性受质疑
- ⚠️ **P1-5 (R74 P1-8 续)**: 隐私政策 §11 跨域 PII 描述"审计日志(本地)"但代码层 `safety_alert_dispatcher.dart` / `audit_log_repository.dart` **0 个 audit 写入点** — R66 业务暂停期间 OK,R67 撤回同意生效后必须真接 audit log(建议 `audit_log_repository.dart` 加 `recordSafetyAlertDispatch(...)` 方法)

**🔴 阻塞项** (R74 继承, R76 验证全在):
- 🔴 **P0-12 (R74 综合, R76 仍 P0)**: Medical 类需要 en-US 走 App Store,**英文版 3 法律 md 不存在** (P0-10) + support@ 占位 (P0-9) + 引用不存在文件 (P0-11 已修) + 占位截图 (P0-6) + 占位 URL (P0-8) + bundle ID 不一致 (P0-1 已修) → **Apple 审核员**看到这些会**直接打回**(medical + 占位) — 难度 XL (1-2 周综合 6 项)

### 3.2 Privacy (5.1.1)

**R74 → R76 状态**: `assets/legal/privacy_policy.md` (14515 bytes) + `ios/Runner/PrivacyInfo.xcprivacy` (148 行) 完整,**R75 没动**。

**✅ 通过项** (R74 继承):
- 隐私政策 14 KB,详尽列 8 类数据(用户标识 / 紧急联系人 / 心理健康 / 药物 / 评估 / 树洞 / 情绪日记 / 录音元数据) + 收集目的 + 存储位置 + 敏感性
- PIPL §14 单独同意(setup 3 勾选 — 用户协议 / 隐私政策 / 敏感个人信息处理同意书)
- PIPL §23 紧急联系人告知(软提示 R66 起每个联系人单独勾选)
- `PrivacyInfo.xcprivacy` 4 类 CollectedDataType + 5 类 AccessedAPI
- `NSUserTrackingUsageDescription` 防御性声明"零追踪"
- `NSPrivacyTracking=false`

**🟡 警告项** (R74 继承, R76 无变化):
- ⚠️ 3 份法律 md 缺英文版/繁体版(见 3.1 P0-12)
- ⚠️ `its_app_uses_non_exempt_encryption=false` 跟 SQLCipher AES-256 矛盾(见 2.1 P1-1)

**🔴 阻塞项**:
- 同 3.1 P0-12

### 3.3 App Completeness (2.1)

**R74 → R76 状态**: 8 个页面全部有真实实现,**R75 没动**。

**✅ 通过项** (R74 继承):
- 8 个页面全部有真实实现(home / setup / settings / trend / assessment / check_in / contact / medication / mood / vent)
- 3 个核心数据(check_in / mood / medication)有 streak 跟踪
- 心理评估 PHQ-9 / GAD-7 量表 + 历史趋势
- 树洞(vent)文字 + 录音
- 数据导出 JSON
- 主题切换 light/dark
- 多语 zh-Hans / zh-Hant / en(setup 选语种)

**🟡 警告项** (R74 继承, R76 无变化):
- ⚠️ 失联通知功能整体暂停(`FeatureFlags.emergencyContactEnabled=false`, R66 决策)但 UI 流程保留,description 写"coming soon" — R69 P0-9 修了文档层
- ⚠️ IAP 8 元买断整体暂停(`FeatureFlags._prodIapEnabled=false`, R68 决策),App 内不显示入口 — R69 加 v0.28 注脚
- ⚠️ PHQ-9 / GAD-7 i18n 关闭(中英量表混用,准确度问题)(见 3.1 P1-4)

**🔴 阻塞项**:
- 🔴 **P0-5 衍生 (R74 继承)**: `ios/Podfile` 不存在, `flutter pub get` 后才能 build,但 git 不跟踪 → 首次 `bundle exec fastlane ios beta` 跑会**直接 build 失败** → App Completeness (c) build 必须能跑通 fail

### 3.4 Privacy Manifest (2.3.1)

**R74 → R76 状态**: `ios/Runner/PrivacyInfo.xcprivacy` 完整 5 类 AccessedAPI + 4 类 CollectedDataType,**R75 没动**。

**✅ 通过项** (R74 继承):
- `PrivacyInfo.xcprivacy` 完整 5 类 AccessedAPI(CA92.1/CA92.2/C617.1/35F9.1/85F4.1/AC67.1)+ 4 类 CollectedDataType(HealthAndFitness/AudioData/ContactInfo/UserContent) — Apple 2024-05 强制
- 12 个 plugin 都有 `native_build=true` 标识 (path_provider_foundation 实际 false 但仍正常工作),各自带 PrivacyInfo(但 `pod install` 跑过后才能 verify,见 1.4 P1-7)
- `NSPrivacyTracking=false` / `NSPrivacyTrackingDomains=[]`

**🟡 警告项** (R74 继承, R76 无变化):
- ⚠️ 第三方 plugin 自带 PrivacyInfo 完整性**未 verify**(见 1.4 P1-7)

**🔴 阻塞项**:
- 无直接 P0(项目自身 PrivacyInfo 完整)

### 3.5 Background Mode

**R74 → R76 状态**: `UIBackgroundModes=[audio, processing]` 声明齐全,**R75 没动**。

**✅ 通过项** (R74 继承):
- `UIBackgroundModes=[audio, processing]` 声明齐全
- `BGTaskSchedulerPermittedIdentifiers=[com.chroniccare.safety-check]` 跟 AppDelegate 一致
- `audio` 真实使用(树洞/情绪日记录音)
- `processing` 占位(失联通知业务暂停,R66 决策)

**🟡 警告项** (R74 继承, R76 无变化):
- ⚠️ `processing` 模式声明但**不触发**(R66 业务暂停),App Store Connect App Privacy 需手动声明 (见 1.3 P1-5)
- ⚠️ `audio` 真实使用但 vent 录音 dialog **缺"切到后台会继续录制"提示**(见 1.3 P1-6)

**🔴 阻塞项**:
- 无

### 3.6 IAP (4.0 — 强制 IAP)

**R74 → R76 状态**: `FeatureFlags._prodIapEnabled=false`(R68 决策),App 内不显示入口,**R75 没动**。

**✅ 通过项** (R74 继承):
- `FeatureFlags._prodIapEnabled=false`(R68 d691551 决策),App 内不显示入口
- `in_app_purchase` plugin 已集成但 dev 模式走 kDebugMode 直接返 true
- 3 locale description 都有 8 元买断注脚("v0.28 真接 productId 后启用")
- Fastfile `precheck_include_in_app_purchases: false` 显式声明无 IAP

**🟡 警告项** (R74 继承, R76 无变化):
- ⚠️ `in_app_purchase_storekit 0.4.11` 引用了 StoreKit 框架但**未真接 productId** — Apple 4.0 不强制声明 IAP 存在(描述里写"8 元买断"但代码层不接 = R69 P0-8 已警示,R69 加注脚修了文档层)
- ⚠️ v0.28 真接时需在 App Store Connect 创建 NonConsumable product,Fastfile `precheck_include_in_app_purchases: true` 同步改

**🔴 阻塞项**:
- 无 IAP P0(已通过 FeatureFlags 隔离)

---

## 4. App Store Connect 表单必填项

| # | 字段 | 当前值 (R76) | 阻塞状态 | R74 状态 | R76 状态 |
|---|---|---|---|---|---|
| 1 | App 名称 (App Name) | "慢病管家" (per-locale) | 🟡 P1-3 (InfoPlist.strings pbxproj 半配) | 🔴 P0-4 (knownRegions 缺) | 🟡 P1-3 (knownRegions 已加, 但 PBXVariantGroup 漏) |
| 2 | Bundle ID | `com.chroniccare.chroniccare` (fastlane) = `com.chroniccare.chroniccare` (pbxproj) | ✅ | 🔴 P0-1 (不一致) | ✅ R75 修一致 |
| 3 | SKU | 未设 | 🟢 P2-1(可任意字符串) | 🟢 P2-1 | 🟢 P2-1 |
| 4 | Primary Language | 英文 (en-US) | ✅ | ✅ | ✅ |
| 5 | Primary Category | Health & Fitness | ✅ | ✅ | ✅ |
| 6 | Secondary Category (可选) | 未设 | 🟢 P2-2(建议 Medical) | 🟢 P2-2 | 🟢 P2-2 |
| 7 | Price / 售价 | 未设 | 🟡 P1-8 (8 元文案 vs 不接 IAP) | 🟡 P1-7 | 🟡 P1-8 |
| 8 | App 描述 | en-US 2913 / zh-Hans 1359 / zh-Hant 1324 | ✅ | ✅ | ✅ |
| 9 | 关键词 | en-US 54 / zh-Hans 27 / zh-Hant 27 | ✅ | ✅ | ✅ |
| 10 | 副标题 | en-US 25 / zh-Hans 28 / zh-Hant 27 | ✅ | ✅ | ✅ |
| 11 | 宣传文本 | en-US 136 / zh-Hans 69 / zh-Hant 69 | ✅ | ✅ | ✅ |
| 12 | 隐私 URL | `https://chroniccare.app/privacy` | 🔴 P0-8 (域名未注册) | 🔴 P0-8 | 🔴 P0-8 |
| 13 | 支持 URL | `https://chroniccare.app/support` | 🔴 P0-8 (域名未注册) | 🔴 P0-8 | 🔴 P0-8 |
| 14 | 营销 URL (可选) | 未设 | 🟢 P2-3 | 🟢 P2-3 | 🟢 P2-3 |
| 15 | Copyright | "© 2026 chroniccare" (UTF-8, 终端 mojibake) | ✅ (实质) | ✅ | ✅ |
| 16 | App Icon 1024×1024 | 67 字节占位 | 🔴 P0-7 | 🔴 P0-7 | 🔴 P0-7 |
| 17 | iPhone 6.5" 截图 | 67 字节占位 × 5 × 3 locale | 🔴 P0-6 | 🔴 P0-6 | 🔴 P0-6 |
| 18 | iPhone 5.5" 截图 | 67 字节占位 × 3 × 3 locale | 🔴 P0-6 | 🔴 P0-6 | 🔴 P0-6 |
| 19 | iPad 12.9" 截图 | 67 字节占位 × 3 × 3 locale | 🔴 P0-6 | 🔴 P0-6 | 🔴 P0-6 |
| 20 | iPhone 6.7" 截图 | **不存在** (Apple 2024 新要求) | 🟡 P1-8 (R74 加重) | 🟡 P1-8 | 🟡 P1-8 |
| 21 | App Privacy 数据收集 | 需 ASC 后台勾选 | 🟡 P1-5 (对应 `processing` dormant) | 🟡 P1-5 | 🟡 P1-5 |
| 22 | App Privacy 跟踪 | `NSPrivacyTracking=false` | ✅ | ✅ | ✅ |
| 23 | Export Compliance | `ITSAppUsesNonExemptEncryption=false` | 🟡 P1-1 (跟 SQLCipher 矛盾) | 🟡 P1-1 | 🟡 P1-1 |
| 24 | App Review 信息(测试账号) | 0 个 IAP 0 个测试账号 | ✅ | ✅ | ✅ |
| 25 | 审核员联系邮箱 | `support@chroniccare.app` (占位) | 🔴 P0-9 | 🔴 P0-9 | 🔴 P0-9 |
| 26 | 版本号 | 0.27.0+64 | 🟡 P1-9 (< 1.0.0) | 🟡 P1-9 | 🟡 P1-9 |
| 27 | Copyright © 文本 | 已填 | ✅ | ✅ | ✅ |
| 28 | 推送通知 | NO(代码无 APNs,R70 删 aps-environment) | ✅ | ✅ | ✅ |
| 29 | Sign in with Apple | NO(无第三方登录) | ✅ | ✅ | ✅ |
| 30 | Apple Pay | NO | ✅ | ✅ | ✅ |
| 31 | In-App Purchase | 0 productId 声明 | ✅ | ✅ | ✅ |
| 32 | App 内购产品列表 | 0 个(暂停业务) | ✅ | ✅ | ✅ |
| 33 | Beta Testing (R76 NEW) | RunnerTests 1 个空 test, 选 Yes 风险 | 🟡 P1-10 (R76 NEW) | N/A (R74 没列) | 🟡 P1-10 |

**🔴 阻塞 (R76)**: 12, 13, 16, 17, 18, 19, 25 = **7 项** (R74 8 项, -P0-1 修)
**🟡 警告 (R76)**: 1, 7, 20, 21, 23, 26, 33 = **7 项** (R74 4 项, +1-3 升级 +P1-8 6.7"+P1-10 RunnerTests)
**✅ 通过 (R76)**: 18 项 (R74 20 项, -P0-1 解除, +1 修正)

---

## 5. R74 → R76 P0 跟踪

| R74 编号 | 描述 | R74 状态 | R75 修了? | R76 状态 | 证据 |
|---|---|---|---|---|---|
| **P0-1** | PRODUCT_BUNDLE_IDENTIFIER 不一致 (`com.chroniccare.app` vs `com.chroniccare.chroniccare`) | 🔴 | ✅ R75 `403753c` | ✅ **已修** | `pbxproj:380,560,583 = com.chroniccare.chroniccare`, `fastlane/Appfile:19 = com.chroniccare.chroniccare`, 一致 |
| **P0-2** | fastlane/Appfile 3 TODO ID 占位 (`your-apple-id@example.com` / `YOUR_TEAM_ID` / `YOUR_ITC_TEAM_ID`) | 🔴 | ❌ R75 没动 | 🔴 **未修** | `Appfile:21,23,25` 占位仍存在 |
| **P0-3** | AppDelegate UNUserNotificationCenter willPresent 未实现 | 🔴 | ✅ R75 `b045953` | ✅ **已修** | `AppDelegate.swift:54-61` 实现 willPresent, 返回 `[.banner, .list, .sound, .badge]` |
| **P0-4** | pbxproj `knownRegions` 缺 zh-Hans/zh-Hant | 🔴 | 🟡 R75 `403753c` 修了 knownRegions 但 PBXVariantGroup 漏 | 🔴 **半修半废** | knownRegions ✅ (`pbxproj:196-197` 加 zh-Hans/zh-Hant), 但 `pbxproj:294-311` PBXVariantGroup 只有 storyboard, 未加 InfoPlist.strings 引用; `pbxproj:112-128` PBXGroup Runner children 未列 lproj 文件 → 编译时 InfoPlist.strings 不进 bundle → 中文 locale fallback 英文 |
| **P0-5** | iOS 端缺 Podfile + Podfile.lock (走 CocoaPods 路径) | 🔴 | ❌ R75 没动 | 🔴 **未修** | `Test-Path 'ios\Podfile'` = False, `Test-Path 'ios\Podfile.lock'` = False |
| **P0-6** | 33 张 67 字节透明占位截图 (1232×720) | 🔴 | ❌ R75 没动 | 🔴 **未修** | 33 张 PNG 全 67 字节 (R76 验证 36 张 PNG 总 2412 字节, 平均 67 字节) |
| **P0-7** | 3 张 67 字节 app_icon 占位 | 🔴 | ❌ R75 没动 | 🔴 **未修** | 3 张 `app_icon.png` × 67 字节 (R76 验证) |
| **P0-8** | 6 URL 文件 `chroniccare.app` 域名未注册 | 🔴 | ❌ R75 没动 | 🔴 **未修** | `privacy_url.txt` + `support_url.txt` × 3 locale = 6 文件全 `https://chroniccare.app/{privacy,support}` (R76 验证) |
| **P0-9** | `user_agreement.md:60-61` support@ + github 仓库占位 | 🔴 | ❌ R75 没动 | 🔴 **未修** | `user_agreement.md:60-61` 仍占位 (R76 验证) |
| **P0-10** | 3 法律 md 无英文版 / 繁体版 | 🔴 | ❌ R75 没动 | 🔴 **未修** | `user_agreement.md` / `privacy_policy.md` / `sensitive_data_consent.md` 都**只中文** (R76 验证, Test-Path en/zh-Hant 副本 = False) |
| **P0-11** | privacy_policy.md / user_agreement.md 引用不存在文件 | 🔴 | (R68 修) | ✅ **已修** | `docs/SPRINT1_LEGAL_TODO.md` 133 行 + `docs/LEGACY_API_NOTES.md` 147 行 真实存在 (R68 commit 556d454, R76 验证) |
| **P0-12** | Medical 类综合 (依赖 P0-9/10) | 🔴 | ❌ | 🔴 **未修** | 依赖 P0-9/10/11 (P0-11 已修, P0-9/10 仍) |

**统计**:
- R74 P0 阻塞 **12 项**
- R75 (iOS Sprint) 修 3 项 (P0-1/3/4 一半)
- R68 修 1 项 (P0-11, 不计 R75)
- R76 实际 P0 阻塞 **9 项** (P0-2/4 半/5/6/7/8/9/10/12)
- **R76 P0 修复率**: 25% (3/12 由 R75 修, 0 由 R76 新修)

**R76 新发现** (相对 R74):
- 🔴 **P0-4 升级 (R76)**: R75 修了 knownRegions 但 PBXVariantGroup / PBXGroup 没补, InfoPlist.strings 不进 bundle = P0 实质未修
- 🟡 **P1-10 (R76 NEW)**: RunnerTests.swift 空 test, Apple 4.0 in-app testing 评分 + ASC Beta Testing 表单风险
- 🟢 **R76 报告事实修正**: R74 报告 (1.4 表格) 标 path_provider_foundation `native_build=true`, 实际 R76 验证为 `false` (但**不影响上架**, 仍正常工作, 是 R74 报告细节差错)
- 🟢 **R76 报告事实修正**: R74 报告 4.15 copyright 标 ✅, 实际文件 UTF-8 正确 (PowerShell 终端 GBK mojibake 显示成"漏 2026 chroniccare", 文件实质是 "© 2026 chroniccare", **不影响 Apple 上传**)

---

## 6. 上架阻塞清单

### 🔴 P0 阻塞 (R76: 9 项)

| # | 类别 | 难度 | 位置 | 问题 | Guideline 引用 | 估时 | 谁来做 |
|---|---|---|---|---|---|---|---|
| **P0-2** | 底层 | XS | `fastlane/Appfile:21, 23, 25` | 3 个 TODO ID 占位(`your-apple-id@example.com` / `YOUR_TEAM_ID` / `YOUR_ITC_TEAM_ID`) → fastlane upload authentication error | **2.1 + 5.6.2 Developer Identity**: 信息必 truthful + verifiable | 0.5-1h (需用户填真实 Apple ID + Team ID) | 用户(需真实 Apple ID + Team ID) |
| **P0-4** | 底层 | S | `ios/Runner.xcodeproj/project.pbxproj:294-311` + `:112-128` | R75 修了 `knownRegions` 加 `zh-Hans`/`zh-Hant` ✅, 但 **PBXVariantGroup 没加 InfoPlist.strings 引用** + **PBXGroup Runner 没列 lproj 文件** → 编译时 InfoPlist.strings 不进 bundle → 简体/繁体用户看英文名"ChronicCare" (R70 修的 per-locale 失效) | **2.3.7 App Names**: 30 字符 + 必 localized correctly | 0.5-1h (Xcode GUI 在 Runner target → Info → Localizations 勾 Chinese Simplified + Traditional, Xcode 自动改 pbxproj; 或手工 pbxproj 加 PBXVariantGroup + 2 PBXFileReference) | 工程 |
| **P0-5** | 底层 | M | `ios/Podfile`(不存在) + `ios/Podfile.lock`(不存在) | iOS 端缺 `Podfile` + `Podfile.lock` (`.flutter-plugins-dependencies:100` 走 CocoaPods 路径) → `bundle exec fastlane ios beta` 首次 build 失败 | **2.1 App Completeness (c)**: build 必须能跑通 | 2-4h (等 `flutter pub get` + `pod install` + 验证 build) | 工程 |
| **P0-6** | 底层 | L | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/{iphone_6_5,iphone_5_5,ipad_12_9}_screenshots/0[1-5]_home.png` 33 张 | **全 67 字节透明占位 PNG**(`1232×720` 不是任何 Apple 尺寸, IDAT 块仅 10 字节 ≈ 空白) → ASC 校验分辨率直接拒 | **2.3.3 Screenshots**: "should show the app in use" — 67 字节占位 not in use | 1-2 天 (Simulator 截图 + 5 主页面 × 3 device × 3 locale) | 工程(需真机或 Simulator) |
| **P0-7** | 底层 | XS | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/app_icon.png` 3 张 | **67 字节占位** → 必须替换 1024×1024 不透明 PNG (Apple 强制, ASC 校验) | **2.3.9 App Icons**: 1024×1024 opaque PNG | 1h (从 `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` 复制) | 工程 |
| **P0-8** | 底层 | M | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/{privacy_url,support_url}.txt` 6 文件 | 全是 `https://chroniccare.app/privacy` + `https://chroniccare.app/support` → 域名**未注册未验证** → reviewer 点 URL 404 直接拒 | **1.5 + 5.1.1 (i)**: privacy URL 必实际可达 | 0.5-1 天 (注册 chroniccare.app 域名 + 部署 privacy / support 页面 + HTTPS 证书) | 用户(法务 / 运营) |
| **P0-9** | 底层 | S | `assets/legal/user_agreement.md:60-61` | `support@chroniccare.app` 邮箱占位 + `https://github.com/example/chroniccare/issues` 仓库占位 | **1.5 Developer Information**: Support URL 必可联系 | 0.5h (注册 `support@chroniccare.app` 邮箱 + 创建/确认 GitHub 仓库) | 用户 |
| **P0-10** | 底层 | L | `assets/legal/{privacy_policy,user_agreement,sensitive_data_consent}.md` 0 英文 / 0 繁体版 | 3 份 md 全中文 → en-US 走 App Store 时 consent 3 份都是中文,**Apple 1.4.3 + PIPL 知情同意语种双重 fail** | **1.4.3 + 5.1.1 (iii)**: 知情同意语种必用户语种一致 | 1-2 周 (翻译 3 份 md × 2 locale) | 用户(法务 / 翻译) |
| **P0-12** | 顶层 | XL | 综合 (P0-2 + P0-6 + P0-7 + P0-8 + P0-9 + P0-10) | Medical 类 (1.4.1) en-US 上架时缺英文法律 + 占位邮箱 + 占位 URL + 占位截图 + 占位 TODO ID → **Apple 审核员**看到这些会**直接打回**(medical + 占位) | **1.4.1 + 2.1 + 2.3 + 5.1.1** 多重 fail | 2-3 周 (综合 6 项) | 多方协调 |

**P0 总工时 (R76)**: ~17-25 工程人天 + 用户配合 1-2 周 (域名 + 邮箱 + 翻译 + 真实 Apple ID/Team ID)

### 🟡 P1 警告 (R76: 7 项, 含 1 项 R76 NEW)

| # | 类别 | 难度 | 位置 | 问题 | 修复建议 |
|---|---|---|---|---|---|
| **P1-1** | 底层 | S | `ios/Runner/Info.plist:103-104` | `ITSAppUsesNonExemptEncryption=false` 跟 SQLCipher AES-256 + 隐私政策"字段级加密"声明矛盾 | 改 `true` + 准备 self-classification report (CCATS), 或反向把 `privacy_policy.md` 措辞改"标准库 SQLCipher 加密,符合 Apple export compliance 豁免" |
| **P1-2** | 底层 | S | `ios/Runner/Info.plist:144-148` + ASC App Privacy 勾选 | `UIBackgroundModes=processing` 声明但失联通知业务整体暂停 → ASC 提交时需在 App Privacy 描述加醒目声明 "Lost-contact safety net: currently disabled, capability reserved for v1.0" | 手动勾选 ASC App Privacy 对应标签, 加 capability reserved 描述 |
| **P1-3** | 底层 | S | `ios/Runner.xcodeproj/project.pbxproj:294-311` + `:112-128` | R75 修了 knownRegions 但 PBXVariantGroup / PBXGroup 没补, InfoPlist.strings 不进 bundle (跟 P0-4 同一个根因, P0-4 修后自动解除) | 已在 P0-4 列 |
| **P1-4** | 底层 | S | `lib/domain/logic/phq9.dart` + `gad7.dart` + `lib/l10n/app_en.arb` | PHQ-9 / GAD-7 32 题 + 严重度 + 危机电话**未走 ARB 全 i18n**(`FeatureFlags.phqGad7I18nEnabled=false` R65b 默认关闭) → en-US 用户看到中文量表 = 准确性受质疑(Apple 1.4.1) | 翻译量表 + 打开 FeatureFlag |
| **P1-5** | 底层 | XS | ASC App Privacy 提交勾选 | `processing` 后台模式 dormant 需 ASC 手动声明 | 同 P1-2 |
| **P1-6** | 底层 | S | `lib/presentation/pages/vent/vent_compose_page.dart` 录音 dialog | vent 录音 dialog 顶部**缺"录音时切到后台会继续录制"提示** → Apple 4.0 Background audio 建议 visible purpose 提示 | 录音 dialog 顶部加 1 行 caption |
| **P1-7** | 底层 | S | `ios/Pods/...(未生成)` | 第三方 plugin 12 个自带 PrivacyInfo **未 verify** (`pod install` 跑后 grep `<App>.app/Frameworks/*.framework/PrivacyInfo.xcprivacy`) | 跑 `pod install` + grep 校验 + 缺则修 plugin 版本 |
| **P1-8** | 底层 | M | `fastlane/metadata/ios/*/iphone_6_7_screenshots/` 不存在 | Apple 2024 起新提交要求 6.5" (1242×2688) 或 6.7" (1290×2796) 二选一; 项目当前是 `1232×720` 占位,**不是任一尺寸**, 需重做 | 跑 `flutter run -d "iPhone 15 Pro"` Simulator + Screenshot, 存 6.5 + 6.7 两套 |
| **P1-9** | 底层 | XS | `pubspec.yaml:4` | 版本号 `0.27.0+64` < 1.0.0 → 上架前 bump `1.0.0+1`(表达"正式版",避免 Apple 4.3 Spam 自动标 pre-release) | bump 1.0.0+1 |
| **P1-10** | 底层 | S | `ios/RunnerTests/RunnerTests.swift:7-10` | 整个 XCTestCase 只 1 个空 `testExample()` 方法 → Apple 4.0 "include in-app testing" 评分 + ASC Beta Testing 表单选 Yes 风险 | 加 ≥1 个真实测试 (e.g. `FlutterEngine` 起 `Runner` channel + 调 Dart API 验证 `appContext.dbKeyService` 可达) |

**P1 总工时 (R76)**: ~5-8 工程人天

### 🟢 P2 建议 (R76: 3 项, R74 继承)

| # | 类别 | 难度 | 位置 | 问题 | 建议 |
|---|---|---|---|---|---|
| **P2-1** | 顶层 | XS | ASC App 信息 | SKU 未设(可任意字符串) | 填 `chroniccare-001` 或类似 |
| **P2-2** | 顶层 | XS | ASC App 信息 | 未设 Secondary Category | 加 Medical 二次分类(精神心理患者属 medical) |
| **P2-3** | 顶层 | XS | ASC App 信息 | 未设 Marketing URL | 填 `https://chroniccare.app` 主域名(配合 P0-8) |

**P2 总工时**: < 1h

---

## 附录: R75 修了什么确认 (git log + git show 验证)

| 修了什么 | R75 commit | 文件 | 现状 (R76) | 评级 |
|---|---|---|---|---|
| AppDelegate conform `UNUserNotificationCenterDelegate` + 实现 `userNotificationCenter(_:willPresent:)` 返回 `[.banner, .list, .sound, .badge]` | `b045953` (iOS-1) | `ios/Runner/AppDelegate.swift:7, 23, 54-61` | ✅ R76 验证全过 | **完整** |
| pbxproj `PRODUCT_BUNDLE_IDENTIFIER = com.chroniccare.app` → `com.chroniccare.chroniccare` (3 build config) | `403753c` (iOS-2) | `ios/Runner.xcodeproj/project.pbxproj:380, 560, 583` | ✅ R76 验证 3 处一致 | **完整** |
| pbxproj `knownRegions` 加 `zh-Hans` + `zh-Hant` | `403753c` (iOS-2) | `ios/Runner.xcodeproj/project.pbxproj:196-197` | ✅ R76 验证 knownRegions ✅ | **半修** — knownRegions 加了, 但 pbxproj 的 `PBXVariantGroup` + `PBXGroup Runner children` 没补 InfoPlist.strings 引用 → 编译时 InfoPlist.strings 不进 bundle, R70 修的 per-locale 失效 |

**R75 总结**:
- 3 个 commit 改 2 个文件 (AppDelegate.swift + project.pbxproj)
- 实际修了 **2 项完整 P0** (AS-P0-1 bundle ID, AS-P0-3 willPresent) + **1 项半修 P0** (AS-P0-4 knownRegions 但 PBXVariantGroup 漏)
- 修 P0 量: **2 + 0.5 = 2.5 P0 修了**

**R75 没修的 P0 (R76 仍 P0)**:
- P0-2 (Appfile 3 TODO ID) — 用户负责
- P0-4 (InfoPlist.strings 编译依赖) — 工程, 跟 R75 knownRegions 配套, 需补 PBXVariantGroup
- P0-5 (Podfile 缺失) — 工程
- P0-6 / P0-7 (33 + 3 张占位图) — 工程 / 设计
- P0-8 (域名未注册) — 用户 (法务 / 运营)
- P0-9 (邮箱 + github 占位) — 用户
- P0-10 (3 法律 md 翻译) — 用户 (法务 / 翻译)
- P0-12 (Medical 综合, 依赖 P0-2/6/7/8/9/10) — 多方协调

---

## 审计总结

**项目当前状态** (R76):
- 代码层: 16 守护脚本全绿, flutter analyze 0 issue, dart check_all ✅, 1098+ tests pass, 0 error / 0 warning / 0 info
- iOS 端工程: R75 修 2.5 P0, R76 实际剩 **9 P0** (P0-2/4/5/6/7/8/9/10/12)
- iOS 端材料: **0 进展** (R74 7 P0 + 0 R75 修 = R76 仍 7 P0: P0-2/6/7/8/9/10 + P0-12 综合)
- 上架就绪度: **2 / 10** (R74 同分, +0.5 工程层 - 0.5 P0-4 半修 = 2/10 持平)

**R75 Sprint 评价**:
- ✅ 工程层 3 commit 改 2 文件, 1.5 个工作日
- ❌ 修了 knownRegions 但**漏 PBXVariantGroup** = P0-4 半修半废, 等于没真修
- ❌ 材料层 0 进展 (screenshot / URL / 邮箱 / 法律翻译 / Appfile TODO 都没动)

**R76 → R77 建议** (上架前必修路径):

1. **R77 工程 0.5 天** (补 R75 漏的):
   - **P0-4**: Xcode GUI 打开 `ios/Runner.xcworkspace` → Runner target → Info → Localizations 勾 `Chinese (Simplified)` + `Chinese (Traditional)`, Xcode 自动补 PBXVariantGroup + PBXFileReference → 验证 build 后 `find build/ios/Build/Products -name "InfoPlist.strings"` 存在
   - **P0-2**: 用户填真实 Apple ID + Team ID + itc_team_id 到 `fastlane/Appfile:21,23,25` (建议走 ENV `apple_id(ENV["APPLE_ID"])`)
   - **P0-7**: 复制 `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` 到 `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/app_icon.png` (3 张, 各 10932 bytes)

2. **R77 工程 1-2 天** (P0-5 build 路径):
   - `flutter pub get` (自动生成 `ios/Podfile`)
   - `cd ios && pod install` (生成 `ios/Podfile.lock`)
   - commit `ios/Podfile` + `ios/Podfile.lock`
   - `flutter build ios --release --no-codesign` 验证 build 成功
   - 跑 `find build/ios/Build/Products -name "InfoPlist.strings"` 验 P0-4 修完整
   - 跑 `find build/ios/Build/Products/Release-iphoneos/Runner.app/Frameworks -name "PrivacyInfo.xcprivacy" | xargs -I {} sh -c 'echo "=== {} ==="; cat {}'` 验 P1-7 plugin PrivacyInfo 完整

3. **R77 设计 1-2 天** (P0-6 截图):
   - 跑 `flutter run -d "iPhone 15 Pro"` Simulator
   - 5 主页面 (home / setup / settings / trend / assessment) 截图 6.5" (1242×2688) + 6.7" (1290×2796) 各 5 张
   - iPad 12.9" (2048×2732) 3 张
   - 总 3 locale × (5 + 5 + 3) = **39 张** (覆盖 6.5" + 6.7" 解决 P1-8)
   - 5 主页面 × 3 device × 3 locale = 45 张, design polish 1-2 天

4. **R77 运营 0.5-1 天** (P0-8 + P0-9):
   - 注册 `chroniccare.app` 域名 (Google Domains / Cloudflare Registrar ~$10/year)
   - 部署 `https://chroniccare.app/privacy` (GitHub Pages / Vercel / Netlify 静态站点, 从 `assets/legal/privacy_policy.md` 渲成 HTML, HTTPS 证书自动)
   - 部署 `https://chroniccare.app/support` (静态 HTML 含邮箱 + GitHub Issues 链接)
   - 注册 `support@chroniccare.app` 邮箱 (Google Workspace / 阿里云邮箱, forward 到开发者个人邮箱, 7 日响应 SLA)
   - 创建 `https://github.com/chroniccare/app-feedback` 仓库 (R67 LEGACY_NOTES 决策 C), 改 user_agreement.md:61

5. **R77 法务 1-2 周** (P0-10 + P0-11 配套):
   - 找 PIPL 专长律师 (北京安杰 / 君合 / 立方, ~¥15k-30k/文档) 审 3 法律 md
   - 翻译 3 法律 md 英文版 (用 deepl.com 草稿, 律师 review) + OpenCC s2tw 简→繁 转换
   - 改 docs/SPRINT1_LEGAL_TODO.md R67 checklist 全 ✅
   - 改 `lib/l10n/app_en.arb` / `app_zh_Hant.arb` 法律 md 链接指向新 HTML
   - App 内 setup 流程重走 — 刷 `userAgreementVersion` / `privacyPolicyVersion` / `sensitiveDataConsentAt` 字段

6. **R77 工程 0.5 天** (P1 综合):
   - P1-1: 改 `ITSAppUsesNonExemptEncryption=false` → `true` + 准备 self-classification report (CCATS 编号, 改 `privacy_policy.md` 第 §11 段措辞)
   - P1-4: 翻译 PHQ-9 / GAD-7 量表 32 题到 en/zh-Hant ARB, 打开 `FeatureFlags.phqGad7I18nEnabled=true`
   - P1-6: vent_compose_page.dart 录音 dialog 顶部加 1 行 caption "录音时切到后台会继续录制"
   - P1-9: pubspec.yaml:4 `0.27.0+64` → `1.0.0+1`
   - P1-10: 加 RunnerTests.swift 真实测试 (e.g. `testFlutterEngineInit` 起 `FlutterEngine` + 验证 `DartEntrypoint` 加载)
   - P1-8: 截图改 6.7" (1290×2796), 跟 P0-6 一起做

**最快上架时间**: 假设用户配合 1 周内 (域名 + 邮箱 + 真实 Apple ID/Team ID + 截图 + 法务), 工程 1 周内 — **2-3 周后可提交 App Store 审核**, 审核周期 1-3 天

**最大风险**:
1. **P0-10 法务翻译** — 1-2 周, 可能因 PIPL 律师协调更长
2. **P0-6 截图** — 需真机或 Simulator 跑 + 5 主页面 × 3 device × 3 locale = 45 张图, design polish 1-2 天
3. **P0-8 域名 + 部署** — 域名注册 + DNS 解析 + HTTPS 证书 + 部署 2 个静态页面 = 0.5-1 天 (用户层面)
4. **Podfile 漂移** — `flutter pub get` + `pod install` 在不同 master spec repo 状态可能产生不同 Podfile.lock, 需锁版本 + 严格 CI 验证
5. **P0-4 半修半废** — R75 修了 knownRegions 但漏 PBXVariantGroup, R77 必修, 否则中文 locale 失效 = 病耻感反向 (R69 P1-2 修了又退回)

**最后建议**:
- R76 报告后**优先 R77 修 P0-4** (补 Xcode GUI 加 localization) + P0-2 (用户填真实 ID) + P0-7 (复制 app_icon), **3 项 0.5 天** = 工程最大 ROI
- 同步启动法务 (P0-10) + 运营 (P0-8/9) + 设计 (P0-6) 多线并行
- P0-5 (Podfile) + P0-12 (Medical 综合) 等 P0-2/4/6/7/8/9/10 修了自动解
- **总 2-3 周可提交审核**, 提交时按 ASC 流程:
  1. ASC 创建 App + 选 Bundle ID `com.chroniccare.chroniccare` (R75 一致)
  2. 填 App Information (名称 / 副标题 / 类别 / 隐私 URL / 支持 URL)
  3. 填 App Privacy (4 类 CollectedDataType + 5 类 AccessedAPI, 加 `processing` dormant 声明)
  4. 上传 build (fastlane `bundle exec fastlane ios release`)
  5. 上传 metadata (fastlane `bundle exec fastlane ios metadata` 或手工)
  6. 上传 screenshot (P0-6 修后)
  7. Export Compliance 选 `ITSAppUsesNonExemptEncryption=true` (P1-1 修后) + CCATS 编号
  8. App Review 信息填 `support@chroniccare.app` (P0-9 修后)
  9. Version 1.0.0 (P1-9 修后)
  10. Submit for Review (选 manual release, 审核通过手动 release)
