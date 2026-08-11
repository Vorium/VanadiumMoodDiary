// v0.30 round 92 (audit-fixes / P0 #15): treatment_list
//
// 治疗记录列表 widget:
// - 按月分组 (SectionHeader + entries 列表, 跟 trend_page 同款排版)
// - AppListTile.carded (跟 R91 5 list widget 一致)
// - Dismissible swipe-to-delete (跟 R67 swipe_delete_background 同款)
//
// 4 层架构: presentation/pages/daily_tracking/widgets/, 0 跨 feature import。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/treatment_entry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/swipe_delete_background.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';

/// 治疗记录列表 widget (按月分组)
///
/// 排版:
/// - 按 entry.timestamp 月份分组
/// - 每组: SectionHeader "2026-08" + AppListTile 列表
/// - 每条: AppListTile.carded + Icon + title(category+provider) + subtitle(timestamp + note)
class TreatmentList extends ConsumerWidget {
  final List<TreatmentEntryEntity> entries;

  const TreatmentList({super.key, required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // 按月分组: key = "yyyy-MM", value = entries (按 date DESC)
    final byMonth = <String, List<TreatmentEntryEntity>>{};
    for (final e in entries) {
      final key = DateFormat('yyyy-MM').format(e.timestamp);
      (byMonth[key] ??= <TreatmentEntryEntity>[]).add(e);
    }
    // 排序: 月份降序, entries 按 date DESC (R91 DAO 已排)
    final monthKeys = byMonth.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingSm,
        vertical: AppTokens.spacingSm,
      ),
      itemCount: monthKeys.length,
      itemBuilder: (context, monthIdx) {
        final monthKey = monthKeys[monthIdx];
        final monthEntries = byMonth[monthKey]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacingSm,
                vertical: AppTokens.spacingSm,
              ),
              child: SectionHeader(title: monthKey),
            ),
            for (final entry in monthEntries)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacingXxs,
                  vertical: AppTokens.spacingXxs,
                ),
                child: Dismissible(
                  key: ValueKey('treatment-${entry.id}'),
                  background: const SwipeDeleteBackground(),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    ref.read(treatmentRepositoryProvider).delete(entry.id);
                  },
                  child: AppListTile.carded(
                    leading: Icon(
                      _categoryIcon(entry.treatmentType),
                      color: AppTokens.tintedPrimaryDeep(context),
                    ),
                    title: Text(
                      _entryTitle(entry, l10n),
                      style: AppTokens.textStyleLabelStrong(context),
                    ),
                    subtitle: Text(
                      '${DateFormat('MM-dd HH:mm').format(entry.timestamp)}'
                      '${entry.note != null ? ' · ${entry.note}' : ''}',
                      style: AppTokens.textStyleBody(context),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppTokens.spacingMd),
          ],
        );
      },
    );
  }

  /// treatmentType → 中文 label (R92: 4 选 1 类别)
  ///
  /// 4 类: medication_adjustment / consultation / hospitalization / other
  /// 跟 R91 existing free String treatmentType 兼容 (R60 模式, 不开 enum)。
  String _categoryLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'medication_adjustment':
        return l10n.treatmentCategoryMedicationAdjustment;
      case 'consultation':
        return l10n.treatmentCategoryConsultation;
      case 'hospitalization':
        return l10n.treatmentCategoryHospitalization;
      case 'other':
        return l10n.treatmentCategoryOther;
    }
    return type;
  }

  /// treatmentType → Icon
  IconData _categoryIcon(String type) {
    switch (type) {
      case 'medication_adjustment':
        return Icons.medication_outlined;
      case 'consultation':
        return Icons.psychology_outlined;
      case 'hospitalization':
        return Icons.local_hospital_outlined;
      case 'other':
        return Icons.medical_services_outlined;
    }
    return Icons.medical_services_outlined;
  }

  /// entry 显示： "类别 · 医生／医院"
  String _entryTitle(TreatmentEntryEntity e, AppLocalizations l10n) {
    final category = _categoryLabel(e.treatmentType, l10n);
    return e.description.isEmpty ? category : '$category · ${e.description}';
  }
}
