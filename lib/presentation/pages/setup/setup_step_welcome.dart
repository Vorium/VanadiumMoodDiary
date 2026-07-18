// setup_step_welcome.dart — 首次设置 Step 1: 欢迎 + 联系人
//
// 从 setup_page.dart 拆分，v0.19 (Q2)
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// Step 1: 欢迎 + 紧急联系人
///
/// 用户输入姓名 + 紧急联系人手机号。
/// 状态（TextEditingControllers）由父级管理。
class SetupStepWelcome extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(
            l10n.setupIntro,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: l10n.setupName,
              hintText: l10n.setupNameHint,
            ),
            textCapitalization: TextCapitalization.words,
          ),
          if (validationError != null) ...[
            const SizedBox(height: AppTokens.spacingXs),
            Text(
              validationError!,
              style: const TextStyle(
                color: AppTokens.error,
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
            '（至少填 1 个手机号，用于失联时通知）',
            style: const TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          for (int i = 0; i < contactPhoneControllers.length; i++) ...[
            _ContactRow(
              index: i,
              nameController: contactNameControllers[i],
              phoneController: contactPhoneControllers[i],
            ),
            const SizedBox(height: AppTokens.spacingSm),
          ],
          OutlinedButton.icon(
            onPressed: onAddContact,
            icon: const Icon(Icons.add),
            label: Text(l10n.setupAddContact),
          ),
          const SizedBox(height: AppTokens.spacingXl),
          Row(
            children: [
              TextButton(
                onPressed: onBack,
                child: const Text('← 上一步'),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: validationError != null ? null : onContinue,
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
                labelText: '联系人 ${index + 1} 姓名',
                hintText: '称呼（选填）',
              ),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: '紧急联系人手机号 ${index + 1}',
                hintText: '13800138000',
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }
}
