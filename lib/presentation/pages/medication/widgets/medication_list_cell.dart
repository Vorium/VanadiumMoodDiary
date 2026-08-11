// v0.32 R109 (god class 拆 round 3): 抽 MedicationListCell 公开 widget
//
// 改前: `_MedicationListCell` 是 `medication_page.dart` 552L 内的 private
//   sub-widget (line 398-421, ~80L), 跟 4 个其他 sub-widget (`_SlotEntryRow` /
//   `_EmptyMedicationsCard` / `_EmptyScheduleCard`) + main build + 5 个 helper
//   混在 1 个 page 文件. 跨 feature import 触发 check_cross_feature 风险.
// 改后: 移到 `widgets/medication_list_cell.dart` 公开 widget, 跟现有
//   `medication_pill_icon` / `medications_list_widget` 同目录. page 调
//   `MedicationListCell(med: ..., onTap: ...)`. emil DRY 跟 R31 R108 子
//   widget 抽模式一致.
//
// 4 层架构: presentation/widgets/ 抽公开 widget, 跨 feature 复用.

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_pill_icon.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 我的药物 list cell (AppleListSection 内部用)
///
/// v0.32 R109 (god class 拆 round 3): 公开化 + 移 `widgets/` 目录.
/// 替代原 `_MedicationListCell` (presentation private).
class MedicationListCell extends StatelessWidget {
  const MedicationListCell({
    super.key,
    required this.med,
    required this.onTap,
  });

  final MedicationEntity med;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PressFeedback(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingXxs),
        child: Row(
          children: [
            MedicationPillIcon(
              colorIndex: med.colorIndex,
              size: 36,
              initial: med.name,
            ),
            const SizedBox(width: AppTokens.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeBody,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.textPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${med.dosage}${med.dosageUnit.id}  ·  '
                    '${med.times.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').join(', ')}',
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textHintColor(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.spacingXs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacingXs,
                vertical: AppTokens.spacingXxxs,
              ),
              decoration: BoxDecoration(
                color: med.isInUse
                    ? AppTokens.tintedSuccessSoft(context)
                    : AppTokens.dividerColor(context),
                borderRadius: BorderRadius.circular(AppTokens.radiusChip),
              ),
              child: Text(
                med.isInUse
                    ? l10n.medicationStatusInUse
                    : l10n.medicationStatusStopped,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeCaptionSm,
                  fontWeight: FontWeight.w600,
                  color: med.isInUse
                      ? AppColors.success
                      : AppTokens.textHintColor(context),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.spacingXxs),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: AppTokens.textHintColor(context),
            ),
          ],
        ),
      ),
    );
  }
}
