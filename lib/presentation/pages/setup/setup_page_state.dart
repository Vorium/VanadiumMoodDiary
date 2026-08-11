// setup_page_state.dart — 首次设置引导页 state (R95 sub-spec 6 task 6c 拆解)
//
// 职责:
// 1. [SetupPageState] 4 步 wizard 状态 + 业务方法 (跟 _HomePageState 改 public
//    HomePageState 模式一致, R95 sub-spec 4 task 5)
//
// 状态分组:
// - Step 0 consent: 4 个 bool 勾选 (userAgreement / privacyPolicy /
//   sensitiveData / ageAttestation)
// - Step 1 welcome: nameController + contactName/PhoneControllers (动态数组)
// - Step 2 medication: _meds (MedDraft list) + _saving
// - Step 3 done: 终态, 触发 GoRouter /home
//
// 业务方法 (8):
// - _onTextChanged: 7 controller listener
// - _buildStep: 4 step switch + SetupStepXxx 拼装
// - _validateWelcomeForm: 名字 + 手机号格式 + 重复校验
// - _showPresetTemplatesSheet: 模态弹窗选 template
// - _finishSetup: PIPL §13 同意循环 + DB save + notification 重排
//
// 跟 R95 sub-spec 4 task 5 模式一致:
// - _SetupPageState 私有 → public SetupPageState (避免循环 import)
// - 主壳 setup_page.dart 只 ConsumerStatefulWidget 入口
// - 老 caller (e.g. router) `import 'package:chroniccare/presentation/pages/setup/setup_page.dart'`
//   拿 SetupPage 类型 + createState() 返回 SetupPageState 0 改动

import 'package:chroniccare/core/data/services/preset_medication_templates.dart';
import 'package:chroniccare/core/data/utils/phone_validator.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/consent_artifact.dart'
    show ConsentArtifact, ConsentKind;
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/logic/setup_welcome_form_validator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_legal_dialog.dart';
import 'package:chroniccare/presentation/pages/setup/setup_page.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_consent.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_welcome.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_medication.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_done.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/pages/setup/widgets/preset_templates_sheet.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';
import 'package:chroniccare/presentation/widgets/consent_dialog.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 首次设置引导页 state (4 步 wizard coordinator)
class SetupPageState extends ConsumerState<SetupPage> {
  int _step = 0;

  // Step 0: consent
  bool _consentUserAgreement = false;
  bool _consentPrivacyPolicy = false;
  bool _consentSensitiveData = false;
  // v0.27 R83: 第 4 个勾选 — 年龄严正声明
  bool _consentAgeAttestation = false;
  // R103 (P0-9): 第 5 个勾选 — 医学免责声明
  bool _consentMedicalDisclaimer = false;

  // Step 1: welcome
  final _nameController = TextEditingController();
  final List<TextEditingController> _contactNameControllers = [
    TextEditingController(),
  ];
  final List<TextEditingController> _contactPhoneControllers = [
    TextEditingController(),
  ];

  // Step 2: medication
  final List<MedDraft> _meds = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onTextChanged);
    for (final c in _contactNameControllers) {
      c.addListener(_onTextChanged);
    }
    for (final c in _contactPhoneControllers) {
      c.addListener(_onTextChanged);
    }
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
    for (final c in _contactNameControllers) {
      c.removeListener(_onTextChanged);
      c.dispose();
    }
    for (final c in _contactPhoneControllers) {
      c.removeListener(_onTextChanged);
      c.dispose();
    }
    for (final m in _meds) {
      m.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step != 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // v0.22 round 29 (emil-38): 走 AppSnackBar.info 集中器
        AppSnackBar.showInfo(
          context,
          AppLocalizations.of(context).setupConsentRequired,
        );
      },
      child: PageScaffold(
        title: AppLocalizations.of(context).setupStep(_step + 1, 4),
        // v0.31 round 10 (Apple Health redesign · Phase 3 Task 3.2):
        // 顶部 4 段 hairline 进度条, 走 currentStep 0-3 控制高亮
        // (R10 spec §5.2 "顶部: 进度条 1/4 (小 hairline)")
        appBarBottom: PreferredSize(
          preferredSize: const Size.fromHeight(12), // 4+3+4 (top padding + bar + bottom padding)
          child: SetupProgressBar(currentStep: _step, totalSteps: 4),
        ),
        // v0.23 round 40 (emil F5/F7 fix): 改用 PageTransitionSwitcher 集中器
        // 之前 inline AnimatedSwitcher + 自定义 transitionBuilder (40+ 行)
        // 抽到 PageTransitionSwitcher.transitionBuilder 后 setup 这里只 1 个 widget
        child: PageTransitionSwitcher(
          switchKey: _step,
          duration: Motion.duration(context, MotionScheme.standard.duration),
          transitionBuilder: (child, anim) {
            return FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_step),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return SetupStepConsent(
          consentUserAgreement: _consentUserAgreement,
          consentPrivacyPolicy: _consentPrivacyPolicy,
          consentSensitiveData: _consentSensitiveData,
          consentAgeAttestation: _consentAgeAttestation,
          consentMedicalDisclaimer: _consentMedicalDisclaimer,
          onConsentUserAgreementChanged: (v) =>
              setState(() => _consentUserAgreement = v),
          onConsentPrivacyPolicyChanged: (v) =>
              setState(() => _consentPrivacyPolicy = v),
          onConsentSensitiveDataChanged: (v) =>
              setState(() => _consentSensitiveData = v),
          onConsentAgeAttestationChanged: (v) =>
              setState(() => _consentAgeAttestation = v),
          onConsentMedicalDisclaimerChanged: (v) =>
              setState(() => _consentMedicalDisclaimer = v),
          onViewUserAgreement: () =>
              showLegalDocument(context, 'user_agreement'),
          onViewPrivacyPolicy: () =>
              showLegalDocument(context, 'privacy_policy'),
          onViewSensitiveData: () =>
              showLegalDocument(context, 'sensitive_data_consent'),
          onViewMedicalDisclaimer: () =>
              showLegalDocument(context, 'medical_disclaimer'),
          // R104: 一键全部同意
          onAgreeAll: () => setState(() {
            _consentUserAgreement = true;
            _consentPrivacyPolicy = true;
            _consentSensitiveData = true;
            _consentAgeAttestation = true;
            _consentMedicalDisclaimer = true;
          }),
          onViewAll: () => showLegalDocument(context, 'user_agreement'),
          onContinue: () => setState(() => _step = 1),
        );
      case 1:
        return SetupStepWelcome(
          nameController: _nameController,
          contactNameControllers: _contactNameControllers,
          contactPhoneControllers: _contactPhoneControllers,
          validationError: _validateWelcomeForm(),
          onAddContact: () {
            setState(() {
              final nameCtrl = TextEditingController();
              final phoneCtrl = TextEditingController();
              nameCtrl.addListener(_onTextChanged);
              phoneCtrl.addListener(_onTextChanged);
              _contactNameControllers.add(nameCtrl);
              _contactPhoneControllers.add(phoneCtrl);
            });
          },
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
          contactNameControllers: _contactNameControllers,
          contactPhoneControllers: _contactPhoneControllers,
          onAddContact: () {},
          onBack: () {},
          onContinue: () {},
        );
    }
  }

  String? _validateWelcomeForm() {
    // v0.32 R109: 透传 SetupWelcomeFormValidator 静态方法
    //   行为跟原 30L 实现 100% 一致 (name 必填 + phone 格式 + phone 重复)
    //   错误码透传给 caller, caller 决定怎么映射到 l10n
    final errorCode = SetupWelcomeFormValidator.validateWelcomeForm(
      name: _nameController.text,
      phones: _contactPhoneControllers.map((c) => c.text).toList(),
    );
    if (errorCode == null) return null;
    // 把错误码映射回 l10n 文案, 跟原 behavior 1:1
    final l10n = AppLocalizations.of(context);
    switch (errorCode) {
      case 'setup_validation_name_required':
        return l10n.setupValidationNameRequired;
      case 'setup_validation_phone_invalid':
        return l10n.setupValidationPhoneInvalid;
      case 'setup_validation_phone_duplicate':
        return l10n.setupValidationPhoneDuplicate;
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
        final m = MedDraft()
          // v0.28 round 65 (spzh P2-G): 药名走 i18n (zh/en/zh_Hant),
          // 用户可编辑覆盖 — 初始值按 l10n 给当前 locale 文案
          ..nameController.text = d.nameL10n(AppLocalizations.of(context))
          ..dosageController.text = d.dosage == d.dosage.toInt()
              ? d.dosage.toInt().toString()
              : d.dosage.toString()
          ..dosageUnit = d.dosageUnit
          ..times.addAll(
            d.times.map((hm) => TimeOfDay(hour: hm.hour, minute: hm.minute)),
          );
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

    final validationError = _validateWelcomeForm();
    if (validationError != null) {
      setState(() => _saving = false);
      return;
    }

    final userName = _nameController.text.trim();
    final contactList = <({String name, String phone, int sortOrder})>[];
    final contactConsents = <ConsentArtifact>[];
    // v0.27 round 68 (CC-1 修复, PIPL §13 单独同意): setup 阶段对每个填了的
    // 联系人弹 ConsentDialog,只有同意的才入 contactList (跟 contactConsents 等长)
    // 跟主路径 contacts_list_widget.dart:208-212 走同一 ConsentDialog 集中器
    for (int i = 0; i < _contactPhoneControllers.length; i++) {
      final phone = _contactPhoneControllers[i].text.trim();
      if (phone.isEmpty) continue;
      // PIPL §13: 弹同意 dialog, 用户拒绝 → 不写该联系人,终止 setup
      // v0.27 round 82: 改用 placeholders map (R82 抽象化 ConsentDialog)
      final consent = await ConsentDialog.show(
        context,
        kind: ConsentKind.emergencyContactSharing,
        placeholders: const {
          'thresholdDays': 2, // 跟 care_strategies.secondDayMissed 一致
        },
      );
      if (consent == null) {
        // 用户拒绝: 终止整个 setup (PIPL §13 严同意, 部分填也不行)
        if (mounted) {
          AppSnackBar.showInfo(
            context,
            AppLocalizations.of(context).setupConsentRejected,
          );
        }
        setState(() => _saving = false);
        return;
      }
      // v0.27 R73 (重构-1): analyzer 期望 await 后用 context 之前有 mounted guard。
      // 之前直接用 `AppLocalizations.of(context)` 在 await 之后, analyzer 报
      // use_build_context_synchronously (R17+R56b 已知模式, 之前 5 处都靠 mounted
      // check 跟 context 同一对象 修, 这里 for-loop 内 context 跨 await 用, 同款)。
      if (!mounted) {
        setState(() => _saving = false);
        return;
      }
      final normalized = PhoneValidator.normalize(phone) ?? phone;
      final name = _contactNameControllers[i].text.trim().isEmpty
          ? AppLocalizations.of(context).setupContactFallbackName(i + 1)
          : _contactNameControllers[i].text.trim();
      contactList.add((name: name, phone: normalized, sortOrder: i));
      contactConsents.add(consent);
    }

    final medicationList = <({
      String name,
      double dosage,
      String dosageUnit,
      List<HourMinute> times,
    })>[];
    for (final m in _meds) {
      final name = m.nameController.text.trim();
      if (name.isEmpty) continue;
      final dosage = double.tryParse(m.dosageController.text.trim()) ?? 0;
      medicationList.add(
        (
          name: name,
          dosage: dosage,
          dosageUnit: m.dosageUnit,
          times: m.times
              .map((t) => HourMinute(hour: t.hour, minute: t.minute))
              .toList(),
        ),
      );
    }

    try {
      await ref.read(databaseProvider).saveSetup(
            userName: userName,
            contactList: contactList,
            contactConsents: contactConsents, // R68 CC-1
            medicationList: medicationList,
          );
      // v0.21 Round 22 (P1-22 修复): PIPL §14 同意记录
      // setup 步骤 0 勾选完成时,记录同意时刻 + 协议版本号,
      // 后续可证明"用户当时同意了哪一版协议"
      if (!mounted) return;
      await ref.read(userProfileRepositoryProvider).recordConsent(
            // v0.27 round 77 (R76-N6 修): 跟 consent_dialog 同步从 provider 读
            // 启动时算的 legal version, 不再有 hardcode const
            userAgreementVersion: ref.read(legalVersionProvider),
            privacyPolicyVersion: ref.read(legalVersionProvider),
          );
      if (!mounted) return;

      // v0.27 round 59 (spen §5#18 latent P0 fix): 修正 fail-soft timeout 丢数据
      // R52 加 5s timeout 防御 drift stream hang (DB lock 时罕见)
      // 但 fail-soft onTimeout: () => const [] 让"用户若有 N 个药"被吞成 0 个 → 失通知
      // 修正成 fail-loud: 让 TimeoutException 抛出 → 落入外层 catch → setup 失败 + UI 提示
      final medications = await ref
          .read(medicationRepositoryProvider)
          .watchAll()
          .first
          .timeout(const Duration(seconds: 5));

      // R97-P1-6 (2026-08-07): 在 context 内请求通知权限。
      //
      // 修前: notification_service.init() 在 main.dart 启动时立即弹权限请求,
      // 用户没看到任何 UI 不知为何授权 → 拒绝率高 + 违反 App Store 5.1.1
      // "权限应在 context 内请求"指南。
      //
      // 修后: 改在 setup 流程配完药、即将调度提醒的时机请求 — 用户已明确
      // 配置了药物 + 看到"提醒"相关 UI, 此刻请求权限符合用户预期。
      // 用户拒绝时仍继续 setup (提醒调度失败不阻塞核心功能, 跟 main.dart
      // try/catch 一致), 后续在 settings/reminders_hub 还可重新触发。
      try {
        await ref.read(notificationServiceProvider).requestPermission();
      } catch (e, st) {
        // 平台异常 (e.g. web 不支持) 不阻塞 setup, 走 swallowError 集中器
        swallowError(
          where: 'setup_page_state._goToStep3.requestPermission',
          error: e,
          stack: st,
          note: '通知权限请求失败不阻塞 setup',
        );
      }

      await ref
          .read(notificationServiceProvider)
          .delegate
          .rescheduleMedicationReminders(medications);
      await ref
          .read(notificationServiceProvider)
          .delegate
          .scheduleDailyReminder(hour: 20, minute: 0);
      if (!mounted) return;

      if (mounted) {
        setState(() => _step = 3);
      }
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
      if (mounted) {
        setState(() => _saving = false);
      } else {
        _saving = false;
      }
    }
  }
}
