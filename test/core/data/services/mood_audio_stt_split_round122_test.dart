// v1.1.0+164 R122 P2-1 (mood_audio_service 拆 3 facade step 1) regression
// test: MoodAudioStt 抽独立 class 后, 主 service 委派模式 + STT state 完整
// 保留。
//
// Goal: if anyone re-merges STT state/methods 回主 service 文件 (undoing
// the split), this test fails. The split is a soft architectural choice
// (file size + readability), not a functional one — so the test asserts
// structural properties:
//
//   1. MoodAudioStt 文件存在 + 主 service 文件 < 450L (R122 拆后 406L,
//      god-class size guard)
//   2. 主 service 不再含 STT 私有 state fields
//   3. 主 service 不再含 STT 私有 _sttController StreamController
//   4. 主 service 不再调 speech_to_text 包 (委派后不需要直接用)
//   5. MoodAudioStt public API 完整: isSttListening + sttAvailable +
//      sttTranscriptStream + initialize + startListen + stop + dispose
//
// Functional correctness: integration tests under `test/presentation/`
// (mood_dialog_audio_round31 + mood_audio_recorder_round7b + ...)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R122 P2-1 step 1 — mood_audio_service STT 抽独立 class', () {
    const mainPath = 'lib/features/mood/data/services/mood_audio_service.dart';
    const sttPath = 'lib/features/mood/data/services/mood_audio_stt.dart';

    test('主 service + MoodAudioStt 文件双存在', () {
      expect(File(mainPath).existsSync(), isTrue, reason: mainPath);
      expect(File(sttPath).existsSync(), isTrue, reason: sttPath);
    });

    test('主 service 文件 < 450L (R122 拆后 406L, god-class size guard)', () {
      final lines = File(mainPath).readAsLinesSync().length;
      expect(
        lines,
        lessThan(450),
        reason:
            'mood_audio_service.dart 主壳应保持精简 (R122 P2-1 拆 STT 后 406L), '
            '回归到 496+L 表示 STT 逻辑被回填',
      );
    });

    test('主 service 不再含 STT 私有 state fields', () {
      final main = File(mainPath).readAsStringSync();
      // STT state 已迁到 MoodAudioStt
      expect(main, isNot(contains('bool _isSttListening')),
          reason: '主 service 不应再有 _isSttListening (迁到 MoodAudioStt)');
      expect(main, isNot(contains('bool _sttAvailable')),
          reason: '主 service 不应再有 _sttAvailable (迁到 MoodAudioStt)');
      expect(main, isNot(contains('_sttController = StreamController')),
          reason:
              '主 service 不应再有 _sttController StreamController (迁到 MoodAudioStt)');
    });

    test('主 service 不再直接用 speech_to_text 包 (委派后不需要)', () {
      final main = File(mainPath).readAsStringSync();
      expect(
        main,
        isNot(contains("import 'package:speech_to_text")),
        reason: '主 service 不应再 import speech_to_text (委派到 MoodAudioStt)',
      );
      expect(
        main,
        isNot(contains('SpeechToText()'),
        ),
        reason: '主 service 不应再直接构造 SpeechToText (MoodAudioStt 内部封装)',
      );
    });

    test('MoodAudioStt public API 完整 (5 method + 1 stream + 2 getter)', () {
      final stt = File(sttPath).readAsStringSync();
      // 2 getter: isSttListening + sttAvailable
      expect(stt.contains('bool get isSttListening'), isTrue,
          reason: 'MoodAudioStt 应有 isSttListening getter');
      expect(stt.contains('bool get sttAvailable'), isTrue,
          reason: 'MoodAudioStt 应有 sttAvailable getter');
      // 1 stream getter
      expect(stt.contains('Stream<String> get sttTranscriptStream'), isTrue,
          reason: 'MoodAudioStt 应有 sttTranscriptStream Stream getter');
      // 5 method: initialize + startListen + stop + _stopInternal + dispose
      expect(stt.contains('Future<bool> initialize()'), isTrue,
          reason: 'MoodAudioStt 应有 initialize method');
      expect(stt.contains('Future<bool> startListen()'), isTrue,
          reason: 'MoodAudioStt 应有 startListen method');
      expect(stt.contains('Future<void> stop()'), isTrue,
          reason: 'MoodAudioStt 应有 stop method');
      expect(stt.contains('Future<void> _stopInternal()'), isTrue,
          reason: 'MoodAudioStt 应有 _stopInternal method (内部 stop)');
      expect(stt.contains('Future<void> dispose()'), isTrue,
          reason: 'MoodAudioStt 应有 dispose method');
    });

    test('主 service 通过 _sttController 委派 STT (行为不变)', () {
      final main = File(mainPath).readAsStringSync();
      // initialize / stopStt / dispose 委派到 _sttController
      expect(main.contains('_sttController.initialize()'), isTrue,
          reason: '主 service initialize 应委派到 _sttController.initialize()');
      expect(main.contains('_sttController.stop()'), isTrue,
          reason: '主 service stopStt 应委派到 _sttController.stop()');
      expect(main.contains('_sttController.dispose()'), isTrue,
          reason: '主 service dispose 应委派到 _sttController.dispose()');
      // startListen (录音启动后) 也应委派
      expect(main.contains('_sttController.startListen()'), isTrue,
          reason: '主 service startRecording 应委派 STT startListen');
    });
  });
}
