// setup_step_welcome.dart — 首次设置 Step 1: 欢迎 + 联系人
//
// 从 setup_page.dart 拆分，v0.19 (Q2)
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

/// Step 1: 欢迎 + 紧急联系人
///
/// 用户输入姓名 + 紧急联系人手机号。
/// 状态（TextEditingControllers）由父级管理。
///
/// v0.21 Round 23 (P1-23 修复): 紧急联系人知情同意 checkbox
/// 法律要求: 给第三方(紧急联系人)发通知前,必须先获得用户声明已告知第三方
/// (PIPL §23 + 个人信息保护法 + 民法典人格权)
class SetupStepWelcome extends StatefulWidget {
  final TextEditingController nameController;
  final List<TextEditingController> contactNameControllers;
  final List<TextEditingController> contactPhoneControllers;
  final String? validationError;
  final VoidCallback onAddContact;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const SetupStepWelcome({
    super.key,
    required this.nameController,
    required this.contactNameControllers,
    required this.contactPhoneControllers,
    this.validationError,
    required this.onAddContact,
    required this.onBack,
    required this.onContinue,
  });

  @override
  State<SetupStepWelcome> createState() => _SetupStepWelcomeState();
}

class _SetupStepWelcomeState extends State<SetupStepWelcome> {
  bool _contactConsentConfirmed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // v0.21 Round 23 (P1-23): 未勾选"已告知联系人" → 阻止进入下一步
    final canContinue = widget.validationError == null && _contactConsentConfirmed;
    return SingleChildScrollView(
      key: const ValueKey(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.spacingXl),
          Text(
            l10n.setupHello,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeTitle,
              fontWeight: FontWeight.w600,
              height: AppTokens.lineHeightTight,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(
            l10n.setupIntro,
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          TextField(
            controller: widget.nameController,
            decoration: InputDecoration(
              labelText: l10n.setupName,
              hintText: l10n.setupNameHint,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          if (widget.validationError != null) ...[
            const SizedBox(height: AppTokens.spacingXs),
            Text(
              widget.validationError!,
              style:TextStyle(
                color: AppTokens.errorColor(context),
                fontSize: AppTokens.fontSizeCaption,
              ),
            ),
          ],
          const SizedBox(height: AppTokens.spacingXl),
          Text(
            l10n.setupContacts,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(
            l10n.setupWelcomeContactHint,
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          for (int i = 0; i < widget.contactPhoneControllers.length; i++) ...[
            _ContactRow(
              index: i,
              nameController: widget.contactNameControllers[i],
              phoneController: widget.contactPhoneControllers[i],
            ),
            const SizedBox(height: AppTokens.spacingSm),
          ],
          // v0.22 round 30 (emil P3-5): 包 PressFeedback 接管 tap
          PressFeedback(
            onTap: widget.onAddContact,
            child: OutlinedButton.icon(
              onPressed: null, // 委托给 PressFeedback
              icon: const Icon(Icons.add),
              label: Text(l10n.setupAddContact),
            ),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          // v0.21 Round 23 (P1-23 修复): 紧急联系人知情同意 checkbox
          // 法律合规: 给第三方(联系人)发通知前,用户必须声明已告知联系人
          // (PIPL §23 个人信息处理者向第三方提供应取得个人同意)
          CheckboxListTile(
            value: _contactConsentConfirmed,
            onChanged: (v) {
              setState(() {
                _contactConsentConfirmed = v ?? false;
              });
            },
            title: Text(
              l10n.setupContactConsent,
              style: TextStyle(
                fontSize: AppTokens.fontSizeBody,
                color: AppTokens.textPrimaryColor(context),
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: AppTokens.spacingLg),
          Row(
            children: [
              TextButton(
                onPressed: widget.onBack,
                child: Text(l10n.setupBack),
              ),
              const Spacer(),
              PrimaryButton(
                isFullWidth: false,
                onPressed: canContinue ? widget.onContinue : null,
                child: Text(l10n.setupNext),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final int index;
  final TextEditingController nameController;
  final TextEditingController phoneController;

  const _ContactRow({
    required this.index,
    required this.nameController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: l10n.setupContactNameLabel(index + 1),
                hintText: l10n.setupContactNameHint,
              ),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: l10n.setupContactPhoneLabel(index + 1),
                hintText: l10n.setupContactPhoneHint,
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }
}
