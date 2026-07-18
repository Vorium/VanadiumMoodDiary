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
  // P1-4 fix: 极小圆角(热力图 cell / 日历 cell),2-4px
  static const double radiusCell = 2.0;
  static const double radiusCellLg = 4.0;

  // ============= 尺寸 =============
  static const double buttonHeight = 88.0;
  static const double buttonHeightSmall = 56.0;
  static const double minTapArea = 48.0;
  static const double inputHeight = 56.0;
  static const double iconSize = 24.0;
  static const double iconSizeLg = 32.0;

  // ============= 动画 =============
  // v0.17 round 1 (emil 动效 token): 之前只有 duration 缺 curve / easing
  // 各 widget 各写各的 → 风格不统一
  // 频度决策（emil 框架）：
  //   100+/day（键盘 / 核心导航）→ 无动画
  //   tens/day（hover）→ 微弱
  //   occasional（modal / drawer / snackbar）→ durNormal + curveStandard
  //   rare（onboarding / 庆祝）→ durSlow + curveDelight
  static const Duration durFast = Duration(milliseconds: 200);
  static const Duration durNormal = Duration(milliseconds: 300);
  static const Duration durSlow = Duration(milliseconds: 500);

  /// 标准进入/出场缓动 — `easeOutCubic`：开始快、收尾慢
  /// 替代 Flutter 默认 `easeInOut`（emil: 延迟了用户最关注的入场瞬间）
  /// 适用：modal / drawer / 状态切换 / fade in
  static const Curve curveStandard = Curves.easeOutCubic;

  /// 强减速缓动 — `easeOutQuart`：比 standard 更明显的"快速起步、缓慢收尾"
  /// 适用：celebration / 大数字递增（streak 数字）
  static const Curve curveDecelerate = Curves.easeOutQuart;

  /// 入场缓动 — `easeInCubic`：开始慢、结束快
  /// 适用：exit / dismiss 动画（离开屏幕要"果断"）
  static const Curve curveAccelerate = Curves.easeInCubic;

  /// 弹性缓动 — `elasticOut`：超过目标再回弹
  /// 适用：onboarding 首次 / 庆祝反馈（rare 频度，emil: 禁滥用）
  static const Curve curveDelight = Curves.elasticOut;

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

// ============= MotionScheme (v0.17 round 14 / P2-14) =============
//
// emil 决策框架: 4 档动画强度,按"用户一天看到几次"分。
// 用 enum 强制 caller 选档,避免在 widget 里直接传
// (Duration, Curve) 导致风格不统一。
//
// 用法:
// ```dart
// final motion = MotionScheme.standard;  // most UI
// AnimatedContainer(
//   duration: motion.duration,
//   curve: motion.curve,
//   ...
// )
// ```
//
// 选择规则:
// - none:      100+/day (键盘 / 核心导航 / 日常按钮) → 用户已经熟,无动画
// - subtle:    tens/day (hover / press feedback) → 微弱反馈
// - standard:  occasional (modal / drawer / snackbar / 状态切换)
// - delight:   rare (onboarding 首次 / 庆祝 / 解锁成就) → 弹性,可加 highlight
enum MotionScheme {
  /// 100+/day — 不加动画,直接切换
  none,

  /// tens/day — 微弱反馈 (e.g. button press)
  subtle,

  /// occasional — modal / drawer / snackbar 默认档
  /// durNormal + curveStandard (easeOutCubic)
  standard,

  /// rare — onboarding 首次 / 庆祝 / 解锁
  /// durSlow + curveDelight (elasticOut)
  delight,
}

extension MotionSchemeTokens on MotionScheme {
  Duration get duration {
    switch (this) {
      case MotionScheme.none:
        return Duration.zero;
      case MotionScheme.subtle:
        return AppTokens.durFast;
      case MotionScheme.standard:
        return AppTokens.durNormal;
      case MotionScheme.delight:
        return AppTokens.durSlow;
    }
  }

  Curve get curve {
    switch (this) {
      case MotionScheme.none:
        return Curves.linear;
      case MotionScheme.subtle:
        return AppTokens.curveStandard;
      case MotionScheme.standard:
        return AppTokens.curveStandard;
      case MotionScheme.delight:
        return AppTokens.curveDelight;
    }
  }
}

// ============= Motion (v0.18 round 14 / P0-7) =============
//
// **P0-7 fix**: 之前没有任何代码处理 `prefers-reduced-motion: reduce` 媒体查询。
// 精神心理患者前庭功能敏感比例高于普通用户,长时间用 App 可能眩晕。
// emil 原则第 8 条: reduced-motion 是 non-negotiable a11y 标准。
//
// 用法:
// ```dart
// AnimatedContainer(
//   duration: Motion.duration(context, AppTokens.durNormal),
//   curve: Motion.curve(context, AppTokens.curveStandard),
//   ...
// )
// ```
//
// 系统没开 reduce motion → 走原 duration/curve
// 系统开了 reduce motion → duration = 0 + curve = linear
class Motion {
  Motion._();

  /// 系统是否启用了"减少动画"
  ///
  /// Flutter 内置 API: [MediaQuery.disableAnimations]
  static bool prefersReduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;

  /// 包装 duration: 系统开了 reduce motion → 0
  ///
  /// [base] 通常是 AppTokens.durNormal / durFast / durSlow。
  static Duration duration(BuildContext context, Duration base) =>
      prefersReduced(context) ? Duration.zero : base;

  /// 包装 curve: 系统开了 reduce motion → linear (避免任何加速/减速)
  static Curve curve(BuildContext context, Curve base) =>
      prefersReduced(context) ? Curves.linear : base;
}
