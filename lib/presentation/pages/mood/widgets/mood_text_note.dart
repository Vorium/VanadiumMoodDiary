// v0.24 Sprint #5 (emil): 抽 MoodTextNote 子 widget
//
// 从 mood_dialog.dart 抽出文字备注 TextField。
//
// emil 设计决策:
// - TextEditingController 由 parent 持有 + dispose (避免 child 状态泄漏)
// - Stateless, 仅作为 TextField 容器 (标签 + 提示)
// - 复现原代码: maxLines=2, OutlineInputBorder
import 'package:flutter/material.dart';

import 'package:chroniccare/l10n/app_localizations.dart';

/// 文字备注输入框
///
/// Controller 透传: parent 持有 + dispose。
class MoodTextNote extends StatelessWidget {
  final TextEditingController controller;

  const MoodTextNote({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: controller,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: l10n.moodNoteLabel,
        hintText: l10n.moodNoteHint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
