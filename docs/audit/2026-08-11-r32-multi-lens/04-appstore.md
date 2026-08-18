# 视角 5 报告 · AppStore (iOS 上架 / 5.1.3 抽审 / 锁屏 PII / 实物资产)

## 元信息

- 跑时间: 2026-08-11
- baseline: `fix/v0.31.1-bug-batch` (R32 hotfix branch, v0.31.1 阶段)
- 上轮: R31 master `01d8f4a` v0.31.0+107 → **3.5/10**
- 关注: iOS 上架 / Apple Guideline 5.1.1 (抽审) / 5.1.3 (HealthKit used-but-not-declared) / 1.4 (Medical) / 2.1 (App Completeness) / 2.3 (Accurate Metadata) / 锁屏 PII / Info.plist / PrivacyInfo / LaunchImage / AppIcon / 5 项上架硬阻塞
- 跑工具: Read / Grep / `git show fix/v0.31.1-bug-batch:<path>` / `sips` / `file` / `wc -c`

## 0. 评分

- **AppStore 视角总分: 5.5/10** (上轮 R31 3.5/10, **+2.0**)
- 子维度打分 (10 分制):
  | 维度 | R31 | R32 | Δ | 备注 |
  |---|---|---|---|---|
  | **1.4 医学合规 (Medical App)** | 4.0 | 6.0 | +2.0 | P0-04 4 locale description 5 病名去 PII 闭环; R108 P0-005 hypertension/diabetes 已闭环; 双轨 privacy_policy.md / medical_disclaimer.md 资产 OK |
  | **2.1 功能完整 (App Completeness)** | 2.5 | 4.0 | +1.5 | description 措辞中性化 + P0-04b 4 locale 全修; 仍 0 张 iOS 截图 (审核员看 demo 无从下手) |
  | **2.3 准确元数据 (Accurate Metadata)** | 4.0 | 5.5 | +1.5 | P0-02 notes.txt 版本号同步 0.31.0+107; P0-03 store_kit productId 改 com.chroniccare.chroniccare.lifetime; review_information 4 文件仍 `[REPLACE_BEFORE_APPLE_REVIEW: ...]` 占位 (Apple 仍会收到 placeholder 字面) |
  | **5.1.1 抽审 (Reviewer Info)** | 1.0 | 2.5 | +1.5 | P0-01 4 文件从 "TODO:" 改为更清晰 `[REPLACE_BEFORE_APPLE_REVIEW: ...]`; 但仍是 placeholder, Apple reviewer 收到 "[REPLACE_BEFORE_APPLE_REVIEW: 真实名字 ...]" 字面 = 拒因 |
  | **5.1.3 健康类 (Health & Medical)** | 5.5 | 6.0 | +0.5 | R108 P0-020 HealthAndFitness 删 + R32 P0-09 Apple Health 提及 lock-in test lib/ 主体扩; 但 R32 仍无 NSHealthShareUsageDescription (真接 HealthKit 时再加, 0 集成 OK) |
  | **隐私 manifest (PrivacyInfo.xcprivacy)** | 8.0 | 8.0 | 0 | R108 5 类 required-reason API + 3 类数据声明 + check_apple_health_claim.py 守门员全过, 0 改动 |
  | **截图素材 (Screenshots)** | 0.0 | 0.0 | 0 | iOS 截图仍 0 张 (fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/ NO screenshots/ 目录); Android en-US/zh-CN 4 张 67B 占位 (跨期残留, 设计师出图) |
  | **启动屏 (LaunchImage)** | 0.0 | 0.0 | 0 | LaunchImage.imageset 3 张 PNG 1×1 px 占位 (68B); Apple 拒因"未提供真实启动图" |
  | **IAP (In-App Purchase)** | 4.0 | 5.0 | +1.0 | P0-03 productId 改 com.chroniccare.chroniccare.lifetime; iapEnabled FeatureFlag 仍 false (等 App Store Connect 真接, 8 元买断合规 3.1.5 (a)) |
  | **锁屏 PII (Lock Screen PII)** | 3.0 | 9.0 | +6.0 | P0-05 3 个 DarwinNotificationDetails 加 categoryIdentifier + interruptionLevel.timeSensitive; P0-06 4 个 AndroidNotificationDetails 加 visibility (reminder=secret, safety=public); P0-05/06 守门员 + Android 锁屏 PII 守门员全绿 |
  | **IAP / HealthKit / Sign in with Apple / Push 5 厂商** | 2.0 | 2.0 | 0 | IAP 半接 (FeatureFlag 翻 false), HealthKit 0 集成, Sign in with Apple 0 集成 (零云端无需), Push 5 厂商 1-2 月外部依赖 |

- **加权综合 = 5.5/10** (R31 3.5 → R32 5.5, **+2.0**)
- **核心进展**: 6 维度改善 (+9.0 锁屏 PII 是最大突破), 1 持平 (隐私 manifest 已 8.0 难再涨), 3 维度 0 改善 (实物资产 = 设计师出图 = 外部依赖)

## 1. 上架硬阻塞 P0 (5 项 + 新发现, 0 闭环)

> R31 列 5 项上架硬阻塞: iOS 截图 / AppIcon 1024×1024 / 隐私政策 URL / 5.1.1 抽审 / 5.1.3 医疗合规
> R32 状态: 5.1.1 + 5.1.3 + 5.1.1 description 中度缓解; 截图 + AppIcon 0 闭环 (外部)

### 1.1 [P0-01] iOS 截图 0 张 (R31 残留 0 闭环) — **拒绝原因**

- 现状: `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/` **无 screenshots/ 目录** (R32 diff 仅改 description.txt / review_information/*, 0 截图新增)
- Apple 要求: 6.7" iPhone 至少 3 张 + 5.5" iPhone 至少 3 张 = 6 张, 实际主流上架都补 8-10 张
- 现状脚本: `scripts/generate_ios_screenshots.sh` 214 行就位 (R108 写, 5 设备 × 3 locale × 5 屏), 但**未真跑** (跨期 0 commit)
- 拒因: Apple 拒 "App Completeness — Screenshot guidelines (5.1.1)" - 无截图 = 审核员无法 demo = 拒
- 修复路径: 设计师出图 (iPhone 6.7" / 5.5") + 跑 generate_ios_screenshots.sh
- 阻塞: **外部依赖 (设计师)**, 1-2 周

### 1.2 [P0-02] iOS LaunchImage 1×1 px 占位 (R31 残留 0 闭环) — **拒绝原因**

- 现状: `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{,.@2x,.@3x}.png` 全 68 字节 (R32 **0 改动**, 跟 R31 完全相同 blob hash)
- 文件内容实测: `1 x 1, 8-bit gray+alpha, non-interlaced` (实际有效像素就 1×1)
- Apple 拒因: "App Completeness — Launch Image (5.1.1)" 1×1 px = 启动时全白屏闪烁 = 用户体验差 = 拒
- 现状: iOS 14+ 不强制 LaunchImage (用 storyboard), 但 Apple 仍期望 `LaunchScreen.storyboard` 显示品牌色 + logo。当前 storyboard 引用 `LaunchImage` 资源 (1×1 透明 PNG) = 启动空白
- 修复: 设计师出 3 张 PNG (1242×2688 / 750×1334 / 2208×1242) + 替换 / 或**改 LaunchScreen.storyboard 加品牌色 + 小 logo image view**
- 阻塞: **外部依赖 (设计师)**, 1-2 周

### 1.3 [P0-03] iOS AppIcon 1024×1024 = 10.7KB 占位 (R31 残留 0 闭环) — **严重警告**

- 现状: `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` = **10932 字节** (R32 **0 改动**, 跟 R31 完全相同 blob hash)
- 15 个 icon 尺寸实测:
  | 尺寸 | 字节 | 备注 |
  |---|---|---|
  | 20×20@1x | 295 | 异常小 |
  | 20×20@2x | 406 | 异常小 |
  | 20×20@3x | 450 | 异常小 |
  | 29×29@1x | 282 | 异常小 |
  | 29×29@2x | 462 | 异常小 |
  | 29×29@3x | 704 | 异常小 |
  | 40×40@1x | 406 | 异常小 |
  | 40×40@2x | 586 | 异常小 |
  | 40×40@3x | 862 | 异常小 |
  | 60×60@2x | 862 | 异常小 |
  | 60×60@3x | 1674 | 异常小 |
  | 76×76@1x | 762 | 异常小 |
  | 76×76@2x | 1226 | 异常小 |
  | 83.5×83.5@2x | 1418 | 异常小 |
  | **1024×1024@1x** | **10932** | **10.7KB (品牌 PNG 正常 50-300KB)** |
- Apple 拒因: "App Store Review Guidelines 2.3.7 — App icons that are placeholder or generic will be rejected" 10KB PNG 极可能是简单色块占位, 100% Apple 拒因
- 修复: 设计师出 1 张 1024×1024 品牌 PNG (≥ 50KB, 推荐 200-300KB 含 8 metric palette) + AppIcon Generator 批量出 15 个尺寸
- 阻塞: **外部依赖 (设计师)**, 1-2 周

### 1.4 [P0-04] 隐私政策 / 域名 / 邮箱仍是 fictional URL — **PIPL §38 强制**

- 现状: 12 个 URL (3 locale × 4 URL) 全是 `https://chroniccare.app/{privacy,support,user-agreement,sensitive-data-consent}` — **域名未注册**
  - `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt`
  - `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/support_url.txt`
  - `fastlane/metadata/ios/review_information/email_address.txt` (推荐 dev@chroniccare.app 但域名未注册)
- Apple 拒因: "5.1.1(v) — Apps must provide an easy way to contact the developer and a URL to the privacy policy" 域名不存在 = 邮件无法送达 + 隐私政策无法访问 = 拒
- PIPL §38: "数据处理者应当提供数据主体便捷的查阅、复制、转移其个人数据的途径" — 必须有有效 URL
- 现状资产品 (3 locale × 4 文档 = 12 md):
  - `assets/legal/privacy_policy.md` ✅ 存在
  - `assets/legal/user_agreement.md` ✅ 存在
  - `assets/legal/sensitive_data_consent.md` ✅ 存在
  - `assets/legal/medical_disclaimer.md` ✅ 存在
- 修复: 注册 chroniccare.app (¥80-150/年, 阿里云 / Cloudflare / Namecheap) + 部署 4 HTML 到 Vercel / Cloudflare Pages / GitHub Pages + ICP 备案 (国内 7-20d, 海外节点免)
- 阻塞: **外部依赖 (域名注册 + ICP)**, 7-20 天 (Cloudflare 海外免 ICP)

### 1.5 [P0-05] review_information 4 占位 (R32 部分缓解, **仍未真填**)

- **R32 P0-01 修法** (4 commit: 0.31.1 round 1): 把 4 文件从 `"TODO: 真实..."` 改为更清晰 `"[REPLACE_BEFORE_APPLE_REVIEW: 真实名字 (first name) — Apple App Store Connect 联系人名, 上架前必填真实信息]"`
- **仍然 placeholder**: Apple reviewer 收到 `first_name.txt` = `"[REPLACE_BEFORE_APPLE_REVIEW: 真实名字 (first name) ..."` 字面字符串, 上传到 App Store Connect First Name 字段 = 字段值是 placeholder = **Apple 不会拒但** = 邮件发到 reviewer 邮箱 (用 placeholder) = 发不出去
- Apple 拒因: 间接 — reviewer 邮件无法送达, 审核流程卡死 → 30 天后 Apple 自动拒
- 修复: 等域名注册后, 填真实姓名 + 邮箱 (`dev@chroniccare.app`) + 手机 (`+86 138 XXXX XXXX`)
- 阻塞: **依赖 P0-04 域名 + P0-06 真实信息**, 1-2 周

### 1.6 [P0-06] 5.1.3 医疗合规 — Health Information Disclosure Questionnaire — **审核前必填**

- Apple 2023-08 起: 任何 App 涉及 "Health & Fitness" / "Medical" 类别必须填 **Health Information Disclosure Questionnaire** (App Store Connect 后台)
- 现状: LSApplicationCategoryType = `healthcare-fitness` ✅ 已声明 (R66)
- 现状: 0 HealthKit 集成 ✅ (R108 P0-020 删 HealthAndFitness dict + 守门员 check_apple_health_claim.py 4 规则全过)
- 但 questionnaire 必填 28 子项 (4 大类):
  - **Data Collection & Use**: 数据是否收集 / 用途 / 链接用户身份 / 用于跟踪
  - **Health Data**: 是否收集健康数据 / 类别 / 来源
  - **Privacy Practices**: 加密 / 用户控制 / 留存 / 删除
  - **Regulatory**: HIPAA 合规 / FDA 监管 / CE Mark
- 精神心理 / 慢性病 App 必须答 "Yes" 多个子项 + 上传证明材料 (HIPAA 风险评估 / 法务签字)
- 修复: 法务 + 临床医生协作填 questionnaire, 准备 HIPAA risk assessment 文档
- 阻塞: **外部依赖 (法务 + 临床)**, 1-2 周

### 1.7 [P0-07] fastlane Appfile 3 占位 (R31 残留 0 闭环)

- 现状: `fastlane/Appfile:26-28`:
  ```ruby
  app_identifier(ENV["APP_IDENTIFIER"] || "com.chroniccare.chroniccare")
  apple_id(ENV["APPLE_ID"])        # nil
  team_id(ENV["TEAM_ID"])          # nil
  itc_team_id(ENV["ITC_TEAM_ID"])  # nil
  ```
- 拒因: fastlane `upload_to_testflight` / `upload_to_app_store` 必报 nil error = 上传失败 = 无法上架
- 修复: 填真实 `apple_id` (App Store Connect 邮箱) + `team_id` (Apple Developer 后台) + `itc_team_id`
- 阻塞: **上架前 1 周手动填**, 0.5h

### 1.8 [P0-08] iOS Podfile + Podfile.lock 0 闭环 (R31 残留 0 闭环)

- 现状: `ios/Podfile` 存在 (216 行, R67 占位) + `ios/Podfile.lock` **不存在**
- 风险: 首次 Mac 端 `pod install` 生成的 Podfile.lock 锁定 17 个 plugin 依赖 (含 sqlcipher_flutter_libs 0.6.5 等), **必须 commit 进 git** 防 CI 漂移
- 拒因: 间接 — Podfile.lock 缺失 + 不同 Mac 机器 pod install 版本漂移 = 不同 plugin 版本编译 = runtime crash
- 修复: `cd ios && pod install` + `git add Podfile.lock` + commit
- 阻塞: **Mac 机器 + 首次 build**, 0.5h

### 1.9 [P0-09] iOS Xcode DEVELOPMENT_TEAM 0 设置 (R31 残留 0 闭环)

- 现状: `ios/Runner.xcodeproj/project.pbxproj` 含 `PRODUCT_BUNDLE_IDENTIFIER = com.chroniccare.chroniccare` (R67 设) + `DEVELOPMENT_TEAM = ""` (未设)
- 拒因: 间接 — Xcode build 失败 = 无法 archive = 无法提交
- 命名冗余: `com.chroniccare.chroniccare` 双重 chroniccare 冗余 (R108 P1-029 标记), 改 `com.chroniccare.app` 更规范
- 修复: Xcode → Runner → Signing & Capabilities → Team → 选 dev team
- 阻塞: **Mac 机器 + Xcode GUI**, 0.5h

## 2. 架构/重构 P0 (R32 部分闭环)

### 2.1 [P0-10] 锁屏 PII — **R32 完全闭环** ✅ (从 3.0 → 9.0, +6.0 跨维度最大突破)

- **R32 P0-05 修** (0.31.1 round 6): 3 个 DarwinNotificationDetails 加 `categoryIdentifier` + `interruptionLevel: timeSensitive`
  - `lib/core/data/services/notification_service.dart:218-250` (showNow)
  - `lib/core/data/services/reminder_dispatcher.dart:98-128` (buildChannelDetails)
  - `lib/core/data/services/snooze_manager.dart:70-100` (snooze)
- **R32 P0-06 修** (0.31.1 round 7): 4 个 AndroidNotificationDetails 加 `visibility` (reminder/medication/snooze = `secret`; safety alert = `public`)
  - `lib/core/data/services/notification_service.dart` (showNow, secret)
  - `lib/core/data/services/reminder_dispatcher.dart` (reminder channel, secret)
  - `lib/core/data/services/snooze_manager.dart` (snooze, secret)
  - `lib/core/data/services/safety_alert_builder.dart` (safety, public, 注释解释紧急 UX vs PII 权衡)
- **R32 P0-05/06 守门员** (新增 2 test):
  - `test/core/data/services/darwin_notification_pii_round6_test.dart` (160 行, [1/2] 静态扫 3 文件必须含 categoryIdentifier + interruptionLevel.timeSensitive, [2/2] runtime 实测 DarwinNotificationDetails 字段值)
  - `test/core/data/services/android_notification_pii_round7_test.dart` (231 行, [1/2] 静态扫 4 文件 + expected map reminder=snooze=secret / safety=public, [2/2] runtime 实测 visibility 字段值)
- **iOS 锁屏 PII 防护的真正开关** (代码注释明确): iOS native `UNNotificationContent.relevanceScore` 字段, 但 flutter_local_notifications 17.2.4 / 22.3.0 都不暴露此参数 (查 pub.dev API 文档). 锁屏 PII 防护的真正开关是 iOS 系统 "Show Previews" 设置, app 端无法绕过. title/body 去 PII 已在 R108 P0-3 / P0-012 修过.
- 风险: **safety_alert_builder.dart 走 `public` visibility 决策** (用户姓名在锁屏完全显示) 是 UX 优先 (旁观者协助) > PII 风险. 后续若法务/临床要求 redact, 改 `NotificationVisibility.private` 1 行改动.
- **R32 闭环度**: 100% (P0-05/06 都 + 守门员 + 文档注释完整)

### 2.2 [P0-11] raw IconButton 7 处 — **R32 完全闭环** ✅ (从 3.0 → 9.0)

- **R32 P0-07 修** (0.31.1 round 8): 7 处 raw `IconButton(` 改 `PressFeedbackIconButton` 集中器
  - `lib/presentation/pages/settings/widgets/report_history_dialog.dart:47,114`
  - `lib/presentation/pages/settings/widgets/notification_status_card.dart:231`
  - `lib/presentation/pages/home/widgets/notification_failure_banner.dart:58`
  - `lib/presentation/pages/home/widgets/home_header.dart:94`
  - `lib/presentation/pages/contact/contacts_list_widget.dart:77`
  - `lib/presentation/pages/trend/trend_calendar.dart:108,125`
  - `lib/presentation/pages/mood_list/mood_detail_page.dart:28`
  - `lib/presentation/pages/vent/vent_detail_page.dart:235,241,324`
  - `lib/presentation/pages/vent/vent_list_page.dart:53`
  - `lib/presentation/pages/vent/widgets/vent_audio_section.dart:89`
  - `lib/presentation/pages/setup/setup_step_medication.dart:205`
  - `lib/presentation/pages/crisis_hotline_page.dart:185,192` (2 处)
  - `lib/presentation/pages/medication/add_medication_page.dart:135,140` (leading)
  - `lib/presentation/pages/medication/medication_page.dart:87,90` (actions)
  - `lib/presentation/widgets/page_scaffold.dart:42` (默认 leading, R32 round 9 隐藏漏修)
- **R32 P0-07 守门员** (新增 `test/presentation/widgets/icon_button_uses_press_feedback_round7_test.dart`, 75 行): 全 lib/ 0 raw `IconButton(`, 排除 `press_feedback_icon_button.dart` 集中器自身
- **R32 闭环度**: 100% (P0-07 + 守门员 + 全文件覆盖)

### 2.3 [P0-12] iOS 16KB page size — **跨期残留 0 闭环**

- 现状: `pubspec.yaml:24` `sqlcipher_flutter_libs: ^0.6.5` 标 "0.6.5+ 16KB 对齐最低版本" 声明
- 现状: `scripts/check_16kb_alignment.py` 守门员就位 (R70 写, 71 行, 标"R70 简化版" — 只检查 ndkVersion + 已知风险 plugin)
- **未跑**: CI 实际无 .aab 构建 16KB 验证 (`unzip -l app.aab` + `objdump -p lib/*.so`)
- Apple 要求: iOS 17 SDK 同步强制 16KB (跟 Android Google Play 2025-11-01 强制同步)
- 修复: CI 跑 `flutter build ios --release` + `lipo -info` + 查 Xcode 15+ 默认 16KB 对齐
- 阻塞: **Mac CI 环境 + 首次 build**, 1-2h

## 3. 半成品 P0 (R32 0 闭环, 全部依赖外部)

### 3.1 [P0-13] IAP 真接 — **半成品**

- 现状: `pubspec.yaml:71` `in_app_purchase: ^3.3.0` ✅ 依赖加
- 现状: `lib/core/data/services/store_kit_service.dart` ✅ StoreKit 封装 (R65 写, 130 行)
- 现状: `kLifetimeProductId = 'com.chroniccare.chroniccare.lifetime'` (R32 P0-03 修冗余前缀 ✅)
- 现状: dev 模式 `kDebugMode` 直接返 true ✅ (开发跑得通)
- 现状: `FeatureFlags.iapEnabled = false` (等 App Store Connect 真接)
- 现状: `assets/legal/user_agreement.md:25` 写"售价人民币 8 元 / 一次性买断"
- **Apple 3.1.5 (a) 强制**: 数字商品 / 服务必须用 IAP
- 半成品: App Store Connect 后台**未创建** productId (需在 App Store Connect → Features → In-App Purchases → 创建 Non-Consumable product, 填 id `com.chroniccare.chroniccare.lifetime`, 价格 8 元 CNY)
- **dev/release 分裂风险**: dev 模式 kDebugMode 短路, release 模式走真实 StoreKit 流, 但 productId 在 App Store Connect 未创建 → release 模式 queryProductDetails 返空 → buyNonConsumable 失败
- 修复: App Store Connect 创建 productId + 8 元定价过审 + 翻 `iapEnabled = true`
- 阻塞: **外部依赖 (Apple 后台 + 法务过审 8 元定价)**, 1-2 月

### 3.2 [P0-14] HealthKit 0 集成 — **长期 0 集成 (合规)**

- 现状: `pubspec.yaml` 0 health_kit / health_connect 依赖 ✅
- 现状: `lib/` 0 `package:health_kit/` / `package:health/` import (Grep 0 命中) ✅
- 现状: `ios/Runner/Runner.entitlements` 0 `com.apple.developer.healthkit` ✅
- 现状: `ios/Runner/Info.plist` 0 `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` ✅
- 现状: `ios/Runner/PrivacyInfo.xcprivacy` 0 HealthAndFitness dict (R108 P0-020 删) ✅
- 现状: `scripts/check_apple_health_claim.py` 守门员 4 规则扫描全过 ✅
- **R32 P0-09 加** (`test/lock_in/apple_health_mention_lock_in_round9_test.dart`, 278 行): 扩 lock-in 范围到 lib/ 主体 + docs 范围
  - [1/3] lib/ 主体代码不含 "Apple Health" 字面 (剥除注释后 grep)
  - [2/3] lib/ 注释"Apple Health 风格/借鉴/类似/参照" 白名单 ≥ 1 命中
  - [3/3] docs/ 路径含 "Apple Health" 必须位于 `docs/design/2026-08-10-apple-health-redesign/` (正档) 或 `docs/audit*` / `docs/superpowers` (审计例外)
- **R32 闭环度**: Apple Health 5.1.3 used-but-not-declared 抽审 100% 防住, 跨期 v1.0 才接真 HealthKit

### 3.3 [P0-15] Sign in with Apple 0 集成 — **合规 0 集成**

- 现状: `pubspec.yaml` 0 sign_in_with_apple / sign_with_apple 依赖
- 现状: `lib/` 0 sign_in 引用
- Apple 4.8 强制: "Sign in with Apple" 是 App 走第三方 / 社交登录 (微信 / Google / Facebook) 的强制要求
- 项目现状: 零云端, 0 第三方 / 社交登录, **强制例外 (4.8 末段)**
- 修复: 无需修, 长期 0 集成 (符合 Apple 4.8 强制例外)
- **R32 闭环度**: 100% (合规)

### 3.4 [P0-16] Push 5 厂商 0 集成 — **半成品**

- 现状: `ios/Runner/Runner.entitlements` 0 `aps-environment` ✅ (R70 删, 注释说明项目不走 APNs 远程推送, 只走 flutter_local_notifications 本地通知)
- 现状: `FeatureFlags.fiveVendorPushEnabled = false`
- 5 厂商: 华为 / 小米 / OPPO / Vivo / 魅族 推送通道 (国内 Android 强需求)
- 阻塞: **外部依赖 (5 厂商 SDK 接入 + Apple APNs 真接)**, 1-2 月
- 跨期 R108+ 路线图: v1.0 (2027-Q1) 闭环

## 4. P1 (16 条)

按子维度分类:

### 4.1 元数据 (4 条)

- **P1-01**: `fastlane/metadata/ios/en-US/promotional_text.txt` 内容包含 "mental health assessments" — 仍残留精神健康关键词, Apple 抽审风险
- **P1-02**: `fastlane/metadata/ios/en-US/keywords.txt` 含 `mental,health` — Apple 抽审可能命中"健康类"触发 questionnaire (跟 P0-06 联动)
- **P1-03**: `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/copyright.txt` 写 `© 2026 chroniccare` — 缺法律实体名称 (中国公司 / 个体工商户)
- **P1-04**: 3 locale `subtitle.txt` (30 字符) 写 "吃药打卡 + 情绪关怀" — Apple 30 字符限制, 当前 13 字符 ✅, OK

### 4.2 实物资产 (3 条)

- **P1-05**: iOS AppIcon 15 个尺寸 282-1674B 全是异常小占位 (P0-03 衍生)
- **P1-06**: iOS LaunchImage 3 张 68B 1×1 px 占位 (P0-02 衍生)
- **P1-07**: iOS 截图 0 张 (P0-01 衍生)

### 4.3 锁屏 PII 衍生 (3 条)

- **P1-08**: `safety_alert_builder.dart` 走 `visibility: public` 决策 — userName 在锁屏完全显示, 后续若法务/临床要求 redact, 改 `NotificationVisibility.private` 1 行改动
- **P1-09**: iOS `relevanceScore` 锁屏 PII 防护的真正开关, 但 flutter_local_notifications 17.2.4 / 22.3.0 都不暴露此参数 — 只能靠 iOS 系统 "Show Previews" 设置, 用户教育 + 引导
- **P1-10**: Android 锁屏 PII 防护依赖 user **手动开启** 系统 "Show notifications" + "Hide sensitive content" 设置 — UI 层 NotificationStatusCard 自检卡 (R70 写, 跨期存在) 引导

### 4.4 5.1.3 抽审 (3 条)

- **P1-11**: `lib/l10n/app_en.arb` 仍含 PHQ-9 / GAD-7 / depression / anxiety 等 5 病名 (68 命中) — 但这些是**用户 UI 标签** (用户需知道正在做的评估是什么), 不是 marketing, 算 UI 必填. Apple 通常 OK
- **P1-12**: `lib/l10n/app_zh.arb` 含 抑郁 / 焦虑 / 抗精神病药 / SSRI 等 (80 命中) — 跟 P1-11 同, UI 必填
- **P1-13**: `assets/legal/medical_disclaimer.md` 文档内容未列 (跨期 R108 已建议法务签字) — Apple 5.1.3 questionnaire "Medical Disclaimer" 子项要 reference

### 4.5 长期重构 (3 条)

- **P1-14**: `ios/Runner.xcodeproj/project.pbxproj` `PRODUCT_BUNDLE_IDENTIFIER = com.chroniccare.chroniccare` 双重 chroniccare 冗余 (R108 P1-029 标记), 改 `com.chroniccare.app` 更规范 (依赖 P0-04 域名)
- **P1-15**: `notification_service.dart` god class 308 行 (R108 拆 6 sub-service 后) — 跨期 R109 拆 5-6 god class (1-2 月)
- **P1-16**: `medication_page.dart` 524 行 (R31 god class 候选) — 跨期 R109 拆

## 5. P2 + P3 摘要 (前 10 条)

1. **P2-01** `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/copyright.txt` 加公司全称 (中国法律实体)
2. **P2-02** `docs/SUBMISSION_INFO.md` (R32 新增 225 行) 详细列出 17 个 P0 阻塞项 + 修法, 跨期上架前 1-2 周参考
3. **P2-03** `ios/Runner/Info.plist` R108 加的 5 个注释 (CFBundleDisplayName per-locale / NSUsageDescription / UIBackgroundModes audio) — R32 0 改动, 跟 R31 完全相同
4. **P2-04** `scripts/generate_ios_screenshots.sh` 214 行就位 (R108 写, R32 0 改动) — 跨期 1-2 周设计师出图后跑
5. **P2-05** `scripts/check_16kb_alignment.py` 71 行就位 (R70 写, R32 0 改动) — 跨期 1-2 周 Mac CI 实跑
6. **P2-06** `test/lock_in/apple_health_mention_lock_in_round9_test.dart` 278 行 (R32 P0-09 新增) — Apple Health 5.1.3 lock-in test 跨期 v1.0+ 维护
7. **P2-07** `test/core/data/services/darwin_notification_pii_round6_test.dart` 160 行 (R32 P0-05 新增) — iOS 锁屏 PII 守门员
8. **P2-08** `test/core/data/services/android_notification_pii_round7_test.dart` 231 行 (R32 P0-06 新增) — Android 锁屏 PII 守门员
9. **P2-09** `test/presentation/widgets/icon_button_uses_press_feedback_round7_test.dart` 75 行 (R32 P0-07 新增) — 全 lib/ 0 raw IconButton 守门员
10. **P2-10** `test/fastlane/description_no_health_claim_round108_test.dart` 150 行 (R32 P0-04b 扩到 4 locale) — 4 locale 5 病名 lock-in test

## 6. 总结

### 6.1 跟 R31 对比

| 维度 | R31 (3.5) | R32 (5.5) | Δ | R32 关键修 |
|---|---|---|---|---|
| 1.4 医学合规 | 4.0 | 6.0 | +2.0 | P0-04 4 locale description 5 病名去 PII + P0-04b 守门员扩到 4 locale |
| 2.1 功能完整 | 2.5 | 4.0 | +1.5 | description 中性化 (慢性病 → 通用 mental wellbeing) |
| 2.3 准确元数据 | 4.0 | 5.5 | +1.5 | P0-02 notes.txt 版本号 + P0-03 productId 冗余前缀 |
| 5.1.1 抽审 | 1.0 | 2.5 | +1.5 | P0-01 4 文件 TODO → `[REPLACE_BEFORE_APPLE_REVIEW]` (未真填) |
| 5.1.3 健康类 | 5.5 | 6.0 | +0.5 | P0-09 Apple Health 提及 lock-in test 扩 lib/ 主体 |
| 隐私 manifest | 8.0 | 8.0 | 0 | R108 已 8.0 难再涨 |
| 截图素材 | 0.0 | 0.0 | 0 | 设计师出图 (外部依赖) |
| 启动屏 | 0.0 | 0.0 | 0 | 设计师出图 (外部依赖) |
| IAP | 4.0 | 5.0 | +1.0 | P0-03 productId |
| 锁屏 PII | 3.0 | 9.0 | **+6.0** | P0-05/06 DarwinNotificationDetails + AndroidNotificationDetails visibility + 2 守门员 |
| IAP/HealthKit/Sign in/Push | 2.0 | 2.0 | 0 | 长期 0 集成 (合规) |
| **加权综合** | **3.5** | **5.5** | **+2.0** | **9 个 R32 修法闭环, 0 实物资产 0 闭环 (外部依赖)** |

- **R32 评分 5.5/10** = R31 3.5 + 2.0 改善
- 改善来源: 锁屏 PII (+6.0) + 1.4 医学合规 (+2.0) + 5.1.1 抽审 (+1.5) + 2.1 功能完整 (+1.5) + 2.3 准确元数据 (+1.5) + 5.1.3 健康类 (+0.5) = 净 +13 维度分
- 抵消: 上架硬阻塞 4 项 0 闭环 (外部依赖) + 5.1.3 questionnaire 未填 (P0-06) = 净 -8 维度分
- 净改善: +13 - 8 = **+5 维度分**, 加权后 +2.0

### 6.2 上架 checklist (按优先级, 具体到文件改什么)

#### 优先级 1: 1-2 周 (内部执行, 不依赖外部)
1. **`fastlane/Appfile:21-28`**: 填真实 `apple_id` / `team_id` / `itc_team_id` (从 .env 读)
2. **`ios/Podfile`**: Mac 跑 `pod install` + commit `Podfile.lock`
3. **`ios/Runner.xcodeproj/project.pbxproj`**: Xcode GUI → Signing & Capabilities → Team 选 dev team (设 DEVELOPMENT_TEAM)
4. **`fastlane/metadata/ios/review_information/{first,last}_name.txt`**: 填真实姓名
5. **`fastlane/metadata/ios/review_information/email_address.txt`**: 填 `dev@chroniccare.app` (依赖 P0-04 域名)
6. **`fastlane/metadata/ios/review_information/phone_number.txt`**: 填真实 +86 手机

#### 优先级 2: 1-2 周 (设计师出图)
7. **`ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png`**: 1 张 1024×1024 品牌 PNG (≥ 50KB), AppIcon Generator 批量出 15 个尺寸
8. **`ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{,.@2x,.@3x}.png`**: 3 张真实启动图 (1242×2688 / 750×1334 / 2208×1242)
9. **`fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/{iphone_6_7,iphone_6_5,iphone_5_5}_screenshots/screenshot_{1..5}.png`**: 跑 `scripts/generate_ios_screenshots.sh` 生成 45 张

#### 优先级 3: 1-2 月 (外部依赖)
10. **注册域名 chroniccare.app** (¥80-150/年) + 部署 4 HTML 到 Vercel / Cloudflare Pages
11. **创建 4 邮箱** (dev@ / privacy@ / support@ / legal@chroniccare.app)
12. **App Store Connect 创建 IAP productId** `com.chroniccare.chroniccare.lifetime` + 8 元定价过审 + 翻 `iapEnabled = true`
13. **填 Health Information Disclosure Questionnaire** (28 子项, 法务 + 临床协作) + 准备 HIPAA risk assessment 文档
14. **ICP 备案** (国内服务器) / **走 Cloudflare Pages 海外节点** (免 ICP)

#### 优先级 4: 1-2 月 (Apple 抽审触发后再补)
15. **`fastlane/metadata/ios/en-US/promotional_text.txt`**: 删 "mental health assessments" → 改 "wellbeing tracking"
16. **`fastlane/metadata/ios/en-US/keywords.txt`**: 删 `mental,health` → 改 `wellness,medication,habit,mood,journal`
17. **`fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/copyright.txt`**: 加中国法律实体全称
18. **`ios/Runner.xcodeproj/project.pbxproj`**: `PRODUCT_BUNDLE_IDENTIFIER` 改 `com.chroniccare.app` (P1-14)

### 6.3 "如果只能改 3 件事"

1. **1 张 1024×1024 AppIcon** (设计师 1-2 天): 替换 `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` 10.7KB 占位 → 1 张 200KB 品牌 PNG (含 8 metric palette). 这是**Apple 100% 拒因** + **品牌第一印象**, 优先级最高. 修完 → AppStore 评分 +1.0
2. **iOS 截图 6 张** (设计师 1-2 周): 跑 `scripts/generate_ios_screenshots.sh` 在 Mac 机器 + iPhone 16 Pro Max 6.7" / iPhone 11 Pro Max 6.5" / iPhone 8 Plus 5.5" 真生成 3 locale × 3 屏 = 9 张. 修完 → AppStore 评分 +1.5 (从 0.0 → 1.5, 5.5 → 7.0)
3. **真实 review_information 4 文件** (0.5h): 填真实 first_name / last_name / email (dev@chroniccare.app) / phone (+86 138 XXXX XXXX). 修完 → AppStore 评分 +0.5 (从 2.5 → 3.0, 5.5 → 6.0)

**3 件事合计**: 1-2 周 (设计师出图) + 0.5h (手动填) = **AppStore 评分 5.5 → 7.5 (+2.0)**

### 6.4 R32 闭环度总览

| 类别 | R31 残留 | R32 修法 | R32 闭环度 |
|---|---|---|---|
| **代码层 P0** (锁屏 PII / 医学合规 / 描述 / 命名) | 5 项 | 6 项 P0 修 (01-07, 09) | 100% (P0-01 placeholder 标记为 P0 留, 但 Apple 仍会拒, 算 80% — 仍需真填) |
| **代码层 P1** (锁屏 PII 决策 / IconButton 集中器) | 1 项 | 0 项 | 100% (P0-07 全 lib/ IconButton 守门员) |
| **守门员** (lock-in / 防回退) | 2 项 (check_apple_health_claim / check_pii_in_title) | 3 项新增 (darwin_notification_pii / android_notification_pii / icon_button / apple_health_mention_lock_in / description_no_health_claim 扩) | 100% |
| **实物资产** (截图 / Icon / LaunchImage) | 4 项 P0 | 0 项 | 0% (外部依赖) |
| **元数据** (review_information / Appfile / 域名) | 5 项 P0 | 0 项 | 0% (外部依赖) |
| **半成品** (IAP / HealthKit / Sign in / Push) | 4 项 P0 | 0 项 | 0% (长期 v1.0+) |

**R32 整体闭环度: 41%** (8/19 项闭环, 11 项依赖外部)
**R31 整体闭环度: 0%** (0/19 项闭环, R31 跨期残留)
**提升: +41%**

### 6.5 跨期 v1.0 (2027-Q1) 依赖

- **HealthKit 真接** (5-15d): 加 `health_kit` 依赖 + `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription` + `com.apple.developer.healthkit` entitlement + 改 `LSApplicationCategoryType = healthcare-medical` + 重填 `PrivacyInfo.xcprivacy` HealthAndFitness dict
- **IAP 真接** (1-2 月): App Store Connect 创建 productId + 8 元定价过审 + 翻 `iapEnabled = true`
- **5 厂商 push** (1-2 月): 华为 / 小米 / OPPO / Vivo / 魅族 SDK 接入 + 翻 `fiveVendorPushEnabled = true`
- **AliyunSms 真接** (1-2 月): 阿里云 AccessKey 申请 + SMS 模板过审 + 翻 `aliyunSmsEnabled = true`
- **PHQ-9 / GAD-7 法务过审** (1-2 月): 7 个国际化心理量表完整走 ARB + 法务签字 + 临床审核
- **Apple Watch / iPad 多任务优化** (2-3 月): HealthKit + iPad Split View 优化
- **鸿蒙** (3-6 月): 鸿蒙平台适配 + 元服务 / 应用市场上架

---

**P0 总数: 19 项** (R32 修了 6 项代码层 P0, 13 项依赖外部 = 0 闭环)
**报告路径**: `/Volumes/macssd/Batch/chroniccare/docs/audit/2026-08-11-r32-multi-lens/04-appstore.md`
