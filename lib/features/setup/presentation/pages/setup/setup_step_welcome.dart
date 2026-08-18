// setup_step_welcome.dart — 首次设置 Step 1: 欢迎
//
// 从 setup_page.dart 拆分,v0.19 (Q2)
//
// v0.31 round 10 (Apple Health redesign · Phase 3 Task 3.2):
// 改 Apple 引导流程 (spec §5.2):
// - 顶部 SetupStepHeader 大标题 28pt + 副标题 15pt
// - name 改 AppleListSection (圆角 16 容器, hairline 分隔)
// - 底部 PrimaryButton full width (default isFullWidth: true)
// - 间距统一 16
//
// 1.1.0 round 4 (emotion-first refactor): 紧急联系人表单整摘 —
// 失联通信业务暂停定版, step 1 只剩姓名输入。
import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

/// Step 1: 欢迎
///
/// 用户输入姓名。
/// 状态(TextEditingControllers)由父级管理。
class SetupStepWelcome extends StatefulWidget {
  final TextEditingController nameController;
  final String? validationError;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const SetupStepWelcome({
    super.key,
    required this.nameController,
    this.validationError,
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
    // 1.1.0 round 4: 联系人表单已摘, canContinue 只看父级名字校验
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
                style: AppTokens.textStyleCaption(context),
              ),
            ),
          const SizedBox(height: AppTokens.spacingXl), // 24 (spec 章节间距)
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
