// R114 B1-1: AppleListSection 的懒加载 sliver 变体
// (2026-08-16 标准审计 · 02-code-standards F-01)
//
// R112 ALS 化回归: mood_list / vent_list 从 ListView.builder /
// ListView.separated 改成 `ListView(children: [AppleListSection(children:
// [for ...])])` — Column 全量构建 + 无 viewport 回收, 年积累 1000+ 条时
// 首帧/滚动帧率劣化 (树洞每条还叠 FadeIn + Dismissible)。
//
// 修法: CustomScrollView + SliverMainAxisGroup + SliverList.builder —
// 只构建 viewport 内的 cell。视觉 1:1 复刻 AppleListSection:
// - title 13pt w500 ALL CAPS letterSpacing 0.6 textHint (可选 chip)
// - 圆角 16 surface 容器 + hairline 0.5 divider + cell padding 16/12
// - dark mode #1C1C1E / dividerDark
// 圆角容器改为"每 cell 自带 Material 背景 + 首尾圆角" (iOS 分组列表标准
// 做法), 视觉与单容器一致。若 AppleListSection header 样式变更, 本文件
// header 同步改 (两处集中器注释互指)。
//
// R114 B2-4: margin 参数删除 (B1-1 引入后 0 caller + build 从未应用 —
// 死参数; 页边距统一由 PageScaffold 负责 20px, 同 AppleListSection 裁决)。
import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/widgets/chip_badge.dart';

class LazyAppleListSection extends StatelessWidget {
  const LazyAppleListSection({
    super.key,
    this.title,
    this.chip,
    required this.itemCount,
    required this.itemBuilder,
    this.footer,
    this.physics,
    this.scrollPadding = EdgeInsets.zero,
  });

  /// iOS section header (同 AppleListSection.title, 13pt ALL CAPS)
  final String? title;

  /// 标题右侧数量徽章 (同 AppleListSection.chip)
  final String? chip;

  /// cell 数量 (懒构建, 只建 viewport 内的)
  final int itemCount;

  /// cell builder — cell 由本 widget 包默认 padding (16/12) + hairline divider
  final IndexedWidgetBuilder itemBuilder;

  /// section footer 小字 (同 AppleListSection.footer)
  final String? footer;

  /// 滚动物理 (RefreshIndicator 场景传 AlwaysScrollableScrollPhysics)
  final ScrollPhysics? physics;

  /// 整段滚动 padding (原 ListView padding 迁移)
  final EdgeInsets scrollPadding;

  /// iOS section header 字号 (13pt) — 与 AppleListSection 同
  static const double _titleFontSize = AppTokens.fontSizeCaption; // 13.0

  /// iOS ALL CAPS section header letter-spacing (与 AppleListSection 同)
  static const double _titleLetterSpacing = 0.6;

  /// 章节内容 cell 默认 padding (16 横向, 12 纵向 — 与 AppleListSection 同)
  static const EdgeInsets _cellPadding = EdgeInsets.symmetric(
    horizontal: AppTokens.spacingMd, // 16
    vertical: AppTokens.spacingSm, // 12 (iOS list cell vertical)
  );

  /// hairline divider 厚度 (与 AppleListSection 同)
  static const double _hairlineThickness = 0.5;

  @override
  Widget build(BuildContext context) {
    // 与 AppleListSection 同款取色: dark 用静态 surfaceDark (#1C1C1E),
    // light 走 theme.surface (不跟 M3 seed 派生色)
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppTokens.surfaceDark : AppTokens.surfaceColor(context);
    final dividerColor =
        isDark ? AppTokens.dividerDark : AppTokens.dividerColor(context);

    return CustomScrollView(
      physics: physics,
      slivers: [
        SliverPadding(
          padding: scrollPadding,
          sliver: SliverMainAxisGroup(
            slivers: [
              if (title != null) ...[
                SliverToBoxAdapter(child: _buildTitle(context, title!, chip)),
              ],
              SliverList.builder(
                itemCount: itemCount,
                itemBuilder: (context, i) {
                  final radius = BorderRadius.vertical(
                    top: i == 0
                        ? const Radius.circular(AppTokens.radiusCard) // 16
                        : Radius.zero,
                    bottom: i == itemCount - 1
                        ? const Radius.circular(AppTokens.radiusCard)
                        : Radius.zero,
                  );
                  return ClipRRect(
                    borderRadius: radius,
                    child: Material(
                      color: surfaceColor,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: _cellPadding,
                            child: itemBuilder(context, i),
                          ),
                          if (i < itemCount - 1)
                            Divider(
                              height: 0,
                              thickness: _hairlineThickness,
                              color: dividerColor,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (footer != null) ...[
                SliverToBoxAdapter(child: _buildFooter(context, footer!)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 章节 header — 与 AppleListSection 的 inline title 行 1:1 复刻
  Widget _buildTitle(BuildContext context, String title, String? chip) {
    return Padding(
      // 8 上 + 4 下 (跟 AppleListSection spec "padding 8/4" 一致)
      padding: const EdgeInsets.only(
        top: AppTokens.spacingXs, // 8
        bottom: AppTokens.spacingXxs, // 4
      ),
      child: Row(
        children: [
          // 窄屏/大字号防溢出 — title 弹性收缩 (同 AppleListSection)
          Flexible(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: _titleFontSize, // 13
                color: AppTokens.textHintColor(context),
                fontWeight: FontWeight.w500,
                letterSpacing: _titleLetterSpacing, // 0.6
              ),
            ),
          ),
          if (chip != null) ...[
            const SizedBox(width: AppTokens.spacingXs),
            ChipBadge(label: chip),
          ],
        ],
      ),
    );
  }

  /// footer 小字 — 与 AppleListSection footer 1:1 复刻
  Widget _buildFooter(BuildContext context, String footer) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTokens.spacingXxs, // 4
        left: AppTokens.spacingXs, // 8 (跟 title 横向对齐)
        right: AppTokens.spacingXs,
      ),
      child: Text(
        footer,
        style: AppTokens.textStyleCaptionHint(context),
      ),
    );
  }
}
