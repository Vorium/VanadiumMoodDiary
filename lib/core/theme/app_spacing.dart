// v0.27 round 65 (alibaba B16 god constant 拆分): 间距 / 尺寸 / 圆角 / 断点 独立
//
// 拆解前: app_tokens.dart 644 行 8 大类混合。R65 拆 4 文件, 间距/圆角/尺寸/
// 断点/数字常量全部在本文件。app_tokens.dart 留 facade re-export。
//
// 设计原则:
// - 0 依赖 BuildContext, 全部 static const (可进 const constructor)
// - 老 caller 兼容: `AppTokens.spacingMd` 仍能用 (走 facade)

/// v0.27 round 65 (alibaba B16 god constant 拆分): 间距 / 尺寸 / 圆角 / 断点 token 集中器
///
/// 5 大类:
/// 1. **Spacing** (10 个, 8/16/24/40/80 5 主档 + 2/4/6/12/100/1800 细颗粒)
/// 2. **Radius** (6 个, 2/4/8/12/16/24)
/// 3. **Size** (10 个, buttonHeight/iconSize/calendarLabel/shimmer 等业务专用)
/// 4. **Page margin** (2 个, H/V)
/// 5. **Responsive breakpoint** (5 个, M3 window size class)
class AppSpacing {
  AppSpacing._();

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

  /// v0.27 round 62 (P1-9 修复): Deep link race guard 100ms
  ///
  /// 之前 `home_page.dart:87` 用 `Future.delayed(Duration(milliseconds: 100))`
  /// 等 GoRouter 把 query param 完整传过来再跑 safety check, 避免 race。
  /// 现在用命名 token 替代裸值, 跨文件复用 + grep 找得到。
  static const Duration kDeepLinkRaceGuard = Duration(milliseconds: 100);

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
  // v0.25 round 56 (emil P1 #3 + #4): icon 尺寸集中器
  // 替代散落 30+ 处 `size: 18` / `size: 14` / `size: 64` / `size: 56`
  // - iconSizeInline=18 按钮内 / 列表项 (介于 iconSize=24 跟 iconSizeMicro=12 之间)
  // - iconSizeSmall=14  时间 chip / 日历 cell 内部小 icon
  // - iconSizeEmpty=64   empty state 大 icon
  // - iconSizeError=56   error state 大 icon
  static const double iconSizeInline = 18.0;
  static const double iconSizeSmall = 14.0;
  static const double iconSizeEmpty = 64.0;
  static const double iconSizeError = 56.0;

  // v0.25 round 56 (emil A3 续): shimmer 配套 (已有 shimmerCycleMs, 缺 pause)
  // v0.24 round 45 加了 shimmerCycleMs=1200, 缺配套的 pause 时长。
  // emil "decisions should be nameable" — 600ms magic 应命名。
  static const int shimmerPauseMs = 600;

  // v0.25 round 56 (emil P1): chart 占位 + sparkline 高度集中器
  // 替代散落 5+ 处 `SizedBox(height: 200)` / `height: 80` magic
  // v0.26 round 57 (emil C-10): 删 sparklineHeight + heatmapLabelWidth
  // (R56 加了但 0 引用, R57 修正后确认无合适使用场景, 删 const 避免 dead token)
  static const double chartPlaceholderHeight = 200.0;
  static const double eventTimeColWidth = 36.0;

  // v0.27 round 60 (审计 M11 修正): medication_calendar label 列宽集中器
  // 替代 `medication_calendar_page.dart:440` file-private `const _labelWidth = 60`
  // (3 处使用: 周几 label + 时段 label 列宽). 加 token 后 design system 一致.
  static const double calendarLabelWidth = 60.0;

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
  if (width < AppSpacing.breakpointMedium) return WindowSize.compact;
  if (width < AppSpacing.breakpointExpanded) return WindowSize.medium;
  return WindowSize.expanded;
}
