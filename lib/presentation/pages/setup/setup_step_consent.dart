// setup_step_consent.dart — 首次设置 Step 0: 法律同意 (PIPL)
//
// 从 setup_page.dart 拆分,v0.19 (Q2)
//
// v0.27 round 83 (R83) 律师审核 ⚠️ Q11a 修复:
//   新增第 4 个 ConsentCheckRow: setupLegalAgeAttestation(年龄严正声明)
//   依据《未成年人保护法》§44 与《个人信息保护法》§31,14-18 周岁用户
//   需监护人代为签署同意。setup 流程中要求用户勾选严正声明(本人郑重承诺
//   已年满 18 周岁;如 14-18 周岁,已取得监护人代为同意,并愿意承担虚假
//   陈述的法律后果)。setupConsentUserAgreement / PrivacyPolicy / SensitiveData
//   措辞保持不变,新加的 age 勾选与 md 隐私政策 §10 措辞同步。
//
// v0.31 round 10 (Apple Health redesign · Phase 3 Task 3.2):
// 改 Apple 引导流程 (spec §5.2):
// - 顶部 SetupStepHeader 大标题 28pt + 副标题 15pt
// - consent 项改 ALL CAPS section header (AppleListSection title 自带 toUpperCase)
// - 大字条款: ConsentCheckRow label 改 fontSizeBody (17pt) 从 fontSizeLabel (15pt)
// - 同意列表改 AppleListSection (圆角 16 容器, hairline 分隔)
// - 底部 PrimaryButton full width
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

/// Step 0: 法律同意
///
/// 用户必须勾选 5 个 checkbox 才能进入下一步(3 个协议 + 1 个年龄严正声明 + 1 个医疗免责声明)。
/// 状态由父级管理(通过回调),本 widget 只负责 UI。
class SetupStepConsent extends StatelessWidget {
  final bool consentUserAgreement;
  final bool consentPrivacyPolicy;
  final bool consentSensitiveData;
  // v0.27 R83: 第 4 个勾选 — 年龄严正声明
  final bool consentAgeAttestation;
  // R103: 第 5 个勾选 — 医学免责声明
  final bool consentMedicalDisclaimer;
  final ValueChanged<bool> onConsentUserAgreementChanged;
  final ValueChanged<bool> onConsentPrivacyPolicyChanged;
  final ValueChanged<bool> onConsentSensitiveDataChanged;
  final ValueChanged<bool> onConsentAgeAttestationChanged;
  final ValueChanged<bool> onConsentMedicalDisclaimerChanged;
  final VoidCallback onViewUserAgreement;
  final VoidCallback onViewPrivacyPolicy;
  final VoidCallback onViewSensitiveData;
  final VoidCallback? onViewMedicalDisclaimer;
  final VoidCallback? onContinue;
  // R104: 全部同意
  final VoidCallback? onAgreeAll;
  final VoidCallback? onViewAll;

  const SetupStepConsent({
    super.key,
    required this.consentUserAgreement,
    required this.consentPrivacyPolicy,
    required this.consentSensitiveData,
    required this.consentAgeAttestation,
    required this.consentMedicalDisclaimer,
    required this.onConsentUserAgreementChanged,
    required this.onConsentPrivacyPolicyChanged,
    required this.onConsentSensitiveDataChanged,
    required this.onConsentAgeAttestationChanged,
    required this.onConsentMedicalDisclaimerChanged,
    required this.onViewUserAgreement,
    required this.onViewPrivacyPolicy,
    required this.onViewSensitiveData,
    this.onViewMedicalDisclaimer,
    this.onContinue,
    this.onAgreeAll,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allChecked = consentUserAgreement &&
        consentPrivacyPolicy &&
        consentSensitiveData &&
        consentAgeAttestation &&
        consentMedicalDisclaimer;
    return SingleChildScrollView(
      key: const ValueKey(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // v0.31 round 10: 顶部 SetupStepHeader (28pt 大标题 + 15pt 副标题)
          SetupStepHeader(
            title: l10n.setupConsentTitle,
            subtitle: l10n.setupConsentDescription,
          ),
          // v0.31 round 10: 全部同意 section (ALL CAPS via AppleListSection title)
          AppleListSection(
            margin: EdgeInsets.zero, // step content 自管 padding
            title: l10n.setupConsentAgreeAll,
            children: [
              ConsentCheckRow(
                checked: allChecked,
                // v0.31 round 10: label 走 fontSizeBody (17pt) "大字条款" 风格
                label: l10n.setupConsentAgreeAll,
                onTap: onAgreeAll ?? () {},
                onView: onViewAll ?? () {},
              ),
            ],
          ),
          // v0.31 round 10: 单独同意 section (无 title — 跟"全部同意"区分)
          // v0.31 round 10: 走 hairline 分隔, 圆角 16 容器
          AppleListSection(
            margin: EdgeInsets.zero,
            children: [
              ConsentCheckRow(
                checked: consentUserAgreement,
                label: l10n.setupConsentUserAgreement,
                onTap: () =>
                    onConsentUserAgreementChanged(!consentUserAgreement),
                onView: onViewUserAgreement,
              ),
              ConsentCheckRow(
                checked: consentPrivacyPolicy,
                label: l10n.setupConsentPrivacyPolicy,
                onTap: () =>
                    onConsentPrivacyPolicyChanged(!consentPrivacyPolicy),
                onView: onViewPrivacyPolicy,
              ),
              ConsentCheckRow(
                checked: consentSensitiveData,
                label: l10n.setupConsentSensitiveData,
                onTap: () =>
                    onConsentSensitiveDataChanged(!consentSensitiveData),
                onView: onViewSensitiveData,
              ),
              // v0.27 R83 (Q11a 律师审核 ⚠️): 第 4 个勾选 — 年龄严正声明
              ConsentCheckRow(
                checked: consentAgeAttestation,
                label: l10n.setupLegalAgeAttestation,
                onTap: () =>
                    onConsentAgeAttestationChanged(!consentAgeAttestation),
                onView: () {},
              ),
              // R103 (P0-9): 第 5 个勾选 — 医学免责声明
              ConsentCheckRow(
                checked: consentMedicalDisclaimer,
                label: l10n.setupConsentMedicalDisclaimer,
                onTap: () => onConsentMedicalDisclaimerChanged(
                  !consentMedicalDisclaimer,
                ),
                onView: onViewMedicalDisclaimer ?? () {},
              ),
            ],
          ),
          // v0.31 round 10: 底部 PrimaryButton full width
          Builder(
            builder: (_) {
              final allChecked = consentUserAgreement &&
                  consentPrivacyPolicy &&
                  consentSensitiveData &&
                  consentAgeAttestation &&
                  consentMedicalDisclaimer;
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.pageMarginH, // 20
                  AppTokens.spacingXl, // 24
                  AppTokens.pageMarginH, // 20
                  AppTokens.spacingMd, // 16
                ),
                child: PrimaryButton(
                  isFullWidth: true,
                  onPressed: allChecked ? onContinue : null,
                  child: Text(l10n.setupConsentStart),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: Text(
              l10n.setupConsentWithdrawHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: AppTokens.textHintColor(context),
                height: AppTokens.lineHeightSnug,
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingLg),
        ],
      ),
    );
  }
}
