// v0.32 R112 (AR-20 god class 批2b): 抽 add_medication_page 3 步表单
// 共享视觉 helper
//
// 改前: `_StepTitle` (3 步重复大标题) + `_formLabel` / `_formIcon`
//   (药型 → l10n label / icon) 是 `add_medication_page.dart` 573L 内
//   private helper (form + validation + submit 3 职责)。
// 改后: 抽公开 widget + 2 公开映射函数, add_medication_step1/2/3_form
//   共用, 避免 3 文件各自 copy。跟 R109 round 4 抽 MedicationConfirmRow
//   同款子 widget 抽模式。
//
// 4 层架构: presentation/widgets 公开 widget + 纯映射函数。

import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/features/medication/domain/entities/medication_form.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 添加向导 3 步共用的大标题 (textStyleTitle w600, 横向 pageMarginH)
///
/// R112 AR-20 批2b: 原 `_StepTitle` (page private) 公开化。
class MedicationStepTitle extends StatelessWidget {
  const MedicationStepTitle({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
      child: Text(
        text,
        style: AppTokens.textStyleTitle(context).copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 药型 → l10n label (Step1 chip + Step3 确认行共用)
///
/// R112 AR-20 批2b: 原 `_formLabel` (page private) 公开化。
String medicationFormLabel(MedicationForm f, AppLocalizations l10n) {
  switch (f) {
    case MedicationForm.tablet:
      return l10n.medFormTablet;
    case MedicationForm.capsule:
      return l10n.medFormCapsule;
    case MedicationForm.liquid:
      return l10n.medFormLiquid;
    case MedicationForm.patch:
      return l10n.medFormPatch;
    case MedicationForm.injection:
      return l10n.medFormInjection;
    case MedicationForm.other:
      return l10n.medFormOther;
  }
}

/// 药型 → icon (Step1 chip avatar)
///
/// R112 AR-20 批2b: 原 `_formIcon` (page private) 公开化。
IconData medicationFormIcon(MedicationForm f) {
  switch (f) {
    case MedicationForm.tablet:
      return Icons.medication_rounded;
    case MedicationForm.capsule:
      return Icons.vaccines_rounded;
    case MedicationForm.liquid:
      return Icons.water_drop_outlined;
    case MedicationForm.patch:
      return Icons.healing_outlined;
    case MedicationForm.injection:
      return Icons.colorize_outlined;
    case MedicationForm.other:
      return Icons.more_horiz_rounded;
  }
}
