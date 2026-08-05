// v0.27 round 65 (alibaba B16 god constant 拆分收尾): app_tokens.dart 瘦身
//
// 拆解前: 644 行 god constant 8 大类混合 (颜色/字号/间距/圆角/动效/alpha/
// shadow/业务 + MotionScheme + Motion)。
// 拆解后: app_tokens.dart ≤50 行 facade, 4 个子文件:
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_motion.dart';
import 'package:chroniccare/core/theme/app_spacing.dart';
import 'package:chroniccare/core/theme/app_typography.dart';
import 'package:flutter/material.dart'
    show Color, Curve, TextStyle, BuildContext, BoxShadow;

// Re-export top-level symbols (Motion / MotionScheme / WindowSize / windowSizeOf)
// 让老 import `package:chroniccare/core/theme/app_tokens.dart` 的 caller
// 仍能直接用 `Motion.xxx` / `MotionScheme.standard` / `windowSizeOf(w)`。
export 'package:chroniccare/core/theme/app_motion.dart'
    show Motion, MotionScheme, MotionSchemeTokens;
export 'package:chroniccare/core/theme/app_spacing.dart'
    show WindowSize, windowSizeOf;

/// v0.27 round 65 (alibaba B16 god constant 拆分): 慢病管家 · 设计 Token 规范
///
/// **facade 入口**: 老 caller 走 `AppTokens.xxx` 不变, 内部走 4 个子模块
/// static const 转发。新 caller 推荐走子模块 (AppColors / AppTypography /
/// AppSpacing / AppMotion) — 单一职责, 改动一处生效。
///
/// 命名空间映射 (1:1 对应 4 子模块):
/// - AppColors     → 颜色 + tinted + fg + dynamic color getter
/// - AppTypography → fontSize + lineHeight + TextStyle helper
/// - AppSpacing    → spacing + radius + size + breakpoint
/// - AppMotion     → duration + curve + shadow + MotionScheme + Motion
///
/// 历史版本:
/// - v0.5  · 2026-07-12 增加 dark 颜色 + 响应式断点
/// - v0.18 · 2026-07-18 (P1-5) 增加 dynamic Color getter,支持 dark mode
/// - v0.27 R65 · 拆 4 文件, 留 facade
class AppTokens {
  AppTokens._();

  // ===== AppColors (颜色) — 全部转发 =====
  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color primaryLight = AppColors.primaryLight;
  static const Color background = AppColors.background;
  static const Color surface = AppColors.surface;
  static const Color textPrimary = AppColors.textPrimary;
  static const Color textSecondary = AppColors.textSecondary;
  static const Color textHint = AppColors.textHint;
  static const Color border = AppColors.border;
  static const Color disabled = AppColors.disabled;
  static const Color divider = AppColors.divider;
  static const Color backgroundDark = AppColors.backgroundDark;
  static const Color surfaceDark = AppColors.surfaceDark;
  static const Color textPrimaryDark = AppColors.textPrimaryDark;
  static const Color textSecondaryDark = AppColors.textSecondaryDark;
  static const Color textHintDark = AppColors.textHintDark;
  static const Color borderDark = AppColors.borderDark;
  static const Color dividerDark = AppColors.dividerDark;
  static const Color disabledDark = AppColors.disabledDark;
  static const Color primaryLightDark = AppColors.primaryLightDark;
  static const Color success = AppColors.success;
  static const Color warning = AppColors.warning;
  static const Color warningStrong = AppColors.warningStrong;
  static const Color error = AppColors.error;
  static const Color errorDark = AppColors.errorDark;
  static const Color adherencePartial = AppColors.adherencePartial;
  static const Color adherenceAlmost = AppColors.adherenceAlmost;
  static const Color fgOnSuccess = AppColors.fgOnSuccess;
  static const Color fgOnWarning = AppColors.fgOnWarning;

  // ===== AppTypography (字体 + TextStyle) — 全部转发 =====
  static const double fontSizeTitle = AppTypography.fontSizeTitle;
  static const double fontSizeHeadline = AppTypography.fontSizeHeadline;
  static const double fontSizeButton = AppTypography.fontSizeButton;
  static const double fontSizeBody = AppTypography.fontSizeBody;
  static const double fontSizeLabel = AppTypography.fontSizeLabel;
  static const double fontSizeCaption = AppTypography.fontSizeCaption;
  static const double fontSizeMicro = AppTypography.fontSizeMicro;
  static const double fontSizeXxxSmall = AppTypography.fontSizeXxxSmall;
  static const double fontSizeBodySm = AppTypography.fontSizeBodySm;
  static const double fontSizeCaptionSm = AppTypography.fontSizeCaptionSm;
  static const double fontSizeLabelSm = AppTypography.fontSizeLabelSm;
  static const double fontSizeScoreLg = AppTypography.fontSizeScoreLg;
  static const double fontSizeScoreXl = AppTypography.fontSizeScoreXl;
  static const double fontSizeScoreXxl = AppTypography.fontSizeScoreXxl;
  static const double lineHeightTight = AppTypography.lineHeightTight;
  static const double lineHeightNormal = AppTypography.lineHeightNormal;
  static const double lineHeightLoose = AppTypography.lineHeightLoose;
  static const double lineHeightSnug = AppTypography.lineHeightSnug;
  static const double lineHeightRelaxed = AppTypography.lineHeightRelaxed;
  static TextStyle textStyleTitle(BuildContext c) =>
      AppTypography.textStyleTitle(c);
  static TextStyle textStyleHeadline(BuildContext c) =>
      AppTypography.textStyleHeadline(c);
  static TextStyle textStyleBody(BuildContext c) =>
      AppTypography.textStyleBody(c);
  static TextStyle textStyleBodyStrong(BuildContext c) =>
      AppTypography.textStyleBodyStrong(c);
  static TextStyle textStyleLabel(BuildContext c) =>
      AppTypography.textStyleLabel(c);
  static TextStyle textStyleLabelStrong(BuildContext c) =>
      AppTypography.textStyleLabelStrong(c);
  static TextStyle textStyleButton(BuildContext c) =>
      AppTypography.textStyleButton(c);
  static TextStyle textStyleButtonInverse(BuildContext c) =>
      AppTypography.textStyleButtonInverse(c);
  static TextStyle textStyleCaption(BuildContext c) =>
      AppTypography.textStyleCaption(c);
  static TextStyle textStyleCaptionStrong(BuildContext c) =>
      AppTypography.textStyleCaptionStrong(c);
  static TextStyle textStyleMicro(BuildContext c) =>
      AppTypography.textStyleMicro(c);
  static TextStyle textStyleLabelMedium(BuildContext c) =>
      AppTypography.textStyleLabelMedium(c);
  static TextStyle textStyleCaptionHint(BuildContext c) =>
      AppTypography.textStyleCaptionHint(c);
  static TextStyle textStyleLegal(BuildContext c) =>
      AppTypography.textStyleLegal(c);
  static TextStyle textStyleMono(BuildContext c, {double? size}) =>
      AppTypography.textStyleMono(c, size: size);

  // ===== AppSpacing (间距/圆角/尺寸/断点) — 全部转发 =====
  static const double spacingXs = AppSpacing.spacingXs;
  static const double spacingSm = AppSpacing.spacingSm;
  static const double spacingMd = AppSpacing.spacingMd;
  static const double spacingLg = AppSpacing.spacingLg;
  static const double spacingXl = AppSpacing.spacingXl;
  static const int staggerStepMs = AppSpacing.staggerStepMs;
  static const int staggerCapMs = AppSpacing.staggerCapMs;
  static const double spacingXxs = AppSpacing.spacingXxs;
  static const double spacingXxxs = AppSpacing.spacingXxxs;
  static const double spacingChipGap = AppSpacing.spacingChipGap;
  static const double spacingChipGapInline = AppSpacing.spacingChipGapInline;
  static const double spacingChipPaddingH = AppSpacing.spacingChipPaddingH;
  static const double spacingChipPaddingV = AppSpacing.spacingChipPaddingV;
  static const int textLengthWarningThreshold =
      AppSpacing.textLengthWarningThreshold;
  static const int celebrationDisplayMs = AppSpacing.celebrationDisplayMs;
  static const Duration kDeepLinkRaceGuard = AppSpacing.kDeepLinkRaceGuard;
  static const double pageMarginH = AppSpacing.pageMarginH;
  static const double pageMarginV = AppSpacing.pageMarginV;
  static const double radiusButton = AppSpacing.radiusButton;
  static const double radiusCard = AppSpacing.radiusCard;
  static const double radiusInput = AppSpacing.radiusInput;
  static const double radiusChip = AppSpacing.radiusChip;
  static const double radiusCell = AppSpacing.radiusCell;
  static const double radiusCellLg = AppSpacing.radiusCellLg;
  static const double buttonHeight = AppSpacing.buttonHeight;
  static const double buttonHeightSmall = AppSpacing.buttonHeightSmall;
  static const double minTapArea = AppSpacing.minTapArea;
  static const double inputHeight = AppSpacing.inputHeight;
  static const double iconSize = AppSpacing.iconSize;
  static const double iconSizeLg = AppSpacing.iconSizeLg;
  static const double iconSizeMicro = AppSpacing.iconSizeMicro;
  static const double iconSizeInline = AppSpacing.iconSizeInline;
  static const double iconSizeSmall = AppSpacing.iconSizeSmall;
  static const double iconSizeEmpty = AppSpacing.iconSizeEmpty;
  static const double iconSizeError = AppSpacing.iconSizeError;
  // v0.27 R70 (emil B-5 重构): atomic size token 集中化
  // 替代 8+ 处 SizedBox(width: 10/12/36/40/110, height: ...) magic
  static const double legendDotSizeLg = 12; // 图例大点 (medication_calendar 7天视图)
  static const double legendDotSizeSm = 10; // 图例小点 (trend_assessment_chart)
  static const double avatarSizeSm = 36; // avatar 小 (refill_manage_page)
  static const double avatarSizeMd =
      40; // avatar 中 (reminder_cards + assessment_history_list)
  static const double buttonWidthNarrow =
      110; // 窄按钮 (setup_step_medication '下一步')
  static const double buttonHeightCompact =
      44; // 紧凑按钮高度 (跟 buttonHeight 一致但语义不同)
  static const int shimmerPauseMs = AppSpacing.shimmerPauseMs;
  static const double chartPlaceholderHeight =
      AppSpacing.chartPlaceholderHeight;
  static const double eventTimeColWidth = AppSpacing.eventTimeColWidth;
  static const double calendarLabelWidth = AppSpacing.calendarLabelWidth;
  static const double breakpointCompact = AppSpacing.breakpointCompact;
  static const double breakpointMedium = AppSpacing.breakpointMedium;
  static const double breakpointExpanded = AppSpacing.breakpointExpanded;
  static const double contentMaxWidth = AppSpacing.contentMaxWidth;
  static const double navRailWidth = AppSpacing.navRailWidth;
  static const double navRailExtendedWidth = AppSpacing.navRailExtendedWidth;

  // ===== AppMotion (动效/阴影) — 全部转发 =====
  static const Duration durFast = AppMotion.durFast;
  static const Duration durNormal = AppMotion.durNormal;
  static const Duration durSlow = AppMotion.durSlow;
  static const Duration durPress = AppMotion.durPress;
  static const int shimmerCycleMs = AppMotion.shimmerCycleMs;
  static const Duration durPageTransition = AppMotion.durPageTransition;
  static const int refreshMinVisibleMs = AppMotion.refreshMinVisibleMs;
  static const Duration snackBarDurationShort = AppMotion.snackBarDurationShort;
  static const Duration snackBarDurationMedium =
      AppMotion.snackBarDurationMedium;
  static const Duration snackBarDurationLong = AppMotion.snackBarDurationLong;
  static const Curve curveStandard = AppMotion.curveStandard;
  static const Curve curveSubtle = AppMotion.curveSubtle;
  static const Curve curveDecelerate = AppMotion.curveDecelerate;
  static const Curve curveAccelerate = AppMotion.curveAccelerate;
  static const Curve curveDelight = AppMotion.curveDelight;
  static const Curve curveBackOut = AppMotion.curveBackOut;

  // ===== AppColors dynamic getter — 全部转发 (R65 兼容老 caller) =====
  static Color primaryColor(BuildContext c) => AppColors.primaryColor(c);
  static Color errorColor(BuildContext c) => AppColors.errorColor(c);
  static Color warningColor(BuildContext c) => AppColors.warningColor(c);
  static Color onSurfaceMuted(BuildContext c) => AppColors.onSurfaceMuted(c);
  static Color surfaceColor(BuildContext c) => AppColors.surfaceColor(c);
  static Color backgroundColor(BuildContext c) => AppColors.backgroundColor(c);
  static Color textPrimaryColor(BuildContext c) =>
      AppColors.textPrimaryColor(c);
  static Color textSecondaryColor(BuildContext c) =>
      AppColors.textSecondaryColor(c);
  static Color textHintColor(BuildContext c) => AppColors.textHintColor(c);
  static Color borderColor(BuildContext c) => AppColors.borderColor(c);
  static Color dividerColor(BuildContext c) => AppColors.dividerColor(c);
  static Color primaryLightColor(BuildContext c) =>
      AppColors.primaryLightColor(c);
  static Color disabledColor(BuildContext c) => AppColors.disabledColor(c);
  static Color tintedPrimarySoft(BuildContext c) =>
      AppColors.tintedPrimarySoft(c);
  static Color tintedPrimaryDeep(BuildContext c) =>
      AppColors.tintedPrimaryDeep(c);
  static Color tintedPrimaryLight(BuildContext c) =>
      AppColors.tintedPrimaryLight(c);
  static Color tintedWarningSoft(BuildContext c) =>
      AppColors.tintedWarningSoft(c);
  static Color tintedSuccessSoft(BuildContext c) =>
      AppColors.tintedSuccessSoft(c);
  static Color tintedErrorSoft(BuildContext c) => AppColors.tintedErrorSoft(c);
  static Color tintedErrorDeep(BuildContext c) => AppColors.tintedErrorDeep(c);
  static Color tintedPrimaryMid(BuildContext c) =>
      AppColors.tintedPrimaryMid(c);
  static Color tintedPrimaryHigh(BuildContext c) =>
      AppColors.tintedPrimaryHigh(c);
  static Color fgDisabled(BuildContext c) => AppColors.fgDisabled(c);
  static Color fgHintInput(BuildContext c) => AppColors.fgHintInput(c);
  static Color tintedWarningBorder(BuildContext c) =>
      AppColors.tintedWarningBorder(c);
  static Color fgOnPrimary(BuildContext c) => AppColors.fgOnPrimary(c);
  static Color fgOnError(BuildContext c) => AppColors.fgOnError(c);
  static Color fgOnSurface(BuildContext c) => AppColors.fgOnSurface(c);
  static Color fgOnPrimaryMuted(BuildContext c) =>
      AppColors.fgOnPrimaryMuted(c);

  // ===== AppMotion dynamic shadow getter — 全部转发 (R65 兼容老 caller) =====
  static List<BoxShadow> shadowCardOf(BuildContext c) =>
      AppMotion.shadowCardOf(c);
  static List<BoxShadow> shadowCardDarkOf(BuildContext c) =>
      AppMotion.shadowCardDarkOf(c);
  static List<BoxShadow> shadowDialogOf(BuildContext c) =>
      AppMotion.shadowDialogOf(c);
  static List<BoxShadow> shadowOverlayOf(BuildContext c) =>
      AppMotion.shadowOverlayOf(c);

  // v0.27 round 65 (alibaba B9 magic alpha): scrim alpha 转发
  // long-task modal 0.54 (medication_report_dialog)
  static const double scrimAlpha = AppMotion.scrimAlpha;

  // ===== v0.30 round 91 (fix): 删除 `assessmentColors` / `assessmentColorFor` / `assessmentDashFor` 转发 =====
  //
  // 之前 round 90 在 `AppTokens` + `AppColors` 重复暴露色板 forwarder,
  // 跟 `AssessmentColorPalette.colorArgbFor(scaleId)` single-arg API 冲突
  // (2 个 source-of-truth)。round 91 删 4 个 forwarder, caller 统一走
  // `AssessmentColorPalette.colorArgbFor(scaleId)` / `.dashFor(scaleId)`。
  //
  // `assessmentDashArrays` (3 线型 list) 保留: 它是 R85 rerated chart 等
  // 老 caller 引用的 const list, R90 没用上 (chart 走 palette.dashFor),
  // 但删除需要 grep 排查, 留 R92 batch 处理。
  static const List<List<int>> assessmentDashArrays =
      AppColors.assessmentDashArrays;
}
