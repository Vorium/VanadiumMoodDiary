// v0.32 R112 (AR-20 god class 批2b): 抽 add_medication_page Step 3 表单
//
// 改前: `add_medication_page.dart` 573L, `_buildStep3` (line 441-534)
//   inline builder 混在 page state 里 (form + validation + submit 3 职责)。
// 改后: 抽无状态 widget, 值 + 回调注入, state 留在 page。跟 R109 round 4
//   抽 MedicationConfirmRow 同款子 widget 抽模式。
//
// 4 层架构: presentation/widgets 公开 widget, 0 state 值注入。UI 行为
// 1:1 不动 (AppleListSection "颜色" 选择器 + "确认信息" 4 行)。

import 'package:flutter/material.dart';

import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/features/medication/domain/entities/medication_form.dart';
import 'package:chroniccare/domain/logic/add_medication_form_validator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/add_medication_form_shared.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_confirm_row.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_pill_icon.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// Step 3: 确认 + 颜色选择 (AppleListSection "颜色" + "确认信息")
///
/// R112 AR-20 批2b: 原 `_buildStep3` 1:1 迁移。
/// 只读展示 + 颜色回调, 0 可变 state。
class AddMedicationStep3Form extends StatelessWidget {
  const AddMedicationStep3Form({
    super.key,
    required this.name,
    required this.form,
    required this.dosageText,
    required this.dosageUnit,
    required this.times,
    required this.colorIndex,
    required this.onColorChanged,
  });

  /// 药名 (展示 + 药丸首字)
  final String name;

  /// 剂型
  final MedicationForm form;

  /// 剂量文本 (parse 兜底 0 跟原 _buildStep3 1:1)
  final String dosageText;

  /// 剂量单位
  final DosageUnit dosageUnit;

  /// 服药时间列表 (仅展示)
  final List<TimeOfDay> times;

  /// 当前颜色索引
  final int colorIndex;

  /// 颜色切换回调
  final ValueChanged<int> onColorChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final timesStr = times
        .map((t) => HourMinute(hour: t.hour, minute: t.minute).toTimeString())
        .join(', ');

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingMd),
      children: [
        MedicationStepTitle(text: l10n.medAddStep3Title),
        const SizedBox(height: AppTokens.spacingMd),

        // "颜色" AppleListSection
        AppleListSection(
          title: l10n.medAddColor,
          children: [
            Text(
              l10n.medAddColorLabel,
              style: AppTokens.textStyleCaptionHint(context),
            ),
            const SizedBox(height: AppTokens.spacingXs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(kMedPillColors.length, (i) {
                final selected = colorIndex == i;
                return PressFeedback(
                  onTap: () => onColorChanged(i),
                  child: Semantics(
                    label: l10n.medAddColorN(i + 1),
                    selected: selected,
                    button: true,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(
                                color: AppTokens.primaryColor(context),
                                width: 3,
                              )
                            : null,
                      ),
                      child: MedicationPillIcon(
                        colorIndex: i,
                        size: 40,
                        initial: name.isNotEmpty ? name : null,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spacingMd),

        // "确认信息" AppleListSection
        AppleListSection(
          title: l10n.medAddConfirm,
          children: [
            MedicationConfirmRow(
              label: l10n.medAddConfirmName,
              value: name,
            ),
            MedicationConfirmRow(
              label: l10n.medAddConfirmForm,
              value: medicationFormLabel(form, l10n),
            ),
            MedicationConfirmRow(
              label: l10n.medAddConfirmDosage,
              value: Formatters.dosage(
                // 跟原 _buildStep3 `double.tryParse(dosage) ?? 0` 1:1,
                // R109 validator.parseDosage 同语义集中
                AddMedicationFormValidator.parseDosage(dosageText),
                dosageUnit,
              ),
            ),
            MedicationConfirmRow(
              label: l10n.medAddConfirmTime,
              value: timesStr,
            ),
          ],
        ),
      ],
    );
  }
}
