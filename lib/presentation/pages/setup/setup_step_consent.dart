// setup_step_consent.dart — 首次设置 Step 0: 法律同意 (PIPL)
//
// 从 setup_page.dart 拆分，v0.19 (Q2)
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';

/// Step 0: 法律同意
///
/// 用户必须勾选 3 个 checkbox 才能进入下一步。
/// 状态由父级管理（通过回调），本 widget 只负责 UI。
class SetupStepConsent extends StatelessWidget {
  final bool consentUserAgreement;
  final bool consentPrivacyPolicy;
  final bool consentSensitiveData;
  final ValueChanged<bool> onConsentUserAgreementChanged;
  final ValueChanged<bool> onConsentPrivacyPolicyChanged;
  final ValueChanged<bool> onConsentSensitiveDataChanged;
  final VoidCallback onViewUserAgreement;
  final VoidCallback onViewPrivacyPolicy;
  final VoidCallback onViewSensitiveData;
  final VoidCallback? onContinue;

  const SetupStepConsent({
    super.key,
    required this.consentUserAgreement,
    required this.consentPrivacyPolicy,
    required this.consentSensitiveData,
    required this.onConsentUserAgreementChanged,
    required this.onConsentPrivacyPolicyChanged,
    required this.onConsentSensitiveDataChanged,
    required this.onViewUserAgreement,
    required this.onViewPrivacyPolicy,
    required this.onViewSensitiveData,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.spacingLg),
          const Icon(
            Icons.gavel_outlined,
            size: 56,
            color: AppTokens.primary,
          ),
          const SizedBox(height: AppTokens.spacingMd),
          const Text(
            '使用前请阅读',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTokens.fontSizeTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          const Text(
            '为遵守《个人信息保护法》(PIPL),本 App 处理您的健康医疗等'
            '敏感个人信息前，需要您明确、单独同意以下 3 份文件。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppTokens.spacingLg),
          ConsentCheckRow(
            checked: consentUserAgreement,
            label: '我已阅读并同意《用户协议》',
            onTap: () => onConsentUserAgreementChanged(!consentUserAgreement),
            onView: onViewUserAgreement,
          ),
          const SizedBox(height: AppTokens.spacingSm),
          ConsentCheckRow(
            checked: consentPrivacyPolicy,
            label: '我已阅读并同意《隐私政策》',
            onTap: () => onConsentPrivacyPolicyChanged(!consentPrivacyPolicy),
            onView: onViewPrivacyPolicy,
          ),
          const SizedBox(height: AppTokens.spacingSm),
          ConsentCheckRow(
            checked: consentSensitiveData,
            label: '我已阅读并同意《敏感个人信息处理同意书》',
            onTap: () => onConsentSensitiveDataChanged(!consentSensitiveData),
            onView: onViewSensitiveData,
          ),
          const SizedBox(height: AppTokens.spacingXl),
          Builder(
            builder: (_) {
              final allChecked = consentUserAgreement &&
                  consentPrivacyPolicy &&
                  consentSensitiveData;
              return ElevatedButton(
                onPressed: allChecked ? onContinue : null,
                child: const Text('开始设置'),
              );
            },
          ),
          const SizedBox(height: AppTokens.spacingMd),
          const Text(
            '提示：您可以随时在「设置 → 法律与隐私」撤回同意。'
            '拒绝或撤回后,App 的相关功能将无法使用。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textHint,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppTokens.spacingLg),
        ],
      ),
    );
  }
}
