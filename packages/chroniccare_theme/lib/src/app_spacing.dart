// v0.31 round 3 (Apple Health redesign · Phase 1 Task 1.3): iOS 标准间距/尺寸/圆角
//
// 历史:
// - v0.27 round 65 (alibaba B16 god constant 拆分): 间距 / 尺寸 / 圆角 / 断点 独立
//   拆解前: app_tokens.dart 644 行 8 大类混合。R65 拆 4 文件, 间距/圆角/尺寸/
//   断点/数字常量全部在本文件。app_tokens.dart 留 facade re-export。
// - v0.31 R3: Apple Health redesign Phase 1 Task 1.3
//   - buttonHeight 88→50 (iOS 50pt CTA, **关键改**)
//   - spacingMd 24→16 (iOS list cell standard, **关键改**)
//   - spacingXl 80→48 (减少空旷, **关键改**)
//   - radiusButton 24→14 (iOS standard 圆角)
//   - inputHeight / buttonHeightSmall 56→44 (iOS 44pt)
//   - iconSize / iconSizeLg / iconSizeInline / iconSizeSmall 微调
//   - 新增 radiusTile 12 (AppleHealthTile) / radiusLargeButton 22 (Pill)
//   - 新增 spacingXxxl 32 (Apple 章节间距)
//   - stagger 30 / 150 (略快, 5 行后立即出现)
//
// 设计原则:
// - 0 依赖 BuildContext, 全部 static const (可进 const constructor)
// - 老 caller 兼容: `AppTokens.spacingMd` 仍能用 (走 facade)
import 'package:flutter/widgets.dart' show EdgeInsets;

/// v0.31 round 3 (Apple Health redesign · Phase 1 Task 1.3): 间距 / 尺寸 / 圆角 / 断点 token 集中器
///
/// 5 大类:
/// 1. **Spacing** (11 个, 8/12/16/24/32/48 6 主档 + 2/4/6/12/1800 细颗粒)
/// 2. **Radius** (8 个, 4/6/8/10/12/14/16/22)
/// 3. **Size** (10 个, buttonHeight/iconSize/calendarLabel/shimmer 等业务专用)
/// 4. **Page margin** (2 个, H/V)
/// 5. **Responsive breakpoint** (5 个, M3 window size class)
class AppSpacing {
  AppSpacing._();

  // ============= 间距 =============
  // v0.31 R3: iOS list cell standard
  // - spacingMd 24→16 (**关键改**: iOS list cell standard 16pt)
  // - spacingLg 40→24 / spacingXl 80→48 (减少空旷, 信息密度 +30%)
  // - spacingSm 16→12 (略小, 配套 iOS)
  // - 新增 spacingXxxl 32 (Apple 章节间距, 介于 Md=16 / Lg=24 之外)
  static const double spacingXs = 8.0;
  static const double spacingSm = 12.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 48.0;
  // v0.31 R3: Apple 章节间距 (30ms 区间在 Lg=24 / Xl=48 之间, 用于 section 间分隔)
  static const double spacingXxxl = 32.0;

  // v0.22 round 30 (emil P1-3): stagger 公式抽 token
  // v0.31 R3: 30ms (略快, 30ms / 5 行 = 150ms cap, 跟 cap 匹配)
  static const int staggerStepMs = 30;
  // v0.24 round 43 (emil D-06 P2): cap 200ms (5 行后立即出现, 避免长列表等太久)
  // v0.31 R3: 150ms (跟 30ms step 配对, 5 行后立即出现)
  // emil "perceived performance" — user 看到第 5 行已开始 = 不再等
  static const int staggerCapMs = 150;

  // v0.22 round 30 (emil P2-7): 微小 padding 集中器
  // 之前散落 5+ 处 `EdgeInsets.symmetric(horizontal: 8/6/10, vertical: 2/1/6)` magic
  static const double spacingXxs = 4.0; // 微小 (cell padding 上下)
  static const double spacingXxxs = 2.0; // 极小 (chip 内部)
  static const double spacingChipGap = 6.0; // chip 与 text 间距
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

  // v0.30 round 95 (sub-spec 5 task 3-4): EdgeInsets 静态 const helper
  // 替代散落 120+ 处 `EdgeInsets.all(8/16/24/40/80)` literal
  // 跟 spacingXs/Sm/Md/Lg/Xl 1:1 配对, 走 facade `AppTokens.edgeInsetsXs/Sm/...`
  // **不加** symmetric/only/fromLTRB wrapper — 组合数爆炸, 不如保留
  // `EdgeInsets.symmetric(horizontal: AppTokens.spacingXs, vertical: ...)`
  // 这种 inline 写法 (token 复用清晰, 不污染集中器 API)
  static const EdgeInsets edgeInsetsXs = EdgeInsets.all(spacingXs);
  static const EdgeInsets edgeInsetsSm = EdgeInsets.all(spacingSm);
  static const EdgeInsets edgeInsetsMd = EdgeInsets.all(spacingMd);
  static const EdgeInsets edgeInsetsLg = EdgeInsets.all(spacingLg);
  static const EdgeInsets edgeInsetsXl = EdgeInsets.all(spacingXl);

  // v0.31 R3: iOS standard page margin (20pt 横向 / 16pt 纵向)
  static const double pageMarginH = 20.0;
  static const double pageMarginV = 16.0;

  // ============= 圆角 =============
  // v0.31 R3: iOS standard radius
  // - radiusButton 24→14 (iOS 14pt button radius, **关键改**)
  // - radiusInput 12→10 (iOS 10pt input)
  // - radiusCell 2→4 / radiusCellLg 4→6 (heatmap cell 略大, 跟 iOS 表格 cell 接近)
  // - 新增 radiusTile 12 (AppleHealthTile 容器)
  // - 新增 radiusLargeButton 22 (Pill button, 类似 FAB, ≈ buttonHeight/2)
  // - radiusCard 16 不变 (iOS card 仍 16)
  // - radiusChip 8 不变 (chip 仍 8)
  static const double radiusButton = 14.0;
  static const double radiusCard = 16.0;
  static const double radiusInput = 10.0;
  static const double radiusChip = 8.0;
  // P1-4 fix: 极小圆角(热力图 cell / 日历 cell)
  // v0.31 R3: 2→4 / 4→6 (heatmap cell 略大, iOS 风格)
  static const double radiusCell = 4.0;
  static const double radiusCellLg = 6.0;
  // v0.31 R3: AppleHealthTile 容器圆角 (12pt, 介于 chip 8 / card 16 之间)
  static const double radiusTile = 12.0;
  // v0.31 R3: Pill button 圆角 (22pt, ≈ buttonHeight/2, pill 形状)
  static const double radiusLargeButton = 22.0;

  // ============= 尺寸 =============
  // v0.31 R3: iOS standard size
  // - buttonHeight 88→50 (**关键改**: iOS 50pt CTA)
  // - buttonHeightSmall 56→44 (iOS 44pt small button)
  // - inputHeight 56→44 (iOS 44pt text field)
  // - iconSize 24→22 / iconSizeLg 32→28 (略小, 更 Apple)
  // - iconSizeInline 18→17 / iconSizeSmall 14→13 (微调)
  // - iconSizeEmpty 64→56 / iconSizeError 56→48 (略小)
  // - iconSizeMicro 12 不变
  // - minTapArea 48 不变 (Apple HIG 44, M3 48)
  static const double buttonHeight = 50.0;
  static const double buttonHeightSmall = 44.0;
  static const double minTapArea = 48.0;
  // v1.1.0 R114 (Wave D spec §5.5): mood 5 档圆形按钮直径 (Apple Health
  // 72pt 大触达) + 窄屏下限 (5 个按钮并排装不下时按比例收缩, ≥ 48pt 触达下限)
  static const double moodScoreButtonSize = 72.0;
  static const double moodScoreButtonMinSize = 48.0;
  static const double inputHeight = 44.0;
  static const double iconSize = 22.0;
  static const double iconSizeLg = 28.0;
  // v0.23 round 40 (emil F6/F12 fix): 微小 icon (chip 内, spinner)
  static const double iconSizeMicro = 12.0;
  // v0.25 round 56 (emil P1 #3 + #4): icon 尺寸集中器
  // v0.31 R3 微调: 18→17 / 14→13 / 64→56 / 56→48 (跟 iOS 略小)
  static const double iconSizeInline = 17.0;
  static const double iconSizeSmall = 13.0;
  static const double iconSizeEmpty = 56.0;
  static const double iconSizeError = 48.0;

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
