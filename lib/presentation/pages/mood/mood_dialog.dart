import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/data/services/mood_audio_service.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/mood_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/dimension_row.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/loading_text_button.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 情绪日记 dialog
///
/// v0.18 round 18 (P1-15) 升级 4 维度:
/// - 情绪 (mood): 1-5 分 (主轴, 必填)
/// - 精力 (energy): 1-5 分 (1=很低 5=充沛)
/// - 睡眠 (sleep): 1-5 分 (1=很差 5=很好)
/// - 焦虑 (anxiety): 1-5 分 (反向:1=严重 5=平静)
/// + 预设标签 (多选) + 自由备注
///
/// v0.23 (Round 31) 语音录入:
/// - 加录音按钮 (与文字备注并存, 互不影响)
/// - 录音中态: 红色按钮 + 计时器 + "识别中..." (STT partial 实时显示)
/// - 录完态: 时长 + 识别文字 + 重录 / 删除按钮
/// - 3min 自动停止 (UI 提示)
/// - STT 失败: graceful degrade (snackbar 提示, 录音仍正常保存)
/// - 保存后 snackbar 带 "回放" action
class MoodDialog {
  MoodDialog._();

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (_) => const _MoodDialogContent(),
    );
  }
}

/// 内部 widget — 抽出来管录音 + STT 状态机
///
/// 之前 mood_dialog 是 StatefulBuilder 局部 state,录音状态机复杂
/// (idle / recording / recorded / playing) 加 STT 实时流,放 StatefulBuilder
/// 容易失控。改成 ConsumerStatefulWidget,dispose 时统一清理
/// recorder / player / stream subscription。
class _MoodDialogContent extends ConsumerStatefulWidget {
  const _MoodDialogContent();

  @override
  ConsumerState<_MoodDialogContent> createState() => _MoodDialogContentState();
}

class _MoodDialogContentState extends ConsumerState<_MoodDialogContent> {
  // ===== 4 维度评分 =====
  int _score = 3;
  int _energy = 3;
  int _sleep = 3;
  int _anxiety = 3;
  final Set<String> _tags = {};

  // ===== 文字备注 =====
  late final TextEditingController _noteController;

  // ===== 录音状态机 =====
  bool _saving = false;
  bool _isRecording = false;
  String? _audioPath; // 加密文件路径 (.m4a.enc), 准备写入 DB
  int? _audioDurationMs;
  String _liveTranscript = ''; // 实时 STT partial
  String _finalTranscript = ''; // 录音结束时 STT final
  bool _isPlaying = false;
  bool _sttAvailable = false;
  bool _sttFailed = false; // 录音结束但 STT 失败 = 提示 1 句

  // 临时解密播放文件, dispose 时清理
  String? _tempDecryptedPath;

  // Player + subscription
  late final AudioPlayer _player;
  StreamSubscription<void>? _playerCompleteSub;
  StreamSubscription<String>? _sttSub;

  // service 是 widget 字段, 不存到 state, dispose 时取一次
  MoodAudioService get _service => ref.read(moodAudioServiceProvider);

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
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
    _playerCompleteSub?.cancel();
    _sttSub?.cancel();
    _noteController.dispose();
    // 取消录音 (如果还在录)
    if (_isRecording) {
      _service.cancelRecording().catchError((Object e, StackTrace st) {
        swallowError(
          where: 'mood_dialog.dispose',
          error: e,
          stack: st,
          note: 'cancel recording on dispose failed',
        );
      });
    }
    // 停 player + 清理临时文件
    _player.stop().then((_) {
      _player.dispose();
    }).catchError((Object e, StackTrace st) {
      swallowError(
        where: 'mood_dialog.dispose.playerStop',
        error: e,
        stack: st,
      );
    });
    if (_tempDecryptedPath != null) {
      ref
          .read(moodAudioStorageProvider)
          .deleteTempFile(_tempDecryptedPath!)
          .catchError((Object e, StackTrace st) {
        swallowError(
          where: 'mood_dialog.dispose.deleteTemp',
          error: e,
          stack: st,
        );
      });
    }
    // service dispose (释放 AudioRecorder + SpeechToText)
    _service.dispose().catchError((Object e, StackTrace st) {
      swallowError(
        where: 'mood_dialog.dispose.service',
        error: e,
        stack: st,
      );
    });
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(
          context,
          action: AppLocalizations.of(context).moodAudioErrorStart,
          error: e,
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final result = await _service.stopRecording();
      // STT 停止（最终文本由 stream 推送，不依赖返回值）
      try {
        await _service.stopStt();
      } catch (e, st) {
        swallowError(
          where: 'mood_dialog.stopStt',
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
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error(
            context,
            action: AppLocalizations.of(context).moodAudioErrorEncrypt,
            error: e,
          ),
        );
        return;
      }

      // final transcript: 由 sttTranscriptStream 最后一条推送决定
      final transcript = _liveTranscript;
      final sttFailed = transcript.isEmpty && _sttAvailable;

      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _audioPath = encryptedPath;
        _audioDurationMs = result.durationMs;
        _finalTranscript = transcript;
        _sttFailed = sttFailed;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRecording = false);
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(
          context,
          action: AppLocalizations.of(context).moodAudioErrorStop,
          error: e,
        ),
      );
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
    if (_audioPath != null) {
      await ref.read(moodAudioStorageProvider).deleteAudio(_audioPath!);
    }
    if (!mounted) return;
    setState(() {
      _audioPath = null;
      _audioDurationMs = null;
      _finalTranscript = '';
      _liveTranscript = '';
      _isPlaying = false;
      _sttFailed = false;
    });
  }

  // ===== 播放 =====
  Future<void> _togglePlay() async {
    if (_audioPath == null) return;
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
      final tempPath = await storage.decryptToTemp(_audioPath!);
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
            where: 'mood_dialog.failCleanup',
            error: e2,
            stack: st,
          );
        }
        _tempDecryptedPath = null;
      }
      if (!mounted) return;
      setState(() => _isPlaying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(
          context,
          action: AppLocalizations.of(context).moodAudioErrorPlay,
          error: e,
        ),
      );
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

  // ===== 保存 =====
  Future<void> _save() async {
    final hasText = _noteController.text.trim().isNotEmpty;
    final hasAudio = _audioPath != null;
    if (!hasText && !hasAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.info(
          context,
          AppLocalizations.of(context).moodNoteHint,
        ),
      );
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    final savedAudioPath = _audioPath;
    try {
      await ref.read(moodRepositoryProvider).add(
            score: _score,
            tags: _tags.toList(),
            note: hasText ? _noteController.text.trim() : null,
            energy: _energy,
            sleep: _sleep,
            anxiety: _anxiety,
            audioPath: savedAudioPath,
            audioTranscript: _finalTranscript.isEmpty ? null : _finalTranscript,
            audioDurationMs: _audioDurationMs,
          );
      if (!mounted) return;
      // 先展示 snackbar，再 pop — pop 后 context 可能已失效
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.info(
          context,
          AppLocalizations.of(context).moodAudioSavedWithPlay,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.error(
          context,
          action: AppLocalizations.of(context).snackbarActionSave,
          error: e,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final presetTags = [
      l10n.moodTagAnxiety,
      l10n.moodTagDepression,
      l10n.moodTagCalm,
      l10n.moodTagInsomnia,
      l10n.moodTagIrritable,
      l10n.moodTagLowEnergy,
    ];
    return AlertDialog(
      title: Text(l10n.moodDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DimensionRow(
              label: l10n.moodDimensionMood,
              hint: l10n.moodDimensionMoodHint,
              value: _score,
              onChanged: (v) => setState(() => _score = v),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            DimensionRow(
              label: l10n.moodDimensionEnergy,
              hint: l10n.moodDimensionEnergyHint,
              value: _energy,
              onChanged: (v) => setState(() => _energy = v),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            DimensionRow(
              label: l10n.moodDimensionSleep,
              hint: l10n.moodDimensionSleepHint,
              value: _sleep,
              onChanged: (v) => setState(() => _sleep = v),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            DimensionRow(
              label: l10n.moodDimensionAnxiety,
              hint: l10n.moodDimensionAnxietyHint,
              value: _anxiety,
              onChanged: (v) => setState(() => _anxiety = v),
            ),
            const SizedBox(height: AppTokens.spacingMd),
            const Divider(height: 1),
            const SizedBox(height: AppTokens.spacingSm),
            // 预设标签
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final tag in presetTags)
                  FilterChip(
                    label: Text(tag),
                    selected: _tags.contains(tag),
                    onSelected: (sel) {
                      setState(() {
                        if (sel) {
                          _tags.add(tag);
                        } else {
                          _tags.remove(tag);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingSm),
            // 文字备注
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.moodNoteLabel,
                hintText: l10n.moodNoteHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            // v0.23 (Round 31) 语音录入区
            _MoodAudioSection(
              isRecording: _isRecording,
              audioPath: _audioPath,
              audioDurationMs: _audioDurationMs,
              isPlaying: _isPlaying,
              liveTranscript: _liveTranscript,
              finalTranscript: _finalTranscript,
              sttAvailable: _sttAvailable,
              sttFailed: _sttFailed,
              maxReached:
                  _audioDurationMs != null && _audioDurationMs! >= 180000,
              onToggleRecord: _toggleRecord,
              onTogglePlay: _togglePlay,
              onReRecord: _reRecord,
              formatDuration: _formatDuration,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        LoadingTextButton(
          label: l10n.commonSave,
          isLoading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}

/// 语音录入区: 按钮 / 录音中 / 录完 / 重录 / 播放
///
/// 状态机:
/// - 无录音 + 未在录: 显示"录语音"按钮
/// - 录音中: 红色"停止"按钮 + 计时器 + 实时 STT partial
/// - 录完: 时长 + 识别文字 + 播放 / 重录 按钮
class _MoodAudioSection extends ConsumerWidget {
  final bool isRecording;
  final String? audioPath;
  final int? audioDurationMs;
  final bool isPlaying;
  final String liveTranscript;
  final String finalTranscript;
  final bool sttAvailable;
  final bool sttFailed;
  final bool maxReached;
  final VoidCallback onToggleRecord;
  final VoidCallback onTogglePlay;
  final VoidCallback onReRecord;
  final String Function(int?) formatDuration;

  const _MoodAudioSection({
    required this.isRecording,
    required this.audioPath,
    required this.audioDurationMs,
    required this.isPlaying,
    required this.liveTranscript,
    required this.finalTranscript,
    required this.sttAvailable,
    required this.sttFailed,
    required this.maxReached,
    required this.onToggleRecord,
    required this.onTogglePlay,
    required this.onReRecord,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasRecording = audioPath != null;
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
                    onTap: onToggleRecord,
                    borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isRecording
                            ? AppTokens.error
                            : Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRecording ? Icons.stop : Icons.mic,
                            size: 18,
                            color: AppTokens.fgOnPrimary(context),
                          ),
                          const SizedBox(width: 4),
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
                // v0.23 (Round 31): 录音中从 service.recordingElapsed 拿计时
                // (audioDurationMs 录音未停时还是 null,不能直接用)
                // parent _MoodDialogContentState.startRecording() 的 onTick 100ms 触发
                // setState({}) 让整个 widget tree rebuild,这里直接 ref.read 拿。
                Text(
                  formatDuration(
                    ref.read(moodAudioServiceProvider).recordingElapsed.inMilliseconds,
                  ),
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    color: AppTokens.textPrimaryColor(context),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                if (sttAvailable)
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
                      const SizedBox(width: 4),
                      Text(
                        l10n.moodAudioSttListening,
                        style: AppTokens.textStyleCaptionHint(context),
                      ),
                    ],
                  ),
              ] else if (hasRecording) ...[
                Text(
                  l10n.moodAudioRecorded(formatDuration(audioDurationMs)),
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    color: AppTokens.textPrimaryColor(context),
                  ),
                ),
              ],
              const Spacer(),
              if (hasRecording && !isRecording) ...[
                IconButton(
                  onPressed: onTogglePlay,
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: l10n.moodAudioPlayAction,
                ),
                IconButton(
                  onPressed: onReRecord,
                  icon: Icon(
                    Icons.refresh,
                    color: AppTokens.textSecondaryColor(context),
                  ),
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
              style: const TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: AppTokens.error,
              ),
            ),
          ],
          // 实时识别文字
          if (isRecording && liveTranscript.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spacingXs),
            Text(
              liveTranscript,
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: AppTokens.textSecondaryColor(context),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          // 录完识别文字
          if (!isRecording && hasRecording && finalTranscript.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spacingXs),
            Text(
              '${l10n.moodAudioTranscriptLabel}: $finalTranscript',
              style: AppTokens.textStyleCaption(context),
            ),
            if (audioDurationMs != null && audioDurationMs! > 60000) ...[
              const SizedBox(height: 2),
              Text(
                l10n.moodAudioTranscriptPartialHint,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeCaption - 1,
                  color: AppTokens.textHintColor(context),
                ),
              ),
            ],
          ],
          if (!isRecording && hasRecording && sttFailed) ...[
            const SizedBox(height: AppTokens.spacingXs),
            Text(
              l10n.moodAudioSttFailed,
              style: AppTokens.textStyleCaptionHint(context),
            ),
          ],
          // STT 不可用提示 (仅在还没录音时显示)
          if (!isRecording && !hasRecording && !sttAvailable) ...[
            const SizedBox(height: AppTokens.spacingXs),
            Text(
              l10n.moodAudioSttUnavailable,
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: AppTokens.textHintColor(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 录音中时 audioDurationMs 还没拿到,用 ref.watch(moodAudioServiceProvider)
  /// 拿 service.recordingElapsed(每 100ms tick 一次,触发 ConsumerWidget 重建)。
  /// 录音停止后走 audioDurationMs。
}
