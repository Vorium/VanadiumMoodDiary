// v0.29 round 84 (CBT 思维记录): prompt 库 bottom sheet
//
// 点击问题追加到当前文本框末尾 (不替换)
//
// 频度: 5/7 栏 wizard 每步都可能调, tens/day
import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

class CbtPromptSheet {
  CbtPromptSheet._();

  static Future<void> show(
    BuildContext context, {
    required List<String> prompts,
    required ValueChanged<String> onSelected,
  }) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.spacingMd,
                AppTokens.spacingMd,
                AppTokens.spacingMd,
                AppTokens.spacingXxs,
              ),
              child: Text(
                l10n.moodCbtPromptTitle,
                style: AppTokens.textStyleLabelStrong(context),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: prompts.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, thickness: 0.5),
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
          ],
        ),
      ),
    );
  }
}
