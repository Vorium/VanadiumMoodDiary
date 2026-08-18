# emilkowalski 设计工程视角审计 (2026-08-13, R111)

基线: R110 报告 `docs/audit/2026-08-13-multi-lens/01-emilkowalski-design.md` (EM-01~13)。本次为纯只读验证, 逐项重跑 EM-01~13 + 新增 EM-14~21。遍历 `lib/presentation/` + `lib/core/theme/` ~150 文件 (7 个子目录全扫)。master `6bbb308` (0.32.0+140), working tree clean。

**结论: 设计工程健康度 ≈ 7.5/10 (R110 9.0 → -1.5)**。token/动效/触觉集中器层健康 (EM-01/04/12 闭环), 但 8 项跨期残留中 7 项 0 闭环 (EM-02/02b/05/06/07/08/09/10/11 大部分原样), 且新增 3 个 P1: disabled 态假反馈 (EM-14)、状态色对比度 < 2:1 (EM-16)、en locale mood 标签显示中文 (EM-21, 实为 EM-13 的真相)。

## R110 跨期残留验证 (EM-01~13 逐项)

**已闭环 (验证通过)**:

- **EM-01 mood 双色板 — 闭环** ✅: `mood_visual.dart` 的 colorArgbFor 已删, mood 颜色全走 `AppColors.moodScoreColor` (trend_event_row.dart:99 / trend_calendar.dart:226 / trend_mood_chart.dart:138,222 / today_summary_card.dart:122 / mood_trend_page.dart:535 / mood_detail_page.dart:65); `colorArgbFor` 仅剩 AssessmentColorPalette 量表专用
- **EM-04 reduce-transparency — 闭环** ✅: page_scaffold 头注释确认 "用户开 reduce-transparency → 走 solid" 分支已实现 (非 `false &&`); disableAnimations 已由 spec §4.9 记录
- **EM-12 AppleHealthTile/StatCard — 基本闭环** ✅: StatCard 4 variant + ultralight w200 + 数字 tween; AppleHealthTile R109 已支持 tileWidth 140 (medication 横滚走 grid); 仅 tileHeight 注释陈旧 (见 EM-20)

**部分闭环**:

- **EM-03 Spring stub — 部分闭环** 🔶: check_in_button.dart:242 `Spring.standard.toSimulation()` → `_EntrySpring` 真接线, 物理弹簧已进 production (R32 P0-08 闭环); 但 spring.dart:125+ `Spring.of(context, ...)` context 参数工厂 + gentle/bouncy 仍 0 caller, 死代码未清
- **EM-13 labelFor 双源 — 假闭环, 升级为 EM-21** ⚠️: 基线称 "与 ARB moodLabelN 双源" — 实测 **ARB 中不存在任何 moodLabelN key** (grep 0 命中), 唯一源 = core/l10n/strings.dart:293 `moodLabel` **硬编码中文** ('很差'..'很好'), presentation 层 3 处直接用它 (trend_mood_chart.dart:110,220 / mood_quick_button.dart:50) → **en locale 下 UI 显示中文 mood 标签 = i18n bug** (P1, 见 EM-21)

**未闭环 (R110 跨期残留, 7 项)**:

- **EM-02 8 feature 未 AppleListSection 化 — 残留** ❌: settings 4 组仍 `Card` + 11pt SectionHeader (profile_group / reminders_group / data_group / legal_group); vent_list_page 4 处 Card; assessment_widgets 5 + assessment_chart_card 3 处 Card; mood_detail_page 4 处 Card; reminders_hub_page 13 + reminder_cards 10 处 Card; contacts_list_widget、daily_tracking 系列同样 Card 方言。trend_summary 已闭环 (唯一)
- **EM-02b 双 header 并存 — 残留** ❌: 11pt SectionHeader 仍 12+ 处 (trend_page ×4 / crisis_hotline ×1 / medication_calendar_page ×3 / refill_manage ×2 / settings 4 组) vs AppleListSection 13pt (home + trend_summary) — 同屏两套 header 字号/风格
- **EM-05 raw SnackBar — 残留 5/5** ❌: quick_mood_carousel.dart:91-92 / crisis_hotline_page.dart:220-221,249-250 / medication_calendar_page.dart:245-246 / daily_tracking_widgets.dart:106-107, 与基线完全一致
- **EM-06 mood_detail 大数字 — 残留** ❌: mood_detail_page.dart:44 raw Card + :52 `TextStyle(fontSize:48)` w700 (非 StatCard/ultralight); medication_detail_page:259-297 私有 `_StatCard` 与公共 StatCard 重复实现
- **EM-07 fl_chart Colors.white — 残留 3/3** ❌: mood_trend_page.dart:267,283,540 原样 (dark mode 下轴线/网格仍白)
- **EM-08 raw TextStyle — 残留 4/4** ❌: add_medication_page.dart:395 (16) / medication_detail_page.dart:346 (10) / cbt_three_column_mode.dart:44,56 (20) / mood_trend_page.dart:383 (20)
- **EM-09 _ChipBadge — 残留 2 份** ❌: vent_list_page + mood_trend_page 各一份私有 _ChipBadge 仍并存 (集中器缺位)
- **EM-10 done 态 press scale — 残留** ❌: medication done 等 disabled/完成态按钮仍带 press scale + haptic; 且发现普适版 (EM-14, PressFeedback 无 disabled 感知)
- **EM-11 72pt quick mood — 残留** ❌: mood_quick_button.dart 仍 48px 圆形 IconButton, 无 72pt 超大按钮

## Findings (新增)

| ID | 类别 | 标题 | 证据(file:line) | 难度 | 优先级 |
|---|---|---|---|---|---|
| EM-14 | 反馈真实性 | disabled 态按钮仍给 press scale + haptic — PressFeedback/Button 无 disabled 感知 (EM-10 普适版: 全库 disabled 按钮都在"假反馈") | press_feedback.dart:120-125 (Listener 无条件) / primary_button.dart:194 (无条件 pressScale) / check_in_button.dart:91 | ≤2h (3 widget 加 isEnabled) | **P1** |
| EM-15 | 状态组件集中 | 8 处 inline 错误态绕过 ErrorState (daily_tracking 5 + assessment_center:56 + treatment:64) + 6 处 raw CircularProgressIndicator 绕过 LoadingSkeleton/LoadingSpinner | anxiety_agitation_widgets:57 / stress_event_widgets:86 / weight_widgets:60 / social_rhythm_widgets:60 / sleep_widgets:69 / assessment_center_page:54,56 / treatment_page:64 / legal_page:193 / mood_trend_page:101 / medication_detail_page:223 / medication_page:193 | ≤2h (统一走 ErrorState + LoadingSkeleton) | P2 |
| EM-16 | a11y 对比度 | 状态色当文字色对比度失败: AppColors.warning #FFB74D on white ≈ 1.9:1 (WCAG 4.5:1 差 2.4x); fgOnWarning #E65100 已存在未用 | today_summary_card.dart:97 (streak 文字) / mood_factor_analysis.dart:110,140 (success/warning/error 文字) | ≤0.5h (换 fgOnWarning/fgOnSuccess) | **P1** |
| EM-17 | 假 affordance | settings _UserProfileCard 内 chevron 无任何 tap 目标 — 外观可点, 点了没反应 | profile_group.dart:209-257 | ≤0.5h (删 chevron 或加 InkWell) | P2 |
| EM-18 | reduce-motion 盲区 | quick_mood_carousel _MoodButton AnimatedScale/AnimatedContainer 硬编码 duration/curve, 未走 Motion wrapper — 全代码库唯一 reduce-motion 盲区 | quick_mood_carousel.dart:177-184 | ≤0.5h | P2 |
| EM-19 | 假 API | AppListTile.destructive 构造与 standard 完全同实现 (destructive 只改了颜色语义, 行为 0 差异) — 假 API, 语义未落地 | app_list_tile.dart:95-108 | ≤0.5h (删或实做) | P3 |
| EM-20 | 注释漂移 | AppleHealthTile tileHeight 注释 "88pt" 陈旧, 实际 110 (R31 已改) — 文档/代码不同步 | apple_health_tile.dart 头注释 | ≤0.5h | P3 |
| EM-21 | i18n | en locale mood 标签显示中文 — presentation 3 处用 core Strings.moodLabel (硬编码 '很差'..'很好'), ARB 无 moodLabelN key (EM-13 真相) | mood_quick_button.dart:50 / trend_mood_chart.dart:110,220 / core/l10n/strings.dart:293-303 | 1-2d (ARB 加 moodLabel1-5 ×3 语 + 迁移 + 清注释) | **P1** |

## 验证健康项 (R110/R31 遗产, 验证通过)

- **5 token 集中器**: app_colors / app_typography / app_spacing / app_motion / spring 全部在位, 无回归
- **Haptics 单源**: presentation 0 处 raw `HapticFeedback.`, 13 个调用点全走 feedback.dart 5 类集中器 (home/contact/vent/medication/quick_mood)
- **路由动效**: app_routes.dart:47-90 3 类 transition 全走 `Motion.duration(context, ...)` (fade/slide-right/slide-up), 无硬编码
- **R32 P0-07 闭环**: raw IconButton 全库已消灭 (全走 PressFeedbackIconButton / PressFeedback), 包括 page_scaffold 内
- **PrimaryButton 3 variant + AppListTile 3 命名构造 + StatCard 4 variant**: 集中器本身健康, 问题是落地不完全 (EM-02/06)
- **home 8 页 AppleListSection 化 100% 保持**: home_page_state / today_summary_card / home_header 无 Card 方言回潮

## 总结

- **8 项 R110 残留, 7 项 0 闭环** (EM-02/02b/05/06/07/08/09/10/11), 仅 EM-01/04/12 闭环 + EM-03/13 部分 — "R110 全绿" 后 visual 落地面停滞, 与 v0.31 视觉重设的 9.5/10 峰值形成 2.5 分 gap
- **新增 8 项 (EM-14~21), P1 3 项**: EM-14 disabled 假反馈 (全库一致性债)、EM-16 对比度 1.9:1 (0.5h 可修)、EM-21 en 中文 mood 标签 (1-2d, 也是真 i18n bug)
- **评分**: token/集中器层 9/10, 落地层 (残留方言 + 假反馈 + a11y + i18n) 6/10, 加权 ≈ 7.5/10
- **下轮优先**: 3 个 P1 (≤3h 总量) 一次性清掉, 即可回 8.5/10; EM-02/02b 合并成 "Card 方言 → AppleListSection" 专项 (settings/vent/assessment/mood_detail/reminders_hub, 约 1-2d)
