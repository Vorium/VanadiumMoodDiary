# superpowers-zh 视角代码审查 · round 62 (7-lens #3)

> **基线**: v0.27 round 60+working tree (R61 platform 准备已合,未 commit) / schemaVersion 14 / 1151 tests / 0 analyze error
> **审查范围**: i18n / PIPL 合规 / 法务文档 / 命名注释 / Git 提交风格 / 术语一致性 / 国产 ROM / 隐私边界
> **方法**: 抽样 8 个核心文件 (main/strings/sms_service/safety_watch/email_template/setup_page/contacts_list/setup_legal_dialog) + 3 份法务 markdown + ARB zh/en/zh_Hant + terminology.md + 16 守护脚本 + 全文中文 string literal 扫描 (590 hits)
> **对照基线**: docs/review/superpowers_zh_report_v0.27.md (45KB v0.27 R60 spzh 报告) + 历史 spzh P0-P3 清单

---

## 1. 总评 (1 句话)

R60-R61 修真 (P0-3 安全告警 3 态分流 i18n + P1-4 safety_check_result 8 kind i18n + P2 medication_unit i18n) 已落地,**但 home_page 漏改 displayMessage 调用 + reminder_scheduler 整段 SMS 模板未走 strings + 5 处联系人/PIPL 硬实做仍是 P0 production blocker**。

---

## 2. P0 — PIPL / 上架前必修 (5 项)

| # | 项 | 状态 | 证据 |
|---|----|------|------|
| P0-1 | **AliyunSmsProvider.send() 真接** | ❌ UnimplementedError | `lib/core/data/services/sms_service.dart:156-160` throw + R55 plan 仍卡"法务 1-2 月模板审核 + 阿里云 AccessKey 申请"。release 模式 `validateForRelease` 框架已就绪,send() 阻塞整个失联通知核心价值承诺。 |
| P0-2 | **联系人 consentConfirmedAt 字段** | ❌ schema 未加 | `lib/presentation/pages/setup/setup_legal_dialog.dart:21` 注释待 R59+;`lib/` 0 hit grep。严格 PIPL §13 单独同意需联系人回 Y 确认,软实做 (用户主动告知) 风险等级中,4 store 上架审核可能打回。 |
| P0-3 | **5 厂商 push SDK 接入** | ❌ 0 hit pubspec | docs/SMS_PROVIDERS.md 提到小米/Huawei/OPPO/Vivo/Meizu 默认杀进程,送达率 ≈ 5%,自检卡 + 引导已修但**底层不通**。 |
| P0-4 | **3 份法务 markdown 律师过审** | ❌ 全部 v0.22/v0.24 草稿 | `assets/legal/privacy_policy.md:3` "未经律师过审" / `user_agreement.md:3` 同款 / `sensitive_data_consent.md:3` 同款 + 3 处邮箱 `privacy@chroniccare.app` `support@chroniccare.app` TODO 占位,上 store 前必修。 |
| P0-5 | **`check_sms_release_ready.py` warn → fail** | ⚠️ R58 降级 | scripts 仍 warn-only,v1.0 升 hard fail 之前 release 模式可能漏配 SMS provider。 |

---

## 3. P1 — i18n / 术语 / 修真漏洞 (6 项)

| # | 文件:行号 | 描述 | 修法 |
|---|----------|------|------|
| P1-1 | `lib/presentation/pages/home/home_page.dart:155, 324` | **真 bug**: `action: '⚠️ ${result.displayMessage}'` 用 R61 新 getter 但**返 i18n key 字符串**(非翻译值),用户实际看到 "⚠️ safetyCheckResultAlerted"。R61 dartdoc 明确说"UI 改用 `displayMessageL10n(l10n)`" | 改 `result.displayMessageL10n(l10n)`,home_page 已有 `l10n` 变量,1 行修 |
| P1-2 | `lib/core/data/services/reminder_scheduler.dart:217-230` | 整段 SMS 模板 5 行 hardcode 中文 (`'你的家人'` / `'【慢病管家】$name 已 $daysSince 天没打卡。'` / `'常吃药: ...'` / `'—— 这是一条自动提醒,请勿回复'`),跟 R57 抽 strings.dart 模式不一致 | 抽到 `Strings.careSmsBody()` / `Strings.careSmsFooter()`,跟 email_template 同款 |
| P1-3 | `lib/core/data/services/snooze_manager.dart:83-84` | `'吃药提醒'` / `'到点提醒你吃药打卡'` 重复 `Strings.notifChannelMedicationName/Desc` | 改 `Strings.notifChannelMedicationName/Desc` (const 已存在) |
| P1-4 | `lib/core/data/utils/phone_validator.dart:161-169` | 5 行 hardcode 区域名 (`'中国大陆' / '中国香港' / '中国澳门' / '中国台湾' / '国际'`) | 走 ARB `phoneRegion{Cn|Hk|Mo|Tw|International}` 5 新 key (R57 风格) |
| P1-5 | `lib/presentation/pages/setup/setup_page.dart:431` | `action: '完成设置'` 硬编中文,应该走 l10n (`commonActionSave` 已存在) | 1 行改 `l10n.commonActionSave` |
| P1-6 | `lib/core/data/services/notification_service.dart:370` | `'从未打卡'` 兜底 hardcode,R61 主流程已走 `_resolveSafetyAlertBody` 3 态分流,**但这行 old branch 未走 l10n** | 走 `l10n.safetyAlertLastCheckInNever` 新 key (R61 P0-3 修真边界) |

---

## 4. P2 — 术语 / 标点 / 文档一致性 (4 项)

| # | 项 | 证据 | 修法 |
|---|----|------|------|
| P2-1 | **"App" 术语混用** | terminology.md §2 R60 plan ⏳ 14 处 `app_zh.arb` (50/96/120/256/286/290/300/808/813/818/1130/1135/1138/1152/1163) "App" 未改"本应用"/"慢病管家" | R60 计划加 `lib/core/l10n/terms.dart` 集中器 + `check_zh_terms_consistency.py` 守门员 |
| P2-2 | **隐私政策 §0.5 "App" vs §10/11 "本 App"** | `assets/legal/privacy_policy.md:11, 28` 2 处用 "App",§10/§11 用 "本 App" — 跟 terminology §2 规则不一致 | 统一"本应用"(对外正式法律文档) |
| P2-3 | **树洞录音启用时间错位** | `sensitive_data_consent.md:49` 标"2026-07 起启用",但 v0.27 round 60 才真落地 (git log: 最近的 vent 加密 + audio 加密是 R57 批次) | 标"v0.27 起启用"或"2026-07 后期",跟代码 commit 时间对齐 |
| P2-4 | **`displayMessage` 旧 getter 留 compat 风险** | safety_watch_service.dart:308-315 dartdoc 说"data 层 0 flutter 仍用 displayMessage 兼容老 caller",但 home_page 漏改导致 UX bug (见 P1-1) | R62 加 deprecation 注释 + 修 home_page + 后续 R63 删旧 getter |

---

## 5. 已修项 (R57-R61 spzh 修真,维持)

- ✅ `safety_watch_service.dart` 8 个 @Deprecated facade 删,R61 P1-12 拆分收尾,`safetyConfigServiceProvider` 新加
- ✅ `safety_watch_service.displayMessageL10n(l10n)` 8 kind i18n 走 ARB (zh/en/zh_Hant 全)
- ✅ `notification_service.showSafetyAlert` 3 态分流 (sent / mocked / failed) + SmsDispatchOutcome record + l10n
- ✅ `medication_unit_label.dart` R61 P2 走 ARB (`medicationUnitMg` / `medicationUnitTablet`)
- ✅ `setup_page._kLegalVersion` PIPL §14 recordConsent 已写库
- ✅ `setup_step_welcome` CheckboxListTile `_contactConsentConfirmed` 软实做门控
- ✅ 半角斜杠 SSRI / SNRI → SSRI ／ SNRI (R59 修真 3 处)
- ✅ 半角省略号 ... warn-only (45 violations,flutter gen 限制,合理)
- ✅ zh_Hant 100% 跟 OpenCC s2tw 一致 (check_zh_hant_consistency 全绿)
- ✅ PUA 0 hit (check_no_pua 全绿)
- ✅ vent 0 hit 跨 trend/assessment/CareEngine/SafetyWatch/notification/PDF/email
- ✅ schemaVersion 14 完整 14 段 if migration
- ✅ commit 风格 273/218 (80%) 符合 `<version> round <N>: <title>`,R14+ 修真后 100% 符合,中文 commit 主体,0 emoji

---

## 6. 16 守护脚本全跑 (R61 修真后)

| # | 脚本 | 状态 |
|---|------|------|
| 1-15 | check_arb_keys / check_changelog / check_cross_feature / check_datetime_race{,_2} / check_drift_namespace / check_fullwidth_punctuation / check_legal_consent / check_no_hardcoded_utc / check_no_pua / check_orphan_arb_keys / check_sms_release_ready / check_strings_hardcoded / check_widget_dispose / check_zh_hant_consistency | 14 ✅ + 1 ⚠️ (sms_release_ready warn-only R58 降) + 1 ⚠️ (fullwidth_punctuation 45 半角省略号 warn) |
| 16 | dart scripts/check_all.dart | ✅ 4 层纯度 + entity↔table 1:1 + shared ≥2 层 |

---

## 7. dartdoc / 命名 / 注释质量抽查

- ✅ `safety_watch_service.dart:74-83, 247-250, 296-307, 309-326` 多段 dartdoc 解释 R57 拆 sub + R61 修真细节,跟代码版本号锚定
- ✅ `main.dart:38-71` 启动顺序 6 步骤注释清晰
- ✅ `setup_legal_dialog.dart:1-25` 完整说明 R58 文档化 + R59+ 计划 + 守门员豁免
- ✅ `medication_unit_label.dart:1-15` 解释为什么不放 core/l10n/strings.dart (domain 0 flutter 边界)
- ✅ 类名 / 方法名 / 私有 `_` 前缀 / 文件名 全部符合 AGENTS 命名表
- ⚠️ `setup_page.dart:33` `_kLegalVersion = 'v0.21-2026-07-20'` 是 const 写死,无 auto bump 提醒,跟 version 升级容易脱节。`pubspec.yaml` 改时人工同步

---

## 8. 推荐修真优先级 (round 62+)

1. **P0**: 法务 3 份 markdown 律师过审 + 邮箱 TODO 占位替换 (上 store 前必修,跟 PIPL §54 审计相关)
2. **P0**: `AliyunSmsProvider.send()` 真接 (R55 80-120h 外部依赖,需 1-2 月前置)
3. **P1**: home_page.dart:155, 324 改 `displayMessageL10n(l10n)` (1 行,真 bug,用户能看见 key 字符串)
4. **P1**: reminder_scheduler.dart:217-230 抽 Strings.careSmsBody 5 行 hardcode (跟 R57 风格一致)
5. **P1**: snooze_manager / phone_validator / setup_page / notification_service 4 处 1-5 行硬编修真 (各 5-15 min)
6. **P2**: terminology R60 计划: 14 处 "App" → "本应用" + 新 `lib/core/l10n/terms.dart` + `check_zh_terms_consistency.py` 守门员
7. **P2**: `displayMessage` 旧 getter 标 @Deprecated + R63 删

---

## 9. 与历史 spzh v0.27 R60 报告对比

v0.27 R60 spzh 报告 45KB 覆盖 30 个 bug 模式 + 16 守护脚本全跑 + i18n/i18n completeness + PIPL 软实做。本 round 62 重点:修真 R57-R61 落地状态 + R60 working tree 修真 + 修真漏洞 (P1-1/2/3/4/5/6) + 隐私法务文档完整性 + 术语一致性。**没发现新 P0 类别**,主要是修真落地漏的尾巴。
