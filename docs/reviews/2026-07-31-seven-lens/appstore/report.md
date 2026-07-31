# AppStore 视角审视报告 — chroniccare v0.27.0+62

> **视角**: Apple App Store Review Guidelines 5.x + Human Interface Guidelines + 4.3 医疗 App 特别条款
> **扫描范围**: `ios/` (Info.plist / PrivacyInfo.xcprivacy / AppDelegate / SceneDelegate / project.pbxproj / Assets.xcassets) + `pubspec.yaml` + 关键服务 (notification / sms / safety_watch / safety_alert_dispatcher / lost_contact_sms) + 隐私政策 3 份 + 联系人 / consent UI
> **扫描方法**: ripgrep 全文 + 关键文件 read
> **基础**: `docs/reviews/2026-07-31-three-lens/consolidated.md` (P0/P1 已修列表) + `CHANGELOG.md` Unreleased + AGENTS.md (iOS 13+ / iPad 已做)
> **状态标注**: ✅ 已就绪 / 🔶 部分就绪 / ⏳ 未就绪 / 🆕 本视角新发现
> **优先级**: P0 (必修复才能上架) / P1 (上架后 1 月内修) / P2 (v1.0 前修) / P3 (nit)
> **修复难度**: S (<1h) / M (1-4h) / L (1-3d)

---

## 0. 一页总览

| 指标 | 数值 |
|---|---|
| 总问题 | **26** 条 |
| 架构级 | 4 条 |
| 底层级 | 22 条 |
| P0 | 9 条 |
| P1 | 10 条 |
| P2 | 5 条 |
| P3 | 2 条 |
| 上架就绪度 | **3.5 / 10** (代码层 90% ready, 元数据/法务/构建 30% ready) |
| 最大阻塞 | 隐私政策 `privacy@chroniccare.app` 占位 + AliyunSmsProvider 未真接 + 缺 TestFlight 验证 + 缺 IAP StoreKit 集成 |

**3 行总结**:
1. **代码 + 平台配置已 90% ready** — Info.plist 4 个 NSUsageDescription / PrivacyInfo.xcprivacy 2024-05 强制项 / iPad 多任务 / iOS 13+ 全部到位；R61-R62 把 P0-2 ConsentArtifact + P0-3 SmsService 单例 + P1-4/1-5 修正完毕（CHANGELOG 部分漏记）。
2. **法务 + 业务 + 元数据 0 ready** — 隐私政策邮箱占位 / NMPA 备案 / IAP StoreKit / 6.7"/12.9" 截图 / 英文 App 名 / `ITSAppUsesNonExemptEncryption` key / `Runner.entitlements` / `EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64` 全部 0。
3. **3 个月内可修复 (按 S/M/L)** — 截图 + 元数据 (S) → IAP StoreKit (M) → ITSAppUsesNonExemptEncryption + 隐私政策邮箱替换 + entitlements (S-M) → 法务过审 + NMPA 备案 (L, 外部依赖) → AliyunSmsProvider 真接 (L, 外部依赖法务 + AccessKey)。

---

## 1. 顶层架构审视

### 1.1 架构评级

| 维度 | 评分 | 理由 |
|---|---|---|
| 平台适配 | ⭐⭐⭐⭐ (4/5) | TARGETED_DEVICE_FAMILY=1,2 (iPhone+iPad) ✓ / UIRequiresFullScreen=false ✓ / iPad 多任务 ✓ / iOS 13+ ✓ — 但 deployment target 13.0 落后 Apple 2024 推荐 14+ / iPad Pro 12.9" layout 没特殊适配 (R55 拆分) |
| 隐私 / 权限 | ⭐⭐⭐⭐ (4/5) | 4 NSUsageDescription ✓ / NSPrivacyTracking=false ✓ / PrivacyInfo.xcprivacy 4 required-reason API ✓ — 但缺 `NSPhotoLibraryAddUsageDescription` (PDF export) / 缺 `ITSAppUsesNonExemptEncryption` / 缺 `Runner.entitlements` |
| 法务 / 合规 | ⭐⭐ (2/5) | 隐私政策 12 章节覆盖 PIPL ✓ / ConsentArtifact + ConsentDialog 已落地 ✓ — 但 `privacy@chroniccare.app` 占位邮箱 / 法务过审未做 / NMPA 备案未做 / Apple 5.1.1 隐私政策 URL 仍占位 `chroniccare.app` |
| 业务能力 | ⭐⭐ (2/5) | 本地通知 6 类编排 + iPad / iOS 13+ / SQLCipher 加密 / 树洞隐私边界 — **失联通知 release 永远发不出** (AliyunSmsProvider.send() 抛 UnimplementedError) / 8 元买断价 → **必走 IAP StoreKit** 没集成 |
| 元数据 / 商店 | ⭐ (1/5) | `CFBundleDisplayName` 4 字中文 ✓ / AppIcon 1024 ✓ / LaunchScreen 1x 占位 — **App Store Connect 元数据 0**: 6.7" / 6.5" / 5.5" / iPad 12.9" 截图 / 170 字促销文本 / 4000 字描述 / 100 字关键词 / 英文 App 名 / 副标题 / 类别 / 版权 / Support URL 全部缺 |

### 1.2 顶层重构建议 (4 条, 高内聚低耦合)

| # | 模块 | 现状 | 建议 | 难度 | 优先级 |
|---|------|------|------|------|------|
| 1 | **iOS HealthKit 集成 (可选)** | 精神心理数据 (PHQ-9 / GAD-7 / 心情评分) 全在自管 SQLCipher DB | 评估是否走 HealthKit (`HKCategoryTypeIdentifier.mindfulSession` / `HKQuantityTypeIdentifier.mindfulMinutes`)。**优势**: 走 HealthKit = Apple 已知"医疗数据" 路径, 4.3 审核更顺, 隐私营养标签可省 health 字段声明。**劣势**: 1-2 周集成 + 用户授权流程 + HealthKit 文档化要求 | L | P2 |
| 2 | **IAP StoreKit 2 集成** | `assets/legal/user_agreement.md:25` 写"售价人民币 8 元" — 但 pubspec 无 `in_app_purchase` / 无 StoreKit 代码 | 加 `in_app_purchase: ^7.0.0` + `StoreKitService` + 受 StoreKit 约束的 `pro` 开关 (解锁 IAP 后才能用失联通知 SMS 模板高级版 / 树洞音频加密等)。**8 元一次性买断**走 `ConsumablePurchase` / `NonConsumablePurchase` (非订阅) | M | P0 |
| 3 | **Background Tasks 重构 (iOS 13+ deprecated `fetch`)** | `ios/Runner/Info.plist:101` UIBackgroundModes 写 `fetch` — iOS 13+ Apple 推 `BGTaskScheduler` (短任务) + `BGProcessingTask` (长任务), `fetch` 已弃用且实际不再触发 | 把 `fetch` 改成 `processing` + 加 `BGTaskSchedulerPermittedIdentifiers` (`com.chroniccare.safety-check`) 到 Info.plist, 写 `BGTaskScheduler.shared.register(...)` 在 AppDelegate.swift, 改失联检测走 `BGProcessingTask` | M | P1 |
| 4 | **iPad Pro 12.9" layout 重审** | `pubspec.yaml` 标 iPad 多任务 OK, layout 主要走 NavigationRail, 但 mood_recorder 564 行 / setup_page 431+ 行 / data_mgmt 多列 layout 在 12.9" 1024pt 宽下未做 "regular vs compact" 适配, Apple 4.0 Design 审核会扣分 | 在 `lib/core/theme/breakpoints.dart` (如果有) 加 iPad Pro 12.9" breakpoint, 抽样 5 个 page 加 `LayoutBuilder` 适配多列 / sidebar 模式 | M | P2 |

---

## 2. 底层逐行排查 (15 条, 按上架就绪度排序)

### 2.1 P0 — 必修复才能上架

| # | 文件:行 | 现状 | 建议 | 架构/底层 | 难度 | 优先级 |
|---|---------|------|------|------|------|------|
| **P0-1** | `ios/Runner/Info.plist:0` (整文件) | **缺 `ITSAppUsesNonExemptEncryption` key**。Apple App Store Connect 2024 起强制问 export compliance, 缺此 key → 上架时表单问"是否使用加密" + 选 yes 必填 CCATS 编号 / 选 no 也可。精神心理患者数据走 SQLCipher AES-256 + FlutterSecureStorage 是"标准加密", 应明确声明 `ITSAppUsesNonExemptEncryption=false` | 加 `<key>ITSAppUsesNonExemptEncryption</key><false/>` + Info.plist 注释说明 SQLCipher 是"标准库加密" (无自定义加密算法) | 底层 | S | P0 |
| **P0-2** | `assets/legal/privacy_policy.md:111, 123, 150` | **3 处 `privacy@chroniccare.app` 占位邮箱**。App Store 5.1.1 要求"有效的 support URL" + 隐私政策必须含真实联系方式; 占位邮箱 Apple 审核 = 直接拒 | 注册 `privacy@chroniccare.app` (或换用 `team@chroniccare.app` 等) + 替换 3 处占位 + 在 App Store Connect "Support URL" 填 `https://chroniccare.app/support` (需先建官网) | 底层 | S (改邮箱) / M (建官网) | P0 |
| **P0-3** | `assets/legal/privacy_policy.md:3` + `sensitive_data_consent.md:3` + `user_agreement.md:3` | **3 份法律文档顶部都标"v0.24 草稿 (升级日期 2026-07-26),未经律师过审"**。Apple 5.1.1 明确要求"隐私政策必须清晰 + 当前生效" + 5.1.2"敏感数据收集必须明确同意"。草稿状态 = 直接拒 | 律师过审 3 份文档 (法务流程 2-4 周) + 删"草稿"字样 + 加律师签字 / 律所名 / 生效日期 | 底层 | L (法务流程) | P0 |
| **P0-4** | `ios/Runner/Info.plist:0` + `pubspec.yaml:0` | **IAP 没集成**。`assets/legal/user_agreement.md:25` 写"售价人民币 8 元 / 一次性买断", 但 pubspec 无 `in_app_purchase` 依赖 + 全代码库 0 StoreKit 调用。App Store 3.1.5 (a) 明确"App 内购买数字商品 / 服务必须用 IAP", 漏接 = 上架拒 + 下架风险 | 加 `in_app_purchase: ^7.0.0` + `lib/core/data/services/store_kit_service.dart` (封装 NonConsumable) + `setup_page` 加 IAP 闸 (未购买限制"失联通知"等高级功能) + App Store Connect 创建 product id `com.chroniccare.app.lifetime` | 架构 + 底层 | M | P0 |
| **P0-5** | `lib/core/data/services/sms_service.dart:171-176` + `lib/main.dart:154` | **AliyunSmsProvider.send() 抛 UnimplementedError**。即使 `validateForRelease` 检测到 4 个字段 (accessKey/secret/signName/templateCode) 都非空, release 模式启动不阻断, 但 send() 永远 throw → 上层走 SmsResult.fail → UI 显示"已通知 0 位 (X 失败)"。**失联通知功能在 release 永远不工作**。3-lens 报告 R60+ P0-1 标"未真接", R62 修正只到 `isProductionReady` 字段检查层级, send() 仍 TODO | 真接阿里云 SMS (R55 plan): 加 `dio: ^5.0.0` + `crypto: ^3.0.0` + 实现 `_signRequest()` (HMAC-SHA1) + POST `https://dysmsapi.aliyuncs.com/` + 5s timeout + 3 次重试 + 解析 `Code='OK'` 返 true。**外部依赖**: 法务过审短信模板 (1-2 月) + 阿里云 AccessKey 申请 | 架构 + 底层 | L (法务 + 接入) | P0 |
| **P0-6** | `ios/Runner/Info.plist:0` | **缺 `NSPhotoLibraryAddUsageDescription`**。`pubspec.yaml:51` 依赖 `share_plus: ^10.1.4`, `lib/presentation/widgets/medication_report_dialog.dart:4` import `share_plus` — iOS 上 PDF 报告分享会触发 PHPhotoLibrary 调用 (即使走 share sheet, 部分场景会触发), 没 usage description 拒 | 加 `<key>NSPhotoLibraryAddUsageDescription</key><string>用于保存用药报告 PDF 到相册</string>` | 底层 | S | P0 |
| **P0-7** | `ios/Runner/Info.plist:101` | **UIBackgroundModes `fetch` 实际 iOS 13+ 已 deprecated**。Apple 文档明确 "Background fetch is deprecated; use BGTaskScheduler instead"。提交时 Apple 自动 warning (不拒, 但 App Review 4.0 Design 扣分) | 改成 `processing` + 加 `BGTaskSchedulerPermittedIdentifiers` array 含 `com.chroniccare.safety-check` + AppDelegate.swift 写 `BGTaskScheduler.shared.register(forTaskWithIdentifier:using:launchHandler:)` | 底层 | M | P1 (本视角升 P0) |
| **P0-8** | `ios/Runner/project.pbxproj:0` (整文件) | **缺 `Runner.entitlements` 文件**。当前 0 entitlement 声明: 未来接 APNs (P0-1 配套) 必须 entitlements; 失联通知 SMS 模板若走 APNs silent push 触发, 也必须 entitlements; iOS 16+ Live Activity 需 `NSSupportsLiveActivities`。当前 iOS 13+ 0 entitlement 可上架, 但 v1.0 扩展前必须补 | 新建 `ios/Runner/Runner.entitlements` (plist) + pbxproj `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` + 至少加 `aps-environment = development` (P0-1 真接预留) | 底层 | S | P1 (本视角升 P0) |
| **P0-9** | `ios/Runner/Info.plist:10` + App Store Connect | **`CFBundleDisplayName` 仅 4 字中文"慢病管家", 没英文 / 繁体**。App Store Connect 支持 per-locale display name, 但当前 Info.plist 只 1 个 key → 英文用户看到中文 display name (App Store 自动 fallback 差, 用户体验差) | Info.plist 加 `<key>CFBundleDisplayName</key><dict><key>en</key><string>ChronicCare</string><key>zh-Hans</key><string>慢病管家</string><key>zh-Hant</key><string>慢病管家</string></dict>` (per-language 字典模式) | 底层 | S | P0 |

### 2.2 P1 — 上架后 1 月内修

| # | 文件:行 | 现状 | 建议 | 架构/底层 | 难度 | 优先级 |
|---|---------|------|------|------|------|------|
| **P1-1** | `ios/Runner/Info.plist:0` (App Store Connect metadata) | **6.7" / 6.5" / 5.5" / iPad Pro 12.9" 截图全部缺**。App Store Connect 必填 (iPhone 6.7" 是 iPhone 15/16 Pro Max 1290×2796, iPad 12.9" 是 2048×2732)。无截图 = 上架表单必填校验失败 | 用 `flutter build ios --release` 跑真机 / simulator 截图, 至少 3 张 (主页打卡 / 趋势 / 失联通知) × 4 尺寸 = 12 张 | 底层 | M (截图 + 上传) | P0 (本视角升) |
| **P1-2** | App Store Connect metadata | **170 字促销文本 / 4000 字描述 / 100 字关键词 / 副标题 30 字 / 类别 (医疗 vs 健康 vs 生产力) / 版权 `© 2026 chroniccare.app` / Support URL 全部缺** | App Store Connect 一步步填, 参考"死了么" (竞品) 风格: 副标题 "不漏一次药, 不失一次联" / 关键词 `medication,reminder,mental-health,depression,anxiety,care` / 类别 "医疗" + "健康" 双类 | 底层 | M | P0 (本视角升) |
| **P1-3** | `ios/Runner.xcodeproj/project.pbxproj:357` | **`TARGETED_DEVICE_FAMILY = "1,2"` 是 Universal (iPhone + iPad)**, 但 iPad Pro 12.9" (2732×2048) layout 没特殊适配。`mood_recorder_page.dart:564` / `setup_page.dart:431` / `data_mgmt` 在 12.9" 1024pt 宽下未做 "regular size class" 适配 — NavigationRail + 2-column layout 走 default 可能让 12.9" 显示局促 | `lib/core/theme/app_tokens.dart:641` 已有 `contentMaxWidth = 720` — 在 12.9" 应允许多列; 抽样 5 page 加 `LayoutBuilder` 适配 | 架构 | M | P1 |
| **P1-4** | `ios/Runner.xcodeproj/project.pbxproj:353, 479, 530` | **`IPHONEOS_DEPLOYMENT_TARGET = 13.0`**。Apple 2024-04 起, 新 app 最低 iOS 14; 2025 起推荐 15+。13.0 落后 1-2 个 major version, 上架 warning + 4.0 Design 扣分 | 升 14.0 (最低推荐) / 15.0 (Apple 推), pubspec 已有 `flutter: '>=3.41.0'`, flutter 3.41 默认 iOS 13 — 改 project.pbxproj 3 处 + 验证 iOS 14 API 兼容 (无 `discard _` 等 14 弃用 API) | 底层 | S | P1 |
| **P1-5** | `ios/Runner.xcodeproj/project.pbxproj:356, 533` | **`SUPPORTED_PLATFORMS = iphoneos`**, 缺 `iphonesimulator` — Apple Silicon Mac 跑 iOS simulator 需要; 当前 CI / TestFlight 跑 simulator 需补 | 改 `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"` + 加 `EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64` (M1+ Mac 用 arm64 simulator, 但部分 plugin 仍 0 arm64 simulator binary) | 底层 | S | P1 |
| **P1-6** | `ios/Runner.xcodeproj/project.pbxproj:375, 554, 576` | **`PRODUCT_BUNDLE_IDENTIFIER = com.chroniccare.chroniccare`** — `.chroniccare.chroniccare` 重复 2 次, 不是标准 reverse-DNS 命名 (应为 `com.chroniccare.app` / `com.chroniccare.chroniccare` 二选一)。App Store 上架后无法换 bundle id (locked) — 趁现在改 | 改 `com.chroniccare.app` (推荐) / `com.chroniccare.chroniccare` 改 `com.chroniccare` (3 处 build config) + 检查 entitlements / provisioning profile 一致 | 底层 | S | P1 |
| **P1-7** | `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json:0` | **LaunchScreen.storyboard 用纯白色 + LaunchImage.png 1x (168x185 占位)**。精神心理 App 给用户第一印象, 纯白 + 默认 Flutter 图标 = 不专业, 4.0 Design 扣分 | 加品牌色 (`AppTokens.primaryLight`) 做 launch screen 背景 + 加 App 名称 + 改 LaunchImage 1024x1024 品牌 logo | 底层 | S | P1 |
| **P1-8** | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png:0` | **AppIcon 1024x1024 = 10932 bytes** (10.7 KB) — 是 Flutter 默认占位 logo (蓝白圆角矩形), 不是品牌图标。App Store 4.0 Design 拒 | 设计师出 1024x1024 PNG (无 alpha, 无 rounded corner, 纯 icon) + 替换; Apple 要求"无透明 / 无 rounded" | 底层 | M (设计) | P1 |
| **P1-9** | `ios/Runner/Info.plist:0` (App Store Connect) | **NMPA 备案未做**。精神心理 App 涉及"医疗信息"按 4.3.4 + 4.3 (a) 需走医疗器械备案 / NMPA 备案 (中国大陆)。App Store 4.3 审核可能问"是医疗器械吗"。**风险**: 不是医疗器械 = 必须在 App 描述 + 隐私政策明示"本 App 不提供医疗建议、诊断或治疗" (当前 `user_agreement.md:21` 已声明, ✓) | 律师 + 医疗器械咨询 (2-4 周) 确认是否需 NMPA; 不需就保留声明 | 底层 | L (外部) | P1 |
| **P1-10** | `ios/Runner/Info.plist:0` (App Store Connect) | **没隐私政策 URL**。App Store 5.1.1 必填"Privacy Policy URL", 即使 app 自己展示也要 URL。`chroniccare.app` 域名还是占位, 隐私政策 3 份在 `assets/legal/`, 没 host 到网站 | 买 `chroniccare.app` 域名 + 部署静态页 (`mkdocs` / `hugo`) + App Store Connect "Privacy Policy URL" 填 `https://chroniccare.app/privacy` | 底层 | M (建站) | P0 (本视角升) |

### 2.3 P2 — v1.0 前修

| # | 文件:行 | 现状 | 建议 | 架构/底层 | 难度 | 优先级 |
|---|---------|------|------|------|------|------|
| **P2-1** | `lib/core/data/services/safety_watch_service.dart:114` | **`checkNow({now})` 只在 dev / 测试用**。iOS production 走 `BGTaskScheduler` 触发 (`trigger: 'bg'`) — 但实际是 `ReminderDispatcher` 在 `flutter_local_notifications` zonedSchedule 触达时, 在 `onDidReceiveBackgroundNotificationResponse` 调 `SafetyWatchService.checkNow()`。Apple 4.0 Background Execution 审核可能问"为什么 background 跑失联检测" | Info.plist 注释已声明 `fetch: 失联检测 24h 周期` ✓, 加上 `AppDelegate.swift` BGTaskScheduler 注释, 备审时给 Apple 解释 | 底层 | S | P2 |
| **P2-2** | `lib/main.dart:36` (top-level static) | **`SmsService _smsService = SmsService()` 顶层 static** — R62 P0-3 修复注释承诺"单一实例", 但 iOS 真接阿里云后, 需 provider 切换 (MockSmsProvider → AliyunSmsProvider), 顶层 static 改起来要全局搜索 | R62 完成时已 `provider` 注入 — 顶层 static 仅 bootstrap 守卫用, 走 `.env` 读 key 后, 改 `SmsService(provider: AliyunSmsProvider(...))` 单点改, 注掉 static | 架构 | S | P2 |
| **P2-3** | `ios/Runner/Base.lproj/LaunchScreen.storyboard:18-29` | **LaunchScreen 用 Flutter default storyboard** (白色 + 占位图), 跟 `Assets.xcassets/LaunchImage.imageset` 不一致 | 改成自定义 storyboard: 品牌色背景 + App 名 + icon, 用 iOS 14+ launch screen (不依赖 LaunchImage) | 底层 | S | P2 |
| **P2-4** | `lib/presentation/pages/mood/mood_recorder_page.dart:564` | **564 行 god page**, iPad Pro 12.9" 1024pt 宽下, 录音波形 / 录音按钮 / STT transcript 3 区域挤一列显示, 4.0 Design 扣分 | 拆 3-5 子 widget + `LayoutBuilder` 适配 iPad (多列 / sidebar) | 架构 | L | P2 |
| **P2-5** | `ios/Runner/Info.plist:0` (App Store Connect) | **App 类别没选**。精神心理 App 应选 "医疗" (Medical) 主类 + "健康" (Health & Fitness) 副类, 不选生产力 | App Store Connect 选 Medical 主 + Health 副, 跟 Apple "4.3 医疗类" 审核要求对齐 | 底层 | S | P2 |

### 2.4 P3 — nit / 顺手

- **P3-1** `ios/Runner/Info.plist:7` `CFBundleDevelopmentRegion = $(DEVELOPMENT_LANGUAGE)` 默认 en → 改 `zh-Hans` 或加 `Base.lproj/InfoPlist.strings`
- **P3-2** `ios/Runner.xcodeproj/project.pbxproj:0` 缺 `Debug.xcconfig` 自定义 `DEVELOPMENT_TEAM` / `PROVISIONING_PROFILE` → 上架前 CI 必填

---

## 3. 视角特定清单 (AppStore 必查)

### A. 隐私 / 权限

✅ **已就绪** (R61): NSUserNotificationUsageDescription / NSMicrophoneUsageDescription / NSSpeechRecognitionUsageDescription / NSUserTrackingUsageDescription / NSPrivacyTracking=false / NSPrivacyCollectedDataTypes=空 / NSPrivacyAccessedAPITypes 4 required-reason API (2024-05 强制) 全 ✓
⏳ **缺**: NSPhotoLibraryAddUsageDescription (share_plus PDF export → P0-6) / ITSAppUsesNonExemptEncryption (Apple export compliance → P0-1) / Age Rating 12+ 或 17+ (精神心理推荐 17+)
✅ **不需要**: NSContactsUsageDescription (无 flutter_contacts) / NSLocationWhenInUseUsageDescription (无定位) / NSHealthShareUsageDescription (不接 HealthKit, 见 1.2 #1)

### B. 内容 / 政策

- **4.0 Design** 🔶 AppIcon 1024 是占位 (P1-8)
- **4.2 最低功能** ✅ Flutter native + 6 类通知 + 树洞加密 + 失联检测 (远超 wrapper)
- **4.3 医疗 App** 🔶 `user_agreement.md:21` 已声明"不提供医疗建议" ✓, 但 NMPA 备案未做 (P1-9)
- **5.1.1 隐私政策 URL** ⏳ (P1-10 建站)
- **5.1.2 单独同意** ✅ R62 P0-2 已修 (ConsentArtifact 实体 + ConsentDialog 共享 + contact_repository 强制), 3-lens 报告 R60+ 标"未修"已 stale
- **1.4.1 医疗伦理** ✅ `safety_watch_service.dart:158-164` 同日不重复 + DND + 阈值配置
- **1.5 儿童不能注册** 🔶 `privacy_policy.md:120-124` 写"14 周岁以下不适用", 但 setup UI 0 "我已满 18" 闸
- **3.1.5 IAP** ⏳ 0 StoreKit 集成 (P0-4)

### C. 性能 / 技术

- **崩溃率** ⏳ 无 Mac 跑过 TestFlight (3 月内必做)
- **64-bit** ✅ Flutter 默认 arm64, ENABLE_BITCODE=NO
- **iPad 适配** 🔶 TARGETED_DEVICE_FAMILY=1,2 + UIRequiresFullScreen=false ✓, 但 12.9" 1024pt 适配弱 (P1-3)
- **启动时间** ✅ runZonedGuarded + 1.5s bootstrap
- **Background Modes** 🔶 `UIBackgroundModes audio` ✓ + `fetch` iOS 13+ deprecated (P0-7 改 processing)
- **SwiftUI/UIKit** ✅ Flutter + Material 3

### D. 元数据 (App Store Connect)

⏳ **全部缺**: 副标题 30 字 / 类别 / 6.7"+6.5"+5.5"+iPad 12.9" 截图 / 170 字促销 / 4000 字描述 / 100 字关键词 / 版权 / Support URL / Marketing URL → **P0-9 / P1-1 / P1-2 / P1-10 / P2-5**

### E. 业务 / 法规

- **IAP** ⏳ (P0-4) 8 元买断价在 `user_agreement.md:25` 已写, 0 StoreKit 集成
- **导出/导入** 🔶 `data_export_service` 死代码 (P2-1.11), 但 share_plus 已走 ✓
- **网络电话/SMS** ✅ 走阿里云 HTTP (无需 NSContactsUsageDescription); 但 AliyunSmsProvider.send() 抛 UnimplementedError → P0-5
- **APNs entitlement** ⏳ 缺 `Runner.entitlements` (P0-8)

### F. 精神心理特别关注

- ✅ **PIPL/HIPAA-like 合规** (3 份法律文档覆盖 §13/§23/§38/§28) — 但 P0-3 法务过审未做
- ✅ **失联 SMS** (R62 P1-5 抽单一 source, "如确认安全请回复 1" 业务逻辑) — 但 P0-5 release 不真发
- ✅ **录音 / 麦克风** (NSMicrophoneUsageDescription + 加密 + vent 隐私边界)
- ✅ **本地加密** (sqlcipher_flutter_libs + flutter_secure_storage Keychain)
- ✅ **App Tracking = 0** (NSPrivacyTracking=false + 0 IDFA)
- ✅ **树洞隐私边界** (vent 0 notification / 0 trend / 0 care engine)
- ✅ **PHQ-9 危机 + 6 region 热线** (R50 R51b, 21 case test)
- 🔶 **撤销同意** (`user_profile_repository.withdrawConsent` 0 caller) — v1.0 前修

---

## 4. 与历史报告对比

| 历史报告项 | 之前状态 (R60+ / 3-lens) | 当前 (R62 working tree) | 验证 |
|-----------|------------------------|------------------------|------|
| **P0-1 SMS 真接** (spzh 3-lens) | UnimplementedError + validateForRelease 仅检查配置 | ⏳ 仍未真接 (AliyunSmsProvider.send() 仍 throw, R62 修到 isProductionReady 字段级) | → **本视角 P0-5** |
| **P0-2 PIPL §13 ConsentArtifact** (spzh 3-lens) | 0 consent, grep 0 個 | ✅ **R62 已修** (ConsentArtifact 实体 + ConsentDialog 共享 + contact_repository 强制); CHANGELOG Unreleased **漏记** (只记 P0-3 tail) | grep 命中 6 文件 ✓ |
| **P0-3 main.dart SmsService 单例** (spzh 3-lens) | 注释撒谎 / 临时实例 | ✅ **R62 已修** (`_smsService` 顶层 static + `overrideWithValue(_smsService)` @ main.dart:191) | 验证 ✓ |
| **P0-3 SafetyAlert 3 态分流** (spzh + spen 3-lens) | hardcode "已自动通知" | ✅ **R60 已修** (SmsDispatchOutcome + _resolveSafetyAlertBody + 3 i18n key) | 验证 ✓ |
| **P1-4 safety_watch.displayMessage i18n** (spzh + spen 3-lens) | 8 case hardcode 中文 | ✅ **R61 已修** (9 ARB key + displayMessageL10n) | 验证 ✓ |
| **P1-5 失联 SMS 单一 source** (spzh + spen 3-lens) | 2 service 50% 重复 | ✅ **R62 已修** (`lib/domain/logic/lost_contact_sms.dart`) | glob 命中 ✓ |
| **R61 平台配置 (Info.plist 4 NSUsageDescription + PrivacyInfo.xcprivacy 4 required-reason API)** (CHANGELOG) | R61 落地 | ✅ 已就绪 | 验证 ✓ |
| **R61 iPad 多任务 UIRequiresFullScreen=false + TARGETED_DEVICE_FAMILY=1,2** (CHANGELOG) | R61 落地 | ✅ 已就绪 (Info.plist:50-51 + pbxproj:357) | 验证 ✓ |
| **R61 IPHONEOS_DEPLOYMENT_TARGET 13+** (CHANGELOG) | R61 落地 | 🔶 部分就绪 (13.0 太旧, Apple 2024 起推荐 14+) | → **本视角 P1-4** |
| **iOS 14+ HealthKit 集成** (—) | — | ⏳ 未做 (可选) | → **本视角 1.2 #1** |
| **IAP StoreKit** (—) | — | ⏳ 未做 (8 元买断必走) | → **本视角 P0-4** |
| **隐私政策 / NMPA / 截图 / 元数据** (spzh P0-of-P0) | v0.24 草稿, 上 store 阻塞 | ⏳ 仍未修 | → **本视角 P0-2 / P0-3 / P1-1 / P1-2 / P1-9 / P1-10** |
| **`Runner.entitlements` 文件** (—) | — | ⏳ 不存在 (整个文件缺失) | → **本视角 P0-8** |
| **`ITSAppUsesNonExemptEncryption`** (—) | — | ⏳ 未加 (Apple export compliance) | → **本视角 P0-1** |

---

## 5. 修复路线 (Top 5, 按上架就绪度排序)

> 假设目标: 3 个月内 (2026-10-31 前) 完成 iOS App Store 1.0.0 上线
> 外部依赖: 法务 (4 周) + 阿里云 AccessKey + 短信模板审核 (4-8 周) + NMPA 咨询 (4-8 周) + Apple Developer Program 账号 ($99/年) + Mac

### 路线 1 (S 难度, 1 周内): P0-1 + P0-2 + P0-6 + P0-9 — 单一文件改
- **P0-1** (5min) `Info.plist` 加 `ITSAppUsesNonExemptEncryption=false`
- **P0-2** (30min) 替换 `privacy_policy.md:111,123,150` 3 处 `privacy@chroniccare.app` 占位
- **P0-6** (5min) `Info.plist` 加 `NSPhotoLibraryAddUsageDescription`
- **P0-9** (10min) `CFBundleDisplayName` 改 per-language dict (zh-Hans + en + zh-Hant)

### 路线 2 (M 难度, 1-2 周): P1-1 + P1-2 + P1-10 — 元数据 + 建站
- **P1-1** (3d) 设计师 4 尺寸 × 3 张 = 12 张截图
- **P1-2** (1d) App Store Connect 填 170 字促销 / 4000 字描述 / 100 字关键词 / 副标题 / 类别 (Medical 主 + Health 副) / 版权
- **P1-10** (3d) 买 `chroniccare.app` 域名 + mkdocs 部署隐私政策 + App Store Connect URL

### 路线 3 (M 难度, 2-3 周): P0-3 + P0-4 + P0-7 + P0-8 — 法务 + IAP + iOS 现代
- **P0-3** (L, 2-4w 外部法务) 律师过审 3 份法律文档 + 删"草稿"字样
- **P0-4** (1w) pubspec 加 `in_app_purchase: ^7.0.0` + `StoreKitService` + IAP product `com.chroniccare.app.lifetime` $1.19 ≈ 8 元
- **P0-7** (0.5d) `UIBackgroundModes fetch` → `processing` + `BGTaskSchedulerPermittedIdentifiers`
- **P0-8** (1h) 新建 `Runner.entitlements` + pbxproj `CODE_SIGN_ENTITLEMENTS`

### 路线 4 (M 难度, 1-2 周): P1-4 + P1-5 + P1-6 + P1-7 + P1-8 + P1-9 — iOS 现代化
- **P1-4** (1h) `IPHONEOS_DEPLOYMENT_TARGET 13.0 → 14.0`
- **P1-5** (1h) `SUPPORTED_PLATFORMS` 加 `iphonesimulator` + `EXCLUDED_ARCHS`
- **P1-6** (30min) `PRODUCT_BUNDLE_IDENTIFIER com.chroniccare.chroniccare → com.chroniccare.app`
- **P1-7** (1d) LaunchScreen 自定义 (品牌色 + App 名 + icon)
- **P1-8** (3d) 设计师 AppIcon 1024x1024 替换占位
- **P1-9** (L, 4-8w 外部) NMPA 备案咨询

### 路线 5 (L 难度, 外部依赖 1-2 月, 可与 #3 #4 并行): P0-5 — AliyunSmsProvider 真接
- pubspec 加 `dio: ^5.0.0` + `crypto: ^3.0.0`
- `.env` 加 `ALIYUN_ACCESS_KEY_ID / SECRET / SIGN_NAME / TEMPLATE_CODE_CARE / LOST`
- 实现 `_signRequest()` (HMAC-SHA1) + POST `https://dysmsapi.aliyuncs.com/` + 5s timeout + 3 次重试
- **外部阻塞**: 法务 1-2 月审核短信模板 (避"药"/"病"敏感词) + 阿里云 AccessKey + SMS 签名备案

---

## 附录: iOS 上架一次性 Checklist

```
平台账号: [ ] Apple Developer Program $99/年 + [ ] Mac + [ ] Xcode
证书: [ ] iOS App IDs com.chroniccare.app + [ ] Distribution Cert + [ ] Provisioning Profile
App Store Connect: [ ] 创建 app + [ ] IAP product com.chroniccare.app.lifetime (Non-Consumable $1.19)
元数据: [ ] AppIcon 1024 + [ ] 4 尺寸 × 3 张截图 + [ ] 副标题 + [ ] 类别 Medical+Health + [ ] 版权 © 2026
       + [ ] 促销 170 字 + [ ] 描述 4000 字 + [ ] 关键词 100 字 + [ ] 17+ 年龄分级
URL: [ ] chroniccare.app 域名 + [ ] 隐私政策 URL + [ ] Support URL
合规: [ ] Privacy Nutrition Labels (Data Collection=None, Track=None) + [ ] ITSAppUsesNonExemptEncryption=false
测试: [ ] TestFlight 内部测试 ≥ 1 完整周期 (1-2 周) + [ ] 至少 2 tester 跑核心流程
审核: [ ] App Review 备注: 精神心理 + 医疗 + 失联通知 + PIPL + [ ] App Privacy 详情
```

---

## 总评: 上架就绪度 3.5/10

| 维度 | 评分 | 关键瓶颈 |
|------|------|---------|
| 代码 (lib/) | **9/10** | AliyunSmsProvider.send() 抛 UnimplementedError (release 失联通知不工作) |
| 平台 (ios/) | **7/10** | 缺 ITSAppUsesNonExemptEncryption / NSPhotoLibraryAddUsageDescription / Runner.entitlements / IPHONEOS_DEPLOYMENT_TARGET 13 太旧 / PRODUCT_BUNDLE_IDENTIFIER 重复 / AppIcon 占位图 |
| 法务 (assets/legal/) | **3/10** | privacy@chroniccare.app 占位邮箱 / 3 份文档"未经律师过审" / 隐私政策 URL 域名未注册 / NMPA 备案未做 |
| 业务 (StoreKit) | **1/10** | IAP 完全未集成, 8 元买断价挂在那 |
| 元数据 (App Store Connect) | **0/10** | 0 截图 / 0 描述 / 0 关键词 / 0 副标题 / 0 类别 / 0 英文 App 名 |
| 测试 (TestFlight) | **0/10** | 无 Mac 跑过, 0 崩溃率数据 |

**3 句话核心结论**:
1. **上架就绪度 3.5/10** — 代码层 90% ready, 平台配置 70% ready, 但法务 / IAP / 元数据 / TestFlight 4 个维度 0-30% ready, 离真正上架 1.0 还差 2-3 月。
2. **最大阻塞项**: **P0-3 (法务过审 3 份法律文档, 2-4 周外部) + P0-4 (IAP StoreKit, 1 周) + P1-10 (买域名建站, 1 周) 三件并行**。任意一个不修, Apple 5.1.1 / 3.1.5 / 4.0 审核必拒。
3. **3 个月内可修复项**: 9 个 P0 (含 1 个 L 外部 + 1 个 L 外部法务) + 10 个 P1 (含 1 个 L 外部 NMPA) + 5 个 P2, 总计 24 项; 假设 2 个 FTE + 律师 + 设计师 + 阿里云 + Apple 团队并行, 90 天可达 8.5/10 上架就绪度。
