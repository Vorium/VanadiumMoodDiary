// 规则 3 标记: 麦克风错误 中文 fallback — v1.0+ i18n (显示层走 ARB)
// v0.23 (Round 31) MoodAudioService — 情绪日记录音 + STT 编排
//
// 仿 vent_compose_page 内联实现,抽成 service 类便于:
// 1. widget 测试时通过 ProviderScope override 替换
// 2. 业务逻辑 (3min 上限 / 60s STT 窗口) 集中,不散在 UI
//
// **核心 trade-off (P0 设计决策)**:
// 1. 录音 3min 上限 — UI 主动停 / 时间到 3min 自动停
// 2. STT 60s 窗口 — speech_to_text 7.x + Chrome Web Speech API 单次识别
//    硬限制 60s,3min 录音时 STT 只覆盖前 60s,剩余部分不识别
// 3. STT 失败 graceful degrade — 不识别成功也不阻塞录音保存
//
// **Stream 设计**: sttTranscriptStream 在 startRecording() 后立即启动 STT listen,
// 每收到 partial result 推一次; stopStt() 拿 final transcript 后关闭 stream。
// 调用方 (page) 订阅 stream 实时显示识别文字。
//
// **3min 上限实现**: startRecording 启动 Timer.periodic 每 100ms tick,
// 累计 elapsed;到 3min 自动 stopRecording,不依赖用户主动停。

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:chroniccare/core/data/services/mood_audio_storage.dart';
import 'package:chroniccare/core/shared/error_sinks.dart';

/// 录音 + STT 编排结果
class MoodAudioResult {
  final String plainPath;
  final int durationMs;
  const MoodAudioResult({required this.plainPath, required this.durationMs});
}

/// v0.23 (Round 31) 情绪日记录音 + STT 编排接口
///
/// 抽接口是为 widget 测试:用 ProviderScope override 注入 FakeMoodAudioService
/// 可以完全不走 record / speech_to_text,纯 UI 流程测试。
abstract class MoodAudioService {
  /// 初始化 STT (申请权限, 加载 on-device 模型)
  ///
  /// 返回 true = STT 可用;false = 设备不支持 / 权限被拒。
  /// 录音功能不依赖 STT, 即使 false 录音 + 加密 + 保存仍正常工作。
  Future<bool> initialize();

  /// 是否正在录音
  bool get isRecording;

  /// 是否正在 STT 监听
  bool get isSttListening;

  /// 当前录音已耗时 (录音未启动 = Duration.zero)
  Duration get recordingElapsed;

  /// 启动录音 + 同步启动 STT listen
  ///
  /// 流程:
  /// 1. 检查权限
  /// 2. 生成临时明文路径
  /// 3. recorder.start 写明文
  /// 4. STT 启动 listen (如果 initialize() 返回 true)
  /// 5. 启动 100ms tick Timer 累计 elapsed
  /// 6. 3min 时自动 stopRecording
  ///
  /// [onTick] 每个 tick (100ms) 调一次,page 用来显示计时器
  /// [onMaxReached] 3min 自动 stop 时调一次,page 用来显示提示
  Future<void> startRecording({
    required void Function(Duration elapsed) onTick,
    required void Function() onMaxReached,
  });

  /// 停止录音
  ///
  /// 返回明文文件路径 + 时长, 由 caller (page) 负责调 storage.encryptAndWrite
  /// 加密 + 删明文。
  Future<MoodAudioResult?> stopRecording();

  /// v0.32 R112 round 8h: 暂停录音 (elapsed 冻结, recorder 保持打开)
  Future<void> pauseRecording();

  /// v0.32 R112 round 8h: 继续录音
  Future<void> resumeRecording();

  /// v0.32 R112 round 8h: 是否暂停中
  bool get isPaused;

  /// 取消录音(不保存, 直接清掉临时文件)
  Future<void> cancelRecording();

  /// STT 实时识别结果流
  ///
  /// startRecording 后立即产生; stopRecording 后仍可继续 emit 直到
  /// stopStt() 被调。每条是 partial result (Web Speech API 风格)。
  Stream<String> get sttTranscriptStream;

  /// 停止 STT 监听
  ///
  /// 录音停止后页面需要这个把 STT 也停掉。
  /// 最终文本由 [sttTranscriptStream] 的最后一条推送决定。
  Future<void> stopStt();

  /// 释放所有资源 (AudioRecorder / SpeechToText / Timer / stream)
  Future<void> dispose();
}

/// v0.23 (Round 31) 默认实现 — 真实 record + speech_to_text
///
/// 测试通过 ProviderScope override 注入 [MoodAudioService] 的 fake 实现。
class MoodAudioServiceImpl implements MoodAudioService {
  final AudioRecorder _recorder;
  final SpeechToText _stt;
  final MoodAudioStorage _storage;

  // ===== 录音状态 =====
  bool _isRecording = false;
  // v0.32 R112 round 8h: pause 支持
  bool _isPaused = false;
  DateTime? _pausedAt;
  Duration _pausedTotal = Duration.zero;
  DateTime? _recordingStart;
  Timer? _recordingTimer;
  Duration _recordingElapsed = Duration.zero;
  String? _tempRecordPath;
  void Function(Duration)? _onTickCb;
  void Function()? _onMaxReachedCb;

  // ===== STT 状态 =====
  bool _isSttListening = false;
  bool _sttAvailable = false;
  final StreamController<String> _sttController = StreamController.broadcast();

  // 3min 上限
  static const Duration _maxDuration = Duration(minutes: 3);

  // 100ms tick interval
  static const Duration _tickInterval = Duration(milliseconds: 100);

  // v0.23 round 43 (spen-4 test helper): 测试可注入短 maxDuration + tickInterval
  // 默认 3min / 100ms,真实使用不变。test 用 100ms / 1s 加速跑完。
  final Duration _effectiveMaxDuration;
  final Duration _effectiveTickInterval;

  MoodAudioServiceImpl({
    AudioRecorder? recorder,
    SpeechToText? stt,
    MoodAudioStorage? storage,
    Duration? maxDuration,
    Duration? tickInterval,
  })  : _recorder = recorder ?? AudioRecorder(),
        _stt = stt ?? SpeechToText(),
        _storage = storage ?? MoodAudioStorage(),
        _effectiveMaxDuration = maxDuration ?? _maxDuration,
        _effectiveTickInterval = tickInterval ?? _tickInterval;

  /// R114 BUG 2 (PIPL §28): 删除明文录音临时文件 (best-effort)。
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
  @visibleForTesting
  static Future<void> deleteTempRecordFile(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (f.existsSync()) {
        f.deleteSync();
      }
    } catch (e, st) {
      audioErrorSink(
        where: 'mood_audio_service.deleteTempRecordFile',
        error: e,
        stack: st,
        note: 'temp record file delete failed — OS will clean',
      );
    }
  }

  @override
  bool get isRecording => _isRecording;

  @override
  bool get isPaused => _isPaused;

  @override
  bool get isSttListening => _isSttListening;

  @override
  Duration get recordingElapsed => _recordingElapsed;

  @override
  Future<bool> initialize() async {
    try {
      _sttAvailable = await _stt.initialize(
        onError: (errorNotification) {
          // STT 错误 = graceful degrade, 不影响录音
          audioErrorSink(
            where: 'mood_audio_service.stt.onError',
            error: errorNotification.errorMsg,
            note: 'STT error during listen — recording continues',
          );
        },
        onStatus: (status) {
          // 'done' / 'notListening' 状态由 stopStt / cancelStt 处理
        },
      );
      return _sttAvailable;
    } catch (e, st) {
      // 设备不支持 / 初始化失败 = graceful degrade
      audioErrorSink(
        where: 'mood_audio_service.initialize',
        error: e,
        stack: st,
        note: 'STT initialize failed — recording without transcript',
      );
      _sttAvailable = false;
      return false;
    }
  }

  @override
  Future<void> startRecording({
    required void Function(Duration elapsed) onTick,
    required void Function() onMaxReached,
  }) async {
    if (_isRecording) return;

    _onTickCb = onTick;
    _onMaxReachedCb = onMaxReached;

    // 1. 权限检查
    final hasPerm = await _recorder.hasPermission();
    if (!hasPerm) {
      throw const MoodAudioException('麦克风权限被拒绝');
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
      await deleteTempRecordFile(tempPath);
      audioErrorSink(
        where: 'mood_audio_service.startRecording',
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

    // 4. STT 启动 listen (如果可用)
    if (_sttAvailable) {
      try {
        await _stt.listen(
          onResult: (SpeechRecognitionResult result) {
            // partial / final 都推,UI 实时显示 partial,save 时用 final
            final text = result.recognizedWords;
            if (text.isNotEmpty) {
              _sttController.add(text);
            }
          },
          listenOptions: SpeechListenOptions(
            partialResults: true,
            listenMode: ListenMode.dictation,
          ),
        );
        _isSttListening = true;
      } catch (e, st) {
        audioErrorSink(
          where: 'mood_audio_service.startSttListen',
          error: e,
          stack: st,
          note: 'STT listen failed — recording continues without transcript',
        );
        _isSttListening = false;
      }
    }

    // 5. 启动 100ms tick Timer
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(_effectiveTickInterval, (_) {
      if (!_isRecording || _recordingStart == null) return;
      // v0.32 R112 round 8h: 暂停期间冻结 elapsed (不增长)
      if (_isPaused) return;
      _recordingElapsed =
          DateTime.now().difference(_recordingStart!) - _pausedTotal;
      _onTickCb?.call(_recordingElapsed);
      if (_recordingElapsed >= _effectiveMaxDuration) {
        // 6. 到 3min 自动 stop
        // v0.23 round 43 (spen-4) fix: 之前只 cancel timer + fire onMaxReached,
        // **不**强制 stop recorder,导致录音继续吃 mic 资源 + 累计空文件。
        // 修法: cancel timer → fire callback → 立刻 unawaited(stopRecording)
        // 强制关闭 recorder + 释放 mic。stopRecording 内部 idempotent
        // (_isRecording check),即使 page 也在调 cancelRecording 也安全。
        _recordingTimer?.cancel();
        _onMaxReachedCb?.call();
        // 强制 stop recorder (footgun: callback 抛错时录音仍继续)
        unawaited(
          stopRecording().catchError((Object e, StackTrace st) {
            audioErrorSink(
              where: 'mood_audio_service._recordingTimer.maxDuration',
              error: e,
              stack: st,
              note:
                  'auto-stop recorder at 3min failed — page may need manual cancel',
            );
            return null;
          }),
        );
      }
    });
  }

  @override
  Future<MoodAudioResult?> stopRecording() async {
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
      await deleteTempRecordFile(tempPath);
      return null;
    }
    // 成功路径: caller (page) 负责 encryptAndWrite + 删明文 —
    // _tempRecordPath 清空, dispose 不再二次处理
    _tempRecordPath = null;
    return MoodAudioResult(
      plainPath: plainPath,
      durationMs: elapsed.inMilliseconds,
    );
  }

  @override
  Future<void> pauseRecording() async {
    if (!_isRecording || _isPaused) return;
    await _recorder.pause();
    _isPaused = true;
    _pausedAt = DateTime.now();
  }

  @override
  Future<void> resumeRecording() async {
    if (!_isRecording || !_isPaused) return;
    await _recorder.resume();
    final pausedAt = _pausedAt;
    if (pausedAt != null) {
      _pausedTotal += DateTime.now().difference(pausedAt);
    }
    _pausedAt = null;
    _isPaused = false;
  }

  @override
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    // R114 BUG 2 (PIPL §28): 取消录音必须删明文临时 m4a —
    // 修前只置 _tempRecordPath = null 从不 delete, 用户中途退出页面
    // (widget dispose → cancelRecording) → 明文精神心理语音永留 systemTemp
    final tempPath = _tempRecordPath;
    _tempRecordPath = null;
    try {
      await _recorder.stop();
    } catch (e, st) {
      audioErrorSink(
        where: 'mood_audio_service.cancelRecording',
        error: e,
        stack: st,
        note: 'recorder.stop() during cancel',
      );
    }
    await deleteTempRecordFile(tempPath);
    _isRecording = false;
    // v0.32 R112 round 8h: 复位 pause 状态
    _isPaused = false;
    _pausedAt = null;
    _pausedTotal = Duration.zero;
    // STT 也停
    await _stopSttInternal();
  }

  @override
  Stream<String> get sttTranscriptStream => _sttController.stream;

  @override
  Future<void> stopStt() async {
    try {
      if (_isSttListening) {
        await _stt.stop();
        // 注意: speech_to_text 在 stop() 时会触发最后 1 次 onResult with final=true,
      }
    } catch (e, st) {
      audioErrorSink(
        where: 'mood_audio_service.stopStt',
        error: e,
        stack: st,
        note: 'STT stop failed',
      );
    }
    _isSttListening = false;
    // 最终文本由 sttTranscriptStream 的最后一条推送决定
    // (page 端会收集 stream 里的 final recognized text 存到 mood_entry)
  }

  Future<void> _stopSttInternal() async {
    try {
      if (_isSttListening) {
        await _stt.stop();
      }
    } catch (e, st) {
      audioErrorSink(
        where: 'mood_audio_service._stopSttInternal',
        error: e,
        stack: st,
      );
    }
    _isSttListening = false;
  }

  @override
  Future<void> dispose() async {
    _recordingTimer?.cancel();
    // R114 BUG 2 (PIPL §28): dispose 也删明文录音 temp —
    // 修前 dispose 只 stop/dispose recorder, _tempRecordPath 文件泄漏
    final tempPath = _tempRecordPath;
    _tempRecordPath = null;
    try {
      if (_isRecording) {
        await _recorder.stop();
      }
      await _recorder.dispose();
    } catch (e, st) {
      audioErrorSink(
        where: 'mood_audio_service.dispose',
        error: e,
        stack: st,
      );
    }
    await deleteTempRecordFile(tempPath);
    await _stopSttInternal();
    await _sttController.close();
  }
}

/// 公开异常 — 给 page 捕获后展示 snackbar
class MoodAudioException implements Exception {
  final String message;
  const MoodAudioException(this.message);
  @override
  String toString() => 'MoodAudioException: $message';
}
// rule3-whitelist: 244
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
