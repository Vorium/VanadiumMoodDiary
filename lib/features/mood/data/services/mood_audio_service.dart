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
// **3min 上限实现**: recorder 内部 Timer.periodic 每 100ms tick,
// 累计 elapsed;到 3min 自动 fire onAutoStop 回调 → service 层 stopRecording
// 强制释放 mic。
//
// **R122 P2-1 拆 3 facade**:
// - 跨 audio recording + STT + storage 3 业务 (R31 误判"已闭环" cross-residual)
// - 拆 recorder / stt / orchestrator, 跟 R120 notification_service 7 sub-service
//   模式对齐
// - step 1 抽 STT (496L→406L), step 2 抽 recorder (本文件 406L→~250L)
// - step 3 storage review (mood_audio_storage 已独立, 验证接口)

import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:chroniccare/features/mood/data/services/mood_audio_recorder.dart';
import 'package:chroniccare/features/mood/data/services/mood_audio_stt.dart';
import 'package:chroniccare/features/mood/data/services/mood_audio_storage.dart';
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
  /// 1. recorder 内部检查权限
  /// 2. 生成临时明文路径
  /// 3. recorder.start 写明文
  /// 4. STT 启动 listen (如果 initialize() 返回 true)
  /// 5. recorder 内部 100ms tick Timer 累计 elapsed
  /// 6. 3min 时 fire onMaxReached + onAutoStop → service 层 stopRecording
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

  /// 释放所有资源 (recorder / stt / stream)
  Future<void> dispose();
}

/// v0.23 (Round 31) 默认实现 — 真实 record + speech_to_text
///
/// R122 P2-1 拆 3 facade 后的 orchestrator: 1 行委派 recorder / stt 状态机,
/// 自身只保留 public API 入口 + 异常转译 (recorder 抛 MoodAudioRecorderException
/// → 公开 MoodAudioException 兼容 page 层既有捕获逻辑)。
///
/// 测试通过 ProviderScope override 注入 [MoodAudioService] 的 fake 实现。
class MoodAudioServiceImpl implements MoodAudioService {
  // R122 P2-1 step 2: recorder 状态机委派到独立 class
  final MoodAudioRecorder _recorderController;
  // R122 P2-1 step 1: STT 状态机委派到独立 class
  final MoodAudioStt _sttController;
  // ignore: unused_field — 保留 import 兼容 (R122 路线图 future 扩展)
  final MoodAudioStorage _storage;

  MoodAudioServiceImpl({
    MoodAudioRecorder? recorderController,
    MoodAudioStt? sttController,
    MoodAudioStorage? storage,
  })  : _recorderController = recorderController ?? MoodAudioRecorder(),
        _sttController = sttController ?? MoodAudioStt(),
        _storage = storage ?? MoodAudioStorage() {
    // R122 P2-1 step 2: 挂 auto-stop 回调 → 调 service 层 stopRecording
    // (footgun: callback 抛错时录音仍继续, 走 audioErrorSink)
    _recorderController.setAutoStopCallback(() {
      unawaited(
        stopRecording().catchError((Object e, StackTrace st) {
          audioErrorSink(
            where: 'mood_audio_service._recorderController.autoStop',
            error: e,
            stack: st,
            note:
                'auto-stop recorder at max duration failed — page may need manual cancel',
          );
          return null;
        }),
      );
    });
  }

  /// R114 BUG 2 (PIPL §28): 删除明文录音临时文件 (best-effort)。
  ///
  /// R122 P2-1 step 2: 1 行委派到 [MoodAudioRecorder.deleteTempFile],
  /// 保持 single source of truth (recorder 内部 cancel / dispose / start
  /// 失败 / stop 无结果 4 条路径都走同一处)。
  ///
  /// 不抛: 删除失败走 audioErrorSink (OS 最终会清 temp, 不阻塞 UI)。
  /// 注: 用 sync 文件操作 (existsSync/deleteSync) — async File future
  /// 在 testWidgets FakeAsync zone 永不 resolve, widget 测试内 dispose /
  /// cancelRecording 链会被卡死 (AudioLifecycleMixin 同款决策)。
  /// @visibleForTesting — 单测直接注入真实临时文件验证删除行为。
  @visibleForTesting
  static Future<void> deleteTempRecordFile(String? path) =>
      MoodAudioRecorder.deleteTempFile(path);

  @override
  bool get isRecording => _recorderController.isRecording;

  @override
  bool get isPaused => _recorderController.isPaused;

  @override
  bool get isSttListening => _sttController.isSttListening;

  @override
  Duration get recordingElapsed => _recorderController.recordingElapsed;

  @override
  Future<bool> initialize() => _sttController.initialize();

  @override
  Future<void> startRecording({
    required void Function(Duration elapsed) onTick,
    required void Function() onMaxReached,
  }) async {
    // recorder 内部:
    // 1. 权限检查 (MoodAudioRecorderException 抛错时转 MoodAudioException)
    // 2. 生成临时明文路径
    // 3. recorder.start 写明文 (失败时回滚 temp 路径)
    // 4. 100ms tick Timer + 3min auto-stop callback
    try {
      await _recorderController.start(
        onTick: onTick,
        onMaxReached: onMaxReached,
      );
    } on MoodAudioRecorderException catch (e) {
      // 转译 recorder 私有异常 → 公开 MoodAudioException 保持 page 层 API 兼容
      throw MoodAudioException(e.message);
    }
    // STT 启动 listen (如果可用) — R122 P2-1 step 1 委派到 _sttController
    await _sttController.startListen();
  }

  @override
  Future<MoodAudioResult?> stopRecording() async {
    if (!_recorderController.isRecording) return null;
    final outcome = await _recorderController.stop();
    if (outcome == null) return null;
    return MoodAudioResult(
      plainPath: outcome.plainPath,
      durationMs: outcome.durationMs,
    );
  }

  @override
  Future<void> pauseRecording() => _recorderController.pause();

  @override
  Future<void> resumeRecording() => _recorderController.resume();

  @override
  Future<void> cancelRecording() async {
    await _recorderController.cancel();
    // STT 也停 — R122 P2-1 step 1 委派到 _sttController
    await _sttController.stop();
  }

  @override
  Stream<String> get sttTranscriptStream => _sttController.sttTranscriptStream;

  @override
  Future<void> stopStt() => _sttController.stop();

  @override
  Future<void> dispose() async {
    // R122 P2-1 step 2: recorder dispose 委派 (内部 stop + 删 temp)
    await _recorderController.dispose();
    // R122 P2-1 step 1: STT dispose 委派
    await _sttController.dispose();
  }
}

/// 公开异常 — 给 page 捕获后展示 snackbar
class MoodAudioException implements Exception {
  final String message;
  const MoodAudioException(this.message);
  @override
  String toString() => 'MoodAudioException: $message';
}
