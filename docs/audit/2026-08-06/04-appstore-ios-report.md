# App Store iOS 上架审计

> **审计对象**: `chroniccare` Flutter App 精神心理患者吃药打卡
> **审计时间**: 2026-08-06 (v0.30.0+85, R91 后)
> **审计员**: Apple App Store Review Guidelines + iOS 平台规范独立视角
> **审计基础**:
> - `docs/reviews/2026-07-31-seven-lens/appstore/report.md` (R62 阶段, 9 P0 / 10 P1 / 5 P2 / 2 P3, 就绪度 3.5/10)
> - `reports/round69_appstore.md` (R64+R69 阶段, 7 P0 阻塞, 就绪度 38/100)
> - 本次审计: 实际 walk 完 `ios/` + `lib/main.dart` + `lib/core/data/services/*` + `lib/presentation/pages/setup/*` + `lib/domain/logic/care_engine.dart` + `pubspec.yaml` + `fastlane/` + `CHANGELOG.md R61–R91`
>
> **状态标注**: ✅ 已就绪 / 🟡 部分就绪 (可上架但有 P1 警告) / 🔴 阻塞 (P0 必修)
> **难度**: S (<1h) / M (1-4h) / L (1-3d) / XL (1-2w 外部依赖)
> **优先级**: P0 (上架 blocker) / P1 (上架后 1 月内修) / P2 (v1.0 前) / P3 (nit)
> **架构级 vs 底层级**: 架构级 = 影响多模块的代码结构 / 业务边界; 底层级 = 单文件 / 单字段 / 单 API 调用

---

## 总体评估

### 上架就绪度: **6.0 / 10** (R62 3.5/10 → R69 3.8/10 → 当前 6.0/10)

| 维度 | 评分 | 关键事实 |
|------|------|----------|
| **代码 (lib/)** | **8.5/10** | 4 层架构纯度保留, NotificationService facade 拆 6 sub-service, CareEngine 拆 4 strategy, 1617 测试 pass。**3 个挂置**: AliyunSmsProvider.send() 仍 `throw StateError` + `_prodIapEnabled=false` 隐藏 IAP 入口 + `withdrawConsent` 0 caller |
| **iOS 工程 (ios/)** | **9.0/10** | R61-R75 期间把 7 个 P0 平台配置全修完 — IPHONEOS_DEPLOYMENT_TARGET 14.0 / SUPPORTED_PLATFORMS=iphoneos+iphonesimulator / CODE_SIGN_ENTITLEMENTS=Runner/Runner.entitlements / NSPhotoLibraryAddUsageDescription + NSPhotoLibraryUsageDescription / ITSAppUsesNonExemptEncryption=false / LSApplicationCategoryType=healthcare-fitness / UIBackgroundModes=audio+processing / BGTaskSchedulerPermittedIdentifiers / NSUserTrackingUsageDescription 防御性声明 / UNUserNotificationCenterDelegate R75 修 / InfoPlist.strings per-locale zh-Hans+zh-Hant+Base / 删 NSUserNotificationUsageDescription (iOS 10+ 弃用) / 删 UIMainStoryboardFile (跟 SceneManifest 重复) / 删 aps-environment (无 APNs 不声明)。**剩 4 个 P0**: AppIcon 1024 = Flutter 默认图 / LaunchImage.png = 68 字节占位 / LaunchScreen 纯白 / Podfile 占位 (Windows 没跑过 `pod install`) |
| **隐私 (PrivacyInfo.xcprivacy)** | **9.0/10** | R61 R67 R71 三轮加 5 类 required-reason API (UserDefaults CA92.1+CA92.2 / FileTimestamp C617.1 / SystemBootTime 35F9.1 / DiskSpace 85F4.1 / ProcessInfo AC67.1) + 4 类 collected data (HealthAndFitness / AudioData / ContactInfo / UserContent, 全 Linked=false Tracking=false Purposes=AppFunctionality)。**剩 1 个 P1**: 需补 `NSFaceIDUsageDescription` (flutter_secure_storage 内部走 LAContext) |
| **法务 (assets/legal/)** | **3.0/10** | 3 份文档 12 章节覆盖 PIPL/HIPAA/GDPR ✓ + R67 ConsentArtifact 实体 + R83 第 4 个年龄严正声明 + R67 软隐藏 support@chroniccare.app + R67 5 危机热线 (大陆 2 + 港澳台 3)。**剩 3 个 P0**: 文档仍标"草稿"未经律师过审 / privacy_url=https://chroniccare.app/privacy 是占位域名 (404) / support_url 同占位 / 留 1 个 `https://github.com/example/chroniccare/issues` 占位 |
| **业务 (StoreKit + SMS)** | **2.0/10** | in_app_purchase: ^3.3.0 + StoreKitService 封装 + dev 模式绕开。**2 个 P0 阻塞**: `_prodIapEnabled=false` (`buyLifetime()` release 返 false) + `user_agreement.md:25` 写 8 元买断 = 描述 vs 实际不符 (3.1.5 + 2.1.4 双面风险) + `AliyunSmsProvider.send()` 抛 `StateError` 永不发 (失联通知 release 永远不工作) |
| **元数据 (App Store Connect / fastlane)** | **0.5/10** | 11 个截图 (en-US + zh-Hans + zh-Hant × iphone_5_5/6_5/ipad_12_9) 全 67 字节占位 (纯黑 PNG, 1232×720 比例错) + 3 个 app_icon.png 全 67 字节占位 + fastlane/Appfile 4 处 TODO 占位 (apple_id/team_id/itc_team_id) + description.txt:14-16 写"Lost-contact safety net (coming soon — currently disabled)" (描述 vs 实际断层) + privacy_url/support_url 占位 |
| **测试 (TestFlight)** | **0.0/10** | **从未在 Mac 跑过 build**, 0 崩溃率数据, 0 真机回归, 0 device farm 测试。`pubspec.yaml:3` Flutter `>=3.41.0` 兼容但当前 CI 跑 web (`flutter build web`) 不跑 ios (`flutter build ios` Mac only) |
| **iPad Pro 12.9" 适配** | **6.0/10** | TARGETED_DEVICE_FAMILY=1,2 ✓ + UIRequiresFullScreen=false ✓ + iPad 多任务 ✓。**剩 1 个 P1**: setup_page / home_page / mood_recorder_page 在 1024pt 宽下未做"regular size class" 适配, Apple 4.0 Design 扣分 |

### 3 行总结

1. **平台层从 0 → 90% (R61-R75 功劳)**: 9 个 P0 平台配置 (Info.plist NSUsageDescription / PrivacyInfo.xcprivacy / IPHONEOS_DEPLOYMENT_TARGET / Runner.entitlements / UIBackgroundModes / BGTaskSchedulerPermittedIdentifiers / ITSAppUsesNonExemptEncryption / LSApplicationCategoryType / InfoPlist.strings) 全部到位。剩 4 个 iOS 平台 P0 (AppIcon / LaunchScreen / LaunchImage / Podfile)。

2. **业务 / 法务 / 元数据 / 测试 仍 0-30%**: 4 类 blocker 各占 25% — 法务文档未过审 + IAP 业务暂停 + 失联通知 release 不发 + 占位截图 + 占位 fastlane + 占位域名 + 占位 productId。**任何一个不修, 提交即拒**。

3. **3-6 个月内可修复**: 5 个 P0 外部依赖 (律师 4w / 阿里云 SMS 模板 4-8w / 阿里云 AccessKey / Apple Developer 账号 $99 / Mac 设备 + 设计师截图 2-3d) + 7 个 P0 内部改造 (IAP 真接 / Podfile 跑一次 / AppIcon 重做 / 域名注册建站 / 文档法务过审 / 截图替换 / fastlane 4 TODO 替换) 并行, 可达 9.0/10。

### 与历史对比

| 维度 | R62 报告 (7-lens) | R69 报告 | 当前 (R91 后) |
|------|------------------|----------|---------------|
| 上架就绪度 | 3.5/10 | 3.8/10 (38/100) | **6.0/10** |
| P0 总数 | 9 | 7 + 4 (screenshot+appfile) | **10** (合并后 8 个真 P0) |
| 平台 P0 已修 | 0/9 | 4/9 | **9/9** (R61-R75 修完 9 个) |
| 业务 P0 已修 | 0/4 | 0/4 | **0/4** (IAP / SMS / 域名 / 法务 仍未动) |
| 元数据 P0 已修 | 0/4 | 0/4 | **0/4** (截图 / fastlane TODO / app_icon / 描述 vs 实际) |

---

## 1. App Store 审核指南合规

### 1.1 数据收集和隐私 (App Store Review Guidelines §2.5.1 / §5.1)

| # | 问题 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|------|------|------|------|------|--------|
| 1.1.1 | **PrivacyInfo.xcprivacy 完整性** (Apple 2024-05 强制) | ✅ 已就绪 | `ios/Runner/PrivacyInfo.xcprivacy:42-92` 列 4 类 collected data (HealthAndFitness / AudioData / ContactInfo / UserContent, 全 Linked=false Tracking=false Purposes=AppFunctionality) + 5 类 accessed API (UserDefaults CA92.1+CA92.2 / FileTimestamp C617.1 / SystemBootTime 35F9.1 / DiskSpace 85F4.1 / ProcessInfo AC67.1) | 底层 | - | - |
| 1.1.2 | **NSPrivacyTracking = false** | ✅ 已就绪 | `ios/Runner/PrivacyInfo.xcprivacy:22` `<false/>` | 底层 | - | - |
| 1.1.3 | **第三方 SDK 声明** (Drift / SQLCipher / flutter_local_notifications / audioplayers / record / share_plus / printing / pdf / fl_chart / speech_to_text / flutter_secure_storage / pointycastle / in_app_purchase) | 🟡 部分就绪 | `assets/legal/privacy_policy.md:97-105` 列 9 个, 缺 `in_app_purchase` (R65 加的) + `speech_to_text` (v0.23 加的) + `pointycastle` (v0.20 加的)。Apple 5.1.2 要求**所有** third-party SDK 在 App Privacy 详情声明 | 底层 | S | P1 |
| 1.1.4 | **隐私政策 URL 必须可访问** | 🔴 P0 阻塞 | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt:1` 全是 `https://chroniccare.app/privacy` — **域名未注册**, 点击 404 = Apple 5.1.1 必拒 | 底层 | M (建站 + 部署 3-5d) | **P0** |
| 1.1.5 | **Support URL 必须可访问** | 🔴 P0 阻塞 | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/support_url.txt:1` 全是 `https://chroniccare.app/support` — 占位域名 | 底层 | M | **P0** |
| 1.1.6 | **隐私政策 3 份文档** (PIPL/HIPAA/GDPR) | 🟡 部分就绪 | `assets/legal/{user_agreement,privacy_policy,sensitive_data_consent}.md` 12 章节 + R67 ConsentArtifact + R83 第 4 个年龄严正声明 + R67 5 危机热线。**剩**: 文档头部仍标"草稿 (Sprint 1 修订)" + "TODO 上 store 前必须由专业律师过审" | 底层 | L (法务 4w) | **P0** |
| 1.1.7 | **隐私 / 投诉邮箱软隐藏** | 🟡 部分 | R67 决定"不提供邮件渠道", 但 Apple 5.1.1 要求"可联系的支持渠道"。App Store Connect 有 "Contact Information" 字段需填 | 底层 | S (注册 1h) | P1 |
| 1.1.8 | **App Tracking Transparency (ATT)** | 🟡 防御性 | `ios/Runner/Info.plist:67-68` 加 `NSUserTrackingUsageDescription = "本应用不收集任何追踪数据，仅用于 App Store 透明性声明"`。项目 0 IDFA / 0 ad SDK, OK | 底层 | - | - |
| 1.1.9 | **Personal Data 类型 — Health & Fitness** | ✅ 已就绪 | `PrivacyInfo.xcprivacy:46` 声明 `NSPrivacyCollectedDataTypeHealthAndFitness`, Purposes=AppFunctionality | 底层 | - | - |
| 1.1.10 | **Personal Data 类型 — Audio Data** | ✅ 已就绪 | `PrivacyInfo.xcprivacy:58` 声明 `NSPrivacyCollectedDataTypeAudioData` (树洞录音 + 情绪语音) | 底层 | - | - |
| 1.1.11 | **Personal Data 类型 — Contact Info** | ✅ 已就绪 | `PrivacyInfo.xcprivacy:70` 声明 `NSPrivacyCollectedDataTypeContactInfo` (紧急联系人) | 底层 | - | - |
| 1.1.12 | **Personal Data 类型 — User Content** | ✅ 已就绪 | `PrivacyInfo.xcprivacy:82` 声明 `NSPrivacyCollectedDataTypeUserContent` (树洞文字 / 树洞录音元数据) | 底层 | - | - |
| 1.1.13 | **Required Reason API — UserDefaults** | ✅ 已就绪 | `PrivacyInfo.xcprivacy:98-108` 声明 `CA92.1` + `CA92.2` (R71 补 cross-app) | 底层 | - | - |
| 1.1.14 | **Required Reason API — FileTimestamp** | ✅ 已就绪 | `PrivacyInfo.xcprivacy:111-116` 声明 `C617.1` | 底层 | - | - |
| 1.1.15 | **Required Reason API — SystemBootTime** | ✅ 已就绪 | `PrivacyInfo.xcprivacy:119-124` 声明 `35F9.1` (跨日检测) | 底层 | - | - |
| 1.1.16 | **Required Reason API — DiskSpace** | ✅ 已就绪 | `PrivacyInfo.xcprivacy:127-132` 声明 `85F4.1` | 底层 | - | - |
| 1.1.17 | **Required Reason API — ProcessInfo** | ✅ 已就绪 | `PrivacyInfo.xcprivacy:135-146` 声明 `AC67.1` (R71 补) | 底层 | - | - |
| 1.1.18 | **NSFaceIDUsageDescription 缺失** | 🟡 防御性缺失 | `flutter_secure_storage` 9.x iOS 14+ 内部走 `LAContext.evaluatePolicy(.deviceOwnerAuthentication)`, 真机首次 Keychain unlock 弹"需要 Face ID 权限"但无 description 字符串可能闪退。**强烈建议**补防御性 `NSFaceIDUsageDescription` | 底层 | S | P1 |

**1.1 维度小结**: 90% 就绪, 剩 4 个 P0 (1.1.4 / 1.1.5 / 1.1.6 法务过审) + 2 个 P1 (1.1.3 SDK 列表补 / 1.1.18 NSFaceID 防御性)。

---

### 1.2 权限 (App Store Review Guidelines §2.4 / §5.1.1)

| # | 权限 Key | 状态 | 实际值 / 位置 | 类型 | 难度 | 优先级 |
|---|---------|------|--------------|------|------|--------|
| 1.2.1 | `NSMicrophoneUsageDescription` | ✅ | `Info.plist:42-43` "用于情绪日记的语音录入，本地处理，文件加密存储" | 底层 | - | - |
| 1.2.2 | `NSSpeechRecognitionUsageDescription` | ✅ | `Info.plist:44-45` "用于情绪日记的语音转文字，本地处理，不上传" | 底层 | - | - |
| 1.2.3 | `NSPhotoLibraryAddUsageDescription` | ✅ (R62) | `Info.plist:51-52` "用于保存用药报告 PDF 到相册" | 底层 | - | - |
| 1.2.4 | `NSPhotoLibraryUsageDescription` | ✅ (R67) | `Info.plist:61-62` "用于分享用药报告 PDF 时选择保存位置" | 底层 | - | - |
| 1.2.5 | `NSUserTrackingUsageDescription` | ✅ (R61) | `Info.plist:67-68` "本应用不收集任何追踪数据，仅用于 App Store 透明性声明" | 底层 | - | - |
| 1.2.6 | `NSCameraUsageDescription` | ✅ 不需要 | `pubspec.yaml` 无 `image_picker` / `camera` 依赖 | 底层 | - | - |
| 1.2.7 | `NSContactsUsageDescription` | ✅ 不需要 | 项目无 `flutter_contacts` 依赖 | 底层 | - | - |
| 1.2.8 | `NSLocationWhenInUseUsageDescription` | ✅ 不需要 | 项目无 `geolocator` 依赖 | 底层 | - | - |
| 1.2.9 | `NSHealthShareUsageDescription` | ✅ 不需要 | 项目**不接 HealthKit**, PHQ-9/GAD-7 是自评量表不入 HealthKit | 底层 | - | - |
| 1.2.10 | `NSHealthUpdateUsageDescription` | ✅ 不需要 | 同上 | 底层 | - | - |
| 1.2.11 | `NSLocalNetworkUsageDescription` | ✅ 不需要 | 项目零网络请求 (`shared_preferences` 走本地) | 底层 | - | - |
| 1.2.12 | `NSFaceIDUsageDescription` | 🔴 缺失 (防御性) | `flutter_secure_storage` iOS 14+ 走 LAContext, 缺 description 可能闪退 | 底层 | S | P1 |
| 1.2.13 | `UIBackgroundModes` | ✅ | `Info.plist:144-148` `audio` (录音后台继续) + `processing` (失联检测长任务) | 底层 | - | - |
| 1.2.14 | `BGTaskSchedulerPermittedIdentifiers` | ✅ (R62) | `Info.plist:153-156` `com.chroniccare.safety-check` — 跟 `AppDelegate.swift:33` `BGTaskScheduler.shared.register` 一致 | 底层 | - | - |
| 1.2.15 | `aps-environment` (APNs 远程推送) | ✅ 故意不加 | `ios/Runner/Runner.entitlements:0-12` 空 dict, R70 注释"项目无 APNs 远程推送, 只用本地通知"。`App Store Connect` 自动推断 No Push Notifications | 底层 | - | - |
| 1.2.16 | `com.apple.developer.usernotifications.critical-alerts` | ✅ 不需要 | 项目失联通知走"温柔提醒"措辞, 不是 Critical Alert, 不需 entitlement | 底层 | - | - |
| 1.2.17 | `NSAppTransportSecurity` | ✅ 不需要 | 零网络请求, 不需 ATS 例外; `in_app_purchase` 走系统框架不需 ATS | 底层 | - | - |
| 1.2.18 | `NSUserActivityTypes` | ✅ 不需要 | 无 Handoff / Spotlight 功能 | 底层 | - | - |

**1.2 维度小结**: 95% 就绪, 剩 1 个 P1 (1.2.12 NSFaceID 防御性)。

---

### 1.3 隐私政策 / 用户协议 / EULA (§5.1.1 / §5.1.2)

| # | 问题 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|------|------|------|------|------|--------|
| 1.3.1 | **隐私政策 URL 必填 + 可访问** | 🔴 P0 | `privacy_url.txt:1` 是 `https://chroniccare.app/privacy`, 域名未注册 | 底层 | M | **P0** |
| 1.3.2 | **用户协议 URL** | 🔴 P0 | `assets/legal/user_agreement.md` 引用 `https://github.com/example/chroniccare/issues` (占位) | 底层 | S | **P0** |
| 1.3.3 | **EULA (软件最终用户许可协议)** | 🟡 部分 | `user_agreement.md` 内容是 EULA 风格, 但未明确标记"EULA"; App Store Connect 可勾选"使用标准 EULA"或"自定义" | 底层 | S | P1 |
| 1.3.4 | **PIPL §13 单独同意** (敏感个人信息) | ✅ R62 | `sensitive_data_consent.md` §4 单独同意书 + R67 ConsentArtifact 实体 + R58 ConsentDialog 共享 + setup 第 3 步 + 联系人 add 强制 consent | 架构 | - | - |
| 1.3.5 | **PIPL §14 撤回机制** | 🟡 文档承诺 0 caller | `privacy_policy.md:81` 写"撤回机制 R67 真接", 但 `lib/` grep `withdrawConsent` 0 caller — 用户无 UI 入口撤回 | 架构 | M | P1 |
| 1.3.6 | **PIPL §23 家庭事务单独同意** | 🟡 R58 软实施 | setup 加联系人时强制 ConsentDialog (`lib/presentation/widgets/consent_dialog.dart` R62 落地), 但**联系人本人**没独立确认通道 (依赖用户"担保已告知")。R58 文档承诺 v1.0 真接阿里云 SMS 后做"联系人回复 Y 才确认" | 架构 | L (外部 1-2w) | P2 (卡 A-01) |
| 1.3.7 | **PIPL §38 跨境** | ✅ | `privacy_policy.md:132-176` 完整 §11 跨境说明 (紧急联系人境外号段时走 SMS provider 备案) | 底层 | - | - |
| 1.3.8 | **文档未过审** | 🔴 P0 | 3 份 md 头部均标 "草稿 (Sprint 1 修订) — 未经律师过审"。Apple 5.1.1 明确"隐私政策必须清晰 + 当前生效", 草稿状态必拒 | 底层 | L (法务 4w) | **P0** |
| 1.3.9 | **年龄 14+ 声明** | ✅ R83 | setup 第 4 步"年龄严正声明" (本人郑重承诺已年满 18 周岁) + `privacy_policy.md:120-124` 14 周岁以下不适用 | 架构 | - | - |
| 1.3.10 | **§5.1.1(iv) 收集通知** | ✅ | `NSPrivacyCollectedDataTypes` 完整 4 类 + Purpose=AppFunctionality 显式标注 | 底层 | - | - |

**1.3 维度小结**: 60% 就绪, 剩 4 个 P0 (1.3.1 / 1.3.2 / 1.3.8) + 2 个 P1 (1.3.3 / 1.3.5)。

---

### 1.4 内购 / 订阅 (§3.1.5)

| # | 问题 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|------|------|------|------|------|--------|
| 1.4.1 | **数字商品 / 服务必须走 IAP** | 🔴 P0 阻塞 (描述 vs 实际) | `assets/legal/user_agreement.md:25` 写"售价人民币 8 元 / 一次性买断", 但 `lib/core/data/feature_flags.dart:38` `_prodIapEnabled = false` (R68 软隐藏) + `lib/core/data/services/store_kit_service.dart:119` `buyLifetime()` release 返 `false`。**3.1.5 + 2.1.4 双面风险** | 架构 + 底层 | L (1-2w) | **P0** |
| 1.4.2 | **productId 必须 App Store Connect 创建** | 🔴 P0 | `store_kit_service.dart:50` `kLifetimeProductId = 'com.chroniccare.app.lifetime'` — App Store Connect 0 商品, 审核员查不到 | 底层 | S (App Store Connect 5min) | **P0** |
| 1.4.3 | **Restore Purchase 按钮** | 🔴 P0 | `lib/presentation/pages/settings/` grep 0 `Restore` 调用。Apple 3.1.5 强制 Non-Consumable 必须有 restore 入口 | 架构 | S (UI + StoreKit restore 0.5d) | **P0** |
| 1.4.4 | **订阅条款链接** | ✅ 不需要 | 项目走 Non-Consumable 一次性买断, 非订阅, 不需订阅条款 | 底层 | - | - |
| 1.4.5 | **IAP receipt 验证** | 🟡 未做 | `store_kit_service.dart` 仅本地 SharedPreferences 缓存 `_proCache`, 无 receipt 验证。Apple 3.1.5 强烈建议 (非必须) 走服务端 verify | 架构 | M (1-2d 写 verify endpoint) | P2 |
| 1.4.6 | **in_app_purchase plugin 升级** | 🟡 stale comment | `pubspec.yaml:63` 实际 `in_app_purchase: ^3.3.0`, 但 `store_kit_service.dart:9` 注释"pubspec 加 in_app_purchase: ^7.0.0" (R65 时估计的, 实际真接时 v3.3.0 兼容) | 底层 | S (改注释) | P3 |
| 1.4.7 | **Family Sharing** | 🟡 默认 false | `store_kit_service.dart` productId 走 Non-Consumable 默认不可 Family Share, OK | 底层 | - | - |
| 1.4.8 | **Sandbox 测试** | 🔴 未做 | 0 sandbox tester 配置, 0 IAP 测试文档 | 底层 | M (1d) | **P0** (IAP 真接后) |

**1.4 维度小结**: 10% 就绪, 剩 5 个 P0 (1.4.1 启用 IAP / 1.4.2 创建 productId / 1.4.3 Restore 按钮 / 1.4.8 sandbox 测试) + 1 个 P2 (1.4.5 receipt 验证)。

---

### 1.5 内容审核 (§1.4.1 / §1.5 / §4.0)

| # | 问题 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|------|------|------|------|------|--------|
| 1.5.1 | **不能给出医疗建议** | ✅ | `fastlane/metadata/ios/en-US/description.txt:38` "ChronicCare is NOT a medical device and does not provide medical advice, diagnosis, or treatment" + `user_agreement.md:17,21,44` 同步 + `sensitive_data_consent.md` §4 | 底层 | - | - |
| 1.5.2 | **UGC (User Generated Content) 树洞** | 🟡 部分 | 树洞 (vent) 是 UGC, 但项目设计**全本地不分享**, 无"举报/过滤"机制需求。Apple 1.4.1 主要针对"云端 UGC" (社交/评论), 本项目 UGC 不离开设备, OK | 架构 | - | - |
| 1.5.3 | **危机信号: 危机干预热线** | ✅ | en-US: US 988 + UK 116 123 + International; zh-Hans: 北京 010-82951332 + 全国 400-161-9995 + 上海 021-12320-5; zh-Hant: 台灣 1925 + 香港 2389 2222 + International; R83 律师审核后 5 条本地区 (大陆 2 + 港澳台 3) 在 `setup_legal_dialog.dart:74-124` 展示 | 架构 | - | - |
| 1.5.4 | **树洞隐私边界** | ✅ | vent 0 notification / 0 trend / 0 care engine / 0 export (PIPL 合规) | 架构 | - | - |
| 1.5.5 | **PHQ-9 / GAD-7 严重度阈值 + 危机资源** | ✅ | R50 R51b 21 case test, 高分 (>15) 弹危机资源卡片 | 架构 | - | - |
| 1.5.6 | **儿童 (14 周岁以下) 误用处理** | ✅ R83 | `privacy_policy.md:120-124` 监护人可发起数据删除请求, 7 工作日内处理 | 架构 | - | - |
| 1.5.7 | **题目 (PHQ-9 / GAD-7) 走 ARB** | 🟡 部分 | R78 PHQ-9 / GAD-7 48 ARB keys, R90 加 8 新量表 134 keys, R91 加 7 子功能 73 keys。**8 量表题目全文 (~70 题) 留 v1.0 翻译**, `AppLocalizationsScaleTranslations` stub 返 `''` 兜底, 走 const class 中文 — en/zh_Hant 用户看 const 题目 (也是中文) | 架构 | L (1-2w 法务+临床翻译) | P2 |
| 1.5.8 | **错别字 / 病耻感文案** | ✅ R72 R75 R77 | R72+R75+R77 5+1 鼓励文案中性化, 树洞/心情日记/能量加油站 | 架构 | - | - |

**1.5 维度小结**: 95% 就绪, 剩 1 个 P2 (1.5.7 题目全文 v1.0 翻译)。

---

### 1.6 健康类 App 额外审查 (§1.4.1 / §5.2 / §5.1.5)

| # | 问题 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|------|------|------|------|------|--------|
| 1.6.1 | **HealthKit 接入?** | ✅ 不接 | 项目 PHQ-9 / GAD-7 是自评量表, 不入 HealthKit; 精神心理数据全在 SQLCipher | 架构 | - | - |
| 1.6.2 | **"医疗 / 诊断 / 治疗" 字眼** | ✅ 已规避 | `description.txt:38` + `user_agreement.md` 全文 grep "diagnose/diagnosis/treat/cure/medical device" — **0 命中** | 底层 | - | - |
| 1.6.3 | **"Mental Health / Psychiatric" 标签慎重** | ✅ | App Store Connect Primary Category = Medical (跟 `LSApplicationCategoryType=healthcare-fitness` 对应) | 底层 | - | - |
| 1.6.4 | **"Medication Reminder" vs "Medication Tracker"** | ✅ | 副标题 = "Medication + Mood Tracker" (Tracker 非 Adherence App, 规避 FDA 风险) | 底层 | - | - |
| 1.6.5 | **NMPA 备案** | 🔴 P0 阻塞 (外部) | 精神心理 App 涉及"医疗信息"按 4.3 (a) / 4.3.4 需走医疗器械备案 / NMPA 备案。`user_agreement.md:21` 已声明"非医疗器械" + "不提供医疗建议" ✓, 但**未走 NMPA 咨询** | 底层 | L (外部 4-8w) | **P0** (法务) |
| 1.6.6 | **"FDA / NMPA 监管" 正确规避** | ✅ | 4.0 Design 评估, App 自定位"个人记录工具"非"医疗器械", 未声明诊断/治疗/治愈, 正确规避 FDA/NMPA | 底层 | - | - |
| 1.6.7 | **Clinical Health Records 接入** | ✅ 不接 | 无 HealthKit 自然无 Clinical Health Records | 底层 | - | - |
| 1.6.8 | **App Review 备注: 精神心理 + 医疗 + 失联通知** | 🟡 待写 | App Store Connect "App Review Information" 字段需填测试账号 + 备注, 0 占位文件 | 底层 | M (写 1 段) | P1 |

**1.6 维度小结**: 60% 就绪, 剩 1 个 P0 (1.6.5 NMPA 备案外部) + 1 个 P1 (1.6.8 App Review 备注)。

---

### 1.7 紧急功能 (§5.1.5 / §2.1.4)

| # | 问题 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|------|------|------|------|------|--------|
| 1.7.1 | **Critical Alert entitlement** | ✅ 不需要 | 项目失联通知走"温柔提醒"措辞, **不是 Critical Alert** (不被静音/勿扰拦截)。Apple Critical Alert 需要 `com.apple.developer.usernotifications.critical-alerts` entitlement, 申请极严 | 底层 | - | - |
| 1.7.2 | **紧急联系人功能过度调用系统?** | 🟡 | `lib/presentation/pages/contact/` 仅调 `tel:` URL Scheme 拨打电话, **不调系统 API** (不读通讯录); iOS 不需 `LSApplicationQueriesSchemes` 因为是 `tel:` 通用 scheme | 底层 | - | - |
| 1.7.3 | **失联通知业务暂停** | 🔴 P0 (业务) | `FeatureFlags._prodEmergencyContactEnabled = false` (R66 起) + `AliyunSmsProvider.send()` 抛 `StateError` (sms_service.dart:163) → release 永远不发。`description.txt:14-16` 已写"currently disabled" 透明声明, 但 Apple 2.1.4 "App 与描述不符" 风险 | 架构 + 底层 | XL (外部 4-8w 法务 + 阿里云) | **P0** |
| 1.7.4 | **BGTaskScheduler handler 空实现** | 🟡 | `AppDelegate.swift:73` `task.setTaskCompleted(success: true)` 立即返, 不真触发失联检测。设计决策 (业务暂停), OK | 底层 | - | - |
| 1.7.5 | **失联通知 UI 3 态分流** | ✅ R60 | `SmsDispatchOutcome` + `_resolveSafetyAlertBody` + 3 i18n key | 架构 | - | - |
| 1.7.6 | **PIPL §23 单独同意"已告知并取得同意"** | 🟡 R58 软实施 | 用户主动告知担保, 联系人本人**没独立确认通道** (v1.0 真接阿里云 SMS 后做"联系人回复 Y 才确认") | 架构 | L (外部 1-2w) | P2 (卡 A-01) |

**1.7 维度小结**: 50% 就绪, 剩 1 个 P0 (1.7.3 失联通知真接外部)。

---

## 2. iOS 平台规范

### 2.1 启动 / Splash / App Icon

| # | 问题 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|------|------|------|------|------|--------|
| 2.1.1 | **LaunchScreen.storyboard 配置** | 🟡 默认 | `ios/Runner/Base.lproj/LaunchScreen.storyboard:1-37` 用纯白色背景 + LaunchImage.png 居中, 无品牌色/App 名/icon | 底层 | S | P1 |
| 2.1.2 | **AppIcon 完整性 (1024x1024 marketing)** | 🟡 Flutter 默认 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` 10932 字节 — `flutter create` 默认图 (蓝白圆角矩形), **不是品牌图标** | 底层 | M (设计师 1-2d) | P1 |
| 2.1.3 | **AppIcon 所有 size 完整** | ✅ | `Assets.xcassets/AppIcon.appiconset/Contents.json:1-121` 列 18 个 size (iPhone 20/29/40/60 × 1x/2x/3x + iPad 20/29/40/76/83.5 + ios-marketing 1024) 全有 PNG | 底层 | - | - |
| 2.1.4 | **Dark Mode App Icon (iOS 18+ 必填)** | 🔴 缺失 | iOS 18 (2024-09 发布) 强制要求 Dark / Tinted / Clear 4 种风格 AppIcon。本项目只有 1 套 1024×1024 | 底层 | M (设计师 2-3d) | **P0** (iOS 18+ 上架) |
| 2.1.5 | **LaunchImage 占位** | 🔴 P0 | `Assets.xcassets/LaunchImage.imageset/LaunchImage.png` 68 字节占位 (R69 报告同款), iPhone 启动时**显示 1×1 黑屏 0.5s** | 底层 | S (删 3 个 + 改 storyboard) | **P0** |
| 2.1.6 | **启动时间** | ✅ | `main.dart:107-245` runZonedGuarded + 1.5s bootstrap, R62 评估 OK | 架构 | - | - |
| 2.1.7 | **iPhone 6.5" 启动图 vs iOS 18 LaunchScreen** | ✅ | iOS 14+ 推荐用 storyboard 启动图 (本项目已用), 不依赖 LaunchImage.imageset。`UILaunchStoryboardName = LaunchScreen` (Info.plist:107) ✓ | 底层 | - | - |

**2.1 维度小结**: 50% 就绪, 剩 2 个 P0 (2.1.4 Dark Mode App Icon / 2.1.5 LaunchImage 占位) + 2 个 P1 (2.1.1 LaunchScreen 品牌化 / 2.1.2 AppIcon 重做)。

---

### 2.2 Background Mode / 后台任务

| # | 问题 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|------|------|------|------|------|--------|
| 2.2.1 | **UIBackgroundModes = audio** | ✅ | `Info.plist:146` audio (录音时允许后台继续, 切到后台录音不中断) | 底层 | - | - |
| 2.2.2 | **UIBackgroundModes = processing** | ✅ (R62) | `Info.plist:147` processing (替代 iOS 13+ 弃用的 `fetch`) | 底层 | - | - |
| 2.2.3 | **BGTaskSchedulerPermittedIdentifiers** | ✅ (R62) | `Info.plist:153-156` `com.chroniccare.safety-check` — 跟 `AppDelegate.swift:33` `BGTaskScheduler.shared.register(forTaskWithIdentifier:using:launchHandler:)` 一致 | 底层 | - | - |
| 2.2.4 | **BGTaskScheduler handler 实现** | 🟡 占位 | `AppDelegate.swift:72-74` `private func handleSafetyCheckTask(task: BGProcessingTask) { task.setTaskCompleted(success: true) }` 空实现, 因业务暂停 (FeatureFlags.emergencyContactEnabled=false)。Apple 2.1.4 "功能描述必真", 业务真接时必须真实现 | 架构 | L (1w) | P2 |
| 2.2.5 | **APNs 远程推送** | ✅ 故意不加 | 不用远程推送, 走本地通知 (`flutter_local_notifications: ^17.2.3`)。`Runner.entitlements` 空 dict, R70 注释说明 | 底层 | - | - |
| 2.2.6 | **Background fetch (iOS 13+ 弃用)** | ✅ 已删 | `Info.plist` 无 `fetch`, 改走 `processing` | 底层 | - | - |
| 2.2.7 | **Background Processing (BGTaskScheduler)** | ✅ | `BGProcessingTask` 走 `processing` background mode, 失联检测可用 | 底层 | - | - |
| 2.2.8 | **audio 后台播放 (树洞 audio 回放)** | ✅ | `UIBackgroundModes audio` + `audioplayers: ^6.1.0` 走 AVAudioSession 配 `playback` category (待验证) | 架构 | S (验证 0.5d) | P2 |

**2.2 维度小结**: 80% 就绪, 剩 2 个 P2 (2.2.4 真接业务时 / 2.2.8 AVAudioSession 验证)。

---

### 2.3 通知 (UNUserNotificationCenter)

| # | 问题 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|------|------|------|------|------|--------|
| 2.3.1 | **UNUserNotificationCenter 配置** | ✅ (R67) | `AppDelegate.swift:22-24` `UNUserNotificationCenter.current().delegate = self` | 底层 | - | - |
| 2.3.2 | **UNUserNotificationCenterDelegate 实现** | ✅ (R75) | `AppDelegate.swift:54-61` `userNotificationCenter(_:willPresent:withCompletionHandler:)` 返 `[.banner, .list, .sound, .badge]` (R75 修过 R67 `as?` 强转 delegate=nil 静默 bug) | 底层 | - | - |
| 2.3.3 | **Critical Alert entitlement** | ✅ 不需要 | 失联通知走"温柔提醒"措辞, 不是 Critical Alert, 不需 entitlement | 底层 | - | - |
| 2.3.4 | **通知 Category / Action** | 🟡 未配 | `flutter_local_notifications` 默认无 category, 失联通知/打卡提醒只 banner 不带 action (e.g. "我已吃药" / "稍后提醒") | 架构 | M (1d) | P2 |
| 2.3.5 | **Quiet Hours / Focus Filter** | 🟡 | `lib/core/data/services/safety_config_service.dart` 有 DND 配置 (R62 P1-5 抽单一 source), UI 入口在 settings/reminders_hub。Apple iOS Focus 是系统级, 项目只能遵循系统设定 (不打扰时段跳过通知) | 架构 | S | P2 |
| 2.3.6 | **通知权限申请时机** | 🟡 | `notification_service.dart:init` 调 `requestPermissions`, 用户首次启动立即弹 — 符合 Apple 2.1 规范 (不要 "in context" 弹), 但**没"稍后提醒"选项** | 架构 | S | P2 |
| 2.3.7 | **iOS 17+ 通知交互** | ✅ | `flutter_local_notifications: ^17.2.3` 支持 iOS 17 banner / list / badge | 底层 | - | - |

**2.3 维度小结**: 85% 就绪, 剩 3 个 P2 (2.3.4 Action / 2.3.5 Focus 验证 / 2.3.6 权限时机)。

---

### 2.4 音频 (AVAudioSession)

| # | 问题 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|------|------|------|------|------|--------|
| 2.4.1 | **AVAudioSession category 配置** | 🟡 待验证 | `record: ^5.2.0` 录音时配 `record` category, `audioplayers: ^6.1.0` 播放时配 `playback` category, **没在 Dart 显式配 `playAndRecord`** (iOS 录音+播放时正确做法)。录制时回放, iOS 默认会中断 | 架构 | S (0.5d 验证) | P2 |
| 2.4.2 | **Background Audio entitlement** | ✅ | `UIBackgroundModes audio` ✓, 但 `audioplayers` 默认不申请 "Background Audio" capability, 需在 audioplayers 配置中显式声明 | 底层 | S | P2 |
| 2.4.3 | **NSMicrophoneUsageDescription** | ✅ | `Info.plist:42-43` 已声明, 真机首次录音弹权限框 | 底层 | - | - |
| 2.4.4 | **音频中断处理 (interrupt notification)** | 🟡 未做 | `AVAudioSession.interruptionNotification` 监听 (电话来电 / Siri / 闹钟) 没注册, iOS 录音/播放被中断时不会自动恢复 | 架构 | M (1d) | P2 |
| 2.4.5 | **AirPods / Bluetooth route change** | 🟡 未做 | `AVAudioSession.routeChangeNotification` 没监听, 蓝牙耳机断开时音频不回落到 speaker | 架构 | S (0.5d) | P3 |
| 2.4.6 | **Now Playing Info Center (锁屏控制)** | 🟡 未做 | `audioplayers` 默认不填 `MPNowPlayingInfoCenter`, 锁屏看不到树洞 audio 播放信息, 不可控制 | 架构 | M (1d) | P3 (体验) |
| 2.4.7 | **iOS 16+ Live Activity (锁屏活动)** | 🟡 未做 | 失联通知 / 打卡提醒可走 Live Activity 提升可见度, 但需 `NSSupportsLiveActivities` Info.plist + ActivityKit (Dart 端 `flutter_live_activity` plugin), 0 实现 | 架构 | L (1w) | P2 |

**2.4 维度小结**: 30% 就绪, 缺 6 项中等级别 P2/P3 (2.4.1-2.4.7)。

---

### 2.5 文件 / 存储 (iOS 沙盒 / Keychain)

| # | 问题 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|------|------|------|------|------|--------|
| 2.5.1 | **iOS 沙盒路径 (Documents / Library / tmp)** | ✅ | `path_provider: ^2.1.4` + Drift 自动选 `<Documents>/chroniccare.db` (iOS 真机), SQLite 沙盒 | 底层 | - | - |
| 2.5.2 | **SQLCipher 数据库加密** | ✅ | `sqlcipher_flutter_libs: ^0.6.5` (R82 升 0.6.5+ 满足 Google Play 2025-11 16KB page size) | 底层 | - | - |
| 2.5.3 | **DB 密钥管理 (Keychain)** | ✅ | `lib/core/data/services/db_key_service.dart` + `flutter_secure_storage: ^9.2.2` iOS 走 Keychain (kSecAttrAccessibleAfterFirstUnlock) | 底层 | - | - |
| 2.5.4 | **iCloud Backup 排除** | 🟡 未做 | `<Documents>/chroniccare.db` 默认被 iCloud Backup 包含, 精神心理患者敏感数据走云端 = 隐私风险。需加 `kCFURLIsExcludedFromBackupKey` 标记 `NSURLIsExcludedFromBackupKey` | 架构 | S (0.5d) | **P0** (隐私) |
| 2.5.5 | **音频文件加密 (树洞 / 情绪语音)** | ✅ | `pointycastle: ^3.9.1` AES-256 字段级加密, R62 已修 file 上 DB 元数据加密 | 底层 | - | - |
| 2.5.6 | **iOS 11+ Data Protection** | 🟡 待验证 | NSFileProtectionComplete 标记没显式设, iOS 锁屏时 DB 默认 `<Documents>` 仍可访问, 真机锁屏后精神心理数据应不可读 | 架构 | S (0.5d) | P1 (隐私) |

**2.5 维度小结**: 60% 就绪, 剩 1 个 P0 (2.5.4 iCloud Backup 排除) + 1 个 P1 (2.5.6 Data Protection)。

---

### 2.6 数据库迁移 (drift onUpgrade)

| # | 问题 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|------|------|------|------|------|--------|
| 2.6.1 | **drift schemaVersion 当前** | ✅ 12 | `lib/core/data/database/app_database.dart` schemaVersion=12, 12 个表 + 全部 migration 完备 | 架构 | - | - |
| 2.6.2 | **onUpgrade 完备** | ✅ | AGENTS.md "schemaVersion 升级漏 migration = 老用户升级会崩" 已有守门 | 架构 | - | - |
| 2.6.3 | **schemaVersion 跳变 / 备份回滚** | ✅ | `lib/core/data/services/database_migration.dart` 有 `migrateIfNeeded` + `MigrationException`, `main.dart:130-145` 弹确认 dialog | 架构 | - | - |
| 2.6.4 | **iCloud 恢复后数据冲突** | 🟡 | iCloud Backup 排除后, 用户换机/重装需走 in-app JSON export/import (已有) | 架构 | - | - |

**2.6 维度小结**: 100% 就绪。

---

### 2.7 Performance

| # | 问题 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|------|------|------|------|------|--------|
| 2.7.1 | **Flutter Engine 启动时间** | ✅ | R62 评估 1.5s bootstrap OK, < iPhone 推荐 400ms 是冷启动后续 | 架构 | - | - |
| 2.7.2 | **Drift 启动时间** | ✅ | `AppDatabase()` 单例, R62 P0 修复避免 provider tree 双连接 | 架构 | - | - |
| 2.7.3 | **60fps / 120fps ProMotion** | ✅ | `CADisableMinimumFrameDurationOnPhone = true` (Info.plist:5) 启用 120Hz | 底层 | - | - |
| 2.7.4 | **Memory footprint** | 🟡 未做 profile | 无 DevTools 跑过 release build, 无 baseline | 架构 | M (1d 跑 DevTools) | P2 |
| 2.7.5 | **audioplayers 资源泄漏** | ✅ | v0.16 R19B 已知坑 + R62 widget_dispose 守门员检测 | 架构 | - | - |
| 2.7.6 | **Stream subscription leak** | ✅ | 同上 R62 守门员 | 架构 | - | - |
| 2.7.7 | **大 JSON 导出内存峰值** | 🟡 | `data_export_service` 导出全表 JSON, 用户记录多时 (几万条) 可能 OOM | 架构 | M (1d stream + chunk) | P2 |

**2.7 维度小结**: 80% 就绪, 剩 2 个 P2 (2.7.4 Memory profile / 2.7.7 大 JSON)。

---

### 2.8 可访问性 (Accessibility)

| # | 问题 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|------|------|------|------|------|--------|
| 2.8.1 | **VoiceOver label / hint** | 🟡 部分 | `lib/presentation/widgets/` 抽查 `Semantics(label:)` 调用**散落**, 无统一 SemanticsHelper | 架构 | L (3-5d 全量补) | P1 |
| 2.8.2 | **Dynamic Type (字体缩放)** | 🟡 部分 | 用 Material 3 默认 `textScaler`, 但部分 `Text('...', style: const TextStyle(fontSize: 14))` 硬编 size 不响应 Dynamic Type | 架构 | M (2-3d 改 tokens) | P1 |
| 2.8.3 | **Reduce Motion** | 🟡 未做 | emil 动效 token 4 curve 走 `Curves.easeInOut` 等, **没监听 `MediaQuery.disableAnimations`**, Reduce Motion 用户看完整动画 | 架构 | S (0.5d) | P1 |
| 2.8.4 | **Increase Contrast** | 🟡 未做 | 主题硬编颜色, 没监听 `MediaQuery.highContrast` | 架构 | S (0.5d) | P2 |
| 2.8.5 | **颜色对比度 (WCAG AA)** | 🟡 待验证 | `AppTokens` 颜色对未做 WCAG AA 校验, 灰背景 + 灰文字可能不过 4.5:1 | 架构 | M (1d audit) | P1 |
| 2.8.6 | **Accessibility Inspector** | 🔴 未跑过 | 0 Accessibility Inspector 跑过, Apple 4.0 Design 扣分 | 架构 | M (1d) | P1 |

**2.8 维度小结**: 20% 就绪, 缺 6 项 P1 (2.8.1-2.8.6) — 精神心理 App 用户尤其需要可访问性。

---

## 3. iOS 工程配置

| # | 问题 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|------|------|------|------|------|--------|
| 3.1 | **Info.plist 完整性** | ✅ 95% | 已 7 个 NSUsageDescription + ITSAppUsesNonExemptEncryption + UIBackgroundModes + BGTaskSchedulerPermittedIdentifiers + LSApplicationCategoryType + InfoPlist.strings per-locale。**剩 1 个**: NSFaceIDUsageDescription 防御性缺失 (1.2.12) | 底层 | S | P1 |
| 3.2 | **Podfile 完整性** | 🔴 P0 占位 | `ios/Podfile:1-7` 注释"本 Podfile 是占位 (Windows 平台无法跑 `pod install`), 首次 macOS build 必须重新生成"。当前是 Flutter 标准模板, 没 SQLCipher / flutter_secure_storage / share_plus / printing / pdf / fl_chart / flutter_local_notifications / record / audioplayers / speech_to_text / in_app_purchase / sqlcipher_flutter_libs 任何 plugin 真实 Podfile.lock | 底层 | M (Mac 跑 0.5d) | **P0** |
| 3.3 | **Runner.xcodeproj bundle id** | 🟡 | `com.chroniccare.chroniccare` (Info.plist 引用) — `fastlane/Appfile:19` 一致。但**不是标准 reverse-DNS** (应为 `com.chroniccare.app` / `com.chroniccare`)。Apple 锁 bundle id, 趁现在改 | 底层 | S (改 6 处 build config) | P1 |
| 3.4 | **Runner.xcodeproj team / signing** | 🟡 | `ios/Runner.xcodeproj/project.pbxproj` grep `DEVELOPMENT_TEAM` 0 命中 (R69 报告 `Debug.xcconfig` 也无), 上 store 前必填 | 底层 | S (1h) | **P0** |
| 3.5 | **最低 iOS 版本 (deployment target)** | ✅ 14.0 | `project.pbxproj:372,499,550` `IPHONEOS_DEPLOYMENT_TARGET = 14.0`, 符合 Apple 2024 推荐 | 底层 | - | - |
| 3.6 | **Universal App (iPhone + iPad)** | ✅ | `project.pbxproj:376,503,556` `TARGETED_DEVICE_FAMILY = "1,2"` | 底层 | - | - |
| 3.7 | **iPad 多任务** | ✅ | `Info.plist:74-75` `UIRequiresFullScreen = false` + SceneDelegate.swift 4 行 | 底层 | - | - |
| 3.8 | **App Clip** | ✅ 不需要 | 项目无独立 App Clip 需求 | 底层 | - | - |
| 3.9 | **Widget Extension / Live Activity** | 🟡 未做 | iOS 16+ Live Activity 可提升失联通知 / 打卡提醒可见度, 需 `NSSupportsLiveActivities` + `flutter_live_activity` plugin, 0 实现 | 架构 | L (1-2w) | P2 |
| 3.10 | **Runner.entitlements 文件** | ✅ (R62) | `ios/Runner/Runner.entitlements:0-12` 空 dict (R70 注释"无 APNs 远程推送"), `project.pbxproj:390,570,593` `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` 配好 | 底层 | - | - |
| 3.11 | **SUPPORTED_PLATFORMS** | ✅ (R61) | `project.pbxproj:375,553` `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"` | 底层 | - | - |
| 3.12 | **EXCLUDED_ARCHS** | ✅ | `ios/Flutter/Generated.xcconfig:9-10` `EXCLUDED_ARCHS[sdk=iphonesimulator*]=i386` + `[sdk=iphoneos*]=armv7` (Apple Silicon Mac arm64 simulator OK) | 底层 | - | - |
| 3.13 | **ENABLE_BITCODE** | ✅ | `project.pbxproj:388,568,591` `ENABLE_BITCODE = NO` (Apple 2017 起弃用, Flutter 默认 NO) | 底层 | - | - |
| 3.14 | **64-bit (arm64)** | ✅ | Flutter 3.41 默认 arm64 only | 底层 | - | - |
| 3.15 | **SceneDelegate** | ✅ | `ios/Runner/SceneDelegate.swift:1-4` 4 行 `class SceneDelegate: FlutterSceneDelegate` (Flutter 3.41+ Scene Manifest) | 底层 | - | - |
| 3.16 | **AppDelegate UNUserNotificationCenter** | ✅ (R75) | `AppDelegate.swift:7,22-24,54-61` conform + 设 delegate + 实现 willPresent (R75 修 R67 `as?` 强转 bug) | 底层 | - | - |
| 3.17 | **Main.storyboard 兼容** | ✅ (R70) | 保留 `Base.lproj/Main.storyboard` (Scene 模式 UISceneStoryboardFile=Main 引用) | 底层 | - | - |
| 3.18 | **InfoPlist.strings per-locale** | ✅ (R70-R77) | `Base.lproj/InfoPlist.strings` (R77 兜底 "ChronicCare") + `zh-Hans.lproj/InfoPlist.strings` ("慢病管家") + `zh-Hant.lproj/InfoPlist.strings` ("慢病管家"), project.pbxproj 引用 4 个 PBXVariantGroup | 底层 | - | - |
| 3.19 | **fastlane/Appfile 4 处 TODO** | 🔴 P0 | `fastlane/Appfile:21,23,25` `apple_id("your-apple-id@example.com")` / `team_id("YOUR_TEAM_ID")` / `itc_team_id("YOUR_ITC_TEAM_ID")` 全占位 | 底层 | S (1h) | **P0** |
| 3.20 | **fastlane/Fastfile 完整性** | ✅ 75% | 3 lane (beta / release / metadata) + Android 块完整, R70 加 Android 端, `automatic_release = false` 手动控制 | 底层 | - | - |

**3 维度小结**: 75% 就绪, 剩 5 个 P0 (3.2 Podfile / 3.4 team / 3.19 fastlane TODO / 1.1.4 / 1.1.5 / 1.6.5 重复计入 1.x)。

---

## 4. 上架材料 (App Store Connect)

| # | 项 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|----|------|------|------|------|--------|
| 4.1 | **App 名 (en)** | ✅ | `fastlane/metadata/ios/en-US/name.txt:1` "ChronicCare" (29 字符内 OK) | 底层 | - | - |
| 4.2 | **App 名 (zh-Hans)** | ✅ | `fastlane/metadata/ios/zh-Hans/name.txt:1` "慢病管家" (mojibake 但内容对, 4 字符 OK) | 底层 | - | - |
| 4.3 | **App 名 (zh-Hant)** | ✅ | `fastlane/metadata/ios/zh-Hant/name.txt:1` "慢病管家" (mojibake, OK) | 底层 | - | - |
| 4.4 | **副标题 (en)** | ✅ | `fastlane/metadata/ios/en-US/subtitle.txt:1` "Medication + Mood Tracker" (29 字符内 OK) | 底层 | - | - |
| 4.5 | **副标题 (zh-Hans)** | ✅ | "吃药打卡 + 情绪关怀(失联通知规划中)" 透明声明失联通知未上, OK | 底层 | - | - |
| 4.6 | **副标题 (zh-Hant)** | ✅ | "吃藥打卡 + 情緒關懷(失聯通知規劃中)" OK | 底层 | - | - |
| 4.7 | **描述 (en)** | 🟡 描述 vs 实际 | `description.txt:14-16` "Lost-contact safety net (coming soon — currently disabled)" 标"会发短信"+ 详细说"会发" — **实际 `FeatureFlags.emergencyContactEnabled=false` + `AliyunSmsProvider.send()` 抛 StateError** = 永远不发。**2.1.4 风险** | 底层 | S (改文案) | **P0** |
| 4.8 | **描述 (zh-Hans)** | 🟡 同上 | 同步需改 | 底层 | S | **P0** |
| 4.9 | **描述 (zh-Hant)** | 🟡 同上 | 同步需改 | 底层 | S | **P0** |
| 4.10 | **关键词 (en)** | ✅ | `keywords.txt:1` "medication,reminder,mood,mental,health,chronic,tracker" (62 字符内 OK) | 底层 | - | - |
| 4.11 | **关键词 (zh-Hans)** | ✅ | "吃药,提醒,情绪,心理,健康,慢病,打卡" (23 字符) | 底层 | - | - |
| 4.12 | **关键词 (zh-Hant)** | ✅ | "吃藥,提醒,情緒,心理,健康,慢病,打卡" (24 字符) | 底层 | - | - |
| 4.13 | **促销文本 (en)** | ✅ | `promotional_text.txt:1` 152 字符 OK (170 字符内) | 底层 | - | - |
| 4.14 | **促销文本 (zh-Hans)** | ✅ | 60 字符 | 底层 | - | - |
| 4.15 | **促销文本 (zh-Hant)** | ✅ | 60 字符 | 底层 | - | - |
| 4.16 | **版权** | ✅ | `copyright.txt:1` "© 2026 chroniccare" (zh-Hans "© 2026 慢病管家") | 底层 | - | - |
| 4.17 | **类别 (Primary)** | 🟡 待选 | `LSApplicationCategoryType=healthcare-fitness` (Info.plist:136) → App Store Connect 选 Medical 主类 + Health & Fitness 副类 (R62 评估) | 底层 | S | P1 |
| 4.18 | **年龄分级** | 🟡 待评估 | 精神心理 App 推荐 17+, 实际可能 12+。无 UGC, 无真实社交, 无位置, 无广告 → 估算 12+, 需 App Store Connect 答问卷 | 底层 | S (1h 答问卷) | P1 |
| 4.19 | **6.7" 截图 (iPhone 15/16 Pro Max 1290×2796)** | 🔴 P0 | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/iphone_6_5_screenshots/*.png` 5 张 × 3 locale = 15 张, **67 字节占位** (实测 1232×720 比例错, IDAT 10 字节 = 1×1 像素 PNG) | 底层 | L (设计师 + Mac 截图 2-3d) | **P0** |
| 4.20 | **6.5" 截图 (iPhone 11 Pro Max 1242×2688)** | 🔴 P0 | 同上, 15 张全占位 | 底层 | L | **P0** |
| 4.21 | **5.5" 截图 (iPhone 8 Plus 1242×2208)** | 🔴 P0 | `iphone_5_5_screenshots/*.png` 3 × 3 locale = 9 张全占位 | 底层 | L | **P0** |
| 4.22 | **iPad 12.9" 截图 (2048×2732)** | 🔴 P0 | `ipad_12_9_screenshots/*.png` 3 × 3 locale = 9 张全占位 | 底层 | L | **P0** |
| 4.23 | **App Store Icon 1024×1024** | 🔴 P0 | `app_icon.png` (fastlane) 3 × 67 字节占位 (跟 ios/Runner 10932 字节 Flutter 默认图**不同** — fastlane 走 Connect 走的是 app_icon.png 单独字段) | 底层 | L | **P0** |
| 4.24 | **App Preview 视频** | ✅ 不必须 | Apple 不强制, 跳过 OK | 底层 | - | - |
| 4.25 | **TestFlight 测试账号** | 🟡 | 0 sandbox tester 配置文档 | 底层 | S (1h) | **P0** (IAP 真接) |
| 4.26 | **测试账号 (App Review)** | 🟡 | 0 占位文件 `App Store Connect → App Review Information` 待写 (无账号系统, 但需"test mode" 流程描述) | 底层 | S (1h) | **P0** |
| 4.27 | **Demo 数据 / Demo 视频** | 🟡 | 无占位 | 底层 | M (1-2d) | P1 |

**4 维度小结**: 50% 就绪, 剩 8 个 P0 (4.7-4.9 描述改 / 4.19-4.23 截图+icon 5 类 / 4.25-4.26 测试账号) + 3 个 P1 (4.17 类别 / 4.18 年龄分级 / 4.27 Demo)。

---

## 5. 已知 iOS 坑

| # | 坑 | 现状 | 证据 | 类型 | 难度 | 优先级 |
|---|----|------|------|------|------|--------|
| 5.1 | **iOS 16+ Live Activity** | 🟡 未做 | 失联通知 / 打卡提醒可走 ActivityKit, 0 实现, 无 `NSSupportsLiveActivities` Info.plist key | 架构 | L (1-2w) | P2 |
| 5.2 | **iOS 17+ Interactive Widget** | ✅ 不需要 | 项目无 Widget Extension | 底层 | - | - |
| 5.3 | **iOS 18+ 控制中心交互** | ✅ 不需要 | 项目无控制中心集成 | 底层 | - | - |
| 5.4 | **iOS 18+ Apple Intelligence** | ✅ 不需要 | 项目无 AI 集成 (R89 AI rolledback) | 底层 | - | - |
| 5.5 | **TestFlight 内测流程** | 🟡 未跑 | 无 Mac 跑过 build, 0 内部测试轮次 | 架构 | M (1-2w) | **P0** |
| 5.6 | **iOS 18+ Dark Mode App Icon** | 🔴 P0 | 见 2.1.4 | 底层 | M | **P0** |
| 5.7 | **iOS 18+ Sensitive Content Analysis** | 🟡 | Apple 强制开发者声明 app 是否含 sensitive content (mental health 是), 需 App Store Connect "Sensitive Content" 字段勾选 | 底层 | S (答问卷) | P1 |
| 5.8 | **iOS 18+ Privacy Manifest 强化** | ✅ R61+R67 完整 | 5 类 accessed API + 4 类 collected data, 2024-05 强制项全 | 底层 | - | - |
| 5.9 | **InkWell Material 3 shader 缺失** | ✅ | `assets/shaders/ink_sparkle.frag` + pubspec.yaml:84-85 `shaders:` 声明, AGENTS.md 已知坑 + 守门员 | 底层 | - | - |
| 5.10 | **flutter_secure_storage iOS 14+ LAContext** | 🟡 | 见 1.2.12, 缺 NSFaceIDUsageDescription | 底层 | S | P1 |
| 5.11 | **iOS 17+ StandBy Mode** | ✅ 不需要 | 项目无 StandBy 集成 | 底层 | - | - |
| 5.12 | **iOS 17+ Journaling Suggestions** | ✅ 不需要 | 项目无 Journal 集成 | 底层 | - | - |
| 5.13 | **iOS 16+ Passkeys** | 🟡 未做 | DB Keychain 当前用密码, 可升级 Passkey (biometric + iCloud Keychain), 1-2w | 架构 | L (1-2w) | P3 |
| 5.14 | **iOS 17+ TipKit** | 🟡 未做 | 失联通知 / 用药提醒可走 TipKit, 0 实现 | 架构 | M (1w) | P3 |
| 5.15 | **iOS 18+ 翻译 API** | 🟡 未做 | `TranslationSession` 系统级翻译, 可用于 en/zh-Hant 树洞 1-tap 翻译, 0 实现 | 架构 | M (1w) | P3 |

**5 维度小结**: 70% 就绪, 剩 1 个 P0 (5.5 TestFlight 跑过) + 1 个 P0 (5.6 Dark Mode App Icon 重复) + 2 个 P1 (5.7 Sensitive Content / 5.10 NSFaceID) + 4 个 P2/P3 (Live Activity / TipKit / Passkeys / Translation)。

---

## 修复路线 (按 P0 → P3 排)

### 🟥 P0 — 上架 blocker (Apple 必拒, 必修)

| 序 | 修复项 | 阻塞类型 | 修复难度 | 外部依赖 |
|----|--------|----------|----------|----------|
| 1 | **4.19-4.22 截图 + 4.23 App Store Icon 替换** (4 尺寸 × 3 locale + AppIcon 1024) | 2.1.2 Placeholder + 2.3.1 | L (设计师 + Mac 2-3d) | Mac + 设计师 |
| 2 | **3.19 fastlane/Appfile 4 处 TODO 替换** (apple_id / team_id / itc_team_id) | 流程不通 | S (1h) | Apple Developer 账号 $99 + Team ID |
| 3 | **1.1.4 + 1.1.5 隐私 / 支持 URL 注册** (买 chroniccare.app 域名 + 部署隐私政策 + Support 页) | 5.1.1 | M (建站 3-5d) | 域名注册 + 部署 |
| 4 | **1.3.8 3 份法律文档法务过审** (律师签字 + 删"草稿" + 加生效日期) | 5.1.1 | L (法务 4w) | 律所 |
| 5 | **1.4.1 + 1.4.2 + 1.4.3 IAP 真接** (启用 _prodIapEnabled=true + App Store Connect 创建 productId + Restore Purchase 按钮 + sandbox tester) | 3.1.5 + 2.1.4 | L (1-2w) | App Store Connect 配 |
| 6 | **1.7.3 AliyunSmsProvider.send() 真接** (HMAC-SHA1 + POST dysmsapi.aliyuncs.com + 5s timeout + 3 retry + receipt) | 失联通知 release 永远不发 | XL (4-8w) | 阿里云 AccessKey + 短信模板法务审核 |
| 7 | **3.2 Podfile 真生成** (mac 跑 `pod install` 生成 Podfile.lock + Pods/) | Mac build 必报错 | S (Mac 跑 0.5d) | Mac |
| 8 | **3.4 Runner.xcodeproj DEVELOPMENT_TEAM 填** (3 处 build config) | 上架签名必填 | S (1h) | Apple Developer 账号 |
| 9 | **2.1.4 iOS 18+ Dark Mode App Icon** (4 套 1024×1024) | iOS 18+ 上架必填 | M (设计师 2-3d) | 设计师 |
| 10 | **2.1.5 LaunchImage.png 删 3 个** (改用 LaunchScreen.storyboard) | 启动时显示 1×1 黑屏 0.5s | S (5min) | - |
| 11 | **2.5.4 iCloud Backup 排除** (kCFURLIsExcludedFromBackupKey 标记 DB) | 精神心理数据走 iCloud = 隐私 | S (0.5d) | - |
| 12 | **4.7-4.9 description.txt 改文案** (删"会发短信" + 改"功能规划中, v1.0 真接") | 2.1.4 描述不符 | S (0.5d) | - |
| 13 | **5.5 TestFlight 跑 1 完整周期** (1-2w, 2 tester) | 0 崩溃率数据 | M (1-2w) | Mac + 2 tester |
| 14 | **1.6.5 NMPA 备案咨询** | 精神心理 App 4.3 (a) | XL (4-8w) | 律所 + 医疗器械咨询 |

### 🟧 P1 — 上架后 1 月内修

| 序 | 修复项 | 类型 | 难度 |
|----|--------|------|------|
| 15 | **1.1.3 第三方 SDK 列表补** (in_app_purchase / speech_to_text / pointycastle) | 底层 | S |
| 16 | **1.1.7 隐私 / 投诉邮箱注册** (替换软隐藏的 `support@chroniccare.app`) | 底层 | S |
| 17 | **1.1.18 + 1.2.12 NSFaceIDUsageDescription 防御性补** | 底层 | S |
| 18 | **1.3.3 EULA 显式标记** (App Store Connect 选"Custom EULA" 路径) | 底层 | S |
| 19 | **1.3.5 PIPL §14 撤回机制 UI 入口** (withdrawConsent caller + settings 入口) | 架构 | M |
| 20 | **1.6.8 App Review 备注写** (精神心理 + 医疗 + 失联通知 + PIPL 1 段) | 底层 | M |
| 21 | **2.1.1 LaunchScreen.storyboard 品牌化** (品牌色 + App 名 + icon) | 底层 | S |
| 22 | **2.1.2 AppIcon 1024 设计师重做** (替换 Flutter 默认图) | 底层 | M |
| 23 | **2.5.6 iOS 11+ Data Protection** (NSFileProtectionComplete) | 架构 | S |
| 24 | **2.8.1-2.8.6 可访问性全量补** (VoiceOver label + Dynamic Type + Reduce Motion + Contrast + Inspector) | 架构 | L (1-2w) |
| 25 | **3.3 PRODUCT_BUNDLE_IDENTIFIER 改 com.chroniccare.app** (6 处 build config) | 底层 | S |
| 26 | **3.9 + 5.1 iOS 16+ Live Activity** (失联通知 / 打卡提醒 + NSSupportsLiveActivities) | 架构 | L (1-2w) |
| 27 | **4.17 类别选 Medical 主 + Health & Fitness 副** | 底层 | S |
| 28 | **4.18 年龄分级问卷** (精神心理推荐 17+, 实际可能 12+) | 底层 | S |
| 29 | **4.27 Demo 数据 / 视频** | 底层 | M |
| 30 | **5.7 iOS 18+ Sensitive Content Analysis 答问卷** | 底层 | S |

### 🟨 P2 — v1.0 前修

| 序 | 修复项 | 类型 | 难度 |
|----|--------|------|------|
| 31 | **1.3.6 + 1.7.6 PIPL §23 真接阿里云 SMS 联系人确认流** (R58 软实施 → 硬实施) | 架构 | L (外部 1-2w) |
| 32 | **1.4.5 IAP receipt 验证 endpoint** | 架构 | M |
| 33 | **1.5.7 8 量表题目全文 v1.0 翻译** (走 ARB, 8 量表 × 5-12 题 = 70+ keys) | 架构 | L (法务+临床 1-2w) |
| 34 | **2.2.4 BGTaskScheduler handler 真实现** (业务真接时调 CareEngine.checkLostContact) | 架构 | L |
| 35 | **2.2.8 + 2.4.1-2.4.4 AVAudioSession 验证 + interrupt 处理** | 架构 | M |
| 36 | **2.3.4 通知 Category / Action** (打卡/失联加 action button) | 架构 | M |
| 37 | **2.4.6 Now Playing Info Center** (树洞 audio 锁屏控制) | 架构 | M |
| 38 | **2.4.7 Live Activity 集成** | 架构 | L |
| 39 | **2.7.4 Memory profile (DevTools)** | 架构 | M |
| 40 | **2.7.7 大 JSON 导出流式化** | 架构 | M |
| 41 | **2.8.4 Increase Contrast** | 架构 | S |
| 42 | **3.9 Widget Extension (打卡 widget)** | 架构 | L (1-2w) |
| 43 | **5.14 iOS 17+ TipKit** | 架构 | M |
| 44 | **5.15 iOS 18+ 翻译 API** | 架构 | M |

### 🟩 P3 — nit / 体验

| 序 | 修复项 | 类型 | 难度 |
|----|--------|------|------|
| 45 | **1.4.6 store_kit_service.dart 注释 ^7.0.0 → ^3.3.0 改** | 底层 | S |
| 46 | **2.4.5 AirPods / Bluetooth route change 监听** | 架构 | S |
| 47 | **5.13 iOS 16+ Passkeys** (DB Keychain 升级) | 架构 | L (1-2w) |

---

## 半成品 / 残缺项 / TODO 总览

| 文件:行 | 半成品状态 | 阻塞影响 |
|---------|-----------|----------|
| `fastlane/Appfile:21,23,25` | apple_id / team_id / itc_team_id 3 处 TODO 占位 | 必拒 (流程不通) |
| `assets/legal/user_agreement.md:25` | 写"售价人民币 8 元 / 一次性买断" | 描述 vs 实际不符 (IAP 关) |
| `assets/legal/user_agreement.md` 头部 | 标"草稿 (Sprint 1 修订) — 未经律师过审" | 必拒 (法务) |
| `assets/legal/privacy_policy.md` 头部 | 同上 | 必拒 |
| `assets/legal/sensitive_data_consent.md` 头部 | 同上 | 必拒 |
| `assets/legal/user_agreement.md:60-61` | `https://github.com/example/chroniccare/issues` 占位 | 警告 (不致命) |
| `lib/core/data/services/sms_service.dart:163` | `AliyunSmsProvider.send()` 抛 `StateError` 永不发 | 失联通知 release 永远不工作 |
| `lib/core/data/services/store_kit_service.dart:50,108-119` | productId 留 v0.28 真接 + `buyLifetime` release 返 false | 8 元买断用户买不到 |
| `lib/core/data/feature_flags.dart:38` | `_prodIapEnabled = false` 软隐藏 IAP 入口 | 跟 user_agreement §3 不一致 |
| `lib/core/data/feature_flags.dart:35` | `_prodEmergencyContactEnabled = false` 失联通知业务暂停 | 跟 README "自动 SMS 通知紧急联系人" 不一致 |
| `lib/main.dart:170-181` | `SmsService.validateForRelease` + `EmailService.validateForRelease` 启动守卫 | 业务真接后必须改 (现在 release 模式 mock 即阻断启动) |
| `ios/Podfile:1-7` | "本 Podfile 是占位 (Windows 平台无法跑 `pod install`)" | macOS build 必报错 |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage*.png` | 3 个 68 字节占位 (1×1 透明 PNG) | 启动时显示 1×1 黑屏 0.5s |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` | Flutter 默认 README, 占位 | - |
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/iphone_6_5_screenshots/*.png` | 5 × 3 = 15 张 67 字节占位 | 必拒 (截图 placeholder) |
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/iphone_5_5_screenshots/*.png` | 3 × 3 = 9 张 67 字节占位 | 必拒 |
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/ipad_12_9_screenshots/*.png` | 3 × 3 = 9 张 67 字节占位 | 必拒 |
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/app_icon.png` | 3 个 67 字节占位 | 必拒 (App Store Connect 必填) |
| `fastlane/metadata/ios/zh-Hans/name.txt:1` | mojibake 字符 "鎱㈢梾绠″" | 终端显示错乱 (UTF-8 BOM 缺失, 实际文件内容是"慢病管家" 4 字符 OK) |
| `fastlane/metadata/ios/zh-Hant/name.txt:1` | mojibake "鍚冭嵂鎵撳崱" | 同上 (实际"吃藥打卡" OK) |
| `lib/main.dart:188-192` | `FeatureFlags.iapEnabled` false 时 `StoreKitService.warmup()` 跳过 | v0.28 真接前 OK, 真接时必须改 |
| `lib/presentation/pages/settings/` (grep `Restore`) | 0 Restore Purchase 按钮 | Apple 3.1.5 强制 (IAP 真接时必做) |
| `lib/` (grep `withdrawConsent`) | 0 caller | PIPL §14 撤回机制文档承诺, UI 缺入口 |
| `lib/core/data/services/store_kit_service.dart:9` | stale comment "in_app_purchase: ^7.0.0" (实际 ^3.3.0) | nit |
| `lib/main.dart` (IAP 启动守卫) | 0 IAP 启动守卫 (StoreKitService.warmup 异常才进 runZonedGuarded) | IAP 真接时需加 (1-2h) |
| `App Store Connect` (字段) | 0 测试账号 / 0 App Review 备注 / 0 Contact Info | 上架表单必填 (1d) |
| `ios/Runner/Runner.entitlements` | 空 dict (R70 故意) | v1.0 接 APNs 时需加 aps-environment (1h) |

---

## iOS 平台未完成的适配

| # | 缺失项 | 影响 | 优先级 |
|---|--------|------|--------|
| A | **iOS 18+ Dark Mode App Icon** (Default / Dark / Tinted / Clear 4 套 1024×1024) | iOS 18+ 上架 4 套必填 | **P0** |
| B | **iOS 16+ Live Activity** (失联通知 / 打卡提醒走 ActivityKit + `NSSupportsLiveActivities`) | 锁屏可见度 | P2 |
| C | **iOS 17+ Interactive Widget** (锁屏 / 主屏 widget 显示 streak) | 用户留存 | P2 |
| D | **iOS 17+ TipKit** (失联通知 / 用药提醒 onboarding tip) | 用户教育 | P3 |
| E | **iOS 16+ Passkeys** (DB Keychain 升级) | 安全性 | P3 |
| F | **iOS 18+ Apple Intelligence** (本地 LLM 集成 5/7 栏 CBT 思维分析) | 产品差异化 | P3 (R89 已 rolledback) |
| G | **iOS 18+ 翻译 API** (TranslationSession 系统级翻译) | 多语言 | P3 |
| H | **AVAudioSession category 显式配** (playAndRecord / playback) | 录音+回放同时不中断 | P2 |
| I | **AVAudioSession interruptionNotification 监听** | 中断恢复 | P2 |
| J | **MPNowPlayingInfoCenter 填充** (锁屏控制) | 体验 | P3 |
| K | **iCloud Backup 排除** (kCFURLIsExcludedFromBackupKey) | 隐私 | **P0** |
| L | **iOS 11+ Data Protection** (NSFileProtectionComplete) | 锁屏数据不可读 | P1 |
| M | **NSFaceIDUsageDescription 防御性补** (flutter_secure_storage 内部) | 启动稳定性 | P1 |
| N | **iPad Pro 12.9" 1024pt 宽 "regular size class" 适配** (home / setup / mood_recorder / data_mgmt) | Apple 4.0 Design | P1 |
| O | **无障碍 VoiceOver label / Dynamic Type / Reduce Motion / Increase Contrast** | Apple 4.0 + 精神心理用户 | P1 |
| P | **沙盒 (Sandbox) tester 配置 + IAP 测试文档** | IAP 真接后必做 | **P0** |
| Q | **App Review 备注 (精神心理 + 医疗 + 失联通知 + PIPL)** | 5.1.1 + 5.2 + 4.3 | P1 |
| R | **App Store Connect "Sensitive Content Analysis" 答问卷** (iOS 18+) | 5.1.5 | P1 |
| S | **AVAudioSession route change 监听** (AirPods / Bluetooth) | 体验 | P3 |
| T | **通知 Category / Action** (打卡/失联 action button) | 体验 | P2 |

---

## 关键决策点 (供 PM 决策)

1. **IAP 业务是否真接?** 当前 `_prodIapEnabled=false` 软隐藏, 但 `user_agreement.md:25` 写 8 元买断, 描述 vs 实际矛盾。**3 选 1**:
   - (A) v0.28 真接 IAP (1-2w) — 启用 + App Store Connect 配 productId + Restore 按钮
   - (B) 删 `user_agreement.md` 8 元买断段落, 改"免费下载" — 5min
   - (C) 改产品定位"免费 + 自愿打赏" — 1d

2. **失联通知业务是否真接?** 当前 `AliyunSmsProvider.send()` 永 throw, 业务整体暂停。**3 选 1**:
   - (A) v1.0 真接阿里云 SMS (4-8w 法务 + AccessKey) — 风险: 短信模板"药/病"敏感词
   - (B) 改 Apple 生态替代方案 — 失联通知改 APNs 远程推送 (用户装 App 在第 2 台设备) — 1-2w
   - (C) 永久不接, 改"App 内紧急联系人通知" (App 内 Notification, 不出 App) — 1w

3. **Mac 设备 + Apple Developer 账号 + 设计师** 3 件必备, 1 件不可少:
   - Mac (build iOS / TestFlight / 截图)
   - Apple Developer Program $99/年 (1.1.4 / 1.1.5 / 3.4 / 5.5 必填)
   - 设计师 (4.19-4.23 截图 + 2.1.2 AppIcon + 2.1.4 Dark Mode Icon)

4. **R82+ iOS 18+ 适配窗口**: iOS 18 (2024-09 发布) 上架 1.0.0 必填 Dark Mode App Icon; iOS 19 (2025-09 预计) 可能新增 Mandatory Privacy Manifest 强化 (类似 Live Activity)。

---

## 总结: 上架就绪度计算

```
代码层 9/10 × 0.25 = 2.25
iOS 工程 9/10 × 0.20 = 1.80
隐私 9/10 × 0.10 = 0.90
法务 3/10 × 0.10 = 0.30
业务 (IAP+SMS) 2/10 × 0.10 = 0.20
元数据 0.5/10 × 0.10 = 0.05
测试 (TestFlight) 0/10 × 0.10 = 0.00
iPad 12.9" 适配 6/10 × 0.05 = 0.30
────────────────────────────
总: 5.80 / 10 ≈ 6.0 / 10
```

**关键瓶颈 (按修复 ROI)**:
1. **0-1 周** (S 难度): Podfile 跑 / 截图占位换 / fastlane 4 TODO 换 / 描述文案改 / 删 LaunchImage 占位 — **上架就绪度 → 7.5/10**
2. **1-2 周** (M 难度): 买域名建站 / IAP 真接 / AppIcon + Dark Mode Icon 重做 / 可访问性补 — **上架就绪度 → 8.5/10**
3. **1-2 月** (L 难度, 部分外部): 律师过审 3 份文档 / 设计师全套截图 / TestFlight 跑 1 周期 / Apple Developer 申请 — **上架就绪度 → 9.0/10**
4. **2-3 月** (XL 难度, 外部依赖): 阿里云 SMS 模板法务审核 + AccessKey 申请 + AliyunSmsProvider 真接 + NMPA 备案咨询 — **上架就绪度 → 9.5/10**

**最终建议**: 当前可走"v0.30.x" 走 Google Play + Android 主战, iOS 推迟到 v0.32 / v1.0 (法务 + IAP + 阿里云 SMS 三件外部依赖完备后)。短期"占位截图 + 域名"刷一遍可达 7.5/10, 但 Apple 5.1.1 + 3.1.5 + 4.3 必拒, 不建议在 P0 法务过审前提交。

---

**报告完。**
