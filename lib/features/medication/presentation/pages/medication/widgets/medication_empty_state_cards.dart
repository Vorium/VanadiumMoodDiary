// v0.32 R109 (god class 拆 round 3): 抽 2 个空态 widget
//
// 改前: `_EmptyMedicationsCard` (line 343-380, 38L) + `_EmptyScheduleCard`
//   (line 383-415, 33L) 是 `medication_page.dart` 552L 内的 2 个 private
//   sub-widget, 跟 4 个其他 sub-widget + main build + 5 个 helper 混.
// 改后: 移到 `widgets/medication_empty_state_cards.dart` 公开 widget,
//   跟 `medication_list_cell.dart` (本批同抽) + `medication_pill_icon`
//   等同目录. 跟 R31 R108 子 widget 抽模式一致.

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

/// 空态：无药物
///
/// v0.32 R109: 公开化 + 移 `widgets/` 目录.
/// 替代原 `_EmptyMedicationsCard` (presentation private).
class EmptyMedicationsCard extends StatelessWidget {
  const EmptyMedicationsCard({super.key, required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingMd),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 48,
            color: AppTokens.textHintColor(context),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(
            l10n.medEmptyTitle,
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              fontWeight: FontWeight.w600,
              color: AppTokens.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: AppTokens.spacingXxs),
          Text(
            l10n.medEmptySubtitle,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textHintColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 空态：无今日计划
///
/// v0.32 R109: 公开化 + 移 `widgets/` 目录.
/// 替代原 `_EmptyScheduleCard` (presentation private).
class EmptyScheduleCard extends StatelessWidget {
  const EmptyScheduleCard({super.key, required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      title: l10n.medTodaySchedule,
      margin: EdgeInsets.zero,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 28,
              color: AppTokens.textHintColor(context),
            ),
            const SizedBox(width: AppTokens.spacingSm),
            Expanded(
              child: Text(
                l10n.medNoScheduleToday,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeBodySm,
                  color: AppTokens.textHintColor(context),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
