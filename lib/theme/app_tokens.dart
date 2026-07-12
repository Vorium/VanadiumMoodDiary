import 'package:flutter/material.dart';

/// 慢病管家 · 设计 Token 规范
/// v0.4 · 2026-07-11
/// 详细规范见 /workspace/prd-chronic-disease-app/design-tokens.md
class AppTokens {
  AppTokens._();

  // ============= 颜色 =============
  /// 主色：嫩绿（萌芽意象，呼应"还在坚持"）
  static const Color primary = Color(0xFF6BCF7F);

  /// 主色 - 按下态
  static const Color primaryDark = Color(0xFF4FB05F);

  /// 主色 - 背景态
  static const Color primaryLight = Color(0xFFE8F8EC);

  /// 页面背景
  static const Color background = Color(0xFFFAFAFA);

  /// 卡片/表面
  static const Color surface = Color(0xFFFFFFFF);

  /// 主文字
  static const Color textPrimary = Color(0xFF1A1A1A);

  /// 副文字
  static const Color textSecondary = Color(0xFF666666);

  /// 占位文字
  static const Color textHint = Color(0xFF999999);

  /// 边框
  static const Color border = Color(0xFFE0E0E0);

  /// 禁用
  static const Color disabled = Color(0xFFBDBDBD);

  /// 分割线
  static const Color divider = Color(0xFFF0F0F0);

  // 状态色（仅 3 个）
  static const Color success = primary;
  static const Color warning = Color(0xFFFFB74D);
  static const Color error = Color(0xFFE57373);

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

  static const List<BoxShadow> shadowDialog = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
