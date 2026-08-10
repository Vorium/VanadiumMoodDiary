// v0.31 round 9a (Apple Health redesign · Phase 3 Task 3.1):
// SecondaryActionRow 重设
//
// 历史:
// - v0.18 round 18 (P1-27): 从 home_page 抽出
// - v0.21 Round 22 (P0-9): PressFeedback 集中器
// - v0.22 round 28 (emil-28): MoodQuickButton 也外包 PressFeedback
// - v0.30 R87 (sub-spec 3 mood 列表页): 在 MoodQuickButton 下方加 "Mood 历史" 入口
//
// v0.31 R9a 改造 (Apple Health "更多" 章节):
// - AppleListSection("更多") 包装 (iOS 群组列表风格)
// - 4 个 icon-row cell: 心情 (mood) / Mood 历史 (mood-list) / 树洞 (vent) /
//   设置 (settings) — 取代原 3 个 SecondaryButton column
// - 间距 16 (spacingMd) — 章节内容 cell 垂直间距
// - cell 用 PressFeedback (mode 2 不接管 tap, child 自带 onTap)
//
// 设计选择:
// - 删 MoodQuickButton: QuickMoodCarousel (新设计) 已替代速记心情, 留 MoodQuickButton
//   重复 + 占视觉; "更多" 章节的 "心情" cell 改走完整 MoodRecorderPage 入口
// - "设置" 从原 HomeHeader 搬过来 (新 header 只留 theme toggle, 入口功能下放)
// - 求助热线保留在 HomeFabToolbar (R92 P0-2 永远显示), 不在 "更多" 章节重复
// - iOS 风格 cell: Icon 24 (主色/feature 色) + 标题 17 + 副标题 (可选) + chevron

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 主页"更多" 4 项 icon-row cell (Apple Health 风格)
///
/// v0.31 R9a: 4 个 cell — 心情 / Mood 历史 / 树洞 / 设置
class SecondaryActionRow extends StatelessWidget {
  /// "心情" cell onTap — 走完整 MoodRecorderPage 4 维度评分
  final VoidCallback onMoodTap;

  const SecondaryActionRow({super.key, required this.onMoodTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppleListSection(
      title: '更多',
      margin: EdgeInsets.zero,
      children: [
        _RowCell(
          icon: Icons.mood,
          iconColor: AppColors.healthMetricsColorFor('mood'), // systemPink
          title: '心情',
          subtitle: l10n.moodRecordButton, // "记一下情绪 ✏️"
          onTap: onMoodTap,
        ),
        _RowCell(
          icon: Icons.list_alt,
          iconColor: AppTokens.textSecondaryColor(context),
          title: l10n.moodListPageTitle, // "Mood 历史"
          // TODO(Phase 5): 走 ARB
          subtitle: '查看过往记录',
          onTap: () => context.push('/mood-list'),
        ),
        _RowCell(
          icon: Icons.forest_outlined,
          iconColor: AppColors.healthMetricsColorFor('vent'), // systemPurple
          title: l10n.homeVentButton.replaceAll(' 🌲', ''), // "树洞"
          // TODO(Phase 5): 走 ARB
          subtitle: '私密空间 · 1 人可见',
          onTap: () => context.push('/vent'),
        ),
        _RowCell(
          icon: Icons.settings_outlined,
          iconColor: AppTokens.textSecondaryColor(context),
          // TODO(Phase 5): 走 ARB
          title: '设置',
          subtitle: '提醒 / 隐私 / 数据导出',
          onTap: () => context.push('/settings'),
        ),
      ],
    );
  }
}

/// v0.31 R9a: 单个 iOS 风格 icon-row cell
///
/// Icon 24 (主色) + 标题 17 + 副标题 13 (textSecondary) + chevron 16
class _RowCell extends StatelessWidget {
  const _RowCell({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      onTap: onTap,
      child: Row(
        children: [
          // 左侧 icon (24pt, 主色)
          Icon(icon, size: 24, color: iconColor),
          const SizedBox(width: AppTokens.spacingSm),
          // 中: title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTokens.textStyleBody(context).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTokens.textStyleCaption(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // 右: chevron
          Icon(
            Icons.chevron_right,
            size: 16,
            color: AppTokens.textHintColor(context),
          ),
        ],
      ),
    );
  }
}
