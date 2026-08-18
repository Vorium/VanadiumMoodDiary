// v0.31 round 1 (Apple Health redesign · Phase 1 Task 1.1):
// 颜色 token 从 M3 嫩绿系 → Apple Health iOS system color + 8 metric palette。
//
// 历史:
// - v0.27 round 65 (alibaba B16 god constant 拆分): 颜色 token 独立
//   拆解前: app_tokens.dart 644 行混合 8 大类 (颜色/字号/间距/圆角/动效/alpha/
//   shadow/业务 + MotionScheme + Motion) god constant。
//   拆解后:
//     - app_colors.dart     (~250 行) 颜色 + dynamic getter + tintedXxx + fgXxx
//     - app_typography.dart (~150 行) 字号 + 行高 + TextStyle helper
//     - app_spacing.dart    (~120 行) 间距 + 圆角 + 尺寸 + 断点
//     - app_motion.dart     (~200 行) duration + curve + shadow + MotionScheme + Motion
//     - app_tokens.dart     (≤50 行)  facade 入口, static const re-export, 老 caller 不动
//
// - v0.31 round 1 (本轮 Apple Health redesign):
//   改 8 个 light 静态 const (background / surface / textPrimary / textSecondary /
//     textHint / border / divider / primary / primaryDark) → iOS 风格
//   改 3 个 dark 静态 const (backgroundDark / surfaceDark / textPrimaryDark)
//   新增 healthMetricsColors (8 iOS system colors) + healthMetricsIds +
//     healthMetricsColorFor (v0.32 R112 AH-16: tintedMetricSoft 0 caller 删)
//   保留 success / warning / error / 16 个 dynamic getter / 现有 18 个 dark 静态 const
//
// 设计原则:
// - 单一职责: 颜色 + tinted + fg + health metric palette 全部在 AppColors 一处
// - 老 caller 兼容: `AppTokens.primary` 仍能用 (走 facade static const 转发)
// - 新 caller 鼓励: `AppColors.primary` / `AppColors.healthMetricsColorFor(id)`
// - 跟 Material 3 ColorScheme 桥接: dynamic getter 走 Theme.of(context).colorScheme
// - metric palette 跨 light/dark 用同色: 趋势/图标需要稳定视觉标识, 跟 R90 assessment
//   palette 风格一致
import 'package:flutter/material.dart';

/// v0.27 round 65 (alibaba B16 god constant 拆分): 颜色 token 集中器
///
/// v0.31 round 1 (Apple Health redesign): 加 8 iOS system metric palette
///
/// 5 大类:
/// 1. **静态 const Color** (light/dark 二选一, 不依赖 BuildContext)
/// 2. **Dynamic color getter** (接受 BuildContext, 走 M3 ColorScheme 适配)
/// 3. **Tinted color getter** (alpha 0.08-0.85 调色, 软背景用)
/// 4. **Foreground color getter** (text on top, 走 M3 onXxx)
/// 5. **Health metric palette** (8 iOS system color, 跨 light/dark 稳定)
class AppColors {
  AppColors._();

  // ============= 品牌色（亮/暗通用）=============
  /// v0.31 R1 (Apple Health redesign): 主色 → iOS systemGreen
  /// (原 0xFF6BCF7F 嫩绿偏冷; iOS 0xFF34C759 更鲜亮, 是 Apple Health "favorites" 标准绿)
  /// 决策记录: spec.md §6 决策 #1 ✅ 用户已确认
  static const Color primary = Color(0xFF34C759);

  /// v0.31 R1: 主色按下态 → iOS systemGreen dark
  static const Color primaryDark = Color(0xFF248A3D);

  // ============= 亮色色板 =============
  static const Color primaryLight = Color(0xFFE8F8EC);

  /// v0.31 R1: 背景 → iOS systemGroupedBackground (#F2F2F7)
  static const Color background = Color(0xFFF2F2F7);

  /// 卡片/容器表面 — 纯白不变
  static const Color surface = Color(0xFFFFFFFF);

  /// v0.31 R1: 主文字 → iOS label 纯黑 (#000000, light mode)
  static const Color textPrimary = Color(0xFF000000);

  /// v0.31 R1: 次要文字 → iOS secondaryLabel (3C3C43 @ 60% alpha, const 取底色)
  /// const 不能带 alpha; dynamic getter textSecondaryColor(c) 走 M3 onSurfaceVariant
  /// 已自动应用 60% alpha。static const 仅给"硬编码背景"场景兜底, 实际 widget 走 getter。
  static const Color textSecondary = Color(0xFF3C3C43);

  /// v0.31 R1: 提示文字 → iOS tertiaryLabel (3C3C43 @ 30% alpha, const 取底色)
  static const Color textHint = Color(0xFF3C3C43);

  /// v0.31 R1: 边框 → iOS opaqueSeparator (#C6C6C8)
  /// 跟 spec §3.1.1 "3C3C43 10% alpha / #C6C6C8" 二选一; 取后者因 const 不能带 alpha。
  /// 实际 widget 走 borderColor(c) 走 M3 outline, 自带 12% alpha 感。
  static const Color border = Color(0xFFC6C6C8);
  static const Color disabled = Color(0xFFBDBDBD);

  /// v0.31 R1: 分割线 → iOS hairline (C6C6C8 @ 40% alpha, 在白底预计算 ≈ #E8E8E9)
  /// 0.5px 视觉等效。const 不能带 alpha, 预计算到白底上的实际呈现值。
  static const Color divider = Color(0xFFE8E8E9);

  // ============= 暗色色板 =============
  // 注意：M3 实际用 ColorScheme.fromSeed 派生；这里是兜底色，
  // 仅当 widget 硬编码 AppColors.xxx 时（dark mode 下视觉会偏色）
  /// v0.31 R1: 暗色背景 → iOS 暗色纯黑 (#000000)
  static const Color backgroundDark = Color(0xFF000000);

  /// v0.31 R1: 暗色表面 → iOS secondarySystemGroupedBackground (#1C1C1E)
  static const Color surfaceDark = Color(0xFF1C1C1E);

  /// v0.31 R1: 暗色主文字 → 纯白 (#FFFFFF)
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textHintDark = Color(0xFF7A7A7A);
  static const Color borderDark = Color(0xFF2A2A2A);
  static const Color dividerDark = Color(0xFF242424);
  static const Color disabledDark = Color(0xFF4A4A4A);
  static const Color primaryLightDark = Color(0xFF1F3A26);

  // 状态色（仅 3 个，亮/暗共用，error 在暗色下提亮）
  // v0.22 round 30 (emil P1-8): success 之前 = primary（等于没用）,
  // 改成跟 warning/error 平行的 distinct green（dev 阶段提示用）
  // 实际绿色调一致（嫩绿系列），但语义独立，调用点更清晰
  static const Color success = Color(0xFF66BB6A);
  static const Color warning = Color(0xFFFFB74D);
  // v0.14 加重度色阶：比 warning 更橙，用于"中度"档（比"轻度"更警示）
  static const Color warningStrong = Color(0xFFFF8A65);
  static const Color error = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFEF9A9A);

  // 依从性热力图色阶（浅色变体，用于部分达标/接近达标）
  static const Color adherencePartial = Color(0xFFFFCC80); // 浅橙 < 50%
  static const Color adherenceAlmost = Color(0xFFA5D6A7); // 浅绿 < 100%

  // ============= Dynamic Color getter (v0.18 P1-5) =============
  //
  // **dark mode 修复**:上面 9 个静态 const color (surface/background/textPrimary/
  // textSecondary/textHint/border/divider) 是 light 模式的硬编码值。widget
  // 直接用 `AppColors.surface` 在 dark mode 下视觉错(背景白、文字白)。
  //
  // 修法：新增下面 7 个 dynamic getter,接受 BuildContext,从
  // Theme.of(context).colorScheme 派生正确颜色(M3 已经按 light/dark 派生好)。
  //
  // 后续 widget 改造时：把 `const TextStyle(color: AppColors.textHint)` 改成
  // `TextStyle(color: AppColors.textHintColor(context))`。
  //
  // 注意:dynamic getter 不能在 const constructor 里用(必须 const Color)。
  // 这是 dark mode 支持的必要 trade-off,跟 const optimization 互斥。
  //
  // v0.18 (P1-5) batch 1: 加 7 个 getter + 替换 EmptyState + vent_list 最 critical 处。
  // batch 2+ 替换剩余 90+ 处。

  /// v0.25 round 49 (emil R49 P0 #1): Theme-aware 主色 (status bar / icon 64pt /
  /// 评估大数字 / 续方 chip / 通知 banner)
  /// 之前 35+ 处裸用 `color: AppColors.primary` (static const 0xFF6BCF7F),
  /// dark mode 下该色在深色背景上对比度崩 → 用户视觉错。
  /// 修法:用 M3 colorScheme.primary 自动适配 light/dark
  static Color primaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// v0.25 round 49 (emil R49 P0 #1): Theme-aware 错误色 (错误 banner / 危机分数 / 评估 "重度" 标签)
  /// 之前 8+ 处裸用 `color: AppColors.error` (static const 0xFFE57373)
  /// 修法:用 M3 colorScheme.error 自动适配
  static Color errorColor(BuildContext context) =>
      Theme.of(context).colorScheme.error;

  /// v0.25 round 49 (emil R49 P0 #1): Theme-aware 警告色
  /// 之前 3+ 处裸用 `color: AppColors.warning` (static const 0xFFFFB74D)
  /// 修法:warning 状态色亮暗都用,沿用 const (不破坏 M3 contrast)
  static Color warningColor(BuildContext context) => AppColors.warning;

  /// v0.25 round 49 (emil R49 P0 #1): Theme-aware onSurface 弱一档 (50% alpha)
  /// 替代散落 4+ 处 `cs.onSurface.withValues(alpha: 0.5)` 硬编码
  /// 用途:次要文字 / icon disabled / list 副标题
  static Color onSurfaceMuted(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);

  /// Theme-aware surface (卡片/容器背景)
  static Color surfaceColor(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Theme-aware background (页面背景)
  static Color backgroundColor(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Theme-aware text primary (主文字)
  static Color textPrimaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// Theme-aware text secondary (次要文字,80% 透明度 onSurface)
  static Color textSecondaryColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  /// Theme-aware text hint (提示文字,60% 透明度 onSurfaceVariant)
  static Color textHintColor(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

  /// Theme-aware border (边框)
  static Color borderColor(BuildContext context) =>
      Theme.of(context).colorScheme.outline;

  /// Theme-aware divider (分割线)
  static Color dividerColor(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  /// Theme-aware primary light (主色浅底 / 选中背景)
  static Color primaryLightColor(BuildContext context) =>
      Theme.of(context).colorScheme.primaryContainer;

  /// v0.21 (P1-9 fix): Theme-aware disabled
  ///
  /// batch 1 (v0.18 P1-5) 漏了 disabled, 此前 widget 直接用
  /// `AppColors.disabled` 在 dark mode 下是浅灰 (BDBDBD), 看不见。
  /// 这里补上 getter 跟其它 8 个 dynamic color 保持一致。
  ///
  /// v0.27 round 63 (P1-3 修复): 走 M3 standard `onSurface @ 12% alpha`,
  /// 替代 hardcode `Color(0xFF4A4A4A)` / `Color(0xFFBDBDBD)` + Brightness
  /// 判。bypass 整个 M3 scheme = 重新发明 token。
  static Color disabledColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
  }

  // ============= v0.21 (P2-1 fix): Tinted surface tokens =============
  //
  // emil 原则 "good defaults matter more than options":
  // 全代码库出现 21+ 次 `X.withValues(alpha: 0.X)`, 多数是
  // warning/error/primary 的浅色背景 (提示/警告/选中态)
  // 抽成 named token 让:
  // 1. 调用点更可读 (tintedWarningSoft vs warning.withValues(alpha: 0.1))
  // 2. 未来调 alpha 集中改, 不用 grep
  // 3. 命名暗示"这是 浅色背景"用途, 防止误用
  //
  // 命名: tintedXxxSoft = alpha 0.1 左右 (默认浅背景)
  //      tintedXxxStrong = alpha 0.15+ (稍深)

  /// 主色浅色背景 (选中态, 强调底) — primary @ alpha 0.1
  static Color tintedPrimarySoft(BuildContext context) =>
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.1);

  /// 主色更深浅色背景 — primary @ alpha 0.15
  static Color tintedPrimaryDeep(BuildContext context) =>
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.15);

  /// v0.22 round 29 (emil-01~12): 主色最浅背景 (alpha 0.08) — 报告提示 / 选中极浅态
  static Color tintedPrimaryLight(BuildContext context) =>
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);

  /// 警告浅色背景 (提醒卡片) — warning @ alpha 0.1
  static Color tintedWarningSoft(BuildContext context) =>
      AppColors.warning.withValues(alpha: 0.1);

  /// v0.23 round 40 (emil F1 fix): 成功浅色背景 (已完成 chip) — 绿色 @ alpha 0.1
  /// 替代 ChipBadge.success 之前跟 neutral 配色完全一样的 bug
  static Color tintedSuccessSoft(BuildContext context) =>
      AppColors.success.withValues(alpha: 0.1);

  /// 错误浅色背景 (错误卡片) — error @ alpha 0.1
  static Color tintedErrorSoft(BuildContext context) =>
      Theme.of(context).colorScheme.error.withValues(alpha: 0.1);

  /// v0.22 round 30 (sp-zh P2-3): 错误更深浅色背景 — error @ alpha 0.15
  /// 替代散落 3 处 `error.withValues(alpha: 0.15)` 硬编码
  static Color tintedErrorDeep(BuildContext context) =>
      Theme.of(context).colorScheme.error.withValues(alpha: 0.15);

  /// v0.24 round 45 (emil P1-13): 主色中度透明 (alpha 0.5)
  /// 替代散落 5+ 处 `primary.withValues(alpha: 0.5)` 硬编码（chip / 卡片 / 弹层背景）
  static Color tintedPrimaryMid(BuildContext context) =>
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.5);

  /// v0.24 round 45 (emil P1-13): 主色高透明 (alpha 0.85)
  /// 替代散落 5+ 处 `primary.withValues(alpha: 0.85)` 硬编码（强调态 / 选中态强调）
  static Color tintedPrimaryHigh(BuildContext context) =>
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.85);

  /// v0.24 round 45 (emil P1-13 续): onSurface 50% — 按钮 disabled 前景色
  /// M3 标准是 0.38, 但项目偏弱化 0.5 (跟 textHint 区分)
  /// 替代 app_theme.dart:121 `cs.onSurface.withValues(alpha: 0.5)`
  static Color fgDisabled(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);

  /// v0.24 round 45 (emil P1-13 续): onSurfaceVariant 60% — InputDecoration hint
  /// M3 standard placeholder / caption text 颜色
  /// 替代 app_theme.dart:202 + home_footer.dart:51 两处 `cs.onSurfaceVariant.withValues(alpha: 0.6)`
  static Color fgHintInput(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

  /// v0.24 round 45 (emil P1-13 续): warning 边框 30% (notification_failure_banner)
  /// 替代 `AppColors.warning.withValues(alpha: 0.3)` 硬编码
  static Color tintedWarningBorder(BuildContext context) =>
      AppColors.warning.withValues(alpha: 0.3);

  // ============= v0.27 round 65 (alibaba B7/B8 magic alpha) =============

  /// 状态色浅色背景 (续方 / 评估状态 chip + 圆点) — alpha 0.15
  /// 替代散落 2 处 `statusColor.withValues(alpha: 0.15)` 硬编码
  /// (refill_manage_page.dart:265 + :329)
  ///
  /// 跟 tintedPrimaryDeep (0.15) 同 alpha, 但语义独立:
  /// - tintedPrimaryDeep 强调"主色"语义
  /// - tintedStatusSoft 强调"状态"语义 (任意 status color 通用)
  ///
  /// 调用方: `AppColors.tintedStatusSoft(context, statusColor)`
  static Color tintedStatusSoft(BuildContext context, Color base) =>
      base.withValues(alpha: 0.15);

  /// 趋势线 / 箭头 alpha 0.6 (中间值, 表达"非极端过渡")
  /// 替代 assessment_widgets.dart:351 `trendColor.withValues(alpha: 0.6)` 硬编码
  /// 跟 tintedPrimaryMid (0.5) 区分: 0.6 = "中等可见" 比 0.5 略强
  ///
  /// 调用方: `AppColors.tintChartLine(context, trendColor)`
  static Color tintChartLine(BuildContext context, Color base) =>
      base.withValues(alpha: 0.6);

  // v0.22 round 30 (emil P2-6): 前景色 helper 替代 Colors.white/black54
  // 之前 18 处直接 `Colors.white` (含 .withValues(alpha: 0.85)),
  // dark mode 下反白失效 (check_in_button:205 是已知 case)。
  // 用 theme-aware 替代, 自动适配 light/dark
  static Color fgOnPrimary(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;
  static Color fgOnError(BuildContext context) =>
      Theme.of(context).colorScheme.onError;
  static Color fgOnSurface(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;

  /// v0.23 round 40 (emil F1 fix): 成功前景色 — 成功 chip 文字
  ///
  /// v0.32 round 8 (R112 EM-16b fix): 深绿 #2E7D32 (Material Green 800) —
  /// 修前 `fgOnSuccess = success` 是浅绿别名 (假 token, 白底对比度仅
  /// 2.4:1, 低于 WCAG AA 4.5:1)。深绿在白底 ≈ 5.1:1, light/dark 都可读。
  static const Color fgOnSuccess = Color(0xFF2E7D32);

  /// v0.23 round 40 (emil F1 fix): 警告前景色 — 警告 chip 文字
  static const Color fgOnWarning = Color(0xFFE65100); // 深橙,在 light/dark 都可读

  /// v0.32 round 8 (R112 EM-16b fix): 错误文字前景色 — 深红 #C62828
  /// (Material Red 800, 白底 ≈ 5.6:1)
  ///
  /// 跟 [fgOnError] (dynamic getter, "on error 表面" 语义 = onError 白字,
  /// 用在错误 banner / delete 底上) 区分: 本 token 是 error 状态色**作为
  /// 文字色**用在浅底上的深色档 (emil EM-16b 同族修复, 浅红 #E57373
  /// 白底 3.0:1 不达标)。
  static const Color fgError = Color(0xFFC62828);

  /// v0.32 round 8 (R112 EM-16b fix): warningStrong 文字前景色 — 深橙
  /// #BF360C (Material Deep Orange 900, 白底 ≈ 5.6:1)
  ///
  /// warningStrong #FF8A65 白底 2.3:1 不达标, 作文字色时用本深色档
  /// (跟 fgOnWarning #E65100 同模式, 但更深一档以区分"中度"语义)。
  static const Color fgWarningStrong = Color(0xFFBF360C);

  /// v0.23 round 40 (emil F3/F8 fix): 反白弱一档 — onPrimary @ alpha 0.85
  /// 替代散落 5+ 处 `onPrimary.withValues(alpha: 0.85)` 硬编码
  /// emil "decisions should be nameable" — 0.85 不应裸用，命名 "muted"
  static Color fgOnPrimaryMuted(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.85);

  // ============= v0.30 round 90 (sub-spec 6 量表中心): 量表色板 =============
  //
  // 12 量表多色 (10 开放 + 2 unavailable 灰) — 色相分散, 色盲友好, 跟 R85
  // rerated chart 风格一致。3 线型 (实线/虚线/点线) 按 scale index % 3 循环。
  //
  // 跟 R85 风格一致: 不用 theme-aware, 固定 const Color —
  // 趋势图需要稳定的视觉标识 (跨 dark mode 同一个量表 = 同一个色),
  // dark mode 下 alpha 自动按需调。
  // 顺序固定: 跟 AssessmentColorPalette._scaleIds 一一对应, 通过
  // assessmentColorFor(scaleId, scaleIds) 拿色 / assessmentDashFor 拿线型。

  /// 3 线型 — 按 scale index % 3 循环
  /// (实线 / 虚线 / 点线, 让色盲用户也能区分)
  ///
  /// v0.30 round 91 (fix): `assessmentColors` 12 色 list 删除 — 它跟
  /// `AssessmentColorPalette.colorArgbFor(...)` (single source of truth)
  /// 重复, 2 个 source-of-truth 容易选错。`assessmentColorFor(scaleId, scaleIds)`
  /// 改走 palette (见下)。
  static const List<List<int>> assessmentDashArrays = [
    <int>[], // 实线 (index 0, 3, 6, 9)
    <int>[5, 5], // 虚线 (index 1, 4, 7, 10)
    <int>[2, 3], // 点线 (index 2, 5, 8, 11)
  ];

  /// 按 scaleId 拿色 / 拿线型 → 走 `AssessmentColorPalette` (single source)
  ///
  /// v0.30 round 91 (fix): 删除 `assessmentColorFor(scaleId, scaleIds)` /
  /// `assessmentDashFor(scaleId, scaleIds)` 旧 API — 它们跟 palette
  /// `(scaleId)` single-arg API 重复, 2 个 source-of-truth 容易选错。
  /// `AssessmentColorPalette.colorArgbFor(scaleId)` / `.dashFor(scaleId)`
  /// 是 single source of truth。

  // ============= v0.30 round 91 (sub-spec 7 日常追踪 / Task 6): 4 指标色板 =============
  //
  // 4 日常追踪指标 (体重 / 睡眠 / 心境 / 应激源) 多色多线型 —
  // 4 指标单位不同 (kg / min / 1-5 / 1-5) → Y 轴归一化 0-1
  // 4 指标分散色 (蓝/紫/绿/红) — 跟 R85 rerated chart + R90 assessment chart
  // 风格一致, 色盲友好。
  // 4 线型 (实线 / 虚线 / 点线 / 双点) 区分 4 指标, 不只靠色。
  //
  // 设计:
  // - 跟 R90 不同: 4 指标是固定枚举 (不会扩张到 N 个), 不用 palette 单独文件,
  //   直接放 AppColors 集中管理 (跟 R85 rerated 一致)
  // - 顺序固定: weight / sleep / mood / stress (跟 daily_tracking_multi_chart
  //   `_metricIds` 1:1 对应, 修改需同步)
  // - 未知 metric 兜底: 灰 0xFF9E9E9E (跟 R90 AssessmentColorPalette 同款)
  // - 不用 theme-aware, 固定 const Color — 趋势图需要稳定的视觉标识
  //   (跨 dark mode 同一个指标 = 同一个色)

  /// 4 日常追踪指标 Color (const) — 跟 dailyTrackingMetricIds index 1:1
  /// 色相分散, 色盲友好: 蓝 / 紫 / 绿 / 红
  static const List<Color> dailyTrackingColors = [
    Color(0xFF1E88E5), // 体重 蓝
    Color(0xFF8E24AA), // 睡眠时长 紫
    Color(0xFF43A047), // 心境均值 绿
    Color(0xFFE53935), // 应激源均值 红
  ];

  /// 4 日常追踪指标 id (顺序固定, 跟色 + 线型 1:1 对应)
  static const List<String> dailyTrackingMetricIds = [
    'weight',
    'sleep',
    'mood',
    'stress',
  ];

  /// 4 日常追踪指标线型 (实线/虚线/点线/双点) — 按 metric index 一一对应
  /// (fl_chart LineChartBarData.dashArray 接受 `List<int>` 表示 dash on/off 像素)
  static const List<List<int>> dailyTrackingDashArrays = [
    <int>[], // 实线 (index 0: 体重)
    <int>[5, 5], // 虚线 (index 1: 睡眠)
    <int>[2, 3], // 点线 (index 2: 心境)
    <int>[8, 3, 2, 3], // 双点 (index 3: 应激源)
  ];

  /// 按 metricId 拿色 (Color, 找不到返 0xFF9E9E9E 深灰 兜底)
  ///
  /// UI 层直接用: `AppColors.dailyTrackingColorFor(metricId)`
  static Color dailyTrackingColorFor(String metricId) {
    final idx = dailyTrackingMetricIds.indexOf(metricId);
    if (idx < 0) return const Color(0xFF9E9E9E);
    return dailyTrackingColors[idx];
  }

  /// 按 metricId 拿线型 (`List<int>`, 找不到返 const `[]` 实线 兜底)
  ///
  /// UI 层直接传给 LineChartBarData.dashArray
  static List<int> dailyTrackingDashFor(String metricId) {
    final idx = dailyTrackingMetricIds.indexOf(metricId);
    if (idx < 0) return const <int>[];
    return dailyTrackingDashArrays[idx];
  }

  // ============= v0.31 R1 (Apple Health redesign · Phase 1 Task 1.1): 8 metric palette =============
  //
  // Apple Health 标志性 "favorites" 8 彩色 metric tile 调色板, 映射到本项目 8 个
  // feature 入口 (medication / mood / vent / assessment / checkIn / trend / contact /
  // sleep)。全部走 iOS system color, 跟 spec §3.1.3 表 1:1 对应。
  //
  // 设计原则 (跟 R90 assessment color palette + R91 daily tracking 一致):
  // - 8 metric 是固定枚举 (不会扩张到 N 个), 直接放 AppColors 集中管理
  // - 顺序固定: 跟 `healthMetricsIds` 1:1 对应, 修改需同步
  // - 跨 light/dark 用同一色: 趋势/图标/tile 背景需要稳定视觉标识
  //   (跟 R90 R91 同款, dark mode 下 alpha 自动按需调)
  // - 未知 metric 兜底: 灰 0xFF9E9E9E (跟 R90 R91 同款)
  // - 不用 theme-aware, 固定 const Color

  /// 8 iOS system color (顺序固定, 跟 healthMetricsIds index 1:1)
  /// 对应 spec §3.1.3 表 8 个 metric: medication / mood / vent / assessment /
  /// checkIn / trend / contact / sleep
  static const List<Color> healthMetricsColors = [
    Color(0xFFFF3B30), // systemRed     — medication (用药 / 续方 / 提醒)
    Color(0xFFFF2D55), // systemPink    — mood (心情 / 应激)
    Color(0xFFAF52DE), // systemPurple  — vent (树洞 / 录音)
    Color(0xFF5856D6), // systemIndigo  — assessment (心理评估)
    Color(0xFF34C759), // systemGreen   — checkIn (打卡 / streak)  ← 同 primary
    Color(0xFF007AFF), // systemBlue    — trend (趋势 / 图表)
    Color(0xFFFF9500), // systemOrange  — contact (紧急联系人)
    Color(0xFF5AC8FA), // systemTeal    — sleep (睡眠 / 日常, R1 暂未接入)
  ];

  /// 8 metric id (顺序固定, 跟 healthMetricsColors index 1:1)
  /// UI 层用: `AppColors.healthMetricsColorFor('medication')` 拿对应色
  static const List<String> healthMetricsIds = [
    'medication',
    'mood',
    'vent',
    'assessment',
    'checkIn',
    'trend',
    'contact',
    'sleep',
  ];

  /// 按 metricId 拿 metric 色 (Color, 找不到返 0xFF9E9E9E 深灰 兜底)
  ///
  /// UI 层直接用: `AppColors.healthMetricsColorFor('medication')` → systemRed
  static Color healthMetricsColorFor(String metricId) {
    final idx = healthMetricsIds.indexOf(metricId);
    if (idx < 0) return const Color(0xFF9E9E9E);
    return healthMetricsColors[idx];
  }

  /// R32 (P0-26 集中器): 透明色集中器 (emil "decisions should be nameable")
  /// 替代散落 5 处 `Colors.transparent` 硬编码
  static const Color transparent = Color(0x00000000);

  /// R32 (P0-09 集中器): 6 元素药物药丸颜色 (medication_page 专用)
  ///
  /// 跟 `healthMetricsColors` (8 metric) 1:1 重叠 4 个 (绿/红/蓝/紫),
  /// 4 个 (黄/灰) 是 medication 专属 (e.g. 警示药 / 安慰剂)。
  /// 独立保留: medication 历史选择 0-5 (跟 8 metric 0-7 索引无冲突)
  static const List<Color> kMedicationPillColors = [
    Color(0xFF34C759), // 绿 (systemGreen, 跟 metric 绿重叠)
    Color(0xFFFFCC00), // 黄 (警示药, medication 专属)
    Color(0xFFFF3B30), // 红 (systemRed, 跟 metric 红重叠)
    Color(0xFF007AFF), // 蓝 (systemBlue, 跟 metric 蓝重叠)
    Color(0xFFAF52DE), // 紫 (systemPurple, 跟 metric 紫重叠)
    Color(0xFF8E8E93), // 灰 (安慰剂 / 中性, medication 专属)
  ];

  /// R32 (P0-10 集中器): 5 元素 mood 评分色板 (mood score 1-5)
  ///
  /// 顺序对应 1=最差 (红) → 5=最好 (蓝), 跟 mood_visual.dart scoreToLabel 一致。
  /// 跟 healthMetricsColors (8 metric) 跟 assessmentPalette (12 量表色) 不打通,
  /// 因此独立保留 (R91 删了 12 色 list 重复, 但 5 元 mood 没纳入)。
  static const List<Color> kMoodScoreColors = [
    Color(0xFFFF3B30), // 1 - 红 (systemRed, 跟 metric 红重叠)
    Color(0xFFFF9500), // 2 - 橙 (systemOrange, mood 专属)
    Color(0xFFFFCC00), // 3 - 黄 (systemYellow, 跟 medication 警示药黄重叠)
    Color(0xFF34C759), // 4 - 绿 (systemGreen, 跟 metric 绿重叠)
    Color(0xFF007AFF), // 5 - 蓝 (systemBlue, 跟 metric 蓝重叠)
  ];

  /// R32 (P0-10 helper): mood score 1-5 → 对应色 (越界 fallback 4=绿中性)
  static Color moodScoreColor(int score) {
    if (score < 1 || score > 5) return const Color(0xFF34C759);
    return kMoodScoreColors[score - 1];
  }

  /// v1.1.0 R114 (Wave D spec §5.5): mood score 文字前景色板 (1-5)
  ///
  /// 5 档圆形按钮下方 label 选中态文字色。浅色状态色 (kMoodScoreColors) 白底
  /// 对比度 1.9~2.4:1 不达标, 作文字色必须走深色档 (跟 R112 EM-16b 同族):
  /// - 1 → fgError 深红 #C62828 (5.6:1)
  /// - 2 → fgWarningStrong 深橙 #BF360C (5.6:1)
  /// - 3 → fgOnWarning 深橙 #E65100 (4.5:1+)
  /// - 4 → fgOnSuccess 深绿 #2E7D32 (5.1:1)
  /// - 5 → primaryDark 品牌深绿 #248A3D (primary #34C759 白底 2.1:1 不达标)
  static const List<Color> kMoodScoreFgColors = [
    fgError, // 1 - 深红
    fgWarningStrong, // 2 - 深橙
    fgOnWarning, // 3 - 深橙
    fgOnSuccess, // 4 - 深绿
    primaryDark, // 5 - 品牌深绿
  ];

  /// R114 helper: mood score 1-5 → 文字前景色 (越界 fallback 4=深绿)
  static Color moodScoreFgColor(int score) {
    if (score < 1 || score > 5) return fgOnSuccess;
    return kMoodScoreFgColors[score - 1];
  }
}
