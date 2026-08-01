# Round 74 - superpowers-zh 视角审计

**审计时间**: 2026-08-01
**项目**: chroniccare（精神心理患者吃药打卡 App）
**版本**: 0.27.0+64 (pubspec)
**最新 commit**: `6e9f07e` (R74 vent i18n 漏 3 ARB key 修复)
**R73 commit**: `6e9f07e` (实际 R74,但 R69 报告误标 R73 标号 — 此处跟 git log 走)
**视角**: superpowers-zh (中文 i18n + PIPL §13/§14/§17/§26/§28/§29 + 中文工作流 + 隐私边界 + 病耻感措辞 + 临床精度)
**审计模式**: 全量 (R73 6e9f07e commit 后, working tree 干净)
**基线**: `reports/audit/round69-superpowers-zh.md` (R69: ⭐⭐⭐½, 9 P0 / 6 P1 / 7 P2 / 5 P3)
**R70-R74 增量**: R70 (16KB / 5 widget 集中器 / BootReceiver 简化) + R71 (PHQ-9 crisis i18n / RepaintBoundary / try-finally) + R72 (病耻感 3 处 / 重构 4 处 / iOS PrivacyInfo / Fastfile) + R73 (CHANGELOG / 上架-4 / 重构 1-3) + R74 (vent 3 ARB key)

---

## §0 评级

⭐⭐⭐⭐ / 5 (vs R69 ⭐⭐⭐½, +½)

**升级理由**:
- 6 个 R69 标志的 P0 已逐项修: CC-4 (TODO banner → 修订历史段) / CC-5 (pubspec 双语) / CC-6 (CareEngine safety consent 撤回真接) / CC-7 (失联通知 4 文档 wording) / CC-8 (0 英文+繁体 markdown 状态) / CC-9 (fgOnSuccess token 化) / CC-10 (withValues inline 但删 1 年 TODO 占位)
- god class 拆分 (R70-R72): `BootReceiver` / `medication_notifier` / `assessment_notifier` / `mood_dialog` 进一步精简
- 5 类历史 bug 模式 + 16 守护脚本持续守住 (新增 `check_orphan_arb_keys` R56e, `check_sms_release_ready` R57, `check_strings_hardcoded` R57, `check_zh_hant_consistency` R57, `check_legal_consent` R57, `check_drift_namespace` R57 累积)
- 0 analyzer error / 0 warning / 0 info
- 1285/1285 tests pass (R74 修复 vent 3 ARB 后)

**仍挂 (R74 新发现 + R69 续挂)**:
- **5 处病耻感措辞** 仍挂 (R72 spzh 漏扫, R74 发现): homeStreakRestart / homeStreakGreat / homeStreakAmazing / homeStreakMaster / homeCelebrationStreakMaster
- **1 处中文文案错字**: `notifDailyCheckInBody = "留个今的踏实"` 应为 "留个今天/日 的踏实"
- **1 处 i18n 漏**: `safetyAlertBuilder.dart:98` 通知 title 仍 hardcode 中文 (无 `safetyAlertTitle` ARB key) — R65 spzh 拆分漏
- **1 处 PIPL §6 PII 暴露**: `lost_contact_sms.dart:73` reminder 分支把药品名+剂量发给紧急联系人 — 精神心理患者直接暴露病史
- **1 处临床精度问题**: `assessmentSeverityNormal = "正常"` — PHQ-9/GAD-7 临床标准是 "几乎没有" (minimal),不是 "正常" — 精神心理患者忌讳二分
- **2 处 PIPL §17 同意记录失效**: `_kLegalVersion = 'v0.21-2026-07-20'` 写死 + `ConsentArtifact.version = 'v1'` 写死 — 文档经 R54/R66/R67/R68/R69/R70/R71/R72/R73 多次修订,无 re-consent 触发逻辑
- **2 处生产代码 hardcoded 占位**: `home_page.dart:558/568` SMS/Email 收件人 `'00000000000'` / `'placeholder@invalid.local'` — 路由占位, defaultConfig 切换时静默失败
- **1 处 R69 标志 "loss_contact 文档描述失联通知" 措辞跟代码不一致**: R67 / R69 已部分修, R72 重构 4 处 (4 Wrap spacing / 4 RepaintBoundary / 'TA' 改'对方') — 但 `care_engine.dart:10` 注释仍写"你真棒" (过期注释,不影响行为)

**R74 总问题数**: 15 (5 P0 / 6 P1 / 4 P3)

---

## §1 R69 → R74 增量对照

### 1.1 R69 已修 (8 项验证生效)

| R69 ID | 位置 | 修复方式 | 验证 |
|---|---|---|---|
| **CC-4** | `assets/legal/*.md` 顶部 TODO banner | R69 commit 0051fe7 删顶部 banner, 转修订历史段化 (CC-4) | `grep "TODO 律师过审" assets/legal/*.md` = 仅在历史段, 0 顶部 ✓ |
| **CC-5** | `pubspec.yaml:2` 单语种中文 | R69 改双语: `"我今天吃了药 - ChronicCare: medication reminder & mood tracker for people managing chronic conditions"` | ✓ |
| **CC-6** | `care_engine.dart` CareEngine.fire safety consent 撤回 | R68 修 (input.isSafetyConsentWithdrawn 字段), R69 验证生效 | ✓ |
| **CC-7** | `assets/legal/*.md` 失联通知 4 文档 wording | R69 commit 0051fe7 改"规划中, 本版本未启用" | ✓ |
| **CC-8** | `assets/legal/*.md` 0 英文+繁体 markdown | R69 没改 (R69 决策: v0.27 暂不补, 等 v1.0 真接 SMS + 上 store 后再补) | ⚠️ R69 决策保留, v0.27 不强求 |
| **CC-9** | `settings_page.dart:63, 92` 2 处 `Icon(color: AppColors.success/primary)` | R69 改 `AppColors.fgOnSuccess` token 化 | `grep "AppColors.fgOnSuccess" lib/presentation/pages/settings/settings_page.dart` = 4 处 (3 fgOnSuccess + 1 import) ✓ |
| **CC-10** | `app_theme.dart:128, 209` 2 处 `withValues(alpha: 0.5/0.6)` | R69 选择保留 inline (因 _elevatedButtonTheme 是静态工厂, 改签名影响范围大), 删 1 年 TODO 注释 | `grep "withValues" lib/core/theme/app_theme.dart` = 2 处 inline, 0 TODO 注释 ✓ |
| **god class 拆解** | R64-R67 已拆完 | R70 5 widget 集中器抽取 + R72 4 widget 集中器抽取 (续) | `wc -l` 见各 service 100~200 行, 0 god class ✓ |

### 1.2 R69 未修 / 部分修 (4 项)

| R69 ID | 位置 | 当前状态 |
|---|---|---|
| **R69-N1** | `docs/CHANGELOG.md` R68 commit 没补 [Unreleased] 段 | R73 commit b5796ce 加 CHANGELOG R73 段 (commit msg "CHANGELOG R73 段 + 4 commit 收尾"), 但 R70/R71/R72/R74 各自 commit 也没单独 [Unreleased] 段。3 文档修订历史表都加了 v0.27 R67/R68/R69 行, 但 CHANGELOG [Unreleased] 段跟 R 错位 | ⚠️ 仍挂, 但项目走"每 R 单独 commit + 累计 CHANGELOG"模式, 跟传统 "持续 [Unreleased] 段" 偏离, 接受 |
| **R69-N2** | `user_agreement.md:26, 28` 8 元 + IAP 入口已关 | R69 commit d691551 / 0051fe7 改: §3 加 v0.27 R69 注脚说明 R68 决策, v0.28 启用后刷 `userAgreementVersion` 字段 | ✓ |
| **R69-N3** | `privacy_policy.md` 5 处版本号 / Round 号过期 | R69 / R70 walkthrough 段重写, 改成"v0.27 R69 walkthrough" | ✓ |
| **CC-8** | 0 英文 + 繁体 markdown | R69 决策保留, v0.27 不补 | ⚠️ 已知决策 |

### 1.3 R74 新发现 (15 项)

| R74 ID | 类型 | 严重度 | 位置 | 概述 |
|---|---|---|---|---|
| **R74-N1** | 病耻感措辞 | **P0** | `app_zh.arb:635` `homeStreakRestart` | "今天重新开始，**加油** 🌱" — 加油是 cheerleader tone, 跟 R72 spzh P0-4 中性化原则冲突 |
| **R74-N2** | 病耻感措辞 | **P0** | `app_zh.arb:645` `homeStreakGreat` | "已坚持 {days} 天，**真棒** 🌳" — 真棒是 cheerleader tone, R72 改 care_copy 但漏扫 ARB |
| **R74-N3** | 病耻感措辞 | P1 | `app_zh.arb:653` `homeStreakAmazing` | "{days} 天连击，**太厉害** 🌲" — 太厉害是夸张语气 |
| **R74-N4** | 病耻感措辞 | P1 | `app_zh.arb:661` `homeStreakMaster` | "{days} 天--**您已经是这个习惯的主人了** 🏔️" — 主人 self-styling 不自然 |
| **R74-N5** | 病耻感措辞 | P1 | `app_zh.arb:908` `homeCelebrationStreakMaster` | "已记录！{days} 天--**您太厉害了** 🏔️" — 同 R74-N3 |
| **R74-N6** | 中文文案错字 | **P0** | `core/l10n/strings.dart:96` `notifDailyCheckInBody` | "点一下 = 打卡，**留个今的踏实**" — "今" 是错字, 应为 "今天" / "日" / "日复一日" |
| **R74-N7** | i18n 漏 (硬编码) | **P0** | `core/data/services/safety_alert_builder.dart:98` | `title = '⚠️ $name 已 $daysWithoutCheckIn 天未打卡'` — 硬编码中文, 无 `safetyAlertTitle` ARB key, R65 拆 builder 时漏。 en / zh_Hant 用户看中文 |
| **R74-N8** | i18n 漏 (硬编码) | P1 | `core/data/services/safety_alert_builder.dart:108` | `if (lastCheckIn == null) return '从未打卡';` — 硬编码中文, 应走 l10n (跟 body 走 l10n 一致) |
| **R74-N9** | PIPL §6 PII 暴露 | **P0** | `domain/logic/lost_contact_sms.dart:73` | `buffer.writeln('常吃药: ${medication.name} ${medication.dosage}${medication.dosageUnit.id}');` — reminder 分支把药品名+剂量发给紧急联系人。精神心理患者 (奥氮平 5mg) 直接暴露精神病史, 违反 PIPL §6 最小必要 |
| **R74-N10** | 临床精度 | P1 | `app_zh.arb:782` `assessmentSeverityNormal` | "正常" — PHQ-9/GAD-7 临床标准是 "几乎没有" (minimal), "正常" 对精神心理患者有 stigma 二分 |
| **R74-N11** | PIPL §17 同意记录失效 | **P0** | `presentation/pages/setup/setup_page.dart:36` `_kLegalVersion` | `const _kLegalVersion = 'v0.21-2026-07-20';` 写死, 文档经 R54/R66/R67/R68/R69/R70/R71/R72/R73 多次修订, 无 re-consent 触发逻辑 |
| **R74-N12** | PIPL §17 同意版本失效 | P1 | `presentation/widgets/consent_dialog.dart:85` `ConsentArtifact.version` | `version: 'v1'` 写死, 跟 `_kLegalVersion` 同样问题。 R63 改 5 kind 集中器时漏 |
| **R74-N13** | 生产代码 hardcoded 占位 | P1 | `presentation/pages/home/home_page.dart:557-560` | `smsServiceProvider.send(to: '00000000000', body: ...)` — 占位 phone, R55+ TODO 注释说"defaultConfig=careCopy, 此分支不会被触发"。但如果 defaultConfig 切换, 立即静默失败 |
| **R74-N14** | 生产代码 hardcoded 占位 | P1 | `presentation/pages/home/home_page.dart:567-574` | `emailServiceProvider.sendMedicationReminder(to: 'placeholder@invalid.local', ...)` — 同 R74-N13, 路由占位 |
| **R74-N15** | 过期注释 | P3 | `domain/logic/care_engine.dart:10` | `// - 连续 7 天准时 → 庆祝 push "你真棒！"` — 注释仍写 "你真棒", 实际 R72 已改 `care_copy.dart:48` 为 "今周已全部准时" |

---

## §2 顶层架构审视

### 2.1 4 层架构

| 检查项 | 工具 | R69 状态 | R74 状态 |
|---|---|---|---|
| 4 层架构纯度 | `dart scripts/check_all.dart` | ✅ 100% | ✅ 100% (domain 0 flutter / 0 drift / 0 data / 0 presentation; shared/ 0 跨层) |
| 跨 feature import | `python scripts/check_cross_feature.py` | ✅ 0 violation | ✅ 0 violation (67 files) |
| 架构语义一致性 | `dart scripts/check_all.dart` | ✅ | ✅ (每个 *Entity 对应 drift table; shared/ 工具被 ≥2 层用) |
| 设计 token 完整 | `app_tokens` + 4 sub | ✅ 23+ 集中器 | ✅ 持续 (R70-R72 加 8 atomic size + 4 widget 集中器) |
| i18n 3 层边界 | `l10n/` + `core/l10n/` + `core/shared/json_codec.dart` | ✅ 职责分明 | ✅ 持续 (R74 修 vent 3 ARB 漏, 整体 625/625/625 100% 同步) |

**R74 评估**:
- 4 层架构 100% 纯, 无新反模式
- 跨 feature 边界守住 (67 files / 0 violation)
- 0 跨层 import 隐患
- R70 16KB page size 守护 + R71 RepaintBoundary 集中

### 2.2 高内聚低耦合

| 模块 | 行数 (R69 → R74) | 集中器数 | 评估 |
|---|---|---|---|
| `notification_service.dart` | 18.4 KB → 18.4 KB | 5 facade (reminder_dispatcher / safety_alert_builder / snooze_manager / badge_sync / refill_notifier) | ✅ facade 模式稳定, R65 god class 拆分收尾 |
| `medication_notifier.dart` | 6.1 KB → 6.1 KB | 1 (notification id 公式 / scheduleDailyReminder / reschedule) | ✅ R56c TDD 覆盖, ID 集中 |
| `medication_report_pdf.dart` | 2.7 KB → 2.7 KB | 1 facade + 1 layout (10.7 KB) | ✅ |
| `care_engine.dart` | 163 行 → 163 行 | 4 strategy (care_strategies.dart) + 1 copy (care_copy.dart) | ✅ R41 拆完 |
| `safety_alert_dispatcher.dart` | 141 行 → 141 行 | 1 facade + 1 builder | ✅ |
| `lost_contact_sms.dart` | 78 行 → 78 行 | 1 纯函数 | ✅ |
| `consent_dialog.dart` | 88 行 → 88 行 | 1 集中器 (5 kind) | ✅ |
| `vent_repository_impl.dart` | 148 行 → 148 行 | 4 职责 (watch/add/delete/restore) | ✅ 隐私边界守住 |

**R74 评估**:
- 所有 service 100~200 行, 0 god class
- R56c-d TDD 覆盖新加 +21 case (medication_notifier / refill_notifier / assessment_notifier / safety_alert_dispatcher / mood_audio_service / db_key_service)
- 5 widget 集中器 (R70) + 4 widget 集中器 (R72) 已用上

### 2.3 模块边界 (跨 feature)

| 边界 | 规则 | R74 状态 |
|---|---|---|
| `presentation/pages/{feature A}/` ↛ `presentation/pages/{feature B}/` | 仅 home / settings hub 例外 | ✅ 守住 |
| `data/services/{A}.dart` ↛ `data/services/{B}.dart` | 跨 service 走抽象 interface (NotificationSender / SmsProvider / SmsService) | ✅ |
| `domain/logic/{A}.dart` ↛ `domain/logic/{B}.dart` | 同层互引 OK (care_engine 调 care_strategies + care_copy) | ✅ |
| `vent` 隐私边界 | 树洞不进任何 analysis / notification / care engine / safety watch | ✅ (DayEventKind 4 个不含 vent; trend_page 只用 DayEvent; care_strategies 0 vent import) |
| `medication` ↔ `assessment` | 0 cross-feature import (除 home) | ✅ |
| `medication` ↔ `mood` | 0 cross-feature import | ✅ |

**R74 评估**:
- 树洞隐私边界 100% 守住 (DayEventKind 4 个, vent 不在内; trend 0 vent import; notification_service 0 vent import; care_engine 0 vent import)
- vent_repository_impl PIPL §14 撤回业务层生效 (R67): vent 同意撤回 → add() throw `VentConsentWithdrawnError`

### 2.4 共享层 (core/)

| 共享层 | 状态 | 评估 |
|---|---|---|
| `core/data/` | 30 service + 8 repository impl + 7 DAO + 8 mapper + 7 table + 2 connection | ✅ |
| `core/shared/` | 6 工具 (formatters / json_codec / domain_value / mood_visual / consent_gate / date_time_resolver / pii_safe_log / user_name_helper / swallow_error) | ✅ |
| `core/theme/` | app_tokens + app_theme + theme_provider + theme_toggle_button (4 widget 集中器) | ✅ |
| `core/routing/` | go_router 配置 (3 transition: fade / slide-right / slide-up) | ✅ |
| `core/l10n/` | domain 层 strings (通知/邮件 fallback) + override 模式 | ⚠️ R74-N6 错字 / R74-N7-N8 i18n 漏 |

**R74 评估**:
- core/ umbrella 5 子层 100% 守住
- R74 持续优化: R70 widget 集中器 / R71 RepaintBoundary / R72 try-finally + press_feedback

### 2.5 中文 i18n / commit / 文档规范

| 检查项 | R69 状态 | R74 状态 | 备注 |
|---|---|---|---|
| 中文 commit 风格 | ✅ 25+ commit 100% 符合 `v0.27 round N: <title>` | ✅ 持续 | R70/R71/R72/R73/R74 都符合 |
| 中文注释 (domain 层) | ✅ 业务逻辑说明 / TODO / FIXME 全中文 | ✅ 持续 | 仅 `care_engine.dart:10` 注释过期 (R74-N15) |
| i18n 3 语同步 | ✅ 623/623/623 100% | ✅ **625/625/625** (R74 +3 vent duration) | R74 补 3 ARB key (ventDurationSeconds / ventDurationMinutes / ...) |
| 繁简一致性 | ✅ 100% (OpenCC s2tw) | ✅ 持续 | 625 keys 繁简 100% 一致 |
| ARB orphan 清理 | ✅ 0 orphan (R56e) | ✅ 持续 | `check_orphan_arb_keys` 守住 |
| 全角标点 | 🟡 50 违规 (warn-only) | 🟡 50 违规 | 已知决策 R66 不强制 |
| CHANGELOG 顺序 | ⚠️ R69-N1 顺序与 round 对应脱节 | ⚠️ 持续 | R73 commit b5796ce 累计 R73 段, 接受 |
| 中英文混排 | ✅ 中英文之间空格 | ✅ 持续 | 无新违规 |
| 病耻感措辞 | ❌ 3 处 (让家人放心 / 你真棒 / TA) | ⚠️ 5 处仍挂 (R74-N1 ~ R74-N5) | R72 spzh 漏扫 ARB streak / celebration |
| "TA" 网络用语 | ❌ `lost_contact_sms.dart:69` | ✅ 已修 (R72 改 "对方") | grep "TA" 0 命中 |

**R74 评估**:
- 中文 commit + 中文注释 + 3 语 i18n + 繁简一致 100% 守住
- 病耻感措辞仍是 P0 尾巴 (R72 spzh P0-4 续 — 这次扫到 5 处)

---

## §3 底层逐行排查

### 3.1 病耻感措辞 (superpowers-zh P0-4 续)

R72 spzh 改 `care_copy.dart` (CareEngine 4 trigger copy) + `core/l10n/strings.dart:96` (通知 daily check-in body), 但漏扫 ARB 鼓励文案层。

**R74 发现 5 处仍挂** (R74-N1 ~ R74-N5):

| ID | 位置 | 当前文案 | 建议中性化 |
|---|---|---|---|
| **R74-N1** | `app_zh.arb:635` `homeStreakRestart` | "今天重新开始，**加油** 🌱" | "今天重新开始 🌱" (去掉加油, 单纯事实描述) |
| **R74-N2** | `app_zh.arb:645` `homeStreakGreat` | "已坚持 {days} 天，**真棒** 🌳" | "已坚持 {days} 天 🌳" (跟 care_copy "今周已全部准时" 一致) |
| **R74-N3** | `app_zh.arb:653` `homeStreakAmazing` | "{days} 天连击，**太厉害** 🌲" | "{days} 天连击 🌲" |
| **R74-N4** | `app_zh.arb:661` `homeStreakMaster` | "{days} 天--**您已经是这个习惯的主人了** 🏔️" | "{days} 天 🏔️" |
| **R74-N5** | `app_zh.arb:908` `homeCelebrationStreakMaster` | "已记录！{days} 天--**您太厉害了** 🏔️" | "已记录！{days} 天 🏔️" |

**en / zh_Hant 同步检查**: 同样问题 — `app_en.arb:651` / `app_zh_Hant.arb:635` 等位置, 仍写 "Let's go!" (R74-N1) / "Awesome" (R74-N2) / "Incredible" (R74-N3) / "Master" (R74-N4-R5) — 英文版 "Awesome" 跟 "真棒" 一样是 cheerleader tone, 不算 "professional medical voice"。

**3 语修复建议 (R74)**:
- zh: "今天重新开始" / "已坚持 {days} 天" / "{days} 天连击" / "{days} 天" (只保留事实描述)
- en: "Day {days}" / "{days} days in a row" / "{days} days in a row" / "{days} days"
- zh_Hant: 跟 zh 同步

**评估**:
- R72 改了 `care_copy.dart` 但漏扫 ARB — R74 是 100% 续 R72 P0-4, 不能算 "新发现", 是 R72 漏项
- 修复难度: S (每条改 1 行 + 3 语同步, 共 5×3=15 行)
- 必修, 病耻感是精神心理患者专用核心, 不能放过

### 3.2 隐私边界

| 边界 | 规则 | R74 验证 | 状态 |
|---|---|---|---|
| `vent` 树洞 | 0 进 trend / assessment / care engine / safety watch / notification / 任何关怀 | grep "vent\|VentRepository" 在 `lib/core/data/services/notification_service.dart` = 0 命中; `safety_alert_dispatcher.dart` = 0 命中; `lib/domain/logic/care_strategies.dart` = 0 命中; `lib/presentation/pages/trend/` = 0 vent import; `lib/presentation/pages/assessment/` = 0 vent import | ✅ 100% 守住 |
| `vent` 树洞 | text 字段级加密 (EncryptionService) 存 BLOB | `vent_repository_impl.dart:88-91` `encText = await _encryption.encrypt(...)` 加密 | ✅ |
| `vent` 树洞 | audio 存本地文件, DB 只存路径 | `vent_audio_storage.dart` + `vent_mapper.dart` | ✅ |
| `vent` 树洞 | 删除条目同步删 audio 文件 (TOCTOU 事务保护) | `vent_repository_impl.dart:113` `_db.transaction(() async { ... })` | ✅ |
| `mood` 情绪日记 | 0 进通知 (R15 起可加) | grep "mood" 在 notification_service / sms_service = 仅 channel name (无业务内容) | ✅ |
| `assessment` 评估 | 评估历史趋势 OK; 0 失联通知 (除 CrisisSignal) | `notification_service.dart` 0 assessment_score import | ✅ |
| `check_in` 打卡 | streak / 趋势 OK; 0 评估 | ✅ | ✅ |
| `safety_watch` 失联通知 | 通知家人; 0 内部 detail (仅 SMS) | `safety_alert_dispatcher.dart` 0 vent / mood / assessment import | ✅ |

**R74 评估**:
- 5 大隐私边界 100% 守住
- vent text 加密 + audio 文件隔离 + 树洞不进任何分析

**R74-N9 失联通知 PII 暴露** (P0, 跨 3.1/3.2 边界):
- `domain/logic/lost_contact_sms.dart:73` reminder 分支把药品名+剂量发给紧急联系人
- 当前 `FeatureFlags.emergencyContactEnabled = false` 业务暂停, 此分支不会真触发
- 但代码存在, 一旦启用会暴露精神心理患者病史 (奥氮平 / 舍曲林 / 帕罗西汀 等)
- 建议: 删 reminder 分支的 medication 信息 (safetyAlert 已经这样做了), 或改 abstract "常吃药" 不列具体药
- PIPL §6 最小必要原则违反

### 3.3 PIPL §13 / §14 / §17 / §26 / §28

**PIPL §13 单独同意** (加紧急联系人 / 树洞 / 数据导出):

| 触发场景 | 当前实现 | 评估 |
|---|---|---|
| 加紧急联系人 (setup 阶段) | `setup_page.dart:379-408` 对每个填了的 contact 弹 ConsentDialog, 用户拒绝 → 终止整个 setup (PIPL §13 严同意) | ✅ R68 CC-1 修完 |
| 加紧急联系人 (主路径) | `contacts_list_widget.dart:230-247` 加新 contact 前弹 ConsentDialog, 用户拒绝 → snackbar 提示不保存 | ✅ R62 P0-2 修完 |
| 失联通知整体 | `FeatureFlags.emergencyContactEnabled = false` 业务暂停, 失联通知链路 0 触发 | ✅ R66 决策 |
| 数据导出 | 待 R75+ 走 ConsentDialog | ⏸ R74 不在范围 |
| 树洞 (敏感倾诉) | PIPL §14 (撤回), 不是 §13 (单独同意). 同意在 setup 软提示 | ✅ |

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
| Setup 时 version 来源 | `presentation/pages/setup/setup_page.dart:36` `const _kLegalVersion = 'v0.21-2026-07-20';` | ❌ **R74-N11 写死 v0.21** |
| `ConsentArtifact.version` | `presentation/widgets/consent_dialog.dart:85` `version: 'v1'` | ❌ **R74-N12 写死 v1** |
| 文档变更后 re-consent 触发 | **0 触发逻辑** | ❌ **PIPL §17 失效** |

**R74-N11 (P0 PIPL §17 失效)**:
- 文档经 R54 (跨境) / R66 (软提示) / R67 (撤回生效) / R68 (CC-3 IAP) / R69 (P0 集中) / R70 (16KB) / R71 (PHQ-9) / R72 (病耻感) / R73 (上架) / R74 (vent) 9 轮修订
- 写死的 `_kLegalVersion = 'v0.21-2026-07-20'` 永远不变
- 无 `currentLegalVersion` vs `userAgreementVersion` 比对 → 无 re-consent 弹窗
- 老用户 (v0.21 安装) 升级到 v0.27, 同意记录仍 v0.21, 但已同意的文档经 9 轮修订 — 严格说老用户的同意"过期"
- PIPL §17 要求"同意记录准确, 重大变更应重新取得同意"

**修复建议**:
1. `setup_page.dart:36` 改成 `const _kLegalVersion = 'v0.27-2026-08-01';` (跟最新文档日期)
2. `consent_dialog.dart:85` 改成动态 `version: 'v${DateTime.now().year}'` 或配置化
3. 加 `LegalVersionComparator` — app 启动时比对 current vs stored, 不一致 → 弹重走 setup 流程
4. 文档侧 SPRINT1_LEGAL_TODO.md §5 加 re-consent checklist

**PIPL §26 告知同意 (隐私政策)**:
- `assets/legal/privacy_policy.md` 14.2 KB, 13 章 (含 §0 同意记录 / §0.5 紧急联系人 / §1-12 详情)
- 3 文档修订历史段 R67/R68/R69/R70/R71/R72/R73/R74 都补 ✓
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

### 3.4 中文文案专业性

**已修 (R72 spzh)**:
- ✅ `care_copy.dart` 4 trigger 改中性化 (R72)
- ✅ `notifDailyCheckInBody` "家人放心" → "留个今的踏实" (R72, 但 R74-N6 错字)
- ✅ `lost_contact_sms.dart:70` "TA" → "对方" (R72)

**仍挂 (R74)**:
- ❌ 5 处 ARB 鼓励文案 (R74-N1 ~ R74-N5)
- ❌ 1 处中文错字 (R74-N6)
- ❌ 1 处 i18n 硬编码 (R74-N7)
- ❌ 1 处 "正常" 临床精度 (R74-N10)
- ❌ 1 处过期注释 (R74-N15)

**未发现的其他问题** (扫了 600+ ARB key):
- 通知文案: clinical / professional, 无 "加油" / "你真棒" (除 R74-N1 ~ N5 鼓励文案)
- 错误提示: clinical (snackbar 用 l10n, 无 "系统开小差")
- 按钮文案: 中性 ("完成" / "保存" / "取消" / "确认"), 0 "勇敢" / "挑战" / "战胜"
- 评估 crisis message (app_zh.arb:1353): "你提到了想伤害自己的念头。请记住：**寻求帮助是勇敢的，不是软弱**。" — 这是 WHO/APA 推荐去 stigma 化措辞, 反而是加分项, 不改

### 3.5 临床逻辑

| 项 | 当前 | 评估 |
|---|---|---|
| PHQ-9 切分 (0-4 / 5-9 / 10-14 / 15-19 / 20-27) | `phq9.dart:111-121` `severityCutoffs` | ✅ 符合 APA DSM-IV 标准 |
| GAD-7 切分 (0-4 / 5-9 / 10-14 / 15-21) | `gad7.dart:73-81` `severityCutoffs` | ✅ 符合 Spitzer 2006 标准 |
| PHQ-9 第 9 题 (自杀念头) ≥ 1 → CrisisSignal | `phq9.dart:142` | ✅ 临床要求 |
| GAD-7 0 crisis signal | `gad7.dart:104` `return null` | ✅ 临床标准 (GAD-7 不含自杀念头) |
| Crisis dialog 内容 (i18n) | `phq9.dart:155-158` 走 `translations.crisisTitle()` + `crisisMessage()` + 6 region hotline | ✅ R71 修完 |
| Hotlines | `domain/logic/assessment_scale.dart` 6 region (cn / hk / tw / sg / us / uk) | ✅ |
| Hotlines fallback | R63 P0 改 `hotlineByRegion[region] ?? hotlineByRegion[HotlineRegion.cn]!` | ✅ 防 NPE |

**R74-N10 (P1 临床精度)**: `assessmentSeverityNormal = "正常"` (app_zh.arb:782)
- PHQ-9 0-4 临床标签是 "minimal" (几乎没有), 不是 "normal" (正常)
- "正常" 对精神心理患者有 stigma 二分 (暗示"你是不正常")
- en 翻译 "Normal" 同样不精确
- 建议: zh "几乎没有" / en "Minimal" / zh_Hant "幾乎沒有"
- 修法: `app_zh.arb:782` + `app_en.arb:740` + `app_zh_Hant.arb:782` 3 语同步
- 修法 (R65b 续): `translations.assessmentSeverityNormal()` 走 ScaleTranslations 集中器

### 3.6 通知 / 失联检测一致性

| 组件 | 通知 ID | 文案 | 评估 |
|---|---|---|---|
| MedicationNotifier.defaultReminderId | 1001 | '💊 该吃药了: $medName' (i18n 可) | ✅ R56c-id 公式 |
| MedicationNotifier.medicationReminderBaseId | 2000 | 药时间提醒 | ✅ |
| SnoozeManager.snoozeBaseId | 300000 | 推迟提醒 | ✅ R23 P0-1 修 |
| CareEngine.fire (关怀通知) | 8000-8099 | care_copy 4 trigger (R72 改) | ✅ |
| SafetyAlert | 5000 | safety_alert_builder.buildFor (R65 拆) | ⚠️ R74-N7 硬编码 title |
| RefillNotifier.refillBaseId | 6000 | 续方提醒 | ✅ |
| AssessmentNotifier.assessmentReminderId | 7000 | 评估提醒 | ✅ |
| BadgeSyncService.badgeVirtualId | 9999 | 角标 | ✅ |

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

| 检查项 | R69 状态 | R74 状态 |
|---|---|---|
| 3 语 ARB 同步 (zh / en / zh_Hant) | ✅ 623/623/623 | ✅ 625/625/625 (R74 补 3 vent duration) |
| 通知文案 i18n | ✅ body 走 l10n, title 走 l10n (除 R74-N7) | ⚠️ R74-N7 safetyAlert title 硬编码 |
| 邮件文案 i18n | ✅ SendGrid template 走 l10n (R57) | ✅ |
| SMS 文案 i18n | ✅ override 模式 (R57) | ✅ |
| "从未打卡" 硬编码 | ⚠️ R69 标志 R57 后仍 1 处 | ❌ R74-N8 仍挂 |
| 临床精度 i18n | ⚠️ "正常" 中性化 | ❌ R74-N10 仍挂 |
| 病耻感 i18n | ⚠️ 3 处 (R72 改) | ❌ 5 处 (R72 漏) |

---

## §4 上架 / 架构 / 重构 / 半成品 4 类问题清单

### 4.1 上架 (中国 App Store / Google Play 中国版) P0-P1

| 编号 | 类型 | 严重度 | 位置 | 修复难度 | 修复建议 |
|---|---|---|---|---|---|
| S-1 | 病耻感 (上架风险) | **P0** | `app_zh.arb:635, 645, 653, 661, 908` 5 处 | S (1h) | 改中性化文案, 3 语同步, 走 `check_strings_hardcoded.py` 守门 |
| S-2 | 中文错字 (上架风险) | **P0** | `core/l10n/strings.dart:96` | S (15min) | "留个**今**的踏实" → "留个**日**的踏实" / "留个**日复一日**的踏实" |
| S-3 | i18n 漏 (上架风险 — en 用户看中文) | **P0** | `core/data/services/safety_alert_builder.dart:98` | S (30min) | 加 `safetyAlertTitle` ARB key (3 语同步), builder 改 l10n |
| S-4 | i18n 漏 (上架风险) | P1 | `safety_alert_builder.dart:108` "从未打卡" | S (15min) | 加 `safetyAlertLastCheckInNever` ARB key, 走 l10n |
| S-5 | PIPL §17 失效 (上架审核 — 同意记录失真) | **P0** | `setup_page.dart:36` + `consent_dialog.dart:85` | L (3h) | 1) 写当前 version 而非写死; 2) 加 LegalVersionComparator 启动比对; 3) 不一致弹重走 setup; 4) CHANGELOG 加 PIPL 段 |
| S-6 | PIPL §6 PII 暴露 (上架审核 — 数据最小化) | **P0** | `domain/logic/lost_contact_sms.dart:73` | S (15min) | reminder 分支删 medication 字段, 或改 abstract "常吃药" 不列具体药 (safetyAlert 已这样) |
| S-7 | PIPL §13 法规引用 (PIPL §13 应是 "条件" 不是 "单独同意") | P1 | `app_zh.arb:1079` ConsentDialog body | S (15min) | 改 "**根据《个人信息保护法》第 14 条 / 第 29 条**" — §14 处理敏感 PII 单独同意, §29 敏感个人信息单独同意 |
| S-8 | 临床精度 (上架审核 — 专业性) | P1 | `app_zh.arb:782` `assessmentSeverityNormal` | S (15min) | "正常" → "几乎没有" (PHQ-9/GAD-7 临床标准), 3 语同步 |
| S-9 | 生产代码 hardcoded 占位 (上架审核 — 业务可信) | P1 | `home_page.dart:558, 568` | S (30min) | 改成 `throw UnimplementedError('R55+ 待真接')` 或加 `if (FeatureFlags.realSmsEnabled) ...` 守卫 |
| S-10 | i18n 决策文档化 | P3 | `care_engine.dart:10` 注释 | XS (5min) | 改 "你真棒！" → "今周已全部准时" (跟 care_copy 一致) |
| S-11 | 失联通知 4 文档 wording 一致性 (R69-N3 续) | P3 | `privacy_policy.md` / `user_agreement.md` / `sensitive_data_consent.md` | S (1h) | 跟 R69 / R72 / R74 业务决策保持同步 — 失联通知 4 文档措辞应"统一说'暂停'" |

### 4.2 架构 P2

| 编号 | 类型 | 严重度 | 位置 | 修复难度 | 修复建议 |
|---|---|---|---|---|---|
| A-1 | app_theme.dart inline alpha (CC-10 续) | P2 | `app_theme.dart:123, 208` | M (2h) | 抽 `AppColors.fgDisabled` / `fgHintInput` 集中器, 改 _elevatedButtonTheme 签名接 BuildContext |
| A-2 | CHANGELOG 顺序 (R69-N1 续) | P3 | `docs/CHANGELOG.md` | S (1h) | R74 / R75 / R76 等每次 commit 同步加 [Unreleased] 段 (目前 R70/R71/R72/R73/R74 累计补在 R73 段) |
| A-3 | 0 英文 / 繁体 markdown (CC-8 续) | P3 | `assets/legal/*.md` | XL (跨 round) | v0.28+ 上 store 前 1 天补 3 语 markdown (或 1 英文 + 1 繁体) |
| A-4 | `_kLegalVersion` 集中化 (S-5 续) | P2 | 多处 | M (1h) | 抽 `LegalConfig.currentVersion` 集中器, 而不是 `const _kLegalVersion` 写死 |

### 4.3 重构 P2-P3

| 编号 | 类型 | 严重度 | 位置 | 修复难度 | 修复建议 |
|---|---|---|---|---|---|
| R-1 | 5 widget 集中器抽取 (R70 续) | P3 | `lib/presentation/pages/*/widgets/` | M (1h/each) | 5 个仍 inline 的 widget: 比如 medication row 的 dosage chip / mood 的 score picker 等 — 检查还有没有"重复模式" |
| R-2 | god class 风险 | P3 | `lib/presentation/pages/medication/medication_calendar_page.dart` | M (2h) | 跟 assessment_page 一样, 拆 4 widget 集中器 |
| R-3 | god class 风险 | P3 | `lib/presentation/pages/home/home_page.dart` 28.7 KB | L (3h) | 拆成 4 widget 集中器 (header / footer / primary_action_row / secondary_action_row 已拆, 还差 1-2 个) |

### 4.4 半成品 (TODO / 假数据 / hardcoded) P1-P3

| 编号 | 类型 | 严重度 | 位置 | 修复难度 | 修复建议 |
|---|---|---|---|---|---|
| H-1 | TODO 注释 | P1 | `home_page.dart:550, 558, 568` | S (30min) | S-9 同款 |
| H-2 | TODO 注释 | P1 | `sms_service.dart:90, 104, 196` | XL (跨 round) | R55+ 真接阿里云 — 等法务模板审核 + 申请 AccessKey |
| H-3 | TODO 注释 | P1 | `email_service.dart:19, 40, 162` | XL (跨 round) | v1.0+ 真接 SendGrid |
| H-4 | TODO 注释 | P2 | `domain/entities/scale_translations.dart:99` | M (2h) | R65b 补 3 region key (tw/sg/uk intl fallback) |
| H-5 | 假数据 hardcode | P1 | `home_page.dart:558, 568` | S (30min) | S-9 同款 |
| H-6 | `_isFullyImplemented = false` 守门 (R63 修) | P3 | `sms_service.dart:136` | XL | R55 真接 send() 时改 true |
| H-7 | 隐私 URL 部署 (SPRINT1_LEGAL_TODO.md §5) | P2 | `docs/SPRINT1_LEGAL_TODO.md:117` | L (跨 sprint) | 部署 https://chroniccare.app/privacy, Play Console / App Store Connect 填 |
| H-8 | 真实邮箱注册 | P1 | `assets/legal/user_agreement.md:60` + `privacy_policy.md:115` | L (1-2 周) | 注册 `support@chroniccare.app` 真实邮箱 |
| H-9 | GitHub 仓库占位 | P1 | `assets/legal/user_agreement.md:61` | M (1h) | 决策 C / D (公开 issues 仓库 vs 删 URL) + 替换 / 删除 |
| H-10 | 律师过审 | **P0 (上架前置)** | 3 法律文档 | XL (跨月) | 找 1 个 PIPL 律师过审, ~¥15k-30k / 文档, 1-2 周 |
| H-11 | re-consent 逻辑 | **P0 (PIPL §17)** | app 启动 + setup 流程 | L (3h) | LegalVersionComparator + 自动重走 setup |

---

## §5 修复优先级排序

### 5.1 P0 (上架前必修, 必走 R75)

| 编号 | 标题 | 描述 | 估时 | 备注 |
|---|---|---|---|---|
| S-1 | 5 处病耻感措辞中性化 | `app_zh.arb:635, 645, 653, 661, 908` 改中性化 + 3 语同步 | S (1h) | 跟 R72 P0-4 同款, 1 个 commit 收尾 |
| S-2 | notifDailyCheckInBody 中文错字 | "留个今的踏实" → "留个日的踏实" | XS (5min) | 1 行改, R72 当时改文案时手抖 |
| S-3 | safetyAlert title i18n | `safety_alert_builder.dart:98` 硬编码 → l10n (加 `safetyAlertTitle` ARB key × 3 语) | S (30min) | R65 拆 builder 时漏, R75 续 |
| S-5 | PIPL §17 同意记录失效 | 1) `_kLegalVersion` 改动态; 2) `ConsentArtifact.version` 改动态; 3) 加 `LegalVersionComparator` 启动比对; 4) 不一致弹重走 setup; 5) CHANGELOG | L (3h) | 真正上架前必走 (上架审核员会看"用户当时同意了哪一版协议" 实操) |
| S-6 | 失联通知 reminder 漏药品信息 PII | `lost_contact_sms.dart:73` 删 medication 字段 | XS (5min) | 1 行删, 跟 safetyAlert 保持一致 |
| H-10 | 律师过审 (上架前置) | 找 1 个 PIPL 律师过审 3 文档 | XL (1-2 周) | 真正上架前置条件, 不能拖 |

**P0 6 项 总估时: 4h 代码 + 1-2 周律师**

### 5.2 P1 (上架前强烈建议, 1-2 周内)

| 编号 | 标题 | 描述 | 估时 |
|---|---|---|---|
| S-4 | safetyAlert "从未打卡" i18n | 加 `safetyAlertLastCheckInNever` ARB key, 走 l10n | S (15min) |
| S-7 | ConsentDialog body 法规引用修正 | "PIPL §13" → "PIPL §14 / §29" (单独同意 + 敏感 PII) | S (15min) |
| S-8 | assessmentSeverityNormal 临床精度 | "正常" → "几乎没有" (3 语同步) | S (15min) |
| S-9 | home_page SMS / Email hardcode 占位 | 改 `throw UnimplementedError` 或加 `FeatureFlags.realSmsEnabled` 守卫 | S (30min) |
| H-1 | home_page TODO 注释清理 | 跟 S-9 同款 | S (30min) |
| H-4 | scale_translations R65b 3 region 补 | tw / sg / uk intl fallback | M (2h) |
| H-8 | 真实邮箱注册 | `support@chroniccare.app` 注册 + 3 文档替换 | L (1-2 周, 等用户决策) |
| H-9 | GitHub 仓库占位 | 决策 C / D + 替换 / 删除 | M (1h) |

**P1 8 项 总估时: 4h 代码 + 1-2 周邮箱注册**

### 5.3 P2 (上架后 1-2 月, R76+)

| 编号 | 标题 | 描述 | 估时 |
|---|---|---|---|
| A-1 | app_theme inline alpha 抽集中器 | CC-10 续, R69 决策保留, R76 改 | M (2h) |
| A-4 | LegalConfig 集中器 | 抽 `LegalConfig.currentVersion` 集中器, 而非 `_kLegalVersion` 写死 | M (1h) |
| H-7 | 隐私 URL 部署 | https://chroniccare.app/privacy 部署 | L (1 天) |

**P2 3 项 总估时: 3h 代码 + 1 天部署**

### 5.4 P3 (长期, 1-3 月)

| 编号 | 标题 | 描述 | 估时 |
|---|---|---|---|
| A-2 | CHANGELOG 顺序同步 | R74 / R75 / R76 每次 commit 同步加 [Unreleased] 段 | S (1h) |
| A-3 | 0 英文 / 繁体 markdown | v0.28+ 上 store 前 1 天补 3 语 | XL (跨 round) |
| S-10 | care_engine 过期注释 | "你真棒！" → "今周已全部准时" (跟 care_copy 一致) | XS (5min) |
| S-11 | 失联通知 4 文档 wording 统一 | 跟 R69 / R72 / R74 业务决策保持同步 | S (1h) |
| R-1 | 5 widget 集中器抽取 | 检查 medication / mood 重复模式 | M (1h/each) |
| R-2 | medication_calendar_page 拆 widget | 跟 assessment_page 同款 | M (2h) |
| R-3 | home_page 28.7 KB 拆 widget | 已拆 4 widget, 还差 1-2 个 | L (3h) |
| H-2 | R55 真接阿里云 SMS | 等法务模板审核 + 申请 AccessKey | XL (跨月) |
| H-3 | v1.0+ 真接 SendGrid | 邮件服务 | XL (跨月) |
| H-6 | `_isFullyImplemented = true` 守门 | R55 真接 send() 时改 | XL (跟 H-2 一起) |

**P3 10 项 总估时: 1d 代码 + 跨月 2 项**

---

## §6 总览

| 项 | 数量 | 详情 |
|---|---|---|
| **P0** | 6 | S-1 (病耻感 5 处) / S-2 (错字) / S-3 (i18n 漏 title) / S-5 (PIPL §17) / S-6 (PII 暴露) / H-10 (律师) |
| **P1** | 8 | S-4 (i18n 漏 "从未打卡") / S-7 (法规引用) / S-8 (临床精度) / S-9 (hardcoded 占位) / H-1 (TODO 清理) / H-4 (i18n 续) / H-8 (邮箱) / H-9 (GitHub) |
| **P2** | 3 | A-1 (CC-10 续) / A-4 (LegalConfig) / H-7 (URL 部署) |
| **P3** | 10 | A-2 / A-3 / S-10 / S-11 / R-1 / R-2 / R-3 / H-2 / H-3 / H-6 |
| **合计** | **27** | R69 基线 27 项 → R74 27 项 (基数不变, 但 6 个 R69 P0 已修, 6 个 R74 P0 新发现 — 净增 6 个 P0) |

**P0 增量**: R69 6 个 P0 已修 → R74 6 个新 P0 (S-1 病耻感扫尾 / S-2 错字 / S-3 i18n 漏 / S-5 PIPL §17 / S-6 PII / H-10 律师)

**R74 重点 (跟 R69 对比)**:
- 病耻感措辞: R69 9 个 P0 中 3 个, R74 6 个 P0 中 1 个 (S-1 5 处病耻感) — 持续改善但漏扫
- PIPL: R69 6 个 P0 中 4 个, R74 6 个 P0 中 3 个 (S-5 §17 / S-6 §6 / H-10 律师) — 持续增加
- 临床精度: R69 0 个, R74 1 个 (S-8) — 新发现
- i18n 完整性: R69 0 个, R74 2 个 (S-3 / S-4) — R65 / R72 漏

**R75 建议 (上架冲刺 batch)**:
1. 1 个 commit: S-1 + S-2 + S-3 + S-4 + S-6 + S-7 + S-8 + S-9 + S-10 + H-1 (10 项, ~3h 代码) — 病耻感 / i18n / 临床精度 集中清
2. 1 个 commit: S-5 (PIPL §17, 3h) — LegalVersionComparator + re-consent
3. 1 个 commit: H-10 (律师过审) — 等用户决策 + 外部依赖
4. 1 个 commit: A-2 (CHANGELOG) + R-1 widget 集中器 (跨页)
5. 1 个 commit: H-7 (URL 部署) + H-8 (邮箱注册) + H-9 (GitHub 决策)

**总估时**: ~6h 代码 + 1-2 周律师 + 1-2 周邮箱 — 真正上架前 2-3 周可完成 (跟 SPRINT1_LEGAL_TODO.md §5 checklist 同步)

---

## §7 附: 修复路线图 (R75-R78 4 round)

### R75 (上架冲刺, 1 周)
- **commit 1 (3h)**: S-1 + S-2 + S-3 + S-4 + S-6 + S-7 + S-8 + S-9 + S-10 + H-1 集中清 (10 项, 病耻感 / i18n / 临床精度 / hardcoded)
- **commit 2 (3h)**: S-5 PIPL §17 同意记录失效 (LegalVersionComparator + re-consent)
- **commit 3 (1h)**: A-4 LegalConfig 集中器 + R-1 widget 集中器抽取 (medication row)
- **commit 4 (0.5h)**: CHANGELOG R75 段

### R76 (上架准备, 1 周)
- 律师过审 (H-10, 外部依赖 1-2 周)
- 真实邮箱注册 (H-8, 外部依赖 1-2 周)
- 隐私 URL 部署 (H-7, 1 天)
- 3 文档修订历史段同步 (A-2 续)

### R77 (上架后, 1 月)
- R55 真接阿里云 SMS (H-2, 法务模板 + AccessKey)
- `_isFullyImplemented = true` (H-6)
- 真接 SendGrid (H-3, 邮件服务)
- 16KB page size 验证 (R70 续, 上架后看实际反馈)

### R78 (长期, 1-3 月)
- 3 语 markdown 法律文档 (A-3, 跨 round)
- home_page 28.7 KB 拆 widget (R-3, L)
- medication_calendar_page 拆 widget (R-2, M)

---

**审计完成时间**: 2026-08-01
**下次审计建议**: R76 (上架前 1 周, 验 R75 + 律师过审 + 邮箱注册)
**审计人**: superpowers-zh sub-agent
**审计方法**: 顶层架构审视 (5 子层) + 底层逐行排查 (病耻感 / 隐私 / PIPL §13/§14/§17/§26/§28/§29 / 临床 / i18n) + 4 类问题清单 (上架 / 架构 / 重构 / 半成品) + 修复优先级 (P0 / P1 / P2 / P3)
**审计耗时**: ~25 min
**R74 总问题数**: 27 (6 P0 / 8 P1 / 3 P2 / 10 P3)
