# superpowers-zh 视角报告 — Round 105 (2026-08-09)

**评分**: 8.0/10 (vs R104 的 9.0)
**基线**: R104 (2026-08-09) — 本批 uncommitted 重设计 (R101 用药 / mood_list / daily_tracking 3 大模块 + R100 tracking customize)
**守门员**: 18 个中 **2 个回归 RED** (check_orphan_arb_keys 42 orphan / check_zh_hant_consistency 16 处) + check_arb_keys ✅

## 总评

本批重设计在**硬编码中文清理**上进步明显: R104 报的 P0 硬编码 (mood_detail "录音"/"删除"、add_medication "请输入药物名称"/"已添加"、medication_page "在用"/"已停"、today_summary_card 4 处、daily_tracking_multi_chart 4 处) 全部走 ARB 修复; assessment_comparison / care_copy 中文也收敛到 override-pattern。check_strings_hardcoded ✅。

但本批同时引入 **58 个 ARB 卫生回归**: 42 orphan keys (全为本批新增, 含 26 个 influenceFactor key) + 16 处 zh_Hant 不一致。最核心的问题是 **"情绪影响因素"这条新特性线实际上没做真 i18n** — ARB key 和 `kInfluenceFactorKeys` 都建好了, 但 UI 仍直读中文 fallback `kInfluenceFactors` 且**以中文入库**, en/zh_Hant 用户看到的 chip / 详情 / 因素分析全是简体中文。

## 问题清单

| 编号 | 问题 | 文件:行 | 架构/底层 | 难度 | 优先级 | 建议 |
|---|---|---|---|---|---|---|
| ZH-01 | **影响因素 UI 仍直读中文 fallback**: `kInfluenceFactorKeys` (26 个 ARB key) 已建但无人消费, chips 用 `kInfluenceFactors[category]` 渲染 + 以中文 JSON 入库 → en/zh_Hant 用户见中文 chip | `mood_influence_chips.dart:97,120` / `mood_recorder_page.dart:343` / `mood_detail_page.dart:125` / `mood_factor_analysis.dart:68,129` / `influence_category.dart:38-75,81-118` | 架构/i18n | 中 | **P1** | 新（Z7 半修）: ① UI 层 `label: l10n.influenceFactorXxx` (用 kInfluenceFactorKeys 映射); ② 入库改存 key 或建 key↔中文 双向映射, 老数据兼容; ③ 删 `kInfluenceFactors` 中文 fallback |
| ZH-02 | **check_orphan_arb_keys RED — 42 个 orphan key 全为本批新增**: 26 influenceFactor* + medDetailNoFactors / moodAudioRecording(与 moodRecordingLabel 重复) / moodDetail4D / moodEditTooltip / moodFactorAvgScore / moodFactorCount / moodReminderEnabled·Subtitle·TimeLabel·Title / moodTrendMonth·MonthTitle·Records·WeekTitle / setupConsentViewAll·ViewDisclaimer | `lib/l10n/app_zh.arb` (本批 +174 key, 42 未 wire) | ARB 卫生 | 简单 | **P1** | 新（guard 回归）: 要么 wire (ZH-01), 要么删; moodReminder* 需确认 mood_reminder_notifier 有无设置 UI, 无则删 key |
| ZH-03 | **check_zh_hant_consistency RED — 16 处**: 2 处真错 — `influenceFactorWindy` 刮風→**颳風**, `moodTrendDistTitle`/`moodTrendDistribution` 分布→**分佈**; 14 处是人工改良 (新增/儲存/錠劑/資料/資訊/本週) 但守门员不许 | `app_zh_Hant.arb` 16 key | zh_Hant | 简单 | **P1** | 新（guard 回归）: 修 2 处真错; 14 处人工改良要么让脚本 allowlist, 要么 zh 源字同步 ("添加"→"新增" 等) 保持脚本严格全绿 |
| ZH-04 | **mood_trend_page 时间范围/ tab 标签硬编码非 ARB**: `_TimeRange` '7D'/'30D'/'6M'/'1Y' + `Tab(text: 'CBT')`, 而 ARB 已有 moodTrendWeek(近 7 天)/moodTrendMonth(近 30 天) 但没用 → 时间范围选择器与 ARB key 脱节 | `mood_trend_page.dart:17-26,64,161` | 底层/i18n | 简单 | **P2** | 新: SegmentedButton 改 `l10n.moodTrendWeek` / 新增近 6 月·近 1 年 key; 'CBT' 走 ARB |
| ZH-05 | **手动日期/时间拼接弃用 Formatters/intl** (违反 R56d 约定): `_formatDateTime` 手动拼 `yyyy-MM-dd HH:mm` 重复 `Formatters.dateTime()`; 时间多处 `padLeft` 手拼 | `mood_detail_page.dart:263-266,284-290` / `medication_page.dart:302,428` / `add_medication_page.dart:332,373` / `medication_detail_page.dart:82` / `medication_calendar_grid.dart:211,217` / `mood_trend_page.dart:238,513` | 底层/i18n | 简单 | **P2** | 新: 统一走 `core/shared/formatters.dart` (HourMinute 可加 `toTime()` helper), locale 切换不用改 |
| ZH-06 | **剂量显示用 `'${dosage}${unit.id}'` 而非 `Formatters.dosage()`**: 50.0 → "50.0mg" 且漏 round-half-up (0.05 显示问题), 与 medication_report 不一致 | `medication_page.dart:362` / `add_medication_page.dart:446` / `medication_detail_page.dart:81` | 底层/i18n | 简单 | **P2** | 新: 换 `Formatters.dosage(dosage, unit)` |
| ZH-07 | **通知 channel 名 const 中文 (Z12 残留)**: badge_sync / notification_service 用 `static const _channelName = Strings.notifChannelMedicationName` (const 字段, 非 `*Text({override})`) → en/zh_Hant 系统设置看"用药提醒/安全警报"中文 | `badge_sync_service.dart:34` / `notification_service.dart:63` | 底层/i18n | 简单 | **P2** | 残留: 改 `notifChannelMedicationNameText(override: l10n.xxx)` 注 ARB override (const 需改为晚初始化) |
| ZH-08 | **error 分支裸吐异常 `Text('$e')`**: 用户可见英文/栈错误文本, 未本地化, 也泄露内部细节 | `medication_page.dart:162` / `medication_detail_page.dart:202-204` / `mood_trend_page.dart:101` | 底层/i18n | 简单 | **P2** | 新: 统一 ErrorState widget + `l10n.commonError` 文案 |
| ZH-09 | **剂型/颜色 UI 承诺与持久化脱节**: add wizard 让用户选剂型(MedForm) + 颜色(colorIndex), 但 `_save()` 的 `MedicationDraft` 没传 form/colorIndex → 白选; detail/list 页 TODO colorIndex 永远 0。另 `MedForm` enum 与 domain `MedicationForm` 重复 | `add_medication_page.dart:22-33,91-97` / `medication_page.dart:415` / `medication_detail_page.dart:67` / `medication_form.dart` | 架构/UX | 中 | **P2** | 新: `_save` 传 form+colorIndex; 删 UI 侧 MedForm 改引 domain enum |
| ZH-10 | **moodTrendCbtHint 半角逗号**: "正值 = 情绪改善, 负值 = 恶化" 应全角 (fullwidth 检查 warn-only 未拦截 ARB) | `app_zh.arb` moodTrendCbtHint | 底层/文案 | 简单 | **P2** | 新: 全角逗号; 同扫一遍本批新 key 的标点 |
| ZH-11 | **PIPL 新增字段未同步同意书**: 新采集 剂型/颜色 (medication form/colorIndex) 不在 `sensitive_data_consent.md §2.1` 的"药名、剂量、用药时间"清单; `MedicationDraft.notes` 自由文本字段已存在 (暂未出 UI, 潜伏) | `assets/legal/sensitive_data_consent.md:23` / `medication_draft.dart:59` | 合规 | 简单 | **P3** | 新: 同意书 §2.1 补"剂型、颜色、备注"; notes 出编辑 UI 前必先更新同意书 (本地零云端, 风险低但守 PIPL 纪律) |
| ZH-12 | **术语混用 用药/服药/药物**: medPageTitle=用药、medTodaySchedule=今日服药、medMyMedications=我的药物、medCalendar=用药日历 — 语境都合理但无统一 glossary | `app_zh.arb` med* key | 文案 | 简单 | **P3** | 新: 建 ARB key 术语表; "今日服药计划"与"服药计划"空态文案统一 |
| ZH-13 | **careCopyWeekPerfectBody zh 源词 "今周" 不通顺**: 应"本周"; zh_Hant 已人工改"本週" (守门员因此标记, 属 ZH-03 之一) | `app_zh.arb` careCopyWeekPerfectBody | 文案 | 简单 | **P3** | 新: zh 改"本周" |

## 守门员状态

| 脚本 | 状态 | 说明 |
|---|---|---|
| check_arb_keys (3 语 key 同步) | ✅ | 1265 = 1265 = 1265 |
| check_orphan_arb_keys | ❌ RED | **42 orphan (全本批新增)** — R104 时 0 |
| check_zh_hant_consistency | ❌ RED | **16 处 (全本批新增)** — R104 时 0 |
| check_legal_consent | ✅ | setup_legal_dialog OK |
| check_strings_hardcoded | ✅ | 仅扫 strings.dart, 不覆盖 domain 实体/UI 层 |
| check_cross_feature / no_pua / widget_dispose / drift_namespace / datetime_race / no_hardcoded_utc / changelog | ✅ | 全绿 |

## R104 项目闭环核对

- ✅ 已修 (本批): Z1/Z2 (mood_detail 录音/删除)、Z3/Z4 (add_medication)、Z5 (在用/已停)、Z6 (mood_factor_analysis "条"→factorAnalysisCount)、Z8、Z10 (today_summary_card)、Z11 (daily_tracking_multi_chart)、Z9 (assessment_comparison)、care_copy 改 override-pattern
- ⚠️ 半修: Z7 (influence_category keys 建好未 wire, 见 ZH-01)
- ⭕ 残留: Z12 (通知 channel 名中文, 见 ZH-07)

## 总结

**8.0/10**。硬编码中文纪律大幅改善 (R104 全部 P0 闭环), 但本批 3 大新模块 (medication / mood_list / daily_tracking) 把 ARB 卫生拉回红灯: 42 orphan + 16 zh_Hant 是**提交前必须清零**的 guard 回归 (P1)。"情绪影响因素" i18n 是架构半成品 — key/映射层建好但渲染和存库仍走中文 fallback, 且存量数据已中文入库, 修 ZH-01 需一并做数据兼容。其余为 P2 细节 (intl 统一、剂量格式、错误文案) 和 P3 合规/文案打磨。

**下次审计**: v0.31 或 R101 批提交后 — 重点复查 ZH-01~03 三个红灯 + mood_reminder 设置 UI 是否 wire。

---
*审计人: AI Agent (superpowers-zh 视角, Round 105)*
