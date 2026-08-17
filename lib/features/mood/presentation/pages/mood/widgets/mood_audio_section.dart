// mood_audio_section.dart — mood audio 主壳 (R95 sub-spec 4 task 7 拆解)
//
// 职责: 拼装 mood_audio_recorder_widget + re-export 公共类型
// (MoodRecorderSnapshot / MoodRecorderController / MoodRecorderErrorKind)
//
// **关键: 公共类型从 mood_audio_types.dart re-export, 保持向后兼容**
// 老 caller (e.g. mood_recorder_page.dart, cbt_wizard_save_round92_test 等) 走
// `import 'package:chroniccare/presentation/pages/mood/widgets/mood_audio_section.dart'`
// 仍能拿到 MoodRecorder / MoodRecorderController / MoodRecorderSnapshot, 0 改动。
//
// 历史:
// - v0.28 (round 64 MoodRecorder god-split): audio section 从 mood_recorder.dart 抽出
// - v0.30 round 95 (sub-spec 4 task 7): 拆 3 sub-file
//   1. mood_audio_types.dart — 公共类型 (Snapshot / Controller / ErrorKind)
//   2. mood_audio_recorder_widget.dart — MoodRecorder widget (含 录音/播放/转写/加密)
//   3. mood_audio_section.dart (本文件) — 主壳, re-export 公共类型
//
// 99% 副作用不外泄:
// - 录音状态机内部消化 (idle/recording/recorded/playing)
// - AudioPlayer / Recorder / StreamSubscription / temp file 全部 dispose 链
// - 错误走 controller.onError callback, parent 决定 l10n snackbar
//
// 频度: tens/day (mood 录入核心动作)

// ===== Re-export 公共类型 (向后兼容) =====
//
// 老 caller 走 `import 'mood_audio_section.dart'` 拿 MoodRecorder widget +
// MoodRecorderController, 现在 Controller / Snapshot / ErrorKind 已搬到
// mood_audio_types.dart, 这里 re-export 让老 caller 0 改动。
export 'package:chroniccare/presentation/pages/mood/widgets/mood_audio_types.dart'
    show MoodRecorderController, MoodRecorderErrorKind, MoodRecorderSnapshot;

// Re-export MoodRecorder widget 让老 caller 走 `import 'mood_audio_section.dart'`
// 仍能拿到 (跟 R95 拆解前行为一致)
export 'package:chroniccare/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart'
    show MoodRecorder;
