// v0.24 Sprint #5 (emil): 抽 MoodRecorder 子 widget
//
// **从 mood_dialog.dart god class 抽出录音 + STT 状态机**
//
// 原 706 行文件里 1 个 `_MoodDialogContentState` 同时管:
// - 4 维度评分 / 标签 / 文字 / 录音状态机 / STT 流 / 临时文件清理 /
//   AudioPlayer / 2 StreamSubscription
//
// 拆解后: 评分/标签/文字在 orchestrator, **录音状态机完整下沉到 MoodRecorder**。
// parent 通过 [snapshot] 拉最终数据 (audioPath / durationMs / finalTranscript),
// 通过 [toggleRecord] / [togglePlay] / [reRecord] 触发动作, 99% 副作用不外泄。
//
// emil 设计决策 (decisions should be nameable):
// 1. **不用 Riverpod StateNotifier** — dialog scope, ValueNotifier 已够
// 2. **MoodRecorderController 暴露 snapshot** (ValueListenable) + 3 method
// 3. **dispose 链完整** — recorder / player / 2 StreamSubscription / temp file
//    / service 全在 MoodRecorder 内部清理
// 4. **保留所有 P0 修复**:
//    - snackbar 显示走 parent context (parent 显式传入 l10n key), recorder 内
//      调 onError callback 让 parent 展示
//    - AudioPlayer dispose 顺序 (stop → dispose)
//    - EncryptedAudioStorage temp cleanup
//    - swallowError 模式
//    - _isRecording 时 cancelRecording on dispose
//    - STT failed graceful degrade
// 5. **maxReached 下沉** — 录音中 180s 到时提示由 recorder 内部计算
//
// 频度: tens/day (mood 录入是核心动作), 录音中 100ms tick 触发局部 rebuild
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/data/services/mood_audio_service.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/mood_providers.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

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

/// 录音机 widget — 自管 idle/recording/recorded/playing 状态机
class MoodRecorder extends ConsumerStatefulWidget {
  final MoodRecorderController controller;

  const MoodRecorder({super.key, required this.controller});

  @override
  ConsumerState<MoodRecorder> createState() => _MoodRecorderState();
}

class _MoodRecorderState extends ConsumerState<MoodRecorder> {
  // ===== 内部录音状态 =====
  bool _isRecording = false;
  bool _isPlaying = false;
  String _liveTranscript = '';
  String _finalTranscript = '';
  int? _audioDurationMs;
  bool _sttAvailable = false;
  bool _sttFailed = false;

  // 临时解密播放文件, dispose 时清理
  String? _tempDecryptedPath;

  // Player + subscription
  late final AudioPlayer _player;
  StreamSubscription<void>? _playerCompleteSub;
  StreamSubscription<String>? _sttSub;

  MoodAudioService get _service =>
      widget.controller.serviceFactory?.call() ??
      ref.read(moodAudioServiceProvider);

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _playerCompleteSub = _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
    });
    // 初始化 STT (异步, 不阻塞 UI)
    _initializeStt();
  }

  Future<void> _initializeStt() async {
    final ok = await _service.initialize();
    if (!mounted) return;
    setState(() => _sttAvailable = ok);
  }

  @override
  void dispose() {
    // v0.27 round 61 (P0-1 fix): 先同步设 _isRecording = false, 阻止
    // _disposeResources 链 (await service.cancelRecording) 触发的 onTick
    // / onMaxReached 回调 setState 撞 defunct assert。dispose 之前
    // _isRecording=true 是 race 条件源: service.stopRecording 内部仍可能
    // 走完一次 onTick, 该 setState 落到 disposed widget 触发 assert。
    // 同步 set 之后所有后续检查 `if (_isRecording)` 都返 false, 安全跳过。
    _isRecording = false;
    _playerCompleteSub?.cancel();
    _sttSub?.cancel();
    // v0.25 round 52 (spen P0 #7): State.dispose() 是 sync, 不能 await future,
    // 但 fire-and-forget 必须显式 unawaited 标记 (避免 unhandled async error
    // 跟 implicit linter warning)。race 风险: widget 已 defunct 时 future
    // 仍可能跑 — 每个都 catchError 走 swallowError 兜底 + unawaited 跟踪。
    unawaited(
      _disposeResources().catchError((Object e, StackTrace st) {
        swallowError(
          where: 'mood_recorder.dispose._disposeResources',
          error: e,
          stack: st,
          note: 'dispose resources chain failed',
        );
      }),
    );
    super.dispose();
  }

  /// 顺序释放: 停 player → 清理临时文件 → cancel recording → service dispose
  /// 之前 4 个 fire-and-forget 是 race (spen P0 #7), 现在串行 + 显式 await。
  Future<void> _disposeResources() async {
    // 1) 停 player (如果还在播)
    try {
      await _player.stop();
      await _player.dispose();
    } catch (e, st) {
      swallowError(
        where: 'mood_recorder.dispose.playerStop',
        error: e,
        stack: st,
      );
    }
    // 2) 清理临时解密文件
    if (_tempDecryptedPath != null) {
      try {
        await ref
            .read(moodAudioStorageProvider)
            .deleteTempFile(_tempDecryptedPath!);
      } catch (e, st) {
        swallowError(
          where: 'mood_recorder.dispose.deleteTemp',
          error: e,
          stack: st,
        );
      }
    }
    // 3) 取消录音 (如果还在录)
    if (_isRecording) {
      try {
        await _service.cancelRecording();
      } catch (e, st) {
        swallowError(
          where: 'mood_recorder.dispose.cancelRecording',
          error: e,
          stack: st,
          note: 'cancel recording on dispose failed',
        );
      }
    }
    // 4) service dispose (释放 AudioRecorder + SpeechToText)
    try {
      await _service.dispose();
    } catch (e, st) {
      swallowError(
        where: 'mood_recorder.dispose.service',
        error: e,
        stack: st,
      );
    }
  }

  // ===== 录音流程 =====

  Future<void> _toggleRecord() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _isRecording = true;
        _liveTranscript = '';
        _finalTranscript = '';
        _sttFailed = false;
      });
      // 订阅 STT 流
      _sttSub?.cancel();
      _sttSub = _service.sttTranscriptStream.listen((text) {
        if (!mounted) return;
        setState(() => _liveTranscript = text);
      });

      await _service.startRecording(
        onTick: (elapsed) {
          if (!mounted) return;
          setState(() {}); // 触发 UI 重建, 显示计时器
        },
        onMaxReached: () {
          if (!mounted) return;
          // 3min 自动停
          _stopRecording();
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRecording = false);
      widget.controller.onError?.call(e, MoodRecorderErrorKind.start);
    }
  }

  Future<void> _stopRecording() async {
    try {
      final result = await _service.stopRecording();
      // STT 停止
      try {
        await _service.stopStt();
      } catch (e, st) {
        swallowError(
          where: 'mood_recorder.stopStt',
          error: e,
          stack: st,
          note: 'STT stop failed',
        );
      }
      _sttSub?.cancel();
      _sttSub = null;

      if (result == null) {
        if (!mounted) return;
        setState(() => _isRecording = false);
        return;
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
        if (!mounted) return;
        setState(() => _isRecording = false);
        widget.controller.onError?.call(e, MoodRecorderErrorKind.encrypt);
        return;
      }

      // final transcript: 由 sttTranscriptStream 最后一条推送决定
      final transcript = _liveTranscript;
      final sttFailed = transcript.isEmpty && _sttAvailable;

      if (!mounted) return;
      setState(() {
        _isRecording = false;
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRecording = false);
      widget.controller.onError?.call(e, MoodRecorderErrorKind.stop);
    }
  }

  Future<void> _reRecord() async {
    if (_isPlaying) {
      await _player.stop();
      if (_tempDecryptedPath != null) {
        await ref
            .read(moodAudioStorageProvider)
            .deleteTempFile(_tempDecryptedPath!);
        _tempDecryptedPath = null;
      }
    }
    final previousPath = widget.controller.snapshot.value.audioPath;
    if (previousPath != null) {
      await ref.read(moodAudioStorageProvider).deleteAudio(previousPath);
    }
    if (!mounted) return;
    setState(() {
      _audioDurationMs = null;
      _finalTranscript = '';
      _liveTranscript = '';
      _isPlaying = false;
      _sttFailed = false;
    });
    widget.controller.snapshot.value = MoodRecorderSnapshot.empty;
  }

  // ===== 播放 =====
  Future<void> _togglePlay() async {
    final audioPath = widget.controller.snapshot.value.audioPath;
    if (audioPath == null) return;
    if (_isPlaying) {
      await _player.stop();
      if (_tempDecryptedPath != null) {
        await ref
            .read(moodAudioStorageProvider)
            .deleteTempFile(_tempDecryptedPath!);
        _tempDecryptedPath = null;
      }
      if (mounted) setState(() => _isPlaying = false);
      return;
    }
    try {
      final storage = ref.read(moodAudioStorageProvider);
      final tempPath = await storage.decryptToTemp(audioPath);
      _tempDecryptedPath = tempPath;
      await _player.play(DeviceFileSource(tempPath));
      if (mounted) setState(() => _isPlaying = true);
    } catch (e) {
      if (_tempDecryptedPath != null) {
        try {
          await ref
              .read(moodAudioStorageProvider)
              .deleteTempFile(_tempDecryptedPath!);
        } catch (e2, st) {
          swallowError(
            where: 'mood_recorder.failCleanup',
            error: e2,
            stack: st,
          );
        }
        _tempDecryptedPath = null;
      }
      if (!mounted) return;
      setState(() => _isPlaying = false);
      widget.controller.onError?.call(e, MoodRecorderErrorKind.play);
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
    final maxReached =
        _audioDurationMs != null && _audioDurationMs! >= 180000;

    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingSm),
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
                  color: Colors.transparent,
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
                        color: _isRecording
                            ? AppTokens.errorColor(context)
                            : Theme.of(context).colorScheme.primary,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusChip),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            size: AppTokens.iconSizeInline,
                            color: AppTokens.fgOnPrimary(context),
                          ),
                          const SizedBox(width: AppTokens.spacingXxs),
                          Text(
                            _isRecording
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
              if (_isRecording) ...[
                // v0.23 (Round 31): 录音中从 service.recordingElapsed 拿计时
                Text(
                  _formatDuration(
                    ref
                        .read(moodAudioServiceProvider)
                        .recordingElapsed
                        .inMilliseconds,
                  ),
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    color: AppTokens.textPrimaryColor(context),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                if (_sttAvailable)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: LoadingSpinner(
                          size: 12,
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
              if (hasRecording && !_isRecording) ...[
                // v0.27 round 62 (P1-15 修复): 改用 PressFeedbackIconButton 集中器
                PressFeedbackIconButton(
                  onPressed: _togglePlay,
                  icon: _isPlaying ? Icons.pause : Icons.play_arrow,
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
          if (_isRecording && maxReached) ...[
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
          if (_isRecording && _liveTranscript.isNotEmpty) ...[
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
          if (!_isRecording &&
              hasRecording &&
              _finalTranscript.isNotEmpty) ...[
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
          if (!_isRecording && hasRecording && _sttFailed) ...[
            const SizedBox(height: AppTokens.spacingXs),
            Text(
              l10n.moodAudioSttFailed,
              style: AppTokens.textStyleCaptionHint(context),
            ),
          ],
          // STT 不可用提示 (仅在还没录音时显示)
          if (!_isRecording && !hasRecording && !_sttAvailable) ...[
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

// MoodRecorder 内部消化录音状态机 — 副作用不外泄到 parent
// (saving 状态由 MoodDialogActions / orchestrator 持有, 不在 recorder 内)
