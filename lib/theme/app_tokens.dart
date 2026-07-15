import 'package:flutter/material.dart';

/// 慢病管家 · 设计 Token 规范
/// v0.5 · 2026-07-12 增加 dark 颜色 + 响应式断点
class AppTokens {
  AppTokens._();

  // ============= 品牌色（亮/暗通用）=============
  /// 主色：嫩绿（萌芽意象，呼应"还在坚持"）
  static const Color primary = Color(0xFF6BCF7F);

  /// 主色 - 按下态
  static const Color primaryDark = Color(0xFF4FB05F);

  // ============= 亮色色板（v0.4 已有）=============
  static const Color primaryLight = Color(0xFFE8F8EC);
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color border = Color(0xFFE0E0E0);
  static const Color disabled = Color(0xFFBDBDBD);
  static const Color divider = Color(0xFFF0F0F0);

  // ============= 暗色色板（v0.5 新增）=============
  // 注意：M3 实际用 ColorScheme.fromSeed 派生；这里是兜底色，
  // 仅当 widget 硬编码 AppTokens.xxx 时（dark mode 下视觉会偏色）
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textPrimaryDark = Color(0xFFE6E6E6);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textHintDark = Color(0xFF7A7A7A);
  static const Color borderDark = Color(0xFF2A2A2A);
  static const Color dividerDark = Color(0xFF242424);
  static const Color disabledDark = Color(0xFF4A4A4A);
  static const Color primaryLightDark = Color(0xFF1F3A26);

  // 状态色（仅 3 个，亮/暗共用，error 在暗色下提亮）
  static const Color success = primary;
  static const Color warning = Color(0xFFFFB74D);
  // v0.14 加重度色阶：比 warning 更橙，用于"中度"档（比"轻度"更警示）
  static const Color warningStrong = Color(0xFFFF8A65);
  static const Color error = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFEF9A9A);

  // ============= 字体 =============
  static const double fontSizeTitle = 28.0;
  static const double fontSizeHeadline = 24.0;
  static const double fontSizeButton = 20.0;
  static const double fontSizeBody = 18.0;
  static const double fontSizeLabel = 16.0;
  static const double fontSizeCaption = 14.0;

  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightLoose = 1.8;

  // ============= 间距 =============
  static const double spacingXs = 8.0;
  static const double spacingSm = 16.0;
  static const double spacingMd = 24.0;
  static const double spacingLg = 40.0;
  static const double spacingXl = 80.0;

  static const double pageMarginH = 16.0;
  static const double pageMarginV = 24.0;

  // ============= 圆角 =============
  static const double radiusButton = 24.0;
  static const double radiusCard = 16.0;
  static const double radiusInput = 12.0;
  static const double radiusChip = 8.0;

  // ============= 尺寸 =============
  static const double buttonHeight = 88.0;
  static const double buttonHeightSmall = 56.0;
  static const double minTapArea = 48.0;
  static const double inputHeight = 56.0;
  static const double iconSize = 24.0;
  static const double iconSizeLg = 32.0;

  // ============= 动画 =============
  static const Duration durFast = Duration(milliseconds: 200);
  static const Duration durNormal = Duration(milliseconds: 300);
  static const Duration durSlow = Duration(milliseconds: 500);

  // ============= 阴影 =============
  static const List<BoxShadow> shadowCard = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowCardDark = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowDialog = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // ============= 响应式断点 =============
  // Material 3 推荐的 window size class 边界
  /// 紧凑（手机竖屏）：< 600
  static const double breakpointCompact = 600;

  /// 中等（手机横屏 / 小平板）：600 - 840
  static const double breakpointMedium = 840;

  /// 扩展（桌面 / 大平板）：>= 840
  static const double breakpointExpanded = 840;

  /// 内容最大宽度（窄屏时不限；宽屏时居中显示）
  static const double contentMaxWidth = 720.0;

  /// NavigationRail 宽度（仅 >= breakpointExpanded 时显示）
  static const double navRailWidth = 80.0;
  static const double navRailExtendedWidth = 240.0;
}

/// 便捷判断当前窗口尺寸
enum WindowSize { compact, medium, expanded }

WindowSize windowSizeOf(double width) {
  if (width < AppTokens.breakpointMedium) return WindowSize.compact;
  if (width < AppTokens.breakpointExpanded) return WindowSize.medium;
  return WindowSize.expanded;
}
