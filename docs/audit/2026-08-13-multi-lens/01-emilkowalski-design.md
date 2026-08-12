# emilkowalski 设计工程视角审计 (2026-08-13)

基线: R32 21 P0 大部分落地 (IconButton→PressFeedback / PageScaffold translucent / home stagger 8→3 / haptics 集中)。工作树 uncommitted lib/ 改动 = 纯 dart format 重排, 零视觉 delta → transient, 排除。

## Findings

| ID | 类别 | 标题 | 证据 | 难度 | 优先级 |
|---|---|---|---|---|---|
| EM-01 | 视觉 | **mood 双色板漂移**: mood_visual.colorArgbFor (旧灰蓝) vs AppColors.kMoodScoreColors (iOS 板) 两屏不同语言 | mood_visual.dart:84-99 / app_colors.dart:489-501 / mood_detail_page.dart:64 | ≤0.5h | **P1** |
| EM-02 | 一致性 | 8 个 feature 未 AppleListSection 化: mood/mood_list/vent/assessment/contact/crisis_hotline/settings/daily_tracking 仍 Card+ListTile | contacts_list_widget.dart:47-55 / mood_detail_page.dart:43 / settings/widgets/* | 1-2d（跨 feature） | **P1** |
| EM-02b | 一致性 | 两种 section header 并存: SectionHeader 11pt vs AppleListSection 13pt, trend 页混用 | section_header.dart:75 / apple_list_section.dart:99 | ≤2h | P2 |
| EM-03 | 架构 | Spring.of(context) 是 stub (context 忽略 + ignore unused), gentle/bouncy 0 caller, 只有 standard 接线 | spring.dart:133-144 / check_in_button.dart:236-243 | ≤2h | P1 |
| EM-04 | a11y | reduce-transparency 死代码: `platform == iOS && false` 恒 false, 且错用 disableAnimations 代理 | page_scaffold.dart:61-65 | ≤0.5h | P1 |
| EM-05 | 一致性 | 5 处 raw SnackBar 绕过 AppSnackBar 集中器 | quick_mood_carousel.dart:92 / crisis_hotline_page.dart:221,250 / medication_calendar_page.dart:246 / daily_tracking_widgets.dart:106 | ≤0.5h | P2 |
| EM-06 | 视觉 | mood_detail 分数 28pt w700 — 唯一大数字却不用 ultralight 度量语言; 顶卡是 raw Card 而非 StatCard | mood_detail_page.dart:43-87 | ≤0.5h | P2 |
| EM-07 | tokens | fl_chart tooltip Colors.white 硬编码 | mood_trend_page.dart:267,283,540 | ≤0.5h | P3 |
| EM-08 | tokens | 4 处 raw TextStyle(fontSize:) | add_medication_page.dart:390 / medication_detail_page.dart:346 / cbt_three_column_mode.dart:44,56 / mood_trend_page.dart:383 | ≤0.5h | P3 |
| EM-09 | 一致性 | _ChipBadge 重复 2 份 (apple_list_section + section_header) | apple_list_section.dart:232-256 | ≤0.5h | P3 |
| EM-10 | 视觉 | done 态 CheckInButton 仍给 press scale 动画, iOS disabled 应 inert | check_in_button.dart:72-91 | ≤2h | P3 |
| EM-11 | spec | spec §5.5 72pt mood 按钮未落地 (仍 48px 旧对话框) | mood_list/* | >1w | P3 |
| EM-12 | 细节 | AppleHealthTile 140×110 在 Expanded 网格被覆盖, 110pt 高度值可能贴 clip | apple_health_tile.dart:72-103 | ≤2h | P3 |
| EM-13 | 一致性 | MoodVisual.labelFor 与 ARB moodLabelN 双源 | mood_visual.dart:76 | ≤0.5h | P3 |

## 验证健康项

5 token 集中器 100% 采纳 · 0 硬编码 Color(0x…) / radius · transition 3 类全走 Motion.duration (reduce-motion aware) · shimmer <1.2s + 600ms pause + jump-to-final · EmptyState 17 / ErrorState 9 / LoadingSkeleton 26 caller · haptics (feedback.dart) 统一 · CardTheme 0-elevation 安全网

## 总结

1) mood 色板分裂 (EM-01 最快 P1); 2) 半屏 app 仍在旧 Card+ListTile 方言 (EM-02 最大一致性债); 3) Spring 是 token 不是行为 (EM-03); 4) reduce-transparency 承诺是死代码 (EM-04); 5) SnackBar/header/chip 各有 2-3 份重复拷贝, 漂移风险累积中。