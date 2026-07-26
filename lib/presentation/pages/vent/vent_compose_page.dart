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
//
// v0.24 round 46 (emil B-13 god class 续拆): 从 537 行瘦身到 ~270 行 orchestrator
// 3 个 section widgets 已提取到 vent/widgets/:
//   - VentAudioSection (录音 / 播放 / 重录 3 态切换)
//   - VentTextInput (文字输入 + 字符计数)
//   - VentSaveBar (取消 / 保存按钮)
// audio 状态机保留在 orchestrator state (recorder + player + temp file 生命周期紧密)
library;

import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/pages/vent/widgets/vent_audio_section.dart';
import 'package:chroniccare/presentation/pages/vent/widgets/vent_text_input.dart';
import 'package:chroniccare/presentation/pages/vent/widgets/vent_save_bar.dart';

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

  /// P0-2: 播放时生成的临时解密文件路径,dispose 时清理
  String? _tempDecryptedPath;

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
      } catch (e, st) {
        // v0.22 round 30 (sp-en P1-3): 走 swallowError (app teardown 期间)
        swallowError(where: 'vent_compose_page.dispose', error: e, stack: st);
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
              AppSnackBar.showError(context,
                    action: AppLocalizations.of(context)
                        .snackbarActionEncryptRecording,
                    error: e);
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
          AppSnackBar.showError(context,
                action: AppLocalizations.of(context).snackbarActionRecord,
                error: e);
          setState(() => _isRecording = false);
        }
      }
    } else {
      // 检查权限
      try {
        final hasPerm = await _recorder.hasPermission();
        if (!hasPerm) {
          if (mounted) {
            AppSnackBar.showInfo(
                context,
                AppLocalizations.of(context).snackbarNeedMicPermission,);
          }
          return;
        }
        // P0-2 fix: 录音写到 OS 临时目录(明文),stop 后立刻加密
        // 存到 app docs/{dir}/vent_xxx.m4a.enc (DB 存的路径 = 加密路径)
        // 之前的版本直接写到 newAudioPath() 但那是 .m4a.enc 后缀,
        // record 写明文 m4a 会被理解为加密文件,bug。
        // v0.21 (P1-3 fix): 临时文件路径走 storage.newTempRecordPath() —
        // 同毫秒录 2 段也加 4 位 random suffix 避免覆盖, 跟 newAudioPath 一致。
        final storage = ref.read(ventAudioStorageProvider);
        final tempPath = await storage.newTempRecordPath();
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
          AppSnackBar.showError(context,
                action:
                    AppLocalizations.of(context).snackbarActionStartRecording,
                error: e);
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
      final tempPath = _tempDecryptedPath;
      // v0.24 round 48 (sp-en P1-10) refactor: stop + temp cleanup 抽到
      // top-level helper,加 try/catch + swallowError 防御 audioplayers
      // iOS 偶发 PlatformException (锁文件 / 系统打断 / 后台被杀)
      // 之前 stop 抛异常 → deleteTemp 不调 → temp m4a 泄漏
      await stopAndCleanup(
        stop: _player.stop,
        deleteTempFile: () async {
          if (tempPath != null) {
            await ref.read(ventAudioStorageProvider).deleteTempFile(tempPath);
          }
        },
        where: 'vent_compose_page._togglePlay',
      );
      _tempDecryptedPath = null;
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
        // v0.22 round 28 (spen-bug-02): 失败时清 temp file 避免堆积
        // (之前 _tempDecryptedPath 已被设, _player.play 抛异常时 temp 泄漏)
        if (_tempDecryptedPath != null) {
          try {
            await ref
                .read(ventAudioStorageProvider)
                .deleteTempFile(_tempDecryptedPath!);
          } catch (e, st) {
            // v0.22 round 30 (sp-en P1-3): 走 swallowError
            swallowError(
              where: 'vent_compose_page.failCleanup',
              error: e,
              stack: st,
            );
          }
          _tempDecryptedPath = null;
        }
        if (mounted) {
          AppSnackBar.showError(context,
                action: AppLocalizations.of(context).snackbarActionPlay,
                error: e);
        }
      }
    }
  }

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
      AppSnackBar.showInfo(
          context,
          AppLocalizations.of(context).snackbarEmptyVent,);
      return;
    }
    if (_isRecording) {
      AppSnackBar.showInfo(
          context,
          AppLocalizations.of(context).snackbarStopRecording,);
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
        AppSnackBar.showError(context,
              action: AppLocalizations.of(context).snackbarActionSave,
              error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppLocalizations.of(context).ventComposeTitle,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 顶部说明
            Text(
              AppLocalizations.of(context).ventEmptySubtitle,
              style: TextStyle(
                fontSize: AppTokens.fontSizeBody,
                color: AppTokens.textSecondaryColor(context),
                height: AppTokens.lineHeightNormal,
              ),
            ),
            const SizedBox(height: AppTokens.spacingMd),

            // 文字输入
            VentTextInput(
              controller: _textController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppTokens.spacingMd),

            // 录音 / 播放区域
            VentAudioSection(
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
            VentSaveBar(
              isSaving: _saving,
              saveLabel: AppLocalizations.of(context).ventComposeTitle,
              onCancel: () => context.pop(),
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// v0.24 round 48 (sp-en P1-10): 抽 stop + temp cleanup 为可测的 helper
//
// 之前 _togglePlay 的"暂停"分支直接 await _player.stop() + deleteTempFile,
// 没 try/catch。audioplayers 在 iOS 上偶发 PlatformException (锁文件 /
// 系统打断 / 后台被杀等),stop 抛异常会直接 propagate 出去,导致后续
// deleteTempFile 永远不调 → temp 文件泄漏 (DB 之外的 m4a 残留在 temp dir,
// 反复播放就堆一堆)。
//
// helper 把"stop + deleteTemp"封成 @visibleForTesting 的 top-level 函数,
// 测试可注入抛 PlatformException 的 stop callback,验证 deleteTemp 仍调用。
// RED 阶段 helper 没有 try/catch — 验证"stop 抛异常 → deleteTemp 仍被调"
// 这条 spec 当前实现不满足 → FAIL。
// ============================================================
@visibleForTesting
Future<void> stopAndCleanup({
  required Future<void> Function() stop,
  required Future<void> Function() deleteTempFile,
  required String where,
}) async {
  // v0.24 round 48 (sp-en P1-10) GREEN: 加 try/catch + swallowError
  // 之前: stop 抛异常直接 propagate, deleteTemp 不调 → temp 文件泄漏
  // 现在: stop 异常被吞,deleteTemp 仍跑, 异常仅 developer.log 记录
  try {
    await stop();
  } catch (e, st) {
    swallowError(where: '$where.stop', error: e, stack: st);
  }
  try {
    await deleteTempFile();
  } catch (e, st) {
    swallowError(where: '$where.deleteTemp', error: e, stack: st);
  }
}
