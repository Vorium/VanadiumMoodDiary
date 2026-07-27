// setup_step_medication.dart — 首次设置 Step 2: 药物列表
//
// 从 setup_page.dart 拆分，v0.19 (Q2)
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

/// Step 2: 药物列表
///
/// 用户添加/编辑常吃药物 + 时间。
/// 药物列表（_meds）由父级管理。
class SetupStepMedication extends StatelessWidget {
  final List<MedDraft> meds;
  final bool saving;
  final VoidCallback onAddMed;
  final VoidCallback onShowPresets;
  final ValueChanged<int> onRemoveMed;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  const SetupStepMedication({
    super.key,
    required this.meds,
    required this.saving,
    required this.onAddMed,
    required this.onShowPresets,
    required this.onRemoveMed,
    required this.onBack,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      key: const ValueKey(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.spacingXl),
          Text(
            l10n.setupMedWhatDoYouTake,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(
            l10n.setupMedMultiDrugHint,
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          for (int i = 0; i < meds.length; i++) ...[
            MedCard(
              index: i,
              med: meds[i],
              onRemove: () => onRemoveMed(i),
            ),
            const SizedBox(height: AppTokens.spacingMd),
          ],
          if (meds.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppTokens.spacingMd),
              decoration: BoxDecoration(
                color: AppTokens.primaryLightColor(context),
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(color: AppTokens.borderColor(context)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTokens.textSecondaryColor(context),
                    size: 20,
                  ),
                  const SizedBox(width: AppTokens.spacingXs),
                  Expanded(
                    child: Text(
                      l10n.setupMedEmptyHint,
                      style: TextStyle(
                        color: AppTokens.textSecondaryColor(context),
                        fontSize: AppTokens.fontSizeLabel,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox.shrink(),
          const SizedBox(height: AppTokens.spacingMd),
          OutlinedButton.icon(
            onPressed: onAddMed,
            icon: const Icon(Icons.add),
            label: Text(l10n.setupMedAddDrug),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          TextButton.icon(
            onPressed: onShowPresets,
            icon: const Icon(Icons.auto_awesome_outlined, size: AppTokens.iconSizeInline),
            label: Text(l10n.setupMedLoadPreset),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          Row(
            children: [
              TextButton(
                onPressed: saving ? null : onBack,
                child: Text(l10n.setupBack),
              ),
              const Spacer(),
              SizedBox(
                width: 110,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: saving ? null : onFinish,
                      child: Text(l10n.setupNext),
                    ),
                    if (saving)
                      IgnorePointer(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            // v0.22 round 36: 去掉 const (fgOnPrimary 是函数调用)
                            color: AppTokens.fgOnPrimary(context),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 单个药物卡片（从 setup_page._buildMedCard 提取）
class MedCard extends StatelessWidget {
  final int index;
  final MedDraft med;
  final VoidCallback onRemove;

  const MedCard({
    super.key,
    required this.index,
    required this.med,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  l10n.setupMedDrugNumber(index + 1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppTokens.fontSizeBody,
                  ),
                ),
                const Spacer(),
                // v0.26 round 57 (emil B-11): 走 PressFeedbackIconButton 集中器
                PressFeedbackIconButton(
                  icon: Icons.delete_outline,
                  tooltip: l10n.setupMedDeleteDrug,
                  onPressed: onRemove,
                  color: AppTokens.errorColor(context),
                ),
              ],
            ),
            TextField(
              controller: med.nameController,
              decoration: InputDecoration(
                labelText: l10n.commonMedName,
                hintText: l10n.setupMedNameHint,
              ),
            ),
            const SizedBox(height: AppTokens.spacingMd),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: med.dosageController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.setupMedDosage,
                      hintText: '40',
                    ),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: med.dosageUnit,
                    decoration: InputDecoration(labelText: l10n.setupMedUnit),
                    items: [
                      // v0.22 round 30 (sp-zh P2-5): 'mg' 是国际单位不翻译,
                      // '片' 走 l10n commonDoseUnit (zh: "片" / en: "tablet")
                      // v0.23 (P0-11): 'mg' / '片' 改 DosageUnit enum.id, 去 const
                      //   (Dart const 表达式不支持 enum instance property access)
                      DropdownMenuItem<String>(
                          value: DosageUnit.mg.id,
                          child: const Text('mg'),
                      ),
                      DropdownMenuItem<String>(
                        value: DosageUnit.tablet.id,
                        child: Text(l10n.commonDoseUnit),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        med.dosageUnit = v;
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingMd),
            Text(
              l10n.setupMedTimeHint,
              style: TextStyle(
                fontSize: AppTokens.fontSizeLabel,
                color: AppTokens.textSecondaryColor(context),
              ),
            ),
            const SizedBox(height: AppTokens.spacingXs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int tIdx = 0; tIdx < med.times.length; tIdx++)
                  PressFeedback(
                    child: InputChip(
                      label: Text(_formatTime(med.times[tIdx])),
                      onDeleted: () => med.times.removeAt(tIdx),
                    ),
                  ),
                PressFeedback(
                  child: ActionChip(
                    avatar: const Icon(Icons.add, size: AppTokens.iconSizeInline),
                    label: Text(l10n.setupMedAddTime),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: med.times.isNotEmpty
                            ? med.times.last
                            : const TimeOfDay(hour: 8, minute: 0),
                      );
                      if (picked != null && context.mounted) {
                        med.times.add(picked);
                        med.times.sort(
                          (a, b) => (a.hour * 60 + a.minute)
                              .compareTo(b.hour * 60 + b.minute),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            if (med.times.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.spacingXxs),
                child: Text(
                  l10n.setupMedTimeOptional,
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHintColor(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
