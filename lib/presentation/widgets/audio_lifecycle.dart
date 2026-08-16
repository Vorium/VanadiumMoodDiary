// v0.30 R108 (P1 god class 拆 6 大 F - Fix #1): 抽 audio state machine 共享 mixin
//
// **背景 (R107 §3.4 vent_compose + mood_audio_recorder 重复)**:
// 2 文件实现**几乎相同**的 audio state machine:
// - 字段: `_isRecording` / `_isPlaying` / `_audioPath` / `_tempDecryptedPath`
// - 4 步 dispose 链 (cancel stream → stop recorder → dispose recorder →
//   dispose player → delete temp file) ~50-65 行 pattern 1:1
// - 多个 `swallowError + unawaited + catchError` 模板
//
// **修复**: 抽 AudioLifecycleMixin, 4 状态字段 + 4 抽象方法 + 状态机方法 +
// 共享 asyncDispose。 vent_compose_page 495→~300, mood_audio_recorder 530→~330。
//
// **设计原则**:
// 1. 状态机 = enum AudioState { idle / recording / recorded / playing }
//    替代 3-4 个独立 bool 字段
// 2. 4 抽象方法由 subclass 实现 (record / playback / encryption / STT 业务)
// 3. `startRecordingImpl` 返 `bool` — false = 权限检查等 pre-check 失败
//    (subclass 已 fire AppSnackBar, mixin 回滚状态到 idle)
// 4. `stopRecordingImpl` 返 `String?` — 加密后路径, mixin 写入 audioPath
// 5. Mixin 不依赖 Riverpod / build_runner, 纯 Flutter + audioplayers
// 6. swallowError 集中器, 跟 vent_compose_page R79 + mood_audio_section R61
//    模式 1:1
// 7. 保留 v0.x.y 历史注释 + P0/P1 修复说明, 不重写只聚合
//
// **频度 (emil 决策)**: 100+/day (mood 录音) + tens/day (vent 录音),
// 状态切换是用户主路径, 必须可测。
import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:record/record.dart';

import 'package:chroniccare/core/shared/error_sinks.dart';

/// v0.30 R108: audio 状态机 enum, 替代 4 个独立 bool 字段
///
/// idle → recording → recorded → playing → recorded → idle (re-record)
///                              → idle (dispose)
/// v0.32 R112 round 8h: 加 paused — recording ⇄ paused (暂停/继续录音)
/// recording / paused → recorded (stop); paused → idle (stop 返 null)
@immutable
enum AudioState {
  /// 初始态 / 录音已清空
  idle,

  /// 正在录音 (record 启动, temp 明文写入)
  recording,

  /// 录音暂停 (recorder.pause(), 可 resume 继续 / stop 结束)
  paused,

  /// 录音完成 (已 stop + 加密, _audioPath 是 .m4a.enc)
  recorded,

  /// 正在播放解密后的 temp 明文
  playing,
}

/// v0.30 R108 (P1 god class 拆 6 大 F - Fix #1): 共享 audio state machine mixin
///
/// 抽 vent_compose + mood_audio_recorder 重复:
/// - 4 状态字段: `_isRecording` / `_isPlaying` / `_audioPath` / `_tempDecryptedPath`
/// - 4 步 dispose 链 (cancel stream → stop recorder → dispose recorder →
///   dispose player → delete temp file)
/// - `swallowError` + try/catch 模板
///
/// **使用方式**:
/// ```dart
/// class _MyState extends State<MyWidget> with AudioLifecycleMixin<MyWidget> {
///   late final AudioRecorder _recorder = AudioRecorder();
///   late final AudioPlayer _player = AudioPlayer();
///
///   // mixin 提供字段: isRecording / isPaused / isPlaying / audioPath /
///   //   tempDecryptedPath / recordingElapsed (R112 round 8h)
///   // mixin 提供方法: startRecording / pauseRecording / resumeRecording /
///   //   stopRecording / startPlayback / stopPlayback / asyncDisposeAudio
///   // 6 抽象方法必须实现 (业务逻辑):
///   @override
///   Future<bool> startRecordingImpl() async { ... } // false = 权限拒绝等
///   @override
///   Future<String?> stopRecordingImpl() async { ... } // 返回加密路径
///   @override
///   Future<void> pauseRecordingImpl() async { ... } // R112 round 8h
///   @override
///   Future<void> resumeRecordingImpl() async { ... } // R112 round 8h
///   @override
///   Future<void> startPlaybackImpl(String encryptedPath) async { ... }
///   @override
///   Future<void> stopPlaybackImpl() async { ... }
///   // 可选: 自定义 temp file 清理 (默认走 swallowError 占位)
///   @override
///   Future<void> cleanupTempFile() async { ... }
/// }
/// ```
mixin AudioLifecycleMixin<T extends StatefulWidget> on State<T> {
  // ===== 状态字段 (替代 4 个独立 bool / nullable) =====

  /// 当前 audio 状态, 由 mixin 内部维护
  @protected
  AudioState audioState = AudioState.idle;

  /// 加密后音频路径 (.m4a.enc), recorded / playing 时非空
  @protected
  String? audioPath;

  /// 播放时生成的临时解密文件路径, dispose 时清理
  ///
  /// 复用 vent_compose_page `_tempDecryptedPath` 注释:
  /// P0-2: 播放时生成的临时解密文件路径, dispose 时清理
  @protected
  String? tempDecryptedPath;

  /// R114 BUG 2 (PIPL §28): 录音明文 temp 路径 — subclass 在
  /// startRecordingImpl 生成后写入本字段, mixin dispose 链第 3.5 步
  /// best-effort 删除。修前 dispose 链只删 playback temp (第 6 步),
  /// 录音中途退出页面 → 明文 m4a 永久残留 OS temp。
  /// mood_audio_recorder_widget 走 MoodAudioService (service 层自管
  /// 路径 + 自删), 本字段保持 null 即可。
  @protected
  String? tempRecordPath;

  /// 播放 complete 事件 stream subscription
  ///
  /// vent_compose_page 跟 mood_audio_recorder 都有
  /// `_player.onPlayerComplete.listen(...)` 注册, dispose 时 cancel。
  @protected
  StreamSubscription<void>? playerCompleteSub;

  /// R102 (P1): 播放计时器 (vent_compose 不需要, 留给 subclass 用)
  @protected
  Timer? playbackTimer;

  // ===== v0.32 R112 round 8h: 录音时长追踪 (pause 冻结) =====

  /// 当前录音已录时长 (暂停期间冻结, 供 UI 显示 mm:ss)
  Duration recordingElapsed = Duration.zero;

  DateTime? _recordingStartedAt;
  DateTime? _pausedAt;
  Duration _pausedTotal = Duration.zero;
  Timer? _elapsedTimer;

  /// 500ms tick 刷新 recordingElapsed (暂停时不更新 = 冻结显示)
  void _startElapsedTicker() {
    _elapsedTimer?.cancel();
    _recordingStartedAt = DateTime.now();
    _pausedAt = null;
    _pausedTotal = Duration.zero;
    recordingElapsed = Duration.zero;
    _elapsedTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final startedAt = _recordingStartedAt;
      if (startedAt == null) return;
      final pausedAt = _pausedAt;
      final now = DateTime.now();
      var elapsed = now.difference(startedAt) - _pausedTotal;
      if (pausedAt != null) {
        elapsed -= now.difference(pausedAt);
      }
      if (elapsed < Duration.zero) elapsed = Duration.zero;
      if (mounted && recordingElapsed != elapsed) {
        setState(() => recordingElapsed = elapsed);
      }
    });
  }

  void _stopElapsedTicker() {
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    _recordingStartedAt = null;
    _pausedAt = null;
    _pausedTotal = Duration.zero;
  }

  // ===== 公开 getter (供 widget build 使用, 跟旧 API 兼容) =====

  /// 当前是否在录音 (state == recording)
  bool get isRecording => audioState == AudioState.recording;

  /// 当前是否录音暂停 (state == paused)
  bool get isPaused => audioState == AudioState.paused;

  /// 当前是否在播放 (state == playing)
  bool get isPlaying => audioState == AudioState.playing;

  /// 是否有录音结果 (state == recorded / playing)
  bool get hasRecording =>
      audioState == AudioState.recorded || audioState == AudioState.playing;

  // ===== 4 抽象方法 (subclass 实现业务逻辑) =====

  /// 启动录音 (含权限检查 / temp 路径生成 / record.start)
  ///
  /// 返回:
  /// - `true` = 成功启动 (recorder 已在写)
  /// - `false` = pre-check 失败 (例如权限拒绝), subclass 应已 fire AppSnackBar
  ///   `mixin 会自动回滚状态到 idle`
  ///
  /// 抛异常 = recorder.start 失败等系统错误, mixin 会 swallowError + 回滚
  ///
  /// **subclass 责任**:
  /// 1. 检查麦克风权限
  /// 2. 生成 temp 明文路径
  /// 3. 调 `_recorder.start(...)`
  Future<bool> startRecordingImpl();

  /// 停止录音, 返回加密后路径 (或 null = 失败)
  ///
  /// 返回:
  /// - `String` = 加密路径, mixin 写入 audioPath + state 转 recorded
  /// - `null` = 停止失败 (subclass 应已 fire AppSnackBar), mixin 状态回 idle
  ///
  /// 抛异常 = encrypt 失败等系统错误, mixin 会 swallowError + 回滚
  ///
  /// **subclass 责任**:
  /// 1. 调 `_recorder.stop()` 拿明文路径
  /// 2. `storage.encryptAndWrite(...)` 写到 .m4a.enc
  /// 3. 返回加密路径
  Future<String?> stopRecordingImpl();

  /// v0.32 R112 round 8h: 暂停录音 (recorder.pause, temp 文件保持打开)
  ///
  /// **subclass 责任**: 调 `_recorder.pause()` / `_service.pauseRecording()`
  ///
  /// 抛异常被 mixin swallowError (暂停失败保持 recording, UI 可重试)
  Future<void> pauseRecordingImpl();

  /// v0.32 R112 round 8h: 继续录音 (recorder.resume)
  ///
  /// **subclass 责任**: 调 `_recorder.resume()` / `_service.resumeRecording()`
  ///
  /// 抛异常被 mixin swallowError (恢复失败保持 paused, UI 可重试)
  Future<void> resumeRecordingImpl();

  /// 启动播放
  ///
  /// **subclass 责任**:
  /// 1. decryptToTemp 写 tempDecryptedPath
  /// 2. 调 `_player.setSource(...)` 或 `_player.play(DeviceFileSource(...))`
  /// 3. 注册 `_player.onPlayerComplete` 监听 (setState 回 recorded)
  ///
  /// 抛异常 = 播放失败, mixin 会清 temp + 状态回 recorded
  Future<void> startPlaybackImpl(String encryptedPath);

  /// 停止播放 (清 temp 留给 mixin 调 cleanupTempFile)
  ///
  /// **subclass 责任**:
  /// 1. 调 `_player.stop()`
  /// 2. 不要清 temp, 由 mixin 统一调 cleanupTempFile
  ///
  /// 抛异常被 mixin swallowError (播放失败不阻塞 UI)
  Future<void> stopPlaybackImpl();

  /// 清理 temp 解密文件
  ///
  /// 默认实现: swallow + log 占位, 提示 caller 需 override。
  /// subclass 应 override 调 `ref.read(storageProvider).deleteTempFile(path)`。
  @protected
  Future<void> cleanupTempFile() async {
    final temp = tempDecryptedPath;
    if (temp == null) return;
    try {
      audioErrorSink(
        where: 'AudioLifecycleMixin.cleanupTempFile',
        error: StateError(
          'subclass 未 override cleanupTempFile, temp 不会被真删: $temp',
        ),
        note: 'R108: AudioLifecycleMixin subclass 应 override cleanupTempFile '
            '调具体 storage.deleteTempFile (vent: ventAudioStorageProvider / '
            'mood: moodAudioStorageProvider)',
      );
    } catch (e, st) {
      audioErrorSink(
        where: 'AudioLifecycleMixin.cleanupTempFile',
        error: e,
        stack: st,
      );
    }
  }

  /// R114 BUG 2 (PIPL §28): 删除录音明文 temp 文件 (best-effort, 不抛)
  ///
  /// dispose 链第 3.5 步 + startRecordingImpl 异常回滚共用。
  /// 删除失败走 audioErrorSink (OS 最终会清 temp, 不阻塞 UI)。
  /// 注: 用 sync 文件操作 (existsSync/deleteSync) — async File future
  /// 在 testWidgets FakeAsync zone 永不 resolve, 会卡死 dispose 链
  /// (后续 player.stop / temp 清理全不跑, R114 BUG 2 实测踩坑)。
  /// 公共静态 (无 @protected): 子类 (vent_compose 异常回滚) 与
  /// audio_lifecycle_round108_test 都直接调用, 静态方法无法从子类实例
  /// 语义访问, 加 @protected 会让其中一方 warning。
  static Future<void> deleteRecordTempBestEffort(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (f.existsSync()) {
        f.deleteSync();
      }
    } catch (e, st) {
      audioErrorSink(
        where: 'AudioLifecycleMixin.deleteRecordTempBestEffort',
        error: e,
        stack: st,
        note: 'record temp file delete failed — OS will clean',
      );
    }
  }

  // ===== 状态机方法 (mixin 统一处理 setState + try/catch) =====

  /// 启动录音
  ///
  /// 状态转换: idle → recording (impl 返 true) / idle → idle (impl 返 false / 抛)
  /// 错误处理: 抛异常 → swallowError + 回 idle
  Future<void> startRecording() async {
    if (audioState != AudioState.idle) return;
    setState(() => audioState = AudioState.recording);
    try {
      final ok = await startRecordingImpl();
      if (ok) {
        // v0.32 R112 round 8h: 启动时长 ticker (pause 时冻结显示)
        _startElapsedTicker();
      } else if (mounted) {
        // pre-check 失败 (e.g. 权限拒绝), subclass 已 fire AppSnackBar,
        // mixin 回滚状态
        setState(() => audioState = AudioState.idle);
      }
    } catch (e, st) {
      audioErrorSink(
        where: 'AudioLifecycleMixin.startRecording',
        error: e,
        stack: st,
      );
      // R114 BUG 2 (PIPL §28): startRecordingImpl 半途抛异常 (temp 路径
      // 已生成) → 回滚删除明文 temp, 否则残留空明文文件
      final recordTemp = tempRecordPath;
      tempRecordPath = null;
      if (recordTemp != null) {
        await deleteRecordTempBestEffort(recordTemp);
      }
      if (mounted) {
        setState(() => audioState = AudioState.idle);
      }
    }
  }

  /// v0.32 R112 round 8h: 暂停录音
  ///
  /// 状态转换: recording → paused (impl 成功) / recording → recording (失败)
  /// 时长 ticker 冻结 (recordingElapsed 不再增长)
  Future<void> pauseRecording() async {
    if (audioState != AudioState.recording) return;
    try {
      await pauseRecordingImpl();
      if (!mounted) return;
      _pausedAt = DateTime.now();
      setState(() => audioState = AudioState.paused);
    } catch (e, st) {
      audioErrorSink(
        where: 'AudioLifecycleMixin.pauseRecording',
        error: e,
        stack: st,
      );
      // 保持 recording, UI 可重试
    }
  }

  /// v0.32 R112 round 8h: 继续录音
  ///
  /// 状态转换: paused → recording (impl 成功) / paused → paused (失败)
  /// 暂停时长计入 _pausedTotal, 恢复后 recordingElapsed 继续增长
  Future<void> resumeRecording() async {
    if (audioState != AudioState.paused) return;
    try {
      await resumeRecordingImpl();
      if (!mounted) return;
      final pausedAt = _pausedAt;
      if (pausedAt != null) {
        _pausedTotal += DateTime.now().difference(pausedAt);
      }
      _pausedAt = null;
      setState(() => audioState = AudioState.recording);
    } catch (e, st) {
      audioErrorSink(
        where: 'AudioLifecycleMixin.resumeRecording',
        error: e,
        stack: st,
      );
      // 保持 paused, UI 可重试
    }
  }

  /// 停止录音
  ///
  /// 状态转换: recording / paused → recorded (impl 返 non-null) / recording / paused → idle (impl 返 null / 抛)
  /// 业务逻辑: stopRecordingImpl 内部已 stop recorder + encrypt, 返回加密路径
  Future<void> stopRecording() async {
    // v0.32 R112 round 8h: 允许从 paused 停止 (recorder.stop 对 paused 有效)
    if (audioState != AudioState.recording && audioState != AudioState.paused) {
      return;
    }
    _stopElapsedTicker();
    try {
      final encryptedPath = await stopRecordingImpl();
      if (!mounted) return;
      setState(() {
        if (encryptedPath == null) {
          audioState = AudioState.idle;
        } else {
          audioPath = encryptedPath;
          audioState = AudioState.recorded;
        }
      });
    } catch (e, st) {
      audioErrorSink(
        where: 'AudioLifecycleMixin.stopRecording',
        error: e,
        stack: st,
      );
      if (mounted) {
        setState(() => audioState = AudioState.idle);
      }
    }
  }

  /// 启动播放
  ///
  /// 状态转换: recorded → playing
  /// 业务逻辑: subclass 在 startPlaybackImpl 内部解密 → 写入 tempDecryptedPath →
  ///   调 _player.play
  /// 错误处理: 抛异常 → 清理 temp + 状态回 recorded
  Future<void> startPlayback() async {
    if (audioState != AudioState.recorded) return;
    final path = audioPath;
    if (path == null) return;
    setState(() => audioState = AudioState.playing);
    try {
      // subclass 应在 startPlaybackImpl 内部 decryptToTemp + 写 tempDecryptedPath
      await startPlaybackImpl(path);
    } catch (e, st) {
      audioErrorSink(
        where: 'AudioLifecycleMixin.startPlayback',
        error: e,
        stack: st,
      );
      // R108: 失败时清 temp file 避免堆积 (R22 round 28 spen-bug-02 + R30
      // P1-3 fix 模式)
      await cleanupTempFile();
      if (mounted) {
        setState(() {
          audioState = AudioState.recorded;
          tempDecryptedPath = null;
        });
      }
    }
  }

  /// 停止播放
  ///
  /// 状态转换: playing → recorded
  /// 业务逻辑: stopPlaybackImpl 调 _player.stop, mixin 调 cleanupTempFile
  Future<void> stopPlayback() async {
    if (audioState != AudioState.playing) return;
    try {
      await stopPlaybackImpl();
    } catch (e, st) {
      // v0.22 round 28 (spen-bug-02): 失败时清 temp file 避免堆积
      audioErrorSink(
        where: 'AudioLifecycleMixin.stopPlayback',
        error: e,
        stack: st,
      );
    }
    await cleanupTempFile();
    if (mounted) {
      setState(() {
        audioState = AudioState.recorded;
        tempDecryptedPath = null;
      });
    }
  }

  /// 重录 (清空录音状态)
  ///
  /// 状态转换: recorded / playing → idle
  /// 副作用: 删 audioPath 文件 (subclass 应自己调 storage.deleteAudio)
  ///
  /// **注意**: 本方法只清状态, 删旧文件由 subclass 在调用前完成。
  /// 跟 vent_compose `_reRecord` + mood_audio `_reRecord` 1:1。
  void clearRecording() {
    if (audioState == AudioState.recording || audioState == AudioState.paused) {
      return;
    }
    _stopElapsedTicker();
    if (mounted) {
      setState(() {
        audioState = AudioState.idle;
        audioPath = null;
        tempDecryptedPath = null;
      });
    }
  }

  // ===== 共享 asyncDispose 4 步链 =====

  /// v0.28 R79 (P1 god class 拆 6 大 F - Fix #1): 异步释放资源的统一入口
  ///
  /// 顺序: cancel stream → stop recorder if recording → dispose recorder →
  ///   dispose player → delete temp file
  ///
  /// 之前 vent_compose 50 行 / mood_audio 65 行 1:1 重复, 现在 mixin 统一
  /// 提供。每步 catch 走 swallowError 集中器, 防止 stop/dispose 异常时
  /// 整条链中断, 后续资源漏释放 (R17 模式)。
  ///
  /// **调用方式**:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   unawaited(asyncDisposeAudio(
  ///     player: _player,
  ///     recorder: _recorder,
  ///   ));
  ///   super.dispose();
  /// }
  /// ```
  ///
  /// **iOS / Android native handle 释放** (vent_compose_page R79 修法):
  /// 之前 sync 调 `_recorder.dispose()` / `_player.dispose()` 不 await,
  /// native 资源释放不及时, 反复进/出 page 累积 → OOM / audio session 异常。
  /// 修: 抽 asyncDisposeAudio() 内部顺序释放, 用 unawaited() 包装避免
  /// State.dispose() 强制 sync 签名要求。
  ///
  /// **v0.32 R112 (E-01) 补**: 链内 2 处不 await —
  /// 1. stream subscription 的 `cancel()` future: audioplayers 派生 broadcast
  ///    subscription 的 cancel future 在 root zone 才 resolve (fake-async
  ///    测试内永不 resolve), await 会卡死整条链 → 后续 recorder / temp 清理
  ///    全不跑。cancel 本身同步生效, fire-and-forget 即可。
  /// 2. `player.dispose()`: audioplayers dispose 内部 `Future.wait` 一堆
  ///    内部 stream cancel (同 1), await 同样卡死链。native release 在
  ///    dispose 内部已同步发起, fire-and-forget + catchError 不丢资源,
  ///    且保证第 6 步 temp 清理不被 dispose future 阻塞 (PIPL §28)。
  @protected
  Future<void> asyncDisposeAudio({
    required AudioPlayer? player,
    required AudioRecorder? recorder,
  }) async {
    // 1) cancel player complete stream subscription (sync 收尾)
    // R112 (E-01): 不 await cancel() (root zone future 坑), cancel 同步生效
    try {
      unawaited(playerCompleteSub?.cancel());
    } catch (e, st) {
      audioErrorSink(
        where: 'AudioLifecycleMixin.asyncDisposeAudio.playerCompleteSub',
        error: e,
        stack: st,
      );
    }
    playerCompleteSub = null;

    // 2) cancel playback timer + 录音时长 ticker
    playbackTimer?.cancel();
    playbackTimer = null;
    _stopElapsedTicker();

    // 3) 如果还在录音 (含 paused), 先 stop (不 await 失败, 防止 hang)
    if ((audioState == AudioState.recording ||
            audioState == AudioState.paused) &&
        recorder != null) {
      try {
        await recorder.stop();
      } catch (e, st) {
        // R79: stop 失败也继续 dispose, 防止 native 资源永远挂着
        audioErrorSink(
          where: 'AudioLifecycleMixin.asyncDisposeAudio.recorderStop',
          error: e,
          stack: st,
        );
      }
    }

    // 3.5) R114 BUG 2 (PIPL §28): 删除录音明文 temp — 修前 dispose 链
    // 只删 playback temp (第 6 步 cleanupTempFile), 录音中途退出页面时
    // startRecordingImpl 生成的明文 m4a (精神心理患者语音) 永久残留
    // OS temp。best-effort, 不阻塞链。
    final recordTemp = tempRecordPath;
    tempRecordPath = null;
    if (recordTemp != null) {
      await deleteRecordTempBestEffort(recordTemp);
    }

    // 4) dispose recorder (audioplayers 5.0+ dispose 释放 native handle)
    if (recorder != null) {
      try {
        // R112 (E-01): 不 await recorder.dispose() — record 包 dispose 内部
        // await _stateStreamSubscription.cancel() (root zone future 坑,
        // 同 player.dispose), await 卡死链 → 后续 player / temp 清理全不跑。
        // native handle 释放由 dispose future 自己完成, fire-and-forget +
        // catchError 收口。
        unawaited(
          recorder.dispose().catchError((Object e, StackTrace st) {
            audioErrorSink(
              where: 'AudioLifecycleMixin.asyncDisposeAudio.recorderDispose',
              error: e,
              stack: st,
            );
          }),
        );
      } catch (e, st) {
        audioErrorSink(
          where: 'AudioLifecycleMixin.asyncDisposeAudio.recorderDispose',
          error: e,
          stack: st,
        );
      }
    }

    // 5) dispose player (audioplayers 5.0+ dispose 释放 native handle)
    if (player != null) {
      try {
        await player.stop();
      } catch (e, st) {
        audioErrorSink(
          where: 'AudioLifecycleMixin.asyncDisposeAudio.playerStop',
          error: e,
          stack: st,
        );
      }
      try {
        // R112 (E-01): 不 await player.dispose() — 内部 Future.wait(stream
        // cancel) 同 1) 的 root zone future 坑, await 卡死链 → 第 6 步
        // temp 明文清理永不跑 (PIPL §28)。dispose 的 native release 同步
        // 发起, fire-and-forget + catchError 收口。
        unawaited(
          player.dispose().catchError((Object e, StackTrace st) {
            audioErrorSink(
              where: 'AudioLifecycleMixin.asyncDisposeAudio.playerDispose',
              error: e,
              stack: st,
            );
          }),
        );
      } catch (e, st) {
        audioErrorSink(
          where: 'AudioLifecycleMixin.asyncDisposeAudio.playerDispose',
          error: e,
          stack: st,
        );
      }
    }

    // 6) delete temp decrypted file (R22 P1-3 + R79 续)
    // R112 (E-01): cleanupTempFile 由 subclass override, dispose 期实现
    // 必须走 initState 捕获的 storage 字段 (ref.read 在 unmount 后抛
    // StateError 被吞 → temp 明文永不删, PIPL §28)。
    if (tempDecryptedPath != null) {
      await cleanupTempFile();
      tempDecryptedPath = null;
    }
  }
}
