// v0.29 round 84 (CBT 思维记录): prompt 库 bottom sheet
//
// 点击问题追加到当前文本框末尾 (不替换)
//
// 频度: 5/7 栏 wizard 每步都可能调, tens/day
import 'package:flutter/material.dart';

class CbtPromptSheet {
  CbtPromptSheet._();

  static Future<void> show(
    BuildContext context, {
    required List<String> prompts,
    required ValueChanged<String> onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: prompts.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) => ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: Text(prompts[i]),
            onTap: () {
              onSelected(prompts[i]);
              Navigator.of(ctx).pop();
            },
          ),
        ),
      ),
    );
  }
}
