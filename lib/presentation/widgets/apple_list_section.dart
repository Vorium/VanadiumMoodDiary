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

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// Apple Health / iOS 群组列表 (insetGrouped) 风格章节
///
/// API:
/// - [title]     — 可选, 13pt w500 ALL CAPS letter-spacing 0.6 textHint
///                 不传则不渲染 title (适合"已用 section 包裹"嵌套场景)
/// - [children]  — 内容 cell list, 内部用 hairline Divider(thickness: 0.5) 分隔
/// - [footer]    — 可选, 章节下方小字 (Apple iOS 标准 footer 文字)
/// - [margin]    — 外边距, 默认 EdgeInsets.symmetric(horizontal: pageMarginH=20)
///
/// 视觉: 圆角 16 白色容器 + cell hairline 0.5px 分隔, 0 阴影 (跟 Apple Health 一致)
///
/// v0.31 round 8a (Apple Health redesign · Phase 2 Task 2.4):
/// 新增, 替代现有 `Card + Padding` 模式。Phase 3 将在 11 feature 页面
/// (home/setup/medication/mood/...) 切换到 AppleListSection。
class AppleListSection extends StatelessWidget {
  const AppleListSection({
    super.key,
    this.title,
    required this.children,
    this.footer,
    this.margin,
  });

  /// iOS section header: 13pt w500 ALL CAPS letter-spacing 0.6 textHint
  ///
  /// 不传则不渲染 title (适合"已用 section 包裹"嵌套场景)。
  final String? title;

  /// 内容 cell list, 内部用 hairline Divider(thickness: 0.5) 分隔
  ///
  /// 不限类型, 通常是 [ListTile] / [AppListTile] / 任意 44pt 高的 widget。
  final List<Widget> children;

  /// iOS section footer: 章节下方说明文字 (e.g. "点击卡片查看详情")
  ///
  /// 不传则不渲染 footer。
  final String? footer;

  /// 外边距, 默认 EdgeInsets.symmetric(horizontal: pageMarginH=20)
  ///
  /// 传 null 走默认; 传 EdgeInsets.zero 让 caller 去掉外边距
  /// (用于 PageScaffold 已包 padding 的内嵌场景)。
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
    final effectiveMargin = margin ??
        const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH); // 20
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
          if (title != null) ...[
            Padding(
              // 8 上 + 4 下 (spec "padding 8/4" — 给上方 section 留空, 紧贴 section 内容)
              padding: const EdgeInsets.only(
                top: AppTokens.spacingXs, // 8
                bottom: AppTokens.spacingXxs, // 4
              ),
              child: Text(
                title!.toUpperCase(),
                style: TextStyle(
                  fontSize: _titleFontSize,
                  fontWeight: FontWeight.w500,
                  color: AppTokens.textHintColor(context),
                  letterSpacing: _titleLetterSpacing,
                ),
              ),
            ),
          ],
          // ===== 内容: 圆角 16 白色 (surface) 容器 =====
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusCard), // 16
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: surfaceColor,
                // 0 阴影 (跟 Apple Health 卡片一致, emil 决策 #3)
              ),
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
