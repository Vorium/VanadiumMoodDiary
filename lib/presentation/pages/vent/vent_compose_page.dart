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
//
// v0.30 R108 (P1 god class 拆 6 大 F - Fix #1): audio state machine 抽
// `lib/presentation/widgets/audio_lifecycle.dart` AudioLifecycleMixin。
// - 4 状态字段 (_isRecording / _isPlaying / _audioPath / _tempDecryptedPath) 走 mixin
// - _asyncDispose 50 行 4 步链走 mixin.asyncDisposeAudio
// - _toggleRecord / _togglePlay / _reRecord 简化, 调 mixin 状态机方法
// - 4 抽象方法 (startRecordingImpl / stopRecordingImpl / startPlaybackImpl /
//   stopPlaybackImpl) 保留 vent 特有业务 (权限检查 / 加密 / decryptToTemp)
// - 行数 495 → 327 (减 168, 重复代码消除)

import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/core/data/services/vent_audio_storage.dart';
import 'package:chroniccare/core/shared/error_sinks.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/audio_lifecycle.dart';
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

class _VentComposePageState extends ConsumerState<VentComposePage>
    with AudioLifecycleMixin<VentComposePage> {
  final _textController = TextEditingController();
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();

  bool _saving = false;

  /// vent 特有: 录音时长 (秒), 调 _getAudioDuration() 拿到
  ///
  /// mood 用 millisecond, vent 用 second (跟 vent_audio_section 显示一致),
  /// 留在 widget 层不抽 mixin (audio_lifecycle 不耦合单位)
  int? _audioDurationSec;

  /// v0.32 R112 (E-01): B1-11 同款字段缓存 — dispose 链 (mixin
  /// asyncDisposeAudio 第 6 步 cleanupTempFile) 在 widget unmount 后才跑,
  /// 那时 ref.read 抛 StateError (Riverpod 3.4.2 无条件, release 也抛) 被
  /// swallowError 吞 → 播放后离开页面 temp 解密明文文件永不删 (PIPL §28)。
  /// initState 把 storage 捕获进字段, cleanupTempFile 只用字段不碰 ref。
  VentAudioStorage? _storage;

  @override
  void initState() {
    super.initState();
    // E-01 字段缓存: ref.read 只在 initState 合法, 这里一次性捕获
    _storage = ref.read(ventAudioStorageProvider);
    playerCompleteSub = _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => audioState = AudioState.recorded);
    });
  }

  @override
  void dispose() {
    // v0.28 R79 (R74 P2-1 修): 异步 dispose 用 unawaited 包装
    // 之前 _recorder.dispose() / _player.dispose() 是 Future, 调但不 await,
    // 离开 page 时这些 future 可能还没完成, audioplayers native 资源 (iOS
    // AudioPlayerImpl / Android AudioRecord) 释放不及时, 反复进/出 vent
    // compose page 会累积 native 资源句柄, 最终 OOM 或 audio session 异常。
    //
    // R108 Fix #1: asyncDisposeAudio 4 步链抽到 mixin, 这里只调
    // (order 内部 6 步: cancel stream → cancel timer → stop recorder if
    // recording → dispose recorder → stop + dispose player → delete temp).
    // 仍 unawaited 包装避免 State.dispose() 强制 sync 签名要求。
    unawaited(asyncDisposeAudio(player: _player, recorder: _recorder));
    // _textController.dispose() 同步, 立即调
    _textController.dispose();
    super.dispose();
  }

  // ===== AudioLifecycleMixin 4 抽象方法 + 1 override =====

  /// vent 录音权限检查 + 写明文 temp + 启动 recorder
  ///
  /// v0.21 (P1-3 fix): 临时文件路径走 storage.newTempRecordPath() —
  /// 同毫秒录 2 段也加 4 位 random suffix 避免覆盖, 跟 newAudioPath 一致。
  @override
  Future<bool> startRecordingImpl() async {
    // 1) 检查权限
    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      if (mounted) {
        AppSnackBar.showInfo(
          context,
          AppLocalizations.of(context).snackbarNeedMicPermission,
        );
      }
      // 返 false → mixin 回滚 state 到 idle
      return false;
    }
    // 2) 写到 OS 临时目录(明文), stop 后立刻加密
    // 存到 app docs/{dir}/vent_xxx.m4a.enc (DB 存的路径 = 加密路径)
    // P0-2 fix: 之前的版本直接写到 newAudioPath() 但那是 .m4a.enc 后缀,
    // record 写明文 m4a 会被理解为加密文件,bug。
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
    return true;
  }

  /// vent 停止录音 + 加密 + 推时长
  ///
  /// P0-2: 录音停下后立刻加密, 原 m4a 删掉
  /// 用 audioPath 临时存加密后路径, UI 也用这个
  @override
  Future<String?> stopRecordingImpl() async {
    final plainPath = await _recorder.stop();
    if (plainPath == null) return null;
    final storage = ref.read(ventAudioStorageProvider);
    final encryptedPath = await storage.newAudioPath();
    try {
      await storage.encryptAndWrite(
        plainPath: plainPath,
        encryptedPath: encryptedPath,
      );
    } catch (e) {
      // 加密失败 → 不保存音频, subclass 已 fire AppSnackBar
      if (mounted) {
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).snackbarActionEncryptRecording,
          error: e,
        );
      }
      return null;
    }
    // 推时长 (失败不影响主流程)
    if (mounted) {
      await _getAudioDuration(encryptedPath);
    }
    return encryptedPath;
  }

  /// vent decryptToTemp + 启动 player
  @override
  Future<void> startPlaybackImpl(String encryptedPath) async {
    // P0-2: _audioPath 是 .m4a.enc 加密文件, audioplayer 不能直接播。
    // 先 decryptToTemp 到 temp dir, 播完清。
    final storage = ref.read(ventAudioStorageProvider);
    final tempPath = await storage.decryptToTemp(encryptedPath);
    tempDecryptedPath = tempPath;
    await _player.play(DeviceFileSource(tempPath));
  }

  /// vent 停止 player
  @override
  Future<void> stopPlaybackImpl() async {
    await _player.stop();
  }

  /// vent 清理 temp 解密文件
  ///
  /// v0.32 R112 (E-01): 走 _storage (initState 捕获) 而非 ref.read —
  /// 本方法在 mixin.asyncDisposeAudio 第 6 步 (unmount 后) 被调, ref.read
  /// 抛 StateError 被吞 → temp 明文永不删 (PIPL §28, B1-11 同款修法)。
  @override
  Future<void> cleanupTempFile() async {
    final temp = tempDecryptedPath;
    if (temp == null) return;
    try {
      await _storage!.deleteTempFile(temp);
    } catch (e, st) {
      audioErrorSink(
        where: 'vent_compose_page.cleanupTempFile',
        error: e,
        stack: st,
      );
    }
  }

  // ===== vent 特有 helper =====

  /// vent 推录音时长 (用临时 player decrypt probe, 不影响主 player)
  ///
  /// P0-2 fix: path 是 .m4a.enc, audioplayer 不能直接吃。
  /// 先 decryptToTemp → 用 temp path 推时长 → 删 temp。
  /// v0.16 round 19B: 用 try/finally 确保 player.dispose() 在异常路径也跑
  /// 修前: setSource/getDuration 抛异常时直接走 catch, player 没 dispose → leak
  Future<void> _getAudioDuration(String path) async {
    final player = AudioPlayer();
    String? tempForDuration;
    try {
      // v0.32 round 8 (R112 E-01 同源防御): 走 _storage 字段 — 本方法
      // 从 stopRecordingImpl 起链, 若用户录音后立刻 pop, finally 在
      // unmount 后仍可能执行, ref.read 抛 StateError 被吞 → temp 泄漏。
      // _storage 是 initState 捕获的字段, 不依赖 element 生命周期。
      // (字段不参与类型提升, 显式 local 缓存 + null 分支)
      VentAudioStorage storage;
      final cached = _storage;
      if (cached != null) {
        storage = cached;
      } else {
        storage = ref.read(ventAudioStorageProvider);
        _storage = storage;
      }
      tempForDuration = await storage.decryptToTemp(path);
      await player.setSource(DeviceFileSource(tempForDuration));
      final d = await player.getDuration();
      if (mounted && d != null) {
        setState(() {
          _audioDurationSec = d.inSeconds;
        });
      }
    } catch (e, st) {
      audioErrorSink(
        where: 'vent_compose_page._getAudioDuration',
        error: e,
        stack: st,
        note: 'audio duration probe failed — non-critical',
      );
    } finally {
      // v0.32 R112 (E-01): 不 await player.dispose() — audioplayers dispose
      // 内部 Future.wait(内部 stream cancel) 的 future 可能永不 resolve
      // (root zone 坑), await 会把 deleteTempFile 一起卡死 → 明文 temp
      // 泄漏 (PIPL §28)。fire-and-forget + catchError 收口, native release
      // 由 dispose future 自己完成。
      unawaited(
        player.dispose().catchError((Object e, StackTrace st) {
          audioErrorSink(
            where: 'vent_compose_page._getAudioDuration.playerDispose',
            error: e,
            stack: st,
          );
        }),
      );
      if (tempForDuration != null) {
        await _storage!.deleteTempFile(tempForDuration);
      }
    }
  }

  // ===== 公开方法 (供 VentAudioSection callback) =====

  /// vent 录音切换 (toggle)
  ///
  /// 业务逻辑全在 mixin 状态机, 这里只剩"开始 vs 停止"分派
  Future<void> _toggleRecord() async {
    if (isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  /// vent 播放切换
  ///
  /// 业务逻辑 (decrypt + 启动 player) 在 startPlaybackImpl, 这里只剩
  /// "开始 vs 停止"分派
  Future<void> _togglePlay() async {
    if (audioPath == null) return;
    if (isPlaying) {
      await stopPlayback();
    } else {
      await startPlayback();
    }
  }

  /// vent 重录
  Future<void> _reRecord() async {
    // 删旧文件 (DB 里还没存, 所以可以删)
    if (audioPath != null) {
      final old = audioPath!;
      try {
        await ref.read(ventAudioStorageProvider).deleteAudio(old);
      } catch (e, st) {
        // 文件可能已被用户/系统清掉；删失败不阻塞重录流程
        audioErrorSink(
          where: 'vent_compose_page._reRecord',
          error: e,
          stack: st,
          note: 'old audio delete failed, continuing re-record',
        );
      }
    }
    if (mounted) {
      setState(() {
        _audioDurationSec = null;
      });
    }
    clearRecording();
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    final hasText = text.isNotEmpty;
    final hasAudio = audioPath != null;
    if (!hasText && !hasAudio) {
      AppSnackBar.showInfo(
        context,
        AppLocalizations.of(context).snackbarEmptyVent,
      );
      return;
    }
    if (isRecording) {
      AppSnackBar.showInfo(
        context,
        AppLocalizations.of(context).snackbarStopRecording,
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
              .fileSizeBytes(audioPath!);
        } catch (e, st) {
          // size 读不到(可能文件被外部清掉), sizeBytes 留 null, DB 仍能存
          audioErrorSink(
            where: 'vent_compose_page._onSave',
            error: e,
            stack: st,
            note: 'audio file size unreadable, sizeBytes=null',
          );
        }
      }
      await ref.read(ventRepositoryProvider).add(
            text: hasText ? text : null,
            audioPath: hasAudio ? audioPath : null,
            audioDurationSec: _audioDurationSec,
            audioSizeBytes: sizeBytes,
          );
      if (mounted) {
        context.pop(); // 回到列表
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).snackbarActionSave,
          error: e,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: AppLocalizations.of(context).ventComposeTitle,
      child: Padding(
        padding: AppTokens.edgeInsetsMd,
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
            // R102 (P1): 用 ListenableBuilder 替代空 setState(() {})
            // 之前 onChanged → setState → 整页重建 (SaveBar / AudioSection 全部 rebuild)
            // 现在只有 VentTextInput 区域 rebuild (字符计数 + 字数警告)
            ListenableBuilder(
              listenable: _textController,
              builder: (context, _) => VentTextInput(
                controller: _textController,
              ),
            ),
            const SizedBox(height: AppTokens.spacingMd),

            // 录音 / 播放区域
            // v0.30 round 93 (阶段 2 audit-fixes): vent audio 录音业务闭环不全
            // (storage / export 业务暂停), 走 [FeatureFlags.ventAudioEnabled]
            // gate, 默认 false 隐藏。VentTextInput 文字输入保留 (用户主路径
            // 不依赖 audio)。
            if (FeatureFlags.ventAudioEnabled)
              VentAudioSection(
                isRecording: isRecording,
                audioPath: audioPath,
                audioDurationSec: _audioDurationSec,
                isPlaying: isPlaying,
                onToggleRecord: _toggleRecord,
                onTogglePlay: _togglePlay,
                onReRecord: _reRecord,
              )
            else
              const SizedBox.shrink(),

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
// 系统打断 / 后台被杀等), stop 抛异常会直接 propagate 出去, 导致后续
// deleteTempFile 永远不调 → temp 文件泄漏 (DB 之外的 m4a 残留在 temp dir,
// 反复播放就堆一堆)。
//
// helper 把"stop + deleteTemp"封成 @visibleForTesting 的 top-level 函数,
// 测试可注入抛 PlatformException 的 stop callback, 验证 deleteTemp 仍调用。
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
  // 现在: stop 异常被吞, deleteTemp 仍跑, 异常仅 developer.log 记录
  try {
    await stop();
  } catch (e, st) {
    audioErrorSink(where: '$where.stop', error: e, stack: st);
  }
  try {
    await deleteTempFile();
  } catch (e, st) {
    audioErrorSink(where: '$where.deleteTemp', error: e, stack: st);
  }
}
