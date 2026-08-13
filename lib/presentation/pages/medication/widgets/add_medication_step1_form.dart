// v0.32 R112 (AR-20 god class 批2b): 抽 add_medication_page Step 1 表单
//
// 改前: `add_medication_page.dart` 573L, `_buildStep1` (line 222-296)
//   inline builder 混在 page state 里 (form + validation + submit 3 职责)。
// 改后: 抽无状态 widget, 值 + 回调注入, state 留在 page。跟 R109 round 4
//   抽 MedicationConfirmRow 同款子 widget 抽模式。
//
// 4 层架构: presentation/widgets 公开 widget, 0 state 值注入。UI 行为
// 1:1 不动 (AppleListSection "基本信息" + 药名 TextField + 剂型 ChoiceChip)。

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/medication_form.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/add_medication_form_shared.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

/// Step 1: 药名 + 剂型 (AppleListSection "基本信息")
///
/// R112 AR-20 批2b: 原 `_buildStep1` 1:1 迁移。
/// 值注入: [nameController] (page state 持有) + [form] + [onFormChanged]。
class AddMedicationStep1Form extends StatelessWidget {
  const AddMedicationStep1Form({
    super.key,
    required this.nameController,
    required this.form,
    required this.onFormChanged,
  });

  /// 药名输入 controller (page state 持有, 跨 step 保留)
  final TextEditingController nameController;

  /// 当前剂型
  final MedicationForm form;

  /// 剂型切换回调 (page setState)
  final ValueChanged<MedicationForm> onFormChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingMd),
      children: [
        MedicationStepTitle(text: l10n.medAddStep1Title),
        const SizedBox(height: AppTokens.spacingMd),

        // "基本信息" AppleListSection
        AppleListSection(
          title: l10n.medAddBasicInfo,
          margin: const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
          children: [
            // 药名
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppTokens.spacingXxs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.medAddNameLabel,
                    style: AppTokens.textStyleCaptionHint(context),
                  ),
                  const SizedBox(height: AppTokens.spacingXxs),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: l10n.medAddNameHint,
                      border: InputBorder.none, // AppleListSection 自带容器
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
            ),
            // 剂型
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.spacingXs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.medAddFormLabel,
                    style: AppTokens.textStyleCaptionHint(context),
                  ),
                  const SizedBox(height: AppTokens.spacingXs),
                  Wrap(
                    spacing: AppTokens.spacingSm,
                    runSpacing: AppTokens.spacingSm,
                    children: MedicationForm.values.map((f) {
                      final selected = form == f;
                      return ChoiceChip(
                        label: Text(medicationFormLabel(f, l10n)),
                        selected: selected,
                        onSelected: (_) => onFormChanged(f),
                        avatar: Icon(medicationFormIcon(f), size: 18),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
