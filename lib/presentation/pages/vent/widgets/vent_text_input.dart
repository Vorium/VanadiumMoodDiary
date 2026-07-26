// v0.24 round 46 (emil B-13 god class 续拆): vent_compose 抽 3 子 widget
//
// 文字输入区：TextField (长文本 max 2000) + 字符计数警告 (v0.21 Round 23)
//
// 高内聚：只关心 text controller + 字数统计
// 低耦合：orchestrator 持 controller + watch 字符数变化
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

class VentTextInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final int maxLength;

  const VentTextInput({
    super.key,
    required this.controller,
    this.onChanged,
    this.maxLength = 2000,
  });

  @override
  Widget build(BuildContext context) {
    final textLen = controller.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            maxLength: maxLength,
            textAlignVertical: TextAlignVertical.top,
            style: const TextStyle(fontSize: AppTokens.fontSizeBody),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).ventComposeHint,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.all(AppTokens.spacingSm),
            ),
            onChanged: onChanged,
          ),
        ),
        if (textLen > AppTokens.textLengthWarningThreshold)
          Padding(
            padding: const EdgeInsets.only(top: AppTokens.spacingXxs),
            child: Text(
              '$textLen / $maxLength',
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: textLen > maxLength
                    ? AppTokens.error
                    : AppTokens.textHintColor(context),
              ),
            ),
          ),
      ],
    );
  }
}
