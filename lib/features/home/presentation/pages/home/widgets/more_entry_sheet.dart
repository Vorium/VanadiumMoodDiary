// v1.1.0 round 11 (R115 视觉重构): 「更多」BottomSheet
//
// 主页双主卡 / 快捷操作 不再露「用药」「量表」字样 (emotion-first refactor 续作),
// 二级入口 (用药 / 量表 / 危机热线 / 烦恼闭环) 收进 BottomSheet,
// 用户点 Home 底部「更多」入口 (虚线边框, weak affordance) 唤起。
//
// 视觉: iOS standard BottomSheet 风格 (圆角 14, grabber bar, blur 背景),
// 4 个 AppleListSection-style row (icon + title + subtitle + chevron)。
// 副标题用 computed text (动态 {n} 已服 / {n} 量表等), 来自 ARB
// homeMore*Sub 键 (v1.1.0 round 11 新加)。
//
// 隐私边界: 不读 vent 内容, 不读 mood 分数; 只统计数量。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/providers/worry_providers.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 显示「更多」BottomSheet — Home 底部「更多」入口 onTap 调本函数
///
/// showModalBottomSheet 走 default iOS slide-up (M3 spec 默认), 内部用
/// 4 行 list (用药 / 评估 / 热线 / 烦恼) + grabber bar。
Future<void> showMoreEntrySheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppTokens.surfaceColor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppTokens.radiusCard)),
    ),
    builder: (ctx) => const _MoreEntrySheet(),
  );
}

class _MoreEntrySheet extends ConsumerWidget {
  const _MoreEntrySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // v1.1.0 round 11 (R115): 4 个二级入口的动态计数, 实时反映最新数据
    final meds = ref.watch(medicationsProvider).value ?? const <MedicationEntity>[];
    final activeMeds = meds.where((m) => m.isInUse).toList();
    final checkIns = ref.watch(todayAllCheckInsProvider).value ??
        const <CheckInEntity>[];
    final todayMedIds = <int>{};
    for (final c in checkIns) {
      if (c.isNormal && c.medicationId != null) {
        todayMedIds.add(c.medicationId!);
      }
    }
    final assessments = ref.watch(assessmentsProvider).value ??
        const <CheckInEntity>[];
    final worryOpen = ref.watch(worryOpenProvider).value ?? const [];
    final worryResolved = ref.watch(worryResolvedProvider).value ?? const [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: AppTokens.spacingMd,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppTokens.spacingMd,
                right: AppTokens.spacingMd,
                top: AppTokens.spacingXxs,
                bottom: AppTokens.spacingXs,
              ),
              child: Text(
                l10n.homeMoreSheetTitle,
                style: AppTokens.textStyleCaption(context).copyWith(
                  color: AppTokens.textHintColor(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _SheetRow(
              icon: Icons.medication_outlined,
              iconColor: const Color(0xFFFF3B30), // iOS systemRed
              title: l10n.homeMoreMedication,
              subtitle: activeMeds.isEmpty
                  ? l10n.homeMoreAssessmentSub(0)
                  : l10n.homeMoreMedicationSub(
                      activeMeds.length, todayMedIds.length),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/medication');
              },
            ),
            _SheetRow(
              icon: Icons.assignment_outlined,
              iconColor: const Color(0xFF5E5CE6), // iOS systemIndigo
              title: l10n.homeMoreAssessment,
              subtitle: l10n.homeMoreAssessmentSub(assessments.length),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/assessment-center');
              },
            ),
            _SheetRow(
              icon: Icons.phone_in_talk_outlined,
              iconColor: const Color(0xFFFF9500), // iOS systemOrange
              title: l10n.homeMoreCrisis,
              subtitle: l10n.homeMoreCrisisSub,
              onTap: () {
                Navigator.of(context).pop();
                context.push('/crisis-hotline');
              },
            ),
            _SheetRow(
              icon: Icons.psychology_outlined,
              iconColor: const Color(0xFFAF52DE), // iOS systemPurple
              title: l10n.homeMoreWorry,
              subtitle: l10n.homeMoreWorrySub(
                worryOpen.length, worryResolved.length),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/worry');
              },
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(
                    bottom: BorderSide(
                      color: AppTokens.dividerColor(context),
                      width: 0.5,
                    ),
                  ),
          ),
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
                // gdc R128e audit 2026-08-18: Colors.white → AppColors.fgOnPrimary
                child: Icon(icon, color: AppColors.fgOnPrimary(context), size: 20),
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
    );
  }
}
