// v0.24 Sprint #5 (emil): 抽 MoodDialogActions 子 widget
//
// 从 mood_dialog.dart 抽出 AlertDialog actions 行 (取消 + 保存按钮)。
//
// emil 设计决策:
// - 复用 v0.22 round 34 抽的 LoadingTextButton (saving spinner 集中器)
// - Stateless, 2 callback + 1 bool
// - emil 频度决策: tens/day 频度, 走 PressFeedback 标准反馈
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/loading_text_button.dart';

/// AlertDialog 底部按钮行 (取消 + 保存)
///
/// saving=true 时保存按钮变 LoadingTextButton spinner, 取消按钮禁用。
class MoodDialogActions extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const MoodDialogActions({
    super.key,
    required this.saving,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: saving ? null : onCancel,
          child: Text(l10n.commonCancel),
        ),
        const SizedBox(width: AppTokens.spacingXs),
        LoadingTextButton(
          label: l10n.commonSave,
          isLoading: saving,
          onPressed: saving ? null : onSave,
        ),
      ],
    );
  }
}
