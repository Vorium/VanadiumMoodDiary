// v1.1.0+165 R122 P2-1 (mood_audio_service 拆 3 facade step 2):
// 抽 recorder 状态机 + 方法到独立 class。
//
// 拆解动机 (R122 P2-1 续 step 1):
// - mood_audio_service.dart 406L (step 1 拆 STT 后) 仍 386L recorder + 3min 上限
//   状态机 + pause/resume + cancel 逻辑
// - 拆 recorder 后主 service 只剩 orchestrator (~250L)
// - 跨 audio recording 业务跨期残留 (R31 误判"已闭环" cross-residual) 闭环
//
// R122 P2-1 step 2 范围: recorder state 字段 + 5 method (start / stop /
// pause / resume / cancel / dispose) + 4 getter (isRecording / isPaused /
// recordingElapsed / tempRecordPath) + 1 callback (onMaxReached 触发
// service 层 stopRecording auto-stop)
//
// R123 (跨期 P0 #3 续): MoodAudioRecorderException 中文 fallback
// 是 service 层 catch 转 MoodAudioException 后走 page l10n 翻译, 本地
// 异常 message 保持中文即可 (仅作为日志/调试信号, 不显示给用户)。
// rule3-whitelist: 98 (R113 BUG A 精确豁免 token, line 98 中文 throw 豁免)

import 'dart:async';
import 'dart:io';

import 'package:record/record.dart';

import 'package:chroniccare/features/mood/data/services/mood_audio_storage.dart';
import 'package:chroniccare/core/shared/error_sinks.dart';

/// 情绪日记录音 recorder 状态机 (v0.23 round 31, R122 P2-1 step 2 抽独立 class)
///
/// 抽象: 配合 MoodAudioStt 完成"录音 + 实时识别" 编排。
/// 公开 getters: isRecording / isPaused / recordingElapsed / tempRecordPath
class MoodAudioRecorder {
  final AudioRecorder _recorder;
  final MoodAudioStorage _storage;
  final Duration _effectiveMaxDuration;
  final Duration _effectiveTickInterval;

  // 录音状态
  bool _isRecording = false;
  bool _isPaused = false;
  DateTime? _pausedAt;
  Duration _pausedTotal = Duration.zero;
  DateTime? _recordingStart;
  Timer? _recordingTimer;
  Duration _recordingElapsed = Duration.zero;
  String? _tempRecordPath;
  void Function(Duration)? _onTickCb;
  void Function()? _onMaxReachedCb;

  /// v1.1.0+165 R122 P2-1: auto-stop 回调,让 service 层 orchestrator 决定
  /// 3min 到期时如何停 (调 stopRecording 清理)
  void Function()? _onAutoStop;

  MoodAudioRecorder({
    AudioRecorder? recorder,
    MoodAudioStorage? storage,
    Duration? maxDuration,
    Duration? tickInterval,
  })  : _recorder = recorder ?? AudioRecorder(),
        _storage = storage ?? MoodAudioStorage(),
        _effectiveMaxDuration = maxDuration ?? _defaultMaxDuration,
        _effectiveTickInterval = tickInterval ?? _defaultTickInterval;

  /// 3min 上限
  static const Duration _defaultMaxDuration = Duration(minutes: 3);

  /// 100ms tick interval
  static const Duration _defaultTickInterval = Duration(milliseconds: 100);

  // ===== 公开 getters =====

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  Duration get recordingElapsed => _recordingElapsed;
  String? get tempRecordPath => _tempRecordPath;

  /// 设置 3min 到期时 auto-stop 回调 (service 层调, 启动时挂)
  void setAutoStopCallback(void Function()? onAutoStop) {
    _onAutoStop = onAutoStop;
  }

  /// 启动录音 + 同步启动 100ms tick timer
  ///
  /// [onTick] 每 100ms 触发, 携带当前 elapsed
  /// [onMaxReached] 3min 到期时触发, 之后 auto-stop (service 决定如何处理)
  Future<void> start({
    required void Function(Duration elapsed) onTick,
    required void Function() onMaxReached,
  }) async {
    if (_isRecording) return;

    _onTickCb = onTick;
    _onMaxReachedCb = onMaxReached;

    // 1. 权限检查
    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      throw const MoodAudioRecorderException('麦克风权限被拒绝');
    }

    // 2. 生成临时明文路径
    _tempRecordPath = await _storage.newTempRecordPath();

    // 3. recorder.start 写明文
    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc, // m4a (aac)
          bitRate: 64000,
          sampleRate: 44100,
        ),
        path: _tempRecordPath!,
      );
    } catch (e, st) {
      // R114 BUG 2 (P3 #14 同族): start 失败时 _tempRecordPath 已生成 —
      // 回滚删除, 否则空明文文件残留 (mic 被占等场景)
      final tempPath = _tempRecordPath;
      _tempRecordPath = null;
      await deleteTempFile(tempPath);
      audioErrorSink(
        where: 'mood_audio_recorder.start',
        error: e,
        stack: st,
        note: 'recorder.start failed — temp record file rolled back',
      );
      rethrow;
    }

    _isRecording = true;
    _isPaused = false;
    _pausedAt = null;
    _pausedTotal = Duration.zero;
    _recordingStart = DateTime.now();
    _recordingElapsed = Duration.zero;

    // 4. 启动 100ms tick Timer
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(_effectiveTickInterval, (_) {
      if (!_isRecording || _recordingStart == null) return;
      // v0.32 R112 round 8h: 暂停期间冻结 elapsed (不增长)
      if (_isPaused) return;
      _recordingElapsed =
          DateTime.now().difference(_recordingStart!) - _pausedTotal;
      _onTickCb?.call(_recordingElapsed);
      if (_recordingElapsed >= _effectiveMaxDuration) {
        // 5. 到 3min 自动 stop
        // v0.23 round 43 (spen-4) fix: 之前只 cancel timer + fire onMaxReached,
        // **不**强制 stop recorder,导致录音继续吃 mic 资源 + 累计空文件。
        // 修法: cancel timer → fire callback → 立刻 unawaited(stopRecording)
        // 强制关闭 recorder + 释放 mic。stopRecording 内部 idempotent
        // (_isRecording check),即使 page 也在调 cancelRecording 也安全。
        _recordingTimer?.cancel();
        _onMaxReachedCb?.call();
        // R122 P2-1 step 2: 委派 service 层 auto-stop (走 onAutoStop 回调)
        _onAutoStop?.call();
      }
    });
  }

  /// 停止录音, 返 plain path + 累计 durationMs
  ///
  /// 成功路径: caller 负责 encryptAndWrite + 删明文 (page 层)
  /// 失败路径 (null): best-effort 删 _tempRecordPath
  Future<MoodAudioRecordingOutcome?> stop() async {
    if (!_isRecording) return null;
    _recordingTimer?.cancel();

    final plainPath = await _recorder.stop();
    _isRecording = false;
    // v0.32 R112 round 8h: 复位 pause 状态
    _isPaused = false;
    _pausedAt = null;
    _pausedTotal = Duration.zero;
    final elapsed = _recordingElapsed;

    if (plainPath == null) {
      // R114 BUG 2 (PIPL §28): recorder 未产出文件时, 之前生成的
      // _tempRecordPath 可能仍有部分明文数据 → best-effort 删除
      final tempPath = _tempRecordPath;
      _tempRecordPath = null;
      await deleteTempFile(tempPath);
      return null;
    }
    // 成功路径: caller (page) 负责 encryptAndWrite + 删明文 —
    // _tempRecordPath 清空, dispose 不再二次处理
    _tempRecordPath = null;
    return MoodAudioRecordingOutcome(
      plainPath: plainPath,
      durationMs: elapsed.inMilliseconds,
    );
  }

  /// 暂停录音 (v0.32 R112 round 8h 加)
  Future<void> pause() async {
    if (!_isRecording || _isPaused) return;
    await _recorder.pause();
    _isPaused = true;
    _pausedAt = DateTime.now();
  }

  /// 恢复录音
  Future<void> resume() async {
    if (!_isRecording || !_isPaused) return;
    await _recorder.resume();
    final pausedAt = _pausedAt;
    if (pausedAt != null) {
      _pausedTotal += DateTime.now().difference(pausedAt);
    }
    _pausedAt = null;
    _isPaused = false;
  }

  /// 取消录音 (R114 BUG 2: best-effort 删明文 temp 必走)
  Future<void> cancel() async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    final tempPath = _tempRecordPath;
    _tempRecordPath = null;
    try {
      await _recorder.stop();
    } catch (e, st) {
      audioErrorSink(
        where: 'mood_audio_recorder.cancel',
        error: e,
        stack: st,
        note: 'recorder.stop() during cancel',
      );
    }
    await deleteTempFile(tempPath);
    _isRecording = false;
    _isPaused = false;
    _pausedAt = null;
    _pausedTotal = Duration.zero;
  }

  /// 释放 recorder 资源 (page dispose 时调)
  Future<void> dispose() async {
    _recordingTimer?.cancel();
    final tempPath = _tempRecordPath;
    _tempRecordPath = null;
    try {
      if (_isRecording) {
        await _recorder.stop();
      }
      await _recorder.dispose();
    } catch (e, st) {
      audioErrorSink(
        where: 'mood_audio_recorder.dispose',
        error: e,
        stack: st,
      );
    }
    await deleteTempFile(tempPath);
  }

  /// R114 BUG 2 (PIPL §28): 删除明文录音临时文件 (best-effort)
  ///
  /// cancelRecording / dispose / startRecording 失败 / stopRecording
  /// 无结果 4 条路径共用 — 修前这 4 条路径都不删 [_tempRecordPath],
  /// 用户录音中途退出页面 → 明文 m4a 精神心理患者语音永久留在
  /// [Directory.systemTemp] 直到 OS 碰巧清理。
  ///
  /// 不抛: 删除失败走 audioErrorSink (OS 最终会清 temp, 不阻塞 UI)。
  /// 注: 用 sync 文件操作 (existsSync/deleteSync) — async File future
  /// 在 testWidgets FakeAsync zone 永不 resolve, widget 测试内 dispose /
  /// cancelRecording 链会被卡死 (AudioLifecycleMixin 同款决策)。
  /// @visibleForTesting — 单测直接注入真实临时文件验证删除行为。
  /// R122 P2-1 step 2: 公开 (之前 private) 让主 service 委派 — 内部
  /// recorder 仍私有调用, 但 MoodAudioServiceImpl.deleteTempRecordFile
  /// 是 1 行委派, 保证 single source of truth.
  static Future<void> deleteTempFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (f.existsSync()) {
        f.deleteSync();
      }
    } catch (e, st) {
      audioErrorSink(
        where: 'mood_audio_recorder.deleteTempFile',
        error: e,
        stack: st,
        note: 'temp record file delete failed — OS will clean',
      );
    }
  }
}

/// 公开返回值 (R122 P2-1 step 2): 跟原 MoodAudioResult 同语义, 但
/// 改名为 MoodAudioRecordingOutcome 跟 service 层 MoodAudioResult 区分
/// (service 仍返 MoodAudioResult, recorder 内部用此类型, 通过
/// orchestrator 转换)
class MoodAudioRecordingOutcome {
  final String plainPath;
  final int durationMs;
  const MoodAudioRecordingOutcome({
    required this.plainPath,
    required this.durationMs,
  });
}

/// 公开异常 — R122 P2-1 step 2: 跟 MoodAudioException 同语义, 但限定
/// 在 recorder scope
///
/// 主 service 层 catch MoodAudioRecorderException 转译为 MoodAudioException
/// 保持公开 API 兼容 (page 层只接 MoodAudioException)。
class MoodAudioRecorderException implements Exception {
  final String message;
  const MoodAudioRecorderException(this.message);
  @override
  String toString() => 'MoodAudioRecorderException: $message';
}
