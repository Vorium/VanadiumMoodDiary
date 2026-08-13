// setup_step_medication.dart — 首次设置 Step 2: 药物列表
//
// 从 setup_page.dart 拆分，v0.19 (Q2)
//
// v0.31 round 10 (Apple Health redesign · Phase 3 Task 3.2):
// 改 Apple 引导流程 (spec §5.2):
// - 顶部 SetupStepHeader 大标题 28pt + 副标题 15pt
// - medication list 改 AppleListSection 风格
// - "+ 添加药物" 改 PrimaryButton secondary (FilledButton.tonal)
// - 底部 PrimaryButton full width
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/info_banner.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

/// Step 2: 药物列表
///
/// 用户添加/编辑常吃药物 + 时间。
/// 药物列表(_meds)由父级管理。
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
          // v0.31 round 10: 顶部 SetupStepHeader (28pt 大标题 + 15pt 副标题)
          SetupStepHeader(
            title: l10n.setupMedWhatDoYouTake,
            subtitle: l10n.setupMedMultiDrugHint,
          ),
          if (meds.isEmpty)
            // v0.27 round 67 (C-2): 走 InfoBanner 集中器 (muted tone)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.pageMarginH,
              ),
              child: InfoBanner(
                icon: Icons.info_outline,
                text: l10n.setupMedEmptyHint,
                tone: InfoBannerTone.muted,
                bordered: true,
              ),
            )
          else
            // v0.31 round 10: 药物列表改 AppleListSection 风格
            // 每个 MedCard 作为单独 cell, hairline 分隔
            AppleListSection(
              margin: EdgeInsets.zero,
              children: [
                for (int i = 0; i < meds.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: 0,
                      thickness: 0.5,
                    ),
                  MedCard(
                    index: i,
                    med: meds[i],
                    onRemove: () => onRemoveMed(i),
                  ),
                ],
              ],
            ),
          const SizedBox(height: AppTokens.spacingMd),
          // v0.31 round 10: "+ 添加药物" 改 PrimaryButton secondary (FilledButton.tonal)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: PrimaryButton(
              variant: PrimaryButtonVariant.secondary,
              isFullWidth: true,
              leadingIcon: const Icon(Icons.add),
              onPressed: onAddMed,
              child: Text(l10n.setupMedAddDrug),
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          // v0.31 round 10: "Load preset" 改 PrimaryButton tertiary (TextButton)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: PrimaryButton(
              variant: PrimaryButtonVariant.tertiary,
              isFullWidth: true,
              leadingIcon: const Icon(
                Icons.auto_awesome_outlined,
                size: AppTokens.iconSizeInline,
              ),
              onPressed: onShowPresets,
              child: Text(l10n.setupMedLoadPreset),
            ),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          // v0.31 round 10: 底部 PrimaryButton full width
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            // v0.30 round 95 (sub-spec 2 task 10): PrimaryButton + Stack
            // hacky 改 PressFeedback + LoadingSpinner (emil honest abstraction).
            // saving 态 LoadingSpinner 叠加在 button 上。
            child: PressFeedback(
              onTap: saving ? null : onFinish,
              child: PrimaryButton(
                isFullWidth: true,
                onPressed: null, // PressFeedback 接管 tap
                child: saving
                    ? LoadingSpinner(
                        size: AppTokens.iconSizeInline,
                        color: AppTokens.fgOnPrimary(context),
                      )
                    : Text(l10n.setupNext),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          // v0.31 round 10: "上一步" 改 PrimaryButton tertiary (TextButton) — full width
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: PrimaryButton(
              variant: PrimaryButtonVariant.tertiary,
              isFullWidth: true,
              onPressed: saving ? null : onBack,
              child: Text(l10n.setupBack),
            ),
          ),
          const SizedBox(height: AppTokens.spacingLg),
        ],
      ),
    );
  }
}

/// 单个药物卡片(从 setup_page._buildMedCard 提取)
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
    return Padding(
      // v0.31 round 10: AppleListSection 自带 cell padding (16/12), MedCard
      // 内部 widget 跟 cell padding 一致, 留同样的内边距
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMd,
        vertical: AppTokens.spacingSm,
      ),
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
            // v0.27 R72 (emil E-P2-4): 走 AppTokens.spacingXs 集中器替代 inline 8
            spacing: AppTokens.spacingXs,
            runSpacing: AppTokens.spacingXs,
            children: [
              for (int tIdx = 0; tIdx < med.times.length; tIdx++)
                PressFeedback(
                  child: InputChip(
                    label: Text(_formatTime(med.times[tIdx])),
                    // v0.32 round 8 (R112-09 fix): 走 med.removeTimeAt 触发
                    // 变更通知 (修前裸 removeAt 无通知 → 删除没反应假 bug)
                    onDeleted: () => med.removeTimeAt(tIdx),
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
                      // v0.32 round 8 (R112-09 fix): 走 med.addTime (自动
                      // 排序 + 变更通知, 修前裸 add + sort 无通知 → 添加
                      // 没反应假 bug)
                      med.addTime(picked);
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
                style: AppTokens.textStyleCaptionHint(context),
              ),
            ),
        ],
      ),
    );
  }

  static String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
