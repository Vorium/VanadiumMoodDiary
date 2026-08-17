// mood_audio_types.dart — mood audio section 公共类型
//
// v0.30 round 95 (sub-spec 4 task 7): 从 mood_audio_section.dart 抽出
//
// 公共类型集中器:
// - [MoodRecorderSnapshot] 录音机当前快照 (parent 在 save 时拉)
// - [MoodRecorderController] 录音机对外接口 (ValueNotifier + 3 method + dispose)
// - [MoodRecorderErrorKind] 错误类型 (决定 parent 调哪个 l10n snackbar)
//
// 拆出原因: 原 mood_audio_section.dart 591 行, 主体 MoodRecorder widget 占
// ~400 行, 但 public 类型 80+ 行 跟 widget 混一起, 拆出后 widget 主壳瘦到
// ~470 行, 公共类型独立 80 行, 总文件数 3 但每个文件 < 500 行。
import 'package:flutter/foundation.dart';

import 'package:chroniccare/features/mood/data/services/mood_audio_service.dart';

/// 录音机的当前快照 — parent 在 save 时拉
@immutable
class MoodRecorderSnapshot {
  final String? audioPath;
  final int? audioDurationMs;
  final String finalTranscript;
  final bool sttFailed;

  const MoodRecorderSnapshot({
    this.audioPath,
    this.audioDurationMs,
    this.finalTranscript = '',
    this.sttFailed = false,
  });

  bool get hasRecording => audioPath != null;

  static const empty = MoodRecorderSnapshot();
}

/// 录音机对外接口 — parent 通过这个控制 MoodRecorder
///
/// 设计: ValueNotifier + 3 method + dispose, 不暴露 State (跟 Riverpod 解耦)
class MoodRecorderController {
  final ValueNotifier<MoodRecorderSnapshot> snapshot;
  final VoidCallback _onDisposeNotify;

  /// Service 注入点 — test 时可换 FakeMoodAudioService
  /// 默认 null = 从 moodAudioServiceProvider 拿
  final MoodAudioService Function()? serviceFactory;

  /// 错误回调 — 录音失败时由 parent 决定是否 snackbar
  final void Function(Object error, MoodRecorderErrorKind kind)? onError;

  MoodRecorderController({
    MoodRecorderSnapshot initial = MoodRecorderSnapshot.empty,
    this.serviceFactory,
    this.onError,
    VoidCallback? onDispose,
  })  : snapshot = ValueNotifier(initial),
        _onDisposeNotify = onDispose ?? _noop;

  static void _noop() {}

  void dispose() {
    snapshot.dispose();
    _onDisposeNotify();
  }
}

/// 错误类型 — 决定 parent 调哪个 l10n snackbar
enum MoodRecorderErrorKind { start, stop, encrypt, play }
