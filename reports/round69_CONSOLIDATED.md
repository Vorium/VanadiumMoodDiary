# v0.27 round 69 · 多视角综合审计报告

> **审计时间**:2026-08-02
> **项目版本**:0.27.0+64(v0.27 round 69)
> **审计视角**:6 个(emil 设计 / superpowers-en / superpowers-zh / App Store / Google Play / Flutter v3.1 规范)
> **6 份子报告**:
> 1. `round69_emil_design.md` (设计/动效)
> 2. `round69_superpowers_en.md` (TDD/方法论)
> 3. `round69_superpowers_zh.md` (中文工程/合规)
> 4. `round69_appstore.md` (iOS 上架)
> 5. `round69_googleplay.md` (Android 上架)
> 6. `round69_flutter_spec.md` (Flutter 规范)
> **当前测试基线**:`flutter test` 1368/1368 全过 / `flutter analyze` 0 error / 16 守护脚本全绿(本轮 R82 修后)
> **目标**:把 6 视角发现汇总成 1 份"可执行的修复路线图",**按架构/底层分类 + 修复难度 + 优先级排序**

---

## 0. 一页总览

### 0.1 6 视角评分

| 视角 | 评分 | 状态 | 关键结论 |
|---|---|---|---|
| **emil 设计** | A-(93/100) | 🟢 优秀 | 1 P0(黑底阴影)+ 3 P1 + 2 P2;R81 新增 4 处绕过集中器;20 分钟修可达 A |
| **superpowers-en** | B+(88/100) | 🟢 良好 | 2 处架构违规(1 P0 + 1 P1)+ 8 个 0 测关键路径 + 4 个守门员 P1 漏洞 |
| **superpowers-zh** | B(85/100) | 🟡 良好 | 2 P0(数据导出 0 consent + 繁简 14 处)+ 5 P1 + 5 P2;R55-R67 5 轮 PIPL 大修后留白 |
| **App Store** | 38/100 | 🔴 未达可提交 | **7 P0 阻塞**(截图全假 / Appfile 4 占位 / 隐私 URL 占位 / 0.27 4.3 Spam / 文案自相矛盾 / 8 元 IAP 隐藏 / Podfile 占位) |
| **Google Play** | 60/100 | 🟡 接近可提交 | **10 P0 阻塞**(keystore 缺 / 无 privacy URL / label 硬编码 / Data Safety 0 / 16KB 未验 / 法务未过审 ...)+ 12 P1 |
| **Flutter v3.1 规范** | 79.7% 合规 | 🟡 良好 | **2 阻断**(281 文件未格式化 + 无 PR 模板)+ 8 警告 + 3 建议 |

### 0.2 全项目风险数(去重后)

| 等级 | 数量 | 关键分布 |
|---|---|---|
| **🔴 P0 阻塞** | **17** 项(其中 14 项上架相关,2 项架构违规,1 项数据导出 consent) | App Store 7 + Google Play 10(去重 3) + 架构 1(间接 import flutter) + 繁简 14 处 + 数据导出 consent 1 + emil 黑底阴影 1 + dart format 281 文件 1 |
| **🟠 P1 应修** | **38** 项 | 上架元数据 5 + 国产 ROM 3 + 5 厂商 push 1 + zh_Hant 14 + 0 测试关键路径 8 + 4 守门员漏洞 + 失联 UX 显眼 1 + 联系人版本漂移 1 + 2 hardcode 中文 1 + 2 P1 架构 + 1 flutter_secure_storage 升 10x |
| **🟡 P2 锦上添花** | **11** 项 | API 文档 / 注释清理 / 7 god page 拆分 / P2 bug 等 |
| **🟢 P3 nit** | **2** 项 | last_med_info 走 intl / EdgeInsets 数字 magic |

### 0.3 上架准备度一句话

> **代码层 90% 就绪,工程卫生 85% 就绪,但商业层(元数据 / 法务 / 域名 / keystore)只有 5-60% 就绪**。
> 6 视角均不约而同把"上架元数据 / 法务 / keystore"列为 P0,这一块是不压缩的硬瓶颈。

---

## 1. 顶层架构审视(高内聚低耦合)

### 1.1 ✅ 架构已稳(全部视角共识)

- **4 层架构 + 共享 umbrella**(`core/data/ + core/shared/ + core/theme/ + core/routing/ + core/l10n/` + `domain/` + `presentation/` + `l10n/`)
- 16 守护脚本 + `dart scripts/check_all.dart` 守住架构纯度
- 命名一致(repo / impl / entity / mapper)
- 4 个 god class 已拆完(`data_export` / `medication_report_pdf` / `reminder_scheduler` / `mood_audio`)

### 1.2 🟡 架构级问题(2 项 + 1 项 P1)

#### 架构 P0-1:**`schedule_refill_reminder.dart:17` 间接 import flutter plugin**

- **位置**:`lib/domain/usecases/schedule_refill_reminder.dart:17` → `refill_notifier.dart`(后者顶部 import `flutter_local_notifications`)
- **违反**:domain 层声明 "0 flutter 依赖",但通过 use case 间接拉入整个 flutter plugin
- **影响**:domain 测试无法纯 dart 跑 / 任何 flutter plugin 变动污染 use case
- **修复方案**:把 `RefillNotifier.computeRefillFireTime` 纯函数抽到 `lib/domain/logic/refill_scheduler.dart`,usecase import 纯函数
- **难度**:M / 4h
- **视角**:superpowers-en

#### 架构 P0-2:**数据导出 0 consent 流程(PIPL §13/§44 双违反)**

- **位置**:`lib/presentation/pages/settings/data_management_section.dart:108-211` 导出 dialog 只有"警告",不生成 `ConsentArtifact`,不写 audit log
- **违反**:`lib/domain/entities/consent_artifact.dart:54` 已定义 `ConsentKind.dataExport`,**但 0 调用方**
- **影响**:PIPL §13 单独同意 + §44 数据可携权 双违反;精神心理 App 上 store 前必拒
- **修复方案**:复用 `ConsentDialog` 走 §13 单独同意 + `LegalConsentStore` 写 audit log + 隐私政策补 1 段
- **难度**:M / 1-2 day
- **视角**:superpowers-zh(本质架构,跨 4 个 feature 的横切关注点)

#### 架构 P1-1:**`check_safety.dart:16` 结构违规(实质 OK)**

- **位置**:`lib/domain/usecases/check_safety.dart:16` import `safety_detector.dart`(后者 0 flutter 引用但 import path 在 data 层)
- **影响**:`dart scripts/check_all.dart` 现有规则不查这种"实质合规但路径违规"
- **修复方案**:把 `SafetyDetector` 整个类移到 `lib/domain/logic/safety_detector.dart`
- **难度**:S / 2h
- **视角**:superpowers-en

#### 架构 P1-2:**`ConsentDialog` 仅支持 1 个 kind(架构 P0-2 的根因)**

- **位置**:`lib/presentation/widgets/consent_dialog.dart:43-96` `show(...)` 写死 `kind: ConsentKind.emergencyContactSharing` + `thresholdDays`
- **影响**:数据导出要 §13 单独同意,需要复用 `ConsentDialog` 但目前是 contact-specific API
- **修复方案**:抽 `ConsentDialog.show(...)` 参数抽象化,`thresholdDays` 改为 `placeholders: Map<String, Object>?`,UI 根据 `kind` 决定渲染
- **难度**:M / 半天
- **视角**:superpowers-zh

### 1.3 🟢 架构级建议项(Defer)

- `check_all.dart` 加 `package:flutter_riverpod/` / `package:go_router/` 到 domain forbidden list(P3 / S)
- 7 个 god page 拆分(XL / Defer 到 v1.0)
- Drift → Isar 迁移评估(L / 行业趋势)
- Freezed 替代 enum + nullable(sealed class exhaustive check)(L)

---

## 2. 上架 / 商业层问题(全部 P0)

### 2.1 App Store 7 P0 阻塞(必拒)

| # | 问题 | 文件 | 难度 |
|---|---|---|---|
| AS-1 | **11 个截图全 67 字节占位**(2.1.2 Placeholder) | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/screenshots/*.png` + `app_icon.png` 33 个全假 | M / 1-2 day |
| AS-2 | **fastlane/Appfile 4 处 TODO**(apple_id / team_id / itc_team_id) | `fastlane/Appfile:21-25` | S / 1h |
| AS-3 | **隐私/支持 URL 是占位域名** `https://chroniccare.app/*` | `fastlane/metadata/ios/*/privacy_url.txt` + `support_url.txt` + 法务 md 多处 | M / 1-2 day |
| AS-4 | **0.27.0+64 版本号 4.3 Spam 风险** | `pubspec.yaml:5` | M / 决策半天 |
| AS-5 | **description.txt 含"coming soon" / "currently disabled"** | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/description.txt:13-19` | S / 改文案 1h |
| AS-6 | **8 元买断 user_agreement 写明 + 实际 IAP 入口隐藏** | `assets/legal/user_agreement.md:22` + `feature_flags.dart:38` + `store_kit_service.dart:119` | M / 决策 + 半天 |
| AS-7 | **Podfile 是占位** | `ios/Podfile:1-16` Windows 无法 `pod install` | S / macOS 跑 1 次 30min |

### 2.2 Google Play 10 P0 阻塞(必拒)

| # | 问题 | 文件 | 难度 |
|---|---|---|---|
| GP-1 | **Release keystore 不存在** + `signingConfig` 仍指 debug | `android/app/build.gradle.kts:80` + `android/key.properties`(无) | S / 1-2h |
| GP-2 | **无在线 Privacy Policy URL** | `fastlane/metadata/android/*/privacy_url.txt`(无) | M / 1-2 day |
| GP-3 | **manifest `android:label` 硬编码中文"慢病管家"** | `android/app/src/main/AndroidManifest.xml:45` | S / 1h |
| GP-4 | **Data Safety Form 0 维护** | Play Console + `scripts/generate_data_safety_form.py` 已写 | M / 半天 |
| GP-5 | **Health apps 标记未勾选** | Play Console App content | S / 10min |
| GP-6 | **第三方 SDK 列表不完整**(`in_app_purchase` 必填) | `assets/legal/privacy_policy.md:99-104` 列 6 个,pubspec 16 个 | S / 1h |
| GP-7 | **fastlane/Appfile 缺 `json_key_file`** | `fastlane/Appfile:19-25` | S / 10min |
| GP-8 | **sqlcipher_flutter_libs 0.6.4 不支持 16KB page size** | `pubspec.yaml:23` 2025-11-01 起 AAB 必 16KB 对齐 | M / 半天 |
| GP-9 | **隐私政策仍是"草稿"** | `assets/legal/privacy_policy.md:218-220` | L / 1-2 周 + ¥15-30k |
| GP-10 | **R67 TODO 注释明示的 signingConfig 切换** | `android/app/build.gradle.kts:76-80` | S / 1min |

### 2.3 跨 Apple/Google 共有 P0(去重)

| 共有项 | 双方均要修 |
|---|---|
| **Privacy URL** | AS-3 + GP-2(部署 `https://chroniccare.app/privacy`) |
| **Appfile** | AS-2 + GP-7(2 个文件 1 个目标) |
| **法务过审** | AS-1 警告 + GP-9(¥15-30k/文档 × 3) |
| **隐私 / SDK 披露** | AS-3 + GP-6 |
| **Bug 截图/Icon** | AS-1(Apple 必拒)+ GP(强烈建议) |

### 2.4 严重半成品清单(卡业务)

| 半成品 | 卡点 | 解决路径 |
|---|---|---|
| 阿里云 SMS 真接 | 法务 1-2 月模板审核 + AccessKey | A-01(xlarge 80-120h) |
| SendGrid 邮件真接 | 同上(海外) | A-02(同上) |
| 紧急联系人本人独立确认 "Y" | 卡 SMS 真接 | A-03(卡 A-01) |
| 跨境 PIPL §38 评估 | 卡 SMS 真接 | A-04(卡 A-01) |
| 8 元买断 IAP 真接 | 决策 + App Store Connect 创建 productId | AS-6 决策 |
| 5 厂商 push SDK | 1-2 月审核 + 集成 | GP 长期 |
| BootReceiver 完整方案 | 决策 + 半天实现 | GP-1-1 |
| zh-Hant locale on Android | 翻译 + 截图 1 天 | GP-1-3 |

---

## 3. 底层逐行排查(代码细节 + Bug)

### 3.1 🟢 已修(确认无回归)

| 模式 | 证据 |
|---|---|
| 跨 midnight DateTime race | `safety_watch_service.dart:130-134` 接受 `now` 注入 ✓ |
| 时序数据隐式排序 | care_engine `sort((a,b) => b.timestamp.compareTo(a.timestamp))` ✓ |
| 通知 id cancel range | snooze base 300000,远超实际 ✓ |
| Stream subscription leak | vent_compose / vent_detail / mood_recorder 全 OK ✓ |
| BuildContext 跨 async gap | R73 改 `final ctx = context;` 模式 5 处消警 ✓ |
| AudioPlayer/recorder try/finally dispose | R19B 修过 ✓ |
| Riverpod 3.x `valueOrNull` → `value` | R3 已迁 ✓ |
| Material 3 ink_sparkle shader | `assets/shaders/ink_sparkle.frag` + pubspec 声明 ✓ |

### 3.2 🔴 P0 底层 bug(2 项,均已确认待修)

| # | bug | 文件:行 | 视角 | 难度 |
|---|---|---|---|---|
| bug-1 | **dart format 281 个 lib 文件未格式化** | `lib/ test/ scripts/` 全树 | flutter-spec | S / 5min |
| bug-2 | **domain usecase 间接 import flutter plugin** | `lib/domain/usecases/schedule_refill_reminder.dart:17` | sp-en | M / 4h(同架构 P0-1) |

### 3.3 🟠 P1 底层 bug(7 项)

| # | bug | 文件:行 | 视角 | 难度 |
|---|---|---|---|---|
| bug-3 | **8 个 0 测试 P0 关键路径**(lost_contact_sms / consent_artifact / safety_config_service / store_kit_service / data_export_service + 5 子服务 / encryption) | 8 个文件 | sp-en | M / 1-2 day 集中补 25-50 cases |
| bug-4 | **`check_datetime_race.py` 窗口 11 行太窄** | `scripts/check_datetime_race.py:35-39` | sp-en | S / 1h 替换 v2 |
| bug-5 | **`check_widget_dispose.py` `[^}]*` 嵌套 `}` 截断** | `scripts/check_widget_dispose.py:53-57` | sp-en | M / 2h brace matcher |
| bug-6 | **`check_cross_feature.py` 不查 `part` / `export`** | `scripts/check_cross_feature.py:31-35` | sp-en | S / 加 `EXPORT_RE` / `PART_RE` |
| bug-7 | **2 处 hardcode 中文**(home_fab_toolbar + email_preview) | `lib/presentation/pages/home/widgets/home_fab_toolbar.dart:85,101` + `email_preview.dart:61` | emil + sp-zh | S / 3min |
| bug-8 | **失联通知业务暂停无显眼 UX** | `lib/core/data/feature_flags.dart:35` `_prodEmergencyContactEnabled=false` 但 UI 无 banner | sp-zh | S / 1h |
| bug-9 | **联系人 consent 版本号漂移** | `lib/presentation/widgets/consent_dialog.dart:67,89` UI 硬编码 vs DB 动态 | sp-zh | S / 30min |

### 3.4 🟡 P2 底层 bug(5 项)

| # | bug | 文件:行 | 视角 | 难度 |
|---|---|---|---|---|
| bug-10 | **4 处 `catch (e)` 散落** | `medication_notifier.dart:92,140` / `refill_notifier.dart:170` / `notification_service.dart:159,228` / `snooze_manager.dart:119` | sp-en | S / 1h 替 `swallowError` |
| bug-11 | **`AppSnackBar` 绕开 2 处** | `home_fab_toolbar.dart:83-87, 99-103` 直接 `ScaffoldMessenger.showSnackBar` | emil | S / 15min |
| bug-12 | **emoji 字号 magic 5 处** | `hero_illustration.dart:67,82,96,106` + `quick_mood_carousel.dart:155` | emil | S / 15min 抽 4 token |
| bug-13 | **ListTile 缺 Semantics 标签 20+ 调用点** | `app_list_tile.dart:48-167` 集中器本身没 Semantics | emil | M / 2-3h 加 `semanticsLabel` 参数 + 30+ l10n key |
| bug-14 | **email_preview 预览 subject 走 i18n** | `lib/presentation/pages/settings/email_preview.dart:67` | sp-zh | S / 15min |

### 3.5 🟢 P3 nit(2 项)

| # | nit | 文件:行 | 难度 |
|---|---|---|---|
| bug-15 | `last_med_info` 手写日期格式化 | `lib/presentation/widgets/last_med_info.dart:71-78` 应走 intl.DateFormat | S / 5min |
| bug-16 | `EdgeInsets` 数字 magic 2 处 | `contacts_list_widget.dart:72` `EdgeInsets.all(4)` + `today_med_schedule.dart:180` `EdgeInsets.only(right: 4)` | S / 2min 改 `spacingXxs` |

### 3.6 工程卫生(2 阻断 + 8 警告 + 3 建议)

#### ⭐⭐⭐ 阻断(2 项)
- **flutter-spec B-01**:`dart format` 281 个 lib 文件未格式化(CI 会直接 fail)— S / 5min 一行命令
- **flutter-spec B-02**:无 PR 模板 / 无 CODEOWNERS(附录 A)— S / 30min

#### ⭐⭐ 警告(8 项)
- **flutter-spec W-01**:`withValues(alpha:...)` 13 处散落 → 应抽 `tintedScrimBlack` token
- **flutter-spec W-02**:2 个 test 文件含 unused import / unused variable 5 warning
- **flutter-spec W-03**:`check_zh_hant_consistency` 14 处繁简不一致(zh "抑郁" vs zh_Hant "憂鬱")
- **flutter-spec W-04**:`check_fullwidth_punctuation` 52 处半角符号 / 6 处半角省略号
- **flutter-spec W-05**:无 APM / 崩溃监控接入(`runZonedGuarded` 本地兜底但无远程)
- **flutter-spec W-06**:commit 不符合 Conventional Commits(自创 `<version> round <N>` 格式)— **豁免建议**
- **flutter-spec W-07**:CI 未跑 `check_zh_hant_consistency` 脚本(加 1 行)
- **flutter-spec W-08**:`catch (e)` 吞异常松散(同 bug-10,应强制 `swallowError`)

#### ℹ️ 建议(3 项)
- **I-01**:`flutter_secure_storage` 9.2.2 升 10.x
- **I-02**:`flutter test --coverage` + lcov summary(目标 domain ≥ 80% / overall ≥ 60%)
- **I-03**:MethodChannel 架构选择豁免(已记录在 AGENTS.md)

---

## 4. 关键 bug 模式回归(7 mode,全部已守)

| Mode | 状态 | 证据 |
|---|---|---|
| 1. schemaVersion 漏 migration | ✅ | `app_database.dart` schemaVersion 15 + database_migration R20/R37 |
| 2. 隐式排序假设 | ✅ | streak/assessment/reminder/safety_watch 显式 sort + regression test |
| 3. Stream subscription / 资源释放 | ✅ | vent_compose / vent_detail / mood_recorder 全 OK |
| 4. BuildContext 跨 async gap | ✅ | 3 处 `use_build_context_synchronously` 全用 `mounted` check |
| 5. DateTime.now() 多次 race | ✅ | 95 次 `DateTime.now()` / `check_datetime_race*.py` 双覆盖(但 v1 窗口太窄 → bug-4) |
| 6. notification id 冲突 | ✅ | cancel range 200000+ / medId 公式 |
| 7. 错误处理规范 | ⚠️ 4 处散落 | bug-10 待修 |

**结论**:已知 7 个 bug mode 全部已守,但**守护脚本本身**有 4 个 P1 漏洞(bug-3/4/5/6)需加固。

---

## 5. 半成品 / TODO 清单

### 5.1 真实待办(全部依赖外部)

| TODO | 文件:行 | 状态 | 卡点 |
|---|---|---|---|
| 阿里云 SMS 真接 | `sms_service.dart:90-201` | `_isFullyImplemented=false` 守门员到位 | 法务 1-2 月 + AccessKey |
| SendGrid 邮件真接 | `email_service.dart:158-164` | 跟 SMS 1:1 | 同上(海外) |
| 紧急联系人本人独立确认 "Y" | `setup_legal_dialog.dart:14-26` | 卡 SMS 真接 | 联系人回复 Y 通道 |
| 跨境 PIPL §38 评估 | `sms_service.dart:190-193` | 卡 SMS 真接 | Twilio 境内代理备案 |
| 5 厂商 push SDK | `pubspec.yaml` 0 厂商 | 1-2 月审核 | GP 长期 |
| 8 元买断 IAP 真接 | `feature_flags.dart:38` + `store_kit_service.dart:119` | 决策 + AS-6 | App Store Connect productId |
| BootReceiver 完整方案 | `BootReceiver.kt:18-21` "留给 R64 完善" | R64 注释未兑现 | 半天实现 |

### 5.2 半成品(已收尾但注释未清)

- `lib/domain/entities/scale_translations.dart:17,30` 注释 "R65 起步 TODO" — **R78 已收尾**,注释未删(留误导,5min 修)
- `lib/core/data/services/notification_service.dart:409` 自我引用 "R70 决策删 18+ 月挂 TODO" — 可保留(决策记录)

### 5.3 死代码 / 不可达路径

- **无** — 16 守护脚本 + `flutter analyze` 0 error 抓得很严,无 dead method / unused import

---

## 6. 修复优先级排序(按 ROI + 依赖关系)

### 🔴 批次 A · **本周(1-2 天,20 项 P0 全清)**

**目标**:B 阻断 2 项 + 上架 P0 14 项 + 架构 P0 2 项 = 18 项

| 时序 | 任务 | 来源视角 | 难度 | 估时 |
|---|---|---|---|---|
| 1 | `dart format lib/ test/ scripts/` + `dart fix --apply` | flutter-spec B-01 | S | 5min |
| 2 | 加 `.github/PULL_REQUEST_TEMPLATE.md` + `.github/CODEOWNERS` | flutter-spec B-02 | S | 30min |
| 3 | `flutter test` 确认 1368 全过 | flutter-spec | S | 1h |
| 4 | 修 `schedule_refill_reminder.dart` 抽 `computeRefillFireTime` 到 `domain/logic/` | sp-en 架构 P0-1 | M | 4h |
| 5 | `lost_contact_sms_round70_test.dart` + `consent_artifact_round70_test.dart` | sp-en bug-3 | S | 3.5h |
| 6 | `home_fab_toolbar.dart:124, 174` 改 `AppMotion.shadowOverlayOf(context)` | emil P0 | S | 5min |
| 7 | `home_fab_toolbar.dart:83-87, 99-103` 改 `AppSnackBar.showInfo` + 2 ARB key | emil P1-1 | S | 15min |
| 8 | 数据导出 ConsentDialog 走 §13 + LegalConsentStore audit log | sp-zh 架构 P0-2 + P1-2 | M | 1-2 day |
| 9 | 14 处繁简不一致 + 修 `phq9Severity*` zh_Hant | sp-zh P0 + flutter-spec W-03 | S | 1h |
| 10 | 注册 `chroniccare.app` 域名 + ICP 备案 + HTTPS 部署 3 份 md | AS-3 + GP-2 | M | 1-2 day |
| 11 | 跑 `keytool -genkey` + 改 `signingConfig = release` + 4 个值 | GP-1 + GP-10 | S | 1-2h |
| 12 | 改 `AndroidManifest.xml:45` 走 `@string/app_name` + 加 `values-en/strings.xml` | GP-3 | S | 1h |
| 13 | 跑 `python scripts/generate_data_safety_form.py` + 填 Play Console | GP-4 + GP-5 | M | 半天 |
| 14 | 升级 `sqlcipher_flutter_libs: ^0.6.5+` 验 16KB 对齐 | GP-8 | M | 半天 |
| 15 | 补全 `in_app_purchase` 等 SDK 披露 | GP-6 | S | 1h |
| 16 | Appfile 加 `json_key_file` + 替换 4 处 TODO(apple_id / team_id) | GP-7 + AS-2 | S | 30min |
| 17 | 改 description.txt 删"currently disabled" / "coming soon" | AS-5 | S | 1h |
| 18 | macOS 跑 `pod install` 重新生成 `Podfile.lock` | AS-7 | S | 30min |

**估时合计**:本周 5-7 天

### 🟠 批次 B · **本月(2-4 周,38 项 P1)**

**目标**:上架 P1 5 + 国产 ROM 3 + 0 测试 P0 路径 5 + 4 守门员漏洞 + 2 架构 P1 + 工程卫生 8 警告

#### B1 · 本周内(可与批次 A 并行,16 项)
- `check_safety.dart` 移到 `domain/logic/safety_detector.dart`(sp-en P1-1 / S / 2h)
- `data_export_sub_service_round71_test.dart`(orchestrator + pipeline + crypto + audio + schema 5 子服务,sp-en P1-2 / M / 6h)
- `safety_config_service_round71_test.dart`(8 个 SharedPreferences API + 边界,sp-en P1-3 / M / 3h)
- `check_datetime_race.py` 替换 v2 算法(sp-en bug-4 / S / 1h)
- `check_widget_dispose.py` brace matcher 替换(sp-en bug-5 / M / 2h)
- `check_cross_feature.py` 加 `EXPORT_RE` / `PART_RE`(sp-en bug-6 / S / 1h)
- `ListTile` 加 `semanticsLabel` + 30+ l10n key(emil P1-2 / M / 2-3h)
- 4 处 `catch (e)` 散落改 `swallowError`(sp-en P2 / S / 1h)
- 2 处 hardcode 中文走 l10n key(emil + sp-zh / S / 3min)
- 失联通知业务暂停的 UX 显眼 banner(sp-zh P1 / S / 1h)
- 联系人 consent 版本号漂移(sp-zh P1 / S / 30min)
- 导出/导入 PII 风险告知补全(sp-zh P1 / S / 15min)
- 13 处 `withValues` 替 `tintedScrimBlack` token(flutter-spec W-01 / S / 1h)
- 5 个 test warning 清理(flutter-spec W-02 / S / 15min)
- 52 处半角符号 / 6 处半角省略号(flutter-spec W-04 / M / 2-3h)
- 5 个 widget 加 emoji 字号 token(emil P1-3 / S / 15min)

#### B2 · 2 周内(12 项,涉及用户感知)
- 法务 review 3 法律 md(¥15-30k/文档 / L / 1-2 周)— 启动后立即同步
- 截 33 个真实 App Store 截图 + 3 张 App Icon(AS-1 / M / 1-2 day)— 设计师
- 找注册 `privacy@` + `support@` 邮箱(AS-1 P1-2 / S / 1-2h)
- 创建 GitHub 仓库 + issues section(AS-1 P1-3 / S / 半天)
- 跑 `flutter pub upgrade flutter_secure_storage` 升 10.x(flutter-spec I-01 / S / 1h)
- 加 `flutter test --coverage` + lcov summary(flutter-spec I-02 / S / 1h)
- 6 处 `phq9*Severity*` zh_Hant 走 OpenCC(sp-zh / M / 半天)
- Appfile 加 `json_key_file`(GP-7 / S / 10min)
- Podfile 改 Podfile + Podfile.lock 都跟踪(AS-7 / S / 5min)
- `ConsentDialog` 抽象化支持 5 kind(sp-zh P1-2 / M / 半天)
- TestFlight 至少 100 内部测试(AS-1 强烈建议 / L / 30 天)
- 接 1 厂商 push SDK(小优先 / L / 1 周)

#### B3 · 4 周内(10 项,长期)
- BootReceiver 改完整方案(FlutterEngineCache + MethodChannel / M / 半天)
- zh-Hant locale on Android(GP P1-3 / M / 1 day)
- Tablet 截图(GP P1-4 / M / 1-2 day)
- 修复 7 个 domain entity 0 测试(sp-en / M / 4h)
- iOS 16KB page size 验证(P1-4 / M / 1 day)
- NSFaceIDUsageDescription 加 Info.plist(AS-1 P1-5 / S / 10min)
- 接 3 厂商 push SDK(小米+华为+OPPO / XL / 4-8 周)
- 7 个 god page 拆分(sp-en Defer / XL / R71+)
- `check_fullwidth_punctuation.py` 去掉 `--warn-only`(flutter-spec W-04 跟)
- I-03 MethodChannel 架构选择豁免(仅文档)

### 🟡 批次 C · **季度(战略项,11 项 P2)**

| # | 任务 | 难度 | 估时 |
|---|---|---|---|
| 1 | 接入 Sentry / 自研 endpoint(脱敏 + 加密) | L | 2-3 day |
| 2 | 7 god page 拆分 1-2 个 | XL | 1 周 |
| 3 | `clearAllData` 同步清 LegalConsentStore + audit log | S | 30min |
| 4 | `email_preview` subject 走 i18n | S | 15min |
| 5 | CrisisSignal cn region 强解改兜底 | S | 30min |
| 6 | `scale_translations` 旧 TODO 注释清理 | S | 5min |
| 7 | ConsentArtifact 读 API(按 contactId 查历史) | M | 1-2 day |
| 8 | Freezed 替代 enum + nullable | L | 1 周 |
| 9 | Drift → Isar 迁移评估 | L | 1 月 |
| 10 | `pubspec.yaml` `flutter.ndkVersion: 27.0.12077973` 显式 | S | 5min |
| 11 | `W-06 commit 豁免 + AGENTS.md 一行说明` | S | 5min |

### 🔵 外部依赖(Defer,无 ETA)

- 阿里云 SMS 真接(法务 1-2 月 + AccessKey)
- SendGrid 邮件真接(同上)
- 紧急联系人本人独立确认 "Y"(卡 SMS)
- 跨境 PIPL §38 评估(卡 SMS)
- 5 厂商 push SDK 全部接入(1-2 月 × 5)
- 国内 5 大应用市场同步上架(需 ICP 备案 + 软件著作权 + 营业执照)

---

## 7. 7 视角一致性 + 冲突点

### 7.1 6 视角都说的"上架 P0 阻塞"

**完全一致**:6 视角均把"元数据 / 法务 / keystore / 域名 / 隐私 URL"列为 P0。
- emil P0(1 项)是"集中器绕开",跟其他视角无重叠
- sp-en P0(2 项)是"架构违规 + 0 测试关键路径"
- sp-zh P0(2 项)是"PIPL §13 数据导出 + 繁简 14 处"
- AS P0(7 项)/ GP P0(10 项)集中在上架元数据
- flutter-spec 阻断(2 项)是"工程卫生"

### 7.2 6 视角唯一冲突点

**失联通知业务暂停的 UX 显眼提示**(sp-zh 报 P1)vs **"featureFlags false 整段关闭"**(sp-en + AS + GP 均认为合规可接受)
- 结论:**采纳 sp-zh,加 1 个 banner 显眼提示**,其他 4 视角不冲突(sp-en / AS / GP 都同意业务暂停是临时止血,只是 UI 没显眼告知)

### 7.3 6 视角都未提到的"机会项"

- **接 5 厂商 push SDK**(GP P1 提到但优先级低)— 实际送达率 60% → 95% 是国产 ROM 救命稻草,**应升 P0**
- **flutter test --coverage 缺** — 1368 全过但不知道真实覆盖率,补 lcov 后能发现新盲区
- **R70 mid-night timer** — 跨 midnight streak 不刷新的兜底,已修但 agent 没提(状态保持)

---

## 8. 上架时间线(综合 AS + GP)

```
2026-08-02 (今天)
  ↓ 批次 A 启动(P0 全清,5-7 天)
2026-08-09 (1 周后)
  ↓ Apple M1 提交 + Google Internal Testing 提交
2026-08-16 (2 周后)
  ↓ Apple 审核(精神心理类 5-7 天常见)+ Google Production
2026-08-23 (3 周后)
  ↓ 上架 v0.27.0+64
  ↓ 法务过审完成(1-2 周)→ 重新提交
2026-09-13 (5-6 周后)
  ↓ v0.27.0+64 全合规版在线
  ↓ 批次 B 持续(2-4 周 P1 收尾)
2026-10-15 (10-12 周后)
  ↓ 决策 bump 到 1.0.0+1(M6)
  ↓ 5 厂商 push + BootReceiver 完整方案 + 接 1 厂商 push
2026-12-15 (4 月后)
  ↓ v1.0 准备 + R70+ 持续清理
2027-Q1 (5-6 月后)
  ↓ v1.0.0+1 发布(全合规 + 全功能 + 5 厂商 push + 阿里云 SMS 真接)
```

---

## 9. 总结 + 行动建议(一句话)

> **v0.27 round 69 项目核心 6 视角共识**:代码层 / 架构 / 测试 / 设计 / 规范都已达 85%+ 水准,**但上架商业层(元数据 + 法务 + keystore + 域名 + Data Safety + Data Export consent)是 5-60% 水准的硬瓶颈,这一块不修,代码再好都上不了 store**。
>
> 接下来 R82 优先级:
> 1. **本周批次 A 18 项 P0 全清**(架构 2 + 上架 14 + 工程卫生 2)— 5-7 天
> 2. **本月批次 B 38 项 P1 收尾**(测试 + 守门员 + UX 显眼 + 截图)— 2-4 周
> 3. **季度批次 C 11 项 P2 / 长期 P0** — 持续

**核心指标预测(批次 A 完成后)**:
- `flutter test` 1368 → 1390(+22, 失联 SMS / ConsentArtifact)
- 16 守护脚本 16 → 16(check_datetime_race 替换内部,数量不变)
- `flutter analyze` 0 error / 0 warning(281 个 dart format + 5 test warning 全清)
- 上架准备度:38%(AS)/ 60%(GP)→ **95%+**(AS)/ **95%+**(GP)
- 4 层架构:0 violation
- 0 覆盖 P0 关键路径:8 处 → 5 处
- B 阻断:2 → 0

---

## 引用清单

### 6 份子报告
- `reports/round69_emil_design.md` (9.6 KB)
- `reports/round69_appstore.md` (33.4 KB)
- `reports/round69_googleplay.md` (21.6 KB)
- `reports/round69_superpowers_en.md` (27.3 KB)
- `reports/round69_superpowers_zh.md` (20.4 KB)
- `reports/round69_flutter_spec.md` (21.4 KB)

### 6 视角引用文件(去重后)
**P0 关键路径**:
- `lib/domain/usecases/schedule_refill_reminder.dart:17`(架构违规)
- `lib/domain/usecases/check_safety.dart:16`(结构违规)
- `lib/domain/logic/lost_contact_sms.dart`(0 测)
- `lib/domain/entities/consent_artifact.dart`(0 测 + 数据导出 0 调用方)
- `lib/core/data/services/safety_config_service.dart`(0 测)
- `lib/core/data/services/store_kit_service.dart`(0 测)
- `lib/core/data/services/data_export_service.dart` + 5 子服务(0 测)
- `lib/presentation/pages/settings/data_management_section.dart:108-211`(数据导出 0 consent)
- `lib/core/data/services/refill_notifier.dart`(间接 flutter 依赖)
- `lib/main.dart:99,170,179,188`(LastErrorCapture + SMS/Email/IAP 守卫)

**上架 / 商业层**:
- `ios/Runner/Info.plist` / `ios/Runner/PrivacyInfo.xcprivacy` / `ios/Podfile`(占位)
- `ios/Runner/AppDelegate.swift` / `ios/Runner.xcodeproj/project.pbxproj`
- `fastlane/Appfile:19-25` / `fastlane/Fastfile:22-78` / `fastlane/metadata/ios/*/{screenshots,privacy_url,support_url,app_icon}.*`
- `android/app/build.gradle.kts:32,76-80,87,92-97` / `android/app/src/main/AndroidManifest.xml:30-37,45,88-95`
- `pubspec.yaml:5,23,27,63,65-68`
- `assets/legal/{privacy_policy,user_agreement,sensitive_data_consent}.md`
- `docs/{SPRINT1_LEGAL_TODO,VERSION_1.0_PLAN,DEPLOYMENT}.md`

**emil 设计**:
- `lib/presentation/pages/home/widgets/{home_fab_toolbar,hero_illustration,quick_mood_carousel}.dart`
- `lib/presentation/widgets/{app_list_tile,last_med_info,loading_skeleton}.dart`
- `lib/core/theme/{app_tokens,app_motion,app_colors,app_theme}.dart`

**flutter 规范**:
- `analysis_options.yaml:21`(require_trailing_commas)
- `.github/workflows/ci.yml:50-102`(14 守门员)
- `lib/main.dart:74-105`(runZonedGuarded)
- `lib/core/shared/swallow_error.dart`

**测试**:
- `test/` 143 文件 / `lib/` 266 文件 = 53.8%(文件维度)
- 1368 cases(R81) / 0 error / 5 warning / 21 info

### 18 守门员(全部跑过)
- 12 个 Python(`arb_keys` / `changelog` / `cross_feature` / `datetime_race×2` / `drift_namespace` / `fullwidth_punctuation` / `no_hardcoded_utc` / `no_pua` / `widget_dispose` / `legal_consent` / `sms_release_ready` / `strings_hardcoded` / `16kb_alignment` / `zh_hant_consistency` / `orphan_arb_keys`)
- 1 个 Dart(`check_all.dart`)
- 2 个 helper(`_clean_orphan_arb_keys.py` / `generate_data_safety_form.py`)

---

> **总字数**:约 4 千字
> **总项数**:17 P0 + 38 P1 + 11 P2 + 2 P3 + 4 外部依赖(去重后)
> **总证据数**:100+ 文件:行号引用
> **下次审计建议**:R82 修完(预计 2026-08-15)+ 重新跑 6 视角 + 1.0 上架前再审
