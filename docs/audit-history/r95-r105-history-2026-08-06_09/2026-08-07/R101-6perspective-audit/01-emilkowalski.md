# emilkowalski UI/UX 审计报告 — R101

**审计时间**: 2026-08-07 | **总体评分**: 8.5/10

---

## P0 — Critical (3 项)

### 1. hero_illustration.dart:52 — Colors.black 硬编码 dark mode 阴影不可见
- **文件**: `lib/presentation/pages/home/widgets/hero_illustration.dart:52`
- **问题**: `color: Colors.black.withValues(alpha: 0.04)` 硬编码黑色阴影，dark mode 下完全不可见
- **修复**: 改 `Theme.of(context).colorScheme.shadow`

### 2. hero_illustration.dart:67-110 — 4 处 emoji fontSize 硬编码
- **文件**: `lib/presentation/pages/home/widgets/hero_illustration.dart:67,82,96,106`
- **问题**: `fontSize: 36/28/56/32` 裸数字不在 AppTypography token 体系
- **修复**: 在 AppSpacing 加语义化 size token

### 3. quick_mood_carousel.dart:157 — SizedBox(height: 2) 裸数字
- **文件**: `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:157`
- **问题**: `spacingXxxs = 2.0` 已存在但此处没用
- **修复**: 改 `AppTokens.spacingXxxs`

---

## P1 — Important (12 项)

| # | 文件:行 | 问题 | 修复 |
|---|---------|------|------|
| 4 | trend_assessment_chart.dart:41,46 | SizedBox(height: 8/4) 裸数字 | → spacingXs/spacingXxs |
| 5 | assessment_unavailable_card.dart:33 | SizedBox(width: 4) 裸数字 | → spacingXxs |
| 6 | hero_illustration.dart:50-56 | BoxShadow 不走 theme-aware | → shadowCardOf(context) |
| 7 | quick_mood_carousel.dart:72 | 注释说走 Haptics.success 但未调用 | 加 Haptics.success() |
| 8 | vent_detail_page.dart:266 | size: 20 硬编码 icon | → iconSizeInline 或新 token |
| 9 | setup_step_done.dart:67-81 | 6 处 Text(l10n.xxx) 缺 TextStyle | 加 textStyleBody |
| 10 | vent_detail_page.dart:348 | Slider 缺 Semantics label | 包 AppSemantics |
| 11 | app_theme.dart:59-94 | TextTheme 缺 headlineSmall/titleMedium/bodySmall/labelSmall | 补全 slot |
| 12 | home_header.dart:39-58 | 3 个 IconButton tooltip→Semantics 验证 | 加 widget test |
| 13 | medication_calendar_page.dart:212 | 绕过 AppSnackBar 集中器 | → AppSnackBar.showInfo |
| 14 | setup_step_medication.dart:192 | hintText: '40' 硬编码 | 加 ARB key |
| 15 | contacts_list_widget.dart:199 | hintText: '13800138000' 硬编码 | 加 ARB key |

---

## P2 — Nice-to-have (15 项)

| # | 问题 | 修复 |
|---|------|------|
| 16 | InkSparkle shader 确认 assets/shaders/ 存在 | 确认 |
| 17 | check_in_button 成功无微弹效果 | 加 AnimatedScale |
| 18 | home_fab_toolbar FAB 56×56 硬编码 | 加 fabSize token |
| 19 | home_fab_toolbar icon size: 18 硬编码 | → iconSizeInline |
| 20 | quick_mood_carousel height: 80 硬编码 | 加 token |
| 21 | secondary_action_row icon size: 20 硬编码 | → iconSizeInline |
| 22 | vent_detail_page icon size: 32 硬编码 | → iconSizeLg |
| 23 | trend_page RefreshIndicator 缺 semanticsLabel | 加 ARB key |
| 24 | vent_list_page RefreshIndicator 缺 semanticsLabel | 加 ARB key |
| 25 | setup_step_consent.dart:117 onView: () {} 空回调 | 链接到声明 dialog |
| 26 | medication_calendar_page cell 点击无 Haptic | 加 Haptics.tap() |
| 27 | trend_page list/calendar 切换无 Haptic | 加 Haptics.tap() |
| 28 | assessment_page 选项选择无 Haptic | 加 Haptics.tap() |
| 29 | DividerTheme thickness/space: 1 硬编码 | 加 token |
| 30 | setup_step_welcome spacingXl=80 顶部间距过大 | 改 spacingLg |

---

## P3 — Minor (8 项)

31-38: section_header _ChipBadge vertical:2 / app_tokens 6 size 未走子模块 / mood 目录结构 / check_in 目录不存在 / carousel 间距偏窄 / InputChip PressFeedback / vent maxLength / setup 进度指示器

---

## 架构亮点 (10 项)
1. Motion 类 + prefers-reduced-motion (前庭敏感)
2. PressFeedback scale 0.97 (30+ 处)
3. Haptics 4 档
4. EmptyState/ErrorState 集中器
5. PageTransitionSwitcher
6. AppSnackBar.showXxx
7. InfoBanner 4 tone
8. AppSemantics 3 工厂
9. CelebrationBounce + RepaintBoundary
10. LoadingSkeleton 呼吸模式
