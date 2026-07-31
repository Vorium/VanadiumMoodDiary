// setup_page.dart — 首次设置引导页（4 步 wizard coordinator）
//
// v0.19 (Q2): 拆分为 4 个 step widget + legal dialog
// 本文件只负责状态管理和步骤切换。
import 'package:chroniccare/core/shared/swallow_error.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/services/preset_medication_templates.dart';
import 'package:chroniccare/core/data/utils/phone_validator.dart';
import 'package:chroniccare/domain/entities/consent_artifact.dart' show ConsentArtifact, ConsentKind;
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/animations/animations.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/consent_dialog.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_consent.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_welcome.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_medication.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_done.dart';
import 'package:chroniccare/presentation/pages/setup/setup_legal_dialog.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';

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
        AppSnackBar.showInfo(
          context,
          AppLocalizations.of(context).setupConsentRequired,
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
    // 2026-07-31 联系人软隐藏 (病耻感 + 失联通信业务暂停):
    // 紧急联系人表单**完全可选**, 移除"必填 1 个"校验。
    // 用户可以留空跳过, 后续在 settings 自行添加。
    final filledPhones = _contactPhoneControllers
        .map((c) => c.text.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    // 只校验用户**实际填了**的手机号 — 格式 + 重复
    if (filledPhones.isNotEmpty) {
      for (final phone in filledPhones) {
        if (!PhoneValidator.isValid(phone)) {
          return l10n.setupValidationPhoneInvalid;
        }
      }
      final unique = filledPhones.toSet();
      if (unique.length != filledPhones.length) {
        return l10n.setupValidationPhoneDuplicate;
      }
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
                // v0.26 round 57 (emil C-12): 走 AppListTile.carded 集中器
                AppListTile.carded(
                  leading:
                      // v0.24 round 48 (sp-zh P1-17): emoji 视觉 < 文字,保持 fontSizeTitle 不变
                      // (不是 token 化遗漏,是 deliberate 选择 — emoji 渲染有 size cap)
                      Text(t.emoji,
                          style: const TextStyle(
                              fontSize: AppTokens.fontSizeTitle)),
                  title: Text(
                    // v0.28 round 65 (spzh P2-G): name 走 i18n
                    t.nameL10n(l10n),
                    // v0.26 round 57 (emil B-10): 走 textStyleLabelMedium 集中器
                    // 替代内联 TextStyle(w500)  (ListTile.title 默认 fontSizeLabel)
                    style: AppTokens.textStyleLabelMedium(context),
                  ),
                  subtitle: Text(t.descriptionL10n(l10n)),
                  trailing: const Icon(Icons.add_circle_outline),
                  onTap: () => Navigator.of(ctx).pop(
                    TemplateApplyResult(
                      template: t,
                      append: _meds.isNotEmpty,
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
      final consent = await ConsentDialog.show(
        context,
        kind: ConsentKind.emergencyContactSharing,
        thresholdDays: 2, // 跟 care_strategies.secondDayMissed 一致
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
            userAgreementVersion: _kLegalVersion,
            privacyPolicyVersion: _kLegalVersion,
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
