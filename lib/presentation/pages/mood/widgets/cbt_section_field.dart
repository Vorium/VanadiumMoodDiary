// v0.29 round 84 (CBT 思维记录): 公共 section 字段
//
// 标题 + ℹ️ popup + 文本框 + ? prompt 库按钮
// 5/7 栏 wizard 每步都用这个组件
//
// 频度: 5/7 栏 wizard 每步都用, tens/day
//
// v0.29 round 84 (fix): 改 StatefulWidget + initState/dispose,
// 避免父 setState 重建时丢用户输入 + 泄漏 controller.
import 'package:flutter/material.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_prompt_sheet.dart';

class CbtSectionField extends StatefulWidget {
  final String title;
  final String hint;
  final List<String> prompts;
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final int maxLines;

  const CbtSectionField({
    super.key,
    required this.title,
    required this.hint,
    required this.prompts,
    required this.onChanged,
    this.initialValue,
    this.maxLines = 3,
  });

  @override
  State<CbtSectionField> createState() => _CbtSectionFieldState();
}

class _CbtSectionFieldState extends State<CbtSectionField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(widget.title, style: AppTokens.textStyleLabel(context)),
            const SizedBox(width: AppTokens.spacingXxs),
            InkWell(
              onTap: () => _showInfoDialog(context),
              child: Icon(
                Icons.info_outline,
                size: AppTokens.iconSizeMicro,
                color: AppTokens.textSecondaryColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spacingXxs),
        TextField(
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hint,
            border: const OutlineInputBorder(),
          ),
          controller: _controller,
          onChanged: widget.onChanged,
        ),
        if (widget.prompts.isNotEmpty) ...[
          const SizedBox(height: AppTokens.spacingXxs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => CbtPromptSheet.show(
                context,
                prompts: widget.prompts,
                onSelected: widget.onChanged,
              ),
              icon: const Icon(Icons.help_outline, size: 16),
              label: const Text('?'),
            ),
          ),
        ],
      ],
    );
  }

  void _showInfoDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.title),
        content: Text(widget.hint),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonConfirmOk),
          ),
        ],
      ),
    );
  }
}
