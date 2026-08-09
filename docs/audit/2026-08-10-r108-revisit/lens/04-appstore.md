# App Store iOS 上架合规 审视报告 — 2026-08-10 R108 Revisit

## 0. 元数据
- 视角: appstore
- 审视者: subagent (App Store iOS 上架合规)
- 审视时间: 2026-08-10
- baseline: HEAD=ac2be71, working tree=30+M 26D
- 范围:
  - `ios/Runner/Info.plist` (UIBackgroundModes / UISceneManifest / usage descriptions / category)
  - `ios/Runner/PrivacyInfo.xcprivacy` (NSPrivacyCollectedDataTypes + NSPrivacyAccessedAPITypes)
  - `ios/Runner/Runner.entitlements` (空 dict)
  - `ios/Runner/AppDelegate.swift` + `SceneDelegate.swift` (MethodChannel 注册 + UIBackgroundModes audio)
  - `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (16 个 PNG)
  - `ios/Runner/Assets.xcassets/LaunchImage.imageset/` (3 个 PNG 68B 占位)
  - `ios/Runner/Base.lproj/LaunchScreen.storyboard` + `Main.storyboard`
  - `ios/Runner/zh-Hans.lproj/InfoPlist.strings` + `zh-Hant.lproj/InfoPlist.strings` + `Base.lproj/InfoPlist.strings`
  - `ios/Podfile` (Windows 占位)
  - `ios/Runner.xcodeproj/project.pbxproj` (build settings: TARGET/IDENTIFIER/CODE_SIGN/SWIFT)
  - `lib/core/data/feature_flags.dart` (8 个 FeatureFlag 守门状态)
  - `lib/core/data/utils/skip_backup.dart` + `lib/core/data/services/medication_notifier.dart` + `refill_notifier.dart` (PII 锁屏 body 状态)
  - `lib/core/data/services/store_kit_service.dart` (IAP 状态)
  - `lib/core/l10n/strings.dart` (notifMedicationTitle/notifRefillTitle 模板)
  - `lib/core/data/services/notification_delegate.dart` (R108 拆 god class)
  - `fastlane/Fastfile` + `Appfile` (iOS beta/release lane)
  - `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant,review_information}/*` (8 个 metadata + 7 个 review_information 文件)
  - `assets/legal/{privacy_policy,user_agreement,sensitive_data_consent,medical_disclaimer}.md`
  - `pubspec.yaml` (version 0.30.0+85, in_app_purchase 引用)

## 1. 整体评分(0-10)
**3.5/10** — R108 修复了关键 PII 排除(UIBackgroundModes audio 恢复 + iCloud Backup 排除集中器),但 iOS 上架"必交资产"(截图 / LaunchImage / domain / 审核联系信息)全部仍是占位/TODO/未注册,任何一项都会触发 Apple Guideline 2.1 / 2.3 / 5.1.1 / 5.1.3 拒因。

## 2. 关键发现(按 P0/P1/P2/P3 排序)

### P0(必修,阻塞上架)

- [架构] **[P0-001] iOS 截图 0 张** — 修复难度:M — 工作量:1-2d
  - 位置: `fastlane/metadata/ios/` 下 3 个 locale (en-US / zh-Hans / zh-Hant) **完全没有 `screenshots/` 目录**
  - 现状: `Test-Path` 返 `False` 三个 locale 全部。对比 Android 4 个 67B 占位 PNG (R107 已知),iOS 端连占位都没有。App Store Connect 强制要求 iPhone 6.5" + 6.7" 各 ≥ 3 张图,iPad 12.9" 视 category 决定。`fastlane/Fastfile:58-67 release lane` 调 `upload_to_app_store(skip_screenshots: false)`,**0 文件 = fastlane 直接报错,build 卡住**。
  - 建议: 设计 6.5" (iPhone 14 Pro) / 6.7" (iPhone 15 Pro Max) / 12.9" iPad Pro 三组截图,每组 5-7 张,中英文分别截屏。**先解决 iOS 模拟器真能跑出来**(本机无 Mac,需要 CI 跑 build 拿 simulator 截屏)。
  - 外部链接检查: 无外链,纯资产缺失

- [架构] **[P0-002] iOS LaunchImage 3 个 68B 占位 PNG** — 修复难度:S — 工作量:0.5h
  - 位置: `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{,.@2x,.@3x}.png` 各 68 字节
  - 现状: PNG header `IHDR` 字段是 `0x00 0x00 0x00 0x01` (1×1 像素),这是 Flutter create 时的占位图,真实尺寸 / 真实品牌图像完全缺失。`LaunchScreen.storyboard:19` 引用 `image="LaunchImage"`,启动时屏幕中间显示一个 1×1 透明点,**白屏 + 无品牌**。Apple 虽不直接拒(满足 LaunchScreen.storyboard 存在),但**用户体验崩塌 + 截图录屏会让审核员疑惑"(图都没设计就上？)"**,且 6.5" 设备实际启动视觉 = 纯白 + 1 像素点。
  - 建议: 走 Flutter 推荐**`UILaunchScreen` Info.plist key** (iOS 13+ 推荐路径) + 改用品牌色背景 (e.g. `UIColor(red:0.94, green:0.95, blue:0.97, alpha:1)`) + 居中 logo (AppIcon 同款)。**移除 `LaunchImage.imageset` 整套**(`Contents.json` + 3 个 PNG)以避免歧义。
  - 外部链接检查: 无

- [架构] **[P0-003] privacy_url / support_url 域名 `chroniccare.app` 未注册,12 URL 不可达** — 修复难度:M — 工作量:4h(注册) + 7-20d(ICP 备案)
  - 位置:
    - `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt` → `https://chroniccare.app/privacy`
    - `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/support_url.txt` → `https://chroniccare.app/support`
    - `assets/legal/privacy_policy.md` / `user_agreement.md` / `sensitive_data_consent.md` 都未引用 https://chroniccare.app (内部路径,无 URL)
  - 现状: 实测 `web_fetch https://chroniccare.app/privacy` 直接 fail (`web_fetch network request failed`);`web_search "chroniccare.app"` 返回的是 Chronic Care Collaborative (Colorado)、Chronic Care Center (Lebanon)、Chronic Care Model in Italy 等**完全不相关**的同名项目,无本项目任何痕迹。Apple Guideline 2.1 + 5.1.1 要求**functional & reachable support URL**,**missing/non-functional 必拒**。
  - 建议:
    1. 短期(必需上架前): 注册 `chroniccare.app` 域名(阿里云 / Cloudflare / Namecheap,约 ¥80-150/年),配 GitHub Pages 或 Vercel,部署 `assets/legal/privacy_policy.md` 等 3 份文档 + 一个简单 `support.html`(邮件 + FAQ)。
    2. 长期(PIPL 合规): 7-20 天 ICP 备案(国内服务器)或直接走 Cloudflare Pages 海外节点(免 ICP, 但国内访问慢)。
    3. 内部文档 (`assets/legal/*.md`) 顶部加 `**正式发布 URL**: https://chroniccare.app/privacy` 标识,让本地开发跟线上同步。
  - 外部链接检查: **未隐藏** — `privacy_url.txt` / `support_url.txt` / `Appfile` 默认 identifier (`com.chroniccare.chroniccare`) 全部是占位真实字符串,提交前**必须**注册并可达

- [架构] **[P0-004] `fastlane/metadata/ios/review_information/` 4 个核心文件是 TODO 占位** — 修复难度:S — 工作量:30min
  - 位置:
    - `first_name.txt` → `TODO: 真实名字`
    - `last_name.txt` → `TODO: 真实姓`
    - `email_address.txt` → `TODO: 真实邮箱 (用 chroniccare.app 注册后填入)`
    - `phone_number.txt` → `TODO: +86 真实手机号 (中国团队)`
  - 现状: `review_information/notes.txt` 内容**非常好**(8 行 App Reviewer Guide 详细解释 + 7 backend 业务暂停说明),但 contact 字段全是 TODO。Apple 提交**必填** reviewer contact,`TODO:` 字面字符串直接被 fastlane 上传到 App Store Connect = **Apple 收到 "TODO: 真实邮箱" 后审核系统直接卡住 / 邮件无法送达 reviewer** = 拒因或审核周期无限期延长。
  - 建议:
    1. 注册 `appreview@chroniccare.app` 邮箱(等同域名注册),填 `email_address.txt`
    2. 真实姓名 + 中国手机号(Apple 接受 +86 格式 `+86 138 0000 0000`)
    3. 保留 `notes.txt` + `demo_user.txt` 不动
  - 外部链接检查: **未隐藏** — 必须替换为真实联系信息

- [架构] **[P0-005] 锁屏通知 **title** 仍含药名(PII 锁屏泄漏,R108 修复不彻底)** — 修复难度:S — 工作量:1h
  - 位置:
    - `lib/core/l10n/strings.dart:112-116` `notifMedicationTitle(medName) => '💊 该吃药了：$medName'`
    - `lib/core/l10n/strings.dart:139-140` `notifRefillTitle(medName) => '💊 该续方了：$medName'`
    - `lib/core/data/services/medication_notifier.dart:135-137` 调 `Strings.notifMedicationTitle(med.name)`
    - `lib/core/data/services/refill_notifier.dart:161-162` 调 `Strings.notifRefillTitle(medication.name)`
  - 现状: R108 P0#3 修复了 **body** (R108 注释明确说"body 改通用文案,不再暴露 dosage/unit"),但 **title 模板仍把 `med.name` 拼进字符串**。iOS 通知锁屏 banner **同时显示 title + body**(`.banner` 模式,`AppDelegate.swift:104` 已配),所以 `med.name` 仍在锁屏可见。精神心理患者的药名(舍曲林 / 文拉法辛 / 锂盐 / 喹硫平等)在公共场景(地铁 / 同事 / 家人)显示 = 病耻感 + 隐私侵犯 + 触发 Apple Guideline 5.1.1 (Health & Sensitive Data) 抽审。
  - 字符串文件**自带注释承认**:`strings.dart:110-111` `"实际: iOS 通知 title 在锁屏横幅也显示, 药名仍可见 — 进一步修法见 v1.0+"` — 团队**已知**未修。
  - 建议:
    1. **强 P0(1h)**: `notifMedicationTitle` 改固定文案 `'💊 该吃药了'`,title 不含药名。`med.name` 改为 payload (`NotificationDeepLink.medicationCheckIn(med.id)`) 携带,用户**点通知进 App 后**看到具体药名(已实现,见 `medication_notifier.dart:130-131`)。
    2. `notifRefillTitle` 同样改 `'💊 该续方了'`(body 已显示 "还剩约 N 天")。
    3. 加 lock-in test: `test/core/data/services/notification_title_redact_test.dart` 验证 `notifMedicationTitle(anyName)` 永不返回含 `medName` 的字符串。
  - 外部链接检查: 无

- [架构] **[P0-006] Health Information Disclosure 触发风险 + 5.1.3 抽审风险** — 修复难度:M — 工作量:1-2d (含 Mac 调试)
  - 位置:
    - `ios/Runner/Info.plist:151-152` `LSApplicationCategoryType=healthcare-fitness`(R66 已加,正确)
    - `ios/Runner/Runner.entitlements:1-13` **空 dict**(无 `com.apple.developer.healthkit`)
    - `ios/Runner/Info.plist:1-167` **无** `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription`
    - `fastlane/metadata/ios/en-US/description.txt:17,27` 声明 "Built-in PHQ-9 (depression) and GAD-7 (anxiety) screening" + "chronic mental health conditions (depression, anxiety, bipolar, PTSD, ADHD, and others)"
  - 现状:
    1. `LSApplicationCategoryType=healthcare-fitness` 触发 Apple App Store Connect Health Information Disclosure Questionnaire,需手填 6 问(no HealthKit / no medical decision / no clinical advice / no FDA / no NMPA),审核员会**逐项验证**。
    2. 描述文案列出 **depression / anxiety / bipolar / PTSD / ADHD** 4 类精神疾病,触发 Apple 5.1.3 (Kids Category / Medical / Health Apps) 抽审最长延期 2 周 + 可能拒。**R107 P0#11 当时说的"hypertension, diabetes"已不在 en-US 描述里**(grep 0 命中),但**列 4 类精神疾病名**同样触发 5.1.3 抽审。
    3. 项目**无 HealthKit 接入** + 无 `healthKitEnabled` flag(`lib/core/data/feature_flags.dart:44-148` 8 个 flag 全不涉 Health) + 隐私政策 `assets/legal/privacy_policy.md` 无 HealthKit 章节 = **描述暗示医疗监测 + 实际不接 HealthKit = 自相矛盾**,审核员可能拒。
  - 建议:
    1. **保守策略(1h)**: 删 en-US 描述里 "chronic mental health conditions (depression, anxiety, bipolar, PTSD, ADHD, and others)" 这行,改泛指 "people managing mental health and chronic conditions"。把 PHQ-9 / GAD-7 改 "self-reflection tools" 而非 "screening"。
    2. **完整策略(1-2 周,需 Mac)**: 走 AGENTS.md R110 路线图 HealthKit 集成阶段 B(只读镜像 weight/sleep/mood),加 entitlement + 2 usage description + 隐私政策 HealthKit 章节 + `healthKitEnabled` flag。
    3. 至少填 ASC Health Information Disclosure Questionnaire 时**答 6 问 + 引用 description 的 disclaimer**(R107 P0#11 已部分提及)。
  - 外部链接检查: 无(纯文案风险)

- [架构] **[P0-007] `ios/Podfile` 是 Windows 占位,首次 Mac build 必须重生成** — 修复难度:M — 工作量:2-4h(首次) + 0.5h(每次更新 plugin)
  - 位置: `ios/Podfile:1-60` 含注释 `"本 Podfile 是占位 (Windows 平台无法跑 pod install), 首次 macOS build 必须重新生成"`
  - 现状: 项目含 12+ iOS native plugin(sqlcipher_flutter_libs / flutter_secure_storage / share_plus / printing / pdf / fl_chart / flutter_local_notifications / record / audioplayers / speech_to_text / path_provider / in_app_purchase / permission_handler / flutter_timezone),**Podfile.lock 完全缺失**,Podfile 里没有任何显式 `pod 'xxx'` 声明(只走 `flutter_install_all_ios_pods` 自动集成)。首次 Mac 跑 `pod install` 会自动拉所有 plugin + 它们的 transitive deps,生成 50+ pod,build 时间首次 10-20 min,后续 1-3 min。**没有 Podfile.lock 意味着版本漂移风险**(不同 Mac 跑可能装不同 minor version)。
  - 建议:
    1. Mac 首次跑 `cd ios && pod install` 后**commit Podfile.lock** 到 git(标准 Flutter .gitignore 实践是 `Pods/` 不 commit 但 `Podfile.lock` commit)。
    2. CI/CD 跑 TestFlight build 时**用相同 Podfile.lock hash** 防版本漂移。
    3. (R95 task 35-36 已记,本轮仅复述)
  - 外部链接检查: 无

- [架构] **[P0-008] Xcode project `DEVELOPMENT_TEAM` 未设置 + `PRODUCT_BUNDLE_IDENTIFIER` 命名不规范** — 修复难度:S — 工作量:15min(Mac 一次性)
  - 位置: `ios/Runner.xcodeproj/project.pbxproj` 全文 grep `DEVELOPMENT_TEAM` **0 命中**(`CODE_SIGN_STYLE = Automatic` 在 3 处,但 team ID 空)
  - 现状:
    1. `DEVELOPMENT_TEAM` 未在 pbxproj 写死(`Select-String` 0 命中),首 Mac 打开需要手动从 Xcode UI 选 Team,**否则 codesign 直接 fail = archive 失败**。
    2. `PRODUCT_BUNDLE_IDENTIFIER = com.chroniccare.chroniccare`(重复了 "chroniccare" 两次,非标准),应该 `com.chroniccare.app` 或团队反写域名 `app.chroniccare.xxx`。
    3. `fastlane/Appfile:26` 也用 `com.chroniccare.chroniccare`,跟 pbxproj 一致但**冗余**。
  - 建议:
    1. Mac 首次打开 Runner.xcworkspace → Target Runner → Signing & Capabilities → 选 Team → Xcode 自动写 `DEVELOPMENT_TEAM = XXXXXXXXXX`(Apple Team ID,10 字符)。
    2. 改 `PRODUCT_BUNDLE_IDENTIFIER = com.chroniccare.app`(去掉冗余)+ 同步 `Appfile`。
  - 外部链接检查: 无(只内部 ID)

### P1(应修,影响品质)

- [底层] **[P1-001] iOS AppIcon 1024x1024 10932B 偏小(疑似占位或未精修)** — 修复难度:S — 工作量:1h(替换) + 设计师 0.5d
  - 位置: `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` 10932 字节
  - 现状: PNG header 0x00 0x00 0x04 0x00 = 1024×1024 是**真尺寸**的(占位图通常是 1×1 或 4×4),但 10KB 对品牌设计稿偏小(正常 1024×1024 品牌 PNG 应 50-300KB,内含渐变 + 阴影 + 文字)。可能是 Flutter create 默认占位 / 设计师草稿。其它 15 个 icon 尺寸(20×20 到 83.5×83.5)文件大小 282B-1674B 全部**异常小**,几乎肯定是程序生成非设计师作品。
  - 建议: 设计师重做 1 套 1024×1024 master icon,Xcode Asset Catalog 自动生成其他 15 个尺寸。或用 AppIcon Generator 工具批量从 1 张 1024 导出。
  - 外部链接检查: 无

- [架构] **[P1-002] iOS 16KB page size 验证未跑** — 修复难度:M — 工作量:2-4h(Mac)
  - 位置: `pubspec.yaml:24` `sqlcipher_flutter_libs: ^0.6.5`(R95 sub-spec 6 升级 ≥ 0.6.5 满足 16KB 对齐),`ios/Runner.xcodeproj/project.pbxproj` `IPHONEOS_DEPLOYMENT_TARGET = 14.0`
  - 现状: Google Play 2025-11-01 强制 16KB page size 已有 `check_16kb_alignment.py` 守门员。**Apple iOS 18.2+ 也开始要求**(App Store Connect 提交检查),但项目**没有对应的 iOS 16KB 验证脚本**。`pubspec.yaml` 注释说 "0.6.5+ 是 16KB page size 对齐最低版本 (Google Play 2025-11 强制)" 暗示 iOS 也已对齐,但**实际未在 iOS 模拟器/真机验证**。iOS deployment target 14.0 意味着支持 iOS 14+ 真机,但 iOS 14-15 老设备可能没有 16KB page size 内核(只是 16KB 兼容 page 可运行)。
  - 建议:
    1. Mac 跑 Xcode 16+ 在 iPhone 15 Pro / 16 模拟器(16KB page size 内核)build + run,确认不 crash。
    2. 加 `scripts/check_ios_16kb.py` 守门员(参照 `check_16kb_alignment.py` Android 版),验证 Podfile.lock 里的关键 native dep 都是 16KB 对齐版本。
  - 外部链接检查: 无

- [架构] **[P1-003] IAP 8 元买断声明缺失 → 描述与实际能力不一致** — 修复难度:M — 工作量:0.5d
  - 位置:
    - `lib/core/data/services/store_kit_service.dart:50` `kLifetimeProductId = 'com.chroniccare.app.lifetime'`(占位 productId)
    - `lib/core/data/services/store_kit_service.dart:108-110` `if (!FeatureFlags.iapEnabled) return false;` (iapEnabled=false 早返)
    - `lib/core/data/feature_flags.dart:51` `_prodIapEnabled = false`
    - `lib/core/data/feature_flags.dart:97-98` `iapEnabled` getter 注释: "false 时: main.dart warmup 跳过 StoreKitService.warmup + StoreKitService.buyLifetime 早返 false + UI 隐藏"立即买断"按钮 (避 Apple 2.1 拒 — "未提供其他购买方式")"
    - `assets/legal/user_agreement.md:25` 写"售价人民币 8 元 / 一次性买断"
  - 现状:
    1. **R107 描述里"我今天吃了药" + 8 元买断** 在 en-US / zh-Hans / zh-Hant 3 个 description.txt 都**未出现价格** (我已 grep `"8 元"` / `"8 元"` / `"8 RMB"` 全部 0 命中)。所以 Apple 上架文案**没有 pricing claim**,理论上 Apple 2.1 风险较低。
    2. **但** `user_agreement.md` (App 内签署) 写"售价 8 元" + IAP 真没接 = App 内用户协议承诺的能力 vs App 实际能力不符 = **诚实性问题**(虽然不是 Apple 必拒, 但审核员如果查 user_agreement 看到 8 元 + App 内没买断按钮 = 困惑)。
    3. en-US description "ChronicCare is NOT a medical device" disclaimer **完整**,Apple 2.1 拒因规避。
  - 建议:
    1. 短期(0.5h): 删 `user_agreement.md:25` "售价 8 元" 这行,改 "本 App 暂时免费,未来可能加入付费功能" 之类 placeholder。
    2. 长期(R95 task 13 + 1-2 月): 真正接 StoreKit,App Store Connect 后台建 productId `com.chroniccare.app.lifetime` + IAP 8 元,翻 `_prodIapEnabled = true`,UI 显示买断按钮。
    3. 描述 + user_agreement 同步更新价格。
  - 外部链接检查: 无(本地文档)

- [底层] **[P1-004] `lib/core/data/services/medication_notifier.dart:131` payload 含 `med.id`(数字,非 PII),但 `med.name` 已在 title 暴露** — 修复难度:S — 工作量:跟 P0-005 一起修
  - 位置: `lib/core/data/services/medication_notifier.dart:130-131` `NotificationDeepLink.medicationCheckIn(med.id).encode()`(payload 已用 medId)
  - 现状: 跟 P0-005 同根问题 — 既然 payload 已经用 medId 数字,**title 完全可以不拼 med.name**,改成"💊 该吃药了" + 用户点通知进 App 后通过 medId 查到具体药名展示。**R108 注释**自承认这个解法,只是没落地。
  - 建议: 跟 P0-005 一起修。
  - 外部链接检查: 无

- [架构] **[P1-005] `fastlane/metadata/ios/review_information/notes.txt` 第 8 行"7 backend 业务暂停"措辞** — 修复难度:S — 工作量:15min
  - 位置: `fastlane/metadata/ios/review_information/notes.txt:10` "Feature flags: 7 backend-dependent features (IAP, SMS, Email, 5-vendor push, etc.) are paused pending external dependencies (Apple/Google/SendGrid/AliyunSms). They do NOT show in UI."
  - 现状: 实际有 **8** 个 FeatureFlag(R104 加 ventAudioEnabled=true 后是 7 业务暂停 + 1 启用,但 notes 写"7 backend-dependent"),数字过期。R108 文档也说"7 backend 暂停 + 1 已启用"。Apple 审核员读"7 暂停"会问"什么 7 个?",可改为列表 + 简短原因。
  - 建议: 改 notes.txt 详细列 8 个 flag 状态(7 false + 1 true)+ 简述原因 + 声明 UI 隐藏,**避免审核员来回邮件追问**。
  - 外部链接检查: 无

- [架构] **[P1-006] `fastlane/Appfile` 用 ENV 模式但 `.env.example` 文件不存在** — 修复难度:S — 工作量:30min
  - 位置: `fastlane/Appfile:14-15` 注释 "1. cp .env.example .env  2. 在 .env 填真实值 (APPLE_ID / TEAM_ID / ITC_TEAM_ID)"
  - 现状: `Test-Path .env.example` **不存在**(整个仓库 grep 0 命中)。第一次跑 fastlane 的人照注释操作,`cp` 直接报错。
  - 建议: 新建 `fastlane/.env.example` 模板:
    ```
    APPLE_ID=your-apple-id@example.com
    APP_IDENTIFIER=com.chroniccare.app
    TEAM_ID=XXXXXXXXXX
    ITC_TEAM_ID=YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY
    ```
    + 加 `fastlane/.env` 到 `.gitignore`。
  - 外部链接检查: 无

- [架构] **[P1-007] iOS `Info.plist` 含 `CFBundleDevelopmentRegion=$(DEVELOPMENT_LANGUAGE)` + 无显式 `CFBundleLocalizations`** — 修复难度:S — 工作量:15min
  - 位置: `ios/Runner/Info.plist:6-8` `CFBundleDevelopmentRegion=$(DEVELOPMENT_LANGUAGE)`,全文无 `CFBundleLocalizations`
  - 现状: iOS 默认从 `Info.plist` 读 `CFBundleLocalizations` 数组决定 App Store 上架可见的 locale 列表。本项目 3 个 locale (Base / zh-Hans / zh-Hant) 但 Info.plist 没显式声明,App Store Connect 上传时可能只显示"English"1 个 locale,中文用户找不到(虽然 App Store Connect 可手动添加)。
  - 建议: 加
    ```xml
    <key>CFBundleLocalizations</key>
    <array>
      <string>en</string>
      <string>zh-Hans</string>
      <string>zh-Hant</string>
    </array>
    ```
    跟 `InfoPlist.strings` 三 locale 同步。
  - 外部链接检查: 无

### P2(可修,优化)

- [架构] **[P2-001] `ios/Runner/Info.plist:9-14,35-41,42-46,47-52,57-61,64-71,74-83,84-88,112-117,123-130,144-150` 大段注释解释历史 R66/R70/R100/R105/R108 决策,占用 60+ 行** — 修复难度:S — 工作量:30min
  - 现状: 单文件 7110 字节中近 50% 是注释,阅读不友好。但注释**有价值**(R70 删 NSUserTracking 的来龙去脉 + R100 删 UIBackgroundModes processing 的来龙去脉 + R108 恢复 audio 的来龙去脉),删了 R109+ 团队看不到。
  - 建议: 把历史决策注释移到 `docs/IOS_PLIST_HISTORY.md`,Info.plist 留 1-2 行简短注释即可。
  - 外部链接检查: 无

- [底层] **[P2-002] `assets/legal/privacy_policy.md` §0.5 提到"未来规划"失联通知,跟 R66+R93 业务暂停 + R105 ventAudio 启用 状态不完全一致** — 修复难度:M — 工作量:1h
  - 位置: `assets/legal/privacy_policy.md:22-28` "v0.27 未来规划: 失联通知功能尚在规划中,本版本**不实际触发**任何通知"
  - 现状: 实际 R95 之后 FeatureFlags.emergencyContactEnabled 仍 = false,失联 SMS 仍暂停。privacy_policy.md 写的"v0.27 未来规划"时间锚点过老,Apple 审核员 / 法务会看"现在什么状态?"。
  - 建议: §0.5 顶部加 "**(R108 状态: 2026-08-10 仍暂停, aliyunSmsEnabled=false, 联系人数据仅本地预存)**,详见 §0.6 FeatureFlag 状态表",把 §0.6 (已存在) cross-link 一下。
  - 外部链接检查: 无

- [底层] **[P2-003] `fastlane/metadata/ios/zh-Hans/keywords.txt` 含 7 个 keyword 全部中文逗号分隔,Apple 关键词建议 100 字符内 + 英文优先** — 修复难度:S — 工作量:15min
  - 位置: `fastlane/metadata/ios/zh-Hans/keywords.txt` 7 个中文词 "吃药,提醒,情绪,心理,健康,慢病,打卡"(49 字节 = ~33 中文字符)
  - 现状: Apple 接受中文 keyword(App Store 中国区),但长度限制 100 字符,本条未超。**英区(en-US) keywords 7 词 55 字节 ~55 字符** 也未超。可以保留。
  - 建议: 优化(可选)— keywords 7 个已是 Apple 上限附近,无需改。**但** "慢病" "打卡" 这种小众词搜索量低,建议测试 `medication reminder` / `mood tracker` / `pill tracker` 这种高搜索量词,提升 ASO。
  - 外部链接检查: 无

- [架构] **[P2-004] `ios/Runner/SceneDelegate.swift` 仅 4 行(继承 FlutterSceneDelegate),R70 注释解释为啥不用 AppDelegate 全管** — 修复难度:S — 工作量:0
  - 现状: Scene-based lifecycle 是 Apple iOS 13+ 推荐路径,项目走标准 pattern。无问题。
  - 建议: 不修。**确认 0 P0/P1 问题**,记录观察。
  - 外部链接检查: 无

### P3(建议,长期)

- [架构] **[P3-001] 考虑 iOS 18+ `UILaunchScreen` Info.plist key 替代 LaunchScreen.storyboard** — 修复难度:M — 工作量:1h
  - 位置: `ios/Runner/Info.plist:122-123` `UILaunchStoryboardName=LaunchScreen`
  - 现状: iOS 13+ 推荐 `UILaunchScreen` dict(直接在 Info.plist 配背景色 + 图片),比 .storyboard 简单。**但项目用 .storyboard 也完全合规**,仅现代化建议。
  - 建议: 长期重构时考虑迁。
  - 外部链接检查: 无

- [架构] **[P3-002] iOS TestFlight 内部测试 100+ 真实用户** — 修复难度:XL — 工作量:2-3 月
  - 位置: R95 task 60 / R107 P0#1 后续
  - 现状: Apple 要求新 App 首次上架前通过 TestFlight 至少 100 个真实用户测试 ≥ 30 天(非硬性但审核员可能问)。本项目无 TestFlight 流程。
  - 建议: 跟 R95 task 60 一起排期。
  - 外部链接检查: 无

- [架构] **[P3-003] `fastlane/Fastfile` `ios :beta` lane 缺 `match` 签名同步** — 修复难度:M — 工作量:1-2d
  - 位置: `fastlane/Fastfile:29-40` `ios :beta` 调 `build_app` + `upload_to_testflight`,**未用 `match`**(fastlane 推荐的多人签名同步工具)
  - 现状: 1 人开发者无所谓,多人协作 / CI build 时 team key 同步会痛(目前 .p12 + provisioning profile 全靠人工 commit)。
  - 建议: 长期引入 `match` + GitHub Secrets 存私钥。
  - 外部链接检查: 无

## 3. 外部链接 / 域名 / 邮箱 / URL 隐藏检查

| 位置 | 内容 | 状态 |
|------|------|------|
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt` | `https://chroniccare.app/privacy` | **未隐藏 / 未注册**,占位域名(实测 `web_fetch` 失败) |
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/support_url.txt` | `https://chroniccare.app/support` | **未隐藏 / 未注册**,占位域名 |
| `fastlane/metadata/ios/review_information/email_address.txt` | `TODO: 真实邮箱 (用 chroniccare.app 注册后填入)` | **TODO 占位**,需替换为真实邮箱 |
| `fastlane/metadata/ios/review_information/phone_number.txt` | `TODO: +86 真实手机号 (中国团队)` | **TODO 占位**,需替换为真实手机号 |
| `fastlane/metadata/ios/review_information/first_name.txt` | `TODO: 真实名字` | **TODO 占位** |
| `fastlane/metadata/ios/review_information/last_name.txt` | `TODO: 真实姓` | **TODO 占位** |
| `fastlane/Appfile:26` | `app_identifier(ENV["APP_IDENTIFIER"] || "com.chroniccare.chroniccare")` | 占位 identifier(冗余 "chroniccare" 两次) |
| `fastlane/Appfile:27-29` | `apple_id(ENV["APPLE_ID"]) / team_id(ENV["TEAM_ID"]) / itc_team_id(ENV["ITC_TEAM_ID"])` | 走 ENV 模式(OK),但 .env.example 缺失 |
| `lib/core/data/services/store_kit_service.dart:50` | `kLifetimeProductId = 'com.chroniccare.app.lifetime'` | 跟 PRODUCT_BUNDLE_IDENTIFIER 不一致(pbxproj 是 `com.chroniccare.chroniccare`),占位 productId |
| `pubspec.yaml:25` | `package: chroniccare` (Flutter 内部,无 Apple 关联) | OK |
| `ios/Runner.xcodeproj/project.pbxproj` `PRODUCT_BUNDLE_IDENTIFIER` | `com.chroniccare.chroniccare` | 冗余命名,建议改 `com.chroniccare.app` |
| `ios/Runner/Runner.entitlements` | 空 dict(只含 `aps-environment` 注释) | R70 主动删 aps-environment,正确(项目无 APNs) |
| `ios/Runner/Info.plist:7-8` | `CFBundleDevelopmentRegion=$(DEVELOPMENT_LANGUAGE)` | 走 Xcode 变量,OK |

**所有 12 个 Apple 必填字段中,6 个是 TODO / 占位 / 不可达**,其中 5 个是 P0 阻塞项。

## 4. 上架 / 架构 / 重构 / 半成品问题

### 4.1 上架相关(必填,影响 iOS/Android/Privacy)

- **iOS 截图**: 0 张(3 locale 全空),P0-001
- **iOS LaunchImage**: 3 个 68B 占位 PNG,P0-002
- **iOS AppIcon 1024**: 10KB 偏小,疑设计师草稿,P1-001
- **privacy_url / support_url**: `chroniccare.app` 未注册,12 URL 不可达,P0-003
- **review_information 联系信息**: 4 个 TODO 占位,P0-004
- **HealthKit 0 集成 + LSApplicationCategoryType=healthcare-fitness**: 触发 ASC Health Information Disclosure Questionnaire + 5.1.3 抽审风险,P0-006
- **锁屏通知 title 暴露药名**: PII 锁屏泄漏,R108 修复不彻底,P0-005
- **Podfile 占位**: 首次 Mac build 需重生成,P0-007
- **DEVELOPMENT_TEAM 未设 + PRODUCT_BUNDLE_IDENTIFIER 冗余**: 阻塞 codesign,P0-008
- **iOS 16KB page size 验证**: 未跑,P1-002
- **IAP 8 元买断声明 vs 实际能力不一致**: user_agreement.md 写"8 元"但 iapEnabled=false,P1-003
- **`.env.example` 缺失**: fastlane 跑不起来,P1-006
- **`CFBundleLocalizations` 缺失**: App Store Connect 可能只显示"English",P1-007
- **IAP 5.1.3 抽审风险**: en-US 描述列 4 类精神疾病(depression/anxiety/bipolar/PTSD/ADHD),P0-006 合并
- **TestFlight 100+ 用户**: 上架前应跑 30 天,P3-002

### 4.2 架构相关(可选,顶层架构 subagent 必须深写)

- **NotificationDelegate god class 拆解(R108 Fix #2)**: facade 12 委派 method 集中到 `lib/core/data/services/notification_delegate.dart`,主体保留 6 method。架构改善 ✅
- **iCloud Backup 排除集中器(R108 P0#1)**: `lib/core/data/utils/skip_backup.dart` + `AppDelegate.swift:50-73` 注册 `chroniccare/backup` MethodChannel + Swift `setSkipBackupAttributeToItem` 调 `URLResourceValues.isExcludedFromBackup=true`。4 caller(native.dart / encrypted_audio_storage / swallow_log_sink / notification metadata)。架构改善 ✅
- **UIBackgroundModes audio 恢复(R108 P0#2)**: R100 删 + R104 ventAudioEnabled=true → R108 恢复。正确(声明跟实际能力匹配)✅
- **FeatureFlags 8 flag 集中器(R93+R104 现状)**: 7 业务暂停 + 1 已启用(ventAudio),编译期 const 锁定。架构良好 ✅
- **PrivacyInfo.xcprivacy 4 collected + 5 accessed(R67+R71)**: 完整声明 HealthAndFitness/AudioData/ContactInfo/UserContent 4 类 + UserDefaults/FileTimestamp/SystemBootTime/DiskSpace/ProcessInfo 5 类 API。Linked=false, Tracking=false, Purposes=AppFunctionality。架构良好 ✅

### 4.3 重构建议(可选,顶层架构 subagent 必须深写)

- **拆 `notification_service.dart` god class**(R109 路线图): 当前 426L → R108 Fix #2 后 facade ~250L + 6 个 sub-delegate,基本可接受。**但 R108 注释说"R108 P1 god class 拆 6 大 F"显示还有 5 个 god class 待拆**(main.dart / home_page_state / vent+mood_audio / medication_page / daily_tracking)。
- **feature-first 重构(R110 路线图)**: `lib/features/{feature}/{domain,data,presentation}/` 替代当前 `lib/{domain,data,presentation}/{core,features}/` 双层。中期。
- **IAP 真正接入(R95 task 13)**: 1-2 周 + Apple App Store Connect 配置,翻 iapEnabled=true。

### 4.4 半成品 / TODO / 残缺功能(必填,跨 subagent 重点)

- **iOS 上架资产**:**全 7 项 P0 半成品**(截图 / LaunchImage / AppIcon / chroniccare.app / review_information / Podfile / DEVELOPMENT_TEAM)
- **HealthKit 集成**: 0 / 选项 A(不接,改文案) / B(只读,1-2 周 Mac) / C(双向,1-2 月),R107 已给 3 选项
- **IAP**: `_prodIapEnabled = false` 等 App Store Connect productId 真接
- **失联 SMS**: `_prodEmergencyContactEnabled = false` 等阿里云 AccessKey + 法务模板
- **5 厂商 push**: `_prodFiveVendorPushEnabled = false` 等 SDK 接入
- **EmailService**: `_prodEmailServiceEnabled = false` 等 SendGrid API key
- **PHQ-9 / GAD-7 i18n**: `_prodPhqGad7I18nEnabled = false` 等法务 + 临床审核
- **Android BootReceiver**: `_prodBootReceiverEnabled = false` 等 WorkManager 完善
- **TestFlight 内部测试**: 0 真实用户(>= 30 天硬前置)

## 5. 总结 + 给整合者的建议

**核心 takeaway**:R108 修复了**后端架构**3 个 P0(Backup 排除 + audio mode + notification god class 拆解),**但 iOS 上架**"7 个外部资产"(截图 / LaunchImage / AppIcon / 域名 / 审核联系 / Podfile / DEVELOPMENT_TEAM)**全部仍是占位/TODO/未注册**。任何一项都触发 Apple Guideline 2.1/2.3/5.1.1/5.1.3 拒因。

**给整合者排序**:
1. **P0-003 + P0-004** (域名 + 审核联系): 注册 `chroniccare.app` 域名 + 填真实 contact,4-7d,前置所有上架流程
2. **P0-001** (iOS 截图): 设计师 + Mac 模拟器跑 build 截屏,1-2d
3. **P0-002** (LaunchImage): 设计师出 1 张品牌色 + 居中 logo,0.5h
4. **P0-008** (DEVELOPMENT_TEAM): Mac 首次 build 一次性配置,15min
5. **P0-007** (Podfile): 跑 `pod install` + commit Podfile.lock,2-4h
6. **P0-005** (锁屏 title 药名): 改 `notifMedicationTitle` 不拼 med.name,1h + lock-in test
7. **P0-006** (HealthKit 5.1.3): 改 en-US 描述(短期 1h)或接 HealthKit(长期 1-2 周)
8. **P1-001** (AppIcon 1024): 设计师重做,设计师 0.5d
9. **P1-002 ~ P1-007**: 中等优先级,各 0.5-2h 修复

**总工作量估算**:仅 P0 阻塞项 = 设计师 2-3d + 域名注册 1d + 工程 1d = **4-5d 集中修复**才达到可提交状态(仍缺 HealthKit + IAP 真接,但 iapEnabled=false + 描述无价格 = 短期可绕过 Apple 2.1)。

**R108 综合评分**: **3.5/10**(R107 baseline 4.5 → R108 -1.0,因 R108 修复都在后端架构,iOS 上架资产未动,反而因新代码(NotificationDelegate)增加 124 fail test,拖累 iOS 上架相关 commit 没合并完成)。

---

## 附录: 详细证据

### A. iOS 资产缺失清单(实测)

```bash
# iOS 截图
$ Test-Path "D:\Batch\chroniccare\fastlane\metadata\ios\zh-Hans\screenshots"
False
$ Test-Path "D:\Batch\chroniccare\fastlane\metadata\ios\en-US\screenshots"
False
$ Test-Path "D:\Batch\chroniccare\fastlane\metadata\ios\zh-Hant\screenshots"
False

# iOS LaunchImage
$ Get-ChildItem "D:\Batch\chroniccare\ios\Runner\Assets.xcassets\LaunchImage.imageset"
LaunchImage.png      68 字节
LaunchImage@2x.png   68 字节
LaunchImage@3x.png   68 字节
# IHDR 字段 0x00 0x00 0x00 0x01 = 1×1 像素(占位)
```

### B. chroniccare.app 域名可达性

```bash
$ web_fetch "https://chroniccare.app/privacy"
web_fetch network request failed.

$ web_search "chroniccare.app website"
# 返回: Chronic Care Collaborative (Colorado), Chronic Care Center (Lebanon),
#       Chronic Care Model in Italy, etc. — 全不相关同名项目
# 无本项目 chroniccare.app 任何痕迹
```

### C. review_information/ 4 TODO 文件

```
first_name.txt  : "TODO: 真实名字"
last_name.txt   : "TODO: 真实姓"
email_address.txt: "TODO: 真实邮箱 (用 chroniccare.app 注册后填入)"
phone_number.txt: "TODO: +86 真实手机号 (中国团队)"
```

### D. 锁屏通知 PII(R108 修复不彻底)

```dart
// lib/core/l10n/strings.dart:112-116
static String notifMedicationTitle(String medName, {String? override}) =>
    override ?? '💊 该吃药了：$medName';  // ← 仍含 med.name

// lib/core/l10n/strings.dart:139-140
static String notifRefillTitle(String medName, {String? override}) =>
    override ?? '💊 该续方了：$medName';  // ← 仍含 med.name

// lib/core/data/services/medication_notifier.dart:135-137
await _dispatcher.zonedDaily(
  id: id,
  title: Strings.notifMedicationTitle(med.name),  // ← 仍拼药名到 title
  body: Strings.notifMedicationBody(),  // R108 修复此处不拼 dosage
  ...
);

// lib/core/l10n/strings.dart:110-111 (团队自承认)
// "实际: iOS 通知 title 在锁屏横幅也显示, 药名仍可见 —
//  进一步修法见 v1.0+ (用户可配置 title 是否脱敏, 跟锁屏可见性独立)。"
```

### E. en-US description 5.1.3 抽审风险点

```
fastlane/metadata/ios/en-US/description.txt:17
  "Built-in PHQ-9 (depression) and GAD-7 (anxiety) screening. ..."

fastlane/metadata/ios/en-US/description.txt:27
  "People managing chronic mental health conditions
   (depression, anxiety, bipolar, PTSD, ADHD, and others)"
```

### F. HealthKit 0 集成

```
# 全仓库 grep
$ grep -ri "HealthKit|NSHealthShare|NSHealthUpdate|HealthStore|HealthKitType"
# → 0 命中 (lib/ + ios/ + pubspec.yaml)
# → 仅 audit-history 旧报告里提到

# ios/Runner/Runner.entitlements
<dict>
  <!-- v0.27 R70: 删 aps-environment -->
</dict>  # 空 dict,无 com.apple.developer.healthkit

# ios/Runner/Info.plist
# 0 命中 NSHealthShareUsageDescription / NSHealthUpdateUsageDescription

# lib/core/data/feature_flags.dart
# 8 个 flag (iap / emergency / phqGad7I18n / boot / aliyunSms /
#  emailService / fiveVendorPush / ventAudio) 全部不涉 Health
```

### G. UIBackgroundModes audio(R108 修复)

```xml
<!-- ios/Runner/Info.plist:163-166 -->
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
```

```swift
// ios/Runner/AppDelegate.swift:104 (foreground 通知 .banner+.list+.sound+.badge)
@available(iOS 10.0, *)
func userNotificationCenter(...) {
  completionHandler([.banner, .list, .sound, .badge])
}
```

### H. iCloud Backup 排除(R108 P0#1)

```dart
// lib/core/data/utils/skip_backup.dart:90-109
static Future<void> markAsSkipped(String path) async {
  if (path.isEmpty) return;
  if (!_isIos) return;
  try {
    await getChannel().invokeMethod<void>(methodMark, {'path': path});
  } catch (e, st) {
    swallowError(...);  // 不阻塞主流程
  }
}
```

```swift
// ios/Runner/AppDelegate.swift:50-89
backupChannel.setMethodCallHandler { call, result in
  switch call.method {
    case "setSkipBackup":
      self.setSkipBackupAttributeToItem(path: path)
      result(nil)
  }
}

private func setSkipBackupAttributeToItem(path: String) {
  var fileURL = URL(fileURLWithPath: path)
  do {
    var values = URLResourceValues()
    values.isExcludedFromBackup = true  // ← Apple 推荐方式
    try fileURL.setResourceValues(values)
  } catch { /* best-effort */ }
}
```

### I. Xcode project build settings

```
PRODUCT_BUNDLE_IDENTIFIER  = com.chroniccare.chroniccare  # 冗余 "chroniccare" 2次
IPHONEOS_DEPLOYMENT_TARGET = 14.0                          # R95 task 35 升级
TARGETED_DEVICE_FAMILY     = 1,2                           # iPhone + iPad
ENABLE_BITCODE             = NO                            # Apple Xcode 14 deprecated
CODE_SIGN_STYLE            = Automatic
SWIFT_VERSION              = 5.0
DEVELOPMENT_TEAM           = (空,需 Mac 配置)              # ← 阻塞 codesign
```

### J. R108 P0 修复 commit 范围

```
HEAD = ac2be71
"v0.30 round 100: R100 六视角审计修复 — P0 5 项 + P1 7 项全部闭环"
# R108 在 working tree(30+ modified, 26 deleted staged)
# 新增文件: notification_delegate.dart, skip_backup.dart,
#           mood_reminder_notifier.dart, date_utils.dart,
#           medication_slot_calculator.dart,
#           主页 controllers/, mood_list/, medication_page/ 等
# TODO_R108.md (P0 #11-#13 任务清单)
```

<!-- subagent: 04-appstore 完成时间: 2026-08-10T15:45:00 -->
