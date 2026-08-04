// v0.29 round 84 (CBT 思维记录): 公共 section 字段
//
// 标题 + ℹ️ popup + 文本框 + ? prompt 库按钮
// 5/7 栏 wizard 每步都用这个组件
//
// 频度: 5/7 栏 wizard 每步都用, tens/day
import 'package:flutter/material.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_prompt_sheet.dart';

class CbtSectionField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: AppTokens.textStyleLabel(context)),
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
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          controller: TextEditingController(text: initialValue ?? '')
            ..selection = TextSelection.collapsed(offset: (initialValue ?? '').length),
          onChanged: onChanged,
        ),
        if (prompts.isNotEmpty) ...[
          const SizedBox(height: AppTokens.spacingXxs),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => CbtPromptSheet.show(
                context, prompts: prompts, onSelected: onChanged,
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
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(hint),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('好的'),
          ),
        ],
      ),
    );
  }
}
