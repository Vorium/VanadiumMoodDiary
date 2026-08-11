// mood_audio_recorder_widget.dart — MoodRecorder widget 主壳
//
// v0.30 round 95 (sub-spec 4 task 7): 从 mood_audio_section.dart 抽出
//
// 职责: 录音机的状态机 widget (idle / recording / recorded / playing)
// 4 phase 自管理 + STT 实时转写 + AudioPlayer 播放 + 加密存储
//
// 公共类型 [MoodRecorderSnapshot] / [MoodRecorderController] /
// [MoodRecorderErrorKind] 已搬到 mood_audio_types.dart (主壳
// mood_audio_section.dart re-export)。
//
// v0.30 R108 (P1 god class 拆 6 大 F - Fix #1): audio state machine 抽
// `lib/presentation/widgets/audio_lifecycle.dart` AudioLifecycleMixin。
// - 4 状态字段 (_isRecording / _isPlaying / _audioPath / _tempDecryptedPath)
//   走 mixin
// - _disposeResources 65 行 4 步链走 mixin.asyncDisposeAudio
// - _toggleRecord / _togglePlay / _reRecord 简化, 调 mixin 状态机方法
// - 4 抽象方法 (startRecordingImpl / stopRecordingImpl / startPlaybackImpl /
//   stopPlaybackImpl) 走 MoodAudioService 封装 (record + stt + encrypt)
// - 行数 530 → 339 (减 191, 重复代码消除)
//
// emil 设计决策 (保留自 v0.24):
// 1. 不用 Riverpod StateNotifier — dialog scope, ValueNotifier 已够
// 2. MoodRecorderController 暴露 snapshot (ValueListenable) + 3 method
// 3. dispose 链完整 — recorder / player / 2 StreamSubscription / temp file / service
// 4. 保留所有 P0 修复: snackbar 走 parent context / AudioPlayer dispose 顺序 /
//    EncryptedAudioStorage temp cleanup / swallowError / _isRecording cancel on dispose /
//    STT failed graceful degrade / maxReached 下沉
//
// 频度: tens/day (mood 录入核心动作)
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import 'package:chroniccare/core/data/services/mood_audio_service.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/mood_providers.dart';
import 'package:chroniccare/presentation/widgets/audio_lifecycle.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_audio_types.dart';

/// 录音机 widget — 自管 idle/recording/recorded/playing 状态机
class MoodRecorder extends ConsumerStatefulWidget {
  final MoodRecorderController controller;

  const MoodRecorder({super.key, required this.controller});

  @override
  ConsumerState<MoodRecorder> createState() => _MoodRecorderState();
}

class _MoodRecorderState extends ConsumerState<MoodRecorder>
    with AudioLifecycleMixin<MoodRecorder> {
  // ===== mood 特有字段 (STT / transcript) =====

  String _liveTranscript = '';
  String _finalTranscript = '';
  int? _audioDurationMs;
  bool _sttAvailable = false;
  bool _sttFailed = false;

  // Stream subscription for STT partial results
  StreamSubscription<String>? _sttSub;

  MoodAudioService get _service =>
      widget.controller.serviceFactory?.call() ??
      ref.read(moodAudioServiceProvider);

  @override
  void initState() {
    super.initState();
    final player = AudioPlayer();
    // mood_audio player 实例: 走 AudioLifecycleMixin 共享 asyncDisposeAudio,
    // 私有字段存它
    _player = player;
    playerCompleteSub = player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => audioState = AudioState.recorded);
    });
    // 初始化 STT (异步, 不阻塞 UI)
    _initializeStt();
  }

  // AudioLifecycleMixin 共享 asyncDisposeAudio 需要 player + recorder 实例。
  // mood 用 MoodAudioService 封装 recorder, 这里给 mixin 传 null (mixin
  // 内部会 null-skip recorder 路径, 改成走 service.dispose())。
  AudioPlayer? _player;
  AudioRecorder? get _recorderInstance => null; // 走 service.dispose()

  Future<void> _initializeStt() async {
    final ok = await _service.initialize();
    if (!mounted) return;
    setState(() => _sttAvailable = ok);
  }

  @override
  void dispose() {
    // v0.27 round 61 (P0-1 fix): 先同步设 state 回 idle, 阻止
    // asyncDisposeAudio 链 (await service.cancelRecording) 触发的 onTick
    // / onMaxReached 回调 setState 撞 defunct assert。dispose 之前
    // audioState == recording 是 race 条件源: service.stopRecording 内部
    // 仍可能走完一次 onTick, 该 setState 落到 disposed widget 触发 assert。
    // 同步设之后所有后续检查 `audioState == recording` 都返 false, 安全跳过。
    audioState = AudioState.idle;
    // v0.25 round 52 (spen P0 #7): State.dispose() 是 sync, 不能 await future,
    // 但 fire-and-forget 必须显式 unawaited 标记。race 风险: widget 已 defunct
    // 时 future 仍可能跑 — 每个都 catchError 走 swallowError 兜底 + unawaited 跟踪。
    unawaited(
      _disposeResources().catchError((Object e, StackTrace st) {
        swallowError(
          where: 'mood_audio_section.dispose._disposeResources',
          error: e,
          stack: st,
          note: 'dispose resources chain failed',
        );
      }),
    );
    super.dispose();
  }

  /// 顺序释放: 停 player → 清理临时文件 → cancel recording → service dispose
  ///
  /// R108 Fix #1: 之前 4 个 fire-and-forget 是 race (spen P0 #7), 现在部分走
  /// mixin.asyncDisposeAudio (player + temp), service 释放仍在本类。
  Future<void> _disposeResources() async {
    // 1) stop stream subscriptions (R27 round 61 P0-1 fix)
    try {
      await playerCompleteSub?.cancel();
    } catch (e, st) {
      swallowError(
        where: 'mood_audio_section.dispose.playerCompleteSub',
        error: e,
        stack: st,
      );
    }
    try {
      await _sttSub?.cancel();
    } catch (e, st) {
      swallowError(
        where: 'mood_audio_section.dispose.sttSub',
        error: e,
        stack: st,
      );
    }
    playerCompleteSub = null;
    _sttSub = null;

    // 2) mixin asyncDisposeAudio: stop + dispose player + delete temp
    await asyncDisposeAudio(
      player: _player,
      recorder: _recorderInstance, // null — mood 走 service
    );

    // 3) 取消录音 (如果还在录) — mood 用 service 封装
    try {
      await _service.cancelRecording();
    } catch (e, st) {
      swallowError(
        where: 'mood_audio_section.dispose.cancelRecording',
        error: e,
        stack: st,
        note: 'cancel recording on dispose failed',
      );
    }

    // 4) service dispose (释放 AudioRecorder + SpeechToText)
    try {
      await _service.dispose();
    } catch (e, st) {
      swallowError(
        where: 'mood_audio_section.dispose.service',
        error: e,
        stack: st,
      );
    }
  }

  // ===== AudioLifecycleMixin 4 抽象方法 + 1 override =====

  /// mood 启动录音 + STT + 实时转写
  @override
  Future<bool> startRecordingImpl() async {
    setState(() {
      _liveTranscript = '';
      _finalTranscript = '';
      _sttFailed = false;
    });
    // 订阅 STT 流
    // R97-P1-12: unawaited 显式标记 fire-and-forget (cancel 不阻塞)
    unawaited(_sttSub?.cancel());
    _sttSub = _service.sttTranscriptStream.listen((text) {
      if (!mounted) return;
      setState(() => _liveTranscript = text);
    });
    await _service.startRecording(
      onTick: (elapsed) {
        if (!mounted) return;
        // R102 (P1): 不再需要空 setState — _RecordingTimer 自己管理 rebuild
      },
      onMaxReached: () {
        if (!mounted) return;
        // 3min 自动停
        stopRecording();
      },
    );
    return true;
  }

  /// mood 停止录音 + STT stop + 加密
  @override
  Future<String?> stopRecordingImpl() async {
    final result = await _service.stopRecording();
    // STT 停止
    try {
      await _service.stopStt();
    } catch (e, st) {
      swallowError(
        where: 'mood_audio_section.stopStt',
        error: e,
        stack: st,
        note: 'STT stop failed',
      );
    }
    // R97-P1-12: unawaited 显式标记 fire-and-forget
    unawaited(_sttSub?.cancel());
    _sttSub = null;

    if (result == null) {
      return null;
    }

    // 加密
    final storage = ref.read(moodAudioStorageProvider);
    final encryptedPath = await storage.newAudioPath();
    try {
      await storage.encryptAndWrite(
        plainPath: result.plainPath,
        encryptedPath: encryptedPath,
      );
    } catch (e) {
      if (mounted) {
        widget.controller.onError?.call(e, MoodRecorderErrorKind.encrypt);
      }
      return null;
    }

    // final transcript: 由 sttTranscriptStream 最后一条推送决定
    final transcript = _liveTranscript;
    final sttFailed = transcript.isEmpty && _sttAvailable;

    if (mounted) {
      setState(() {
        _audioDurationMs = result.durationMs;
        _finalTranscript = transcript;
        _sttFailed = sttFailed;
      });
      // 上抛 snapshot 给 parent
      widget.controller.snapshot.value = MoodRecorderSnapshot(
        audioPath: encryptedPath,
        audioDurationMs: result.durationMs,
        finalTranscript: transcript,
        sttFailed: sttFailed,
      );
    }
    return encryptedPath;
  }

  /// mood decryptToTemp + 启动 player
  @override
  Future<void> startPlaybackImpl(String encryptedPath) async {
    final storage = ref.read(moodAudioStorageProvider);
    final tempPath = await storage.decryptToTemp(encryptedPath);
    tempDecryptedPath = tempPath;
    await _player?.play(DeviceFileSource(tempPath));
  }

  /// mood 停止 player
  @override
  Future<void> stopPlaybackImpl() async {
    await _player?.stop();
  }

  /// mood 清理 temp 解密文件
  @override
  Future<void> cleanupTempFile() async {
    final temp = tempDecryptedPath;
    if (temp == null) return;
    try {
      await ref.read(moodAudioStorageProvider).deleteTempFile(temp);
    } catch (e, st) {
      swallowError(
        where: 'mood_audio_section.cleanupTempFile',
        error: e,
        stack: st,
      );
    }
  }

  // ===== 公开方法 (供 widget callback) =====

  /// mood 录音切换
  Future<void> _toggleRecord() async {
    if (isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  /// mood 重录
  Future<void> _reRecord() async {
    final previousPath = widget.controller.snapshot.value.audioPath;
    if (previousPath != null) {
      try {
        await ref.read(moodAudioStorageProvider).deleteAudio(previousPath);
      } catch (e, st) {
        swallowError(
          where: 'mood_audio_section._reRecord',
          error: e,
          stack: st,
        );
      }
    }
    if (mounted) {
      setState(() {
        _audioDurationMs = null;
        _finalTranscript = '';
        _liveTranscript = '';
        _sttFailed = false;
      });
    }
    widget.controller.snapshot.value = MoodRecorderSnapshot.empty;
    clearRecording();
  }

  /// mood 播放切换
  Future<void> _togglePlay() async {
    if (audioPath == null) return;
    if (isPlaying) {
      await stopPlayback();
    } else {
      await startPlayback();
    }
  }

  /// 格式化毫秒 → "M:SS" (单数字也补 0)
  String _formatDuration(int? ms) {
    if (ms == null) return '0:00';
    final seconds = (ms / 1000).floor();
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final snap = widget.controller.snapshot.value;
    final hasRecording = snap.audioPath != null;
    final maxReached = _audioDurationMs != null && _audioDurationMs! >= 180000;

    return Container(
      padding: AppTokens.edgeInsetsSm,
      decoration: BoxDecoration(
        color: AppTokens.surfaceColor(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 录音控制行
          Row(
            children: [
              // 录音 / 停止按钮
              PressFeedback(
                child: Material(
                  color: AppColors.transparent,
                  child: InkWell(
                    onTap: _toggleRecord,
                    borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                    child: Container(
                      // v0.24 round 48 (emil P2-4): 走 spacingChipPadding token
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spacingChipPaddingH,
                        vertical: AppTokens.spacingChipPaddingV,
                      ),
                      decoration: BoxDecoration(
                        color: isRecording
                            ? AppTokens.errorColor(context)
                            : Theme.of(context).colorScheme.primary,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusChip),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRecording ? Icons.stop : Icons.mic,
                            size: AppTokens.iconSizeInline,
                            color: AppTokens.fgOnPrimary(context),
                          ),
                          const SizedBox(width: AppTokens.spacingXxs),
                          Text(
                            isRecording
                                ? l10n.commonCancel
                                : l10n.moodAudioRecordButton,
                            style: TextStyle(
                              color: AppTokens.fgOnPrimary(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.spacingSm),
              if (isRecording) ...[
                // R102 (P1): 用 _RecordingTimer 独立 widget 替代内联 Text
                // 之前 onTick → setState(() {}) 每 100ms 重建整个 widget (537 行)
                // 现在只有 _RecordingTimer (30 行) rebuild, 其余 UI 不受影响
                _RecordingTimer(
                  service: ref.read(moodAudioServiceProvider),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                if (_sttAvailable)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: AppTokens.legendDotSizeLg,
                        height: AppTokens.legendDotSizeLg,
                        child: LoadingSpinner(
                          size: AppTokens.legendDotSizeLg,
                          color: AppTokens.textHintColor(context),
                        ),
                      ),
                      const SizedBox(width: AppTokens.spacingXxs),
                      Text(
                        l10n.moodAudioSttListening,
                        style: AppTokens.textStyleCaptionHint(context),
                      ),
                    ],
                  ),
              ] else if (hasRecording) ...[
                Text(
                  l10n.moodAudioRecorded(_formatDuration(snap.audioDurationMs)),
                  style: AppTokens.textStyleBody(context),
                ),
              ],
              const Spacer(),
              if (hasRecording && !isRecording) ...[
                // v0.27 round 62 (P1-15 修复): 改用 PressFeedbackIconButton 集中器
                PressFeedbackIconButton(
                  onPressed: _togglePlay,
                  icon: isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Theme.of(context).colorScheme.primary,
                  tooltip: l10n.moodAudioPlayAction,
                ),
                PressFeedbackIconButton(
                  onPressed: _reRecord,
                  icon: Icons.refresh,
                  color: AppTokens.textSecondaryColor(context),
                  tooltip: l10n.moodAudioRerecord,
                ),
              ],
            ],
          ),
          // 录音中提示
          if (isRecording && maxReached) ...[
            const SizedBox(height: AppTokens.spacingXs),
            Text(
              l10n.moodAudioMaxReached,
              // v0.27 round 61 (P2): 走 textStyleCaption + copyWith 注入 error 色
              // 之前 inline TextStyle, 6 处 magic 走 token
              style: AppTokens.textStyleCaption(context).copyWith(
                color: AppTokens.errorColor(context),
              ),
            ),
          ],
          // 实时识别文字
          if (isRecording && _liveTranscript.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spacingXs),
            Text(
              _liveTranscript,
              style: AppTokens.textStyleCaption(context).copyWith(
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // 录完识别文字
          if (!isRecording && hasRecording && _finalTranscript.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spacingXs),
            Text(
              '${l10n.moodAudioTranscriptLabel}: $_finalTranscript',
              style: AppTokens.textStyleCaption(context),
            ),
            if (snap.audioDurationMs != null &&
                snap.audioDurationMs! > 60000) ...[
              const SizedBox(height: AppTokens.spacingXxxs),
              Text(
                l10n.moodAudioTranscriptPartialHint,
                // v0.27 round 61 (P2): 走 textStyleCaptionHint
                // (fontSizeCaptionSm=12 + hint color), 替代之前 fontSizeCaption-1=13 magic
                style: AppTokens.textStyleCaptionHint(context),
              ),
            ],
          ],
          if (!isRecording && hasRecording && _sttFailed) ...[
            const SizedBox(height: AppTokens.spacingXs),
            Text(
              l10n.moodAudioSttFailed,
              style: AppTokens.textStyleCaptionHint(context),
            ),
          ],
          // STT 不可用提示 (仅在还没录音时显示)
          if (!isRecording && !hasRecording && !_sttAvailable) ...[
            const SizedBox(height: AppTokens.spacingXs),
            Text(
              l10n.moodAudioSttUnavailable,
              // v0.27 round 61 (P2): 走 textStyleCaptionHint
              style: AppTokens.textStyleCaptionHint(context),
            ),
          ],
        ],
      ),
    );
  }
}

/// R102 (P1): 独立计时器 widget — 只有这个 widget 每 100ms rebuild
///
/// 之前 onTick → setState(() {}) 重建整个 MoodAudioRecorderWidget (537 行),
/// 现在只有这个 ~30 行的 widget rebuild, 其余录音控制 / STT / 播放 UI 不受影响。
class _RecordingTimer extends StatefulWidget {
  final MoodAudioService service;
  const _RecordingTimer({required this.service});

  @override
  State<_RecordingTimer> createState() => _RecordingTimerState();
}

class _RecordingTimerState extends State<_RecordingTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ms = widget.service.recordingElapsed.inMilliseconds;
    final seconds = (ms / 1000).floor();
    final m = (seconds ~/ 60).toString();
    final s = (seconds % 60).toString().padLeft(2, '0');
    return Text(
      '$m:$s',
      style: TextStyle(
        fontSize: AppTokens.fontSizeBody,
        color: AppTokens.textPrimaryColor(context),
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
