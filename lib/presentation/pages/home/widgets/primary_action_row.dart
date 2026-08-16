// v1.1.0 round 11 (R115 视觉重构): 快捷操作改列表式
//
// 历史:
// - v0.18 round 18 (P1-27): 从 home_page 抽出
// - v0.21 Round 22 (P0-9): PressFeedback 集中器
// - v0.31 R9a: 2x2 Apple Health Tile 网格 (用药/评估/回顾/追踪 4 砖块)
// - 1.1.0 round 5b (Task 12): 换血 4 tile → 用药/量表/情绪回顾/日常追踪
// - v1.1.0 round 11 (R115): 砖块改列表 (3 行 + 1 虚线「更多」入口),
//   emotion-first refactor 续作 — 主页不再露「用药」「量表」字样,
//   改走 BottomSheet 二级入口。
//
// 设计:
// - 3 行 list: 情绪回顾 (mood pink) / 日常追踪 (orange) / 心理技巧 (blue)
//   全是 vent + mood 周边功能, 跟双主卡语义一致。
// - 1 虚线入口「更多」: 用药 / 量表 / 危机热线 / 烦恼闭环 4 项 收进
//   [showMoreEntrySheet]。
// - 4 个 onXxxTap 回调: 情绪回顾 / 日常追踪 / 心理技巧 / 更多。
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/home/widgets/more_entry_sheet.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 主页「快捷操作」— 3 行 list + 1 虚线「更多」入口
///
/// v1.1.0 round 11 (R115): 从 2x2 砖块改列表, 移走用药/量表砖块。
class PrimaryActionRow extends StatelessWidget {
  final VoidCallback onMoodReviewTap;
  final VoidCallback onDailyTrackingTap;
  final VoidCallback onTipsTap;

  const PrimaryActionRow({
    super.key,
    required this.onMoodReviewTap,
    required this.onDailyTrackingTap,
    required this.onTipsTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppleListSection(
      title: l10n.medQuickActions, // "快捷操作" / "Quick Actions"
      margin: EdgeInsets.zero,
      children: [
        _listRow(
          context,
          icon: Icons.insights_outlined,
          iconColor: const Color(0xFFFF2D55), // iOS systemPink
          title: l10n.homeActionMoodReview, // "情绪回顾"
          subtitle: l10n.homeActionMoodReviewSub(0, '—'), // 动态数值由 caller 注入
          onTap: onMoodReviewTap,
          showDivider: true,
        ),
        _listRow(
          context,
          icon: Icons.bedtime_outlined,
          iconColor: const Color(0xFFFF9500), // iOS systemOrange
          title: l10n.homeActionDailyTracking, // "日常追踪"
          subtitle: l10n.homeActionDailyTrackingSub,
          onTap: onDailyTrackingTap,
          showDivider: true,
        ),
        _listRow(
          context,
          icon: Icons.self_improvement_outlined,
          iconColor: const Color(0xFF007AFF), // iOS systemBlue
          title: l10n.homeActionTips, // "心理技巧"
          subtitle: l10n.homeActionTipsSub,
          onTap: onTipsTap,
          showDivider: false,
        ),
      ],
    );
  }

  Widget _listRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    final children = <Widget>[
      InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacingMd,
            vertical: AppTokens.spacingSm + 2,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(AppTokens.spacingXs),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppTokens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTokens.textStyleBody(context).copyWith(
                              fontWeight: FontWeight.w500,
                            )),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppTokens.textStyleCaption(context).copyWith(
                              color: AppTokens.textHintColor(context),
                            )),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.spacingXs),
              Icon(
                Icons.chevron_right,
                color: AppTokens.textHintColor(context),
                size: AppTokens.iconSize,
              ),
            ],
          ),
        ),
      ),
    ];
    if (showDivider) {
      children.add(
        Divider(
          height: 0,
          thickness: 0.5,
          color: AppTokens.dividerColor(context),
          indent: 16 + 32 + 16, // padding + icon + gap
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

/// Home 底部「更多」虚线入口 (单独组件, PrimaryActionRow 外放在最底部)
///
/// v1.1.0 round 11 (R115): 弱化二级入口 — 虚线边框 + textSecondary 色
/// (跟 PrimaryActionRow 强列表形成层次差), 提示"这里有更多内容"。
class MoreEntryTrigger extends StatelessWidget {
  const MoreEntryTrigger({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PressFeedback(
      onTap: () => showMoreEntrySheet(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          border: Border.all(
            color: AppTokens.borderColor(context),
            style: BorderStyle.solid,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingMd,
          vertical: AppTokens.spacingSm + 4,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTokens.surfaceColor(context),
                borderRadius: BorderRadius.circular(AppTokens.spacingXs),
                border: Border.all(
                  color: AppTokens.borderColor(context),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.more_horiz,
                color: AppTokens.textSecondaryColor(context),
                size: 20,
              ),
            ),
            const SizedBox(width: AppTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.homeMoreEntryTitle, // "更多"
                      style: AppTokens.textStyleBody(context).copyWith(
                            color: AppTokens.textSecondaryColor(context),
                            fontWeight: FontWeight.w500,
                          )),
                  const SizedBox(height: 2),
                  Text(l10n.homeMoreEntrySubtitle, // "用药 · 量表 · 危机热线"
                      style: AppTokens.textStyleCaption(context).copyWith(
                            color: AppTokens.textHintColor(context),
                          )),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTokens.textHintColor(context),
              size: AppTokens.iconSize,
            ),
          ],
        ),
      ),
    );
  }
}
