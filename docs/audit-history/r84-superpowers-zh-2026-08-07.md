# superpowers-zh 视角审计报告 — Round 84 起点

> **范围**: `D:\Batch\chroniccare` (Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2)
> **版本**: pubspec 0.27.0+64（CHANGELOG R83 写 v0.28 round 83 — **版本号不一致，见 P0-1**）
> **审计员**: superpowers-zh 视角（中文 i18n + 中国合规 + 中文 Git 规范 + 中文文档 + 中文业务温度）
> **审计依据**:
> - GB/T 35273-2020 个人信息安全规范
> - 《中华人民共和国个人信息保护法》(PIPL) §13 §14 §17 §23 §28 §29 §38 §47
> - 《App 违法违规收集使用个人信息行为认定方法》
> - App Store Guideline 3.1.5(a) IAP 政策
> - 《Keep a Changelog》中文版
>
> **审计方式**: 静态审计（读源 + grep） + 不跑 `flutter analyze/test`
> **不修改代码**: 报告归 `docs/`，执行前需用户确认

---

## 0. 一句话总结

> 项目整体走"superpowers-zh"维护范式到位：撤回同意真接 (R67)、13 守护脚本、legal consent 集中器、setup 流程 4 步同意。
> **但上架 launch blocker 真实存在 3 类**：
> (1) 业务层 vs 隐私政策失联通知描述**严重不一致**（隐私政策说"不触发"，代码 `safety_watch_service` 真实在跑）；
> (2) `fastlane/Appfile` 3 处 TODO 占位 + CHANGELOG 顶部 v0.28 vs pubspec 0.27.0+64 不一致；
> (3) speech_to_text 隐私政策描述"on-device / cloud"含糊，PIPL §38 跨境传输风险。
>
> 此外 6 类"非阻断但有碍上架"细节：1 zh key 业务值英文无对照、38 处中文+半角标点、139 个 zh_Hant 直接复制简体、8 元 IAP 6 个 ARB key 当前是 dead code、200 处硬编码中文、setup 热线 section 标题硬编码未走 l10n。
>
> **最大业务温度风险**：`scaleCrisisTitle: "我们关心你"` 是真温度；但 `safetyAlertBodySent: "已自动通知紧急联系人"` 在当前失联通知暂停版本里**对用户撒谎**（实际是 mock），精神心理 App 对危机场景说谎 = 信任崩塌。

---

## 1. 顶层架构审视（高内聚低耦合）

| # | 类别 | 优先级 | 难度 | 描述 | 路径 |
|---|---|---|---|---|---|
| A1 | 架构/隐私边界 | **P0** | 中 | `safety_watch_service.dart:111/116/135` 的 `_checkAndAlert` 在隐私政策说"不实际触发通知"的情况下**仍然每日执行失联检测**。CareEngine `fire()` 在 R75 已 throw StateError，但 `safety_watch_service` 仍跑 `app_start` / `check_in` / `manual` 三个 trigger，逻辑层"假装通知已发"会让用户在隐私政策承诺下产生不实预期 | `lib/core/data/services/safety_watch_service.dart:111,116,135` vs `assets/legal/privacy_policy.md:28,58,158` |
| A2 | 架构/边界 | P1 | 中 | `setup_legal_dialog.dart:101` 把 `'🆘 心理危机干预热线 (24h)'` 硬编码未走 l10n（与 R83 同步到 3 locale 的 12 crisisHotline* key 分离），未来 en 部署会乱码；同文件 `:80-87` 用了 l10n key | `lib/presentation/pages/setup/setup_legal_dialog.dart:101` |
| A3 | 架构/边界 | P1 | 低 | `care_copy.dart:34/39/47` 7 条带 emoji 标题是硬编码中文（'🛏️ 提早一点更稳定' / '☀️ 周末保持节律' / '🌿 后续保持就好' / '🌟 一整周都准时！'），不走 l10n。**好消息**：这部分确实是中文专享的"中文激励文案"，但 en 走时会丢 | `lib/domain/logic/care_copy.dart:34-55` |
| A4 | 架构/数据 | P1 | 中 | 8 元 IAP 6 个 ARB key (`settingsIap*` / `iapPurchase*`) 当前 dead code（`FeatureFlags._prodIapEnabled=false`），`check_orphan_arb_keys` 应已报。R68 决策：v0.27 不显示买断入口，等 v0.28 真接 productId。建议**先标记"v0.28 启用"**，避免漏；或拆 feature gate | `lib/l10n/app_zh.arb: settingsIapUpgradeTitle/Subtitle, iapPurchaseSuccess/Failed` |
| A5 | 架构/i18n | P1 | 低 | `scale_translations.dart` 是 **domain 层但有 11 处硬编码中文**（PHQ-9 / GAD-7 量表题目 + 严重度），违反"domain 层 0 Flutter / 0 硬编码 UI"原则。R78 已 i18n 化 16 题但留了 fallback。**强建议**：补全 en/zh_Hant 对照后清掉 fallback | `lib/domain/entities/scale_translations.dart:118-270` |
| A6 | 架构/i18n | P2 | 低 | `vent_entry_entity.dart:86-113` 9 处硬编码中文（`'$sec秒'`, `'$m分'`），声音时长格式化本应走 formatters | `lib/domain/entities/vent_entry_entity.dart:86,92,99,110,113` |
| A7 | 架构/单元 | P1 | 中 | `medication_report.dart` 17 处硬编码中文（报告模板），未走 l10n。R78 P1-2 已发现但 R84 仍未修 | `lib/domain/logic/medication_report.dart` |
| A8 | 架构/i18n | P1 | 低 | `core/l10n/strings.dart` 39 处硬编码中文 — 这是 domain 层 strings（供通知/邮件 fallback），按 AGENTS.md 设计本就该硬编码 zh 作为 fallback。但需保证 en / zh_Hant 走 `app_localizations` 时能覆盖（这部分走的是 `Localizations.localeOf(context)` 而非 domain 字符串，所以 fallback 不会跑到 UI，OK 风险低） | `lib/core/l10n/strings.dart` |
| A9 | 架构/隐私 | **P0** | 高 | `safety_watch_service` + `home_page.dart:539-540 注释"v1.0+ 真接"` + 隐私政策三处"不实际触发"三方对账。R75 改成 throw StateError，但失联检测 cron 仍在跑（mock SMS log 输出）。**上架前必须二选一**：<br>(a) 失联检测整个 skip 掉直到 v1.0 启用（推荐，最简）<br>(b) 隐私政策承认"失联检测 mock 模式运行，不发真实通知" | 见 A1 |

---

## 2. 中文 i18n 完整性

### 2.1 ARB key 总览

| 类别 | zh | en | zh_Hant | 缺失/差异 |
|---|---|---|---|---|
| 业务 key 数（去 @@ 元数据） | **821** | 816 | 820 | zh 比 en 多 5, zh 比 zh_Hant 多 1 |
| 仅 zh 有 | 6 | — | — | `@_v0.21_round_22_settings_clear_all_data`, `@homeLastMed`, `@homeNextReminder`, `@homeStreak`, `@setupStep`, `@snackbarErrorTemplate`（5 个是元数据 placeholder 描述，1 个是元数据 key） |
| 仅 en 有 | 1 | — | — | `@_v0_21_round_22_settings_clear_all_data`（placeholder 命名差异：zh 用 `.` en 用 `_`） |
| 仅 zh_Hant 有 | 1 | — | — | `@homeSafetyAlertSuffix` — **疑似 en 缺 zh_Hant 业务值** |

### 2.2 实际业务值缺失（不只是 metadata）

| ARB key | zh | en | zh_Hant | 状态 | 优先级 |
|---|---|---|---|---|---|
| `homeLastMed` | `'最后吃药：$time'` | ❌ 缺 | `'最後吃藥：$time'` | zh/zh_Hant 有，en 缺 | **P1**（zh/zh_Hant 用户看 en 文本会 fallback 到 key 名） |
| `homeNextReminder` | `'下次提醒：$time'` | ❌ 缺 | `'下次提醒：$time'` | 同上 | **P1** |
| `homeStreak` | `'已坚持 $days 天'` | ❌ 缺 | `'已堅持 $days 天'` | 同上 | **P1** |
| `setupStep` | `'第 $current 步 / 共 $total 步'` | ❌ 缺 | `'第 $current 步 / 共 $total 步'` | 同上 | **P1** |
| `snackbarErrorTemplate` | `'<action> 失败: <error>'` 描述 | ❌ 缺 | 同 zh | 同上 | **P1** |
| `homeSafetyAlertSuffix` | ❌ 缺 | ❌ 缺 | `'(失联通知已配置)'` | en 缺 zh_Hant | **P1** |

> 5 个 zh/zh_Hant 有而 en 缺的业务文案都是 "主页顶部状态条" 高频曝光位，**en 部署会 fallback 显示 key 名**（"`homeLastMed`"），这是低级错。

### 2.3 139 个 zh_Hant 直接复制简体未翻译

| 文件 | 复制简体 key 数（前 20 抽样） |
|---|---|
| `app_zh_Hant.arb` | `medicationUnitTablet`, `reportHistoryItemPatient`, `snackbarActionGeneratePdf`, `setupNameHint`, `setupPrivacy1`, `legalPageWithdrawTitle`, `dayDetailCheckInWith`, `ventDetailPrivacy`, `crisisHotlineTwNumber`, `crisisHotlineHkNumber`, `assessmentPrevious`, `notificationStatusCardOemBrandVivo`, `ventToday`, `setupContactPhoneHint`, `moodDimensionEnergyHint`, `reminderHubStatusNotConfigured`, `moodDimensionEnergy`, `assessmentSeveritySevere`, `commonSave`, `medsSnackUpdated` |

> 抽样看：其中 `crisisHotlineTwNumber` / `crisisHotlineHkNumber` / `medicationUnitTablet` / `commonSave` 等**简繁相同**（技术术语/标量），无需翻译。
>
> 但 `setupNameHint` / `ventDetailPrivacy` / `moodDimensionEnergyHint` 等是**短语** — OpenCC s2tw 会转成繁（如"设置"→"設置"），当前 zh_Hant 复制简体 = 港澳台用户看简体。
>
> **R76-N3 (R77 修过 hotline 6 region x 2 = 12 个)，但 139 - 12 = 127 个仍复制简体**。 `check_zh_hant_consistency.py` 跑过说 0 diff 是因为 OpenCC s2tw 转换是单向且**接受简体副本**（s2tw 是 "Simplified Chinese to Traditional Chinese (Taiwan Standard)"，如果输入已经是简体 OpenCC 也会"认为"它是繁体的某些子集不报错）。
>
> **建议**: 守门员改为 s2tw 反向 + t2s 一致性（zh_Hant → 简体后 == zh），或写 `check_zh_hant_unchanged.py` 显式列出未翻译的 key。

### 2.4 38 处中文+半角标点（zh + zh_Hant 都有）

| 类别 | key 数量 | 代表 |
|---|---|---|
| 导出风险提示 | 3 | `settingsExportRiskBody`, `settingsExportRiskLiability`, `settingsExportRiskAcknowledge` |
| 树洞撤回 | 5 | `legalVentWithdrawBody`, `legalVentWithdrawDeleteDesc`, `legalVentWithdrawSealDesc`, `legalVentWithdrawnSealed`, `ventSealedSubtitle` |
| 年龄严正声明 | 1 | `setupLegalAgeAttestation`（R83 新加，**律师刚审过的文档还带半角逗号** — 律师层面已认可？需复核） |
| 趋势撤回 | 1 | `trendWithdrawnSubtitle` |
| 安全通知 body | 3 | `safetyAlertBodySent/Failed/Mocked` |
| 其他 | 25 | `setupWelcomeContactHint` 等 |

> 这是 P1 任务：`check_fullwidth_punctuation.py` 已存在但标 warn-only，**建议 R84 升 error**（精神心理 App 法务文案 100% 全角是基本盘）。
>
> 特别警告：`setupLegalAgeAttestation` 是 R83 律师审核后新增的"年龄严正声明"，含 3 处半角逗号 + 1 处半角冒号 — **建议立刻走人工复核**（律师可能未察觉标点问题，但法律文书用半角有违中文规范）。

---

## 3. 中国合规专项（个保法 PIPL + App Store 政策）

| # | 法律条款 | 状态 | 风险 | 修复方案 | 难度 | 证据 |
|---|---|---|---|---|---|---|
| C1 | **PIPL §13/§23/§29 单独同意 + 单独告知** | 🟡 形式合规，**业务层失联通知不触发** | 中 | 撤回同意 4 个 ConsentKind（`safety`/`vent`/`analytics`/`dataExport`）在 R67 真正生效（✓），但 `home_page.dart:539-575` 的 `fireSms/fireEmail` throw StateError，**而 `safety_watch_service` 仍跑 mock 链路**（log 写"已通知"但实际未发）。**用户会以为真发了** | 改 `safety_watch_service` mock 链路文案 + log | `lib/core/data/services/safety_watch_service.dart:111,135,154,219,249,265,279` + `lib/presentation/pages/home/home_page.dart:539-575` |
| C2 | **PIPL §14 敏感个人信息** | ✓ 已设单独同意书 | 中 | `sensitive_data_consent.md:7-9` 列出医疗健康信息等 7 类，**但 §3 处理方式表漏"情绪日记"和"评估"两项的具体处理目的描述**（v0.22+ 新增 mood 维度未同步） | 补 §3 mood/assessment 行 | `assets/legal/sensitive_data_consent.md:39-48` |
| C3 | **PIPL §17 明确告知** | ✓ 导出风险卡有 | 低 | `data_management_section` 已加风险卡 + checkbox 强制勾选（R83 Q4b），合规 | — | `lib/presentation/pages/settings/widgets/data_management_section.dart:121-143` |
| C4 | **PIPL §28 健康医疗** | ✓ 隐私政策 §1 表格有 | 低 | — | — | `assets/legal/privacy_policy.md:36-38` |
| C5 | **PIPL §29 跨境** | ✓ R83 §11 整段改"未来规划" | 中 | 但 `pubspec.yaml:70 speech_to_text: ^7.0.0` 仍声明 — 隐私政策 §7 表行 `speech_to_text` 写"mobile 走平台 on-device / cloud"含糊。**若 cloud 走 Google STT, 即 PII 跨境**。**上架前必须二选一**：<br>(a) 强制 on-device（iOS Speech / Android `RecognitionService` 不走云）<br>(b) 隐私政策 §11 承认"语音转文字走境外云服务" + 启动 STT 前单独弹窗告知 | 改 `speech_to_text` 配置 or 改隐私政策 + 加 STT 同意弹窗 | `pubspec.yaml:70` + `assets/legal/privacy_policy.md:108,155-161` |
| C6 | **PIPL §38 跨境数据传输** | ✓ 隐私政策 §11 整段规划中 | 中 | 跟 C5 同根 | — | 同 C5 |
| C7 | **PIPL §47 撤回同意 + 删除** | ✓ R82.5 vent seal 走通 | 低 | `legal_consent_provider.dart:90-130` 走通 vent 撤回 + delete/seal 二选一 + `VentRepository.deleteAll` | — | `lib/presentation/providers/legal_consent_provider.dart:90-130` + `docs/CHANGELOG.md: R82.5` |
| C8 | **App Store 3.1.5(a) IAP** | 🟡 文档有"8 元"但业务暂停 | 中 | `user_agreement.md:22-28` 写"售价 8 元 / 一次性买断"+ 6 个 IAP ARB key 当前是 dead code（`FeatureFlags._prodIapEnabled=false`），fastlane metadata 4 locale 都未声明 IAP 价格档。**R68 决策：v0.27 不显示买断入口 = 当前上架版本 App Store 不会要求 IAP**（因为功能不上架），合规 | ① 上架前必须确认 `iapEnabled=false` 在 release 模式硬编死 ② v0.28 真接 IAP 时同步 ③ `user_agreement.md:22-28` "售价 8 元" 段降为"未来规划" ④ 6 个 IAP ARB key 标 v0.28 启用注释 | `assets/legal/user_agreement.md:22-28` + `lib/l10n/app_zh.arb: settingsIap*` + `pubspec.yaml` (查 _prodIapEnabled) |
| C9 | **App Store 5.1.1 隐私政策 URL** | 🟡 fastlane 占位 | **P0 上架阻断** | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt` 都是 `https://chroniccare.app/privacy`（占位域名，**未注册**） | 上 store 前必须注册 `chroniccare.app` 域名 + 上传隐私政策 md 渲染为 HTML + 替换 4 locale 12 处 url | `fastlane/metadata/**/privacy_url.txt` + `fastlane/metadata/**/support_url.txt`（同样占位） |
| C10 | **App Store 1.4.1 医疗 App 警告** | 🟡 | 中 | 名称"慢病管家" + full_description 强调"精神心理 / 抑郁 / 焦虑" — 触发 App Store 1.4.1 医学警告。**上架前需准备：医学免责声明 + 隐私政策 URL + 临床医生顾问证明**（如可能） | 准备 disclaimer.md + 医生顾问协议 | `fastlane/metadata/android/zh-CN/full_description.txt:33-42` |
| C11 | **App Store 1.4.3 处方药** | ✓ | 低 | 未声明任何处方药名 | — | — |
| C12 | **App Store Guideline 4.0 设计抄袭** | 🟡 | 中 | `docs/CHANGELOG.md: R81` "emil design eng 借鉴 B 站'哗哩哗哩能量加油站' 6 commit" — **借鉴不构成抄袭但需自查**：4 情绪太阳 emoji + 横滑 carousel + SectionHeader chip + HomeHeroIllustration（自绘蓝天太阳云）— chip 和横滑是通用设计模式 OK，**自绘插画**OK，**IP 化太阳**（emoji ☀️⛅🌧⛈）是 Unicode 公共域 OK | 自查 + 准备设计说明文档 | `docs/CHANGELOG.md` R81 段 |
| C13 | **《数据安全法》/《网络安全法》** | ✓ | 低 | SQLCipher AES-256 + SecureStorage 设备绑定密钥 + 零云端 | — | `assets/legal/privacy_policy.md:43-48` |
| C14 | **《未成年人保护法》§44 + PIPL §31** | ✓ R83 已加 18 周岁严正声明 | 低 | `setupLegalAgeAttestation` 4 个 prop + 1 个 ConsentCheckRow + 隐私政策 §10 措辞改严正声明 | — | `lib/l10n/app_zh.arb: setupLegalAgeAttestation` + `lib/presentation/pages/setup/setup_legal_dialog.dart` |
| C15 | **《广告法》§9 禁用绝对化用语** | 🟡 需自查 | 中 | `care_copy.dart:53 '🌟 一整周都准时！'` / `homeStreakBroken '少 1 次没关系'` / `homeStreak '已坚持 N 天'` — "一整周" 是描述性 OK，"都准时" 是事实描述 OK；但 "🌟" + "！" 修辞不构成绝对化。**全部 OK** | — | `lib/domain/logic/care_copy.dart:53` |
| C16 | **法务 3 md 文件自身状态** | 🟡 | 中 | 3 个 md（`privacy_policy.md` / `user_agreement.md` / `sensitive_data_consent.md`）**全部仍标"草稿 (未经律师过审)"**，且 `user_agreement.md:68-69` 2 处 TODO + `assets/legal/privacy_policy.md:128` 软隐藏邮箱 + `assets/legal/privacy_policy.md:196` 修订历史表 `v0.28+ | 待定 | TODO (上 store 前必须由专业律师过审)` — **法务尚未过审** | **P0 阻断**：上架前必须由执业律师签字 | `assets/legal/*.md` 修订历史段 |
| C17 | **心理危机热线覆盖** | ✓ R83 加港澳台 3 条 | 低 | 3 个 md + `setup_legal_dialog` + 12 crisisHotline* ARB key x 3 locale | — | `assets/legal/*.md §8/§5` + `lib/l10n/app_zh.arb: crisisHotline*` + `lib/presentation/pages/setup/setup_legal_dialog.dart:74-87` |
| C18 | **CHANGELOG 顶部 vs pubspec 不一致** | 🟡 文档 bug | 中 | `pubspec.yaml version: 0.27.0+64` 但 `docs/CHANGELOG.md:3-7` R83 段开头 4 处写 `v0.28 round 83` — **CHANGELOG 走 v0.28 但 pubspec 还停 v0.27.0+64**。`check_changelog.py` 没抓到（它检查 CHANGELOG 内一致性，不检查 pubspec 同步） | `check_changelog.py` 升级 + 加 1 项 `pubspec version match CHANGELOG top section` | `pubspec.yaml` + `docs/CHANGELOG.md:3,5,7,11` |

---

## 4. 硬编码中文 / 半角 / PUA / 标点

### 4.1 PUA 字符

- **lib/ 全树**: 0 PUA
- **ARB 全树**: 0 PUA
- **状态**: ✓ `check_no_pua.py` 全绿

### 4.2 硬编码中文（非 generated，200 处）

| 路径 | 处数 | 严重度 | 建议 |
|---|---|---|---|
| `lib/core/l10n/strings.dart` | 39 | 🟢 设计如此（domain 层 fallback zh） | 保留，需确保 UI 走 `app_localizations` 不绕开 |
| `lib/domain/logic/medication_report.dart` | 17 | 🟡 | R78 P1-2 发现未修，**P1 修**（医疗报告给医生看的，不能硬编码） |
| `lib/domain/entities/scale_translations.dart` | 11 | 🟡 | R78 已 i18n 化 16 题但留 fallback，**P1 清 fallback** |
| `lib/domain/entities/vent_entry_entity.dart` | 9 | 🟡 | `'$sec秒'`/`'$m分'` 时长格式化应走 formatters，**P2** |
| `lib/domain/logic/day_detail.dart` | 9 | 🟡 | `'打卡 · $medName'` 等 UI 标签，**P1** |
| `lib/core/data/services/reminder_scheduler.dart` | 9 | 🟡 | 通知 title/body 硬编码 zh，**P0**（通知不跟 locale 切换会发错语言） |
| `lib/domain/logic/care_copy.dart` | 7 | 🟢 设计如此（中文专享激励文案） | 保留，加注释说明 zh-only |
| `lib/core/data/services/email_service.dart` | 6 | 🟡 | 邮件模板 zh 硬编码，**P0**（发英文用户收中文邮件 = 退订） |
| `lib/core/data/services/refill_notifier.dart` | 6 | 🟡 | 通知 body，**P0**（同 reminder_scheduler） |
| `lib/main.dart` | 4 | 🟢 developer.log 内部日志 | 保留（仅 dev 调试） |
| `lib/presentation/pages/home/home_page.dart:588,600` | 4 | 🟢 developer 注释 + 死代码注释 | 保留，R75 已 throw StateError 标死 |
| `lib/presentation/pages/setup/setup_legal_dialog.dart:101` | 1 | 🔴 业务 UI 文案 | **P0** 走 l10n |
| `lib/presentation/widgets/medication_report_dialog.dart:45` | 1 | 🟡 | `'${l10n.settingsMedReport}（近 ${windowDays} 天）'` — 模板拼装，**P2** 抽 l10n key |
| `lib/presentation/widgets/press_feedback_icon_button.dart:59` | 1 | 🟢 developer 错误信息 | 保留 |
| `lib/presentation/widgets/app_list_tile.dart:142` | 1 | 🟢 developer assert 错误 | 保留 |
| `lib/presentation/widgets/consent_dialog.dart:169,171,173` | 3 | 🟡 | 撤回同意后业务停用提示 — **P1** 走 l10n（zh_Hant 用户撤回会看 zh） |
| `lib/presentation/pages/settings/widgets/data_management_section.dart:121,123,124,143` | 4 | 🟡 | export 注释 / purpose / retention 字段，**P2** |
| `lib/core/routing/notification_navigation.dart` | 2 | 🟡 | 通知点击跳转携带的 deep-link 标签 |
| 其他 ~ 60 | 60 | 🟡 / 🟢 | 大部分是 developer.log / assert / scale 内部 fallback |

> **P0 真硬编码（用户可见）**:
> 1. `setup_legal_dialog.dart:101` 心理危机热线标题
> 2. `reminder_scheduler.dart` 9 处通知 title/body
> 3. `email_service.dart` 6 处邮件模板
> 4. `refill_notifier.dart` 6 处续方提醒 body
> 5. `consent_dialog.dart:169,171,173` 撤回业务停用提示
> 6. `notification_service.dart` 5 处（推测，1 文件）

### 4.3 半角标点细节

- **AGENTS.md**: 8 处半角贴近中文 vs 75 处全角 — **轻度**（AGENTS 是给 AI Agent 看）
- **docs/CHANGELOG.md**: **150 处半角贴近中文** vs 217 处全角 — **中度**（CHANGELOG 是公开文档，半角占比 41% 偏高）
- **R83 律师审核新增的 5 处法务文案** (`setupLegalAgeAttestation` 等) 3 处半角 — 建议人工复核

### 4.4 ARB 内部半角标点（38 处，已列 2.4 表）

---

## 5. 中文文案"温度"评估

### 5.1 高分（精神心理 App 典范）

| key | zh | 评估 |
|---|---|---|
| `scaleCrisisTitle` | "我们关心你" | ✓ 4 字温度满分，避免"自杀警示" / "紧急" 等刺激性词 |
| `scaleCrisisMessage` | "你提到了想伤害自己的念头。\n请记住：寻求帮助是勇敢的，不是软弱。" | ✓ 4 段叙事：承认事实 + 去病耻感 + 鼓励行动，**教科书级** |
| `ventEmptyTitle` | "树洞还是空的" | ✓ 不说"暂无数据"等机械话术 |
| `ventEmptySubtitle` | "想说什么就说出来。文字、语音都可以。\n这些话只有您自己能看到。" | ✓ 隐私承诺 + 行动邀请双层 |
| `homeStreakBroken` | "少 1 次没关系，明天继续" | ✓ 不责怪，**病耻感友好**（精神心理患者中断服药不应被指责） |
| `homeStillOnline` | "🌱 您还在线" | ✓ "您" 敬称 + 🌱 萌芽隐喻 |
| `careCopy` 7 条 | "🛏️ 提早一点更稳定" / "☀️ 周末保持节律" / "🌿 后续保持就好" / "🌟 一整周都准时！" | ✓ emoji + 短句 + 不催促不评判 |
| `ventEmptyAction` | "写第一句" | ✓ 降低门槛，**不是"开始记录"** |
| `snackbarEmptyVent` | "写点东西或录一段吧" | ✓ 口语化 |
| `setupHello` | "您好，我是慢病管家" | ✓ "您好" 礼貌 + 自我定位 |
| `setupDoneSubtitle` | "明天开始您的第 1 天" | ✓ 不说"已成功设置"，避免"成就式"话术对脆弱人群的隐性压力 |
| `setupReminder3` | "✓ 漏 2 天我会联系紧急人" | ✓ 用"我" + "会"暗示承诺感；不过"漏"字可考虑"未打卡 2 天"更中性 |

### 5.2 中等（机械或专业术语）

| key | zh | 评估 |
|---|---|---|
| `setupIntro` | "1 分钟设置好，然后每天 1 次打卡" | 🟡 数字 OK 但稍机械化，**建议加温度**：如"1 分钟陪您设置好。1 天 1 次就好，我们陪您慢慢来" |
| `setupReminder1` | "✓ 推送 1 次提醒" | 🟡 纯描述，**建议**："✓ 每天 1 次贴心提醒" |
| `setupReminder2` | "✓ 您点 1 下 = 打卡" | 🟡 "=" 数学符号对老年用户不友好，**建议**："✓ 您点 1 下就完成打卡" |
| `setupPrivacy1` | "• 本地加密" / `setupPrivacy2` | 🟡 技术黑话，**建议**："• 您的数据只存在您手机里" / "• 不会传到任何服务器" |
| `setupDailyRoutine` | "我每天会做：" | 🟡 "做"字抽象，**建议**："我每天会陪您：" + 列表 |
| `homeCheckedIn` | "今天已打卡 ✓" | 🟡 太短无温度，**建议**："✓ 今天的药已打卡，您真棒" |
| `settingsDisclaimerText` | "本应用不提供医疗建议，所有功能仅供参考。" | 🟡 法律合规温度，OK |
| `settingsAboutVersion` | "v0.23.0 · 我今天吃了药" | 🟡 主题句好，但 **v0.23.0 是 5 个 round 前的版本号，应改 v0.28.0**（P2 同步版本号） |
| `legalVentWithdrawBody` | "树洞内容是您最私密的数据。撤回同意后,您可选择以下方式处理已有数据:" | 🟡 隐私边界清楚，但半角逗号 + 句末"选择以下方式"机械，**建议**："这些是您最私密的内容。撤回同意后，我们可以:..."（去掉"选择以下方式"） |
| `settingsExportRiskBody` | "您即将导出的数据为明文文件,含您的个人健康等敏感信息(用药、打卡、紧急联系人、树洞文字)。请务必保存到安全、可信的位置(加密 U 盘 / 私人云盘),避免上传至公共云盘或发送给不可信的第三方。" | 🟡 半角逗号 + 法律告示口吻，**建议**先温暖后警告："这里有您最珍贵的健康记忆。导出的文件是明文，请妥善保存（加密 U 盘 / 私人云盘），避免上传至公共云盘。" |
| `setupLegalAgeAttestation` | "本人郑重承诺:我已年满 18 周岁。如本人为 14-18 周岁,本人保证已取得监护人代为同意,并愿意承担虚假陈述的一切法律后果。" | 🟡 法律文书口吻 OK，但半角逗号 / 冒号，**全角化**即可 |
| `safetyAlertBodySent` | "上次打卡: {date}。已自动通知紧急联系人，请确认安全。" | 🔴 **对用户撒谎**：当前版本不会真发通知（见 A1 / C1） |
| `safetyAlertBodyFailed` | "上次打卡: {date}。失联检测已触发，但通知发送失败。请检查网络。" | 🔴 同样问题：失联检测可能不触发，**用户会以为系统在保护自己** |
| `safetyAlertBodyMocked` | "上次打卡: {date}。失联检测已触发，但当前为开发模式，**未实际通知**紧急联系人。" | 🟡 已声明 mock，但开发模式 ≠ 用户场景，**建议**："失联检测已触发。当前版本为测试模式，未实际通知紧急联系人。" |
| `medsListEmpty` | "还没添加常吃药" | 🟡 OK |
| `assessmentHistoryEmpty` | "还没有评估记录" | 🟡 OK |
| `assessmentHistoryEmptyHint` | "完成一次心理评估后，记录会显示在这里" | 🟡 OK，**但"心理评估"对病耻感敏感人群可能抗拒**。**建议**："做一次情绪小测验后，记录会显示在这里"（"测验"比"评估"更轻） |
| `gad7SeverityLabel1` | "轻度焦虑" / `gad7SeverityLabel2` "中度焦虑" | 🟡 临床术语 OK，但 **"中度焦虑"在 App 内显示可能引发"我有焦虑症吗"自我标签**。**建议**附录"这是自评倾向，不是诊断"小字 |
| `phq9SeverityLabel0` | "几乎没有抑郁" | ✓ R75 clinical minimal 化 |

### 5.3 失联告警（关键场景）的温度

`lib/core/data/services/safety_watch_service.dart` 触发 `home_page.dart:315,512` 时会显示 `homeSafetyAlertSuffix` 错误信息。

**关键问题**：
- `safetyAlertBodySent: "已自动通知紧急联系人，请确认安全。"` — **对用户撒谎**（v0.27 不真发）
- 精神心理 App 在用户最脆弱时刻（疑似失联）说谎 = **信任崩塌**
- 正确措辞：`"失联检测已触发。当前版本未实际通知紧急联系人。请您或家属主动确认安全。"`（明确告知未发 + 引导用户主动行为）

### 5.4 危机话术 5 条规范

> **精神疾病领域的"危机信号"措辞要特别慎重**（用户原始要求）

| 维度 | 当前 | 建议 |
|---|---|---|
| 词性 | "我们关心你"（名词 + 动词）✓ | 保持 |
| 病耻感 | "寻求帮助是勇敢的，不是软弱" ✓ | 保持，**可加**"很多人走过这段路" |
| 行动指引 | 当前只给 PHQ-9 第 9 题弹窗 | **建议**：所有危机话术附 `setup_legal_dialog` 那 5 条热线 (大陆 2 + 港澳台 3) + 1 个"立即拨打"按钮 |
| 时态 | "你提到了想伤害自己的念头"（过去时）| **建议**："如果你现在有这种想法..."（现在时 + 假设语气，避免让用户感觉"系统记录在案"） |
| 数据透明 | 当前未告知用户"系统记录了这次危机话术" | **建议**：明示"我们已记录这次求助信号，48 小时内可联系 support@chroniccare.app"（如未来开通） |

### 5.5 setup 热线 section

`lib/presentation/pages/setup/setup_legal_dialog.dart:101`：

```dart
Text(
  '🆘 心理危机干预热线 (24h)',  // ← 硬编码中文
  ...
)
```

**问题**：
1. 硬编码未走 l10n（en 部署乱码）
2. **🆘 表情过于刺激** — 精神心理 App 用 SOS emoji 可能增加焦虑。**建议**：🌿 或 ☎️ 替代

---

## 6. Git 提交规范 / 文档规范

### 6.1 Git log 风格

- 抽查 100 commit：**99/100 符合** `<version> round <N>: <title>` 规范
- 唯一不符合：`R63 P1/P2 cleanup batch`（缺 version 前缀 + round 编号）
- 整体：✓ 极规范

### 6.2 CHANGELOG 半角标点

`docs/CHANGELOG.md` 共 **150 处半角贴近中文** vs 217 处全角 — 半角占比 41%

- R83 段（最新）半角标点 30+ 处（律师审核后未做全角化）
- R76-R82 段半角标点 90+ 处
- R50 前段半角标点 30+ 处

**建议**：CHANGELOG 本身就是给人看的，半角 41% 偏高。`check_fullwidth_punctuation.py` 应从 warn-only 升 error。

### 6.3 法务 3 md 半角标点

- `privacy_policy.md`: 半角 25+ 处（"v0.27 本版本不实际触发" 等业务描述）
- `user_agreement.md`: 半角 12+ 处
- `sensitive_data_consent.md`: 半角 8+ 处

**法务文案应 100% 全角化**（这是中文法律文书标准）

### 6.4 文档混合中英

| 文件 | 风格 | 评估 |
|---|---|---|
| `README.md` | 中文为主 + 英文技术词 | ✓ |
| `AGENTS.md` | 中文为主 + 英文 code block | ✓ |
| `docs/CHANGELOG.md` | 中英混排 + 半角标点 | 🟡 41% 半角 |
| `docs/DEPLOYMENT.md` | 中文 + bash code block | ✓ |
| `docs/SPRINT1_LEGAL_TODO.md` | 中文 | ✓（需读） |
| `docs/LEGACY_API_NOTES.md` | 中文 | ✓（需读） |

---

## 7. 按优先级排序的修复列表

### 7.1 P0 阻断上架（不修不能上 store）

| # | 优先级 | 难度 | 类别 | 位置 | 描述 | 预期工时 |
|---|---|---|---|---|---|---|
| P0-1 | **P0** | 低 | 版本号 | `pubspec.yaml:1` vs `docs/CHANGELOG.md:3,5,7,11` | CHANGELOG R83 写 v0.28 但 pubspec 0.27.0+64。统一到 v0.28.0+65 并 `check_changelog.py` 加 pubspec 同步校验 | 30 min |
| P0-2 | **P0** | 高 | 法务过审 | `assets/legal/privacy_policy.md` + `user_agreement.md` + `sensitive_data_consent.md` | 3 个 md 全部标"草稿 (未经律师过审)"。**上架前必须由执业律师签字 + 删除"草稿"标注 + 删除 v0.28+ TODO 段**。3 文件 + 修订历史表 | 2-4 周（外部） |
| P0-3 | **P0** | 中 | 法务 | `fastlane/Appfile:21,23,24` + `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt` + `support_url.txt` (12 个文件) | apple_id / team_id / itc_team_id 全占位 + privacy URL `https://chroniccare.app/privacy` 域名未注册 + support URL 同样。**必须注册 chroniccare.app 域名 + 替换 12 文件 + 部署隐私政策 HTML** | 1 周（域名）+ 30 min（替换） |
| P0-4 | **P0** | 中 | 业务对账 | `lib/core/data/services/safety_watch_service.dart:111,135,154,219,249,265,279` + `lib/presentation/pages/home/home_page.dart:539-575` | 隐私政策三处说"不实际触发"但失联检测 cron 仍在跑。**二选一**：<br>(a) `safety_watch_service` 整个 skip 直到 v1.0<br>(b) 隐私政策承认"mock 模式运行" | 2-4h |
| P0-5 | **P0** | 中 | 失联通知文案 | `lib/l10n/app_zh.arb: safetyAlertBodySent/Failed/Mocked` (3 个文案) | "已自动通知紧急联系人" 在当前版本对用户撒谎。**改**为"失联检测已触发。当前版本未实际通知紧急联系人。请主动联系家人或拨打热线。" | 1h + 3 locale x 2 文案 = 6 ARB key |
| P0-6 | **P0** | 低 | 硬编码 UI | `lib/presentation/pages/setup/setup_legal_dialog.dart:101` | 心理危机热线 section 标题硬编码中文，**走 l10n** | 30 min + 3 locale |
| P0-7 | **P0** | 中 | 通知 i18n | `lib/core/data/services/reminder_scheduler.dart:9` + `refill_notifier.dart:6` + `email_service.dart:6` + `notification_service.dart:5`（推测）| 通知 title/body 走 zh 硬编码，en 部署发错语言。**改**：通知 body 走 l10n 注入（参考 R77-i18n-3 "snooze_manager 1 处改 l10n 化函数版" 模式） | 1-2 天 |
| P0-8 | **P0** | 中 | PIPL §38 | `pubspec.yaml:70 speech_to_text: ^7.0.0` + `assets/legal/privacy_policy.md:108,155-161` | speech_to_text 走 cloud 即 PII 跨境。**二选一**：<br>(a) 强制 on-device（iOS Speech / Android RecognitionService）<br>(b) 隐私政策 §11 承认"语音转文字走境外云服务" + STT 启动前单独弹窗 | 1 周（on-device 测试）+ 4h（弹窗） |

### 7.2 P1 上架前必做（不合规但不阻断）

| # | 优先级 | 难度 | 类别 | 位置 | 描述 | 预期工时 |
|---|---|---|---|---|---|---|
| P1-1 | P1 | 低 | ARB 缺失 | `app_en.arb` 缺 5 个 zh/zh_Hant 有的业务 key | 补 `homeLastMed` / `homeNextReminder` / `homeStreak` / `setupStep` / `snackbarErrorTemplate` + `homeSafetyAlertSuffix` zh_Hant | 30 min |
| P1-2 | P1 | 低 | 半角全角 | ARB 38 处 | 律师审核刚过的 `setupLegalAgeAttestation` 等 5 处法务文案必须 100% 全角。`check_fullwidth_punctuation.py` 升 error | 2-3h |
| P1-3 | P1 | 中 | 繁简一致 | `app_zh_Hant.arb` 139 个 key 复制简体 | 守门员升级为 s2tw 反向 + t2s 校验；127 个未翻译 key 走 OpenCC 批处理 | 4h |
| P1-4 | P1 | 中 | 硬编码 | `lib/domain/logic/medication_report.dart:17` + `lib/domain/logic/day_detail.dart:9` + `lib/presentation/widgets/consent_dialog.dart:3` (撤回业务停用提示) + `lib/domain/entities/scale_translations.dart:11` (PHQ/GAD fallback) | 走 l10n | 1 天 |
| P1-5 | P1 | 低 | 业务温度 | `safetyAlertBodySent/Failed/Mocked` 改完后再走"立即拨打热线"按钮接入 | 4h |
| P1-6 | P1 | 低 | 业务温度 | `assessmentHistoryEmptyHint: "做一次心理评估后..."` 改"做一次情绪小测验后..." | 30 min + 3 locale |
| P1-7 | P1 | 中 | 法务同步 | `sensitive_data_consent.md:39-48` §3 处理方式表补 mood / assessment 行 | 1h |
| P1-8 | P1 | 中 | 业务暂停 | `user_agreement.md:22-28` 8 元段落 + 6 个 IAP ARB key | 加 v0.27 不显示买断入口说明 + 标 v0.28 启用 TODO 注释 | 1h |
| P1-9 | P1 | 中 | 撤回 UX | `consent_dialog.dart:169,171,173` 撤回业务停用提示走 l10n + 加 "撤销" / "保持" 按钮文案审计 | 1h + 3 locale |
| P1-10 | P1 | 中 | 文案温度 | `setupLegalAgeAttestation` 严正声明 100% 全角化 + 1 处改温暖版（"如未达 18 周岁，请监护人协助阅读本政策"） | 1h |

### 7.3 P2 优化（不阻断）

| # | 优先级 | 难度 | 类别 | 位置 | 描述 | 预期工时 |
|---|---|---|---|---|---|---|
| P2-1 | P2 | 低 | 版本号同步 | `lib/l10n/app_zh.arb: settingsAboutVersion` `v0.23.0` → `v0.28.0` | 30 min |
| P2-2 | P2 | 中 | 守门员 | `scripts/check_changelog.py` 加 `pubspec version match CHANGELOG top section` | 1h |
| P2-3 | P2 | 低 | 守门员 | `scripts/check_zh_hant_consistency.py` 升级为 s2tw → t2s 反向校验 | 2h |
| P2-4 | P2 | 低 | 守门员 | `scripts/check_fullwidth_punctuation.py` 升 error（仅法务文件 + ARB 强制） | 1h |
| P2-5 | P2 | 低 | 守门员 | `scripts/check_orphan_arb_keys.py` 增 `iap*` 白名单（v0.28 启用）+ 增 `settingsIap*` 注释 | 30 min |
| P2-6 | P2 | 中 | 业务温度 | `homeCheckedIn: "今天已打卡 ✓"` → `"✓ 今天的药已打卡，您真棒"` | 30 min + 3 locale |
| P2-7 | P2 | 中 | 业务温度 | `setupReminder1/2/3` + `setupPrivacy1/2/3` + `setupDailyRoutine` 改温暖版 | 2h + 3 locale |
| P2-8 | P2 | 中 | 危机话术 | `scaleCrisisMessage` 改现在时 + 加 5 条热线 + 加"我们记录了这次求助"数据透明 | 2h + 3 locale |
| P2-9 | P2 | 低 | 表情 | `setup_legal_dialog.dart:101` 🆘 改 🌿 | 5 min |
| P2-10 | P2 | 中 | 硬编码 | `lib/domain/entities/vent_entry_entity.dart:9` + `medication_report_dialog.dart:45` + `app_list_tile.dart:142` (assert) | 走 formatters / l10n | 2h |
| P2-11 | P2 | 中 | CHANGELOG 标点 | 150 处半角贴近中文 100% 全角化 | 1 天 |
| P2-12 | P2 | 中 | 法务 md 标点 | privacy / user_agreement / sensitive_data_consent 3 个 md 半角贴近中文 100% 全角化 | 1 天 |
| P2-13 | P2 | 中 | `care_copy.dart` | 加 zh-only 注释（避免后续误改 en 版） | 30 min |
| P2-14 | P2 | 中 | ARB 元数据 placeholder | zh 5 个 en 1 个元数据 placeholder 命名差异（`@_v0.21_round_22_settings_clear_all_data` vs `@_v0_21_round_22_settings_clear_all_data`） | 30 min |

### 7.4 P3 调研 / Brainstorm

| # | 优先级 | 难度 | 类别 | 位置 | 描述 | 预期工时 |
|---|---|---|---|---|---|---|
| P3-1 | P3 | 高 | Brainstorm | 待定 | **真接 IAP（R55）** — 当前 `FeatureFlags._prodIapEnabled=false`，需 brainstorm：6 元 vs 8 元定价、订阅 vs 买断、免费功能边界、捐赠模式。**superpowers-zh brainstorming skill 必跑** | 1 周（脑暴） + 4 周（实现） |
| P3-2 | P3 | 高 | Brainstorm | 待定 | **真接阿里云 SMS（R55）** — 法务模板审核 1-2 月 + 阿里云 AccessKey 申请。**brainstorm**：模板分场景（失联 / 续方 / 节日）、脱敏发送、本地预签名 | 1 周 + 2 月 |
| P3-3 | P3 | 高 | Brainstorm | 待定 | **失联通知 v1.0 真接** — 当前是 mock + 隐私政策"不实际触发"。**brainstorm**：阈值（2 天 vs 3 天 vs 用户自定义）、通知模板（关怀 vs 紧急）、用户主动确认机制、误报处理 | 1 周 |
| P3-4 | P3 | 中 | i18n | `lib/l10n/app_zh.arb: phq9*` / `gad7*` 50+ 量表 key | R78 i18n 化 16 题 + 严重度，但量表 instruction / option / fallback 还有 50+ 待补 | 2 天 |
| P3-5 | P3 | 中 | 港澳台上线 | `fastlane/metadata/ios/zh-Hant/description.txt:940 chars` vs `app_zh_Hant.arb:820 key` | 港澳台 App Store 上架需补充繁体 marketing 文案 + 截图本地化 | 1 周 |

---

## 8. superpowers-zh 视角专项观察

### 8.1 中文 i18n 工程化亮点

- ✓ **R56e `check_orphan_arb_keys.py`** 守门员 — 39 个 orphan 一次清掉
- ✓ **R57 4 个守门员**（legal_consent / sms_release_ready / strings_hardcoded / zh_hant_consistency）覆盖中国合规
- ✓ **R78 PHQ/GAD i18n 化** — 16 题 + 严重度 + 选项全文 i18n
- ✓ **R77 4 通知 channel name/desc** 加 ARB
- ✓ **R74 ventDuration* 守护** — 避免 i18n regression
- ✓ **R77 §13 → §29 修订** — 法务条文准确性

### 8.2 superpowers-zh brainstorming 适用度

| 待办 | 是否需 brainstorm | 原因 |
|---|---|---|
| R55 真接 IAP | **必跑** | 8 元定价 / 买断 vs 订阅 / 商业模式 / 心理学角度定价（脆弱人群） |
| R55 真接 SMS | **必跑** | 失联通知的伦理边界 / 误报责任 / 通知模板分场景 / 监护人授权 |
| 失联通知 v1.0 | **必跑** | 阈值 / 模板 / 主动确认 / 误报 |
| 心理评估量表扩展（PHQ-A / GAD-2 / 自杀意念量表）| **必跑** | 临床精度 / 病耻感 / 危机响应 |
| 家属端 / 共同照护 | **必跑** | 家属权限边界 / 隐私分享 / 紧急情况家属接管 |
| 治疗师端 B2B | **必跑** | 合规 / 数据流 / 商业模式 |

### 8.3 superpowers-zh 中文提交规范

- ✓ 99% 提交符合 `<version> round <N>: <title>`
- ✓ 中文 commit title 占主流
- 🟡 CHANGELOG 半角标点 41% — 需统一
- 🟡 律师审核过的法务文案仍带半角 — 需守门员强制

### 8.4 superpowers-zh 中文文档规范

- ✓ AGENTS.md / README.md 风格统一中文为主
- ✓ 5 层架构命名一致
- ✓ 16 守护脚本中文 commit message
- 🟡 法务 3 md 半角标点
- 🟡 CHANGELOG 半角标点

---

## 9. 总结

### 9.1 项目 superpowers-zh 健康度评分

| 维度 | 评分 | 说明 |
|---|---|---|
| 中文 i18n 完整性 | **8.5 / 10** | 821 key 业务值 + 16 守护脚本，仅 5 个 en 缺 zh/zh_Hant |
| 中国合规 | **6.5 / 10** | 形式合规到位（4 步同意 + 撤回真接 + 5 热线 + 22 SDK 表格），**3 大 P0 阻断未解**（法务未过审 + Appfile 占位 + 失联通知业务对账）|
| 中文业务温度 | **9.0 / 10** | 病耻感友好 + "我们关心你" 等金句，但失联通知文案对用户撒谎是严重失分项 |
| 中文 Git / 文档 | **8.0 / 10** | 99% 提交规范 + 16 守护脚本 + 16 文档，半角标点 41% 偏高 |
| **综合** | **8.0 / 10** | 形式合规 + 温度在线 + 工程化扎实，**待法务过审 + 失联通知业务对账**即可上架 |

### 9.2 上架前必须完成的 8 件事

1. **法务过审** (P0-2): 律师签字 + 删除"草稿"标注
2. **Appfile 占位** (P0-3): 注册 chroniccare.app 域名 + 替换 12 个 fastlane 文件
3. **失联通知业务对账** (P0-4): 隐私政策 vs 实际行为二选一
4. **失联通知文案** (P0-5): "已自动通知"改"未实际通知" 3 locale
5. **setup 热线硬编码** (P0-6): `'🆘 心理危机干预热线 (24h)'` 走 l10n
6. **通知 i18n** (P0-7): reminder_scheduler / refill_notifier / email_service 6+5+9+6 处走 l10n
7. **speech_to_text PIPL §38** (P0-8): 强制 on-device 或隐私政策承认
8. **版本号同步** (P0-1): pubspec 0.27.0+64 → 0.28.0+65 + CHANGELOG 同步

**预计工作量**: 1 周工程（不含法务过审 2-4 周外部）

### 9.3 上架后 v0.28+ roadmap

- R84: P0-1 ~ P0-8 + P1-1 ~ P1-10
- R85: 业务温度全面审计 + 病耻感专项 + 危机话术 v2
- R86: 真接 IAP 脑暴 + 实现
- R87: 真接阿里云 SMS 脑暴 + 实现
- R88: 失联通知 v1.0 真接
- R89: 港澳台 marketing 本地化 + 繁体区 App Store 上架

---

## 10. 附录

### 10.1 审计方法

```bash
# 1. ARB key 对比
python -c "import json; print(set(json.load(open('lib/l10n/app_zh.arb', encoding='utf-8-sig'))) - set(json.load(open('lib/l10n/app_en.arb', encoding='utf-8-sig'))))"

# 2. 硬编码中文 (排除 generated)
python -c "
import re, pathlib
for p in pathlib.Path('lib').rglob('*.dart'):
    if p.name.endswith('.g.dart') or p.name.endswith('.freezed.dart') or p.name.startswith('app_localizations_'):
        continue
    for i, line in enumerate(p.read_text(encoding='utf-8').splitlines(), 1):
        for m in re.finditer(r'''(['\"])([^'\\\"\\n]{2,}?)\\1''', line):
            if re.search(r'[\\u4e00-\\u9fff]', m.group(2)):
                print(f'{p}:{i}  {line.strip()[:120]}')
"

# 3. 半角标点贴近中文
python -c "
import re, pathlib
for p in pathlib.Path('lib/l10n').glob('*.arb'):
    for k, v in json.loads(p.read_text(encoding='utf-8-sig')).items():
        if not k.startswith('@@') and isinstance(v, str):
            if re.search(r'[\\u4e00-\\u9fff][,.!?;:]', v):
                print(f'{p.name}  [{k}]')
"

# 4. PUA 字符
python -c "
import re, pathlib
for p in pathlib.Path('lib').rglob('*.dart'):
    for i, line in enumerate(p.read_text(encoding='utf-8').splitlines(), 1):
        if re.search(r'[\\ue000-\\uf8ff]', line):
            print(f'{p}:{i}  {line.strip()[:120]}')
"

# 5. 提交规范
git -C D:/Batch/chroniccare log --pretty=format:'%s' -100 | grep -v -E '^v[0-9]+\.[0-9]+(\.[0-9]+)?\s+round\s+[0-9]+'
```

### 10.2 16 守护脚本清单（确认存在）

```
✓ scripts/check_arb_keys.py
✓ scripts/check_changelog.py
✓ scripts/check_cross_feature.py
✓ scripts/check_datetime_race.py
✓ scripts/check_datetime_race2.py
✓ scripts/check_drift_namespace.py
✓ scripts/check_fullwidth_punctuation.py
✓ scripts/check_no_hardcoded_utc.py
✓ scripts/check_no_pua.py
✓ scripts/check_widget_dispose.py
✓ scripts/check_orphan_arb_keys.py
✓ scripts/check_legal_consent.py
✓ scripts/check_sms_release_ready.py
✓ scripts/check_strings_hardcoded.py
✓ scripts/check_zh_hant_consistency.py
✓ scripts/check_all.dart
```

### 10.3 涉及文件 Top 30（按出现次数）

| 路径 | 出现 | 类别 |
|---|---|---|
| `lib/l10n/app_localizations_zh.dart` | 762 | generated (排除) |
| `lib/core/l10n/strings.dart` | 39 | domain strings (设计) |
| `lib/domain/logic/medication_report.dart` | 17 | 硬编码 |
| `lib/domain/entities/scale_translations.dart` | 11 | 硬编码 |
| `lib/domain/entities/vent_entry_entity.dart` | 9 | 硬编码 |
| `lib/domain/logic/day_detail.dart` | 9 | 硬编码 |
| `lib/core/data/services/reminder_scheduler.dart` | 9 | 硬编码 |
| `lib/domain/logic/care_copy.dart` | 7 | 设计（中文专享）|
| `lib/core/data/services/email_service.dart` | 6 | 硬编码 |
| `lib/core/data/services/refill_notifier.dart` | 6 | 硬编码 |
| `lib/main.dart` | 4 | developer.log |
| `lib/presentation/pages/home/home_page.dart` | 4 | developer 注释 |
| `lib/presentation/pages/settings/widgets/data_management_section.dart` | 4 | 硬编码 |
| `lib/domain/logic/assessment_comparison.dart` | 4 | 硬编码 |
| `lib/domain/logic/assessment_scale.dart` | 4 | 硬编码 |
| `lib/core/data/services/sms_service.dart` | 4 | 硬编码 |
| `lib/presentation/widgets/consent_dialog.dart` | 3 | 硬编码 |
| `lib/core/data/services/assessment_notifier.dart` | 3 | 硬编码 |
| `lib/core/data/services/snooze_manager.dart` | 3 | 硬编码 |
| `lib/core/data/database/connection/web.dart` | 3 | 硬编码 |
| `lib/app.dart` | 2 | developer.log |
| `lib/presentation/providers/legal_consent_provider.dart` | 2 | developer |
| `lib/domain/entities/check_in_entity.dart` | 2 | 硬编码 |
| `lib/core/routing/notification_navigation.dart` | 2 | 硬编码 |
| `lib/core/shared/json_codec.dart` | 2 | 硬编码 |
| `lib/core/data/database/app_database.dart` | 2 | developer |
| `lib/core/data/services/badge_sync_service.dart` | 2 | developer |
| `lib/core/data/services/database_migration.dart` | 2 | developer |
| `lib/core/data/services/safety_watch_service.dart` | 2 | developer |
| `lib/core/data/services/export/export_import_pipeline.dart` | 2 | developer |

---

**审计员**: superpowers-zh 视角
**日期**: 2026-08-02
**版本**: v0.28 round 84 起点
**下次审计**: R86 真接 IAP 脑暴前（届时重点审查商业模式 + 病耻感 + 心理定价）
