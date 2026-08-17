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
//
// v0.32 R112 (AR-20 god class 批2b): 573L → 拆 3 职责 (职责数 3 → 1):
// - 表单 UI (3 步) → widgets/add_medication_step1/2/3_form.dart
//   (+ add_medication_form_shared.dart 共享标题/剂型映射)
// - 校验 → domain/logic/add_medication_form_validator.dart (R109)
// - 提交流程 → add_medication_submit_flow.dart (本目录)
// 本页只留: form state + 步骤编排 + UX (snackbar / pop / _saving)。
//
// v1.1.0 R116 round 4: 247L → 进一步拆 2 个纯展示子 widget
//   (进度条 + 底部按钮 footer) 到 widgets/ 目录, page shell 只剩
//   form state + 步骤编排 + save handler。模式跟 R116 round 1-3
//   (mood_trend 3 chart / assessment_reminder_sheet /
//   medication_slot_entry_row) 一致。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/features/medication/domain/entities/medication_form.dart';
import 'package:chroniccare/domain/logic/add_medication_form_validator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/add_medication_submit_flow.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/add_medication_step1_form.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/add_medication_step2_form.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/add_medication_step3_form.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/add_medication_step_footer.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/add_medication_step_indicator.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

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
      // v0.32 R112 (AR-20 批2b): repo.add + 双 reschedule 抽
      // AddMedicationSubmitFlow (B1-8 watchAll().first 语义保留, 见该文件)
      await AddMedicationSubmitFlow.run(
        repo: repo,
        delegate: notif.delegate,
        draft: draft,
      );

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
          // R116 round 4: 进度指示器抽 AddMedicationStepIndicator 公开 widget
          AddMedicationStepIndicator(currentStep: _currentStep),

          // R104 fix: 条件渲染替代 IndexedStack，setState 立即重建当前步骤
          // R112 AR-20 批2b: 3 步表单抽 widgets/add_medication_form.dart
          Expanded(
            child: _currentStep == 0
                ? AddMedicationStep1Form(
                    nameController: _nameController,
                    form: _form,
                    onFormChanged: (f) => setState(() => _form = f),
                  )
                : _currentStep == 1
                    ? AddMedicationStep2Form(
                        dosageController: _dosageController,
                        dosageUnit: _dosageUnit,
                        onDosageUnitChanged: (u) =>
                            setState(() => _dosageUnit = u),
                        times: _times,
                        onTimeChanged: (i, t) => setState(() => _times[i] = t),
                        onTimeDeleted: (i) =>
                            setState(() => _times.removeAt(i)),
                        onTimeAdded: (t) => setState(() => _times.add(t)),
                      )
                    : AddMedicationStep3Form(
                        name: _nameController.text,
                        form: _form,
                        dosageText: _dosageController.text,
                        dosageUnit: _dosageUnit,
                        times: _times,
                        colorIndex: _colorIndex,
                        onColorChanged: (i) => setState(() => _colorIndex = i),
                      ),
          ),

          // R116 round 4: 底部按钮抽 AddMedicationStepFooter 公开 widget
          AddMedicationStepFooter(
            currentStep: _currentStep,
            totalSteps: 3,
            saving: _saving,
            prevLabel: l10n.medAddPrev,
            nextLabel: l10n.medAddNext,
            saveLabel: l10n.medAddSave,
            onPrev: _prevStep,
            onNext: _nextStep,
          ),
        ],
      ),
    );
  }
}

// v0.32 R109 (god class 拆 round 4): 删 `_ConfirmRow` private class,
// 移到 `widgets/medication_confirm_row.dart` 公开 `MedicationConfirmRow`,
// caller 改 import 公开类. emil DRY 跟 R31 R108 子 widget 抽模式一致.
//
// v0.32 R112 (AR-20 god class 批2b): 删 `_buildStep1/2/3` 3 个 inline
// builder + `_formLabel`/`_formIcon` 2 helper, 移到
// `widgets/add_medication_step1/2/3_form.dart` (3 公开 form widget) +
// `widgets/add_medication_form_shared.dart` (MedicationStepTitle /
// medicationFormLabel / medicationFormIcon);
// `_save` 的 repo.add + 双 reschedule 抽 `add_medication_submit_flow.dart`
// 公开 `AddMedicationSubmitFlow`. page 职责 3 → 1 (编排).
//
// v1.1.0 R116 round 4: 247L → 进一步拆 2 个纯展示子 widget:
// - 进度条 (line 155-176 inline) → `widgets/add_medication_step_indicator.dart`
//   公开 `AddMedicationStepIndicator` (currentStep 值注入, 0 callback)
// - 底部按钮 (line 211-241 inline) → `widgets/add_medication_step_footer.dart`
//   公开 `AddMedicationStepFooter` (currentStep + saving + 3 label + 2 callback)
// page shell 247L → ~190L (-23%)。纯 UI 抽出后 page 真正只剩 form state
// + 步骤编排 + save handler 三件事, 易独立测。
