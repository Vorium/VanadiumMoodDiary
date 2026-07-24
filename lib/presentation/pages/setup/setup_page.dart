// setup_page.dart — 首次设置引导页（4 步 wizard coordinator）
//
// v0.19 (Q2): 拆分为 4 个 step widget + legal dialog
// 本文件只负责状态管理和步骤切换。
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/services/preset_medication_templates.dart';
import 'package:chroniccare/core/data/utils/phone_validator.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_consent.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_welcome.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_medication.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_done.dart';
import 'package:chroniccare/presentation/pages/setup/setup_legal_dialog.dart';

/// 首次设置引导页（4 步 wizard coordinator）

/// v0.21 Round 22 (P1-22 修复): 协议版本号
///
/// 升级时 bump 这个值 (e.g. v0.22-2026-08-01),
/// 重新 setup 时会写新版本号,留 audit trail。
const _kLegalVersion = 'v0.21-2026-07-20';

///
/// 0=consent, 1=welcome, 2=medication, 3=done
/// 各 step 的 UI 在独立文件中，本文件只管状态 + 切换。
class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  int _step = 0;

  // Step 0: consent
  bool _consentUserAgreement = false;
  bool _consentPrivacyPolicy = false;
  bool _consentSensitiveData = false;

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
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.info(
            context,
            AppLocalizations.of(context).setupConsentRequired,
          ),
        );
      },
      child: PageScaffold(
        title: AppLocalizations.of(context).setupStep(_step + 1, 4),
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
          onConsentUserAgreementChanged: (v) =>
              setState(() => _consentUserAgreement = v),
          onConsentPrivacyPolicyChanged: (v) =>
              setState(() => _consentPrivacyPolicy = v),
          onConsentSensitiveDataChanged: (v) =>
              setState(() => _consentSensitiveData = v),
          onViewUserAgreement: () =>
              showLegalDocument(context, 'user_agreement'),
          onViewPrivacyPolicy: () =>
              showLegalDocument(context, 'privacy_policy'),
          onViewSensitiveData: () =>
              showLegalDocument(context, 'sensitive_data_consent'),
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
    final l10n = AppLocalizations.of(context);
    if (_nameController.text.trim().isEmpty) {
      return l10n.setupValidationNameRequired;
    }
    final filledPhones = _contactPhoneControllers
        .map((c) => c.text.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (filledPhones.isEmpty) {
      return l10n.setupValidationContactRequired;
    }
    // 检查手机号格式
    for (final phone in filledPhones) {
      if (!PhoneValidator.isValid(phone)) {
        return l10n.setupValidationPhoneInvalid;
      }
    }
    // 检查重复手机号
    final unique = filledPhones.toSet();
    if (unique.length != filledPhones.length) {
      return l10n.setupValidationPhoneDuplicate;
    }
    return null;
  }

  Future<void> _showPresetTemplatesSheet() async {
    final l10n = AppLocalizations.of(context);
    final result =
        await showModalBottomSheet<TemplateApplyResult<MedicationTemplate>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacingMd,
            vertical: AppTokens.spacingMd,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppTokens.spacingSm),
                child: Text(
                  l10n.setupPresetTitle,
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeTitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.spacingSm),
                child: Text(
                  l10n.setupPresetDescription,
                  style: TextStyle(
                    color: AppTokens.textSecondaryColor(context),
                    fontSize: AppTokens.fontSizeLabel,
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              for (final t in kMedicationTemplates)
                Card(
                  child: ListTile(
                    leading:
                        Text(t.emoji, style: const TextStyle(fontSize: AppTokens.fontSizeTitle)),
                    title: Text(
                      t.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(t.description),
                    trailing: const Icon(Icons.add_circle_outline),
                    onTap: () => Navigator.of(ctx).pop(
                      TemplateApplyResult(
                        template: t,
                        append: _meds.isNotEmpty,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppTokens.spacingMd),
            ],
          ),
        ),
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
          ..nameController.text = d.name
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
    ScaffoldMessenger.of(context).showSnackBar(
      AppSnackBar.info(
        context,
        AppLocalizations.of(context).setupPresetLoaded(
            result.template.name, result.template.meds.length,),
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
    for (int i = 0; i < _contactPhoneControllers.length; i++) {
      final phone = _contactPhoneControllers[i].text.trim();
      if (phone.isEmpty) continue;
      final normalized = PhoneValidator.normalize(phone) ?? phone;
      final name = _contactNameControllers[i].text.trim().isEmpty
          ? 'Contact ${i + 1}'
          : _contactNameControllers[i].text.trim();
      contactList.add((name: name, phone: normalized, sortOrder: i));
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
            medicationList: medicationList,
          );
      // v0.21 Round 22 (P1-22 修复): PIPL §14 同意记录
      // setup 步骤 0 勾选完成时,记录同意时刻 + 协议版本号,
      // 后续可证明"用户当时同意了哪一版协议"
      if (!mounted) return;
      await ref.read(userProfileRepositoryProvider).recordConsent(
            userAgreementVersion: _kLegalVersion,
            privacyPolicyVersion: _kLegalVersion,
          );
      if (!mounted) return;

      final medications =
          await ref.read(medicationRepositoryProvider).watchAll().first;
      await ref.read(notificationServiceProvider).rescheduleMedicationReminders(
            medications,
          );
      await ref
          .read(notificationServiceProvider)
          .scheduleDailyReminder(hour: 20, minute: 0);
      if (!mounted) return;

      if (mounted) {
        setState(() => _step = 3);
      }
    } catch (e, st) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // v0.22 round 30 (sp-zh P1-16): 走 AppSnackBar.error 集中器
          AppSnackBar.error(
            context,
            action: AppLocalizations.of(context).settingsActionGenerateReport,
            error: e,
          ),
        );
      }
      developer.log(
        'setup _finishSetup error',
        name: 'SetupPage',
        error: e,
        stackTrace: st,
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
