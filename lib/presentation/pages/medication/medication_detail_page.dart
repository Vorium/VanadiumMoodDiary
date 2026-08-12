// v0.30 R101: 药物详情页 — 参照 Apple Health Medication Detail
//
// 展示药物信息 + 30天依从性日历 + 操作（编辑/续方/停药）
//
// v0.31 round 11a (Apple Health redesign · Phase 3 Task 3.3):
// 改 AppleListSection 风格 (spec §5.3 medication), 章节拆 3 个 ALL CAPS section:
// - "基本信息" (drug name + dosage + active status)
// - "用药历史" (adherence stats + 30-day mini calendar)
// - "设置" (edit / refill 操作, PrimaryButton)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_pill_icon.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/edit_medication_dialog.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

class MedicationDetailPage extends ConsumerWidget {
  const MedicationDetailPage({super.key, required this.medicationId});
  final int medicationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final medsAsync = ref.watch(allMedicationsProvider);
    final checkInsAsync = ref.watch(allCheckInsProvider);
    final today = ref.watch(todayProvider);

    return medsAsync.when(
      data: (meds) {
        final med = meds.where((m) => m.id == medicationId).firstOrNull;
        if (med == null) {
          return PageScaffold(
            title: l10n.medDetailTitle,
            child: Center(child: Text(l10n.medNotFound)),
          );
        }

        // 计算本月依从性
        final checkIns = checkInsAsync.value ?? [];
        final medCheckIns = checkIns
            .where((c) => c.medicationId == medicationId && c.isNormal)
            .toList();

        // 最近 30 天打卡天数
        final last30 = <DateTime>{};
        for (final c in medCheckIns) {
          final d =
              DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day);
          if (today.difference(d).inDays < 30) {
            last30.add(d);
          }
        }
        final adherencePct =
            med.times.isNotEmpty ? (last30.length / 30 * 100).round() : 0;

        return PageScaffold(
          title: med.name,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingMd),
            children: [
              // ═══════════════════════════════════════════════════
              // 章节 1: 基本信息 — AppleListSection + ALL CAPS title
              // ═══════════════════════════════════════════════════
              AppleListSection(
                title: l10n.medDetailBasicInfo,
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTokens.pageMarginH,
                ),
                children: [
                  // 药 icon + name + dosage
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.spacingXs),
                    child: Row(
                      children: [
                        MedicationPillIcon(
                          colorIndex: med.colorIndex,
                          size: 48,
                          initial: med.name,
                        ),
                        const SizedBox(width: AppTokens.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med.name,
                                style: AppTokens.textStyleTitle(context).copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppTokens.spacingXxs),
                              Text(
                                '${med.dosage}${med.dosageUnit.id}  ·  '
                                '${med.times.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').join(', ')}',
                                style: TextStyle(
                                  fontSize: AppTokens.fontSizeBody,
                                  color: AppTokens.textSecondaryColor(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 状态 chip
                  _InfoChip(
                    label: med.isInUse
                        ? l10n.medDetailActive
                        : l10n.medDetailStopped,
                    color: med.isInUse
                        ? AppColors.success
                        : AppTokens.textHintColor(context),
                  ),
                ],
              ),

              const SizedBox(height: AppTokens.spacingMd),

              // ═══════════════════════════════════════════════════
              // 章节 2: 用药历史 — AppleListSection + ALL CAPS title
              // ═══════════════════════════════════════════════════
              AppleListSection(
                title: l10n.medDetailHistory,
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTokens.pageMarginH,
                ),
                children: [
                  // 依从性 label
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.spacingXs),
                    child: Text(
                      l10n.medDetailAdherence,
                      style: AppTokens.textStyleLabelStrong(context),
                    ),
                  ),
                  // 2 个数字 (ultralight metricMd 22) Row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: '$adherencePct%',
                          label: l10n.medDetailLast30,
                          color: adherencePct >= 80
                              ? AppColors.success
                              : AppTokens.warningColor(context),
                        ),
                      ),
                      const SizedBox(width: AppTokens.spacingSm),
                      Expanded(
                        child: _StatCard(
                          value: '${last30.length}/30',
                          label: l10n.medDetailDays,
                          color: AppTokens.primaryColor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.spacingMd),
                  // 30天日历
                  Text(
                    l10n.medDetailLast30Record,
                    style: AppTokens.textStyleLabelStrong(context),
                  ),
                  const SizedBox(height: AppTokens.spacingSm),
                  _MiniCalendar(
                    checkInDays: last30,
                    today: today,
                  ),
                ],
              ),

              const SizedBox(height: AppTokens.spacingMd),

              // ═══════════════════════════════════════════════════
              // 章节 3: 设置 — AppleListSection + ALL CAPS title
              // ═══════════════════════════════════════════════════
              AppleListSection(
                title: l10n.medDetailSettings,
                margin: const EdgeInsets.symmetric(
                  horizontal: AppTokens.pageMarginH,
                ),
                children: [
                  PrimaryButton(
                    isFullWidth: true,
                    variant: PrimaryButtonVariant.secondary,
                    leadingIcon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      final saved =
                          await showEditMedicationDialog(context, med);
                      if (context.mounted && (saved ?? false)) {
                        ref.invalidate(allMedicationsProvider);
                        ref.invalidate(medicationsProvider);
                      }
                    },
                    child: Text(l10n.medDetailEdit),
                  ),
                  const SizedBox(height: AppTokens.spacingSm),
                  PrimaryButton(
                    isFullWidth: true,
                    variant: PrimaryButtonVariant.secondary,
                    leadingIcon: const Icon(Icons.inventory_2_outlined),
                    onPressed: () => context.push('/settings/refills'),
                    child: Text(l10n.medDetailRefill),
                  ),
                ],
              ),

              const SizedBox(height: AppTokens.spacingLg),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('$e')),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppTokens.fontSizeCaption,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTokens.edgeInsetsMd,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      ),
      child: Column(
        children: [
          // v0.31 R7a: 数字改 ultralight w200 + 22pt (textStyleMetricMd 风格)
          // (保留原色, 走 fontWeightUltralight 让 Apple Health 感更强)
          Text(
            value,
            style: TextStyle(
              fontSize: AppTokens.fontSizeMetricMd,
              fontWeight: AppTokens.fontWeightUltralight,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textHintColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

/// 30天迷你日历
class _MiniCalendar extends StatelessWidget {
  const _MiniCalendar({required this.checkInDays, required this.today});
  final Set<DateTime> checkInDays;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final days = List.generate(30, (i) {
      final d = today.subtract(Duration(days: 29 - i));
      return DateTime(d.year, d.month, d.day);
    });

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: days.map((d) {
        final done = checkInDays.contains(d);
        final isToday = d.year == today.year &&
            d.month == today.month &&
            d.day == today.day;
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: done
                ? AppTokens.primaryColor(context)
                : AppTokens.dividerColor(context),
            borderRadius: BorderRadius.circular(6),
            border: isToday
                ? Border.all(
                    color: AppTokens.primaryColor(context),
                    width: 2,
                  )
                : null,
          ),
          child: Center(
            child: Text(
              '${d.day}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: done
                    ? AppTokens.fgOnPrimary(context)
                    : AppTokens.textHintColor(context),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
