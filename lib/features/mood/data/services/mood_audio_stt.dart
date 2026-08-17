// v1.1.0+164 R122 P2-1 (mood_audio_service 拆 3 facade step 1):
// 抽 STT 状态 + 方法到独立 class。
//
// 拆解动机 (R120 flutter-spec + frame-thinking 跨期残留):
// - mood_audio_service.dart 496L 跨 audio recording + STT + storage 3 业务
// - R31 误判"已闭环" 跨 12 round, flutter-spec R120 重审时仍 > 350L
// - 拆 3 facade: 1) recorder (start/stop/pause/resume + 状态机) 2) stt (本文件)
//   3) orchestrator 留 main 文件
//
// R122 P2-1 step 1 覆盖: STT 部分 (~80L) 抽到本文件, recorder 留
// main 文件待 step 2 处理, storage 已是独立文件 (mood_audio_storage.dart)
//
// R122 P2-1 step 1 范围: STT 状态字段 + 4 method (initialize / startListen
// / stop / _stopInternal) + 1 stream getter (sttTranscriptStream)
import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:chroniccare/core/shared/error_sinks.dart';

/// 情绪日记录音 STT 编排 (v0.23 round 31, R122 P2-1 step 1 抽独立 class)
///
/// 抽象: 配合 MoodAudioRecorder 完成"录音 + 实时识别 partial result" 编排。
/// 公开 getters: isSttListening (R112-04 加 sttTranscriptStream)
class MoodAudioStt {
  final SpeechToText _stt;
  bool _isSttListening = false;
  bool _sttAvailable = false;
  final StreamController<String> _sttController =
      StreamController.broadcast();

  /// 公开 partial transcript stream (page 订阅实时显示)
  Stream<String> get sttTranscriptStream => _sttController.stream;

  /// 是否正在 STT 监听
  bool get isSttListening => _isSttListening;

  /// STT 初始化结果 (true = STT 可用; false = 设备不支持 / 权限被拒)
  bool get sttAvailable => _sttAvailable;

  MoodAudioStt({SpeechToText? stt}) : _stt = stt ?? SpeechToText();

  /// 初始化 STT (申请权限, 加载 on-device 模型)
  ///
  /// 返回 true = STT 可用;false = 设备不支持 / 权限被拒。
  /// 录音功能不依赖 STT, 即使 false 录音 + 加密 + 保存仍正常工作。
  Future<bool> initialize() async {
    try {
      _sttAvailable = await _stt.initialize(
        onError: (errorNotification) {
          // STT 错误 = graceful degrade, 不影响录音
          audioErrorSink(
            where: 'mood_audio_stt.onError',
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
        where: 'mood_audio_stt.initialize',
        error: e,
        stack: st,
        note: 'STT initialize failed — recording without transcript',
      );
      _sttAvailable = false;
      return false;
    }
  }

  /// 启动 STT listen (partial + dictation mode)
  ///
  /// 必须在录音启动后调用 (跟录音生命周期绑定)
  Future<bool> startListen() async {
    if (!_sttAvailable) return false;
    if (_isSttListening) return true;
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
      return true;
    } catch (e, st) {
      // STT 启动失败 = graceful degrade (录音继续)
      audioErrorSink(
        where: 'mood_audio_stt.startListen',
        error: e,
        stack: st,
        note: 'STT listen failed — recording continues without transcript',
      );
      _isSttListening = false;
      return false;
    }
  }

  /// 停止 STT (公开, page 主动停 STT 但录音继续的场景用)
  ///
  /// 注意: speech_to_text 在 stop() 时会触发最后 1 次 onResult with final=true
  Future<void> stop() async {
    try {
      if (_isSttListening) {
        await _stt.stop();
      }
    } catch (e, st) {
      audioErrorSink(
        where: 'mood_audio_stt.stop',
        error: e,
        stack: st,
        note: 'STT stop failed',
      );
    }
    _isSttListening = false;
    // 最终文本由 sttTranscriptStream 的最后一条推送决定
    // (page 端会收集 stream 里的 final recognized text 存到 mood_entry)
  }

  /// 内部停止 (cancelRecording / dispose 用, 跟 stop 行为一致但语义区分)
  Future<void> _stopInternal() async {
    try {
      if (_isSttListening) {
        await _stt.stop();
      }
    } catch (e, st) {
      audioErrorSink(
        where: 'mood_audio_stt._stopInternal',
        error: e,
        stack: st,
      );
    }
    _isSttListening = false;
  }

  /// 释放 STT 资源 (page dispose 时调)
  Future<void> dispose() async {
    await _stopInternal();
    await _sttController.close();
  }
}
