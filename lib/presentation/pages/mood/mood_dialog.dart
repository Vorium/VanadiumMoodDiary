// v0.28 (round 64 MoodRecorder god-split): mood_dialog.dart 降为薄壳
//
// 历史:
// - v0.24 Sprint #5: 706 行 god class 拆解 — _MoodDialogContent 持跨 widget 状态,
//   5 子 widget (recorder / score_form / tags / text_note / dialog_actions) 各自独立
// - v0.28 round 64: _MoodDialogContent 抽出到 widgets/mood_recorder_page.dart,
//   子 widget 重命名 (audio_section / score_chooser / text_input / submit_panel)
//
// **当前职责 (薄壳)**: 保持外部 API 不变 (MoodDialog.show), 转发到 MoodRecorderPage
// 避免 home_page.dart 引用变更 (跟"不"改其他 widget 引用约束一致)。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/presentation/pages/mood/widgets/mood_recorder_page.dart';

/// 情绪日记 dialog (薄壳) — 转发到 MoodRecorderPage
///
/// v0.28 之后真正的 orchestrator 在 widgets/mood_recorder_page.dart, 本文件
/// 只保留外部 API (MoodDialog.show) 不破 home_page.dart 调用方。
class MoodDialog {
  MoodDialog._();

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return MoodRecorderPage.show(context, ref);
  }
}
