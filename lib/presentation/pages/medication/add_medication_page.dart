// v0.30 R101: 添加药物向导 — 3步 wizard 参照 Apple Health
//
// Step 1: 药名 + 剂型
// Step 2: 剂量 + 频率 + 时间
// Step 3: 确认 + 颜色选择
//
// v0.31 round 11a (Apple Health redesign · Phase 3 Task 3.3):
// 改 AppleListSection 风格 (spec §5.3 medication):
// - Step 1 "基本信息" AppleListSection 包装 (药名 + 剂型)
// - Step 2 "用药时间" AppleListSection 包装 (剂量 + 时间)
// - 进度条 1/3 走 iOS 风格 hairline (高 4pt → 3pt)
// - 底部按钮改 PrimaryButton (default + secondary)
// - 间距统一 16 (spacingMd)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_draft.dart';
import 'package:chroniccare/domain/entities/medication_form.dart';
import 'package:chroniccare/domain/logic/add_medication_form_validator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_confirm_row.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_pill_icon.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

class AddMedicationPage extends ConsumerStatefulWidget {
  const AddMedicationPage({super.key});

  @override
  ConsumerState<AddMedicationPage> createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends ConsumerState<AddMedicationPage> {
  int _currentStep = 0;
  bool _saving = false;

  // Step 1
  final _nameController = TextEditingController();
  MedicationForm _form = MedicationForm.tablet;

  // Step 2
  final _dosageController = TextEditingController(text: '50');
  DosageUnit _dosageUnit = DosageUnit.mg;
  final List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];

  // Step 3
  int _colorIndex = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    // v0.32 R109: 透传 validator 静态方法
    if (_currentStep == 0 &&
        !AddMedicationFormValidator.canAdvanceFromStep1(_nameController.text)) {
      final l10n = AppLocalizations.of(context);
      AppSnackBar.showInfo(context, l10n.medicationNameRequired);
      return;
    }
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _save();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final repo = ref.read(medicationRepositoryProvider);
    final notif = ref.read(notificationServiceProvider);
    // v0.32 R109: 透传 validator 静态方法, draft 构造集中到 1 个调用
    final times =
        _times.map((t) => HourMinute(hour: t.hour, minute: t.minute)).toList();
    final draft = AddMedicationFormValidator.toDraft(
      name: _nameController.text,
      dosageText: _dosageController.text,
      dosageUnit: _dosageUnit,
      times: times,
      form: _form,
      colorIndex: _colorIndex,
    );

    try {
      await repo.add(draft);
      // 新增药物后重排提醒 (edit_medication_dialog 同款模式), 否则新药无提醒直到重启
      final meds = await ref.refresh(medicationsProvider.future);
      await notif.delegate.rescheduleMedicationReminders(meds);
      await notif.delegate.rescheduleRefillReminders(meds);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        AppSnackBar.showInfo(context, l10n.medicationAdded(draft.name));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).medAddSave,
          error: e,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PageScaffold(
      title: l10n.medAddTitle,
      // v0.31.1 round 8 (emil P0-C + R108 P1-001 漏修): 改用
      // PressFeedbackIconButton 集中器。原 IconButton 无 tooltip,
      // 集中器要求必填, 用 R75 wizard 步骤 ARB key medAddPrev
      // (en="Back" / zh="上一步") 语义匹配 wizard 步骤返回。
      leading: PressFeedbackIconButton(
        icon: Icons.arrow_back_rounded,
        tooltip: l10n.medAddPrev,
        onPressed: _prevStep,
      ),
      child: Column(
        children: [
          // 进度指示器 (iOS hairline 风格, 3pt)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
            child: Row(
              children: List.generate(3, (i) {
                final active = i <= _currentStep;
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: active
                          ? AppTokens.primaryColor(context)
                          : AppTokens.dividerColor(context),
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                );
              }),
            ),
          ),

          // R104 fix: 条件渲染替代 IndexedStack，setState 立即重建当前步骤
          Expanded(
            child: _currentStep == 0
                ? _buildStep1(l10n)
                : _currentStep == 1
                    ? _buildStep2(l10n)
                    : _buildStep3(l10n),
          ),

          // 底部按钮 — v0.31 R11a: 改 PrimaryButton 3 variant
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: PrimaryButton(
                        variant: PrimaryButtonVariant.secondary,
                        isFullWidth: true,
                        onPressed: _prevStep,
                        child: Text(l10n.medAddPrev),
                      ),
                    ),
                  if (_currentStep > 0)
                    const SizedBox(width: AppTokens.spacingSm),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      isFullWidth: true,
                      onPressed: _saving ? null : _nextStep,
                      child: Text(
                        _currentStep < 2 ? l10n.medAddNext : l10n.medAddSave,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // Step 1: 药名 + 剂型 (AppleListSection "基本信息")
  // ═══════════════════════════════════════════════════
  Widget _buildStep1(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingMd),
      children: [
        // 大标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
          child: Text(
            l10n.medAddStep1Title,
            style: AppTokens.textStyleTitle(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppTokens.spacingMd),

        // "基本信息" AppleListSection
        AppleListSection(
          title: l10n.medAddBasicInfo,
          margin: const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
          children: [
            // 药名
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingXxs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.medAddNameLabel,
                    style: AppTokens.textStyleCaptionHint(context),
                  ),
                  const SizedBox(height: AppTokens.spacingXxs),
                  TextField(
                    controller: _nameController,
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
                      final selected = _form == f;
                      return ChoiceChip(
                        label: Text(_formLabel(f, l10n)),
                        selected: selected,
                        onSelected: (_) => setState(() => _form = f),
                        avatar: Icon(_formIcon(f), size: 18),
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

  // ═══════════════════════════════════════════════════
  // Step 2: 剂量 + 频率 + 时间 (AppleListSection "用药时间")
  // ═══════════════════════════════════════════════════
  Widget _buildStep2(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingMd),
      children: [
        // 大标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
          child: Text(
            l10n.medAddStep2Title,
            style: AppTokens.textStyleTitle(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppTokens.spacingMd),

        // "用药时间" AppleListSection
        AppleListSection(
          title: l10n.medAddTime,
          margin: const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
          children: [
            // 剂量 + 单位
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingXxs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.medAddDosageLabel,
                    style: AppTokens.textStyleCaptionHint(context),
                  ),
                  const SizedBox(height: AppTokens.spacingXxs),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _dosageController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppTokens.spacingSm),
                      Expanded(
                        child: DropdownButtonFormField<DosageUnit>(
                          initialValue: _dosageUnit,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          items: DosageUnit.values
                              .map(
                                (u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(u.id),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _dosageUnit = v);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 时间列表
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.spacingXs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.medAddTimeLabel,
                    style: AppTokens.textStyleCaptionHint(context),
                  ),
                  const SizedBox(height: AppTokens.spacingXs),
                  Wrap(
                    spacing: AppTokens.spacingSm,
                    runSpacing: AppTokens.spacingSm,
                    children: [
                      ..._times.asMap().entries.map((e) {
                        final i = e.key;
                        final t = e.value;
                        return InputChip(
                          avatar: const Icon(Icons.access_time, size: 18),
                          label: Text(
                            HourMinute(hour: t.hour, minute: t.minute).toTimeString(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: t,
                            );
                            if (picked != null && mounted) {
                              setState(() => _times[i] = picked);
                            }
                          },
                          onDeleted: _times.length > 1
                              ? () => setState(() => _times.removeAt(i))
                              : null,
                        );
                      }),
                      // 添加时间按钮
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 18),
                        label: Text(l10n.medAddTimeAdd),
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: const TimeOfDay(hour: 20, minute: 0),
                          );
                          if (picked != null && mounted) {
                            setState(() => _times.add(picked));
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // Step 3: 确认 + 颜色选择 (AppleListSection "颜色" + "确认信息")
  // ═══════════════════════════════════════════════════
  Widget _buildStep3(AppLocalizations l10n) {
    final dosage = _dosageController.text;
    final timesStr = _times
        .map((t) => HourMinute(hour: t.hour, minute: t.minute).toTimeString())
        .join(', ');

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingMd),
      children: [
        // 大标题
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
          child: Text(
            l10n.medAddStep3Title,
            style: AppTokens.textStyleTitle(context).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppTokens.spacingMd),

        // "颜色" AppleListSection
        AppleListSection(
          title: l10n.medAddColor,
          margin: const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
          children: [
            Text(
              l10n.medAddColorLabel,
              style: AppTokens.textStyleCaptionHint(context),
            ),
            const SizedBox(height: AppTokens.spacingXs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(kMedPillColors.length, (i) {
                final selected = _colorIndex == i;
                return PressFeedback(
                  onTap: () => setState(() => _colorIndex = i),
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
                        initial: _nameController.text.isNotEmpty
                            ? _nameController.text
                            : null,
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
          margin: const EdgeInsets.symmetric(horizontal: AppTokens.pageMarginH),
          children: [
            MedicationConfirmRow(
              label: l10n.medAddConfirmName,
              value: _nameController.text,
            ),
            MedicationConfirmRow(
              label: l10n.medAddConfirmForm,
              value: _formLabel(_form, l10n),
            ),
            MedicationConfirmRow(
              label: l10n.medAddConfirmDosage,
              value: Formatters.dosage(
                double.tryParse(dosage) ?? 0,
                _dosageUnit,
              ),
            ),
            MedicationConfirmRow(label: l10n.medAddConfirmTime, value: timesStr),
          ],
        ),
      ],
    );
  }

  String _formLabel(MedicationForm f, AppLocalizations l10n) {
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

  IconData _formIcon(MedicationForm f) {
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
}

// v0.32 R109 (god class 拆 round 4): 删 `_ConfirmRow` private class,
// 移到 `widgets/medication_confirm_row.dart` 公开 `MedicationConfirmRow`,
// caller 改 import 公开类. emil DRY 跟 R31 R108 子 widget 抽模式一致.
