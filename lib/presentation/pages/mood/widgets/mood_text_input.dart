// v0.28 (round 64 MoodRecorder god-split): text input 从 mood_text_note.dart 重命名
//
// 历史:
// - v0.24 Sprint #5: 从 mood_dialog.dart 抽出文字备注 TextField
// - v0.28 round 64: mood_text_note → mood_text_input (emil P2-2.21 命名一致)
//
// **职责**: 文字备注输入框 (1 个 TextField, 2 行)
// **接口**: stateless, TextEditingController 由 parent 持有 + dispose
//
// emil 设计决策 (保留自 v0.24):
// - TextEditingController 由 parent 持有 + dispose (避免 child 状态泄漏)
// - Stateless, 仅作为 TextField 容器 (标签 + 提示)
// - maxLines=2, OutlineInputBorder
//
// 频度: tens/day (mood 录入核心动作)
//
// 已知限制 (跟 emil P2-2.21 任务描述差距):
// - 任务说"text input + tags + character counter", 但本项目 R24 已把 tags 独立
//   到 mood_tags.dart (因 emil "decisions should be nameable" 原则 — tags
//   是 discrete Set<String> 状态, 跟连续文字流不同 axis, 不该合 widget)
// - character counter 不存在, 是新功能需求, 留待后续 sprint
import 'package:flutter/material.dart';

import 'package:chroniccare/l10n/app_localizations.dart';

/// 文字备注输入框
///
/// Controller 透传: parent 持有 + dispose。
class MoodTextInput extends StatelessWidget {
  final TextEditingController controller;

  const MoodTextInput({super.key, required this.controller});

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
