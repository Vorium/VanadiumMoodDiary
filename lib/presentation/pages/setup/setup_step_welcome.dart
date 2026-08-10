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
//
// v0.31 round 10 (Apple Health redesign · Phase 3 Task 3.2):
// 改 Apple 引导流程 (spec §5.2):
// - 顶部 SetupStepHeader 大标题 28pt + 副标题 15pt
// - name + contact 改 AppleListSection (圆角 16 容器, hairline 分隔)
// - 添加联系人 button 改 PrimaryButton secondary (FilledButton.tonal)
// - 底部 PrimaryButton full width (default isFullWidth: true)
// - 间距统一 16
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
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
          // v0.31 round 10: 顶部 SetupStepHeader (28pt 大标题 + 15pt 副标题)
          SetupStepHeader(
            title: l10n.setupHello,
            subtitle: l10n.setupIntro,
          ),
          // ===== 姓名: AppleListSection =====
          // v0.31 round 10: name 字段包 AppleListSection (圆角 16 容器, hairline 分隔)
          AppleListSection(
            margin: EdgeInsets.zero, // step content 自管 padding
            children: [
              Padding(
                // 跟 AppleListSection 默认 cell padding 重叠但更宽松
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.spacingMd,
                  vertical: AppTokens.spacingSm,
                ),
                child: TextField(
                  controller: widget.nameController,
                  decoration: InputDecoration(
                    labelText: l10n.setupName,
                    hintText: l10n.setupNameHint,
                    border: InputBorder.none, // AppleListSection 自带容器
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          if (widget.validationError != null)
            Padding(
              padding: const EdgeInsets.only(
                left: AppTokens.pageMarginH,
                top: AppTokens.spacingXs,
                right: AppTokens.pageMarginH,
              ),
              child: Text(
                widget.validationError!,
                style: TextStyle(
                  color: AppTokens.errorColor(context),
                  fontSize: AppTokens.fontSizeCaption,
                ),
              ),
            ),
          const SizedBox(height: AppTokens.spacingXl), // 24 (spec 章节间距)
          // ===== 联系人 section =====
          // v0.31 round 10: 紧急联系人改 AppleListSection
          // title ALL CAPS (AppleListSection 自带 toUpperCase)
          Padding(
            padding: const EdgeInsets.only(
              left: AppTokens.pageMarginH,
              right: AppTokens.pageMarginH,
              bottom: AppTokens.spacingXs,
            ),
            child: Text(
              l10n.setupContacts,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: Text(
              l10n.setupWelcomeContactHint,
              style: TextStyle(
                fontSize: AppTokens.fontSizeBody,
                color: AppTokens.textSecondaryColor(context),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          for (int i = 0; i < widget.contactPhoneControllers.length; i++) ...[
            AppleListSection(
              margin: EdgeInsets.zero, // step content 自管 padding
              children: [
                _ContactRow(
                  index: i,
                  nameController: widget.contactNameControllers[i],
                  phoneController: widget.contactPhoneControllers[i],
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingMd),
          ],
          // v0.31 round 10: "添加联系人" 改 PrimaryButton secondary (FilledButton.tonal)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: PrimaryButton(
              variant: PrimaryButtonVariant.secondary,
              isFullWidth: true,
              leadingIcon: const Icon(Icons.add),
              onPressed: widget.onAddContact,
              child: Text(l10n.setupAddContact),
            ),
          ),
          // 2026-07-31: 把"已告知联系人" 改为**提示性**段落(非强制勾选)。
          // 复用 `setupContactConsent` 文案 key — 保留 key 避免 ARB orphan。
          if (widget.contactPhoneControllers
              .any((c) => c.text.trim().isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(
                left: AppTokens.pageMarginH,
                right: AppTokens.pageMarginH,
                top: AppTokens.spacingSm,
              ),
              child: Text(
                l10n.setupContactConsent,
                style: AppTokens.textStyleCaption(context),
              ),
            ),
          const SizedBox(height: AppTokens.spacingXl), // 24
          // ===== 底部按钮: PrimaryButton full width + 上一步 tertiary =====
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: PrimaryButton(
              isFullWidth: true,
              onPressed: canContinue ? widget.onContinue : null,
              child: Text(l10n.setupNext),
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          // v0.31 round 10: "上一步" 改 PrimaryButton tertiary (TextButton) — full width
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: PrimaryButton(
              variant: PrimaryButtonVariant.tertiary,
              isFullWidth: true,
              onPressed: widget.onBack,
              child: Text(l10n.setupBack),
            ),
          ),
          const SizedBox(height: AppTokens.spacingLg),
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
    // v0.31 round 10: AppleListSection 自带 cell padding, 这里只填内容
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMd,
        vertical: AppTokens.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: l10n.setupContactNameLabel(index + 1),
              hintText: l10n.setupContactNameHint,
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          TextField(
            controller: phoneController,
            decoration: InputDecoration(
              labelText: l10n.setupContactPhoneLabel(index + 1),
              hintText: l10n.setupContactPhoneHint,
              border: InputBorder.none,
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }
}
