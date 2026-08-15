// setup_page_state.dart — 首次设置引导页 state (R95 sub-spec 6 task 6c 拆解)
//
// v0.32 R112 (AR-20 批2a): god class 拆 — 503L → 编排入口 (~230L), 3 职责
// 各拆 1 文件 (每文件 ≤2 职责):
// - 5 bool consent 状态 → setup_consent_state.dart (SetupConsentState)
// - 提交序列 + 收集 → setup_submit_flow.dart
// - 4 步 wizard 壳 (PopScope/PageScaffold/进度条/切换动画) →
//   widgets/setup_wizard_frame.dart
// - template → 草稿构造 → setup_widgets.dart (MedDraft.fromTemplate)
// 本文件只留: 步骤坐标 (_step) + controller 生命周期 + _buildStep 拼装 +
// _finishSetup 编排入口 (saving 标志 + 错误 snackbar + swallowError)。
//
// 1.1.0 round 4: 联系人同意弹窗循环 (setup_contact_consent_flow.dart) 与
// 联系人 controllers 整摘 (失联通信业务暂停定版)。
//
// 职责:
// 1. [SetupPageState] 4 步 wizard 状态 + 业务方法 (跟 _HomePageState 改 public
//    HomePageState 模式一致, R95 sub-spec 4 task 5)
//
// 状态分组:
// - Step 0 consent: SetupConsentState 5 个 bool 勾选
// - Step 1 welcome: nameController
// - Step 2 medication: _meds (MedDraft list) + _saving
// - Step 3 done: 终态, 触发 GoRouter /home
//
// 跟 R95 sub-spec 4 task 5 模式一致:
// - _SetupPageState 私有 → public SetupPageState (避免循环 import)
// - 主壳 setup_page.dart 只 ConsumerStatefulWidget 入口
// - 老 caller (e.g. router) `import 'package:chroniccare/presentation/pages/setup/setup_page.dart'`
//   拿 SetupPage 类型 + createState() 返回 SetupPageState 0 改动
import 'package:chroniccare/core/data/services/preset_medication_templates.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/domain/logic/setup_welcome_form_validator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_consent_state.dart';
import 'package:chroniccare/presentation/pages/setup/setup_legal_dialog.dart';
import 'package:chroniccare/presentation/pages/setup/setup_page.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_consent.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_welcome.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_medication.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_done.dart';
import 'package:chroniccare/presentation/pages/setup/setup_submit_flow.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/pages/setup/widgets/preset_templates_sheet.dart';
import 'package:chroniccare/presentation/pages/setup/widgets/setup_wizard_frame.dart';
import 'package:chroniccare/presentation/services/preset_med_l10n.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 首次设置引导页 state (4 步 wizard coordinator)
class SetupPageState extends ConsumerState<SetupPage> {
  int _step = 0;

  // Step 0: consent — 5 bool 勾选 (userAgreement / privacyPolicy /
  // sensitiveData / ageAttestation / medicalDisclaimer)
  final SetupConsentState _consent = SetupConsentState();

  // Step 1: welcome
  final _nameController = TextEditingController();

  // Step 2: medication
  final List<MedDraft> _meds = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onTextChanged);
    for (final m in _meds) {
      m.attachListener(_onTextChanged);
    }
  }

  void _onTextChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_onTextChanged);
    _nameController.dispose();
    for (final m in _meds) {
      m.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // v0.32 R112 (AR-20 批2a): 壳抽 SetupWizardFrame
    return SetupWizardFrame(
      step: _step,
      child: _buildStep(),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return SetupStepConsent(
          consentUserAgreement: _consent.userAgreement,
          consentPrivacyPolicy: _consent.privacyPolicy,
          consentSensitiveData: _consent.sensitiveData,
          consentAgeAttestation: _consent.ageAttestation,
          consentMedicalDisclaimer: _consent.medicalDisclaimer,
          onConsentUserAgreementChanged: (v) =>
              setState(() => _consent.userAgreement = v),
          onConsentPrivacyPolicyChanged: (v) =>
              setState(() => _consent.privacyPolicy = v),
          onConsentSensitiveDataChanged: (v) =>
              setState(() => _consent.sensitiveData = v),
          onConsentAgeAttestationChanged: (v) =>
              setState(() => _consent.ageAttestation = v),
          onConsentMedicalDisclaimerChanged: (v) =>
              setState(() => _consent.medicalDisclaimer = v),
          onViewUserAgreement: () =>
              showLegalDocument(context, 'user_agreement'),
          onViewPrivacyPolicy: () =>
              showLegalDocument(context, 'privacy_policy'),
          onViewSensitiveData: () =>
              showLegalDocument(context, 'sensitive_data_consent'),
          onViewMedicalDisclaimer: () =>
              showLegalDocument(context, 'medical_disclaimer'),
          // R104: 一键全部同意
          onAgreeAll: () => setState(_consent.agreeAll),
          onViewAll: () => showLegalDocument(context, 'user_agreement'),
          onContinue: () => setState(() => _step = 1),
        );
      case 1:
        return SetupStepWelcome(
          nameController: _nameController,
          validationError: _validateWelcomeForm(),
          onBack: () => setState(() => _step = 0),
          onContinue: () => setState(() => _step = 2),
        );
      case 2:
        return SetupStepMedication(
          meds: _meds,
          saving: _saving,
          onAddMed: () {
            setState(() {
              final m = MedDraft();
              m.attachListener(_onTextChanged);
              _meds.add(m);
            });
          },
          onShowPresets: _showPresetTemplatesSheet,
          onRemoveMed: (i) {
            setState(() {
              _meds[i].dispose();
              _meds.removeAt(i);
            });
          },
          onBack: () => setState(() => _step = 1),
          onFinish: _finishSetup,
        );
      case 3:
        return SetupStepDone(
          onBack: () => setState(() => _step = 2),
        );
      default:
        return SetupStepWelcome(
          nameController: _nameController,
          onBack: () {},
          onContinue: () {},
        );
    }
  }

  String? _validateWelcomeForm() {
    // v0.32 R109: 透传 SetupWelcomeFormValidator 静态方法
    //   行为跟原 30L 实现 100% 一致 (name 必填)
    //   错误码透传给 caller, caller 决定怎么映射到 l10n
    final errorCode = SetupWelcomeFormValidator.validateWelcomeForm(
      name: _nameController.text,
    );
    if (errorCode == null) return null;
    // 把错误码映射回 l10n 文案, 跟原 behavior 1:1
    final l10n = AppLocalizations.of(context);
    switch (errorCode) {
      case 'setup_validation_name_required':
        return l10n.setupValidationNameRequired;
      default:
        return null;
    }
  }

  Future<void> _showPresetTemplatesSheet() async {
    // v0.32 R109: 抽 modal content 到 PresetTemplatesSheetContent 公开 widget
    //   (原 70L modal builder 改 1 个调用)
    final result =
        await showModalBottomSheet<TemplateApplyResult<MedicationTemplate>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => PresetTemplatesSheetContent(
        hasExistingMeds: _meds.isNotEmpty,
      ),
    );
    if (result == null) return;
    if (!mounted) return;

    setState(() {
      for (final m in _meds) {
        m.dispose();
      }
      _meds.clear();

      for (final d in result.template.meds) {
        // v0.32 R112 (AR-20 批2a): 构造逻辑抽 MedDraft.fromTemplate
        final m = MedDraft.fromTemplate(d, AppLocalizations.of(context));
        m.attachListener(_onTextChanged);
        _meds.add(m);
      }
    });

    if (!mounted) return;
    // v0.22 round 29 (emil-39): 走 AppSnackBar.info 集中器
    // v0.28 round 65 (spzh P2-G): template.name 走 i18n
    AppSnackBar.showInfo(
      context,
      AppLocalizations.of(context).setupPresetLoaded(
        result.template.nameL10n(AppLocalizations.of(context)),
        result.template.meds.length,
      ),
    );
  }

  Future<void> _finishSetup() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final validationError = _validateWelcomeForm();
      if (validationError != null) return;

      final userName = _nameController.text.trim();
      final medicationList = SetupSubmitFlow.collectMedications(_meds);

      // v0.32 R112 (AR-20 批2a): 提交序列抽 SetupSubmitFlow.run, 错误
      // 原样上抛 → 本 catch 管 error snackbar
      await SetupSubmitFlow.run(
        ref: ref,
        context: context,
        userName: userName,
        medicationList: medicationList,
      );
      if (!mounted) return;

      setState(() => _step = 3);
    } catch (e, st) {
      if (mounted) {
        // v0.22 round 30 (sp-zh P1-16): 走 AppSnackBar.error 集中器
        // v0.27 round 59 修正: 用 showError 集中器 + action 修正为"完成设置"
        AppSnackBar.showError(
          context,
          // v0.27 round 62 (P1-7 修复): 改用 l10n key 而非 hardcode 中文,
          // en 模式用户也能看到 "Finish setup"。
          action: AppLocalizations.of(context).snackbarActionFinishSetup,
          error: e,
        );
      }
      swallowError(
        where: 'SetupPage._finishSetup',
        error: e,
        stack: st,
      );
    } finally {
      // v0.32 round 8 (R112-04 fix): 修前 unmounted State 上调 setState
      // 抛 — unmounted 后直接改字段 (_saving 复位不用走 UI)
      if (mounted) {
        setState(() => _saving = false);
      } else {
        _saving = false;
      }
    }
  }
}
