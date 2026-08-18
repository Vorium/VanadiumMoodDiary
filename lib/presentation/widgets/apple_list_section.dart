// v0.31 round 8a (Apple Health redesign · Phase 2 Task 2.4): AppleListSection 新增
//
// iOS 群组列表 (insetGrouped) 风格, 替代现有 `Card + Padding` 模式。
//
// 设计 (spec §4.5):
// - 可选 title (13pt w500 ALL CAPS letter-spacing 0.6 textHint, padding 8/4)
// - 内容: 白色圆角 16 容器 (surface, 0 阴影)
// - 内部 cell 用 hairline Divider(thickness: 0.5) 分隔
// - cell 默认 padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)
// - 默认 margin: EdgeInsets.symmetric(horizontal: 20) (pageMarginH)
// - dark mode: surface 走 1C1C1E, divider 走 theme.outlineVariant
// - 0 阴影 (跟 Apple Health 卡片不靠 shadow 表达层次一致)
//
// 用法:
// ```dart
// AppleListSection(
//   title: l10n.medicationToday,    // i18n 走 ARB, 不要硬编码
//   children: [
//     ListTile(title: Text('...')),
//     ListTile(title: Text('...')),
//   ],
//   footer: '点击卡片查看详情',      // 可选说明
// )
// ```
//
// 决策:
// - children 不限类型, Divider 用 InsertIndexed 模式串联 (避免 caller 手写 Divider)
// - title 用 ALL CAPS (iOS section header 标准), letterSpacing 0.6
// - 圆角 16 用 AppTokens.radiusCard (跟卡片保持一致)
// - 不依赖 Material Card (0 阴影走自定义 Container, emil 决策 #3)
// Apple Health 风格 (spec §4.5 insetGrouped 风格 + hairline 0.5 divider + 13pt ALL CAPS title) [R32 集中器注释, 防后续误改为 Material 3 风格]

import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/widgets/chip_badge.dart';

/// Apple Health / iOS 群组列表 (insetGrouped) 风格章节
///
/// API:
/// - [title]     — 可选, 13pt w500 ALL CAPS letter-spacing 0.6 textHint
///                 不传则不渲染 title (适合"已用 section 包裹"嵌套场景)
/// - [chip]      — 可选, title 右侧数量徽章 (e.g. "5"), 走公共 ChipBadge
///                 (跟 SectionHeader chip 同源, v0.28 R81 设计, 本地化用;
///                 v0.32 round 8 EM-09b 删私有 _ChipBadge 副本)
/// - [children]  — 内容 cell list, 内部用 hairline Divider(thickness: 0.5) 分隔
/// - [footer]    — 可选, 章节下方小字 (Apple iOS 标准 footer 文字)
/// - [margin]    — 外边距, 默认 EdgeInsets.symmetric(horizontal: pageMarginH=20)
///
/// 视觉: 圆角 16 白色容器 + cell hairline 0.5px 分隔, 0 阴影 (跟 Apple Health 一致)
///
/// v0.31 round 8a (Apple Health redesign · Phase 2 Task 2.4):
/// 新增, 替代现有 `Card + Padding` 模式。Phase 3 将在 11 feature 页面
/// (home/setup/medication/mood/...) 切换到 AppleListSection。
///
/// v0.31 round 11a: 加 [chip] 参数 (让 medication_page 等可显示 "5" 数量徽章).
/// 注意: 标题 inline 渲染 13pt (spec §4.5), 不走 [SectionHeader] — 它
/// v0.32 round 8 (R111 EM-02b) 后同为 13pt 但无 chip 参数, 本 widget 保留
/// inline 实现跟锁 test 一致 (R112-06 注释漂移修).
class AppleListSection extends StatelessWidget {
  const AppleListSection({
    super.key,
    this.title,
    this.chip,
    required this.children,
    this.footer,
    this.margin,
  });

  /// iOS section header: 13pt w500 ALL CAPS letter-spacing 0.6 textHint
  ///
  /// 不传则不渲染 title (适合"已用 section 包裹"嵌套场景)。
  final String? title;

  /// v0.31 round 11a: 标题右侧数量徽章 (e.g. "5", 显示 5 种药)
  ///
  /// 走 [SectionHeader.chip] 模式 (B 站哗哩哗哩能量加油站风格)
  /// 1 行 Row[title, chip], 跟 [SectionHeader] 一致。
  /// 不传则不渲染 chip。
  ///
  /// v0.32 round 8 (R112 EM-09b fix): 走公共 widgets/ChipBadge 集中器
  /// (修前本文件私有 _ChipBadge 副本, 跟 ChipBadge + SectionHeader 副本
  /// 3 份同视觉代码)
  final String? chip;

  /// 内容 cell list, 内部用 hairline Divider(thickness: 0.5) 分隔
  ///
  /// 不限类型, 通常是 [ListTile] / [AppListTile] / 任意 44pt 高的 widget。
  final List<Widget> children;

  /// iOS section footer: 章节下方说明文字 (e.g. "点击卡片查看详情")
  ///
  /// 不传则不渲染 footer。
  final String? footer;

  /// 外边距, 默认 EdgeInsets.zero
  ///
  /// R114 Wave B2 (B2-4, apple F-01): 修前默认 symmetric(horizontal: 20)
  /// 与 PageScaffold 的 pageMarginH 20 叠加成 40px 双重 inset。裁决统一
  /// "20+0" — PageScaffold 唯一负责页边距 (20px), 本 widget 默认 0。
  /// 非 PageScaffold 场景的 caller 需要页边距时显式传 margin。
  final EdgeInsets? margin;

  /// iOS section header 字号 (13pt) — AppleListSection 跟 SectionHeader 不同,
  /// 这里用 caption 13 (比 SectionHeader 的 captionSm 11 略大, 因为 AppleListSection
  /// 是更高一层的章节 header, SectionHeader 是 cell 内的小标题)
  static const double _titleFontSize = AppTokens.fontSizeCaption; // 13.0

  /// iOS ALL CAPS section header letter-spacing (Apple HIG 推荐 0.6-1.0)
  static const double _titleLetterSpacing = 0.6;

  /// 章节内容 cell 默认 padding (16 横向, 12 纵向 — iOS 列表 cell 标准)
  static const EdgeInsets _cellPadding = EdgeInsets.symmetric(
    horizontal: AppTokens.spacingMd, // 16
    vertical: AppTokens.spacingSm, // 12 (iOS list cell vertical)
  );

  /// hairline divider 厚度 (iOS separator 0.5pt)
  static const double _hairlineThickness = 0.5;

  @override
  Widget build(BuildContext context) {
    // R114 Wave B2 (B2-4): 默认 margin zero — PageScaffold 负责 20px 页边距
    final effectiveMargin = margin ?? EdgeInsets.zero;
    // v0.31 round 8a: dark mode 用静态 surfaceDark (#1C1C1E, iOS
    // secondarySystemGroupedBackground), light mode 走 theme.surface。
    // 不走 theme.surface 是因为 M3 ColorScheme.fromSeed 在 dark 模式会派生
    // 偏紫/偏蓝的 surface, 跟 iOS #1C1C1E 中性灰不一致, 显式走静态值保设计一致性。
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppTokens.surfaceDark : AppTokens.surfaceColor(context);
    final dividerColor =
        isDark ? AppTokens.dividerDark : AppTokens.dividerColor(context);

    return Padding(
      padding: effectiveMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ===== 可选 title (13pt w500 ALL CAPS letterSpacing 0.6 textHint) =====
          // v0.31 round 11a (revert): 不用 [SectionHeader] — 它 v0.32 round 8
          // (R111 EM-02b) 已从 11pt 升到 13pt (fontSizeCaption, 跟本 widget 同字号),
          // 但 SectionHeader 无 chip 参数且布局语义不同 (cell 内小标题 vs
          // 章节 header). 保留 inline Text + 可选 chip 模式,
          // 跟 lock-in test apple_list_section_round8a 一致.
          if (title != null) ...[
            Padding(
              // 8 上 + 4 下 (spec "padding 8/4" — 给上方 section 留空, 紧贴 section 内容)
              padding: const EdgeInsets.only(
                top: AppTokens.spacingXs, // 8
                bottom: AppTokens.spacingXxs, // 4
              ),
              child: Row(
                children: [
                  // v0.32 R112 round 8i: 窄屏/大字号防溢出 — title 弹性收缩
                  Flexible(
                    child: Text(
                      title!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: _titleFontSize, // 13 (per spec §4.5)
                        color: AppTokens.textHintColor(context),
                        fontWeight: FontWeight.w500,
                        letterSpacing: _titleLetterSpacing, // 0.6
                      ),
                    ),
                  ),
                  if (chip != null) ...[
                    const SizedBox(width: AppTokens.spacingXs),
                    ChipBadge(label: chip!),
                  ],
                ],
              ),
            ),
          ],
          // ===== 内容: 圆角 16 白色 (surface) 容器 =====
          // v0.32 round 8 (R112 F1/F2 ALS 化 root fix): DecoratedBox → Material
          // — ListTile/InkWell 放进非 Material 的 DecoratedBox 会触发
          // "ink splashes may be invisible" debug assert (cbt_section 等 widget
          // test 实测崩); Material(clipBehavior: antiAlias) 提供 ink 支持
          // 且 ClipRRect 可省 (Material 自带 clip)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusCard), // 16
            child: Material(
              color: surfaceColor,
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _buildCells(dividerColor),
              ),
            ),
          ),
          // ===== 可选 footer (章节下方小字) =====
          if (footer != null) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: AppTokens.spacingXxs, // 4
                left: AppTokens.spacingXs, // 8 (跟 title 横向对齐)
                right: AppTokens.spacingXs,
              ),
              child: Text(
                footer!,
                style: AppTokens.textStyleCaptionHint(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 内部 helper: 串联 children + hairline Divider
  ///
  /// N children → N widgets + (N-1) dividers
  /// children 默认包 _DefaultCellPadding 让外部传 raw widget 也对
  List<Widget> _buildCells(Color dividerColor) {
    if (children.isEmpty) return const [];
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      out.add(_wrapCell(children[i]));
      if (i < children.length - 1) {
        out.add(
          Divider(
            height: 0,
            thickness: _hairlineThickness,
            color: dividerColor,
          ),
        );
      }
    }
    return out;
  }

  /// 单个 cell 包默认 padding (16/12)
  ///
  /// 如果 child 已经是 SizedBox / Container 自带 padding, 重复嵌套但不影响视觉
  Widget _wrapCell(Widget child) {
    return Padding(
      padding: _cellPadding,
      child: child,
    );
  }
}
