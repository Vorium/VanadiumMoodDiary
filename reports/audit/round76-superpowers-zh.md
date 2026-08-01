# Round 76 - superpowers-zh 视角审计

**审计时间**: 2026-08-01
**项目**: chroniccare（精神心理患者吃药打卡 App）
**版本**: 0.27.0+64 (pubspec)
**最新 commit**: `6b4fc63` (R76 assessment_history test 同步 R75 '正常' → '几乎没有')
**R75 最新 commit**: `4588e34` (R75 P1-1 partial 注释 + R74 6 视角审计报告归档)
**视角**: superpowers-zh (中文 i18n + PIPL §13/§14/§17/§26/§28/§29 + 中文工作流 + 隐私边界 + 病耻感措辞 + 临床精度)
**审计模式**: 全量 (R76 6b4fc63 commit 后, working tree 干净)
**基线**: `reports/audit/round74-superpowers-zh.md` (R74: ⭐⭐⭐⭐/5, 6 P0 / 8 P1 / 3 P2 / 10 P3 = 27 项)
**R75 增量**: 11 commit 修了 R74 全部 15 项 (5 病耻感 / 1 错字 / 2 i18n / 1 PII / 1 临床 / 2 PIPL §17 / 2 占位 / 1 过期注释) + 4 额外 (iOS-1 / iOS-2 / 架构-1 1/3 / audit)
**R76 增量**: 1 commit 同步 test (必备操作, 0 新功能)

---

## §0 评级

⭐⭐⭐⭐ / 5 (vs R74 ⭐⭐⭐⭐, 持平; vs R75 ⭐⭐⭐⭐, 持平)

**核心结论**:
- **R75 11 commit 高质量** 修了 R74 报告的 15 项问题 (100% 覆盖), 加 4 项必要额外工作
- **R76 1 commit 必备** (R75 临床精度改 ARB 后 test 必跟, 0 新功能)
- **R75 漏 1 项 + R76 没兑现 1 项**: R75 9f06c59 commit msg 提 "R76 完成剩余 2 file" (P1-1 soft 架构违规) 但 R76 实际只动了 test, day_detail.dart + vent_entry_entity.dart 仍 import l10n
- **R76 新发现 11 项** (P0 4 + P1 4 + P3 3) — 跟 R74 同量级, 没"质量滑坡", 但说明 R75 集中清完后, 仍有一些"R65 起步 + R75 没动"的老遗留 (PHQ-9 16 题全题 i18n / hotline label 包装 / 通知 channel name 中文)

**稳定守住项** (R74 → R76 持续 100% 守住):
- 4 层架构纯度 (check_all.dart 0 violation) ✓
- 跨 feature import 边界 (check_cross_feature.py 0 violation / 67 files) ✓
- ARB i18n 同步 (624 keys / zh / en / zh_Hant / 0 orphan / 0 duplicate / 100% 同步) ✓
- 树洞隐私边界 (text 字段级加密 + audio 文件隔离 + PIPL §14 撤回业务层生效) ✓
- 0 analyzer error / 0 warning / 0 info ✓
- 1285/1285 tests pass ✓
- 11 守护脚本全绿 ✓

**仍挂 (R76 新发现 + R74/R75 续挂)**:
- **R76 漏改 R75 提到的工作** (1 项): R75 9f06c59 提到 "R76 完成剩余 2 file" (day_detail.dart + vent_entry_entity.dart l10n 软违规) — R76 没兑现
- **R76-N1 (P0)**: 通知 channel name/desc 4 个 const 硬编码中文 + snooze_manager 硬编码 '吃药提醒' / '到点提醒你吃药打卡', en/zh_Hant 用户系统设置看中文
- **R76-N2 (P0)**: PHQ-9 16 题 + 4 档选项 + 9 严重度 + GAD-7 7 题全 hardcoded 中文 (R65 起步已知 TODO, R51b 计划, R76 没动)
- **R76-N3 (P0)**: `hotlineByRegion` 6 region label 走 const 中文 Map, phq9.dart:157 没走 `translations.crisisHotlineLabel` 包装, tw/sg/uk 3 region 缺 ARB key
- **R76-N4 (P0)**: `check_all.dart` purity 检查不抓 `package:chroniccare/l10n/` import, 软违规会持续 (R75 修 1/3 是 reviewer 手工扫, 守门失效)
- **R76-N5 (P1)**: `contactConsentBody` ARB 引 "PIPL §13", 应是 "§29" (敏感 PII 单独同意) — R74 S-7 提的, R75 没改
- **R76-N6 (P1)**: `_kLegalVersion` 仍 const 写死, 跟 `pubspec.yaml` version 字段脱节, 升级时需手工同步, 无 re-consent 触发逻辑 (R74 S-5 半修, R75 改 const 值但没改"const 写死"模式)
- **R76-N7 (P1)**: `care_copy.dart` L28-29/L33-36/L40-41 残留轻度提醒/督促语气 ("你这几天都" / "容易忘记" / "但记得吃药哦")
- **R76-N8 (P1)**: `trend_page.dart:81/195/221` 3 处 `commonLoadFailed('')` 传空 string, UI 显示 "加载失败: " (空)
- **R76-N9 (P3)**: `safetyCheckResultOk` "正常（{days} 天前打卡）" — 失联告警 0 失联状态用 "正常" 略带二分 (跟 R75 改 severityNormal 同款, 但语境弱)
- **R76-N10 (P3)**: 8 个领域残留的 v1.0+ TODO 注释 (R55+ SMS / R55+ SendGrid / PackageInfo 读 legal version / 16 题 i18n 化 / 紧急联系人本人独立确认 / IAP 真接 / DosageUnit i18n / web 加密), 决策保留

**R76 总问题数**: 11 (4 P0 / 4 P1 / 3 P3)

**评分持平理由**:
- R75 修了 R74 全部 15 项, 质量高, 跨领域 (病耻感/i18n/PIPL/临床/iOS) — 升 ⭐⭐⭐⭐½ (但 R75 提的"R76 完成" 没兑现, 持平 ⭐⭐⭐⭐)
- R76 1 commit 必备, 0 漏改 0 新功能 — 持平
- R76 扫到 11 项新发现 (4 P0), 跟 R74 同量级 — 持平

---

## §1 R74 → R76 增量对照

### 1.1 R74 已修 (15/15 验证生效)

| R74 ID | 位置 | R75 commit | 验证 |
|---|---|---|---|
| **R74-N1** | `app_zh.arb:635` `homeStreakRestart` | 328aa8c (病耻感-1) | "今天重新开始，加油 🌱" → "今天重新开始 🌱" ✓ |
| **R74-N2** | `app_zh.arb:645` `homeStreakGreat` | 328aa8c | "已坚持 {days} 天，真棒 🌳" → "已坚持 {days} 天 🌳" ✓ |
| **R74-N3** | `app_zh.arb:653` `homeStreakAmazing` | 328aa8c | "{days} 天连击，太厉害了 🌲" → "{days} 天连击 🌲" ✓ |
| **R74-N4** | `app_zh.arb:661` `homeStreakMaster` | 328aa8c | "{days} 天--您已经是这个习惯的主人了 🏔️" → "{days} 天 🏔️" ✓ |
| **R74-N5** | `app_zh.arb:908` `homeCelebrationStreakMaster` | 328aa8c | "已记录！{days} 天--您太厉害了 🏔️" → "已记录！{days} 天 🏔️" ✓ |
| **R74-N6** | `core/l10n/strings.dart:96` `notifDailyCheckInBody` | ed5da54 (病耻感-2) | "留个**今**的踏实" → "留个**今天**的踏实" ✓ |
| **R74-N7** | `safety_alert_builder.dart:98` title 硬编码 | 78e80ec (i18n-1) | `final title = l10n.safetyAlertTitle(name, daysWithoutCheckIn);` ✓ |
| **R74-N8** | `safety_alert_builder.dart:108` "从未打卡" 硬编码 | 78e80ec | `if (lastCheckIn == null) return l10n.safetyAlertNeverCheckIn;` ✓ |
| **R74-N9** | `domain/logic/lost_contact_sms.dart:73` medication PII 暴露 | 0f9fe03 (PIPL-1) | 删 `if (medication != null) { buffer.writeln('常吃药: ...'); }` 块, 加 "PIPL §13 单独同意扩展, R76+ 设计" 注释 ✓ |
| **R74-N10** | `app_zh.arb:782` `assessmentSeverityNormal` "正常" | 2b83e6a (临床精度) | zh "正常" → "几乎没有" / en "Normal" → "Minimal" / zh_Hant "正常" → "幾乎沒有" 3 语同步 ✓ |
| **R74-N11** | `setup_page.dart:36` `_kLegalVersion` 写死 | 6181608 (PIPL-2) | `const _kLegalVersion = 'v0.21-2026-07-20';` → `const _kLegalVersion = 'v0.27-2026-08-01';` (但仍 const 写死, 见 R76-N6) ✓ 半修 |
| **R74-N12** | `consent_dialog.dart:85` `ConsentArtifact.version` 写死 | 6181608 | `version: 'v1'` → `version: 'v0.27-2026-08-01'` ✓ |
| **R74-N13** | `home_page.dart:558` SMS 占位 phone | a7e5eac (PIPL-3) | `await ref.read(smsServiceProvider).send(to: '00000000000', ...)` → `throw StateError('FireCareDecision.fireSms requires non-empty input.contacts. ...')` ✓ |
| **R74-N14** | `home_page.dart:567` Email 占位 email | a7e5eac | `await ref.read(emailServiceProvider).sendMedicationReminder(to: 'placeholder@invalid.local', ...)` → `throw StateError('FireCareDecision.fireEmail requires non-empty input.contacts. ...')` ✓ |
| **R74-N15** | `care_engine.dart:10` 过期注释 "你真棒" | ff9e633 (P1-2) | 成功路径删 `swallowError(where: 'CareEngine.fire', error: '关怀触发: ${trigger.type.name}', note: 'success')` 误用, 加注释解释 ✓ |

**总结**: R75 修了 R74 报告 **15/15 全部**, 质量高, 跨 5 个 commit, 3 语同步 (zh/en/zh_Hant), 注释解释清晰。

### 1.2 R75 额外做 (4 项, 0 来自 R74 报告)

| R75 commit | 内容 | 评估 |
|---|---|---|
| **9f06c59 (架构-1)** | `AppLocalizationsScaleTranslations` 迁出 `lib/domain/entities/scale_translations.dart` → `lib/presentation/services/scale_translations_l10n.dart`, 修 1/3 file, commit msg 提 **"R76 完成剩余 2 file"** | 必要 (4 层架构纯度恢复, 软违规部分修) — 但 R76 没兑现 |
| **403753c (iOS-2)** | `ios/Runner.xcodeproj/project.pbxproj` 2 修复: (1) `knownRegions` 加 `zh-Hans` / `zh-Hant` (2) `PRODUCT_BUNDLE_IDENTIFIER` 跟 fastlane `Appfile` 同步 `com.chroniccare.app` → `com.chroniccare.chroniccare` | 必要 (上架审核, knownRegions 缺 zh-Hans/zh-Hant + bundle ID 不一致, 上传包会被拒) |
| **b045953 (iOS-1)** | `ios/Runner/AppDelegate.swift` conform `UNUserNotificationCenterDelegate` + 实现 `userNotificationCenter(_:willPresent:withCompletionHandler:)` 返回 `[.banner, .list, .sound, .badge]` | 必要 (iOS 10+ foreground 通知 R67 写 `self as? UNUserNotificationCenterDelegate` 强转 AppDelegate 没 conform protocol, delegate=nil, foreground 通知静默不弹, 失联告警关键场景错过) |
| **4588e34 (audit)** | R75 P1-1 partial 注释 (R74 6 视角审计报告归档) | 必要 (报告 6 个 file 归档 4029 行) |

**总结**: R75 4 项额外工作, 全必要 (架构守门 + iOS 上架 + 文档归档), 质量高, 跟 R74 报告 15 项互补。

### 1.3 R75 漏改 (2 项, R74 报告跟踪)

| R74 ID | 位置 | 状态 |
|---|---|---|
| **R74 S-7 (P1)** | `app_zh.arb:1079` `contactConsentBody` 法规引用 | ❌ R75 没改, 仍写 "**PIPL §13**" (应是 §29, 见 R76-N5) |
| **R74 S-5 (P0) 半修** | `setup_page.dart:42` `_kLegalVersion` 仍 const 写死 | ⚠️ R75 改 const 值 (v0.21 → v0.27) 但没改"const 写死"模式, 注释提 "R76+ 考虑: 改成启动时读 PackageInfo", R76 没兑现 (见 R76-N6) |

### 1.4 R76 1 commit 评估

| R76 commit | 内容 | 评估 |
|---|---|---|
| **6b4fc63** (测试同步) | `assessment_history_round13b_test.dart` 478 行改 239 行, 同步 R75 '正常' → '几乎没有' (PHQ-9 clinical minimal) | 必要 (R75 临床精度改 ARB 后, test 必跟), 0 新功能, 100% 改对 |

### 1.5 R76 新发现 (11 项)

| 编号 | 类型 | 严重度 | 位置 | 概述 |
|---|---|---|---|---|
| **R76-N1** | 通知 channel i18n 漏 | **P0** | `core/l10n/strings.dart:72-75` + `snooze_manager.dart:83-84` | 4 个 channel name/desc const 硬编码中文 + snooze 硬编码, en/zh_Hant 系统设置看中文 |
| **R76-N2** | 临床精度 + i18n 漏 | **P0** | `phq9.dart:24-29, 86, 89, 92-102, 111-121` + `gad7.dart:21-89` | PHQ-9 16 题 + 4 档选项 + 9 严重度 + GAD-7 7 题全 hardcoded 中文, R65 起步已知 TODO |
| **R76-N3** | 临床 + i18n 漏 | **P0** | `assessment_scale.dart:181-203` + `phq9.dart:157` | `hotlineByRegion` 6 region const 中文 label, 没走 `translations.crisisHotlineLabel` 包装, tw/sg/uk 3 region 缺 ARB key |
| **R76-N4** | 守门失效 | **P0** | `scripts/check_all.dart` purity 检查 | 不抓 `package:chroniccare/l10n/` import, 软违规持续, R75 修 1/3 是 reviewer 手工扫 |
| **R76-N5** | PIPL §13 法规引用 | P1 | `app_zh.arb:1096` `contactConsentBody` | 引 "PIPL §13", 应是 "§29" (敏感 PII 单独同意), R74 S-7 提的, R75 没改 |
| **R76-N6** | PIPL §17 失效 (半修) | P1 | `setup_page.dart:42` `_kLegalVersion` 仍 const 写死 | R74 S-5 半修, R75 改 const 值但没改"const 写死"模式, 跟 pubspec.yaml 脱节 |
| **R76-N7** | 病耻感续 (轻度提醒) | P1 | `care_copy.dart:28-29, 33-36, 40-41` | R72 改 P0-4 留尾, "你这几天都" / "容易忘记" / "但记得吃药哦" 轻度督促 |
| **R76-N8** | UX / i18n 漏 | P1 | `trend_page.dart:81, 195, 221` | 3 处 `commonLoadFailed('')` 传空 string, 显示 "加载失败: " (空) |
| **R76-N9** | 病耻感续 (轻度) | P3 | `app_zh.arb:1257` `safetyCheckResultOk` | "正常（{days} 天前打卡）" — 失联告警 0 失联状态用 "正常" 略带二分, 语境弱 |
| **R76-N10** | 半成品 v1.0+ TODO | P3 | 8 个领域 | R55+ SMS / R55+ SendGrid / PackageInfo 读 legal version / 16 题 i18n / 紧急联系人本人独立确认 / IAP 真接 / DosageUnit i18n / web 加密 |
| **R76-N11** | (R75 漏项) 架构软违规 | P1 | `day_detail.dart:36` + `vent_entry_entity.dart:19` | R75 9f06c59 提的"R76 完成剩余 2 file" 没兑现, 仍 import l10n |

**总结**: R76 新发现 11 项 (4 P0 / 4 P1 / 3 P3), 跟 R74 同量级。P0 集中在**老遗留** (R65 起步 / R51b 计划 / 守门失效 / i18n 系统化), 不是 R75 质量滑坡。

---

## §2 顶层架构审视

### 2.1 4 层架构

| 检查项 | 工具 | R74 状态 | R76 状态 |
|---|---|---|---|
| 4 层架构纯度 (硬) | `dart scripts/check_all.dart` | ✅ 100% | ✅ 100% (domain 0 flutter / 0 drift / 0 data / 0 presentation) |
| 跨 feature import | `python scripts/check_cross_feature.py` | ✅ 0 violation | ✅ 0 violation (67 files) |
| 架构语义一致性 | `dart scripts/check_all.dart` | ✅ | ✅ (每个 *Entity 对应 drift table; shared/ 工具被 ≥2 层用) |
| 设计 token 完整 | `app_tokens` + 4 sub | ✅ 23+ 集中器 | ✅ 持续 |
| i18n 3 层边界 | `l10n/` + `core/l10n/` + `core/shared/json_codec.dart` | ✅ | ✅ 持续 (624 keys 100% 同步) |
| **软架构违规 (l10n 间接 import)** | ❌ 守门失效 | ❌ | ❌ **R76-N4 新发现**, check_all.dart 不抓 l10n 软违规 |

**R76 评估**:
- 4 层架构硬纯度 100% 守住
- **软违规守门失效** (R76-N4): check_all.dart purity grep `package:flutter/` / `package:drift/` / `package:chroniccare/data/`, 不抓 `package:chroniccare/l10n/` → 3 个 domain file 间接 import l10n (vent_entry_entity.dart / scale_translations.dart [R75 修了] / day_detail.dart) 守门抓不到
- R75 9f06c59 修 1/3 是 reviewer (superpowers-en) 手工扫, 不是脚本
- 修复建议: check_all.dart purity 加 `package:chroniccare/l10n/` 匹配, R77 一行 commit

### 2.2 高内聚低耦合

| 模块 | 行数 (R74 → R76) | 集中器数 | 评估 |
|---|---|---|---|
| `notification_service.dart` | 18.4 KB → 18.4 KB | 5 facade (reminder_dispatcher / safety_alert_builder / snooze_manager / badge_sync / refill_notifier) | ✅ facade 模式稳定 |
| `medication_notifier.dart` | 6.1 KB → 6.1 KB | 1 (notification id 公式 / scheduleDailyReminder / reschedule) | ✅ R56c TDD 覆盖, ID 集中 |
| `care_engine.dart` | 163 行 → 163 行 | 4 strategy (care_strategies.dart) + 1 copy (care_copy.dart) | ✅ R41 拆完, R75 删成功路径 swallowError 误用 |
| `safety_alert_builder.dart` | ~140 行 → ~145 行 | 1 facade + 1 builder | ✅ R75 加 l10n 参数注入 |
| `lost_contact_sms.dart` | 78 行 → 80 行 | 1 纯函数 | ✅ R75 删 medication PII 块 |
| `consent_dialog.dart` | 88 行 → 90 行 | 1 集中器 (5 kind) | ✅ R75 sync ConsentArtifact.version = v0.27 |
| `scale_translations.dart` | 88 行 → 88 行 | 1 abstract + 1 static fallback | ✅ R75 迁 AppLocalizationsScaleTranslations 出 domain |
| `scale_translations_l10n.dart` | 0 → 52 行 (新 file) | 1 AppLocalizations 包装 | ✅ R75 新建 |
| `vent_repository_impl.dart` | 148 行 → 148 行 | 4 职责 (watch/add/delete/restore) | ✅ 隐私边界守住 |

**R76 评估**:
- 所有 service 100~200 行, 0 god class
- R75 5 个 commit 改了 4 个 service (care_engine / safety_alert_builder / lost_contact_sms / scale_translations + scale_translations_l10n), 加 1 个新 service (scale_translations_l10n)
- 0 god class 风险

### 2.3 模块边界 (跨 feature)

| 边界 | 规则 | R76 状态 |
|---|---|---|
| `presentation/pages/{feature A}/` ↛ `presentation/pages/{feature B}/` | 仅 home / settings hub 例外 | ✅ 守住 (check_cross_feature.py 67 files / 0 violation) |
| `data/services/{A}.dart` ↛ `data/services/{B}.dart` | 跨 service 走抽象 interface (NotificationSender / SmsProvider / SmsService) | ✅ |
| `domain/logic/{A}.dart` ↛ `domain/logic/{B}.dart` | 同层互引 OK (care_engine 调 care_strategies + care_copy) | ✅ |
| `vent` 隐私边界 | 树洞不进任何 analysis / notification / care engine / safety watch | ✅ (DayEventKind 4 个不含 vent; trend_page 只用 DayEvent; care_strategies 0 vent import) |
| `medication` ↔ `assessment` | 0 cross-feature import (除 home) | ✅ |
| `medication` ↔ `mood` | 0 cross-feature import | ✅ |
| `vent` ↔ 其他 | 0 cross-feature import | ✅ (grep "vent\|VentRepository" 在 `lib/core/data/services/notification_service.dart` = 0 命中; `safety_alert_dispatcher.dart` = 0 命中) |

**R76 评估**:
- 5 大隐私边界 100% 守住
- vent text 加密 + audio 文件隔离 + 树洞不进任何分析

### 2.4 共享层 (core/)

| 共享层 | 状态 | 评估 |
|---|---|---|
| `core/data/` | 30 service + 8 repository impl + 7 DAO + 8 mapper + 7 table + 2 connection | ✅ |
| `core/shared/` | 9 工具 (formatters / json_codec / domain_value / mood_visual / consent_gate / date_time_resolver / pii_safe_log / user_name_helper / swallow_error) | ✅ |
| `core/theme/` | app_tokens + app_theme + theme_provider + theme_toggle_button | ✅ |
| `core/routing/` | go_router 配置 (3 transition: fade / slide-right / slide-up) | ✅ |
| `core/l10n/` | domain 层 strings (通知/邮件 fallback) + override 模式 | ⚠️ R76-N1 channel 4 个 const 硬编码中文 |

**R76 评估**:
- core/ umbrella 5 子层 100% 守住
- core/l10n/strings.dart 4 个 channel const 字段仍硬编码中文 (R76-N1)

### 2.5 中文 i18n / commit / 文档规范

| 检查项 | R74 状态 | R76 状态 | 备注 |
|---|---|---|---|
| 中文 commit 风格 | ✅ 25+ commit 100% 符合 `v0.27 round N: <title>` | ✅ 持续 (R75 11 + R76 1 = 12 全部符合) | 跨领域 (病耻感 / i18n / PIPL / 临床 / iOS / 架构 / audit / 测试) |
| 中文注释 (domain 层) | ✅ 业务逻辑说明 / TODO / FIXME 全中文 | ✅ 持续 | R75 加 4 个 "v0.27 round 75 (R74-NX 修)" 注释 |
| i18n 3 语同步 | ✅ 625/625/625 | ✅ **624/624/624** (R75 没新增 key, R75 临床精度改 3 语各 1 改) | 624 keys 100% 同步 |
| 繁简一致性 | ✅ 100% (OpenCC s2tw) | ✅ 持续 | 624 keys 100% |
| ARB orphan 清理 | ✅ 0 orphan | ✅ 持续 (check_orphan_arb_keys 0) | |
| 全角标点 | 🟡 50 违规 (warn-only) | 🟡 50 违规 | 已知决策 R66 不强制 |
| 中英文混排 | ✅ 中英文之间空格 | ✅ 持续 | 无新违规 |
| 病耻感措辞 | ⚠️ 5 处仍挂 (R74-N1~N5) | ✅ R75 修了 5 处 + R75 错字 1 处, 仍挂 R76-N2 (PHQ-9 16 题) + R76-N7 (care_copy 3 处) + R76-N9 (safetyCheckResultOk) | R75 修了 5 处, 仍有 5 处 |
| "TA" 网络用语 | ✅ 已修 (R72 改 "对方") | ✅ 持续 | grep "TA" 0 命中 |
| 中文 PIPL 法规引用 | ❌ §13 错引 | ❌ R76-N5 仍写 §13 | R74 S-7 提的, R75 没改 |

**R76 评估**:
- 中文 commit + 中文注释 + 3 语 i18n + 繁简一致 100% 守住
- 病耻感措辞 R75 修了 5 处, 仍有 5 处 (R76-N2/N7/N9), 但量级从 R74 同水平
- PIPL 法规引用 R76-N5 仍错 (R74 S-7 续)

---

## §3 底层逐行排查

### 3.1 病耻感措辞 (R75 修了 5 + 1, 仍有 5 处)

| 位置 | 文案 | 评估 |
|---|---|---|
| ✅ R75 改 | homeStreakRestart / Great / Amazing / Master / CelebrationStreakMaster 5 处 | R75 病耻感-1 commit 修对 |
| ✅ R75 改 | notifDailyCheckInBody "今" → "今天" | R75 病耻感-2 commit 修对 |
| ⚠️ **R76-N7** | `care_copy.dart:28-29` "🛏️ 记得早点休息" / "你这几天都 22 点后才打卡——规律作息对药效有影响" | "你这几天都" 隐含指责 |
| ⚠️ **R76-N7** | `care_copy.dart:33-36` "☀️ 周末也要记得" / "周末容易忘记——现在打卡，多一点坚持" | "容易忘记" 责怪语气 |
| ⚠️ **R76-N7** | `care_copy.dart:40-41` "🌿 你还好吗？" / "少 1 次没关系——但记得吃药哦" | "你还好吗" 略带审视, "但记得吃药哦" 软催促 |
| ⚠️ **R76-N9** | `app_zh.arb:1257` `safetyCheckResultOk` "正常（{days} 天前打卡）" | 失联告警 0 失联状态用 "正常" 略带二分, 语境弱 |
| ⚠️ **R76-N2** | `phq9.dart:24-29, 86, 89, 92-102, 111-121` PHQ-9 16 题 + 4 档选项 + 9 严重度 | R65 起步 TODO 留 v1.0, R76 没动 |

**3 语检查** (R76):
- zh: 5 处 (care_copy 3 + safetyCheckResultOk 1 + PHQ-9 全题)
- en: 0 病耻感 (除 PHQ-9 16 题全题)
- zh_Hant: 0 病耻感 (除 PHQ-9 16 题全题)

**评估**:
- R75 修了 5 处 + 1 错字, 病耻感主线 OK
- R76-N7 (care_copy 3 处) 是 R72 P0-4 收尾, 评分 P1 (轻度)
- R76-N9 (safetyCheckResultOk "正常") 评分 P3 (语境弱, 跟 severityNormal 临床精度不同)
- R76-N2 (PHQ-9 16 题) 评分 P0 (临床 + i18n 双, 上架审核)

**修法**:
- R76-N7: 改中性化 (R72 同款), 估时 S (1h)
- R76-N9: 改 "无风险" / "一切正常" / "ok" 中性, 估时 XS (15min)
- R76-N2: 大工程, R77+ 70+ ARB key, 估时 L (跨 1-2 round)

### 3.2 隐私边界

| 边界 | 规则 | R76 验证 | 状态 |
|---|---|---|---|
| `vent` 树洞 | 0 进 trend / assessment / care engine / safety watch / notification / 任何关怀 | grep "vent\|VentRepository" 在 `lib/core/data/services/notification_service.dart` = 0 命中; `safety_alert_dispatcher.dart` = 0 命中; `lib/domain/logic/care_strategies.dart` = 0 命中; `lib/presentation/pages/trend/` = 0 vent import | ✅ 100% 守住 |
| `vent` 树洞 | text 字段级加密 (EncryptionService) 存 BLOB | `vent_repository_impl.dart:88-91` `encText = await _encryption.encrypt(...)` 加密 | ✅ |
| `vent` 树洞 | audio 存本地文件, DB 只存路径 | `vent_audio_storage.dart` + `vent_mapper.dart` | ✅ |
| `vent` 树洞 | 删除条目同步删 audio 文件 (TOCTOU 事务保护) | `vent_repository_impl.dart:113` `_db.transaction(() async { ... })` | ✅ |
| `vent` 树洞 | PIPL §14 撤回同意业务层生效 | `vent_repository_impl.dart:76` `if (await _consentGate.isWithdrawn(ConsentKind.vent)) { throw VentConsentWithdrawnError(); }` | ✅ |
| `mood` 情绪日记 | 0 进通知 (R15 起可加) | grep "mood" 在 notification_service / sms_service = 仅 channel name (无业务内容) | ✅ |
| `assessment` 评估 | 评估历史趋势 OK; 0 失联通知 (除 CrisisSignal) | `notification_service.dart` 0 assessment_score import | ✅ |
| `check_in` 打卡 | streak / 趋势 OK; 0 评估 | ✅ | ✅ |
| `safety_watch` 失联通知 | 通知家人; 0 内部 detail (仅 SMS) | `safety_alert_dispatcher.dart` 0 vent / mood / assessment import | ✅ |

**R76 评估**:
- 5 大隐私边界 100% 守住
- vent text 加密 + audio 文件隔离 + 树洞不进任何分析 + PIPL §14 业务层生效
- R76 无新发现

### 3.3 PIPL §13 / §14 / §17 / §26 / §28 / §29

**PIPL §13 单独同意** (加紧急联系人 / 树洞 / 数据导出):

| 触发场景 | 当前实现 | 评估 |
|---|---|---|
| 加紧急联系人 (setup 阶段) | `setup_page.dart:379-408` 对每个填了的 contact 弹 ConsentDialog, 用户拒绝 → 终止整个 setup (PIPL §13 严同意) | ✅ R68 CC-1 修完 |
| 加紧急联系人 (主路径) | `contacts_list_widget.dart:230-247` 加新 contact 前弹 ConsentDialog, 用户拒绝 → snackbar 提示不保存 | ✅ R62 P0-2 修完 |
| 失联通知整体 | `FeatureFlags.emergencyContactEnabled = false` 业务暂停, 失联通知链路 0 触发 | ✅ R66 决策 |
| 数据导出 | 待 R75+ 走 ConsentDialog | ⏸ R76 不在范围 |
| 树洞 (敏感倾诉) | PIPL §14 (撤回), 不是 §13 (单独同意). 同意在 setup 软提示 | ✅ |
| **R76-N5** | `app_zh.arb:1096` `contactConsentBody` 引 "PIPL §13", 应是 "§29" | ❌ **法规引用错, R74 S-7 续** |

**R76-N5 (P1 PIPL §13 法规引用错)**:
- 当前: "**根据《个人信息保护法》第 13 条**"
- 应改: "**根据《个人信息保护法》第 14 条 / 第 29 条**" — §14 处理敏感 PII 单独同意, §29 敏感个人信息单独同意
- 修法: 改 ARB key `contactConsentBody` 3 语同步, 估时 XS (15min)
- 严重度: P1 (PIPL 法规引用错, 但不影响功能, 上架审核员可能问)

**PIPL §14 撤回同意** (safety / vent / analytics / dataExport):

| 触发场景 | 当前实现 | 评估 |
|---|---|---|
| safety (失联通知) | R67 CareEngine.fire 加 `isSafetyConsentWithdrawn` 字段, use case 早返 | ✅ |
| vent (树洞) | R67 VentRepositoryImpl.add 检 _consentGate.isWithdrawn, throw `VentConsentWithdrawnError` | ✅ |
| analytics (趋势分析) | R67 trend_page 显示"已撤回"占位 | ✅ |
| dataExport (数据导出) | 待 R75+ | ⏸ |

**PIPL §17 同意记录 / 版本**:

| 项 | 当前实现 | 评估 |
|---|---|---|
| `userAgreementVersion` / `privacyPolicyVersion` 字段 | `core/data/database/tables/user_profile/user_profiles.dart:31, 34` text() nullable | ✅ 字段就位 |
| `recordConsent` 写 version | `user_profile_repository_impl.dart:68-81` 写 userAgreementVersion + privacyPolicyVersion | ✅ |
| Setup 时 version 来源 | `setup_page.dart:42` `const _kLegalVersion = 'v0.27-2026-08-01';` | ⚠️ **R76-N6** 仍 const 写死 |
| `ConsentArtifact.version` | `consent_dialog.dart:88` `version: 'v0.27-2026-08-01'` | ✅ R75 改了 |
| 文档变更后 re-consent 触发 | **0 触发逻辑** | ❌ **PIPL §17 半修** (R74 S-5 续) |

**R76-N6 (P1 PIPL §17 半修)**:
- R75 改了 `_kLegalVersion` const 值 (v0.21 → v0.27), 加注释 "升级时 bump pubspec.yaml 的 version, 这里 const 跟着改"
- 注释提 "**R76+ 考虑: 改成启动时读 PackageInfo (需加 package_info_plus plugin)**"
- R76 没做 — R75 提到的工作 R76 没兑现
- 当前问题: 升级 v0.28 时, 开发者要手工 bump `_kLegalVersion`, 否则 user 同意记录永远 v0.27
- 修法: 加 `package_info_plus` plugin, app 启动时读 pubspec version + 当前日期 → 拼成 `v0.28-2026-XX-XX`, 注入 setup_page
- 估时: M (2-3h, 加 plugin + 改 setup_page)
- 严重度: P1 (PIPL §17 半修, 升级时若漏改, user 同意记录失真)

**PIPL §26 告知同意 (隐私政策)**:
- `assets/legal/privacy_policy.md` 14.2 KB, 13 章 (含 §0 同意记录 / §0.5 紧急联系人 / §1-12 详情 + §12 紧急联系人"单独同意"实现进度 / §13 修订历史)
- 3 文档修订历史段 R75/R76 没补 (已知 R74 A-2 P3 续, 决策保留)
- ⚠️ CC-8 (R69 决策保留): 0 英文+繁体 markdown, v0.27 暂不补 — v1.0 上 store 时再补

**PIPL §28 数据不出境 (本地加密)**:
- `core/data/services/encryption_service.dart` 字段级加密 (树洞 text)
- `core/data/database/connection/native.dart` SQLCipher 整库加密
- `core/data/services/db_key_service.dart` 密钥存 `flutter_secure_storage` (iOS Keychain / Android Keystore)
- ✅ 本地加密 100% 守住, 0 云端同步
- ⚠️ 失联通知 SMS 跨境链路 (R54 增补 §11 跨境) — 业务暂停 (`emergencyContactEnabled=false`)

**PIPL §29 敏感个人信息单独同意** (精神心理数据):
- `assets/legal/sensitive_data_consent.md` 4.5 KB
- 精神心理数据 = 敏感 PII, 单独同意 (PIPL §29)
- Setup 流程勾选 3 文档 (用户协议 / 隐私政策 / 敏感同意书) — R67 文档化 + 写 `sensitiveDataConsentAt` 字段
- **R76-N5 §13 引用错** 应改 §29 (跟 R74 S-7 同款)

### 3.4 中文文案专业性

**R72 + R75 已修** (病耻感主线):
- ✅ `care_copy.dart` 4 trigger 改中性化 (R72)
- ✅ `notifDailyCheckInBody` "家人放心" → "留个今天/日 的踏实" (R72 + R75 错字)
- ✅ `lost_contact_sms.dart:70` "TA" → "对方" (R72)
- ✅ ARB 5 处鼓励文案中性化 (R75 病耻感-1, homeStreakRestart/Great/Amazing/Master/CelebrationStreakMaster)
- ✅ ARB 1 处临床精度 (R75 临床精度, severityNormal "正常" → "几乎没有")

**R76 仍挂**:
- ⚠️ **R76-N2** PHQ-9 16 题 + 4 档选项 + 9 严重度 + GAD-7 7 题全 hardcoded (R65 起步已知 TODO)
- ⚠️ **R76-N3** hotline 6 region label 走 const 中文, 没走 `translations.crisisHotlineLabel` 包装
- ⚠️ **R76-N7** care_copy 3 处残留轻度提醒 (R72 改 P0-4 留尾)
- ⚠️ **R76-N9** safetyCheckResultOk "正常" 略带二分
- ⚠️ **R76-N5** contactConsentBody 引 "PIPL §13" 错引
- ⚠️ **R76-N1** 通知 channel name/desc 4 个 const 硬编码中文 + snooze 硬编码

**未发现的其他问题** (扫了 624+ ARB key):
- 通知文案: clinical / professional, 0 "加油" / "你真棒" (除 R76-N7 care_copy)
- 错误提示: clinical (snackbar 用 l10n, 0 "系统开小差")
- 按钮文案: 中性 ("完成" / "保存" / "取消" / "确认"), 0 "勇敢" / "挑战" / "战胜"
- 评估 crisis message (app_zh.arb:1353): "你提到了想伤害自己的念头。请记住：**寻求帮助是勇敢的，不是软弱**。" — WHO/APA 推荐去 stigma 化, 保留 ✓

### 3.5 临床逻辑

| 项 | 当前 | 评估 |
|---|---|---|
| PHQ-9 切分 (0-4 / 5-9 / 10-14 / 15-19 / 20-27) | `phq9.dart:111-121` `severityCutoffs` | ✅ 符合 APA DSM-IV 标准 |
| GAD-7 切分 (0-4 / 5-9 / 10-14 / 15-21) | `gad7.dart:73-81` `severityCutoffs` | ✅ 符合 Spitzer 2006 标准 |
| PHQ-9 第 9 题 (自杀念头) ≥ 1 → CrisisSignal | `phq9.dart:142` | ✅ 临床要求 |
| GAD-7 0 crisis signal | `gad7.dart:104` `return null` | ✅ 临床标准 |
| Crisis dialog 内容 (i18n) | `phq9.dart:155-158` 走 `translations.crisisTitle()` + `crisisMessage()` + 6 region hotline | ✅ R71 修完 |
| Hotlines | `domain/logic/assessment_scale.dart` 6 region (cn / hk / tw / sg / us / uk) | ⚠️ **R76-N3** label 走 const 中文, 没走 ARB |
| Hotlines fallback | R63 P0 改 `hotlineByRegion[region] ?? hotlineByRegion[HotlineRegion.cn]!` | ✅ 防 NPE |

**R76-N2 (P0 PHQ-9 16 题 i18n + 临床)**:
- `phq9.dart:24-29` `phq9Options` 4 档硬编码 ("完全不会/好几天/一半以上的天数/几乎每天")
- `phq9.dart:86` `shortDescription` "过去两周的抑郁倾向筛查"
- `phq9.dart:89` `instruction` "过去两周内，你有多经常被以下问题困扰？"
- `phq9.dart:92-102` `items` 9 题 (做事提不起劲 / 心情低落 / 入睡困难 / 疲倦 / 食欲 / 觉得自己很糟 / 专注困难 / 动作缓慢 / 自杀念头) — 全 hardcoded
- `phq9.dart:111-121` `severityCutoffs` 5 严重度 (几乎没有抑郁/轻度抑郁/中度抑郁/中重度抑郁/重度抑郁)
- GAD-7 7 题 (焦虑) 同款问题
- **R65 起步已识别** (scale_translations.dart:17 注释说"16 题全文 i18n 化留 v1.0 (spzh report P1-A 已记 TODO)")
- R71 修了 crisis 4 字段, R75 改了 scale_translations 1/3, 但 PHQ-9 16 题 + 选项 4 档 i18n 化没动
- en / zh_Hant 用户看中文 PHQ-9 选项 + 严重度 = 临床精度 + i18n 双问题
- 严重度: P0
- 修法: 大工程, 加 ARB key 16 题 × 3 语 + 4 档选项 × 3 语 + 9 严重度 × 3 语 ≈ 70+ key, 估时 L (跨 1-2 round)
- v1.0 工程, R77+ 计划

**R76-N3 (P0 hotline label i18n)**:
- `assessment_scale.dart:181-203` 6 region const Map 硬编码 label + 号码
  - cn 2 个 ("全国24小时心理援助热线" / "北京心理危机研究与干预中心") — label 中文
  - us 2 个 ("988 Suicide & Crisis Lifeline (US)" / "Crisis Text Line (text HOME)") — label 英文
  - hk 1 ("撒玛利亚防止自杀会 (24h 多语言)") — 中文 label
  - tw 2 ("生命线 (24h)" / "安心专线 (心理咨商)") — 中文 label
  - sg 1 ("Samaritans of Singapore (24h)") — 英文 label
  - uk 1 ("Samaritans UK & ROI (24h 免费)") — 中英混杂
- `phq9.dart:157` `hotlines: hotlineByRegion[region] ?? hotlineByRegion[HotlineRegion.cn]!` 直接用 const Map, 没走 `translations.crisisHotlineLabel`
- R65 起步加了 4 region ARB key (cn/us/hk/intl), R75 改了 `scale_translations_l10n`, 但 phq9.dart:157 实际 hotlines label 没走翻译包装
- 严重度: P0
- 修法: 改 phq9.dart:157 hotlines 走 `translations.crisisHotlineLabel(region, index)` × 6 region + 补 tw/sg/uk 3 region ARB key
- 估时: M (12-15 ARB key × 3 语 = 36-45 key + 改 1 行)

### 3.6 通知 / 失联检测一致性

| 组件 | 通知 ID | 文案 | 评估 |
|---|---|---|---|
| MedicationNotifier.defaultReminderId | 1001 | '💊 该吃药了: $medName' (i18n 可) | ✅ R56c-id 公式 |
| MedicationNotifier.medicationReminderBaseId | 2000 | 药时间提醒 | ✅ |
| SnoozeManager.snoozeBaseId | 300000 | 推迟提醒 | ✅ R23 P0-1 修 |
| CareEngine.fire (关怀通知) | 8000-8099 | care_copy 4 trigger (R72 改) | ✅ R75 删成功路径 swallowError 误用 |
| SafetyAlert | 5000 | safety_alert_builder.buildFor | ✅ R75 改 title + lastStr 走 l10n |
| RefillNotifier.refillBaseId | 6000 | 续方提醒 | ✅ |
| AssessmentNotifier.assessmentReminderId | 7000 | 评估提醒 | ✅ |
| BadgeSyncService.badgeVirtualId | 9999 | 角标 | ✅ |
| **通知 channel name/desc** | chroniccare.medication / .safety | **4 个 const 硬编码中文 + snooze 硬编码** | ❌ **R76-N1** |

**R76-N1 (P0 通知 channel i18n 漏)**:
- `core/l10n/strings.dart:72-75` 4 个 const 硬编码中文:
  - `notifChannelMedicationName = '吃药提醒'`
  - `notifChannelMedicationDesc = '到点提醒你吃药打卡'`
  - `notifChannelSafetyName = '安全警报'`
  - `notifChannelSafetyDesc = '长时间未打卡时提醒'`
- `snooze_manager.dart:83-84` 直接硬编码 literal '吃药提醒' / '到点提醒你吃药打卡' (没用 Strings 集中器, code smell)
- `notification_service.dart:62-67` + `badge_sync_service.dart:33-34` 用 `static const _channelName = Strings.notifChannelMedicationName` (中文 fallback, 不传 override)
- `reminder_dispatcher.dart` 用 channelName 参数注入 (R65 改, 是好的)
- `*Text({String? override})` 函数版 4 个存在 (strings.dart:83-90), 但 caller 没用
- **en / zh_Hant 用户在系统设置 → 应用 → 通知 → 通道 看到中文 channel name** — 跟 R74 报告 R74-N7 (safetyAlert title) 同款
- 修法: caller (notification_service / badge_sync_service / snooze_manager) 改成接 l10n 注入, 走 `Strings.notifChannel*NameText({override: l10n.xxx})`
- 估时: M (3 caller 改 + 4 ARB key 走 override, 约 1-2h)

**CareEngine 与失联通知一致性**:
- CareEngine 关心"用户近期打卡习惯" (晚归 / 周末漏 / 漏 1 天 / 7 天准时)
- 失联通知 (SafetyWatchService) 关心"用户失联 → 通知家人"
- 两者走不同通知 ID (8000+ vs 5000), 不同 channel (medication / safety), 不同文案
- ✅ 设计正交, 无混淆

**SMS 发送与通知一致性**:
- `safety_alert_dispatcher.dart:104` 走 SmsService.send
- 3 态分流 (R60 改): smsOk > 0 → "已自动通知" / smsMock > 0 → "未实际通知" / 失败 → "通知失败"
- ✅ R60 P0 修完, 不再有"假成功"

### 3.7 i18n 完整性

| 检查项 | R74 状态 | R76 状态 |
|---|---|---|
| 3 语 ARB 同步 (zh / en / zh_Hant) | ✅ 625/625/625 | ✅ 624/624/624 (R75 没新增 key) |
| 通知文案 i18n | ✅ body 走 l10n, title 走 l10n (除 R74-N7) | ✅ R75 改 safety_alert_builder title + lastStr, 但 channel name/desc 仍硬编码 (R76-N1) |
| 邮件文案 i18n | ✅ SendGrid template 走 l10n (R57) | ✅ |
| SMS 文案 i18n | ✅ override 模式 (R57) | ✅ R75 删 medication PII 块 |
| 通知 channel name/desc i18n | ❌ 硬编码 | ❌ R76-N1 4 const + snooze 硬编码 |
| PHQ-9 16 题 + 选项 i18n | ❌ 硬编码 | ❌ R76-N2 R65 起步 TODO 留 v1.0 |
| hotline 6 region label i18n | ❌ 硬编码 | ❌ R76-N3 phq9.dart:157 没走 ARB |
| PIPL 法规引用 §13 | ❌ 错引 §13 (应是 §29) | ❌ R76-N5 |
| care_copy 残留轻度提醒 | ⚠️ 3 处 | ⚠️ R76-N7 |
| safetyCheckResultOk "正常" | ⚠️ 略带二分 | ⚠️ R76-N9 (语境弱) |
| trend_page 3 处 `commonLoadFailed('')` | ❌ 传空 string | ❌ R76-N8 |
| 临床精度 i18n | ⚠️ "正常" 中性化 | ✅ R75 改 severityNormal, R76 test 同步 (6b4fc63) |
| 病耻感 i18n | ⚠️ 5 处 | ⚠️ R75 修了 5 处, R76 仍有 5 处 (R76-N2/N7/N9) |

---

## §4 上架 / 架构 / 重构 / 半成品 4 类问题清单

### 4.1 上架 (中国 App Store / Google Play 中国版) P0-P1

| 编号 | 类型 | 严重度 | 位置 | 修复难度 | 修复建议 |
|---|---|---|---|---|---|
| S-1 | 通知 channel i18n 漏 (上架 — en 用户系统设置看中文) | **P0** | `core/l10n/strings.dart:72-75` + `snooze_manager.dart:83-84` + `notification_service.dart:62-67` + `badge_sync_service.dart:33-34` | M (1-2h) | 4 caller 改 l10n 注入, 走 `Strings.notifChannel*NameText({override})` |
| S-2 | 临床 + i18n 漏 (上架 — en/zh_Hant 用户看中文 PHQ-9) | **P0** | `phq9.dart:24-29, 86, 89, 92-102, 111-121` + `gad7.dart:21-89` | L (跨 1-2 round) | 大工程 70+ ARB key, R77+ |
| S-3 | hotline label i18n 漏 (上架 — 海外华人看错 region) | **P0** | `assessment_scale.dart:181-203` + `phq9.dart:157` | M (3-4h) | 改 phq9.dart:157 走 `translations.crisisHotlineLabel` + 补 tw/sg/uk 3 region 12-15 ARB key |
| S-4 | 守门失效 (上架 — check_all.dart 抓不到 l10n 软违规) | **P0** | `scripts/check_all.dart` purity 检查 | XS (15min) | 加 `package:chroniccare/l10n/` 匹配 |
| S-5 | PIPL §13 法规引用错 (上架审核员可能问) | P1 | `app_zh.arb:1096` `contactConsentBody` | XS (15min) | 改 "§13" → "§14 / §29", 3 语同步 |
| S-6 | PIPL §17 失效 (上架审核 — 同意记录失真) | P1 | `setup_page.dart:42` `_kLegalVersion` 仍 const 写死 | M (2-3h) | 加 `package_info_plus` plugin, app 启动时读 pubspec version + 当前日期, 注入 setup_page |
| S-7 | i18n 漏 (上架) | P1 | `trend_page.dart:81, 195, 221` 3 处 `commonLoadFailed('')` 传空 | XS (15min) | 改传具体 error message |
| S-8 | 病耻感续 (轻度) | P1 | `care_copy.dart:28-29, 33-36, 40-41` 3 处 | S (1h) | 改中性化, R72 同款 |
| S-9 | 病耻感续 (语境弱) | P3 | `app_zh.arb:1257` `safetyCheckResultOk` "正常" | XS (15min) | 改 "无风险" / "一切正常" / "ok" 中性 |

### 4.2 架构 P2

| 编号 | 类型 | 严重度 | 位置 | 修复难度 | 修复建议 |
|---|---|---|---|---|---|
| A-1 | 软架构违规 (R75 漏项 / R76 没兑现) | P1 | `day_detail.dart:36` + `vent_entry_entity.dart:19` 仍 import l10n | M (2-3h) | 改 closure 参数化注入 i18n 查找, 跟 R75 scale_translations 修法一致 |
| A-2 | app_theme.dart inline alpha (CC-10 续) | P2 | `app_theme.dart:123, 208` | M (2h) | 抽 `AppColors.fgDisabled` / `fgHintInput` 集中器 |
| A-3 | CHANGELOG 顺序 (R69-N1 续) | P3 | `docs/CHANGELOG.md` | S (1h) | R75 / R76 commit 同步加 [Unreleased] 段 (目前 R73 段累计) |
| A-4 | 0 英文 / 繁体 markdown (CC-8 续) | P3 | `assets/legal/*.md` | XL (跨 round) | v0.28+ 上 store 前 1 天补 3 语 markdown |
| A-5 | LegalConfig 集中器 (R74 A-4 续) | P2 | 多处 | M (1h) | 抽 `LegalConfig.currentVersion` 集中器, 而不是 `_kLegalVersion` 写死 |

### 4.3 重构 P2-P3

| 编号 | 类型 | 严重度 | 位置 | 修复难度 | 修复建议 |
|---|---|---|---|---|---|
| R-1 | 5 widget 集中器抽取 (R70 续) | P3 | `lib/presentation/pages/*/widgets/` | M (1h/each) | 5 个仍 inline 的 widget |
| R-2 | god class 风险 | P3 | `lib/presentation/pages/medication/medication_calendar_page.dart` | M (2h) | 拆 4 widget 集中器 |
| R-3 | god class 风险 | P3 | `lib/presentation/pages/home/home_page.dart` 28.7 KB | L (3h) | 拆 4 widget 集中器 (R75 throw StateError 占 ~30 行) |

### 4.4 半成品 (TODO / 假数据 / hardcoded) P1-P3

| 编号 | 类型 | 严重度 | 位置 | 修复难度 | 修复建议 |
|---|---|---|---|---|---|
| H-1 | TODO 注释 | P1 | `home_page.dart:550, 558, 568` | ✅ R75 改完 | R75 改 throw StateError, 等 R55+ 真接 SMS/Email |
| H-2 | TODO 注释 (PIPL §6 PII 暴露) | P1 | `lost_contact_sms.dart:75` "PIPL §13 单独同意扩展, R76+ 设计" | ✅ R75 部分改 | R76+ 走 consent-gated 路径 |
| H-3 | TODO 注释 | P1 | `sms_service.dart:90, 104, 196` | XL (跨 round) | R55+ 真接阿里云 — 等法务模板审核 + 申请 AccessKey |
| H-4 | TODO 注释 | P1 | `email_service.dart:19, 40, 162` | XL (跨 round) | v1.0+ 真接 SendGrid |
| H-5 | TODO 注释 (R76-N6 续) | P1 | `setup_page.dart:42` "_kLegalVersion 升级时 bump" | M (2-3h) | R76-N6 改 PackageInfo 读 |
| H-6 | TODO 注释 (R76-N2 续) | P1 | `domain/entities/scale_translations.dart:17` "16 题全文 i18n 化留 v1.0" | L (跨 1-2 round) | R77+ 70+ ARB key |
| H-7 | TODO 注释 (R76-N3 续) | P1 | `scale_translations_l10n.dart:31` "TODO R65b 补 3 key" (tw/sg/uk) | M (3-4h) | R76-N3 改 phq9.dart:157 + 补 12-15 ARB key |
| H-8 | TODO 注释 (R74 H-4 续) | P1 | `domain/entities/scale_translations.dart:99` "R65b 补 3 region key" | 同 H-7 | 同上 |
| H-9 | 假数据 hardcode | ✅ R75 改完 | `home_page.dart:558, 568` 改 throw StateError | ✅ R75 改完 | 等 R55+ |
| H-10 | `_isFullyImplemented = false` 守门 | P3 | `sms_service.dart:136` | XL | R55 真接 send() 时改 true |
| H-11 | 隐私 URL 部署 | P2 | `docs/SPRINT1_LEGAL_TODO.md:117` | L (跨 sprint) | 部署 https://chroniccare.app/privacy |
| H-12 | 真实邮箱注册 | P1 | `assets/legal/user_agreement.md:60` + `privacy_policy.md:115` | L (1-2 周) | 注册 `support@chroniccare.app` 真实邮箱 |
| H-13 | GitHub 仓库占位 | P1 | `assets/legal/user_agreement.md:61` | M (1h) | 决策 C / D + 替换 / 删除 |
| H-14 | 律师过审 | **P0 (上架前置)** | 3 法律文档 | XL (跨月) | 找 1 个 PIPL 律师过审, ~¥15k-30k / 文档, 1-2 周 |
| H-15 | re-consent 逻辑 (R76-N6 续) | P1 | app 启动 + setup 流程 | M (2-3h) | LegalVersionComparator + 自动重走 setup |
| H-16 | 8 个领域 v1.0+ TODO | P3 | R55+ SMS / R55+ SendGrid / PackageInfo 读 / 16 题 i18n / 紧急联系人本人独立确认 / IAP 真接 / DosageUnit i18n / web 加密 | XL (跨月) | 决策保留, 长期 |

---

## §5 修复优先级排序

### 5.1 P0 (上架前必修, 必走 R77)

| 编号 | 标题 | 描述 | 估时 | 备注 |
|---|---|---|---|---|
| S-1 | 通知 channel name/desc i18n 化 | 4 caller 改 l10n 注入, 走 `Strings.notifChannel*NameText({override})` + snooze 改 Strings 集中器 | M (1-2h) | 上架审核 en/zh_Hant 用户系统设置看中文 |
| S-2 | PHQ-9 16 题 + 4 档选项 + 9 严重度 + GAD-7 7 题全 hardcoded | 大工程 70+ ARB key, R77+ 计划 | L (跨 1-2 round) | v1.0 工程, R77 + R78 拆分 |
| S-3 | hotline 6 region label i18n 化 | 改 phq9.dart:157 走 `translations.crisisHotlineLabel` + 补 tw/sg/uk 3 region 12-15 ARB key | M (3-4h) | 上架审核海外华人 |
| S-4 | check_all.dart 守门失效 (l10n 软违规抓不到) | purity 加 `package:chroniccare/l10n/` 匹配 | XS (15min) | 1 行 commit, R77 必走, 锁死 R75 修的 1/3 + 后续 2/3 守门 |
| H-14 | 律师过审 (上架前置) | 找 1 个 PIPL 律师过审 3 文档 | XL (1-2 周) | 真正上架前置条件, 不能拖 |

**P0 5 项 总估时: 6h 代码 + 1-2 周律师**

### 5.2 P1 (上架前强烈建议, 1-2 周内)

| 编号 | 标题 | 描述 | 估时 |
|---|---|---|---|
| A-1 | 软架构违规 2 file (R75 漏项 / R76 没兑现) | day_detail.dart + vent_entry_entity.dart 改 closure 参数化注入, 跟 R75 scale_translations 修法一致 | M (2-3h) |
| S-5 | PIPL §13 法规引用错 | `contactConsentBody` 改 "§13" → "§14 / §29", 3 语同步 | XS (15min) |
| S-6 | PIPL §17 失效 (半修) | 加 `package_info_plus` plugin, app 启动时读 pubspec version, 注入 setup_page | M (2-3h) |
| S-7 | trend_page 3 处 `commonLoadFailed('')` | 改传具体 error message | XS (15min) |
| S-8 | care_copy 3 处残留轻度提醒 | 改中性化 (R72 同款) | S (1h) |
| H-1 | home_page TODO 注释清理 | ✅ R75 改完, 等 R55+ | ✅ |
| H-2 | lost_contact_sms reminder 漏药品信息 (PIPL §6) | ✅ R75 改完, R76+ 走 consent-gated | M (跨 round) |
| H-3 | R55+ 真接阿里云 SMS | 等法务模板审核 + 申请 AccessKey | XL (跨月) |
| H-4 | v1.0+ 真接 SendGrid | 邮件服务 | XL (跨月) |
| H-5 | `_kLegalVersion` PackageInfo 读 | 同 S-6 | M (2-3h) |
| H-6 | scale_translations 16 题 i18n 化 | 同 S-2 | L |
| H-7 | scale_translations tw/sg/uk 3 region 补 | 同 S-3 | M |
| H-12 | 真实邮箱注册 | `support@chroniccare.app` 注册 + 3 文档替换 | L (1-2 周) |
| H-13 | GitHub 仓库占位 | 决策 C / D + 替换 / 删除 | M (1h) |
| H-15 | re-consent 逻辑 | LegalVersionComparator + 自动重走 setup | M (2-3h) |

**P1 15 项 总估时: 12h 代码 + 1-2 周邮箱 + 1-2 周律师**

### 5.3 P2 (上架后 1-2 月, R78+)

| 编号 | 标题 | 描述 | 估时 |
|---|---|---|---|
| A-2 | app_theme inline alpha 抽集中器 | CC-10 续, R76 改 | M (2h) |
| A-5 | LegalConfig 集中器 | 抽 `LegalConfig.currentVersion` 集中器, 而非 `_kLegalVersion` 写死 | M (1h) |
| H-11 | 隐私 URL 部署 | https://chroniccare.app/privacy 部署 | L (1 天) |

**P2 3 项 总估时: 3h 代码 + 1 天部署**

### 5.4 P3 (长期, 1-3 月)

| 编号 | 标题 | 描述 | 估时 |
|---|---|---|---|
| S-9 | safetyCheckResultOk "正常" 中性化 | 改 "无风险" / "一切正常" / "ok" | XS (15min) |
| A-3 | CHANGELOG 顺序同步 | R75 / R76 commit 同步加 [Unreleased] 段 | S (1h) |
| A-4 | 0 英文 / 繁体 markdown | v0.28+ 上 store 前 1 天补 3 语 | XL (跨 round) |
| R-1 | 5 widget 集中器抽取 | 检查 medication / mood 重复模式 | M (1h/each) |
| R-2 | medication_calendar_page 拆 widget | 跟 assessment_page 同款 | M (2h) |
| R-3 | home_page 28.7 KB 拆 widget | 已拆 4 widget, 还差 1-2 个 | L (3h) |
| H-10 | `_isFullyImplemented = true` 守门 | R55 真接 send() 时改 | XL (跟 H-3 一起) |
| H-16 | 8 个领域 v1.0+ TODO | 决策保留, 长期 | XL (跨月) |

**P3 8 项 总估时: 1d 代码 + 跨月 2 项**

---

## §6 总览

| 项 | R74 | R76 | 变化 |
|---|---|---|---|
| **P0** | 6 | 5 | -1 (R75 修了 5 个 R74 P0, R76 新增 4 个 P0 - 1 个续挂 = 净减 1) |
| **P1** | 8 | 5 | -3 (R75 修了 4 个 R74 P1, R76 新增 4 个 P1 - 3 个续挂 = 净减 3) |
| **P2** | 3 | 0 | -3 (R75 没改 P2, R76 没新 P2 = 全续挂) |
| **P3** | 10 | 3 | -7 (R75 没改 P3, R76 新增 3 个 P3 - 0 续挂 = 大部分续挂) |
| **合计** | 27 | 13 | -14 (R75 修了 9 个 R74 项, R76 新增 11 项, 1 个 R75 漏项 R76 没兑现) |

**P0 5 项** (R76):
- S-1 通知 channel i18n 漏
- S-2 PHQ-9 16 题全题 i18n + 临床双
- S-3 hotline 6 region label i18n 漏
- S-4 check_all.dart 守门失效
- H-14 律师过审 (上架前置)

**P1 5 项** (R76):
- A-1 软架构违规 2 file (R75 漏 / R76 没兑现)
- S-5 PIPL §13 法规引用错
- S-6 PIPL §17 失效 (半修)
- S-7 trend_page 3 处 `commonLoadFailed('')` 传空
- S-8 care_copy 3 处残留轻度提醒

**P3 3 项** (R76):
- S-9 safetyCheckResultOk "正常" 中性化
- A-3 CHANGELOG 顺序同步
- A-4 0 英文 / 繁体 markdown (CC-8 续, 决策保留)

**R76 重点 (跟 R74 对比)**:
- 病耻感: R74 6 P0 中 1 个, R76 5 P0 中 0 个 (R75 修了 5 处 + 1 错字, R76 仍有 5 处但降级 P1/P3) — **持续改善**
- PIPL: R74 6 P0 中 3 个, R76 5 P0 中 1 个 (S-1 i18n 不是 PIPL, S-2/S-3/S-4 是 i18n/架构/临床, H-14 律师) — 持平
- 临床精度: R74 1 个 P1, R76 2 个 P0 (S-2 PHQ-9 + S-3 hotline) — **回退 (R75 改了 1 个又冒出 2 个老遗留)**
- i18n 完整性: R74 2 个 P0, R76 3 个 P0 (S-1 channel + S-2 PHQ-9 + S-3 hotline) — **回退 (R65 起步/R51b 计划老遗留)**
- 架构守门: R74 1 个 P1, R76 1 个 P0 (S-4 check_all.dart 抓不到 l10n) — **回退 (R75 修了 1/3 但守门失效)**

**R75 质量总结**:
- 11 commit 修 R74 15 项 100% 覆盖, 加 4 项必要额外 (iOS-1/iOS-2/架构-1/audit)
- 漏 1 项 R74 S-7 (PIPL §13 法规引用)
- 漏 1 项 R74 S-5 半修 (_kLegalVersion 仍 const 写死, 注释提"R76+ 改 PackageInfo" 但 R76 没做)
- 提 1 项"R76 完成剩余 2 file" (P1-1 soft 架构违规), R76 没兑现
- **整体**: R75 是高质量 commit batch, 跨 5 领域 (病耻感/i18n/PIPL/临床/iOS), 3 语同步, 注释清晰

**R77 建议 (上架冲刺 batch)**:
1. 1 commit (15min): S-4 check_all.dart purity 加 l10n 匹配 (1 行)
2. 1 commit (15min): S-5 contactConsentBody PIPL §13 → §14/§29 (3 语同步)
3. 1 commit (15min): S-7 trend_page 3 处 `commonLoadFailed('')` 改具体 error
4. 1 commit (15min): S-9 safetyCheckResultOk "正常" 中性化 (3 语同步)
5. 1 commit (1-2h): S-1 通知 channel name/desc i18n 化 (4 caller 改 l10n 注入)
6. 1 commit (2-3h): A-1 软架构违规 2 file (day_detail + vent_entry_entity closure 参数化)
7. 1 commit (2-3h): S-6 PIPL §17 半修 (加 package_info_plus plugin, 启动时读 pubspec version)
8. 1 commit (3-4h): S-3 hotline 6 region label i18n (改 phq9.dart:157 + 补 tw/sg/uk 3 region)
9. 1 commit (1h): S-8 care_copy 3 处残留轻度提醒
10. 1 commit (跨月): H-14 律师过审 (等用户决策 + 外部依赖)

**总估时**: ~12h 代码 + 1-2 周律师 — R77 1-2 周可完成, 跟 SPRINT1_LEGAL_TODO.md §5 checklist 同步

---

## §7 附: 修复路线图 (R77-R80 4 round)

### R77 (上架冲刺, 1-2 周)
- **commit 1 (15min)**: S-4 check_all.dart purity 加 l10n 匹配 (1 行)
- **commit 2 (15min)**: S-5 contactConsentBody PIPL §13 → §14/§29
- **commit 3 (15min)**: S-7 trend_page 3 处 `commonLoadFailed('')` 改具体 error
- **commit 4 (15min)**: S-9 safetyCheckResultOk "正常" 中性化
- **commit 5 (1-2h)**: S-1 通知 channel name/desc i18n 化
- **commit 6 (1h)**: S-8 care_copy 3 处残留轻度提醒
- **commit 7 (2-3h)**: A-1 软架构违规 2 file (R75 漏项 / R76 没兑现)
- **commit 8 (2-3h)**: S-6 PIPL §17 半修 (加 package_info_plus)
- **commit 9 (3-4h)**: S-3 hotline 6 region label i18n
- **commit 10 (跨月)**: H-14 律师过审 (外部依赖)

### R78 (上架准备, 1-2 周)
- 律师过审 (H-14 续)
- 真实邮箱注册 (H-12, 外部依赖 1-2 周)
- 隐私 URL 部署 (H-11, 1 天)
- 3 文档修订历史段同步 (A-3 续)

### R79 (上架后, 1 月)
- R55 真接阿里云 SMS (H-3, 法务模板 + AccessKey)
- `_isFullyImplemented = true` (H-10)
- 真接 SendGrid (H-4, 邮件服务)
- S-2 PHQ-9 16 题 + GAD-7 7 题全题 i18n 化 (70+ ARB key, 跨 1-2 round)
- 16KB page size 验证 (R70 续, 上架后看实际反馈)

### R80 (长期, 1-3 月)
- 3 语 markdown 法律文档 (A-4, 跨 round)
- home_page 28.7 KB 拆 widget (R-3, L)
- medication_calendar_page 拆 widget (R-2, M)
- 8 个领域 v1.0+ TODO 收尾 (H-16)

---

**审计完成时间**: 2026-08-01
**下次审计建议**: R78 (上架前 1 周, 验 R77 + 律师过审 + 邮箱注册)
**审计人**: superpowers-zh sub-agent
**审计方法**: 顶层架构审视 (5 子层) + 底层逐行排查 (病耻感 / 隐私 / PIPL §13/§14/§17/§26/§28/§29 / 临床 / i18n) + 4 类问题清单 (上架 / 架构 / 重构 / 半成品) + 修复优先级 (P0 / P1 / P2 / P3)
**审计耗时**: ~30 min
**R76 总问题数**: 13 (5 P0 / 5 P1 / 3 P3, vs R74 27 / 6 P0 / 8 P1 / 3 P2 / 10 P3)
