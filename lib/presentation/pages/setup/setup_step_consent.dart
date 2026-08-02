// setup_step_consent.dart — 首次设置 Step 0: 法律同意 (PIPL)
//
// 从 setup_page.dart 拆分，v0.19 (Q2)
//
// v0.27 round 83 (R83) 律师审核 ⚠️ Q11a 修复:
//   新增第 4 个 ConsentCheckRow: setupLegalAgeAttestation(年龄严正声明)
//   依据《未成年人保护法》§44 与《个人信息保护法》§31,14-18 周岁用户
//   需监护人代为签署同意。setup 流程中要求用户勾选严正声明(本人郑重承诺
//   已年满 18 周岁;如 14-18 周岁,已取得监护人代为同意,并愿意承担虚假
//   陈述的法律后果)。setupConsentUserAgreement / PrivacyPolicy / SensitiveData
//   措辞保持不变,新加的 age 勾选与 md 隐私政策 §10 措辞同步。
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

/// Step 0: 法律同意
///
/// 用户必须勾选 4 个 checkbox 才能进入下一步(3 个协议 + 1 个年龄严正声明)。
/// 状态由父级管理（通过回调），本 widget 只负责 UI。
class SetupStepConsent extends StatelessWidget {
  final bool consentUserAgreement;
  final bool consentPrivacyPolicy;
  final bool consentSensitiveData;
  // v0.27 R83: 第 4 个勾选 — 年龄严正声明
  final bool consentAgeAttestation;
  final ValueChanged<bool> onConsentUserAgreementChanged;
  final ValueChanged<bool> onConsentPrivacyPolicyChanged;
  final ValueChanged<bool> onConsentSensitiveDataChanged;
  final ValueChanged<bool> onConsentAgeAttestationChanged;
  final VoidCallback onViewUserAgreement;
  final VoidCallback onViewPrivacyPolicy;
  final VoidCallback onViewSensitiveData;
  final VoidCallback? onContinue;

  const SetupStepConsent({
    super.key,
    required this.consentUserAgreement,
    required this.consentPrivacyPolicy,
    required this.consentSensitiveData,
    required this.consentAgeAttestation,
    required this.onConsentUserAgreementChanged,
    required this.onConsentPrivacyPolicyChanged,
    required this.onConsentSensitiveDataChanged,
    required this.onConsentAgeAttestationChanged,
    required this.onViewUserAgreement,
    required this.onViewPrivacyPolicy,
    required this.onViewSensitiveData,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      key: const ValueKey(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.spacingLg),
          Icon(
            Icons.gavel_outlined,
            size: AppTokens.iconSizeError,
            color: AppTokens.primaryColor(context),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          Text(
            l10n.setupConsentTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(
            l10n.setupConsentDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondaryColor(context),
              height: AppTokens.lineHeightNormal,
            ),
          ),
          const SizedBox(height: AppTokens.spacingLg),
          ConsentCheckRow(
            checked: consentUserAgreement,
            label: l10n.setupConsentUserAgreement,
            onTap: () => onConsentUserAgreementChanged(!consentUserAgreement),
            onView: onViewUserAgreement,
          ),
          const SizedBox(height: AppTokens.spacingSm),
          ConsentCheckRow(
            checked: consentPrivacyPolicy,
            label: l10n.setupConsentPrivacyPolicy,
            onTap: () => onConsentPrivacyPolicyChanged(!consentPrivacyPolicy),
            onView: onViewPrivacyPolicy,
          ),
          const SizedBox(height: AppTokens.spacingSm),
          ConsentCheckRow(
            checked: consentSensitiveData,
            label: l10n.setupConsentSensitiveData,
            onTap: () => onConsentSensitiveDataChanged(!consentSensitiveData),
            onView: onViewSensitiveData,
          ),
          // v0.27 R83 (Q11a 律师审核 ⚠️): 第 4 个勾选 — 年龄严正声明
          // 严正声明措辞 (本人郑重承诺...),与隐私政策 §10 + 敏感数据同意书
          // 同步,符合《未成年人保护法》§44 + 《PIPL》§31。
          const SizedBox(height: AppTokens.spacingSm),
          ConsentCheckRow(
            checked: consentAgeAttestation,
            label: l10n.setupLegalAgeAttestation,
            onTap: () =>
                onConsentAgeAttestationChanged(!consentAgeAttestation),
            onView: () {},
          ),
          const SizedBox(height: AppTokens.spacingXl),
          Builder(
            builder: (_) {
              final allChecked = consentUserAgreement &&
                  consentPrivacyPolicy &&
                  consentSensitiveData &&
                  consentAgeAttestation;
              return PrimaryButton(
                onPressed: allChecked ? onContinue : null,
                child: Text(l10n.setupConsentStart),
              );
            },
          ),
          const SizedBox(height: AppTokens.spacingMd),
          Text(
            l10n.setupConsentWithdrawHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textHintColor(context),
              height: AppTokens.lineHeightSnug,
            ),
          ),
          const SizedBox(height: AppTokens.spacingLg),
        ],
      ),
    );
  }
}
