// setup_step_welcome.dart — 首次设置 Step 1: 欢迎 + 联系人
//
// 从 setup_page.dart 拆分,v0.19 (Q2)
//
// 2026-07-31 联系人软隐藏 (病耻感 + 失联通信业务暂停):
// - 紧急联系人表单**完全可选**,不强制
// - 移除"已告知联系人" checkbox (PIPL §23 在实际填了之后才需要,纯表单阶段不需要)
// - 保留 `setupContactConsent` key 作为"提示性"段落(让用户知道将来真发通知时
//   需要先告知),但不强制勾选
// - canContinue 只看 `validationError == null`(父级已经校验过名字必填 +
//   手机号格式/重复)
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

/// Step 1: 欢迎 + 紧急联系人(可选)
///
/// 用户输入姓名 + 可选紧急联系人手机号。
/// 状态(TextEditingControllers)由父级管理。
///
/// v0.21 Round 23 (P1-23): 原"已告知联系人" checkbox 已移除,见上方注释。
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
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // 2026-07-31: 紧急联系人完全可选 → canContinue 只看父级校验
    final canContinue = widget.validationError == null;
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
              style: TextStyle(
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
          // 2026-07-31: 把"已告知联系人" 改为**提示性**段落(非强制勾选)。
          // 复用 `setupContactConsent` 文案 key — 保留 key 避免 ARB orphan。
          // 文案含义从"必须勾选"弱化为"如添加请告知对方"提示。
          if (widget.contactPhoneControllers
              .any((c) => c.text.trim().isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(top: AppTokens.spacingSm),
              child: Text(
                l10n.setupContactConsent,
                style: AppTokens.textStyleCaption(context),
              ),
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
