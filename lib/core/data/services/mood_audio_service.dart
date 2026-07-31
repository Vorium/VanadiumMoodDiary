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

import 'package:record/record.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:chroniccare/core/data/services/mood_audio_storage.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';

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

  @override
  bool get isRecording => _isRecording;

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
          swallowError(
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
      swallowError(
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
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc, // m4a (aac)
        bitRate: 64000,
        sampleRate: 44100,
      ),
      path: _tempRecordPath!,
    );

    _isRecording = true;
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
        swallowError(
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
      _recordingElapsed = DateTime.now().difference(_recordingStart!);
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
            swallowError(
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
    final elapsed = _recordingElapsed;

    if (plainPath == null) {
      return null;
    }
    return MoodAudioResult(plainPath: plainPath, durationMs: elapsed.inMilliseconds);
  }

  @override
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    _recordingTimer?.cancel();
    try {
      await _recorder.stop();
    } catch (e, st) {
      swallowError(
        where: 'mood_audio_service.cancelRecording',
        error: e,
        stack: st,
        note: 'recorder.stop() during cancel',
      );
    }
    _isRecording = false;
    _tempRecordPath = null;
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
      swallowError(
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
      swallowError(
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
    try {
      if (_isRecording) {
        await _recorder.stop();
      }
      await _recorder.dispose();
    } catch (e, st) {
      swallowError(
        where: 'mood_audio_service.dispose',
        error: e,
        stack: st,
      );
    }
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
