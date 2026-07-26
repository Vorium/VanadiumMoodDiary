import 'package:flutter/material.dart';

/// 慢病管家 · 设计 Token 规范
/// v0.5 · 2026-07-12 增加 dark 颜色 + 响应式断点
/// v0.18 · 2026-07-18 (P1-5) 增加 dynamic Color getter,支持 dark mode
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
  // 直接用 `AppTokens.surface` 在 dark mode 下视觉错(背景白、文字白)。
  //
  // 修法：新增下面 7 个 dynamic getter,接受 BuildContext,从
  // Theme.of(context).colorScheme 派生正确颜色(M3 已经按 light/dark 派生好)。
  //
  // 后续 widget 改造时：把 `const TextStyle(color: AppTokens.textHint)` 改成
  // `TextStyle(color: AppTokens.textHintColor(context))`。
  //
  // 注意:dynamic getter 不能在 const constructor 里用(必须 const Color)。
  // 这是 dark mode 支持的必要 trade-off,跟 const optimization 互斥。
  //
  // v0.18 (P1-5) batch 1: 加 7 个 getter + 替换 EmptyState + vent_list 最 critical 处。
  // batch 2+ 替换剩余 90+ 处。

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
  /// `AppTokens.disabled` 在 dark mode 下是浅灰 (BDBDBD), 看不见。
  /// 这里补上 getter 跟其它 8 个 dynamic color 保持一致。
  static Color disabledColor(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? const Color(0xFF4A4A4A)
        : const Color(0xFFBDBDBD);
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
      AppTokens.warning.withValues(alpha: 0.1);

  /// v0.23 round 40 (emil F1 fix): 成功浅色背景 (已完成 chip) — 绿色 @ alpha 0.1
  /// 替代 ChipBadge.success 之前跟 neutral 配色完全一样的 bug
  static Color tintedSuccessSoft(BuildContext context) =>
      AppTokens.success.withValues(alpha: 0.1);

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
  /// 替代 `AppTokens.warning.withValues(alpha: 0.3)` 硬编码
  static Color tintedWarningBorder(BuildContext context) =>
      AppTokens.warning.withValues(alpha: 0.3);

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
  /// success color 在 light/dark 都跟 onSurface 区分度足,直接用 const
  static const Color fgOnSuccess = success;

  /// v0.23 round 40 (emil F1 fix): 警告前景色 — 警告 chip 文字
  static const Color fgOnWarning = Color(0xFFE65100); // 深橙,在 light/dark 都可读

  /// v0.23 round 40 (emil F3/F8 fix): 反白弱一档 — onPrimary @ alpha 0.85
  /// 替代散落 5+ 处 `onPrimary.withValues(alpha: 0.85)` 硬编码
  /// emil "decisions should be nameable" — 0.85 不应裸用,命名 "muted"
  static Color fgOnPrimaryMuted(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.85);

  // ============= 字体 =============
  static const double fontSizeTitle = 28.0;
  static const double fontSizeHeadline = 24.0;
  static const double fontSizeButton = 20.0;
  static const double fontSizeBody = 18.0;
  static const double fontSizeLabel = 16.0;
  static const double fontSizeCaption = 14.0;
  // v0.22 round 29 (emil-16): 微小字 (10 / 8) 集中器, 日历 cell + 小标签统一
  static const double fontSizeMicro = 10.0;
  static const double fontSizeXxxSmall = 8.0;

  // v0.22 round 36 (emil 7.2): 中间档 + score 数字集中器
  // 11 / 12 / 13 是 Body / Label / Caption 之间的过渡尺寸
  // 24 / 32 / 64 是 3 个大数字 score (评估 24h / 周报 / 季度)
  static const double fontSizeBodySm = 13.0;
  static const double fontSizeCaptionSm = 12.0;
  static const double fontSizeLabelSm = 11.0;
  static const double fontSizeScoreLg = 24.0;
  static const double fontSizeScoreXl = 32.0;
  static const double fontSizeScoreXxl = 64.0;

  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightLoose = 1.8;
  // v0.22 round 30 (emil P0-4): 中间档 — legal/邮件/条款正文 (1.4) + 长文/日记 (1.6)
  // 之前散落 14+ 处 `height: 1.X` 硬编码
  static const double lineHeightSnug = 1.4;
  static const double lineHeightRelaxed = 1.6;

  // ============= 间距 =============
  static const double spacingXs = 8.0;
  static const double spacingSm = 16.0;
  static const double spacingMd = 24.0;
  static const double spacingLg = 40.0;
  static const double spacingXl = 80.0;

  // v0.22 round 30 (emil P1-3): stagger 公式抽 token
  // 之前 vent_list_page.dart:110 + medication_calendar_page.dart:222 各 1 次
  // `Duration(milliseconds: i * 40)` 硬编码, 40ms / clamp 0-400 是 magic
  static const int staggerStepMs = 40;
  // v0.24 round 43 (emil D-06 P2): cap 200ms (5 行后立即出现, 避免长列表等太久)
  // emil "perceived performance" — user 看到第 5 行已开始 = 不再等
  // 之前 400ms = 10 行才出, 后面的全瞬时, 体感"卡"
  static const int staggerCapMs = 200;

  // v0.22 round 30 (emil P2-7): 微小 padding 集中器
  // 之前散落 5+ 处 `EdgeInsets.symmetric(horizontal: 8/6/10, vertical: 2/1/6)` magic
  static const double spacingXxs = 4.0;  // 微小 (cell padding 上下)
  static const double spacingXxxs = 2.0;  // 极小 (chip 内部)
  static const double spacingChipGap = 6.0;  // chip 与 text 间距
  // v0.23 round 40 (emil F6 fix): chip 内部 icon-text 间距 (4.0)
  static const double spacingChipGapInline = 4.0;

  // v0.24 round 48 (emil P2-4): chip 内部 padding token
  // 之前 1 处散落 `EdgeInsets.symmetric(horizontal: 12, vertical: 8)` (mood_recorder)
  // 12 是 chip 视觉心理学最佳值 (不跟 token sequence 8/16 重复)
  // 8 等同 spacingXs 但语义清晰 (chip 内部用, 跟外部 spacingXs 区分)
  static const double spacingChipPaddingH = 12.0;
  static const double spacingChipPaddingV = 8.0;

  // v0.23 round 40 (emil F9 fix): 文字长度警告阈值 (90% of 2000 maxLength)
  // 替代 vent_compose_page.dart:390 magic 1800
  static const int textLengthWarningThreshold = 1800;

  // v0.22 round 30 (emil P2-8): 庆祝 overlay delay 1800ms 抽 token
  // 之前 home_page.dart:422 硬编码 `Future.delayed(Duration(milliseconds: 1800))`
  static const int celebrationDisplayMs = 1800;

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
  // v0.23 round 40 (emil F6/F12 fix): 微小 icon (chip 内, spinner)
  static const double iconSizeMicro = 12.0;

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

  // v0.24 round 45 (emil P1-16): 4 个细小 duration 抽 token
  // emil "magic numbers should be named" — 之前散落 6 处 hardcode
  // - durPress: PressFeedback 按下→回弹周期 (160ms, 比 durFast 短 — 必须感觉"快")
  // - shimmerCycleMs: LoadingSkeleton shimmer 完整循环周期 (1200ms, 是 magic 不是动画)
  // - durPageTransition: PageTransitionSwitcher fade 100ms (默认 fade 100, override 时)
  // - refreshMinVisibleMs: pull-to-refresh 最小可见时间 400ms (避免 "瞬闪" 感觉没刷新)
  static const Duration durPress = Duration(milliseconds: 160);
  static const int shimmerCycleMs = 1200;
  static const Duration durPageTransition = Duration(milliseconds: 100);
  static const int refreshMinVisibleMs = 400;

  // v0.21 Round 25 (P2 polish): snackbar 时长统一
  // 之前 10+ 处 SnackBar duration: const Duration(seconds: 2|3|4) 硬编码
  // 频度: occasional (偶尔 1 次) → 标准时长
  // - short (2s): 普通 info / 成功提示
  // - medium (3s): 多行 info
  // - long (4s): error 错误信息 (用户需要时间读) + Undo 撤销操作 (4s 反应窗口)
  static const Duration snackBarDurationShort = Duration(seconds: 2);
  static const Duration snackBarDurationMedium = Duration(seconds: 3);
  static const Duration snackBarDurationLong = Duration(seconds: 4);

  /// 标准进入/出场缓动 — `easeOutCubic`：开始快、收尾慢
  /// 替代 Flutter 默认 `easeInOut`（emil: 延迟了用户最关注的入场瞬间）
  /// 适用：modal / drawer / 状态切换 / fade in
  static const Curve curveStandard = Curves.easeOutCubic;

  /// 微弱缓动 — `easeOut`：比 standard 弱 30%，"几乎察觉不到"
  /// v0.24 round 48 (emil P1-1): 之前 MotionScheme.subtle 跟 standard 共用 curveStandard
  /// 导致 subtle 频度档位虚设（emil "decisions should be nameable"）
  /// 现在 subtle 用专属 curve，频度档位可命名
  /// 适用：tens/day 微弱反馈（hover 类 / list item 选中态）
  static const Curve curveSubtle = Curves.easeOut;

  /// 强减速缓动 — `easeOutQuart`：比 standard 更明显的"快速起步、缓慢收尾"
  /// 适用：celebration / 大数字递增（streak 数字）
  static const Curve curveDecelerate = Curves.easeOutQuart;

  /// 入场缓动 — `easeInCubic`：开始慢、结束快
  /// 适用：exit / dismiss 动画（离开屏幕要"果断"）
  static const Curve curveAccelerate = Curves.easeInCubic;

  /// 弹性缓动 — `elasticOut`：超过目标再回弹
  /// 适用：onboarding 首次 / 庆祝反馈（rare 频度，emil: 禁滥用）
  static const Curve curveDelight = Curves.elasticOut;

  /// v0.23 round 40 (emil F2 fix): 回弹缓动 — `easeOutBack`：过冲但不弹多次
  /// 适用：庆祝 overlay 主弹跳 (celebration_overlay:32)
  /// 跟 curveDelight (elasticOut) 区别: easeOutBack 一次过冲,elasticOut 多次回弹
  /// 主庆祝用 easeOutBack 更"稳",副粒子可用 elasticOut
  static const Curve curveBackOut = Curves.easeOutBack;

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

  /// v0.22 round 29 (emil-15): 庆祝 / 浮层轻阴影 (比 shadowDialog 更弱)
  /// 用于 celebration_overlay 等浮在内容上的轻提示, emil rare 频度可加 delight
  static const List<BoxShadow> shadowOverlay = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  // ============= 阴影 (v0.24 round 43 emil D-04 P2: dark mode 反白) =============
  //
  // 上面 4 个 const shadow 全部用黑色 0x14-0x33 透明度, **dark mode 完全不可见**
  // (黑色阴影打在 dark surface 上 = 透明)。M3 标准做法是用
  // `Theme.of(context).colorScheme.shadow` 派生, light/dark mode 自适应。
  //
  // emil "translucent material" 哲学: 暗色下阴影应该反白 / 用 colorScheme.shadow。
  // 加 4 个 context-aware 变体 (不能完全替 const, 因为 const list 在 const
  // constructor 里要用), 新代码优先用 dynamic getter。
  //
  // 用法: `boxShadow: AppTokens.shadowCardOf(context)`

  /// Theme-aware 卡片阴影 (dark mode 反白) — 替换 const shadowCard
  static List<BoxShadow> shadowCardOf(BuildContext context) => [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow,
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  /// Theme-aware 卡片深阴影 (dark mode 反白) — 替换 const shadowCardDark
  /// 跟 shadowCardOf 区别: alpha 更高 (M3 spec: shadow 0.08 vs scrim 0.32)
  static List<BoxShadow> shadowCardDarkOf(BuildContext context) => [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow,
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];

  /// Theme-aware 对话框阴影 (dark mode 反白) — 替换 const shadowDialog
  static List<BoxShadow> shadowDialogOf(BuildContext context) => [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// Theme-aware 浮层轻阴影 (dark mode 反白) — 替换 const shadowOverlay
  static List<BoxShadow> shadowOverlayOf(BuildContext context) => [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  // ============= TextStyle token (v0.22 round 30 / emil P0-4) =============
  //
  // **架构级修复**: 之前 60+ 处直接 `TextStyle(fontSize, fontWeight, height)`
  // 散在 trend / assessment / medication / settings 等 8+ page。
  // 跟动效 token 化水平严重不匹配（动效 85%，文字 40%）。
  //
  // 命名规则:
  //   textStyle{Size}{Weight?} = size + 重量
  //   末尾加 Strong = w600（默认是 w400）
  //   末尾加 Inverse = 用 onPrimary 颜色（按钮反白）
  //
  // 用法:
  // ```dart
  // Text('hello', style: AppTokens.textStyleBody(context))
  // ```
  //
  // 全部 dynamic（接受 BuildContext），color 走 theme-aware getter
  // → 修复 dark mode 文字色 + 行高不一致 + 减 60+ 处硬编码
  //
  // 注意: 不能在 const constructor 里用 (跟 const optimization 互斥, 同 surfaceColor)

  /// 28/w700 页面大标题 (用于主屏 Greeting)
  static TextStyle textStyleTitle(BuildContext context) => TextStyle(
        fontSize: fontSizeTitle,
        fontWeight: FontWeight.w700,
        height: lineHeightTight,
        color: textPrimaryColor(context),
      );

  /// 24/w700 副标题
  static TextStyle textStyleHeadline(BuildContext context) => TextStyle(
        fontSize: fontSizeHeadline,
        fontWeight: FontWeight.w700,
        height: lineHeightTight,
        color: textPrimaryColor(context),
      );

  /// 18/w400 正文
  static TextStyle textStyleBody(BuildContext context) => TextStyle(
        fontSize: fontSizeBody,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        color: textPrimaryColor(context),
      );

  /// 18/w600 正文加粗 (用于 trend summary 数字)
  static TextStyle textStyleBodyStrong(BuildContext context) => TextStyle(
        fontSize: fontSizeBody,
        fontWeight: FontWeight.w600,
        height: lineHeightNormal,
        color: textPrimaryColor(context),
      );

  /// 16/w400 label/正文
  static TextStyle textStyleLabel(BuildContext context) => TextStyle(
        fontSize: fontSizeLabel,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        color: textPrimaryColor(context),
      );

  /// 16/w600 label 加粗 (ListTile title / section header)
  static TextStyle textStyleLabelStrong(BuildContext context) => TextStyle(
        fontSize: fontSizeLabel,
        fontWeight: FontWeight.w600,
        height: lineHeightNormal,
        color: textPrimaryColor(context),
      );

  /// 20/w600 按钮文字
  static TextStyle textStyleButton(BuildContext context) => TextStyle(
        fontSize: fontSizeButton,
        fontWeight: FontWeight.w600,
        height: lineHeightTight,
        color: textPrimaryColor(context),
      );

  /// 20/w600 按钮反白 (onPrimary 底色按钮, 文字用 onPrimary 颜色)
  static TextStyle textStyleButtonInverse(BuildContext context) => TextStyle(
        fontSize: fontSizeButton,
        fontWeight: FontWeight.w600,
        height: lineHeightTight,
        color: Theme.of(context).colorScheme.onPrimary,
      );

  /// 14/w400 caption / 小字 / hint
  static TextStyle textStyleCaption(BuildContext context) => TextStyle(
        fontSize: fontSizeCaption,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        color: textSecondaryColor(context),
      );

  /// 14/w600 caption 加粗 (dialog 标题 / 状态数字)
  static TextStyle textStyleCaptionStrong(BuildContext context) => TextStyle(
        fontSize: fontSizeCaption,
        fontWeight: FontWeight.w600,
        height: lineHeightNormal,
        color: textPrimaryColor(context),
      );

  /// 10/w400 微小字 (日历 cell / 微标签 / 趋势小数字)
  static TextStyle textStyleMicro(BuildContext context) => TextStyle(
        fontSize: fontSizeMicro,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        color: textSecondaryColor(context),
      );

  /// v0.23 (P0-3 emil): 16/w500 label medium (历史标题 / section header
  /// 之前用 (fontSizeLabel + w500) 直拼, 跟 w600 label strong 区分)
  static TextStyle textStyleLabelMedium(BuildContext context) => TextStyle(
        fontSize: fontSizeLabel,
        fontWeight: FontWeight.w500,
        height: lineHeightNormal,
        color: textPrimaryColor(context),
      );

  /// v0.23 (P0-3 emil): 14/w400 caption + hint color (次要 hint 文字, 比
  /// textStyleCaption 更弱的提示, 例 "上次回答 X 月 X 日")
  static TextStyle textStyleCaptionHint(BuildContext context) => TextStyle(
        fontSize: fontSizeCaption,
        fontWeight: FontWeight.w400,
        height: lineHeightNormal,
        color: textHintColor(context),
      );

  /// 12/w400 法律/邮件/条款正文 (lineHeightSnug 1.4)
  /// 替代散落 8+ 处 `TextStyle(fontSize: 12, height: 1.4)`
  /// v0.24 round 46: 内部 `fontSize: 12` 改 `fontSizeCaptionSm` (复用既有 token, 不另造 fontSizeLegal)
  static TextStyle textStyleLegal(BuildContext context) => TextStyle(
        fontSize: fontSizeCaptionSm,
        fontWeight: FontWeight.w400,
        height: lineHeightSnug,
        color: textSecondaryColor(context),
      );

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
// emil 决策框架: 4 档动画强度，按"用户一天看到几次"分。
// 用 enum 强制 caller 选档，避免在 widget 里直接传
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
// - none:      100+/day (键盘 / 核心导航 / 日常按钮) → 用户已经熟，无动画
// - subtle:    tens/day (hover / press feedback) → 微弱反馈
// - standard:  occasional (modal / drawer / snackbar / 状态切换)
// - delight:   rare (onboarding 首次 / 庆祝 / 解锁成就) → 弹性，可加 highlight
enum MotionScheme {
  /// 100+/day — 不加动画，直接切换
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
        // v0.24 round 48 (emil P1-1): 之前跟 standard 共用 curveStandard
        // 频度档位虚设。现在用 curveSubtle (Curves.easeOut) 跟 standard 区分
        return AppTokens.curveSubtle;
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
// 精神心理患者前庭功能敏感比例高于普通用户，长时间用 App 可能眩晕。
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
