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
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

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
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_isRecording) {
      // 停止录音
      try {
        final path = await _recorder.stop();
        if (path != null && mounted) {
          setState(() {
            _audioPath = path;
            _isRecording = false;
          });
          await _getAudioDuration(path);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('录音失败：$e')),
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
              const SnackBar(content: Text('需要麦克风权限')),
            );
          }
          return;
        }
        // 生成新路径
        final storage = ref.read(ventAudioStorageProvider);
        final path = await storage.newAudioPath();
        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc, // m4a (aac)
            bitRate: 64000,
            sampleRate: 44100,
          ),
          path: path,
        );
        if (mounted) setState(() => _isRecording = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('开始录音失败：$e')),
          );
        }
      }
    }
  }

  Future<void> _getAudioDuration(String path) async {
    // 用 audioplayers 探测时长
    // v0.16 round 19B: 用 try/finally 确保 player.dispose() 在异常路径也跑
    // 修前：setSource/getDuration 抛异常时直接走 catch，player 没 dispose → leak
    final player = AudioPlayer();
    try {
      await player.setSource(DeviceFileSource(path));
      final d = await player.getDuration();
      if (mounted && d != null) {
        setState(() {
          _audioDurationSec = d.inSeconds;
        });
      }
    } catch (_) {
      // 时长探测失败不影响保存
    } finally {
      await player.dispose();
    }
  }

  Future<void> _togglePlay() async {
    if (_audioPath == null) return;
    if (_isPlaying) {
      await _player.stop();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      try {
        await _player.play(DeviceFileSource(_audioPath!));
        if (mounted) setState(() => _isPlaying = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('播放失败：$e')),
          );
        }
      }
    }
  }

  Future<void> _reRecord() async {
    if (_audioPath != null) {
      final old = _audioPath!;
      // 删旧文件（DB 里还没存，所以可以删）
      try {
        final f = File(old);
        if (await f.exists()) await f.delete();
      } catch (e, st) {
        // 文件可能已被用户/系统清掉;删失败不阻塞重录流程
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
        const SnackBar(content: Text('写点东西或录一段吧')),
      );
      return;
    }
    if (_isRecording) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先停止录音')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      int? sizeBytes;
      if (hasAudio) {
        try {
          sizeBytes = await File(_audioPath!).length();
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
          SnackBar(content: Text('保存失败：$e')),
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
