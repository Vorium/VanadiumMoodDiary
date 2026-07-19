// v0.15 (Round 18) 树洞撰写页
//
// 用户在这里：
// - 写文字（TextField，长文本，最大 2000 字）
// - 录语音（用 record 包，m4a 格式，存到 app docs/vent_audio/）
// - 同时有文字 + 语音也可以
// - 点"放进树洞"→ 保存到 DB
//
// UI 状态机：
// 1. 文字输入中（默认）
// 2. 录音中（红色按钮 + 波形进度条 + 时长）
// 3. 录音完成（显示"重新录"和"播放"按钮）
library;

import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:record/record.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';

class VentComposePage extends ConsumerStatefulWidget {
  const VentComposePage({super.key});

  @override
  ConsumerState<VentComposePage> createState() => _VentComposePageState();
}

class _VentComposePageState extends ConsumerState<VentComposePage> {
  final _textController = TextEditingController();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  bool _saving = false;
  bool _isRecording = false;
  String? _audioPath;
  int? _audioDurationSec;
  bool _isPlaying = false;
  StreamSubscription<void>? _playerCompleteSub;

  @override
  void initState() {
    super.initState();
    _playerCompleteSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _playerCompleteSub?.cancel();
    _textController.dispose();
    _recorder.dispose();
    _player.dispose();
    if (_tempDecryptedPath != null) {
      try {
        ref.read(ventAudioStorageProvider).deleteTempFile(_tempDecryptedPath!);
      } catch (_) {
        // provider scope may be gone during app teardown
      }
      _tempDecryptedPath = null;
    }
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_isRecording) {
      // 停止录音
      try {
        final plainPath = await _recorder.stop();
        if (plainPath != null && mounted) {
          // P0-2: 录音停下后立刻加密，原 m4a 删掉
          // 用 _audioPath 临时存加密后路径,UI 也用这个
          final storage = ref.read(ventAudioStorageProvider);
          final encryptedPath = await storage.newAudioPath();
          try {
            await storage.encryptAndWrite(
              plainPath: plainPath,
              encryptedPath: encryptedPath,
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                AppSnackBar.error(context, action: '加密录音', error: e),
              );
              // 加密失败 → 不保存音频，但 _isRecording 还是 false
              setState(() {
                _isRecording = false;
              });
            }
            return;
          }
          if (mounted) {
            setState(() {
              _audioPath = encryptedPath;
              _isRecording = false;
            });
            await _getAudioDuration(encryptedPath);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.error(context, action: '录音', error: e),
          );
          setState(() => _isRecording = false);
        }
      }
    } else {
      // 检查权限
      try {
        final hasPerm = await _recorder.hasPermission();
        if (!hasPerm) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              AppSnackBar.info(
                context,
                AppLocalizations.of(context).snackbarNeedMicPermission,
              ),
            );
          }
          return;
        }
        // P0-2 fix: 录音写到 OS 临时目录(明文),stop 后立刻加密
        // 存到 app docs/{dir}/vent_xxx.m4a.enc (DB 存的路径 = 加密路径)
        // 之前的版本直接写到 newAudioPath() 但那是 .m4a.enc 后缀,
        // record 写明文 m4a 会被理解为加密文件,bug。
        final storage = ref.read(ventAudioStorageProvider);
        final tempDirPath = await storage.getTempDirPath();
        final tempPath = p.join(
          tempDirPath,
          'vent_record_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc, // m4a (aac)
            bitRate: 64000,
            sampleRate: 44100,
          ),
          path: tempPath,
        );
        if (mounted) setState(() => _isRecording = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.error(context, action: '开始录音', error: e),
          );
        }
      }
    }
  }

  Future<void> _getAudioDuration(String path) async {
    // P0-2 fix: path 是 .m4a.enc,audioplayer 不能直接吃。
    // 先 decryptToTemp → 用 temp path 推时长 → 删 temp。
    // v0.16 round 19B: 用 try/finally 确保 player.dispose() 在异常路径也跑
    // 修前：setSource/getDuration 抛异常时直接走 catch，player 没 dispose → leak
    final player = AudioPlayer();
    String? tempForDuration;
    try {
      final storage = ref.read(ventAudioStorageProvider);
      tempForDuration = await storage.decryptToTemp(path);
      await player.setSource(DeviceFileSource(tempForDuration));
      final d = await player.getDuration();
      if (mounted && d != null) {
        setState(() {
          _audioDurationSec = d.inSeconds;
        });
      }
    } catch (e, st) {
      swallowError(
        where: 'vent_compose_page._getAudioDuration',
        error: e,
        stack: st,
        note: 'audio duration probe failed — non-critical',
      );
    } finally {
      await player.dispose();
      if (tempForDuration != null) {
        await ref
            .read(ventAudioStorageProvider)
            .deleteTempFile(tempForDuration);
      }
    }
  }

  Future<void> _togglePlay() async {
    if (_audioPath == null) return;
    if (_isPlaying) {
      await _player.stop();
      // 清理临时解密文件
      if (_tempDecryptedPath != null) {
        await ref
            .read(ventAudioStorageProvider)
            .deleteTempFile(_tempDecryptedPath!);
        _tempDecryptedPath = null;
      }
      if (mounted) setState(() => _isPlaying = false);
    } else {
      try {
        // P0-2: _audioPath 是 .m4a.enc 加密文件,audioplayer 不能直接播。
        // 先 decryptToTemp 到 temp dir,播完清。
        final storage = ref.read(ventAudioStorageProvider);
        final tempPath = await storage.decryptToTemp(_audioPath!);
        _tempDecryptedPath = tempPath;
        await _player.play(DeviceFileSource(tempPath));
        if (mounted) setState(() => _isPlaying = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            AppSnackBar.error(context, action: '播放', error: e),
          );
        }
      }
    }
  }

  /// P0-2: 播放时生成的临时解密文件路径,dispose 时清理
  String? _tempDecryptedPath;

  Future<void> _reRecord() async {
    // 停止正在播放的音频并清理临时文件
    if (_isPlaying) {
      await _player.stop();
    }
    if (_tempDecryptedPath != null) {
      await ref
          .read(ventAudioStorageProvider)
          .deleteTempFile(_tempDecryptedPath!);
      _tempDecryptedPath = null;
    }
    if (_audioPath != null) {
      final old = _audioPath!;
      // 删旧文件（DB 里还没存，所以可以删）
      try {
        await ref.read(ventAudioStorageProvider).deleteAudio(old);
      } catch (e, st) {
        // 文件可能已被用户/系统清掉；删失败不阻塞重录流程
        swallowError(
          where: 'vent_compose_page._reRecord',
          error: e,
          stack: st,
          note: 'old audio delete failed, continuing re-record',
        );
      }
    }
    if (mounted) {
      setState(() {
        _audioPath = null;
        _audioDurationSec = null;
        _isPlaying = false;
      });
    }
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    final hasText = text.isNotEmpty;
    final hasAudio = _audioPath != null;
    if (!hasText && !hasAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.info(
          context,
          AppLocalizations.of(context).snackbarEmptyVent,
        ),
      );
      return;
    }
    if (_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar.info(
          context,
          AppLocalizations.of(context).snackbarStopRecording,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      int? sizeBytes;
      if (hasAudio) {
        try {
          sizeBytes = await ref
              .read(ventAudioStorageProvider)
              .fileSizeBytes(_audioPath!);
        } catch (e, st) {
          // size 读不到(可能文件被外部清掉),sizeBytes 留 null,DB 仍能存
          swallowError(
            where: 'vent_compose_page._onSave',
            error: e,
            stack: st,
            note: 'audio file size unreadable, sizeBytes=null',
          );
        }
      }
      await ref.read(ventRepositoryProvider).add(
            text: hasText ? text : null,
            audioPath: hasAudio ? _audioPath : null,
            audioDurationSec: _audioDurationSec,
            audioSizeBytes: sizeBytes,
          );
      if (mounted) {
        context.pop(); // 回到列表
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error(context, action: '保存', error: e),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textLen = _textController.text.length;
    return PageScaffold(
      title: '放进树洞',
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部说明
            const Text(
              '想说什么就说出来。文字、语音都可以。\n这些话只有你自己能看到。',
              style: TextStyle(
                fontSize: AppTokens.fontSizeBody,
                color: AppTokens.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppTokens.spacingMd),

            // 文字输入
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                maxLength: 2000,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: AppTokens.fontSizeBody),
                decoration: const InputDecoration(
                  hintText: '今天过得怎么样……',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(AppTokens.spacingSm),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (textLen > 1800)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '$textLen / 2000',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color:
                        textLen > 2000 ? AppTokens.error : AppTokens.textHint,
                  ),
                ),
              ),

            const SizedBox(height: AppTokens.spacingMd),

            // 录音 / 播放区域
            _AudioSection(
              isRecording: _isRecording,
              audioPath: _audioPath,
              audioDurationSec: _audioDurationSec,
              isPlaying: _isPlaying,
              onToggleRecord: _toggleRecord,
              onTogglePlay: _togglePlay,
              onReRecord: _reRecord,
            ),

            const SizedBox(height: AppTokens.spacingMd),

            // 保存按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => context.pop(),
                    child: Text(AppLocalizations.of(context).commonCancel),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Text('放进树洞'),
                        if (_saving)
                          const IgnorePointer(
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioSection extends StatelessWidget {
  final bool isRecording;
  final String? audioPath;
  final int? audioDurationSec;
  final bool isPlaying;
  final VoidCallback onToggleRecord;
  final VoidCallback onTogglePlay;
  final VoidCallback onReRecord;

  const _AudioSection({
    required this.isRecording,
    required this.audioPath,
    required this.audioDurationSec,
    required this.isPlaying,
    required this.onToggleRecord,
    required this.onTogglePlay,
    required this.onReRecord,
  });

  @override
  Widget build(BuildContext context) {
    if (audioPath == null) {
      // 没有录音
      return Center(
        child: TextButton.icon(
          onPressed: isRecording ? null : onToggleRecord,
          icon: Icon(
            isRecording ? Icons.stop_circle : Icons.mic,
            color: isRecording ? AppTokens.error : AppTokens.primary,
            size: 28,
          ),
          label: Text(
            isRecording ? '正在录音… 点停止' : '按一下开始录音',
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: isRecording ? AppTokens.error : AppTokens.primary,
            ),
          ),
        ),
      );
    }
    // 有录音：显示播放 / 重录
    return Container(
      padding: const EdgeInsets.all(AppTokens.spacingSm),
      decoration: BoxDecoration(
        color: AppTokens.primaryLight,
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isPlaying ? Icons.stop : Icons.play_arrow,
              color: AppTokens.primary,
            ),
            onPressed: onTogglePlay,
          ),
          const Icon(Icons.mic, color: AppTokens.primary, size: 18),
          const SizedBox(width: 6),
          Text(
            audioDurationSec != null ? _formatSec(audioDurationSec!) : '录音',
            style: const TextStyle(
              fontSize: AppTokens.fontSizeBody,
              color: AppTokens.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onReRecord,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('重录'),
            style: TextButton.styleFrom(
              foregroundColor: AppTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSec(int sec) {
    if (sec < 60) return '$sec秒';
    final m = sec ~/ 60;
    final s = sec % 60;
    return s == 0 ? '$m分' : '$m分${s.toString().padLeft(2, '0')}秒';
  }
}
