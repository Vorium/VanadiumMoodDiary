# Round 74 — 6 视角审计总览

**审计时间**: 2026-08-01
**项目**: chroniccare — 精神心理患者吃药打卡 App
**版本**: v0.27.0+64 (R74 commit 6e9f07e 收尾后)
**基线**: 1285/1285 tests pass / 0 error / 0 warning / 0 info (历史性 0 info) / 17 守护脚本全绿
**审计模式**: 6 个 sub-agent 并行 (emilkowalski / superpowers-en / superpowers-zh / AppStore / GooglePlay / flutter-specification)
**R74 重要发现**: R65 entity 加 i18n 调用但 ARB 漏 3 key, flutter clean 第一次才暴露 → commit 6e9f07e 修

## 0. 6 视角评分

| 视角 | 评分 | 评分维度 | 关键发现数 |
|------|------|---------|----------|
| **emilkowalski** (设计工程) | 4.5 / 5 ⭐⭐⭐⭐½ | 设计成熟度 | 高 1 + 中 4 + 低 7 = **12 项** |
| **superpowers-en** (TDD + bug 模式) | **9.2 / 10** | 架构健康度 | 0 P0 + 2 P1 + 4 P2 + 6 P3 = **12 项** |
| **superpowers-zh** (中文 + PIPL + 临床) | 4.5 / 5 ⭐⭐⭐⭐½ | 中文语境 + 病耻感 + 临床 | 5 P0 + 6 P1 + 4 P3 = **15 项** |
| **AppStore** (上架合规) | **2 / 10** | 上架就绪度 | **12 P0** + 7 P1 + 3 P2 = **22 项** |
| **GooglePlay** (上架合规) | **4.0 / 10** (vs R69 3.5) | 上架就绪度 | **8 P0** + 多个 P1 = **~20 项** |
| **flutter-specification** (v3.1 规范) | **9.1 / 10** | v3.1 合规率 | **0 阻断** + 8 警告 + 14 建议 = **22 项** |

**总画像**:
- 架构 / 代码 / 设计 / 规范 = 业界顶级 (9+ / 10 区间, 0 P0 阻断)
- 上架就绪 = 严重不足 (2-4 / 10, 12+ P0 阻塞)
- 中文 / 病耻感 / 临床 / PIPL = 中上 (4.5 / 5, 5 P0 仍挂)

---

## 1. 顶层架构审视 (高内聚低耦合)

### 1.1 4 层架构 + core/ umbrella

| 维度 | 状态 | 证据 |
|------|------|------|
| **依赖方向** | ✅ 100% 纯 | `dart scripts/check_all.dart` 全绿, 0 violation |
| **domain 纯度** | ✅ 0 flutter / 0 drift / 0 data / 0 presentation | check_all.dart [1/2] |
| **shared 纯度** | ✅ 0 flutter / 0 drift | check_all.dart [1/2] |
| **data 不依赖 presentation** | ✅ | check_all.dart [1/2] |
| **跨 feature 互不耦合** | ✅ 67 files checked / 0 violation | check_cross_feature.py |
| **Entity ↔ drift table** | ✅ 7 个 mapper, 1:1 对应 | check_all.dart [2/2] |
| **核心共享层 ≥ 2 层用** | ✅ | check_all.dart [2/2] |

### 1.2 高内聚 (5 / 5)

- **集中器抽取**: 18 个 widget 集中器 (R59-R72 累计) — `InfoBanner` / `StatCard` / `DialogActionsRow` / `ChoiceChipWrap` / `SwipeDeleteBackground` / `ConsentDialog` / `SectionHeader` / `AppListTile` / `PrimaryButton` / `PressFeedbackIconButton` / `LoadingTextButton` / `LoadingScrim` / `CelebrationBounce` / `AppSnackBar` / `EmptyState` / `ErrorState` / `PageTransitionSwitcher` / `Haptics`
- **Token 集中**: 23+ AppTokens (8 atomic size + 6 curve + 8 duration + 4 theme-aware shadow + scrim) — 4 个集中器子文件 (`app_colors` / `app_motion` / `app_spacing` / `app_typography`)
- **共享工具**: `swallowError` (40+ 调用) / `DateTimeResolvers.at` (R67 抽) / `AppSnackBar.showError` (15+ 调用) / `LastErrorCapture` (R22)

### 1.3 低耦合 (5 / 5)

- 8 个 feature page 完全互不耦合 (跨 feature 0 渗透)
- facade pattern: notification_service 6 sub-service / safety 5 sub-service / data_export 4 sub-service — 6 个 facade, 0 god class
- Provider 注入 7 个 repository 都走 `XRepository` abstract 接口, 0 impl 直调

### 1.4 模块边界 — 跨视角发现

| 视角 | 发现 | 严重度 | 类型 |
|------|------|------|------|
| superpowers-en | **P1**: domain 3 文件 import `package:chroniccare/l10n/app_localizations.dart` (软违规) | P1 | **架构** |
| 位置 | `vent_entry_entity.dart:19` / `scale_translations.dart:26` / `day_detail.dart:27` | | |
| 描述 | 3 个 domain 文件通过 l10n 间接依赖 Flutter, 违反 4 层架构纯度 | | |
| 修法 | l10n 调用改 `String Function(AppLocalizations)?` 参数化注入 | | |
| 估时 | 1-2h (中等) | | |

---

## 2. 底层逐行排查

### 2.1 已知 5 类 bug 模式 (superpowers-en 重点)

| 模式 | 状态 | 验证 |
|------|------|------|
| 隐式排序 (`.first/.last` 假设时序) | ✅ 5 处历史 bug 修完 (streak / comparison / scheduler / watch / assessment) | check_datetime_race.py + check_datetime_race2.py |
| Stream subscription leak | ✅ check_widget_dispose.py 0 资源泄漏 | check_widget_dispose.py |
| BuildContext across async gaps | ✅ R73 9 info 全清, 0 残留 | flutter analyze 0 info |
| DateTime.now() race | ✅ check_datetime_race.py 0 命中 | check_datetime_race.py |
| try/finally 资源释放 | ✅ mood_audio_section / vent_compose 修正 | code review |

### 2.2 病耻感措辞 (superpowers-zh 重点) — **R74 新发现 5 处挂**

| ID | 位置 | 当前文案 | 严重度 | 建议 |
|----|------|---------|------|------|
| **R74-N1** | `app_zh.arb:635` `homeStreakRestart` | "今天重新开始，**加油** 🌱" | **P0** | 删 "加油" → "今天重新开始 🌱" |
| **R74-N2** | `app_zh.arb:645` `homeStreakGreat` | "已坚持 {days} 天，**真棒** 🌳" | **P0** | 删 "真棒" → "已坚持 {days} 天 🌳" |
| **R74-N3** | `app_zh.arb:653` `homeStreakAmazing` | "{days} 天连击，**太厉害** 🌲" | P1 | 删 "太厉害" |
| **R74-N4** | `app_zh.arb:661` `homeStreakMaster` | "{days} 天--**您已经是这个习惯的主人了** 🏔️" | P1 | 删 "您已经是…主人" |
| **R74-N5** | `app_zh.arb:908` `homeCelebrationStreakMaster` | "已记录！{days} 天--**您太厉害了** 🏔️" | P1 | 删 "您太厉害了" |
| en/zh_Hant 同步 | 同样问题 — "Let's go!" / "Awesome" / "Incredible" / "Master" | | P1 | 英文 / 繁体同样改 |

**R72 漏扫原因**: R72 spzh P0-4 只扫 `lib/core/l10n/strings.dart` + `care_copy.dart`, 没扫 `lib/l10n/app_zh.arb` 鼓励文案。

### 2.3 i18n 漏 (硬编码中文) — **R74 新发现**

| ID | 位置 | 当前 | 严重度 | 建议 |
|----|------|------|------|------|
| **R74-N6** | `core/l10n/strings.dart:96` `notifDailyCheckInBody` | "留个**今**的踏实" — "今" 错字 | **P0** | 改 "今天" / "日复一日" |
| **R74-N7** | `core/data/services/safety_alert_builder.dart:98` | `title = '⚠️ $name 已 $daysWithoutCheckIn 天未打卡'` | **P0** | 加 `safetyAlertTitle` ARB key, 走 l10n |
| R74-N8 | `core/data/services/safety_alert_builder.dart:108` | `if (lastCheckIn == null) return '从未打卡';` | P1 | 同样走 l10n |

### 2.4 PIPL 合规 (superpowers-zh 重点)

| ID | 位置 | 问题 | 严重度 | 法条 |
|----|------|------|------|------|
| **R74-N9** | `domain/logic/lost_contact_sms.dart:73` | `buffer.writeln('常吃药: ${medication.name} ${medication.dosage}${medication.dosageUnit.id}');` — reminder 发 medication name 给紧急联系人 | **P0** | **PIPL §6 PII 暴露** |
| **R74-N11** | `presentation/pages/setup/setup_page.dart:36` `_kLegalVersion = 'v0.21-2026-07-20'` 写死 | 文档 R54/R66/R67/R68/R69/R70/R71/R72 多次修订, re-consent 触发逻辑失效 | **P0** | PIPL §17 同意记录失效 |
| R74-N12 | `presentation/widgets/consent_dialog.dart:85` `ConsentArtifact.version = 'v1'` 写死 | 同 R74-N11 | P1 | PIPL §17 同意版本失效 |
| R74-N13 | `presentation/pages/home/home_page.dart:557-560` | `smsServiceProvider.send(to: '00000000000', body: ...)` 占位 phone | P1 | 生产代码 hardcoded 占位 |
| R74-N14 | `presentation/pages/home/home_page.dart:567-574` | `emailServiceProvider.sendMedicationReminder(to: 'placeholder@invalid.local', ...)` 占位 email | P1 | 生产代码 hardcoded 占位 |

### 2.5 临床精度 (superpowers-zh 重点)

| ID | 位置 | 问题 | 严重度 | 建议 |
|----|------|------|------|------|
| R74-N10 | `app_zh.arb:782` `assessmentSeverityNormal = "正常"` | PHQ-9 / GAD-7 临床标准是 "几乎没有" (minimal), "正常" 对精神心理患者有 stigma 二分 | P1 | 改 "几乎没有" (minimal) |

### 2.6 i18n 漏 (通知文案)

| ID | 位置 | 问题 | 严重度 | 建议 |
|----|------|------|------|------|
| R74-N7 | `core/data/services/safety_alert_builder.dart:98` | `title = '⚠️ $name 已 $daysWithoutCheckIn 天未打卡'` 硬编码中文 | **P0** | 加 ARB key |
| R74-N8 | 同上 :108 | `'从未打卡'` 硬编码 | P1 | 同样走 l10n |

### 2.7 过期注释 (代码注释错位)

| ID | 位置 | 问题 | 严重度 |
|----|------|------|------|
| R74-N15 | `domain/logic/care_engine.dart:10` 注释 | `// - 连续 7 天准时 → 庆祝 push "你真棒！"` — 注释仍写 "你真棒", 实际 R72 已改 `care_copy.dart:48` 为 "今周已全部准时" | P3 |

### 2.8 动效 / 设计 token (emilkowalski 重点)

| 模式 | 状态 | 集中度 |
|------|------|------|
| `PressFeedbackIconButton` 集中器 | ✅ | 100% (31 IconButton 中 27 走集中器 + 4 集中器自身) |
| `PrimaryButton` 集中器 | ⚠️ | 72% (5 处 ElevatedButton 直调 — reminders_hub/contacts/data_mgmt) |
| Haptics 调用 | ✅ | 11+ 处, 0 散落 |
| AppSnackBar 集中器 | ✅ | 75+ 调用, 0 直调 ScaffoldMessenger |
| 曲线 token (`curve*`) | ✅ | 6 个, 100% 走集中器 |
| duration token | ✅ | 8 个, 100% 走集中器 |

### 2.9 i18n 漏 (superpowers-en 软违规)

| ID | 位置 | 严重度 | 类型 |
|----|------|------|------|
| P1-1 | `vent_entry_entity.dart:19` / `scale_translations.dart:26` / `day_detail.dart:27` 3 文件 import Flutter 间接依赖 | P1 | **架构** |

---

## 3. 上架就绪度 (AppStore + GooglePlay 重点)

### 3.1 App Store 12 P0 阻塞 (评分 2/10)

| ID | 位置 | 阻塞原因 | 难度 |
|----|------|---------|------|
| **AS-P0-1** | `ios/Runner.xcodeproj/project.pbxproj:378/558/581` `PRODUCT_BUNDLE_IDENTIFIER = com.chroniccare.app` vs `fastlane/Appfile:19` `app_identifier("com.chroniccare.chroniccare")` **不一致** | fastlane 上传会被拒 | XS (1 行) |
| **AS-P0-2** | `fastlane/Appfile:21, 23, 25` 3 TODO ID 仍是占位 | 提交即拒 | XS (替换) |
| **AS-P0-3** | `ios/Runner/AppDelegate.swift` UNUserNotificationCenter delegate 设但**未实现 foreground 通知** | 用户用 app 时通知不弹 | XS (加 method) |
| **AS-P0-4** | `ios/Runner.xcodeproj/project.pbxproj:193-196` `knownRegions = (en, Base)` 缺 `zh-Hans` / `zh-Hant` | zh-Hans/zh-Hant InfoPlist.strings 不被 iOS 识别 | XS (改 1 行) |
| **AS-P0-5** | iOS 端缺 `Podfile` + `Podfile.lock` (首次跑 fastlane 直接失败) | first build 失败 | S (跑 pub get) |
| **AS-P0-6** | **33 张 67 字节占位截图** (1232×720 不是任何 Apple 截图尺寸) | 上传即拒 | L (真机截图) |
| **AS-P0-7** | 3 张 `app_icon.png` 全 67 字节占位 (需 1024×1024 不透明) | 上传即拒 | L (设计师) |
| **AS-P0-8** | 6 URL 文件 `privacy_url.txt` / `support_url.txt` × 3 locale 全是 `https://chroniccare.app/privacy` — 域名**未注册未验证** | reviewer 点 URL 验真伪时 404 | L (注册域名) |
| **AS-P0-9** | `user_agreement.md:60-61` `support@chroniccare.app` 邮箱 + GitHub 仓库占位 | 邮箱必填且真实可达 | S (注册邮箱) |
| **AS-P0-10** | 3 份法律 md **无英文版 / 繁体版** | Medical 类 en-US 必走 | L (翻译 1-2 周) |
| **AS-P0-11** | `privacy_policy.md:0.5` + `user_agreement.md:60-61` 引用不存在的 `docs/SPRINT1_LEGAL_TODO.md` + `docs/LEGACY_API_NOTES.md` | 引用死链 | XS (创建占位) |
| **AS-P0-12** | AS-P0-9/10/11 合并: Medical 类 en-US 必走, 邮箱 + 域名 + 英文法律 md 全缺 | 综合阻塞 | L |

### 3.2 Google Play 8 P0 阻塞 (评分 4.0/10, vs R69 3.5/10)

| ID | 位置 | 阻塞原因 | 难度 |
|----|------|---------|------|
| **GP-P0-1** | `android/app/build.gradle.kts:80` 仍 `signingConfig=debug` + `key.properties` 不存在 + `.jks` 不存在 | 上传即拒 | S (跑 generate_release_keystore.ps1) |
| **GP-P0-2** | `assets/legal/privacy_policy.md` + Privacy Policy URL 未托管到 HTTPS 公网 | 提交即拒 | L (HTTPS 部署) |
| **GP-P0-3** | `user_agreement.md:60` `support@chroniccare.app` TODO 占位 | Developer email 必填 | S (注册邮箱) |
| **GP-P0-4** | `fastlane/metadata/android/{en-US,zh-CN}/phone_screenshots/screenshot_{1..4}.png` (8 × 67 字节 1x1 占位) | 上传即拒 | L (真机) |
| **GP-P0-5** | `fastlane/metadata/android/{en-US,zh-CN}/feature_graphic.png` (2 × 67 字节 1x1 占位) | 上传即拒 | L (设计师) |
| **GP-P0-6** | `fastlane/metadata/android/{en-US,zh-CN}/icon.png` (2 × 1443 字节 192×192) | 需 512×512, 当前 192×192 | L (重做) |
| **GP-P0-7** | `lib/core/data/services/sms_service.dart:194-198` `throw StateError` + `AliyunSmsProvider._isFullyImplemented=false` | SMS Provider 仍 throw | XL (法务 + 阿里云 AccessKey 1-2 月) |
| **GP-P0-8** | ~~R70 修完~~ ✅ | | |

### 3.3 iOS / Android 端非阻塞警告

- iOS 端: 6 字段 NSPrivacyAccessedAPICategory + 4 PII key + SceneDelegate + ITSAppUsesNonExemptEncryption 完整 (R61-R72 集中修)
- Android 端: 8 permissions + networkSecurityConfig + dataExtractionRules + backupRules + 64-bit ABI + 16KB check + BootReceiver (R61-R72 集中修)

---

## 4. 建议重构 (emilkowalski + superpowers-en 重点)

### 4.1 重构候选 (评估后排序)

| ID | 位置 | 行数 | 类型 | 难度 | 收益 | 决策 |
|----|------|----|------|------|------|------|
| **R74-REF-1** | `presentation/pages/mood/mood_dialog.dart` | 1204 | god class 候选 | L (3h+) | 大 | superpowers-en P2-2 推荐拆 |
| **R74-REF-2** | `presentation/pages/home/home_page.dart` | 678 | 长文件 (10 method + 1 class) | L (1-2h) | 中 | superpowers-en P3-1 / emil P-LOW-01 推荐抽 3 controller |
| **R74-REF-3** | `core/data/services/export/export_orchestrator.dart` | 565 | 长文件 (exportToJson 200+ 行) | M (2h) | 中 | superpowers-en P2-3 推荐拆 export / import 2 文件 |
| **R74-REF-4** | `presentation/pages/mood/widgets/mood_audio_section.dart` | 591 | audio + STT 状态机 | XL | 低 | emil P-MID-04 / spen: "R46 已拆, 进一步收益小, 保留不拆" |
| **R74-REF-5** | `presentation/pages/trend/trend_calendar.dart` | 528 | 11 处 `TextStyle(...)` inline 残留 | S (1h) | 小 | emil P-MID-05 推荐改 token |
| **R74-REF-6** | `presentation/pages/setup/setup_page.dart` | 495 | 4 step wizard | M (1-2h) | 中 | superpowers-en P3-2 推荐退化为 stepper orchestrator |
| **R74-REF-7** | `core/data/services/notification_service.dart` | 419 | facade 偏长 (6 sub-service 已拆) | L | 低 | emil P-MID-02: "已 facade 化, 进一步收益小" |
| **R74-REF-8** | press feedback 3 文件组 | — | `feedback.dart` + `press_feedback.dart` + `press_feedback_icon_button.dart` | S (半天) | 小 | superpowers-en P3-3 推荐抽 `PressFeedback` 统一 |

### 4.2 集中器抽取机会 (emilkowalski 重点)

| 集中器 | 当前 | 集中度 | 机会 |
|--------|------|------|------|
| `PrimaryButton` | 18 调用 | 72% | 5 处直调 ElevatedButton (reminders_hub/contacts/data_mgmt) — 提至 100% |
| `AppListTile` | 12 调用 | 60% | 5 处直调 ListTile (medication/mood/home) — 提至 100% |
| `StatCard` | 8 调用 | 50% | 8 处直调 Card+Row — 提至 80% |
| `InfoBanner` | 5 调用 | 100% | 已 100% 集中, 0 机会 |
| `Haptics` | 11 调用 | 100% | 已 100% 集中, 0 机会 |

### 4.3 测试覆盖盲区 (superpowers-en 重点)

| ID | 位置 | 覆盖缺失 | 估时 |
|----|------|---------|------|
| P3-5 | vent_entry_entity + scale_translations i18n 测 | R65 抽 l10n 0 测, 补 11 case | 1-2h |
| P3-6 | home_page + setup_page 集成测 | 18 case 覆盖 deep link + CareEngine 4 channel + 4 step wizard | 2-3h |
| P2-4 | notification_service facade 集成测 | init() 顺序 + 6 类 ID 范围 + showSafetyAlert 文案 3 态分流 0 单测 | 1-2h |
| 历史 | 8 个测覆盖盲区 (R66 报告 6 + R74 新增 2) | 8 case | 5-6h |

---

## 5. 半成品 (superpowers-en + zh 重点)

| ID | 位置 | 问题 | 类型 | 难度 | 决策 |
|----|------|------|------|------|------|
| P2-1 | `lib/presentation/pages/vent/vent_compose_page.dart:77` | `deleteTempFile` 未 await + fire-and-forget | 半成品 (代码 bug) | S (30min) | 修 |
| P3-4 | 6 个 v1.0+ 真接大工程 | SMS / Email / IAP / 紧急联系人 SMS / 16KB 完整验 / pod install 核 | 半成品 (外部依赖) | XL | 已集中 docs/, 加 SPRINT2_TODO.md 索引 |
| **R74-N7** | `safety_alert_builder.dart:98` 硬编码 title | i18n 漏 | 半成品 (i18n) | S (1h) | 加 ARB key |
| R74-N8 | `safety_alert_builder.dart:108` `'从未打卡'` 硬编码 | i18n 漏 | 半成品 (i18n) | S (1h) | 加 ARB key |
| R74-N13 | `home_page.dart:557-560` `'00000000000'` 占位 | 半成品 (hardcoded) | P1 | R55 真接 SMS 后 |
| R74-N14 | `home_page.dart:567-574` `'placeholder@invalid.local'` 占位 | 半成品 (hardcoded) | P1 | R55 真接 Email 后 |
| R74-N11 | `_kLegalVersion = 'v0.21-2026-07-20'` 写死 | 半成品 (PIPL §17) | P0 | S (1h) | 从 pubspec / asset 读 version |
| R74-N12 | `ConsentArtifact.version = 'v1'` 写死 | 半成品 (PIPL §17) | P1 | S (1h) | 同步 _kLegalVersion |
| R74-N15 | `care_engine.dart:10` 注释 "你真棒！" 过期 | 半成品 (注释) | P3 | XS (5min) | 改 "今周已全部准时" |

---

## 6. 修复优先级排序 (P0 → P3, 含架构/底层 + 难度 + 估时)

### 🚨 P0 阻塞 (上架前必做, 跨 4 视角综合) — **总 27 项**

#### 上架阻塞 (15 项 — AppStore + GooglePlay 必拒)

| 优先级 | ID | 标题 | 类型 | 难度 | 估时 | 谁做 |
|------|----|------|------|------|------|------|
| P0-1 | AS-P0-1 | PRODUCT_BUNDLE_IDENTIFIER vs Appfile 不一致 | **底层** | XS | 5min | 我 (1 行) |
| P0-2 | AS-P0-2 | fastlane/Appfile 3 TODO ID 占位 | **底层** | XS | 5min | 你 (填真值) |
| P0-3 | AS-P0-3 | iOS UNUserNotificationCenter foreground 通知未实现 | **底层** | XS | 30min | 我 (加 method) |
| P0-4 | AS-P0-4 | pbxproj knownRegions 缺 zh-Hans/zh-Hant | **底层** | XS | 5min | 我 (改 1 行) |
| P0-5 | AS-P0-5 | iOS 缺 Podfile + Podfile.lock | **底层** | S | 1h | 我 (跑 pub get + commit) |
| P0-6 | AS-P0-6 / GP-P0-4 | 41 张截图全 67 字节占位 (iOS 33 + Android 8) | **底层** | XL | 1-2 天 | 你 (真机) |
| P0-7 | AS-P0-7 | 3 张 iOS app_icon 67 字节占位 | **底层** | L | 半天 | 你 (设计师) |
| P0-8 | AS-P0-8 | 6 URL 文件域名 `chroniccare.app` 未注册 | **底层** | L | 1-2 天 | 你 (DNS + 部署) |
| P0-9 | AS-P0-9 / GP-P0-3 | `support@chroniccare.app` 邮箱占位 | **底层** | S | 半天 | 你 (注册邮箱) |
| P0-10 | AS-P0-10 | 3 份法律 md 缺英文 / 繁体版 | **底层** | L | 1-2 周 | 你 (翻译) |
| P0-11 | AS-P0-11 | privacy_policy.md 引用不存在文件 | **底层** | XS | 10min | 我 (创建占位) |
| P0-12 | GP-P0-1 | Android 仍 `signingConfig=debug` + 无 keystore | **底层** | S | 1h | 我 (跑脚本) + 你 (密码) |
| P0-13 | GP-P0-2 | Privacy Policy URL 未托管 HTTPS | **底层** | L | 1-2 天 | 你 (HTTPS 部署) |
| P0-14 | GP-P0-5 | 2 张 Android feature_graphic 67 字节占位 | **底层** | L | 半天 | 你 (设计师) |
| P0-15 | GP-P0-6 | 2 张 Android icon 192×192 (需 512×512) | **底层** | L | 半天 | 你 (重做) |
| P0-16 | GP-P0-7 | SMS Provider 仍 throw + Privacy Policy §3 共享段 | **底层** | XL | 1-2 月 | 你 (法务 + 阿里云) |

#### 病耻感 / PIPL / 临床 阻塞 (5 项 — superpowers-zh)

| 优先级 | ID | 标题 | 类型 | 难度 | 估时 | 谁做 |
|------|----|------|------|------|------|------|
| P0-17 | R74-N1 | `homeStreakRestart` "加油" → 中性 | **底层** | XS | 5min | 我 |
| P0-18 | R74-N2 | `homeStreakGreat` "真棒" → 中性 | **底层** | XS | 5min | 我 |
| P0-19 | R74-N6 | `notifDailyCheckInBody` "今" 错字 | **底层** | XS | 5min | 我 |
| P0-20 | R74-N7 | `safety_alert_builder.dart:98` 硬编码 title 加 ARB | **架构 + 底层** | S | 1h | 我 |
| P0-21 | R74-N9 | `lost_contact_sms.dart:73` medication name 暴露 | **底层** | M | 2-3h | 我 |
| P0-22 | R74-N11 | `_kLegalVersion` 写死 v0.21 → 从 pubspec 读 | **架构** | S | 1h | 我 |

#### R74 紧急修复 (1 项 — 已 commit)

| 优先级 | ID | 标题 | 状态 |
|------|----|------|------|
| P0-23 | R74-P0-1 | R65 vent i18n 漏 3 ARB key | ✅ **6e9f07e commit 修** |

### ⚠️ P1 质量改进 (跨 4 视角, 估时 1-3h 总 12 项)

| 优先级 | ID | 标题 | 类型 | 难度 | 估时 | 谁做 |
|------|----|------|------|------|------|------|
| P1-1 | spen P1-1 | domain 3 文件 import Flutter 软违规 | **架构** | M | 1-2h | 我 |
| P1-2 | spen P1-2 | `care_engine.dart:149-153` swallowError 误导 log | **底层** | S | 30min | 我 |
| P1-3 | R74-N3 | `homeStreakAmazing` "太厉害" → 中性 | **底层** | XS | 5min | 我 |
| P1-4 | R74-N4 | `homeStreakMaster` "您已经是…主人" → 中性 | **底层** | XS | 5min | 我 |
| P1-5 | R74-N5 | `homeCelebrationStreakMaster` "您太厉害了" → 中性 | **底层** | XS | 5min | 我 |
| P1-6 | R74-N8 | `safety_alert_builder.dart:108` "从未打卡" 走 l10n | **底层** | S | 30min | 我 |
| P1-7 | R74-N10 | `assessmentSeverityNormal` "正常" → "几乎没有" | **底层** | XS | 5min | 我 |
| P1-8 | R74-N12 | `ConsentArtifact.version` 写死 'v1' → 同步 _kLegalVersion | **架构** | S | 1h | 我 |
| P1-9 | R74-N13 | `home_page.dart:557-560` `'00000000000'` 占位 | **底层** | S | 1h | 我 (加 config 路由) |
| P1-10 | R74-N14 | `home_page.dart:567-574` `'placeholder@invalid.local'` 占位 | **底层** | S | 1h | 我 (加 config 路由) |
| P1-11 | emil | 5 处 ElevatedButton → PrimaryButton 集中器 | **重构** | S | 1h | 我 |
| P1-12 | emil | 5 处 ListTile → AppListTile 集中器 | **重构** | S | 1h | 我 |

### 📋 P2 架构 / 重构 / 半成品 (估时 半天-1 天, 总 8 项)

| 优先级 | ID | 标题 | 类型 | 难度 | 估时 | 谁做 |
|------|----|------|------|------|------|------|
| P2-1 | spen P2-1 | `vent_compose_page.dart:77` `deleteTempFile` 未 await | **半成品 (底层)** | S | 30min | 我 |
| P2-2 | spen P2-2 | `mood_dialog.dart` 1204 行 god class 拆 3 widget + orchestrator | **重构 (架构)** | L | 半天-1 天 | 我 |
| P2-3 | spen P2-3 | `export_orchestrator.dart` 540 行拆 export/import 2 文件 | **重构 (架构)** | M | 3h+ | 我 |
| P2-4 | spen P2-4 | `notification_service` facade 集成测 18 case | **测试 (底层)** | M | 1-2h | 我 |
| P2-5 | emil R74-REF-5 | `trend_calendar.dart` 11 处 TextStyle 走 token | **重构 (底层)** | S | 1h | 我 |
| P2-6 | emil R74-REF-2 | `home_page.dart` 抽 3 controller (DeepLink/CareEngine/Celebration) | **重构 (架构)** | L | 1-2h | 我 |
| P2-7 | emil R74-REF-3 | `export_orchestrator.dart` exportToJson 单方法 200+ 行抽 helper | **重构 (底层)** | M | 2h | 我 |
| P2-8 | spen P2-4 | `notification_service` init 顺序 + 6 类 ID 范围 + showSafetyAlert 3 态分流集成测 | **测试 (底层)** | M | 1-2h | 我 |

### 💡 P3 优化 / NIT (估时 1-2 天, 总 14 项)

| 优先级 | ID | 标题 | 类型 | 难度 | 估时 | 谁做 |
|------|----|------|------|------|------|------|
| P3-1 | spen P3-1 | `home_page.dart` 631 行 god class 抽 3 controller | **重构 (架构)** | L | 1-2h | 我 |
| P3-2 | spen P3-2 | `setup_page.dart` 4 step wizard 拆 4 widget | **重构 (架构)** | M | 1-2h | 我 |
| P3-3 | spen P3-3 | press feedback 3 文件组统一 `PressFeedback` | **重构 (架构)** | S | 半天 | 我 |
| P3-4 | spen P3-4 | 加 `docs/SPRINT2_TODO.md` 集中索引 6 个 v1.0+ TODO | **半成品 (架构)** | XS | 1h | 我 |
| P3-5 | spen P3-5 | vent_entry_entity + scale_translations i18n 测 11 case | **测试 (底层)** | S | 1-2h | 我 |
| P3-6 | spen P3-6 | home_page + setup_page 集成测 18 case | **测试 (底层)** | M | 2-3h | 我 |
| P3-7 | R74-N15 | `care_engine.dart:10` 注释 "你真棒" 过期 | **底层** | XS | 5min | 我 |
| P3-8 | flutter-spec 5.6 | `mood_audio_section.dart` 553 行 (audio+STT 状态机) | **重构 (评估后保留)** | XL | — | 评估后不拆 |
| P3-9 | flutter-spec 5.6 | `notification_service.dart` 419 行 facade | **重构 (评估后保留)** | L | — | 评估后不拆 |
| P3-10 | flutter-spec 14 | 8 个 facade 集中器集中度 100% 保持 | **重构 (架构)** | L | — | 持续 |
| P3-11 | flutter-spec 9.3 | SMS / Email 抽象接口 R55 真接 | **半成品 (外部)** | XL | 1-2 月 | 你 |
| P3-12 | flutter-spec 9.4 | release guard 阻断未配置 provider | **底层 (已修)** | — | ✅ | 持续 |
| P3-13 | flutter-spec 12 | `AppSnackBar.showError` 集中器全 100% 保持 | **重构 (架构)** | L | — | 持续 |
| P3-14 | flutter-spec 14 | `LastErrorCapture` release 模式友好 | **架构 (已修)** | — | ✅ | 持续 |

---

## 7. 上架就绪路线图 (按周排)

### Week 1 (代码侧 0 阻塞 + 域名邮箱)
- 我做: P0-1/3/4/5/11/12/17/18/19/20/21/22 + P1-1/2/3/4/5/6/7/8/9/10/11/12 + P2-1/2/3/4/5/6/7 + P3-1/2/3/4/5/6/7 (总 33 项, 估时 2-3 天)
- 你做: P0-2 (Appfile 4 ID 替换) + P0-9 (注册 support@chroniccare.app 邮箱)
- 完成: 代码侧 0 P0 阻塞, 上架"代码就绪"

### Week 2 (资源 + 域名部署)
- 你做: P0-8 (注册 chroniccare.app 域名) + P0-13 (HTTPS 部署 3 md) + P0-12 (跑 generate_release_keystore.ps1) + P0-9 邮箱验证
- 完成: 上架"资源就绪"

### Week 3-4 (设计 + 截图 + 法律)
- 你做: P0-6 (33+8 张真机截图) + P0-7/14/15 (icon + feature_graphic) + P0-10 (3 md 英文/繁体翻译 + 律师 review)
- 完成: 上架"内容就绪"

### Month 2-3 (真接服务)
- 你做: P0-16 (法务 + 阿里云 SMS AccessKey) + P0-12 (Play Console 4 表单 + App Store Connect 表单) + P3-11 (Email SendGrid + IAP App Store Connect productId)
- 完成: 上架"全功能就绪" → 提交审核

---

## 8. R74 综合判断

| 维度 | 评分 | 结论 |
|------|------|------|
| **架构** | 9.5 / 10 | 4 层 100% 纯, 18 集中器, 6 facade, 0 跨层渗透 |
| **代码** | 9.2 / 10 | 0 analyzer issue, 5 类已知 bug 模式全清, 1285 test |
| **设计** | 4.5 / 5 ⭐⭐⭐⭐½ | emil 集中器 100% 覆盖主要 widget |
| **规范** | 9.1 / 10 | v3.1 14 章 + 6 附录 0 阻断 |
| **上架** | 2-4 / 10 | 12 + 8 P0 全是外部依赖 (截图/域名/法律) |
| **中文** | 4.5 / 5 ⭐⭐⭐⭐½ | 5 病耻感 + 1 错字 + 1 i18n 漏 仍挂 |
| **临床 / PIPL** | 4.5 / 5 ⭐⭐⭐⭐½ | 1 PII 暴露 + 2 同意版本失效 仍挂 |

**R75 建议**: 1 个 round 把 P0 (代码侧 9 项) + P1 (12 项) 全清, 0 估时 1-2 天
**R76 建议**: P2 8 项 (估时 半天-1 天)
**R77+ 建议**: P3 14 项 + 持续清理

---

## 9. 6 视角报告路径

| 视角 | 文件 | 大小 | 评分 |
|------|------|------|------|
| emilkowalski | `reports/audit/round74-emilkowalski.md` | 41KB | 4.5/5 |
| superpowers-en | `reports/audit/round74-superpowers-en.md` | 41KB | 9.2/10 |
| superpowers-zh | `reports/audit/round74-superpowers-zh.md` | 40KB | 4.5/5 |
| AppStore | `reports/audit/round74-appstore.md` | 50KB | 2/10 |
| GooglePlay | `reports/audit/round74-googleplay.md` | 67KB | 4.0/10 |
| flutter-specification | `reports/audit/round74-flutter-specification.md` | 44KB | 9.1/10 |
| **本总览** | `reports/audit/round74-CONSOLIDATED.md` | — | — |
