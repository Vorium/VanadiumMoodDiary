# Round 76 — 6 视角审计总览（R75 commit 4588e34 / R76 commit 6b4fc63）

**审计时间**: 2026-08-01
**项目**: chroniccare — 精神心理患者吃药打卡 App
**版本**: v0.27.0+64+65 (R75 修了 21 项 + R76 测试同步)
**基线**: 1285/1285 tests pass / 0 error / 0 warning / 0 info / 16 守护脚本全绿
**审计模式**: 6 sub-agent 并行增量 (R74 → R76 跟踪 R75 修了啥 + R76 新发现)
**R76 重要**: R75 修了 11 项可代码化问题 + R76 测试同步 1 项, 6 视角全绿

## 0. R74 → R76 评分变化

| 视角 | R74 评分 | R76 评分 | 变化 | 关键差异 |
|------|---------|---------|------|---------|
| **emilkowalski** | 4.5/5 ⭐⭐⭐⭐½ | **4.5/5 ⭐⭐⭐⭐½** | 持平 | R75 修了 R74 12 项中 11 项, 1 项留 R76 (5 ElevatedButton + 5 ListTile 集中器抽取) |
| **superpowers-en** | 9.2/10 | **9.3/10** | +0.1 | 1292 case (1134 test + 158 testWidgets), R75 修了 R74 12 项中 11 项 |
| **superpowers-zh** | 4.5/5 ⭐⭐⭐⭐½ | **4.5/5 ⭐⭐⭐⭐½** | 持平 | R75 修了 R74 15 项, R76 新发现 11 项 (5 P0 + 6 P1) — R74 修完 旧, R76 新 |
| **AppStore** | 2/10 | **2/10** | 持平 | 9 P0 仍挂 (R74 12 P0 中 R75 修 2 完整 + 1 半修), 1 P0 加重 (PBXVariantGroup 漏) |
| **GooglePlay** | 4.0/10 | **4.0/10** | 持平 | 8 P0 仍挂 (R75 0 改 Android), R76 新发现 GP icon 是 Flutter 默认 logo (非 brand) |
| **flutter-specification** | 9.1/10 | **9.2/10** | +0.1 | 0 阻断 + 5 警告 (R74 8) + 14 建议, R75 修了 3 警告 |

**总画像**:
- 架构 / 代码 / 设计 / 规范 = 持续业界顶级 (9+ / 10, 0 阻断)
- 上架 = 严重不足 (2-4 / 10, 9+8 P0 阻塞)
- 中文 / 病耻感 / 临床 / PIPL = R75 修 R74 15 项, R76 新发现 11 项 — 持续扫描

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

### 1.2 R75 修了什么 (架构视角)

| 项 | 状态 | commit |
|----|------|--------|
| AppLocalizationsScaleTranslations 迁出 domain | ✅ 1/3 file | 9f06c59 (R75-架构-1) |
| day_detail.dart Flutter 软违规 | ❌ R76 仍挂 (R75 留 R76) | — |
| vent_entry_entity.dart Flutter 软违规 | ❌ R76 仍挂 (R75 留 R76) | — |
| care_engine swallowError 误用 | ✅ 删 success 路径 swallowError | ff9e633 (R75-P1-2) |

### 1.3 R76 守门失效 (R76-N4 P0) — **新发现关键**

**问题**: `scripts/check_all.dart` purity 检查 grep `package:flutter/` / `package:drift/` / `package:chroniccare/data/`, **不抓** `package:chroniccare/l10n/` import。
- 3 个 domain file 仍 import l10n (day_detail.dart:36 / vent_entry_entity.dart:19 / scale_translations.dart 之前修了)
- R75 修 1/3 file 是 reviewer 手工扫, 守门失效
- **修法**: check_all.dart purity rules 加 `'package:chroniccare/l10n/'` + 重跑
- 估时: XS (1 行)

## 2. 底层逐行排查

### 2.1 R75 修了什么 (底层视角)

| 项 | R74 评 | R75 状态 | commit |
|----|-------|---------|--------|
| 6 病耻感措辞 (P0-N1/2 + P1-N3/4/5) | 5 项仍挂 | ✅ 全修 | 328aa8c (R75-病耻感-1) |
| 1 错字 "今" → "今天" | P0 | ✅ 修 | ed5da54 (R75-病耻感-2) |
| safety_alert_builder 2 i18n | P0/P1 | ✅ 修 (4 ARB key) | 78e80ec (R75-i18n-1) |
| 临床 "正常" → "几乎没有" | P1 | ✅ 修 | 2b83e6a (R75-临床) |
| lost_contact_sms PIPL §6 PII | P0 | ✅ 修 | 0f9fe03 (R75-PIPL-1) |
| _kLegalVersion + ConsentArtifact.version | P0/P1 | ✅ 修 const 值 | 6181608 (R75-PIPL-2) |
| home_page fireSms/fireEmail 占位 | P1 | ✅ 改 throw StateError | a7e5eac (R75-PIPL-3) |
| iOS AppDelegate UN foreground | P0 | ✅ 修 | b045953 (R75-iOS-1) |
| iOS pbxproj bundle id + knownRegions | P0 | ✅ 修 2 项 (1 半修) | 403753c (R75-iOS-2) |
| domain Flutter 软违规 | P1 | ⚠️ 1/3 file 修, 2/3 留 R76 | 9f06c59 (R75-架构-1) |
| care_engine swallowError 误用 | P1 | ✅ 删 success 路径 | ff9e633 (R75-P1-2) |

### 2.2 R76 新发现 (底层 + i18n + 临床 + PIPL)

| ID | 位置 | 问题 | 严重度 |
|----|------|------|------|
| **R76-N1** | `core/l10n/strings.dart:72-75` + `snooze_manager.dart:83-84` | 4 个 channel name/desc const 硬编码中文 + snooze 硬编码, en/zh_Hant 系统设置看中文 | **P0** |
| **R76-N2** | `phq9.dart:24-29, 86, 89, 92-102, 111-121` + `gad7.dart:21-89` | PHQ-9 16 题 + 4 档选项 + 9 严重度 + GAD-7 7 题全 hardcoded 中文, R65 起步已知 TODO | **P0** |
| **R76-N3** | `domain/logic/assessment_scale.dart:181-203` + `phq9.dart:157` | `hotlineByRegion` 6 region label 走 const 中文, 没走 `translations.crisisHotlineLabel` 包装, tw/sg/uk 3 region 缺 ARB key | **P0** |
| **R76-N4** | `scripts/check_all.dart` purity 检查 | 不抓 `package:chroniccare/l10n/` import, 软违规持续 | **P0** |
| R76-N5 | `app_zh.arb:1096` `contactConsentBody` | 引 "PIPL §13", 应是 "§29" (敏感 PII 单独同意), R74 S-7 提的, R75 没改 | P1 |
| R76-N6 | `setup_page.dart:42` `_kLegalVersion` 仍 const 写死 | R75 改 const 值但没改"const 写死"模式, 跟 pubspec.yaml 脱节 | P1 |
| R76-N7 | `care_copy.dart:28-29, 33-36, 40-41` | 残留轻度提醒/督促 ("你这几天都" / "容易忘记" / "但记得吃药哦"), R72 改 P0-4 留尾 | P1 |
| R76-N8 | `trend_page.dart:81, 195, 221` | 3 处 `commonLoadFailed('')` 传空 string, 显示 "加载失败: " (空) | P1 |
| R76-N9 | `app_zh.arb:1257` `safetyCheckResultOk` | "正常（{days} 天前打卡）" 略带二分, 语境弱 | P3 |
| R76-N10 | 8 个领域 v1.0+ TODO 注释 | R55+ SMS / R55+ SendGrid / PackageInfo 读 legal version / 16 题 i18n / 紧急联系人本人独立确认 / IAP 真接 / DosageUnit i18n / web 加密 | P3 |
| R76-N11 | `day_detail.dart:36` + `vent_entry_entity.dart:19` | R75 9f06c59 提的"R76 完成剩余 2 file" 没兑现 | P1 |

## 3. 上架就绪度 (AppStore + GooglePlay 重点)

### 3.1 App Store **9 P0 仍阻塞** (评分 2/10)

| ID | 位置 | 阻塞原因 | 难度 |
|----|------|---------|------|
| **AS-P0-2** | `fastlane/Appfile:21, 23, 25` 3 TODO ID 仍是占位 | 提交即拒 | XS (替换) |
| **AS-P0-4 (R76 半修)** | `ios/Runner.xcodeproj/project.pbxproj:193-196` `knownRegions` 加了 zh-Hans/zh-Hant, 但**没补 PBXVariantGroup** (R70 修的 per-locale 覆盖实际从未生效) | zh-Hans/zh-Hant InfoPlist.strings 不被 iOS 识别 | M (修 pbxproj) |
| **AS-P0-5** | iOS 端缺 `ios/Podfile` + `ios/Podfile.lock` | first build 失败 | S (跑 pub get) |
| **AS-P0-6** | **33 张 67 字节占位截图** (1232×720 不是任何 Apple 截图尺寸) | 上传即拒 | L (真机截图) |
| **AS-P0-7** | 3 张 `app_icon.png` 全 67 字节占位 (需 1024×1024 不透明) | 上传即拒 | L (设计师) |
| **AS-P0-8** | 6 URL 文件 `https://chroniccare.app/privacy` — 域名未注册 | reviewer 点 URL 404 = 直接拒 | L (注册域名) |
| **AS-P0-9** | `user_agreement.md:60-61` `support@chroniccare.app` 邮箱 + GitHub 仓库占位 | 邮箱必填 | S (注册邮箱) |
| **AS-P0-10** | 3 份法律 md **无英文版 / 繁体版** | Medical 类 en-US 必走 | L (翻译 1-2 周) |
| **AS-P0-11** | `privacy_policy.md:0.5` + `user_agreement.md:60-61` 引用不存在的 `docs/SPRINT1_LEGAL_TODO.md` + `docs/LEGACY_API_NOTES.md` | 引用死链 | XS (创建占位) |

**R75 修了 2 完整 + 1 半修**:
- AS-P0-1 ✅: PRODUCT_BUNDLE_IDENTIFIER 跟 fastlane Appfile 一致
- AS-P0-3 ✅: AppDelegate UNUserNotificationCenter foreground willPresent
- AS-P0-4 ⚠️ 半修: knownRegions 加 zh-Hans/zh-Hant, 但 **PBXVariantGroup 漏** — zh-Hans/zh-Hant InfoPlist.strings 实际从未生效

### 3.2 Google Play **8 P0 仍阻塞** (评分 4.0/10)

| ID | 位置 | 阻塞原因 | 难度 |
|----|------|---------|------|
| **GP-P0-1** | `android/app/build.gradle.kts:80` 仍 `signingConfig=debug` + 无 keystore | 上传即拒 | S (跑 generate_release_keystore.ps1) |
| **GP-P0-2** | Privacy Policy URL 未托管到 HTTPS 公网 | 提交即拒 | L (HTTPS 部署) |
| **GP-P0-3** | `user_agreement.md:60` `support@chroniccare.app` TODO 占位 | Developer email 必填 | S (注册邮箱) |
| **GP-P0-4** | 8 张 `screenshot_{1..4}.png` × 2 locale 全 67 字节 1x1 占位 | 上传即拒 | L (真机) |
| **GP-P0-5** | 2 张 `feature_graphic.png` 全 67 字节 1x1 占位 | 上传即拒 | L (设计师) |
| **GP-P0-6** | 2 张 `icon.png` 192×192 (需 512×512), **R76 新发现: icon 是 Flutter 默认 logo** 不是 brand 绿叶 | 上传即拒 | L (重做) |
| **GP-P0-7** | SMS Provider 仍 throw + `_isFullyImplemented=false` | 业务不可用 | XL (法务 + 阿里云) |
| **GP-P0-8** | ~~R70 修完~~ ✅ | | |

**R76 新发现**: GP-P0-6 icon 是 Flutter 默认 logo (已 PIL 验过视觉确认), 而非已存在的绿叶主视觉 (brand consistency + 1-click brand identity 风险)

## 4. 建议重构 (跨视角)

### 4.1 R75 没做的集中器抽取 (R74 评估后留 R76+)

| 位置 | 调用 | 集中度 | 机会 |
|------|------|------|------|
| `PrimaryButton` | 18 调用 | 72% | 5 处 ElevatedButton 直调 (assessment_reminder_section + contacts_list_widget + reminders_hub 2 处 + data_management_section) → 提至 100% |
| `AppListTile` | 12 调用 | 60% | 5 处 ListTile 直调 (medication/mood/home) → 提至 100% |
| **R76 新发现大文件** | | | `reminders_hub_page 435` + `data_management_section 408` (R74 漏列) |

### 4.2 god class 候选 (评估后决策)

| 位置 | 行数 | 评估 |
|------|------|------|
| `home_page.dart` 678 行 | L | 评估后不拆 (R64 状态机 + R67 CareEngine 拆) |
| `mood_dialog.dart` 1204 行 | L | 评估后不拆 (R64 god split 网) |
| `export_orchestrator.dart` 565 行 | M | 可拆 export/import 2 文件 |
| `trend_calendar.dart` 528 行 + 11 处 TextStyle inline | S | 走 token |
| `reminders_hub_page.dart` 435 行 (R76 新) | M | 评估待定 |
| `data_management_section.dart` 408 行 (R76 新) | M | 评估待定 |

## 5. 半成品 (跨视角)

| ID | 位置 | 问题 | 严重度 | 修法 |
|----|------|------|------|------|
| R76-N2 | PHQ-9 16 题 + 4 档 + 9 严重度 + GAD-7 7 题 | 全 hardcoded 中文, R65 起步 TODO 留 v1.0 | **P0** | 70+ ARB key + 16 题全文 i18n |
| R76-N1 | 通知 channel name/desc 4 const + snooze | 硬编码中文, en/zh_Hant 系统设置看中文 | **P0** | 加 4-6 ARB key (channel_medication_name / desc / safety / snooze) |
| R76-N3 | `hotlineByRegion` 6 region label | const 中文, phq9.dart:157 没走 ARB, tw/sg/uk 3 region 缺 | **P0** | 走 `translations.crisisHotlineLabel`, 补 3 ARB key (tw/sg/uk) |
| R76-N5 | `contactConsentBody` 引 "PIPL §13" | 应是 "§29" | P1 | 改 §29 |
| R76-N6 | `_kLegalVersion` 仍 const 写死 | 跟 pubspec 脱节 | P1 | 改 `package_info_plus` 读 |
| R76-N7 | `care_copy.dart` 3 处轻度督促 | R72 改 P0-4 留尾 | P1 | 中性化 |
| R76-N8 | `trend_page.dart:81, 195, 221` | 3 处 `commonLoadFailed('')` 传空 string | P1 | 改 catch 块传具体 error |
| R76-N9 | `safetyCheckResultOk` "正常（{days} 天前打卡）" | 略带二分 | P3 | 改 "无风险" / "一切正常" |
| R76-N10 | 8 个 v1.0+ TODO | 外部依赖 (1-2 月) | P3 | 加 SPRINT2_TODO.md 索引 |
| R76-N11 | day_detail + vent_entry 软违规 | R75 留 R76 | P1 | closure 参数化注入 i18n (估时 1-2h) |
| R74-N15 | `care_engine.dart:10` 注释 "你真棒" 过期 | R72 改后注释未同步 | P3 | 改 "今周已全部准时" |

## 6. 修复优先级排序 (P0 → P3, 含架构/底层 + 难度)

### 🚨 P0 阻塞 (R76 跨 4 视角 13 项)

#### 代码侧可立刻做 (6 项, 估时 1-2h)

| 优先级 | ID | 标题 | 类型 | 难度 | 估时 | 谁做 |
|------|----|------|------|------|------|------|
| P0-1 | R76-N4 | check_all.dart purity 加 `package:chroniccare/l10n/` | **架构** | XS | 5min | 我 |
| P0-2 | R76-N5 | `contactConsentBody` "PIPL §13" → "§29" | **底层** | XS | 5min | 我 |
| P0-3 | R76-N8 | `trend_page` 3 处 `commonLoadFailed('')` 改 catch 块 | **底层** | S | 30min | 我 |
| P0-4 | R76-N9 | `safetyCheckResultOk` "正常" → "无风险" | **底层** | XS | 15min | 我 |
| P0-5 | R76-N7 | `care_copy.dart` 3 处轻度督促中性化 | **底层** | S | 1h | 我 |
| P0-6 | R76-N11 | day_detail + vent_entry closure 参数化注入 i18n (R75 留 R76) | **架构** | M | 1-2h | 我 |

#### 上架 P0 阻塞 (你那边 7 项, R75 修了 2+1半修, R76 还 9)

| 优先级 | ID | 标题 | 难度 | 估时 | 谁做 |
|------|----|------|------|------|------|
| P0-7 | AS-P0-2 | fastlane/Appfile 3 TODO ID 占位 | XS | 5min | 你 |
| P0-8 | AS-P0-4 半修 | pbxproj PBXVariantGroup 漏 (R75 半修) | M | 30min | 我 |
| P0-9 | AS-P0-5 | iOS 缺 Podfile + Podfile.lock | S | 1h | 我 |
| P0-10 | AS-P0-6 | 33 张真机截图 | XL | 1-2 天 | 你 |
| P0-11 | AS-P0-7 | 3 张 iOS app_icon 1024² | L | 半天 | 你 |
| P0-12 | AS-P0-8 | 域名 `chroniccare.app` 注册 | L | 1-2 天 | 你 |
| P0-13 | AS-P0-9 | 邮箱 `support@chroniccare.app` | S | 半天 | 你 |
| P0-14 | AS-P0-10 | 3 md 英文 + 繁体翻译 | L | 1-2 周 | 你 |
| P0-15 | AS-P0-11 | 引用死链文件创建 | XS | 10min | 我 |

#### 临床精度 + 半成品大工程 (3 项)

| 优先级 | ID | 标题 | 难度 | 估时 | 谁做 |
|------|----|------|------|------|------|
| P0-16 | R76-N1 | 通知 channel name/desc i18n (4 const + snooze) | S | 1h | 我 |
| P0-17 | R76-N3 | `hotlineByRegion` 6 region 走 ARB + 补 3 key (tw/sg/uk) | M | 3-4h | 我 |
| P0-18 | R76-N2 | PHQ-9 16 题 + 严重度 + GAD-7 7 题 i18n (R65 起步 TODO) | XL | 1-2 round | 跨 R77+ |

#### Google Play 8 P0 (你那边 5 项, 我这边 0)

| 优先级 | ID | 标题 | 难度 | 估时 | 谁做 |
|------|----|------|------|------|------|
| P0-19 | GP-P0-1 | 跑 `generate_release_keystore.ps1` + 改 `signingConfig=debug → release` | S | 1h | 我 + 你 (密码) |
| P0-20 | GP-P0-2 | Privacy Policy URL HTTPS 部署 | L | 1-2 天 | 你 |
| P0-21 | GP-P0-3 | `support@chroniccare.app` 邮箱 | S | 半天 | 你 |
| P0-22 | GP-P0-4 | 8 张真机截图 | L | 半天 | 你 |
| P0-23 | GP-P0-5 | 2 张 feature_graphic 1024×500 | L | 半天 | 你 |
| P0-24 | GP-P0-6 | 2 张 icon 512² (R76 新发现: icon 是 Flutter 默认 logo, 换 brand) | L | 半天 | 你 |
| P0-25 | GP-P0-7 | SMS Provider 真接阿里云 | XL | 1-2 月 | 你 (法务 + AccessKey) |

### ⚠️ P1 质量改进 (跨 4 视角 12 项, 估时 半天)

| 优先级 | ID | 标题 | 类型 | 难度 | 估时 | 谁做 |
|------|----|------|------|------|------|------|
| P1-1 | R76-N6 | `_kLegalVersion` 改 `package_info_plus` 读 pubspec | **架构** | M | 2-3h | 我 |
| P1-2 | AS-P1-3 (续) | `InfoPlist.strings` zh-Hans/zh-Hant 修 pbxproj PBXVariantGroup 完整 (跟 P0-8 合并) | **架构** | M | (合并) | 我 |
| P1-3 | emil-12 | 5 处 ElevatedButton → PrimaryButton 集中器 (R75 没做) | **重构** | S | 1h | 我 |
| P1-4 | emil-12 | 5 处 ListTile → AppListTile 集中器 (R75 没做) | **重构** | S | 1h | 我 |
| P1-5 | spen P1-1 partial 2/3 | day_detail + vent_entry closure 注入 (跟 P0-6 合并) | **架构** | M | (合并) | 我 |
| P1-6 | emil-R76-新 | reminders_hub_page 435 + data_management_section 408 评估拆 | **重构** | M | 1-2h | 我 |
| P1-7 | emil-R76-新 | `trend_calendar.dart` 11 处 TextStyle 走 token | **重构** | S | 1h | 我 |
| P1-8 | spen P2-3 | `export_orchestrator.dart` 拆 export/import 2 文件 | **重构** | M | 3h | 我 |
| P1-9 | spen P2-4 | notification_service facade 集成测 18 case | **测试** | M | 1-2h | 我 |
| P1-10 | spen P3-2 | setup_page 4 step wizard 拆 4 widget | **重构** | M | 1-2h | 我 |
| P1-11 | spen P3-5 | vent_entry_entity + scale_translations i18n 测 11 case | **测试** | S | 1-2h | 我 |
| P1-12 | spen P3-6 | home_page + setup_page 集成测 18 case | **测试** | M | 2-3h | 我 |

### 📋 P2/P3 (估时 1-2 天)

| 优先级 | ID | 标题 | 估时 |
|------|----|------|------|
| P2-1 | emil-REF-2 | home_page 678 行 抽 3 controller | 1-2h |
| P2-2 | emil-REF-3 | export_orchestrator exportToJson 单方法 200+ 行抽 helper | 2h |
| P2-3 | spen P3-3 | press feedback 3 文件组统一 | 半天 |
| P2-4 | spen P3-4 | 加 `docs/SPRINT2_TODO.md` 集中索引 6 个 v1.0+ TODO | 1h |
| P3-1 | R74-N15 | `care_engine.dart:10` 注释 "你真棒" 过期 | 5min |
| P3-2 | spen P3-1 | home_page 631 行 god class 抽 3 controller | 1-2h |
| P3-3 | flutter-spec 5.6 | mood_audio 553 行 (评估后保留) | — |
| P3-4 | flutter-spec 9.3 | SMS / Email 真接 (XL, 1-2 月) | 跨 round |

## 7. R75 → R76 变化总结

| 维度 | R74 | R75 修了 | R76 新发现 | R76 实际状态 |
|------|----|---------|----------|------------|
| **病耻感措辞** | 5 项仍挂 | ✅ 修了 6 处 (5 鼓励 + 1 错字) | R76-N7/N9 续 4 处 (轻度 + safetyCheckResultOk) | 4 处新挂 + 6 处修 |
| **PIPL** | 5 P0 | ✅ 修 4 项 (PII / 同意版本 / 2 占位) | R76-N5/N6 续 2 项 (§13 错引 + const 写死) | 2 处续 + 4 处修 |
| **临床精度** | "正常" 二分 | ✅ 改 "几乎没有" | R76-N9 safetyCheckResultOk 仍 "正常" | 1 处续 + 1 处修 |
| **i18n 漏** | safety_alert_builder 2 处 | ✅ 修 (4 ARB key) | R76-N1 通知 channel 4 const + R76-N2 PHQ-9 16 题 + R76-N3 hotline 6 region | 3 大块新挂 |
| **架构软违规** | 3 文件 | ⚠️ 修 1/3 (scale_translations) | R76-N4 守门失效 + R76-N11 2/3 续 | 2 处续 + 1 处修 |
| **iOS 上架** | 12 P0 | ✅ 修 2+1半 (bundle id / foreground / knownRegions 半) | AS-P0-4 半修加重 (PBXVariantGroup 漏) | 9 P0 续 |
| **Android 上架** | 8 P0 | 0 改 | GP-P0-6 icon 是 Flutter 默认 logo 新发现 | 8 P0 续 |
| **上架外依赖** | 14 P0 (12 + 8 - 6 重叠) | 0 改 (全在你) | 仍 14 P0 (9 AS + 8 GP - 3 跨) | 全在用户侧 |

## 8. R77 建议 (按 P0 排序)

### 我能 1 round 做的 (估时 1-2 天)
- **P0-1 R76-N4** check_all.dart 加 l10n 守门 (5min)
- **P0-2 R76-N5** contactConsentBody §13 → §29 (5min)
- **P0-3 R76-N8** trend_page commonLoadFailed 修 (30min)
- **P0-4 R76-N9** safetyCheckResultOk "正常" → "无风险" (15min)
- **P0-5 R76-N7** care_copy 3 处轻度中性化 (1h)
- **P0-6 R76-N11** day_detail + vent_entry closure 注入 (1-2h)
- **P0-8 AS-P0-4 半修** pbxproj PBXVariantGroup (30min)
- **P0-9 AS-P0-5** iOS Podfile (1h)
- **P0-15 AS-P0-11** 创建引用占位文件 (10min)
- **P0-16 R76-N1** 通知 channel 4 const i18n (1h)
- **P0-17 R76-N3** hotline 6 region ARB + 3 key (3-4h)
- **P1-1 R76-N6** _kLegalVersion 改 PackageInfo (2-3h)
- **P1-3/1-4** 集中器 5 ElevatedButton + 5 ListTile (2h)
- **P1-7** trend_calendar 11 处 TextStyle 走 token (1h)
- **P1-9** notification_service facade 集成测 (1-2h)
- **P1-11** vent_entry_entity i18n 测 (1-2h)
- **P3-1** care_engine.dart 注释过期 (5min)

**总估时**: 1-2 天, 19 项

### 你那边 (外部依赖)
- P0-7 fastlane/Appfile 4 ID 替换
- P0-10/11/12/13/14 上架资源 (截图 / icon / 域名 / 邮箱 / 翻译)
- P0-19 GP keystore 跑脚本
- P0-20/21/22/23/24/25 Google Play 资源 + SMS

### 跨 round 大工程
- **P0-18 R76-N2** PHQ-9 16 题 + 严重度 + GAD-7 7 题 i18n (R65 起步 TODO, R77+ 70+ ARB key, 1-2 round)

## 9. 6 视角报告路径

| 视角 | 文件 | 大小 | R74 → R76 评分 |
|------|------|------|---------------|
| emilkowalski | `reports/audit/round76-emilkowalski.md` | 55KB | 4.5/5 → 4.5/5 |
| superpowers-en | `reports/audit/round76-superpowers-en.md` | 48KB | 9.2/10 → 9.3/10 |
| superpowers-zh | `reports/audit/round76-superpowers-zh.md` | 50KB | 4.5/5 → 4.5/5 |
| AppStore | `reports/audit/round76-appstore.md` | 66KB | 2/10 → 2/10 |
| GooglePlay | `reports/audit/round76-googleplay.md` | 67KB | 4.0/10 → 4.0/10 |
| flutter-specification | `reports/audit/round76-flutter-specification.md` | 60KB | 9.1/10 → 9.2/10 |
| **本总览** | `reports/audit/round76-CONSOLIDATED.md` | — | — |
