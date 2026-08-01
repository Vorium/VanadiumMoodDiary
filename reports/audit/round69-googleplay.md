# v0.27 R69 GooglePlay 上架审计

**审计时间**: 2026-08-02 → 2026-08-03
**项目**: chroniccare(精神心理患者吃药打卡 App / 医疗健康类 / 精神心理敏感数据)
**版本**: 0.27.0+64(`pubspec.yaml:4`)/ R68 commit d691551 + 556d454 已落地(working tree 4 文件 = R69 自己写的 4 份视角报告)
**基线**: 1284 tests pass / 0 analyzer error / 16 守护脚本全绿(`check_orphan_arb_keys.py` 0 orphan)
**审计模式**: 增量审计(对照 R68 `round68-googleplay.md` 39KB/472 行 + `round68-CONSOLIDATED.md` §4.1 Android 部分)
**视角**: Google Play Store 上架合规(Health Apps + Data Safety + Permissions Policy + 16KB page size + 64-bit + targetSdk 2026 要求)

---

## §0 评级

**3.5 / 10**(vs R68 3.0/10,**+0.5 回升**)

| 维度 | R66 评分 | R68 评分 | **R69 评分** | Δ vs R68 | 关键变化 |
|------|---------|---------|---------|---------|---------|
| **政策合规 (Policy)** | ⭐⭐ | ⭐⭐½ | ⭐⭐½ | = | CC-1/CC-3/CC-6 三处代码层 P0 修;Play Console 4 大表单 / 3 法律 md 顶部 TODO / 4 处文档脱节 / i18n 仍 0 |
| **技术 (Technical)** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐½ | ↓½ | R68 修 CareEngine safety + IAP 早返 + setup ConsentDialog;R69 仍 0 keystore / 0 16KB 验 / 0 abiFilters / BootReceiver 占位 |
| **元数据 (Store Listing)** | ⭐ | ⭐½ | ⭐½ | = | 8 截图 + 2 feature_graphic + 2 icon + 2 video 0 变化;zh-CN title "失联通知" + en-US "automatically notify" 仍写功能可用 |
| **签名 (Signing)** | ⭐ | ⭐½ | ⭐½ | = | `build.gradle.kts:80` 切 `signingConfig=release` 注释仍在 TODO;`android/key.properties` 不存在;0 真实 keystore |
| **隐私 (Privacy)** | ⭐⭐ | ⭐⭐½ | ⭐⭐½ | = | R68 CC-6 修后 `privacy_policy.md:87` 走通 + ConsentGate R67 业务层真生效;3 文档顶部 TODO + 4 处脱节 + i18n 仍 0 |
| **数据安全 (Data Safety)** | ⭐ | ⭐ | ⭐ | = | Play Console 4 大表单 0 维护(代码外) |

**整体判断 — 3.5/10**。R68 修 3 个代码侧 P0 共识(CC-3 IAP 早返 / CC-6 CareEngine safety 撤回真接 / CC-1 setup ConsentDialog),R68 commit 落地 1.5 工程师天;但上架硬阻塞仍 8 P0 缺 1 不可。**卡在"非代码"环节**:keystore / 域名 / 邮箱 / 律师 review / Play Console 4 大表单。R69 新增"半步"——R68 修后,**失联通知从"代码与文档全撒谎"降级为"代码层已诚实 + 文档层仍撒谎"**,差最后 1 步文档 wording 修(2-3h)。

---

## §1 R68 → R69 增量

### 1.1 R68 已修(11 项,代码侧 hygiene 全绿)

| R68 P0/P1 编号 | 位置 | 修法 | 难度 | 评 |
|----|------|------|------|-----|
| **CC-1** | `setup_page._saveSetup` + `app_database.dart:307-315` | R68 commit d691551: setup 阶段走 ConsentDialog 逐联系人弹窗,不再绕过 | M | ✅ 5/5 |
| **CC-3** | `feature_flags.dart:36` + `store_kit_service.dart:108-110` | R68 commit d691551: `_prodIapEnabled = false` 早返,UI 隐藏"立即买断"入口 | S | ✅ 5/5 |
| **CC-6** | `fire_care_strategy.dart` + `home_page._fireCareEngine` | R68 commit d691551: `FireCareStrategyInput` 加 `isSafetyConsentWithdrawn`,撤回后 `disabled` 早返 | S | ✅ 5/5 |
| **CC-9** | `settings_page.dart:63, 92` | R49 + R66 双轮已修(2 处 dark mode 漏反白) | XS | ✅ 5/5 |
| **CC-10** | `app_theme.dart:128, 209` | R50 已抽 `AppColors.fgDisabled/fgHintInput` 集中器 | XS | ✅ 5/5 |
| R68 P1-2 | `vent_compose_page.dart:135-141` RECORD_AUDIO in-app rationale | R66 守门员已加(grep 没找到 TODO 注释) | S | ✅ 4/5(待 R69 re-verify) |
| R68 P1-4 | `notification_status_card.dart` SCHEDULE_EXACT_ALARM 引导 | R20 + R23 双轮已加(R66 grep 找到 `NotificationStatusCard` 已实装) | XS | ✅ 4/5(待 R69 re-verify) |
| R68 P1-5 | `en-US/short_description.txt:1` "chronic patients" 措辞 | R68 未改(仍 `Daily check-in + mood tracker for chronic patients. Private & local.`) | XS | ❌ 0/5 |
| R68 P1-6 | `video.txt` 2 文件 PLACEHOLDER URL | R68 未改(仍 `https://www.youtube.com/watch?v=PLACEHOLDER_APP_DEMO_VIDEO`) | XS | ❌ 0/5 |
| R68 P1-7 | 16KB page size 验脚本 | R68 未写(`scripts/check_16kb_alignment.{sh,py}` 均 False) | S | ❌ 0/5 |
| R68 P1-8 | abiFilters 显式声明 | R68 未加(grep `abiFilters` in `build.gradle.kts` 0 命中) | XS | ❌ 0/5 |

**R68 净进展**: 4 项 P0 共识修 3(CC-3/CC-6/CC-1),代码侧 hygiene 8 项稳守,上架硬阻塞 0 突破。

### 1.2 R68 未修(11 项,上架阻塞持续)

| R68 编号 | 位置 | R69 状态 |
|----|------|---------|
| P0-1 | `build.gradle.kts:80` 切 `signingConfig=release` + `android/key.properties` 不存在 + `android/app/chroniccare-release.jks` 不存在 | **0 进展**(`android/key.properties` Test-Path=False) |
| P0-2 | `assets/legal/privacy_policy.md` + Play Console 字段 | **0 进展**(`chroniccare.app` 域名未注册 / 隐私 URL 未托管) |
| P0-3 | `user_agreement.md:60` `support@chroniccare.app` + Play Console Developer email | **0 进展**(仍 TODO 占位) |
| P0-4 | `fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/*.png` (8 × 67 字节) | **0 进展** |
| P0-5 | `fastlane/metadata/android/{en-US,zh-CN}/feature_graphic.png` (2 × 67 字节) | **0 进展** |
| P0-6 | `fastlane/metadata/android/{en-US,zh-CN}/icon.png` (2 × 1443 字节, 192×192) | **0 进展** |
| P0-7 | `sms_service.dart:194-198` `throw StateError` + Privacy Policy §3 共享段 | **0 进展**(`AliyunSmsProvider._isFullyImplemented=false` 仍 false,R55+ 真接 TODO) |
| P0-8 | `fastlane/Fastfile` + `fastlane/Appfile` Android 端 0 | **0 进展**(`default_platform(:ios)` + 0 `platform :android do` 块) |
| P0-9 | `assets/legal/{privacy,user_agreement,sensitive_data_consent}.md:3` 顶部 "TODO 律师过审" banner | **0 进展**(3 文件 line 3 全命中) |
| P0-10 | 4 处文档脱节(CC-7) | **2/4 进展**(R67 修 `en-US full_desc` + `zh-CN full_desc` 加 "coming soon" 段;`en-US full_desc.txt:14` + `zh-CN title.txt:1` + `user_agreement.md:17,40` + `sensitive_data_consent.md:27,47,64` 仍 0) |
| P2-4 | `pubspec.yaml:62` `in_app_purchase: ^3.3.0` 已停维护 | **0 进展**(仍 ^3.3.0) |

### 1.3 R69 新增 / 增项(3 项)

| 编号 | 位置 | 问题 |
|------|------|------|
| **R69-N1** | `fastlane/metadata/android/en-US/short_description.txt:1` "chronic patients" 措辞 vs Google Health Apps 政策 | Google Health Apps 政策建议改 "people managing chronic conditions" 避免"病耻感"语气,R66 §6.7 P1 提,R68 未改 |
| **R69-N2** | `assets/legal/privacy_policy.md:175-178` §11 walkthrough vs R68 CC-6 修后 | R68 修 CC-6 后,§11 走通"撤回后业务层停止"段落;但 §3 共享段 `失联通知触发时...` 仍写"用户昵称/距上次打卡/关怀短信模板 → 紧急联系人",**业务层 0 触发**,措辞需改 "如未来启用" 或 "当前不实际触发" |
| **R69-N3** | `assets/legal/privacy_policy.md:191-195` §12 单独同意实现进度 R67 已勾"v0.27 R67" 但 §3 共享段 / `user_agreement.md:17,40` / `sensitive_data_consent.md:27,47,64` 4 处仍写"失联通知"功能可用 | §12 内部一致(标 R67 真接 + 业务层生效),但跨文档 §3 / user_agreement / sensitive_data_consent 三方 4 处 wording 未对齐 CC-6 修后状态 |

---

## §2 Google Play 提交必拒项(P0 阻断,8+2 项)

> 修法按 Google Play Console 实际拒收原因分类 + Policy 引用。

### 2.1 P0 提交时必拒(8 项)

| # | 类别 | 位置 | 问题 | Policy 引用 | 难度 |
|---|------|------|------|------------|------|
| **GP-P0-1** | 底层 | `android/app/build.gradle.kts:80` + `android/key.properties` 不存在 + `android/app/chroniccare-release.jks` 不存在 | release 签名仍是 debug keystore → AAB 100% 拒收 | **Developer Program Policy 签名前提**: release AAB 必须用 production keystore,debug-signed 上 store = 直接拒 | **S** (半天) |
| **GP-P0-2** | 底层 | `assets/legal/privacy_policy.md` + Play Console "Privacy Policy URL" 字段 | Privacy Policy URL 未托管到 HTTPS 公网 → 提交即拒(精神心理类必填) | **Data Safety Policy §1.5 + User Data Policy**: Health apps 必须提供可访问的 Privacy Policy URL | **M** (1-2 天: 注册域名 + 部署 HTML) |
| **GP-P0-3** | 底层 | `assets/legal/user_agreement.md:60` + Play Console "Developer email" 字段 | `support@chroniccare.app` 仍是 TODO 占位,Play Console 必填 Privacy Contact Email | **Developer Program Policy §3**: Developer email 必填且真实可达 | **XS** (1-2h) |
| **GP-P0-4** | 底层 | `fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/screenshot_{1..4}.png` (8 × 67 字节) | 8 张截图全是 1x1 占位 PNG → Play Store 上传即拒 | **Store Listing Policy §1**: Phone screenshots 必填 2-8 张,内容必须真实可读 | **S** (半天) |
| **GP-P0-5** | 底层 | `fastlane/metadata/android/{en-US,zh-CN}/feature_graphic.png` (2 × 67 字节) | 2 张 feature_graphic 全是 1x1 占位 → Play Store 上传即拒 | **Store Listing Policy §1**: Feature graphic 必填 1024×500 | **XS** (1-2h) |
| **GP-P0-6** | 底层 | `fastlane/metadata/android/{en-US,zh-CN}/icon.png` (2 × 1443 字节, 192×192) | App icon 需 512×512,当前 192×192 → Play Store 警告 + 上传失败 | **Store Listing Policy §1.3**: App icon 必填 512×512 | **XS** (1h) |
| **GP-P0-7** | 底层 | `lib/core/data/services/sms_service.dart:194-198` + `AliyunSmsProvider._isFullyImplemented` (line 136) + Privacy Policy §3 共享段 | SMS Provider 仍 `throw StateError('AliyunSmsProvider.send() R55 真接 TODO...')`,Data Safety Form 勾"失联通知触发时...发给紧急联系人"与代码层 0 触发矛盾 | **Data Safety Policy §2.2 + User Data Policy §4.1**: 共享声明必须跟实际代码一致,声称会发数据但代码层 0 调用 = 误导性陈述 → Developer Policy 4.8 拒 | **L** (1-2 月法务 + AccessKey 申请) |
| **GP-P0-8** | 底层 | `fastlane/Fastfile` (`default_platform(:ios)` line 17) + `fastlane/Appfile` (iOS-only) | Android 端 fastlane 0(`platform :android do` 块 0);Play Console 上传 metadata 脚本缺失 | **非直接拒收**,但缺自动化 → 每次手动 Console 填 = P0-9/10 易漏 | **S** (半天: 复制 iOS Fastfile 改 platform) |

### 2.2 P0 审核员抽查必拒(2 项)

| # | 类别 | 位置 | 问题 | Policy 引用 | 难度 |
|---|------|------|------|------------|------|
| **GP-P0-9** | 底层 | `assets/legal/privacy_policy.md:3` + `user_agreement.md:3` + `sensitive_data_consent.md:3` | 3 文档顶部均标 "**TODO (上 store 前必须由专业律师过审)**" + "未经律师过审" → 抽查到 = 误导性陈述 | **Developer Program Policy §4.8 (Impersonation)**: 法律文档含"未过审"标注提交 = 误导性陈述,可拒收 | **L** (律师 1-2 周,~¥15k-30k/文档) |
| **GP-P0-10** | 底层 | `fastlane/metadata/android/en-US/full_description.txt:14` + `zh-CN/title.txt:1` + `user_agreement.md:17,40` + `sensitive_data_consent.md:27,47,64` | 4 处文档写"失联通知"功能可用(CC-7)+ `FeatureFlags.emergencyContactEnabled=false` + `AliyunSmsProvider.send()` throw 业务暂停 — 文档与实际状态不一致 | **Developer Program Policy §4.3 (Deceptive Behavior)**: App 描述跟实际行为不一致,可拒收 | **M** (1-2h: 改 4 处文档 + 加 "本版本已暂停" 段) |

### 2.3 P0 子项 — 缺失/不达标字段(8 子项)

| # | 位置 | 字段 | 修复 |
|---|------|------|------|
| 2-A | Play Console "Privacy Policy URL" | `https://chroniccare.app/privacy` (HTTPS 公网托管) | 注册域名 + 部署 `assets/legal/privacy_policy.md` 转 HTML |
| 2-B | Play Console "Developer email" | `support@chroniccare.app` (真实邮箱) | 注册域名 + 邮箱 + 替换 1 处 TODO |
| 2-C | Play Console Data Safety Form | 4 大类(账号 / 设备 / 应用活动 / 个人信息) + health data 勾 | 手工填 2-3h |
| 2-D | Play Console Health Apps questionnaire | "Mental and behavioral health" 4 问 | 手工填 1h |
| 2-E | Play Console Permissions Declaration Form | `USE_EXACT_ALARM` justification 100+ 字符 | 写 1 段(`定时用药提醒依赖精确闹钟,患者 24h 内不能漏服,允许应用在 Doze 模式下触发精确闹钟` ≥ 100 字) |
| 2-F | Play Console Permissions Declaration Form | `RECORD_AUDIO` in-app rationale | 1 段(树洞语音 + mood audio) |
| 2-G | Play Console "Data deletion endpoint URL" | `https://chroniccare.app/delete-data-instructions` | 部署 1 个静态页 |
| 2-H | Play Console "App content → Data safety" | health data 共享声明需勾"未触发"或真接通 | 跟 P0-7 同步决策 |

---

## §3 Google Play 警告项(P1,9 项)

| # | 类别 | 位置 | 问题 | Policy 引用 | 难度 | R68→R69 |
|---|------|------|------|------------|------|---------|
| **GP-P1-1** | 架构 | `android/app/src/main/kotlin/com/chroniccare/chroniccare/BootReceiver.kt:32-37` | BootReceiver 走 "启动 MainActivity" 占位路径,line 30-31 注释"留给 R64 完善" — **R64+ 4 round 未动** | **非直接拒**,但 BOOT_COMPLETED 后启动 MainActivity = 用户每次重启看到 App 主界面,体验差 | **S** (2-3h) | ❌ 0/5 |
| **GP-P1-2** | 底层 | `lib/presentation/pages/vent/vent_compose_page.dart:135-141` | RECORD_AUDIO in-app rationale R66 提"snackbar 显示'需要麦克风权限'但没引导用户去系统设置" | **Permissions Policy**: Dangerous permissions 必须有 in-app rationale + fallback to system settings | **S** (1-2h) | ⚠ 4/5 待 R69 re-verify |
| **GP-P1-3** | 底层 | `fastlane/metadata/android/zh-CN/title.txt:1` "慢病管家 - 吃药打卡 + 失联通知" | R67 改 `full_description.txt` 但 `title.txt` 漏改 → 用户在 Play Store 看到 title 写"失联通知"功能可用,实际业务暂停 | **Store Listing Policy §1**: title 措辞必须跟功能一致 | **XS** (5min) | ❌ 0/5 |
| **GP-P1-4** | 底层 | `fastlane/metadata/android/en-US/full_description.txt:14` "can automatically notify your trusted contacts" | R67 加 "coming soon" 段(line 13),但 line 14 "automatically notify" 措辞保留 → 跟"currently disabled"段矛盾 | **Developer Program Policy §4.3 (Deceptive)**: 描述含功能可用 wording,审核员读 line 14 即认定误导 | **XS** (5min 改 1 词为 "would") | ❌ 0/5 |
| **GP-P1-5** | 底层 | `fastlane/metadata/android/en-US/short_description.txt:1` "Daily check-in + mood tracker for chronic patients. Private & local." | "chronic patients" 措辞病耻感,Google Health Apps 政策建议改 "people managing chronic conditions" | **Health Apps Policy (非强制)**: 措辞建议 | **XS** (5min) | ❌ 0/5 |
| **GP-P1-6** | 底层 | `fastlane/metadata/android/{en-US,zh-CN}/video.txt` 2 文件 | 仍是 `https://www.youtube.com/watch?v=PLACEHOLDER_APP_DEMO_VIDEO` 占位 URL → Play Console 报"无效视频链接" | **Store Listing Policy §1.7**: Promo video 必填真 URL 或留空 | **XS** (5min 删 2 文件) | ❌ 0/5 |
| **GP-P1-7** | 架构 | `android/app/build.gradle.kts:11` `ndkVersion = flutter.ndkVersion` + 0 验脚本 | 16KB page size Google Play **2025-11-01 起强制**(targetSdk 35+ 必备) — Flutter 3.41.9 默认 ndkVersion 27.0.12077973 已 16KB 对齐,但 `sqlcipher_flutter_libs 0.6.4` + `record 5.2.0` + `audioplayers 6.1.0` 未验 | **Google Play 2025-11 新规**: targetSdk 35+ 必须 16KB page size,未验可拒收 | **S** (2-3h: 写 `scripts/check_16kb_alignment.sh` 守门员 + `flutter build apk` 实测 16KB device) | ❌ 0/5 |
| **GP-P1-8** | 底层 | `android/app/build.gradle.kts` (无 abiFilters / splits) | 64-bit ABI 未显式声明,Flutter 默认含 arm64-v8a + x86_64,旧 armeabi-v7a 仍含 — Google Play 2019-08 起强制 64-bit | **Google Play 2019-08 新规**: APK / AAB 必须支持 64-bit | **XS** (15min 加 `ndk { abiFilters.addAll(listOf("arm64-v8a", "x86_64")) }`) | ❌ 0/5 |
| **GP-P1-9** | 架构 | `lib/main.dart:188-191` + `lib/core/data/services/store_kit_service.dart:108-110` | IAP 8 元买断 R68 CC-3 修后 `_prodIapEnabled=false` 早返;但 `assets/legal/user_agreement.md:25` 仍写"本 App 售价人民币 8 元...一次性买断" + Play Store 上未配 productId → 文档与代码仍不一致 | **Developer Program Policy §4.3**: 描述与实际行为一致 | **M** (半天: 改 1 行 user_agreement.md + 加 1 段 "本版本 IAP 暂停, 详情见 v0.28" + 决策 IAP 是否 v1.0 真接) | ⚠ 3/5(代码修了,文档 + Console 还没) |

---

## §4 Google Play 建议项(P2,6 项)

| # | 类别 | 位置 | 问题 | 难度 |
|---|------|------|------|------|
| **GP-P2-1** | 架构 | `.gitignore:46-49` (root) | R66 §7.5 P2 建议加 `*.jks` / `*.keystore` / `key.properties` — **R67 已加 ✓** | — |
| **GP-P2-2** | 底层 | `docs/DEPLOYMENT.md:120-138` 阶段 5 | Google Play 阶段 5 描述 outdated,R66 §10.2 W14 标"重写" — R67 未改 | **M** (半天) |
| **GP-P2-3** | 架构 | `lib/main.dart:1-237` (Background isolation 注释) | Flutter 默认 OK,加 1 段注释说明 `flutter_local_notifications` 的 background 行为(Android 13+ POST_NOTIFICATIONS) | **XS** (10min) |
| **GP-P2-4** | 底层 | `pubspec.yaml:62` `in_app_purchase: ^3.3.0` | pub.dev 3.3.0 已停维护(2023-04 last update),新版 7.x 已 GA(支持 Billing Library 7 + Pending Purchase) — 升 ^7.x 跟 P0-7 真接 IAP 同步 | **S** (半天) |
| **GP-P2-5** | 架构 | `assets/legal/{privacy,user_agreement,sensitive_data_consent}.md` 0 英文 + 0 繁体版 (CC-8) | en / zh_Hant 用户切 locale 仍看中文(英国 / 港澳 / 台湾用户) — i18n 法律文档是大头(3 份 md 全文翻译 + setup_legal_dialog 切 locale) | **L** (1 周: 3 份 md 翻译 + i18n hook) |
| **GP-P2-6** | 底层 | `pubspec.yaml:2` description 单语种中文 "我今天吃了药 - 精神心理患者吃药打卡 + 停药通知" | App Store / Google Play en 模式 UX 割裂(CC-5) | **M** (1-2h 加 en / zh_Hant description) |

---

## §5 顶层架构审视(用户重点)

### 5.1 Health Apps 类别声明(Play Console App content)

**精神心理类必填项**(Google Health Apps Policy 2026):

| # | 必填 | 当前 | 修复 |
|---|------|------|------|
| 1 | "Health features" 勾选"Mental and behavioral health" | ✗ Play Console 0 填 | Play Console 侧 1h |
| 2 | "Health Connect data types" 说明(如用 Health Connect) | ✓ 当前 App 不用 Health Connect(本地存储) | 勾"My app does not have any health features"或"Mental and behavioral health" 走 explain 段 |
| 3 | "Health data privacy declaration" 段: 收集/存储/共享/删除/跨境 | △ `privacy_policy.md:3-4` 5 段有,需对照 Play Console 字段填 | 1-2h 复制粘贴 |
| 4 | "Data safety section" 4 大类手动勾 | ✗ Play Console 0 填 | 2-3h |

**App 不属医疗器械类**(R66 W13 决策): 4 store 都不需 NMPA 备案,但 Play Console Health Apps 必勾 + 4 大表单必填。

**精神心理类政策风险**(Google Health Apps Policy §2.1):
- ✓ 不发布"诊断/治疗/治愈"声明(隐私政策 §10 已写"本 App 不提供医疗建议、诊断或治疗")
- ✓ 不推送未经核实的医疗内容(本 App 用 PHQ-9 / GAD-7 量表作自评,声明"仅供参考,不能替代专业医师面诊")
- ⚠ 需在 Play Console "App access" 勾 "All functionality is accessible without special access"(精神心理 App 切忌隐藏功能)
- ⚠ 需在 Play Console "Data safety" 勾 "Health info" 收集并说明 AES-256 + SQLCipher 加密

### 5.2 文档脱节(4 处 wording 修 — 5 视角共识 CC-7)

| 位置 | 当前 wording | 应改 wording | 难度 |
|------|------------|------------|------|
| `fastlane/metadata/android/en-US/full_description.txt:14` | "If you stop checking in for 2+ days, ChronicCare **can automatically notify** your trusted contacts..." | "If you stop checking in for 2+ days, ChronicCare **would automatically notify** your trusted contacts (coming soon — currently disabled)." | XS (5min) |
| `fastlane/metadata/android/zh-CN/title.txt:1` | "慢病管家 - 吃药打卡 + **失联通知**" | "慢病管家 - 吃药打卡 + **情绪关怀**" 或 "慢病管家 - 吃药打卡 + 危机提醒(规划中)" | XS (5min) |
| `assets/legal/user_agreement.md:17` | "**失联通知**(连续多日未打卡时,自动通知预设的紧急联系人)" | "**失联通知**(规划中,本版本已暂停) — 当用户连续多日未打卡时,App 将自动通知预设的紧急联系人" | XS (5min) |
| `assets/legal/user_agreement.md:40` | "因 SMS 通道未连接(默认 mock 状态)导致通知未发出" | "因失联通知业务整体暂停(`FeatureFlags.emergencyContactEnabled=false`)导致通知未发出" | XS (5min) |
| `assets/legal/sensitive_data_consent.md:27` | "**打卡时间戳** — 用于失联检测" | "**打卡时间戳** — 用于失联检测(规划中,本版本未启用)" | XS (5min) |
| `assets/legal/sensitive_data_consent.md:47` | "**打卡时间** | 失联检测" | "**打卡时间** | 失联检测(规划中,本版本未启用)" | XS (5min) |
| `assets/legal/sensitive_data_consent.md:64` | "在设置页关闭"失联通知"功能" | "在设置页关闭"失联通知"功能(规划中,本版本未启用)" | XS (5min) |
| `assets/legal/sensitive_data_consent.md:66-67` | "不提供姓名:失联通知无法个性化..." + "不提供紧急联系人:失联通知功能无法启用" | 改"失联通知功能**规划中**,本版本未启用" | XS (5min) |

**总耗时: 1-2h,1 个 PR 改 8 处 wording。** 跟 P0-7 SMS 真接(外部依赖 1-2 月)解耦,**先修文档层跟代码层对齐(CC-6 R68 已修)即可提审**。

### 5.3 法律 md i18n(CC-8,R68 未修)

`assets/legal/` 当前 0 英文 + 0 繁体版,3 份 md 全中文。

**影响**:
- 英国 / 港澳 / 台湾用户在 App 内设置 → 法律与隐私 → 显示中文 md(英文用户读不懂)
- 港澳 / 台湾用户繁体跟简体混用可能病耻感更强
- Play Console 不强制 i18n 法律文档,但**Data Safety Policy §1.5 要求 Privacy Policy URL 跟用户语言一致** → 至少 1 份 en 简版

**修法**:
- 选项 A(快): 1 份 `privacy_policy_en.md` 简版翻译(150 行内,核心 6 段)
- 选项 B(全): 3 份 md × 2 语言 = 6 份 + `setup_legal_dialog.dart:38` `showLegalDocument` 切 locale → 1 周工作量

**建议**: M1 先选 A,M2 再做 B(3 份 md 完整翻译 + locale 切)。

### 5.4 签名 / Play App Signing 流程(R66 §7.1 必做)

**R66 5 步指南** (`docs/PLAYSTORE_SIGNING_GUIDE.md` R67 新增) + R67 `signingConfigs.release` block 已加(读 `key.properties` 缺则 null),**只差最后 2 步**:
1. `keytool -genkey -v -keystore android/app/chroniccare-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias chroniccare`(30s)
2. `cp android/key.properties.example android/key.properties` + 填 4 真实值(2min)
3. 改 `build.gradle.kts:80` `signingConfig = signingConfigs.getByName("release")`(1min,1 行)
4. `flutter build appbundle --release` 测构建(2min)
5. Play Console → App integrity → Enable Play App Signing(5min)

**总耗时: 半天**。**前置**:chroniccare-release.jks 必须本地生成 + 备份到 1Password / Bitwarden,**绝不能丢**(丢 = App 永久无法升级)。

---

## §6 底层逐行排查(用户重点)

按主题:build.gradle / AndroidManifest / Privacy Policy / Data Safety / 截图 / 元数据 / 描述 / 守护脚本。

### 6.1 build.gradle.kts(`android/app/build.gradle.kts`)

| 行 | 项 | R69 状态 | 评 |
|----|----|---------|-----|
| 10 | `compileSdk = flutter.compileSdkVersion` (= 36) | ✓ R63 显式 | ✓ |
| 11 | `ndkVersion = flutter.ndkVersion` (= 27.0.12077973) | ✓ 16KB page size **未验** | ⚠ P1-7 |
| 31-32 | `minSdk = 24, targetSdk = 36` | ✓ R63 显式 pin(2026 Play 要求 ≥ 35) | ✓ |
| 33-34 | `versionCode = flutter.versionCode, versionName = flutter.versionName` | ✓ | ✓ |
| 37 | `multiDexEnabled = true` | ✓ | ✓ |
| 53-72 | `signingConfigs.create("release")` block | ✓ R67 加,读 `key.properties` 缺则 null | ✓ |
| 75-92 | `buildTypes.release { signingConfig = signingConfigs.getByName("debug")` | ✗ **仍 fallback debug** (P0-1) | ❌ |
| 83 | `isDebuggable = false` | ✓ R63 加 | ✓ |
| 86-91 | `isMinifyEnabled = true / isShrinkResources = true / proguardFiles(...)` | ✓ R8 启用 | ✓ |
| (缺) | `abiFilters` 显式声明 arm64-v8a / x86_64 | ✗ **未加** (P1-8) | ❌ |
| (缺) | 16KB page size 验脚本 | ✗ **未加** (P1-7) | ❌ |
| (缺) | APK 拆 abi (apk splits) | △ Flutter 默认 universal APK,**不拆可上传**(Play 自动按 device 切) | OK |

### 6.2 AndroidManifest.xml(`android/app/src/main/AndroidManifest.xml`)

| 行 | 项 | R69 状态 | 评 |
|----|----|---------|-----|
| 30 | `INTERNET` | ✓ | ✓ |
| 31 | `POST_NOTIFICATIONS` | ✓ Android 13+ 必填 | ✓ |
| 32 | `SCHEDULE_EXACT_ALARM` | ✓ + Play Console justification 100+ 字**未准备**(P0 子项 2-E) | ⚠ |
| 33 | `USE_EXACT_ALARM` | ✓ + Play Console justification 100+ 字**未准备** | ⚠ |
| 34 | `WAKE_LOCK` | ✓ | ✓ |
| 35 | `RECEIVE_BOOT_COMPLETED` | ✓ + BootReceiver 实装但**走占位路径**(P1-1) | ⚠ |
| 36 | `VIBRATE` | ✓ | ✓ |
| 37 | `RECORD_AUDIO` | ✓ + in-app rationale 部分 R66 修(待 R69 re-verify, P1-2) | ⚠ |
| 40-42 | `<uses-feature microphone required="false">` | ✓ | ✓ |
| 45 | `android:label="慢病管家"` | ✓ | ✓ |
| 47 | `android:icon="@mipmap/ic_launcher"` | ✓ (launcher icon,Play Console 上传需 512×512 独立,P0-6) | ⚠ |
| 48-50 | `dataExtractionRules` / `fullBackupContent` / `networkSecurityConfig` | ✓ R61/R63 修 | ✓ |
| 51 | `android:enableOnBackInvokedCallback="true"` | ✓ R63 加 | ✓ |
| 52 | `android:debuggable="false"` | ✓ R63 加 | ✓ |
| 53 | `android:allowBackup="false"` | ✓ R63 加 (PIPL §28) | ✓ |
| 55-76 | MainActivity 配置 | ✓ | ✓ |
| 87-95 | BootReceiver 接 BOOT_COMPLETED | ✓ R63 加,但**走占位路径**(P1-1) | ⚠ |

**Manifest 总评**: ✓ 9 个权限全,2 个资源 xml 齐,R63 加 6 项 P1 修,无 missed。

### 6.3 Privacy Policy URL

| 状态 | 评 |
|------|-----|
| `assets/legal/privacy_policy.md` 文档齐(13KB,205 行) | ✓ |
| `https://chroniccare.app/privacy` 公网 HTTPS 托管 | ✗ **未托管**(P0-2) |
| 隐私 URL 包含 §11 跨境 / §12 单独同意 / §3 共享 / §0 同意 / §4 用户权利 5 段 | ✓ R66/R67/R68 修 |
| Privacy §3 共享段 `失联通知触发时...` 措辞 vs 业务暂停 | ⚠ R68 修 CareEngine + ConsentGate,但文档措辞保留(待 P0-10 修) |

### 6.4 Data Safety Form(Play Console 侧 0 维护)

| 类别 | 应填 | 当前 |
|------|------|------|
| **Data collected**(收集) | Health info(药名 / 评估答案 / 情绪 / 录音) | ✗ 0 填 |
| **Data collected** | Contacts(紧急联系人手机号) | ✗ 0 填 |
| **Data collected** | Audio(录音) | ✗ 0 填 |
| **Data collected** | App activity(check-in / trend / settings) | ✗ 0 填 |
| **Data shared**(共享) | "No data shared" 勾(代码层 SMS 0 触发) | ✗ 0 填 |
| **Data security practices** | Data encrypted in transit + at rest | ✗ 0 填 |
| **Data deletion options** | Users can delete data in-app + uninstall | ✗ 0 填 |
| **Data deletion URL** | `https://chroniccare.app/delete-data-instructions` | ✗ 0 填(子项 2-G) |
| **Health data** | 勾"Health info" + 写 1 段 explain | ✗ 0 填 |

**总耗时: 2-3h 复制粘贴**。**优先级: M1 必做**(P0 子项 2-C)。

### 6.5 截图 / feature_graphic / icon

| 位置 | 状态 | 评 |
|------|------|-----|
| `fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/screenshot_{1..4}.png` (8 × 67 字节) | 1x1 像素占位 | ❌ P0-4 |
| `fastlane/metadata/android/{en-US,zh-CN}/feature_graphic.png` (2 × 67 字节) | 1x1 像素占位 | ❌ P0-5 |
| `fastlane/metadata/android/{en-US,zh-CN}/icon.png` (2 × 1443 字节, 192×192) | 192×192,需 512×512 | ❌ P0-6 |
| `fastlane/metadata/android/{en-US,zh-CN}/video.txt` (2 × 59 字节) | PLACEHOLDER URL | ⚠ P1-6 |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | ✓ 真实 launcher icon | ✓ |

**真截图脚本**(M1 必做):
```bash
flutter run -d <device>  # 真机 / 模拟器
# 截 4 个核心页面:
# 1. home_page(打卡主页)
# 2. medication_calendar(用药日历)
# 3. trend_page(趋势图)
# 4. vent_list(树洞列表) — 树洞功能展示
# adb shell screencap -p /sdcard/01.png && adb pull /sdcard/01.png
```
**真截图耗时: 半天**(含选 4 页面 + 排版 + 改尺寸)。

### 6.6 元数据(title / short_description / full_description)

| 位置 | 字符数 | 限制 | 状态 | 评 |
|------|--------|------|------|-----|
| `en-US/title.txt` | 27 | ≤ 50 | ✓ "ChronicCare - Med Reminder" | ✓ |
| `en-US/short_description.txt` | 69 | ≤ 80 | ✓ "Daily check-in + mood tracker for chronic patients. Private & local." | ⚠ P1-5 "chronic patients" 措辞 |
| `en-US/full_description.txt` | 2580 | ≤ 4000 | ✓ R67 加 "coming soon" 段 | ⚠ P1-4 line 14 "automatically notify" 措辞 |
| `zh-CN/title.txt` | 14 | ≤ 30 | ⚠ "慢病管家 - 吃药打卡 + 失联通知" | ❌ P1-3 wording |
| `zh-CN/short_description.txt` | 14 | ≤ 80 | ✓ R67 砍到 14 | ✓ |
| `zh-CN/full_description.txt` | 2232 | ≤ 4000 | ✓ R67 加 "暂停" 段 | ✓ |

### 6.7 描述/数据一致性(代码 vs 文档,CC-7 4 处脱节)

| 位置 | 文档 wording | 代码实际 | 状态 |
|------|------------|---------|------|
| `en-US/full_description.txt:14` | "**can automatically notify**" | `FeatureFlags.emergencyContactEnabled=false` + `AliyunSmsProvider.send()` throw | ⚠ P1-4 |
| `zh-CN/title.txt:1` | "**失联通知**" | 业务暂停 | ❌ P1-3 |
| `user_agreement.md:17` | "**失联通知**(连续多日未打卡时,自动通知预设的紧急联系人)" | 业务暂停 | ⚠ P0-10 |
| `user_agreement.md:40` | "**因 SMS 通道未连接**(默认 mock 状态)导致通知未发出" | 业务整体暂停 | ⚠ P0-10 |
| `sensitive_data_consent.md:27,47,64` | "**失联检测**" / "**失联通知**功能" | 业务暂停 | ⚠ P0-10 |
| `privacy_policy.md:64-72` §3 共享 | "**失联通知触发时**...本版本**不实际触发**" | R68 CC-6 修后 `FireCareStrategyUseCase` 早返 | △ 部分对齐 |

**总评**: 4/6 处 wording 仍跟代码不一致,**P0-10 1-2h 改完 6 处 wording 即可对齐 R68 修后状态**。

### 6.8 守护脚本 16 项状态(全绿,但 0 守护上架)

```
$ ls scripts/ | grep check_
check_all.dart                 check_cross_feature.py         check_fullwidth_punctuation.py
check_arb_keys.py              check_datetime_race.py         check_no_hardcoded_utc.py
check_changelog.py             check_datetime_race2.py        check_no_pua.py
check_orphan_arb_keys.py       check_drift_namespace.py       check_widget_dispose.py
check_legal_consent.py         check_sms_release_ready.py     check_zh_hant_consistency.py
check_strings_hardcoded.py
```

| # | 脚本 | R69 状态 | 评 |
|---|------|---------|-----|
| 1 | check_all.dart (架构纯度 + 一致性) | ✓ 绿 | ✓ |
| 2 | check_arb_keys.py (zh/en/zh_Hant 同步) | ✓ 绿 | ✓ |
| 3 | check_changelog.py | ✓ 绿 | ✓ |
| 4 | check_cross_feature.py | ✓ 绿 | ✓ |
| 5 | check_datetime_race.py + race2.py | ✓ 绿 | ✓ |
| 6 | check_drift_namespace.py | ✓ 绿 | ✓ |
| 7 | check_fullwidth_punctuation.py | △ warn-only(50 处全角标点) | △ |
| 8 | check_legal_consent.py | ✓ 绿 | ✓ |
| 9 | check_no_hardcoded_utc.py | ✓ 绿 | ✓ |
| 10 | check_no_pua.py | ✓ 绿 | ✓ |
| 11 | check_orphan_arb_keys.py | ✓ 绿(0 orphan) | ✓ |
| 12 | check_sms_release_ready.py (warn-only v0.27 R58 降) | ✓ 绿 | ✓ |
| 13 | check_strings_hardcoded.py | ✓ 绿 | ✓ |
| 14 | check_widget_dispose.py | ✓ 绿 | ✓ |
| 15 | check_zh_hant_consistency.py | ✓ 绿 | ✓ |

**R69 建议新增守护**(上架前):

| 建议 | 内容 | 难度 |
|------|------|------|
| `check_googleplay_metadata.sh` | 守护 fastlane/metadata/android/* 字节数: screenshots ≥ 50KB / feature_graphic ≥ 30KB / icon ≥ 20KB / video.txt 0 占位 URL | S (1h) |
| `check_privacy_url_https.py` | 守护 Play Console "Privacy Policy URL" 字段格式 + 域名可达(ping test) | S (1h) |
| `check_16kb_alignment.sh` | 守护 ndkVersion 显式 + apk 16KB 对齐 unzip + `objdump -p lib/*.so | grep LOAD` segment ≥ 16384 | S (2-3h) |
| `check_legal_doc_todo.sh` | 守护 `assets/legal/*.md` 顶部无 "TODO" / "未经律师过审" 关键词(上 store 前必清) | XS (30min) |
| `check_consent_kind_count.py` | 守护 ConsentKind enum 跟 setup 流程勾选项数对齐(R63 已修,守门员防回归) | XS (30min) |

---

## §7 修复优先级总表(按 P0/P1/P2 + 难度 + 阻塞)

### 7.1 P0 必修(10 项,按优先级)

| 序 | 类别 | 位置 | 难度 | 工作量 | 关键路径 |
|----|------|------|------|--------|----------|
| 1 | 底层 | GP-P0-1: `build.gradle.kts:80` 切 `signingConfig=release` + 生成 keystore + 配 `key.properties` | S | 半天 | **Day 1 上午** |
| 2 | 底层 | GP-P0-2: 注册 `chroniccare.app` 域名 + 部署 `https://chroniccare.app/privacy` HTML(转 3 份 md) | M | 1-2 天 | **Day 1-2** |
| 3 | 底层 | GP-P0-3: 注册 `support@chroniccare.app` 邮箱 + 替换 1 处 TODO | XS | 1-2h | **Day 1 下午** |
| 4 | 底层 | GP-P0-4/5/6: 写 8 张真截图 + 2 张 feature_graphic + 切 2 张 icon 512×512 | S | 半天 | **Day 1 下午** |
| 5 | 底层 | GP-P0-8: Android 端 fastlane Fastfile + Appfile 加 `platform :android do` 块 | S | 半天 | **Day 2 上午** |
| 6 | 底层 | GP-P0-10: 改 8 处文档 wording(CC-7 4 处 + R69-N1/N2/N3 4 处新增) | M | 1-2h | **Day 2 上午** |
| 7 | 底层 | GP-P0-2 子项: 填 Play Console 4 大表单(Data Safety + Health Apps + Permissions Declaration + Data Deletion) | M | 2-3h | **Day 2 下午** |
| 8 | 底层 | GP-P0-7 准备: Data Safety Form 勾"未触发失联通知共享"+ 加"如未来启用" 段 | S | 30min | **Day 2 下午** |
| 9 | 底层 | GP-P0-9: 律师 review 3 份 md + 删 "TODO 律师过审" 顶部 banner | L | 1-2 周 | **Day 2 启动并行,等交付** |
| 10 | 底层 | GP-P0-7 真接: `AliyunSmsProvider.send()` 真接(法务 1-2 月 + 阿里云 AccessKey 申请) | L | 1-2 月 | **M3 阶段** |

### 7.2 P1 应修(9 项,按 R68→R69 进展)

| 序 | 类别 | 位置 | 难度 | 工作量 | R68→R69 |
|----|------|------|------|--------|---------|
| 1 | 架构 | GP-P1-1: BootReceiver 切 FlutterEngineCache + MethodChannel | S | 2-3h | ❌ 0/5 |
| 2 | 底层 | GP-P1-3: `zh-CN/title.txt:1` 改 "失联通知" → "情绪关怀" | XS | 5min | ❌ 0/5 |
| 3 | 底层 | GP-P1-4: `en-US/full_description.txt:14` "can automatically" → "would automatically" | XS | 5min | ❌ 0/5 |
| 4 | 底层 | GP-P1-5: `en-US/short_description.txt:1` "chronic patients" → "people managing chronic conditions" | XS | 5min | ❌ 0/5 |
| 5 | 底层 | GP-P1-6: 删 `video.txt` 2 文件(留空 OK) | XS | 5min | ❌ 0/5 |
| 6 | 底层 | GP-P1-8: `build.gradle.kts` 加 `ndk { abiFilters.addAll(listOf("arm64-v8a", "x86_64")) }` | XS | 15min | ❌ 0/5 |
| 7 | 架构 | GP-P1-7: 写 `scripts/check_16kb_alignment.sh` 守门员 + 验证 | S | 2-3h | ❌ 0/5 |
| 8 | 底层 | GP-P1-2: `vent_compose_page.dart:135-141` RECORD_AUDIO in-app rationale 补 `openAppSettings()` 引导 | S | 1-2h | ⚠ 4/5(待 R69 re-verify) |
| 9 | 架构 | GP-P1-9: IAP 8 元 wording + productId 决策(关 / 真接) | M | 半天 | ⚠ 3/5 |

### 7.3 P2 建议(6 项,M2 阶段)

| 序 | 类别 | 位置 | 难度 | 工作量 |
|----|------|------|------|--------|
| 1 | 架构 | GP-P2-2: `docs/DEPLOYMENT.md:120-138` 重写 | M | 半天 |
| 2 | 架构 | GP-P2-3: `lib/main.dart:1-237` 加 background isolation 注释 | XS | 10min |
| 3 | 底层 | GP-P2-4: 升 `in_app_purchase: ^3.3.0` → `^7.x` | S | 半天 |
| 4 | 架构 | GP-P2-5: 3 份 md i18n 化(CC-8,英文简版先) | L | 1 周 |
| 5 | 底层 | GP-P2-6: `pubspec.yaml:2` description 多语(CC-5) | M | 1-2h |
| 6 | 架构 | R69-N1/N2/N3: §3 共享段 + §12 跨文档对齐 wording | S | 1h |

### 7.4 R69 建议新增 5 个守护脚本

| 序 | 守护 | 内容 | 难度 | 评 |
|----|------|------|------|-----|
| 1 | `check_googleplay_metadata.sh` | 守护 fastlane/metadata/android/* 字节数 | S (1h) | 必加 — 防 P0-4/5/6 回归 |
| 2 | `check_privacy_url_https.py` | 守护 Play Console "Privacy Policy URL" 字段格式 | S (1h) | 必加 — 防 P0-2 回归 |
| 3 | `check_16kb_alignment.sh` | 守护 ndkVersion + apk segment ≥ 16384 | S (2-3h) | 必加 — 防 P1-7 回归 |
| 4 | `check_legal_doc_todo.sh` | 守护 `assets/legal/*.md` 顶部无 "TODO" / "未经律师过审" | XS (30min) | 必加 — 防 P0-9 回归 |
| 5 | `check_consent_kind_count.py` | 守护 ConsentKind enum + setup 流程勾选项数对齐 | XS (30min) | 必加 — 防 CC-1 回归 |

---

## §8 3-5 句精炼建议(M1/M2/M3 时间预估)

### 8.1 M1 最小可上架(代码侧 + 半文档,3-5 天,**R69 立即启动**)

1. **Day 1 上午 4h**: GP-P0-1 切 release 签名(本地生成 keystore + 配 key.properties + 改 1 行 build.gradle.kts)。**前置**:keystore 备份到 1Password。
2. **Day 1 下午 4h**: GP-P0-3 邮箱注册(30min)+ GP-P0-4/5/6 真截图 + icon 切 512(3h)+ GP-P1-5/3/4 3 处 wording 改(15min)。
3. **Day 2 上午 4h**: GP-P0-2 注册域名 + 部署隐私 URL(1-2 天,可并行律师 review 启动)+ GP-P0-10 改 8 处文档 wording(1-2h)+ GP-P1-6 删 video.txt(5min)+ GP-P1-8 abiFilters(15min)+ GP-P1-1 BootReceiver 切(2-3h)。
4. **Day 2 下午 4h**: GP-P0-8 写 Android 端 Fastfile(半天)+ GP-P0-2 子项 4 大 Play Console 表单(2-3h)+ GP-P0-7 准备勾"未触发"(30min)。
5. **Day 3**: GP-P1-7 16KB page size 验(2-3h)+ GP-P1-2 RECORD_AUDIO 引导(1-2h)+ 跑 5 个新守护脚本 + flutter analyze + flutter test + 真机 build 测试。
6. **Day 4-5**: 律师 review 3 份 md 启动(并行,1-2 周);R68 决策 GP-P0-7 真接 / 关闭(决策 OR 1-2 月 OR 决策 IAP)。

**M1 关键路径**: 5 天 30-40h,**最大拦路虎仍是律师 review(1-2 周,¥15-30k/文档)**。

### 8.2 M1 法务 review 启动(并行,1-2 周)

启动 3 路并行(都 1-2 周,不可压缩):
- 律师过审 3 份 md(隐私政策 §0-12 + 用户协议 7 段 + 敏感数据同意书 6 段)
- 注册 `chroniccare.app` 域名(¥70/年,NameSilo / Cloudflare)
- 注册 `support@chroniccare.app` 邮箱(绑域名,免费 Zoho / ¥30/月企业邮)

### 8.3 M2 完整 CI 化(+3-5 天)

- 5 个新守护脚本(check_googleplay_metadata.sh / check_privacy_url_https.py / check_16kb_alignment.sh / check_legal_doc_todo.sh / check_consent_kind_count.py)
- GP-P2-2 重写 DEPLOYMENT.md 阶段 5
- GP-P2-3 Background isolation 注释
- GP-P2-4 升 `in_app_purchase: ^3.3.0` → `^7.x`
- 5 个 R68 子智能体遗留(CC-9/CC-10 已守,补 R49 之前的 dark mode 漏)

### 8.4 M3 v1.0 完整上线(+3-6 月,外部依赖)

- **GP-P0-7 真接**: 阿里云 SMS AccessKey 申请(法务 1-2 月 + 阿里云模板审核 1-2 周)
- **真接 IAP**: 创建 `com.chroniccare.app.lifetime` productId + 接入 `in_app_purchase ^7.x` + 法务定价审核
- **NMPA "非医疗器械"备案**: 精神心理类自评量表不属医疗器械,但需省级备案(2-3 月)
- **HIPAA / GDPR 律师过审**(若 v1.0 海外): 海外版需重新过审(¥30-50k)
- **软件著作权登记**: 精神心理类 + 数据安全(2-3 月,¥800-1500)
- **3 份 md i18n 化**(CC-8): 1 周 6 份 + locale 切
- **PIPL §38 跨境评估**: 失联通知真接后,境外紧急联系人触发的跨境 PII 评估(1-2 月,标准合同备案)

### 8.5 1 句话总结

**R68 修 3 个 P0 共识让"代码与文档全撒谎"降级为"代码层已诚实 + 文档层仍撒谎"**,**R69 1 步文档 wording 修(P0-10,1-2h)+ 注册域名邮箱 + 真截图 + Play Console 4 表单**= M1 5 天,**离 v1.0 上 store 剩最后"律师 1-2 周" + "SMS 真接 1-2 月" 2 个外部依赖**。项目代码侧 14 章规范合规率 88% 已是高水准,流程性上架 12% 是最后缺口。

---

## §9 附录:R66 → R67 → R68 → R69 状态总表

| R66 报告项 | R66 状态 | R67 修复 | R68 状态 | **R69 状态** | 评 |
|-----------|---------|---------|---------|---------|-----|
| §3.2 P0 USE_EXACT_ALARM justification | Play Console 必填 100+ 字符未准备 | ✗ 未动 | ⚠ P0 子项 2-E | ⚠ **仍 0 填** | ❌ |
| §3.3 P0 RECORD_AUDIO in-app rationale | 缺引导去 Settings | ✗ 未动 | ⚠ P1-2 | ⚠ R66 已加部分,**待 R69 re-verify** | ⚠ |
| §3.4 P0 SCHEDULE_EXACT_ALARM 引导 | NotificationStatusCard 漏 1 行 | ✗ 未动 | ⚠ P1-4 | ✓ R20 + R23 双轮已加 | ✓ |
| §6.1 P0 Privacy Policy URL 未托管 | 域名未注册 | △ R67 加 SPRINT1_LEGAL_TODO 集中器 | ✗ P0-2 | ✗ **仍 0** | ❌ |
| §6.2 P0 邮箱 TODO 占位 | support@ + privacy@ 都 TODO | △ R67 软隐藏 privacy@ 5 处,support@ 1 处仍 TODO | △ P0-3 | ✗ **仍 TODO** | ❌ |
| §6.4 P1 Health disclaimer | en-US + zh-CN 都已写 | 不变 | ✓ | ✓ | ✓ |
| §6.6 P1 zh-CN short_description 89 字符 | 超 80 字符 | ✓ R67 砍到 14 字 | ✓ | ✓ | ✓ |
| §6.7 P1 en-US "chronic patients" 措辞 | 措辞建议 | ✗ 未动 | ⚠ P1-5 | ❌ **仍 0** | ❌ |
| §6.8 P1 IAP 8 元买断 | 描述与代码不一致 | ⚠ R67 引入新不一致(默认开 + release 返 false) | ⚠ P1-3 (R68 新发现) | ✅ **R68 修: `_prodIapEnabled=false` 早返** | ✅ |
| §6.10 P1 Data deletion endpoint | 必填 | ✗ 未动 | ✗ P0-2 子项 | ✗ **仍 0** | ❌ |
| §6.11 P0 en-US "automatically notify" 措辞 | R66 改但文档没改 | △ R67 加 "coming soon" 段 | △ P0-10 | ⚠ **仍 wording**(R69 改 1 词) | ⚠ |
| §7.1 P0 release keystore 仍是 debug | debug-signed AAB | △ R67 加 signingConfigs.release block + 5 步指南 | ✗ P0-1 | ✗ **仍 fallback debug** | ❌ |
| §7.2 P0 Play App Signing 未启用 | 未启用 | ✗ 未动 | ✗ P0-1 | ✗ **仍 0** | ❌ |
| §7.3 P1 BootReceiver 占位 | 启动 MainActivity | ✗ R64/R65/R66/R67 4 轮未动 | ⚠ P1-1 | ❌ **仍 0**(R69 同) | ❌ |
| §7.4 P1 64-bit ABI 未显式 | 隐式 | ✗ 未动 | ⚠ P1-8 | ❌ **仍 0** | ❌ |
| §7.5 P2 root .gitignore 缺 *.jks | 兜底 | ✓ R67 加 `*.jks` / `*.keystore` / `key.properties` | ✓ | ✓ | ✓ |
| §9.2 P0 Fastfile/Appfile 缺失 | 无 lane | △ R67 加 Fastfile/Appfile **iOS-only** | ✗ P0-8 | ❌ **Android 端仍 0** | ❌ |
| §9.3 P0 截图/feature_graphic/icon 全占位 | 8 + 2 + 2 占位 | ✗ 0 变化 | ✗ P0-4/5/6 | ❌ **仍 0** | ❌ |
| §9.4 P1 video.txt 占位 URL | PLACEHOLDER | ✗ 未动 | ⚠ P1-6 | ❌ **仍 0** | ❌ |
| §10.1 GP-W1 SMS throw | R55+ TODO | △ R67 加 EmailService 守门员 | ⚠ P0-7 (法务依赖) | ❌ **仍 throw StateError** | ❌ |
| §10.1 GP-W2 signingConfig=debug | R55+ TODO | △ R67 加 signingConfigs.release block | ✗ P0-1 | ❌ **仍 fallback debug** | ❌ |
| §10.1 GP-W3 法律文档 TODO | 多 round TODO | ✓ R67 加 SPRINT1_LEGAL_TODO.md 集中器 | △ P0-3/9 | ❌ **3 份 md 顶部 TODO 全保留** | ❌ |
| §10.1 GP-W4 fastlane 缺 | 从未配 | △ R67 修了 iOS 端 | ✗ P0-4/5/6/8 | ❌ **Android 端仍 0** | ❌ |
| §10.1 GP-W5 BootReceiver 占位 | R63 注释 "留 R64" | ✗ 未动 | ⚠ P1-1 | ❌ **R64+ 4 round 0 进展** | ❌ |
| §10.2 GP-W6 RECORD_AUDIO rationale | R63 漏 | ✗ 未动 | ⚠ P1-2 | ⚠ R66 加部分,**待 R69 re-verify** | ⚠ |
| §10.2 GP-W7 SCHEDULE_EXACT_ALARM 引导 | R20 漏 | ✗ 未动 | ⚠ P1-4 | ✓ R20+R23 已加 | ✓ |
| §10.2 GP-W8 IAP dev 模式 | R65 dev 模式 | ⚠ R67 加 FeatureFlags 默认开 IAP | ⚠ P1-3 | ✅ **R68 修: `_prodIapEnabled=false` 早返** | ✅ |
| §10.2 GP-W9 zh-CN short_description 89 字 | 超 80 | ✓ R67 砍到 14 字 | ✓ | ✓ | ✓ |
| §10.2 GP-W10 失联通知 SMS 描述 | R66 改但文档没改 | △ R67 加 "本版本不实际触发" | △ P0-10 | ⚠ R68 CC-6 修后,**4 处 wording 仍 0** | ⚠ |
| §10.2 GP-W11 en-US "automatically notify" | 同上 | △ R67 加 "coming soon" 段 | △ P0-10 | ⚠ **line 14 wording 仍 0** | ⚠ |
| §10.3 GP-W12 Background isolation | 0 注释说明 | ✗ 未动 | ⚠ P2-3 | ❌ **仍 0** | ❌ |
| §10.3 GP-W13 SmsService.validateForRelease | R62 P0-1 加 | ✓ R67 修了 EmailService 平行 | ✓ | ✓ | ✓ |
| §10.3 GP-W14 DEPLOYMENT.md 阶段 5 outdated | 文档 stale | ✗ 未动 | ⚠ P2-2 | ❌ **仍 stale** | ❌ |
| CC-1 setup 阶段 saveSetup 绕过 ConsentDialog | spen 标 P0 | △ R67 加 ConsentDialog | ✗ P0 | ✅ **R68 d691551 修: setup 走 ConsentDialog** | ✅ |
| CC-3 IAP 8 元买断 vs buyLifetime 返 false | spen 标 P0 | ⚠ R67 默认开 IAP 引入新不一致 | ✗ P0 | ✅ **R68 d691551 修: `_prodIapEnabled=false`** | ✅ |
| CC-6 隐私政策撒谎(CareEngine safety) | spen 标 P0 | △ R67 业务层 ConsentGate 生效 | ✗ P0 | ✅ **R68 d691551 修: FireCareStrategyInput 加 isSafetyConsentWithdrawn** | ✅ |
| CC-7 4 处文档脱节(失联通知) | 4 视角共识 | △ R67 修 2 处 | ✗ P0-10 | ⚠ **剩 2 处 (zh-CN title + en-US line 14)** | ⚠ |
| CC-8 3 份 md 0 英文/繁体版 | 3 视角共识 | ✗ 未动 | ✗ P2-5 | ❌ **仍 0** | ❌ |
| CC-9 settings_page 2 处 dark mode 漏 | emil+spec 共识 | ✓ R49 修 35+ | ✓ | ✓ | ✓ |
| CC-10 app_theme 2 处 alpha inline | emil+spec 共识 | ✓ R50 抽 fgDisabled/fgHintInput | ✓ | ✓ | ✓ |
| **R66 P0 总数** | 10 | R67 修了 0 P0 (全是准备) | **R68 P0 仍 10** | **R69 P0 仍 8+2** (CC-3/CC-6/CC-1 修) | -1 |
| **R66 P1 总数** | 12 | R67 修了 3 项 | **R68 P1 9 项** | **R69 P1 9 项** (代码稳守) | 0 |
| **R66 P2 总数** | 6 | R67 修了 1 项 | **R68 P2 4 项** | **R69 P2 6 项** (P2-2/3/4/5/6 仍) | +2 |

**R66 → R69 净进展**:
- P0 持平(10 → 10,**净减 0**)+ 3 个代码侧 P0 修 + 7 个上架硬阻塞 P0 0 进展
- P1 略减(12 → 9 → 9,稳守)
- P2 减(6 → 4 → 6,R69 新增 P2-4 `in_app_purchase` 升 7.x + P2-5 i18n + P2-6 pubspec 多语)
- **R67 修的全是"准备"**,**R68 修的全是"代码侧"**,**R69 须修的是"上架前"流程性**。

---

**报告完毕。** 跟 R68 GooglePlay 报告对比,R69 总问题数从 8+2+9+4 = 23 → 8+2+9+6 = 25(+2 P2)。**核心变化**:
- R68 修 3 个代码侧 P0 共识(CC-3/CC-6/CC-1)→ 评级 3.0 → 3.5
- R69 新增 3 项(R69-N1 措辞 / R69-N2 §3 共享段 / R69-N3 §12 跨文档)+ 5 个建议新守护脚本
- **离 v1.0 上 store 仍卡在"流程性"上架**:keystore / 域名 / 邮箱 / 律师 / Play Console 4 表单(5 项外部依赖,1 周 + 1-2 月不可压缩)
