# v0.27 R69 AppStore 上架审计

**审计时间**: 2026-08-01
**项目**: chroniccare(精神心理患者吃药打卡 App)
**版本**: 0.27.0+64(`pubspec.yaml:4`)/ working tree 干净 / `d691551` = R68 集中修复 commit
**视角**: Apple App Store 上架合规
**审计模式**: 增量(对照 R68 报告 + d691551 commit diff)
**基线**: R68 ⭐ / R67 11 项 P0 已修 / R68 10 P0 + 10 P1 + 6 P2 / R69 实际剩 9 P0 + 9 P1 + 5 P2

**项目基线**: 1285 tests pass / 0 fail / 0 analyzer error / 5 warning / 181 info / 16 守护脚本全绿
**R68 commit diff**(`git show d691551 --stat`):
- 20 文件 / +101 / -14
- 3 视角共识 P0 真接:**CC-1 setup ConsentDialog** / **CC-3 IAP 8 元买断代码层** / **CC-6 CareEngine safety consent 撤回业务层**
- 关联: `lib/core/data/feature_flags.dart:38` `_prodIapEnabled = false`(原 true)
- 关联: `lib/domain/usecases/fire_care_strategy.dart:155, 200-209` 加 `isSafetyConsentWithdrawn` 字段 + 入口早返
- 关联: `lib/core/data/database/app_database.dart:307-315` `saveSetup` 改走 `contactConsents` 等长数组
- 关联: `lib/presentation/pages/setup/setup_page.dart` 拒绝任一联系人同意 → 终止 setup
- 关联: `lib/presentation/pages/home/home_page.dart` `_fireCareEngine` 注入 consent 状态
- 关联: `lib/l10n/app_*.arb` 加 `setupConsentRejected` key
- 关联: `test/data/feature_flags_round67_test.dart` 6 处 expected 同步改 `isFalse`
- **不在 d691551 diff 里**(R68 报告说"已修"但实际 R68 没动):`fastlane/Appfile` 4 处 TODO / 33 张 iOS 截图 / 3 张 app_icon / 3 份法律 md 顶部 TODO / `support@chroniccare.app` 邮箱 / `chroniccare.app` 域名

---

## §0 评级

**⭐(持平 R68)**,跟 R66 持平,R67 提了一档后 R68/R69 没变

**理由**:R68 修了 5 视角共识 10 P0 中的 3 项(CC-1/3/6)→ 净剩 7 P0 = **仍阻塞上架**。新增 P0 跟 R68 重叠(同源文档/截图/邮箱/域名/律师,5 个外部依赖)。技术层(R67 + R68)全绿,卡在"非代码"环节。

**维度**:
- iOS 平台代码: ⭐⭐⭐⭐ (R66 = ⭐⭐⭐,R67 跨过去)
- 元数据完整: ⭐⭐ (R68 文本 27 个全填,截图仍占位)
- 隐私 / 法律: ⭐ (3 份 md 顶部 TODO 全保留)
- 上架阻塞: ⭐ (9 P0 阻塞,1 项可破 Apple 2.1 + 1 项可破 Apple 1.4.3 + 7 项可破 Apple 2.1 / 4.3)

---

## §1 R68 → R69 增量

### 1.1 R68 修过的(已落地,d691551 commit)

| 项 | 位置 | 难度 | R68 报告 | R69 验证 |
|----|------|------|---------|----------|
| **CC-1** setup ConsentDialog 真接 | `app_database.dart:307-315` + `setup_page.dart` `_finishSetup` | M | ✅ 已修 | ✅ grep `ConsentDialog` 验证,setup 拒绝任一同意 → 终止 |
| **CC-3** IAP 8 元买断代码层 | `feature_flags.dart:38` `_prodIapEnabled=false` | S | ✅ 已修 | ✅ grep `_prodIapEnabled` 验证 false;`store_kit_service.dart:108-110` 早返 false |
| **CC-3** buyLifetime 跟 user_agreement 文本 | — | XS | ⚠ user_agreement.md:25 仍写 8 元 | ⚠ 文本未改,用户协议 §3 跟 release 行为仍不一致 |
| **CC-6** CareEngine safety consent | `fire_care_strategy.dart:155, 202-209` | S | ✅ 已修 | ✅ grep `isSafetyConsentWithdrawn` 验证;`home_page` 注入 legalConsentStoreProvider |
| **CC-2** 212 文件 working tree 未 commit | — | XS | ✅ d691551 commit | ✅ `git status --short` 仅 3 个 R69 audit md untracked |

### 1.2 R68 报告里说"已修"但实际 R68 没动(0 修复)

| 项 | 位置 | R68 报告 | R69 实际 |
|----|------|---------|----------|
| Appfile `app_identifier` 改 `com.chroniccare.app` | `fastlane/Appfile:19` | XS 改 1 行 | ⚠ 仍 `com.chroniccare.chroniccare` |
| Appfile 3 个 TODO(apple_id / team_id / itc_team_id) | `fastlane/Appfile:21,23,25` | XS | ⚠ 仍占位 |
| 33 张 iOS 截图 + 3 张 app_icon 占位 | `fastlane/metadata/ios/*/screenshots/*.png` | L | ⚠ 仍 67 字节 |
| 3 份法律 md 顶部 TODO | `user_agreement.md:3` + `privacy_policy.md:3` + `sensitive_data_consent.md:3` | L 律师 | ⚠ 仍 "未经律师过审" 标注 |
| support@chroniccare.app 占位 | `user_agreement.md:60` + `privacy_policy.md:4` | XS | ⚠ 仍占位 |
| github.com/example 占位 | `user_agreement.md:61` | XS | ⚠ 仍占位 |
| chroniccare.app 域名真实性 | `privacy_url.txt` + `support_url.txt` | M | ⚠ 仍占位 URL |
| ITSAppUsesNonExemptEncryption 自评报告 | `Info.plist:108-109` | S | ⚠ 仍 `false`(无 self-classification 文档) |

### 1.3 R69 新发现(基于 R68 后增量 + 别人视角 + 我的新排查)

| # | 新发现 | 位置 | 视角来源 |
|---|-------|------|----------|
| **NEW-1** | `aps-environment=development` 误导(R68 报告 P1-11 提示) | `ios/Runner/Runner.entitlements:5-6` | 实际读 |
| **NEW-2** | `CFBundleDisplayName` per-locale dict iOS 不支持(R68 报告 P1-12 提示) | `Info.plist:14-22` | 实际读 |
| **NEW-3** | `EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64` 3 处(R68 报告 P1-15 提示) | `pbxproj:358, 487, 538` | grep 验证 |
| **NEW-4** | `NSUserNotificationUsageDescription` 老 key dead code(R68 报告 P1-13 提示) | `Info.plist:45-46` | 实际读 |
| **NEW-5** | `user_agreement.md:25, 28` 仍写 "8 元买断"(CC-3 文本未改,R68 报告 P0-8 没修) | `user_agreement.md:25, 28` | 实际读 |
| **NEW-6** | `user_agreement.md:17, 24` 失联通知当"正常功能"写(R68 报告 P1-16,CC-7 部分) | `user_agreement.md:17` | grep 验证 |
| **NEW-7** | 16KB page size 未验(iOS 不需要但 iOS 17+ 默认) | `pubspec.yaml:33-67` 第三方 plugin | 跨视角 |
| **NEW-8** | 第三方 plugin 自带 PrivacyInfo(R68 报告 P2-22 提示,record 5.2.0 / share_plus 10.1.4 / speech_to_text 7.0.0) | `pubspec.yaml:33-67` | R68 P2 |

---

## §2 App Store 提交必拒项(P0 阻断 — 9 项)

每条标**类别**(架构 / 底层)、**优先级**(P0)、**难度**(XS / S / M / L)、**位置**(`file_path:line_number`)、**Guideline 引用**。

| # | 类别 | 难度 | 位置 | 问题 | Guideline 引用 |
|---|------|------|------|------|---------------|
| **P0-1** | 底层 | XS | `fastlane/Appfile:19` | `app_identifier("com.chroniccare.chroniccare")` vs pbxproj `com.chroniccare.app`(行 379/561/584)**不匹配** → fastlane 上传会因 bundle id 不在 App Store Connect 创建列表里**直接拒** | **2.1 App Completeness (a)**: final version 必填 metadata |
| **P0-2** | 底层 | XS | `fastlane/Appfile:21, 23, 25` | `apple_id` / `team_id` / `itc_team_id` 3 处占位(`your-apple-id@example.com` / `YOUR_TEAM_ID` / `YOUR_ITC_TEAM_ID`)→ fastlane upload → 直接拒 | **2.1 App Completeness (a) + 5.6.2 Developer Identity**: 提供信息必须 truthful + verifiable |
| **P0-3** | 底层 | L | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/{iphone_6_5,iphone_5_5,ipad_12_9}_screenshots/0[1-5]_home.png` 33 张 | 全部 67 字节透明占位 PNG → App Store Connect 强校验真截图(1242×2688 / 1242×2208 / 2048×2732),缺则**直接拒** | **2.3.3 Screenshots**: "should show the app in use" — 67 字节占位显然 not in use |
| **P0-4** | 底层 | XS | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/app_icon.png` 3 张 | 67 字节占位 → 必须替换为 1024×1024 不透明 PNG(Apple 规定**无 alpha channel**);**注意**:R66 报告把 app_icon 误归 "无需替换" 类,实际 App Store Connect 后台强制需要 | **2.3.9 App Icons**: "secured rights to use all materials" + 1024×1024 opaque PNG |
| **P0-5** | 底层 | L | `assets/legal/user_agreement.md:3` + `privacy_policy.md:3-4` + `sensitive_data_consent.md:3-4` | 3 份法律 md 顶部 "**TODO (上 store 前必须由专业律师过审)**" banner 仍保留(5 视角共识 CC-4)→ Apple 1.4.3 Medical + PIPL 双重审查时"未经律师过审" = **自认有合规风险** = 拒 | **1.4.1 Medical apps + 5.1.1 (i) Privacy Policies**: 政策必须"clearly and explicitly" identify data,未审稿不算 |
| **P0-6** | 底层 | L | `assets/legal/user_agreement.md:60` | `support@chroniccare.app` 邮箱占位(`**TODO 占位 — 上 store 前必须注册并替换为真实邮箱**`)→ 邮箱未注册 = 收不到 Apple reviewer 反馈 + 用户无法联系 = 拒 | **1.5 Developer Information**: "Support URL must include an easy way to contact you" |
| **P0-7** | 底层 | M | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/{privacy_url,support_url}.txt` 6 文件 | 写 `https://chroniccare.app/privacy` + `https://chroniccare.app/support` → 域名所有权 / HTTPS 证书 / 真实可访问性未验证 → Apple reviewer 点 URL 验真,404/未注册域名 = 拒 | **1.5 + 5.1.1 (i)**: privacy URL 必须实际可达 |
| **P0-8** | 底层 | S | `assets/legal/user_agreement.md:25, 28` | "本 App 售价人民币 8 元" + "一次性买断" 段仍写,但 release 模式 `StoreKitService.buyLifetime()` 返 false + IAP 入口被 FeatureFlags 隐藏(R68 d691551 修代码,**文本未改**)→ 提交时 Apple 1.2 + 2.1 拒(描述承诺 8 元,App 内无购买入口) | **2.1 App Completeness (a)** + **2.3.2 In-App Purchases**: description 必须 clearly indicate whether featured items require additional purchases — 没购买入口但写 8 元 = 误导 |
| **P0-9** | 底层 | S | `assets/legal/user_agreement.md:17` + `privacy_policy.md:64, 72` | 失联通知业务整体暂停(`FeatureFlags.emergencyContactEnabled=false`)但 3 处文档仍按"正常功能"写"自动通知预设的紧急联系人" + "失联通知 SMS 触发的合法性"(5 视角共识 CC-7)→ Apple 1.4.1 + 2.3 透明度问询 | **2.3 Accurate Metadata (a)**: "Don't include any hidden, dormant, or undocumented features" — 失联通知当前不触发但协议写"正常功能" = dormant + undocumented |

**P0 总计**: 9 项 / 修复总工作量 ~6-10 工程师天 + **法务 review 1-2 周(不可压缩)**

---

## §3 App Store 警告项(P1 警告 — 9 项)

每条标**类别**、**优先级**、**难度**、**位置**、**Guideline 引用**。

| # | 类别 | 难度 | 位置 | 问题 | Guideline 引用 |
|---|------|------|------|------|---------------|
| **P1-1** | 底层 | XS | `ios/Runner/Runner.entitlements:5-6` | `aps-environment=development` 误导 → 项目无 APNs 远程推送(只用 `flutter_local_notifications` 本地通知),**但 entitlement 仍声称走 APNs** → App Store Connect "Push Notifications" 标签必须填,**No** 即跟 entitlement 矛盾,Yes 又得真接 APNs | **4.5.4 Push Notifications**: "must not be required for the app to function" + **2.1 App Completeness (a)**: 声明跟实现必须一致 |
| **P1-2** | 底层 | S | `ios/Runner/Info.plist:14-22` | `CFBundleDisplayName` 写 per-locale **dict**(`en` / `zh-Hans` / `zh-Hant`)→ **Apple iOS Info.plist 是单值,per-locale 必须走 `InfoPlist.strings` (`.lproj/`)** → 当前 dict 形式被 iOS 忽略,所有 locale 都 fallback 到 `CFBundleName=chroniccare` → 中文用户看英文名(病耻感反向) | **2.3.7 App Names**: "must be limited to 30 characters" + 必须 localized correctly |
| **P1-3** | 底层 | XS | `ios/Runner/Info.plist:45-46` | `NSUserNotificationUsageDescription` 老 key(iOS 10+ 弃用),`flutter_local_notifications` 17.x 走 `UNUserNotificationCenter` 不读此 key → dead code + 文案"用于在到点提醒你吃药打卡,所有通知本地处理"误导审核员以为项目走老 API | **2.5.1 Software Requirements**: "use APIs and frameworks for their intended purposes" |
| **P1-4** | 底层 | S | `ios/Runner/Info.plist:108-109` | `ITSAppUsesNonExemptEncryption=false` 与代码层 SQLCipher AES-256 + FlutterSecureStorage Keychain 矛盾 → Apple 抽审时发现实际用了加密却声明"未用"可能追问 → 保守:改 `true` + 准备 self-classification report | **2.5.4 Multitasking apps**: 标准库加密 ≤ 一定长度无需申报,但 SQLCipher AES-256 严格说不属"standard" — 走 self-classification 报告是更稳路径 |
| **P1-5** | 底层 | XS | `ios/Runner.xcodeproj/project.pbxproj:358, 487, 538` | `EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64` 3 处 → Apple Silicon Mac 开发体验断档(iOS 17+ Xcode 15 默认 arm64 simulator)→ 不是 P0 但 Apple Silicon 团队 / CI 必踩坑 | **2.4.2 Software Requirements**: 兼容性最佳实践 |
| **P1-6** | 底层 | S | `lib/domain/logic/phq9.dart` + `lib/domain/logic/gad7.dart` | PHQ-9 / GAD-7 32 题题目 + 严重度 + 危机电话未 i18n 化(hardcode 中文)+ `FeatureFlags.phqGad7I18nEnabled=false`(R65b 默认关闭)→ en-US 用户看到中文量表 = 量表**无效**(医学上不能跨语种用),同时 `PrivacyInfo.xcprivacy` 声明了 HealthAndFitness → **Apple 5.1.1 透明度风险** | **1.4.1 Medical apps**: "Apps must clearly disclose data and methodology to support accuracy claims" — 跨语种量表 = 准确性受损 |
| **P1-7** | 底层 | S | `ios/Runner/Info.plist:144-148` `UIBackgroundModes=["audio"]` | 录音时切后台会继续录(树洞 / 情绪语音)→ Apple 4.0 Background audio 必须有 **visible purpose**,建议在 vent 录音 dialog 顶部加 "录音时切到后台会继续录制" 提示文案(用户认知 + Apple 审核) | **2.5.4 Multitasking apps**: "background services for their intended purposes" + UI must clearly indicate |
| **P1-8** | 底层 | M | `assets/legal/privacy_policy.md:165` | 第 11 章跨境 PII 描述 "审计日志(本地)" 但代码层 `safety_alert_dispatcher.dart` / `audit_log_repository.dart` 0 个 audit 写 → R66 业务暂停期间 OK,但 R67 撤回同意生效后必须真接 audit log(建议 `audit_log_repository.dart` 加 `recordSafetyAlertDispatch(...)` 方法,跟 fire_care_strategy 业务路径对接) | **5.1.1 (i) Privacy Policies**: "data retention/deletion policies" — 必须有审计支撑 |
| **P1-9** | 底层 | S | `assets/legal/privacy_policy.md:192` | 表格"紧急联系人回复 Y 确认" 标 ❌ v0.25 TODO,但 R66 起业务暂停,此行**应改为 ⏸ 暂停(R66 决策)**,而非 ❌ TODO | **2.3 Accurate Metadata**: 内部文档自承认未实现 = 提交时 Apple 看到 = 误导 |

**P1 总计**: 9 项 / 修复总工作量 ~3-5 工程师天

---

## §4 App Store 建议项(P2 建议 — 5 项)

| # | 类别 | 难度 | 位置 | 问题 | 建议 |
|---|------|------|------|------|------|
| **P2-1** | 底层 | XS | `ios/Runner/PrivacyInfo.xcprivacy:94-128` | 缺 `NSPrivacyAccessedAPICategoryProcessInfo`(`flutter_local_notifications` 17.x 内部可能调 `ProcessInfo.processInfo` 取 thermalState / uptime) + `UserDefaults` 只 1 reason `CA92.1` | 加 reason `AC67.1` + 防御性补 `CA92.2`(cross-app 共享)|
| **P2-2** | 底层 | S | `pubspec.yaml:33-67` | 第三方 plugin 自带 PrivacyInfo 核:`record 5.2.0` / `share_plus 10.1.4` / `speech_to_text 7.0.0` 需 `pod install` 后 grep `<App>.app/Frameworks/*.framework/PrivacyInfo.xcprivacy` 确认 2024-05 manifest 完整 | 跑 `pod install` + grep 核 + 缺则补(防御性) |
| **P2-3** | 底层 | S | `ios/Runner/Info.plist:96-97, 114-115` + `Base.lproj/Main.storyboard` | `UISceneStoryboardFile=Main` + `UIMainStoryboardFile=Main` 双 storyboard 语义冗余(Main.storyboard 是空 FlutterViewController 占位) | 删 `Main.storyboard` + 2 keys,仅留 `UILaunchStoryboardName=LaunchScreen` + `SceneDelegate` |
| **P2-4** | 底层 | XS | `pubspec.yaml:4` | 版本号 `0.27.0+64` < 1.0.0 → 提 store 前 bump 到 `1.0.0+1`(表达"正式版",避免 Apple 4.3 Spam 自动标记为 pre-release) | bump `1.0.0+1`(配合 M1 提 store) |
| **P2-5** | 底层 | S | `ios/Runner/Info.plist:144-148` `UIBackgroundModes=["processing"]` | 失联通知业务暂停期 `processing` mode 实际不触发,App Store Connect 后台 App Privacy / App Info 描述里加 "Lost-contact safety net: coming in v1.0, currently disabled" 醒目声明(避免审核员后台模式声明跟实际不符) | 描述里醒目声明(描述里已有 R67 "coming soon" 段,但 description 跟 entitlement 配对还需复核) |

**P2 总计**: 5 项 / 修复总工作量 ~1-2 工程师天

---

## §5 顶层架构审视(用户重点)

### 5.1 Health & Wellness 类别声明 vs Medical device 风险

**结论:✅ 风险可控,已对齐 Apple 1.4.1**。

- 类别:`LSApplicationCategoryType=healthcare-fitness`(`Info.plist:136-137`)+ App Store Connect Primary Category 需勾 **Health & Fitness**(提交时手动选)
- "NOT a medical device" 声明:✅ 完整
  - `fastlane/metadata/ios/en-US/description.txt:38`: "ChronicCare is NOT a medical device and does not provide medical advice, diagnosis, or treatment"
  - `fastlane/metadata/ios/zh-Hans/description.txt:35`: "本 App 不提供医疗建议、诊断或治疗"
  - `assets/legal/user_agreement.md:23`: "本 App 不提供医疗建议、诊断或治疗"
  - `assets/legal/privacy_policy.md` 全文 disclaimer
- 危机热线声明:✅ 完整
  - en-US: 988 + 116 123 + findahelpline.com
  - zh-Hans: 北京 010-82951332 / 全国 400-161-9995 / 上海 021-12320-5
  - zh-Hant: 台灣 1925 / 香港 2389 2222
- 精神心理敏感数据:✅ 走 4 类 CollectedDataType 声明(HealthAndFitness / AudioData / ContactInfo / UserContent),Linked=false,Tracking=false,Purpose=AppFunctionality
- **风险点(CC-7)**:失联通知业务暂停但隐私政策 §4 仍写 "失联通知触发时,我们会将下列信息发送给用户预设的紧急联系人" + 用户协议 §1 仍写 "失联通知(连续多日未打卡时,自动通知预设的紧急联系人)" = **描述承诺但实际不触发** = 触发 Apple 1.4.1 + 2.3 透明度问询(**已 P0-9**)

**结论**:M1 提 store 前必须 P0-9 修(改协议 §1 措辞成 "**即将上线 — 当前已暂停**" + 隐私政策同步)。

### 5.2 文档脱节(4 处 wording 修,CC-7 部分)

| 位置 | 现状 | 应改 |
|------|------|------|
| `user_agreement.md:17` | "失联通知(连续多日未打卡时,**自动通知预设的紧急联系人**)" | "失联通知(连续多日未打卡时自动通知预设的紧急联系人 — 即将上线,当前已暂停)" |
| `user_agreement.md:25, 28` | "本 App 售价人民币 8 元" + "一次性买断" | 删整个 §3 付费规则段(R68 修了 IAP 关闭,描述与代码一致应:App 完全免费) |
| `user_agreement.md:60-61` | support@ + github.com/example 占位 | 删占位标注 + 真实邮箱 + 真实项目仓库(或删 GitHub 行) |
| `privacy_policy.md:64, 72, 87, 192` | 失联通知当"正常功能"描述 + ❌ TODO 标 | 4 处加 "v0.27 起业务暂停,预计 v1.0 启用" + 改 ⏸ 暂停 |

**难度**:S(纯文案,无代码)
**位置**:`assets/legal/user_agreement.md` + `assets/legal/privacy_policy.md` + `fastlane/metadata/ios/*/description.txt`(部分英文版已改,中文版待同步)

### 5.3 法律 md i18n(CC-8,3 视角共识)

| 文件 | zh | en | zh-Hant | 状态 |
|------|----|----|---------|------|
| `user_agreement.md` | ✅ 3785 字节 | ❌ 0 | ❌ 0 | P0 阻塞 |
| `privacy_policy.md` | ✅ 13160 字节 | ❌ 0 | ❌ 0 | P0 阻塞 |
| `sensitive_data_consent.md` | ✅ 4024 字节 | ❌ 0 | ❌ 0 | P0 阻塞 |

**修法**:
1. **方案 A(快速,M 难度)**:3 份 md 翻译成 en / zh-Hant → `assets/legal/{en,zh-Hant}/...md`,运行时按 `Localizations.localeOf(context).languageCode` 选文件
2. **方案 B(长期,L 难度)**:走 `setup_legal_dialog.dart` 已有的 `showLegalDocument(BuildContext, DocumentKind)` 集中器,加 locale 分发(目前 `setup_legal_dialog.dart:38` 不分 locale)
3. **方案 C(临时, XS)**:M1 提 store 前用 Apple Localization 退路——`fastlane/metadata/ios/en-US/description.txt` 给英文 fallback,zh-Hant 走 `zh-Hans` 文案,实际产品只 en/zh-Hans 双语 — 但敏感数据 consent 3 份 md 不分 locale = en-US 用户看到中文,触发 Apple 1.4.3

**建议**:M1 用 **方案 A**(en 版快翻 + zh-Hant OpenCC 转),L 难度降到 M 难度。

---

## §6 底层逐行排查(用户重点)

按主题分类,R69 重点 = R68 P0/P1 跟 R69 新增 P0/P1 的逐项验证。

### 6.1 Info.plist(必填 key 完整度)

| 状态 | Key | 位置 | 备注 |
|------|-----|------|------|
| ✅ R66 加 | `NSMicrophoneUsageDescription` | `:47-48` | "用于情绪日记的语音录入,本地处理,文件加密存储" |
| ✅ R62 加 | `NSSpeechRecognitionUsageDescription` | `:49-50` | "用于情绪日记的语音转文字,本地处理,不上传" |
| ✅ R62 加 | `NSPhotoLibraryAddUsageDescription` | `:56-57` | "用于保存用药报告 PDF 到相册" |
| ✅ R67 Sprint 1 加 | `NSPhotoLibraryUsageDescription` | `:66-67` | "用于分享用药报告 PDF 时选择保存位置" |
| ✅ R61 加 | `NSUserTrackingUsageDescription` | `:72-73` | "本应用不收集任何追踪数据,仅用于 App Store 透明性声明" |
| ✅ R66 加 | `LSApplicationCategoryType=healthcare-fitness` | `:136-137` | 健康/健身类别,符合项目定位 |
| ✅ R62 加 | `ITSAppUsesNonExemptEncryption=false` | `:108-109` | ⚠ P1-4 跟 SQLCipher 矛盾 |
| ✅ R62 加 | `UIBackgroundModes=[audio, processing]` | `:144-148` | ⚠ P1-7 / P2-5 |
| ✅ R62 加 | `BGTaskSchedulerPermittedIdentifiers=com.chroniccare.safety-check` | `:153-156` | 跟 AppDelegate.swift:26-31 一致 |
| ✅ R61 加 | `UIApplicationSceneManifest` | `:81-101` | SceneDelegate 接管 |
| ⚠️ P1-3 | `NSUserNotificationUsageDescription` 老 key | `:45-46` | iOS 10+ 弃用,dead code 误导审核 |
| ⚠️ P1-2 | `CFBundleDisplayName` per-locale **dict** | `:14-22` | iOS 单值,需走 `InfoPlist.strings` |
| ⚠️ P2-3 | `UISceneStoryboardFile=Main` + `UIMainStoryboardFile=Main` 双 storyboard | `:96-97, 114-115` | 语义冗余 |
| ℹ️ 缺则 OK | `NSCameraUsageDescription` | — | 无 image_picker / camera 依赖 |
| ℹ️ 缺则 OK | `NSContactsUsageDescription` | — | 无 Contacts framework 依赖(自建 contacts 表) |
| ℹ️ 缺则 OK | `NSHealthShareUsageDescription` | — | 无 HealthKit(全本地存储,零 HealthKit 集成) |
| ℹ️ 缺则 OK | `NSHealthUpdateUsageDescription` | — | 无 HealthKit |

**结论**:必填 key 100% 完整,P1 修 3 项即清。

### 6.2 PrivacyInfo.xcprivacy(2024-05 强制)

| 状态 | 项 | 位置 | 备注 |
|------|-----|------|------|
| ✅ R61 加 | `NSPrivacyTracking=false` + `NSPrivacyTrackingDomains=[]` | `:22-25` | 零追踪,零广告 SDK |
| ✅ R67 Sprint 1 加 | `NSPrivacyCollectedDataTypes` **4 类** | `:42-92` | HealthAndFitness / AudioData / ContactInfo / UserContent,Linked=false,Tracking=false,Purpose=AppFunctionality |
| ✅ R61 加 | `NSPrivacyAccessedAPITypes` 4 类 | `:94-128` | UserDefaults CA92.1 / FileTimestamp C617.1 / SystemBootTime 35F9.1 / DiskSpace 85F4.1 |
| ⚠️ P2-1 | `NSPrivacyAccessedAPICategoryProcessInfo` 缺 | — | `flutter_local_notifications` 17.x 内部可能调 `ProcessInfo.processInfo` 取 thermalState / uptime,需 reason `AC67.1` |
| ⚠️ P2-1 | `UserDefaults` 只 1 reason `CA92.1` | `:99-101` | 防御性补 `CA92.2`(cross-app 共享)|
| ⚠️ P2-2 | 第三方 plugin 自带 PrivacyInfo 核 | `pubspec.yaml:33-67` | `record 5.2.0` / `share_plus 10.1.4` / `speech_to_text 7.0.0` 需 `pod install` 后 grep `<App>.app/Frameworks/*.framework/PrivacyInfo.xcprivacy` 确认 2024-05 manifest 完整 |

**结论**:核心 4 类 Collected + 4 类 Accessed 全填,P2 修 2 项即清。

### 6.3 AppDelegate.swift(通知 delegate / BGTaskScheduler / 后台模式)

| 状态 | 处理 | 位置 | 备注 |
|------|------|------|------|
| ✅ R67 Sprint 1 加 | `UNUserNotificationCenter.current().delegate = self` | `:15-17` | iOS 14+ foreground 通知可见 |
| ✅ R67 Sprint 1 加 | `BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.chroniccare.safety-check")` | `:26-31` | handler `handleSafetyCheckTask` 占位 |
| ✅ | `GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)` | `:36-38` | `FlutterImplicitEngineDelegate` 模式(R66 切到 SceneDelegate 后) |
| ⚠️ | `handleSafetyCheckTask` 入口直接 `setTaskCompleted(success: true)` | `:49-51` | 业务暂停期 OK,v1.0+ 真接阿里云 SMS 后改(MethodChannel 调 Flutter `checkLostContact(now)`)|

**结论**:R67 修的 2 项 iOS P0 全部落地,P1/P2 0 项需修。

### 6.4 SceneDelegate.swift

| 状态 | 项 | 位置 | 备注 |
|------|-----|------|------|
| ✅ | `class SceneDelegate: FlutterSceneDelegate` 4 行空类 | `ios/Runner/SceneDelegate.swift:1-5` | 继承 `FlutterSceneDelegate`,OK |

### 6.5 Runner.entitlements

| 状态 | 项 | 位置 | 备注 |
|------|-----|------|------|
| ⚠️ P1-1 | `aps-environment=development` 误导 | `ios/Runner/Runner.entitlements:5-6` | 项目无 APNs 远程推送(只用 `flutter_local_notifications` 本地通知),删此 key 即可 |

### 6.6 pbxproj + Fastfile + Appfile + 截图

| 状态 | 项 | 位置 | 备注 |
|------|-----|------|------|
| ✅ | `PRODUCT_BUNDLE_IDENTIFIER = com.chroniccare.app` × 3 处 | `pbxproj:379, 561, 584` | 跟 Android `build.gradle.kts` `applicationId=com.chroniccare.app` 一致 |
| ✅ | RunnerTests 走 `com.chroniccare.chroniccare.RunnerTests` | `pbxproj:395, 412, 427` | 测试 target 命名空间,OK |
| ⚠️ P1-5 | `EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64` × 3 处 | `pbxproj:358, 487, 538` | Apple Silicon Mac 开发体验断档 |
| ✅ R67 Sprint 1 建 | `fastlane/Fastfile` iOS lane 完整 | `Fastfile:1-75` | `beta` / `release` / `metadata` 3 lane |
| ⚠️ P0-1 | `app_identifier("com.chroniccare.chroniccare")` vs pbxproj `com.chroniccare.app` 不匹配 | `Appfile:19` | 改 1 行 |
| ⚠️ P0-2 | `apple_id` / `team_id` / `itc_team_id` 3 处占位 | `Appfile:21, 23, 25` | 替换为真实值 |
| ⚠️ P0-3 | 33 张 iOS 截图 67 字节占位 | `fastlane/metadata/ios/*/screenshots/*.png` | 替换真截图 |
| ⚠️ P0-4 | 3 张 app_icon 67 字节占位 | `fastlane/metadata/ios/*/app_icon.png` | 替换 1024×1024 不透明 PNG |
| ⚠️ P0-7 | `privacy_url` / `support_url` 6 文件写 `https://chroniccare.app/{privacy,support}` | `fastlane/metadata/ios/*/{privacy_url,support_url}.txt` | 域名注册 + HTTPS 部署 + 真可访问 |

### 6.7 元数据(27 个文本字段)

| 项 | 现状 | 评估 |
|----|------|------|
| `description.txt` (en-US, 52 行, 2958 字节) | 完整含 "ChronicCare is NOT a medical device" + 危机热线 (988 / 116 123) | ✅ Apple 1.4.3 合规 |
| `description.txt` (zh-Hans, 42 行, 2512 字节) | 完整含 "本 App 不提供医疗建议" + 危机热线 (北京 010-82951332 / 全国 400-161-9995 / 上海 021-12320-5) | ✅ |
| `description.txt` (zh-Hant, 42 行, 2449 字节) | 完整含 危机热线 (台灣 1925 / 香港 2389 2222) | ✅ |
| `keywords.txt` (3 locale, 49-55 字符) | en-US "medication,reminder,mood,mental,health,chronic,tracker" / zh-Hans "慢病管家,吃药,打卡,提醒,情绪" / zh-Hant 同 | ✅ Apple 100 字符限内 |
| `subtitle.txt` (3 locale) | en-US "Medication + Mood Tracker" / zh-Hans "吃药打卡 + 失联通知" / zh-Hant 同步 | ⚠️ **P0-9 部分**:zh-Hans/zh-Hant subtitle 写 "失联通知",但业务暂停期该功能不触发,建议改 "吃药打卡 + 情绪记录" |
| `name.txt` (3 locale) | "ChronicCare" / "慢病管家" / "慢病管家" | ✅ Apple 30 字符限内 |
| `promotional_text.txt` (3 locale, 129-137 字符) | 含 "Private, encrypted" / "100% on-device, zero cloud" | ✅ Apple 170 字符限内 |
| `copyright.txt` (3 locale) | "© 2026 chroniccare" / "© 2026 慢病管家" / "© 2026 慢病管家" | ✅ |
| `app_icon.png` (3 locale) | 67 字节占位 | 🚨 P0-4 |
| `README_PLACEHOLDER.txt` (仅 en-US) | 786 字节说明占位原因 + 替换指南 | ✅ 上 store 前删 |

### 6.8 法律 md(3 份敏感)

| 项 | zh | en | zh-Hant |
|----|----|----|---------|
| `user_agreement.md` (3785 字节) | ✅ v0.24 草稿 | ❌ 0 | ❌ 0 |
| `privacy_policy.md` (13160 字节) | ✅ v0.22 草稿 | ❌ 0 | ❌ 0 |
| `sensitive_data_consent.md` (4024 字节) | ✅ v0.24 草稿 | ❌ 0 | ❌ 0 |

| 问题 | 位置 | 状态 |
|------|------|------|
| 顶部 "**TODO (上 store 前必须由专业律师过审)**" banner 3 份全保留 | `user_agreement.md:3` + `privacy_policy.md:3-4` + `sensitive_data_consent.md:3-4` | 🚨 P0-5 |
| `support@chroniccare.app` 占位 2 处 | `user_agreement.md:60` + `privacy_policy.md:4` | 🚨 P0-6 |
| `github.com/example/...` 占位 1 处 | `user_agreement.md:61` | ⚠️ P0-6 修法之一:删 |
| "本 App 售价人民币 8 元" 段 | `user_agreement.md:25, 28` | 🚨 P0-8 |
| 失联通知当"正常功能"写 4 处 | `user_agreement.md:17, 24, 48` + `sensitive_data_consent.md:60, 66-67, 85` + `privacy_policy.md:32, 34, 41, 64, 72, 85, 87, 148, 151, 161, 164, 170, 191, 198, 204` | 🚨 P0-9 + 5.1 风险 |
| "紧急联系人回复 Y 确认" 标 ❌ TODO 应改 ⏸ 暂停 | `privacy_policy.md:192` | ⚠️ P1-9 |
| 跨境 PII "审计日志"承诺但代码 0 实现 | `privacy_policy.md:165` | ⚠️ P1-8 |

### 6.9 IAP 与声明一致性

| 状态 | 项 | 位置 | 备注 |
|------|-----|------|------|
| ✅ R65 加 | `in_app_purchase: ^3.3.0` | `pubspec.yaml:62` | R65 加依赖,代码可调但 v0.27 业务暂停 |
| ✅ R68 d691551 修 | `FeatureFlags._prodIapEnabled=false` | `feature_flags.dart:38` | 默认 false,release 模式用户看不到"立即买断"按钮 |
| ✅ R67 修 | `StoreKitService.buyLifetime()` 入口早返 | `store_kit_service.dart:108-110` | `if (!FeatureFlags.iapEnabled) return false;` |
| ✅ R68 注释 | `store_kit_service.dart:117-119` 占位返 false | 同上 | "当前 pubspec 加了 in_app_purchase, 但 v0.28 才真接 productId" |
| ⚠️ P0-8 | `user_agreement.md:25, 28` 仍写 "8 元买断" 段 | — | 文本未改,CC-3 半成品 |
| ✅ | `fastlane/metadata/ios/*/description.txt` 全文 0 处提"售价 8 元" | — | description 跟 release 行为一致(IAP 隐藏 → 描述不提价) |
| ⚠️ | App Store Connect "Price tier" 仍需手动选(Free + 0 IAP) | — | 提 store 时手动操作 |

**结论**:IAP 代码层 R68 d691551 修齐,文本层 P0-8 删 1 段即清。

### 6.10 通知权限 + 录音 + 后台

| 状态 | 项 | 位置 | 备注 |
|------|-----|------|------|
| ✅ R65 配 | `DarwinInitializationSettings(requestAlertPermission: true, requestBadgePermission: true, requestSoundPermission: true)` | `notification_service.dart:128-132` | iOS 走 `UNUserNotificationCenter` 弹权限弹窗 |
| ✅ | `IOSFlutterLocalNotificationsPlugin().requestPermissions(alert: true, badge: true, sound: true)` | `notification_service.dart:167-170` | — |
| ⚠️ P1-3 | `NSUserNotificationUsageDescription` 老 key + 文案"用于在到点提醒你吃药打卡,所有通知本地处理,不上传任何数据" | `Info.plist:45-46` | iOS 10+ 弃用,dead code 误导审核,**删** |
| ⚠️ P1-7 | `UIBackgroundModes=["audio"]` 录音时切后台会继续 | `Info.plist:144-148` | vent 录音 dialog 顶部加 "录音时切到后台会继续录制" 提示文案(Apple 4.0 Background audio visible purpose)|

### 6.11 紧急联系人 / 失联通知 / 录音(敏感数据)

| 状态 | 项 | 位置 | 备注 |
|------|-----|------|------|
| ✅ R66 业务暂停 | `FeatureFlags._prodEmergencyContactEnabled=false` | `feature_flags.dart:35` | 双层防御 |
| ✅ R68 d691551 修 | `FireCareStrategyInput.isSafetyConsentWithdrawn` 字段 + use case 早返 | `fire_care_strategy.dart:155, 202-209` | 业务层真接撤回同意 |
| ✅ R68 d691551 修 | `home_page._fireCareEngine` 注入 `legalConsentStoreProvider(ConsentKind.safety)` | `home_page.dart` | UI 层读同意状态 |
| ✅ R67 修 | `VentRepository.add` 拒写 | — | 树洞撤回同意生效 |
| ✅ | `NSPrivacyCollectedDataTypeContactInfo` | `PrivacyInfo.xcprivacy:68-79` | Linked=false / Tracking=false / Purpose=AppFunctionality |
| ✅ | `NSPrivacyCollectedDataTypeAudioData` | `PrivacyInfo.xcprivacy:56-67` | 树洞 / 情绪语音 |
| ⚠️ P1-7 | vent 录音 dialog 顶部缺"切后台继续"提示 | — | Apple 4.0 审核 |
| ⚠️ P0-9 | 3 处文档按"正常功能"写失联通知 | `user_agreement.md:17` + `sensitive_data_consent.md:60-67` + `privacy_policy.md:32, 64, 72` | **5 视角共识 CC-7** |
| ⚠️ P1-8 | `privacy_policy.md:165` 跨境 PII 审计日志承诺但代码 0 | — | R66 业务暂停期 OK,R67 撤回生效后必须真接 |
| ⚠️ P1-9 | `privacy_policy.md:192` "紧急联系人回复 Y 确认" 标 ❌ TODO 应改 ⏸ | — | 改 1 字符 |

---

## §7 修复优先级总表(按 P0/P1/P2 + 难度排序)

### 7.1 P0 提交必拒(9 项,6-10 工程师天 + 法务 1-2 周)

| 序 | 修复 | 难度 | 类别 | 阻塞 |
|----|------|------|------|------|
| 1 | 注册 `support@chroniccare.app` 真实邮箱(2 处:用户协议 + 隐私政策) | XS | 底层 | 域名注册 + 邮箱服务 |
| 2 | 注册 `chroniccare.app` 域名 + 部署 HTTPS 站点(privacy + support 2 页) | M | 底层 | 域名注册 + 部署(国内 ICP 备案 +1 周)|
| 3 | 替换 `fastlane/Appfile` 4 个 TODO(apple_id / team_id / itc_team_id + app_identifier 改 `com.chroniccare.app`) | XS | 底层 | Apple Developer 账号 + App Store Connect 创建 App |
| 4 | 替换 33 张 iOS 截图 + 3 张 app_icon 为真截图/真图标 | L | 底层 | 需 `flutter run -d "iPhone 15 Pro Max"` 截 5 张主页面(主页 / 打卡 / 趋势 / 心理评估 / 树洞 / 设置),3 设备 × 3 locale |
| 5 | 律师过审 3 份法律 md + 移除 TODO banner + 翻译 en/zh-Hant | L+L+L | 底层 | **最大拦路虎 — 中国执业律师 PIPL 专项 1-2 周 + 翻译外包 1 周** |
| 6 | 删 `user_agreement.md:25, 28` "本 App 售价人民币 8 元" 段(CC-3 文本) | XS | 底层 | 跟 R68 IAP 关闭对齐 |
| 7 | 改 `user_agreement.md:17` + `sensitive_data_consent.md:60-67` 失联通知措辞成 "即将上线 — 当前已暂停"(CC-7) | S | 底层 | — |
| 8 | bump `pubspec.yaml` 版本号到 `1.0.0+1`(避 Apple 4.3 Spam) | XS | 底层 | — |
| 9 | 跑 `flutter pub get` + `cd ios && pod install` + `flutter build ios --release` 验真 | S | 底层 | — |

### 7.2 P0 提交后可能被拒(0 项 — 9 项 P0 全在提交前必做)

### 7.3 P1 警告(9 项,3-5 工程师天)

| 序 | 修复 | 难度 | 类别 |
|----|------|------|------|
| 1 | 删 `aps-environment` entitlement(`Runner.entitlements:5-6`) | XS | 底层 |
| 2 | 改 `CFBundleDisplayName` per-locale 走 `InfoPlist.strings`(建 `ios/Runner/{zh-Hans,zh-Hant}.lproj/InfoPlist.strings`)| S | 底层 |
| 3 | 删 `NSUserNotificationUsageDescription` 老 key(`Info.plist:45-46`) | XS | 底层 |
| 4 | 改 `ITSAppUsesNonExemptEncryption=true` + 准备 self-classification report | S | 底层 |
| 5 | 删 `EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64` 3 处(`pbxproj:358, 487, 538`) | XS | 底层 |
| 6 | PHQ-9 / GAD-7 32 题 i18n 化(16 题 × 2 量表 × 3 locale) + ARB key | L | 底层 |
| 7 | vent 录音 dialog 顶部加"切后台继续"提示文案 | S | 底层 |
| 8 | `audit_log_repository.dart` 加 `recordSafetyAlertDispatch(...)` 方法 + fire_care_strategy 业务对接 | M | 底层 |
| 9 | `privacy_policy.md:192` "❌ TODO" 改 "⏸ 暂停" | XS | 底层 |

### 7.4 P2 建议(5 项,1-2 工程师天)

| 序 | 修复 | 难度 | 类别 |
|----|------|------|------|
| 1 | PrivacyInfo 加 `NSPrivacyAccessedAPICategoryProcessInfo` + `UserDefaults` 补 `CA92.2` | XS | 底层 |
| 2 | `pod install` + grep 第三方 plugin 自带 PrivacyInfo 核 | S | 底层 |
| 3 | 删 `Main.storyboard` + 2 双 storyboard keys | S | 底层 |
| 4 | bump `pubspec.yaml` 到 `1.0.0+1` | XS | 底层 |
| 5 | 描述里醒目声明"失联通知 v0.27 暂停,目标 v1.0" | S | 底层 |

### 7.5 总工作量

- **M1 最小可上架**:6-10 工程师天 + **法务 1-2 周** ≈ **2-3 周总**
- **+ P1 9 项**:3-5 工程师天 ≈ **+ 1 周**
- **+ P2 5 项**:1-2 工程师天 ≈ **+ 0.5 周**
- **全清(到 R70 评级 ⭐⭐⭐⭐)**:3-4 周总

---

## §8 3-5 句精炼建议

### M1 最小可上架路径(2-3 周,6-10 工程师天 + 法务 1-2 周)

1. **法务第一** — 联系中国执业律师做 PIPL 专项过审 3 份 md,**最大拦路虎不可压缩**;同步让律师出 self-classification 报告(P1-4 用)
2. **域名 + 邮箱** — 注册 `chroniccare.app`(国内 ICP 备案 +1 周)+ 注册 `support@chroniccare.app` + 部署 `https://chroniccare.app/{privacy,support}` 2 页
3. **Appfile 4 TODO** — 改 `app_identifier` 1 行 + 3 个 ID 替换为真实值(Apple Developer 账号 + App Store Connect 创建 App)
4. **截图 + app_icon** — iOS Simulator 跑 `flutter run -d "iPhone 15 Pro Max"` 截 5 张主页面 × 3 设备 × 3 locale(33 张),`app_icon.png` 用 1024×1024 不透明真图
5. **文本 CC-3 + CC-7** — 删 `user_agreement.md:25,28` 8 元段 + 改 3 处失联通知措辞成 "即将上线 — 当前已暂停"

### M2 完整 CI 化(到 R70 评级 ⭐⭐⭐⭐,再加 1-2 周)

6. **P1 9 项** — 删 aps-environment / 改 CFBundleDisplayName 走 InfoPlist.strings / 删 NSUserNotificationUsageDescription 老 key / EXCLUDED_ARCHS 3 处 / PHQ-9 + GAD-7 32 题 i18n 化(L 难度)/ vent 录音 dialog 提示 / audit log 真接 / 隐私政策 ❌ → ⏸
7. **P2 5 项** — PrivacyInfo 补 2 类 / pod install 核第三方 plugin / 删双 storyboard / bump 到 1.0.0+1 / 描述补强

### M3 v1.0 时间预估(法务 + 真接外部依赖,2-3 个月)

- **M3.1 v0.28** — 真接阿里云 IAP(8 元 NonConsumable `com.chroniccare.app.lifetime`)+ 真接阿里云 SMS(失联通知恢复)
- **M3.2 v0.29** — 真接 SendGrid 邮件(Email 关怀通知)
- **M3.3 v1.0** — 失联通知全功能启用(`FeatureFlags.emergencyContactEnabled=true`)+ 跨境 PII 评估完成(PIPL §38) + 审计日志(本地 + 端到端加密同步)
- **M3.4 v1.x** — 16KB page size 完整验 + 第三方 plugin 全部升 7.x+(`in_app_purchase` 升 7.x + `share_plus` 升 10.x 等)

### 关键提示(给项目所有者)

> **本项目 R68 是技术层的最高水位 — 5 视角共识 10 P0 中修了 3 项,剩 7 项全是"非代码"环节**(域名 / 邮箱 / 律师 / 截图 / 文本 / i18n / 跨 feature 描述)**。卡这些不是技术问题,是商务 / 法务 / 运营问题,1-2 周可破;真接阿里云 SMS / IAP / SendGrid 是 2-3 月外部依赖(法务模板审核 + AccessKey 申请),不可压。**
>
> **建议**:M1 = "Mavis 上完 6-10 工程师天 + 法务 1-2 周" = 2-3 周上 store;不要追求 M3(失联通知全功能)再上 store,先把"已可用功能 + 文档对齐"上架,失联通知在 v1.0 启用。
