// v0.31 round 9a (Apple Health redesign · Phase 3 Task 3.1):
// PrimaryActionRow 重设
//
// 历史:
// - v0.18 round 18 (P1-27): 从 home_page 抽出
// - v0.21 Round 22 (P0-9): PressFeedback 集中器
//
// v0.31 R9a 改造 (Apple Health "快捷操作" 2x2 彩色 tile 网格):
// - AppleListSection("快捷操作") 包装 (iOS 群组列表风格)
// - 2x2 AppleHealthTile 网格: medication(red) / mood(pink) / vent(purple) /
//   assessment(indigo) — 4 个 Apple Health "favorites" 彩色 metric 模块
// - 间距 12 (spacingSm) — 2x2 tile 紧凑布局
// - onTap 走 caller 决定的路由 (本 widget 不 hardcode context.push, 让 home_page
//   注入 onXxxTap 回调, 跟其他 widget 模式一致)
//
// 1.1.0 round 5b (emotion-first refactor · Task 12): 换血 4 tile —
// 用药(medication) / 量表(assessment) / 情绪回顾(mood) / 日常追踪(trend),
// 回调改 onMedicationTap / onAssessmentTap / onMoodReviewTap /
// onDailyTrackingTap (树洞/心情记录入口升格为 hero 卡, 不再放快捷操作)。

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/apple_health_tile.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

/// 主页"快捷操作" 2x2 Apple Health 彩色 tile 网格
///
/// v0.31 R9a: 4 个 AppleHealthTile 替代原 3 个 button column
/// (CheckIn / TempMed / Snooze)。
///
/// 1.1.0 round 5b (Task 12): 4 tile 换血为 用药/量表/情绪回顾/日常追踪
/// (原 medication/mood/vent/assessment → vent 升格 hero 卡, mood 改
/// 情绪回顾)。
class PrimaryActionRow extends StatelessWidget {
  final VoidCallback onMedicationTap;
  final VoidCallback onAssessmentTap;
  final VoidCallback onMoodReviewTap;
  final VoidCallback onDailyTrackingTap;

  const PrimaryActionRow({
    super.key,
    required this.onMedicationTap,
    required this.onAssessmentTap,
    required this.onMoodReviewTap,
    required this.onDailyTrackingTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppleListSection(
      title: l10n.medQuickActions, // "快捷操作" / "Quick Actions"
      margin: EdgeInsets.zero,
      children: [
        // 2x2 AppleHealthTile 网格
        IntrinsicHeight(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppleHealthTile(
                      metricId: 'medication',
                      label: l10n.homeActionMedication, // "用药"
                      value: l10n.homeQuickActionView, // "查看"
                      onTap: onMedicationTap,
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacingSm),
                  Expanded(
                    child: AppleHealthTile(
                      metricId: 'assessment',
                      label: l10n.homeActionAssessment, // "量表"
                      value: l10n.homeQuickActionStart, // "开始"
                      onTap: onAssessmentTap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Row(
                children: [
                  Expanded(
                    child: AppleHealthTile(
                      metricId: 'mood',
                      label: l10n.homeActionMoodReview, // "情绪回顾"
                      value: l10n.homeMoodHeroReview, // "回顾"
                      onTap: onMoodReviewTap,
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacingSm),
                  Expanded(
                    child: AppleHealthTile(
                      metricId: 'trend',
                      label: l10n.homeActionDailyTracking, // "日常追踪"
                      value: l10n.homeQuickActionRecord, // "记录"
                      onTap: onDailyTrackingTap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
