// v0.30 R101: 药物详情页 — 参照 Apple Health Medication Detail
//
// 展示药物信息 + 30天依从性日历 + 操作（编辑/续方/停药）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_pill_icon.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/edit_medication_dialog.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

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
            padding: AppTokens.edgeInsetsMd,
            children: [
              // 药物信息卡
              Card(
                child: Padding(
                  padding: AppTokens.edgeInsetsLg,
                  child: Column(
                    children: [
                      MedicationPillIcon(
                        colorIndex: med.colorIndex,
                        size: 64,
                        initial: med.name,
                      ),
                      const SizedBox(height: AppTokens.spacingMd),
                      Text(
                        med.name,
                        style: const TextStyle(
                          fontSize: AppTokens.fontSizeTitle,
                          fontWeight: FontWeight.w700,
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
                      const SizedBox(height: AppTokens.spacingSm),
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
                ),
              ),

              const SizedBox(height: AppTokens.spacingMd),

              // 依从性统计
              Card(
                child: Padding(
                  padding: AppTokens.edgeInsetsMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.medDetailAdherence,
                        style: const TextStyle(
                          fontSize: AppTokens.fontSizeBody,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTokens.spacingSm),
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTokens.spacingMd),

              // 30天日历
              Card(
                child: Padding(
                  padding: AppTokens.edgeInsetsMd,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.medDetailLast30Record,
                        style: const TextStyle(
                          fontSize: AppTokens.fontSizeBody,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTokens.spacingSm),
                      _MiniCalendar(
                        checkInDays: last30,
                        today: today,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppTokens.spacingMd),

              // 操作按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(l10n.medDetailEdit),
                      onPressed: () async {
                        final saved =
                            await showEditMedicationDialog(context, med);
                        if (context.mounted && (saved ?? false)) {
                          ref.invalidate(allMedicationsProvider);
                          ref.invalidate(medicationsProvider);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacingSm),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.inventory_2_outlined),
                      label: Text(l10n.medDetailRefill),
                      onPressed: () => context.push('/settings/refills'),
                    ),
                  ),
                ],
              ),
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
    return Container(
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
          Text(
            value,
            style: TextStyle(
              fontSize: AppTokens.fontSizeTitle,
              fontWeight: FontWeight.w700,
              color: color,
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
