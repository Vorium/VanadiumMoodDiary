// v1.1.0+165 R122 P2-1 (mood_audio_service 拆 3 facade step 2) regression
// test: MoodAudioRecorder 抽独立 class 后, 主 service 委派模式 + recorder
// state 完整保留。
//
// Goal: if anyone re-merges recorder state/methods 回主 service 文件 (undoing
// the split), this test fails. The split is a soft architectural choice
// (file size + readability), not a functional one — so the test asserts
// structural properties:
//
//   1. MoodAudioRecorder 文件存在 + 主 service 文件 < 280L (R122 拆后 251L,
//      god-class size guard)
//   2. 主 service 不再含 recorder 私有 state fields
//   3. 主 service 不再含 _recordingTimer 字段
//   4. 主 service 不再含 _tempRecordPath 字段
//   5. 主 service 不再调 record 包 (委派后不需要直接用)
//   6. MoodAudioRecorder public API 完整: 4 getter + 5 method + 1 callback
//      + 1 value class + 1 exception
//   7. 主 service 通过 _recorderController 委派 recorder (行为不变)
//
// Functional correctness: integration tests under `test/presentation/`
// (mood_dialog_audio_round31 + mood_audio_recorder_round7b + ...)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R122 P2-1 step 2 — mood_audio_service recorder 抽独立 class', () {
    const mainPath = 'lib/core/data/services/mood_audio_service.dart';
    const recorderPath = 'lib/core/data/services/mood_audio_recorder.dart';

    test('主 service + MoodAudioRecorder 文件双存在', () {
      expect(File(mainPath).existsSync(), isTrue, reason: mainPath);
      expect(File(recorderPath).existsSync(), isTrue, reason: recorderPath);
    });

    test('主 service 文件 < 280L (R122 拆后 251L, god-class size guard)', () {
      final lines = File(mainPath).readAsLinesSync().length;
      expect(
        lines,
        lessThan(280),
        reason:
            'mood_audio_service.dart 主壳应保持精简 (R122 P2-1 step 2 拆 recorder 后 251L), '
            '回归到 280+L 表示 recorder 逻辑被回填',
      );
    });

    test('主 service 不再含 recorder 私有 state fields', () {
      final main = File(mainPath).readAsStringSync();
      // recorder state 已迁到 MoodAudioRecorder
      expect(main, isNot(contains('bool _isRecording')),
          reason: '主 service 不应再有 _isRecording (迁到 MoodAudioRecorder)');
      expect(main, isNot(contains('bool _isPaused')),
          reason: '主 service 不应再有 _isPaused (迁到 MoodAudioRecorder)');
      expect(main, isNot(contains('Duration _pausedTotal')),
          reason: '主 service 不应再有 _pausedTotal (迁到 MoodAudioRecorder)');
      expect(main, isNot(contains('DateTime? _recordingStart')),
          reason: '主 service 不应再有 _recordingStart (迁到 MoodAudioRecorder)');
      expect(main, isNot(contains('Duration _recordingElapsed')),
          reason: '主 service 不应再有 _recordingElapsed (迁到 MoodAudioRecorder)');
    });

    test('主 service 不再含 _recordingTimer 字段', () {
      final main = File(mainPath).readAsStringSync();
      expect(
        main,
        isNot(contains('Timer? _recordingTimer')),
        reason: '主 service 不应再有 _recordingTimer (迁到 MoodAudioRecorder)',
      );
    });

    test('主 service 不再含 _tempRecordPath 字段', () {
      final main = File(mainPath).readAsStringSync();
      expect(
        main,
        isNot(contains('String? _tempRecordPath')),
        reason: '主 service 不应再有 _tempRecordPath (迁到 MoodAudioRecorder)',
      );
    });

    test('主 service 不再直接用 record 包 (委派后不需要)', () {
      final main = File(mainPath).readAsStringSync();
      expect(
        main,
        isNot(contains("import 'package:record/record.dart'")),
        reason: '主 service 不应再 import record (委派到 MoodAudioRecorder)',
      );
      // 用 negative lookbehind 排除 MoodAudioRecorder (Mood 是 facade 前缀)
      // \bAudioRecorder( 会被 MoodAudioRecorder( 命中 → 用 (?<!Mood)
      expect(
        main,
        isNot(matches(RegExp(r'(?<!Mood)AudioRecorder\('))),
        reason:
            '主 service 不应再直接构造 AudioRecorder (MoodAudioRecorder 内部封装)',
      );
      expect(
        main,
        isNot(contains('RecordConfig(')),
        reason: '主 service 不应再直接构造 RecordConfig (MoodAudioRecorder 内部封装)',
      );
    });

    test('主 service 不再含 dart:io (委派后不需要直接用 File)', () {
      final main = File(mainPath).readAsStringSync();
      expect(
        main,
        isNot(contains("import 'dart:io'")),
        reason: '主 service 不应再 import dart:io (MoodAudioRecorder 内部封装 File 操作)',
      );
    });

    test('MoodAudioRecorder public API 完整 (4 getter + 5 method + 1 callback + 1 value + 1 exception)',
        () {
      final recorder = File(recorderPath).readAsStringSync();
      // 4 getter
      expect(recorder.contains('bool get isRecording'), isTrue,
          reason: 'MoodAudioRecorder 应有 isRecording getter');
      expect(recorder.contains('bool get isPaused'), isTrue,
          reason: 'MoodAudioRecorder 应有 isPaused getter');
      expect(recorder.contains('Duration get recordingElapsed'), isTrue,
          reason: 'MoodAudioRecorder 应有 recordingElapsed getter');
      expect(recorder.contains('String? get tempRecordPath'), isTrue,
          reason: 'MoodAudioRecorder 应有 tempRecordPath getter');
      // 1 callback setter
      expect(recorder.contains('setAutoStopCallback'), isTrue,
          reason: 'MoodAudioRecorder 应有 setAutoStopCallback method');
      // 5 method: start / stop / pause / resume / cancel / dispose (6 total)
      expect(recorder.contains('Future<void> start('), isTrue,
          reason: 'MoodAudioRecorder 应有 start method');
      expect(recorder.contains('Future<MoodAudioRecordingOutcome?> stop()'), isTrue,
          reason: 'MoodAudioRecorder 应有 stop method (返 MoodAudioRecordingOutcome)');
      expect(recorder.contains('Future<void> pause()'), isTrue,
          reason: 'MoodAudioRecorder 应有 pause method');
      expect(recorder.contains('Future<void> resume()'), isTrue,
          reason: 'MoodAudioRecorder 应有 resume method');
      expect(recorder.contains('Future<void> cancel()'), isTrue,
          reason: 'MoodAudioRecorder 应有 cancel method');
      expect(recorder.contains('Future<void> dispose()'), isTrue,
          reason: 'MoodAudioRecorder 应有 dispose method');
      // 1 value class
      expect(recorder.contains('class MoodAudioRecordingOutcome'), isTrue,
          reason: 'MoodAudioRecorder 应有 MoodAudioRecordingOutcome value class');
      // 1 exception (公开, 跟 service 层 MoodAudioException 区分)
      expect(recorder.contains('class MoodAudioRecorderException'), isTrue,
          reason:
              'MoodAudioRecorder 应有 MoodAudioRecorderException (公开, service 层 catch 转 MoodAudioException)');
    });

    test('主 service 通过 _recorderController 委派 recorder (行为不变)', () {
      final main = File(mainPath).readAsStringSync();
      // start / stop / pause / resume / cancel / dispose 委派到 _recorderController
      expect(main.contains('_recorderController.start('), isTrue,
          reason: '主 service startRecording 应委派到 _recorderController.start()');
      expect(main.contains('_recorderController.stop()'), isTrue,
          reason: '主 service stopRecording 应委派到 _recorderController.stop()');
      expect(main.contains('_recorderController.pause()'), isTrue,
          reason: '主 service pauseRecording 应委派到 _recorderController.pause()');
      expect(main.contains('_recorderController.resume()'), isTrue,
          reason: '主 service resumeRecording 应委派到 _recorderController.resume()');
      expect(main.contains('_recorderController.cancel()'), isTrue,
          reason: '主 service cancelRecording 应委派到 _recorderController.cancel()');
      expect(main.contains('_recorderController.dispose()'), isTrue,
          reason: '主 service dispose 应委派到 _recorderController.dispose()');
      // 4 getter 委派
      expect(main.contains('_recorderController.isRecording'), isTrue,
          reason: '主 service isRecording 应委派到 _recorderController.isRecording');
      expect(main.contains('_recorderController.isPaused'), isTrue,
          reason: '主 service isPaused 应委派到 _recorderController.isPaused');
      expect(main.contains('_recorderController.recordingElapsed'), isTrue,
          reason:
              '主 service recordingElapsed 应委派到 _recorderController.recordingElapsed');
      // auto-stop 回调挂载
      expect(main.contains('setAutoStopCallback'), isTrue,
          reason: '主 service 应挂 auto-stop 回调 (3min 到期时委派 stopRecording)');
    });

    test('主 service 异常转译: MoodAudioRecorderException → MoodAudioException',
        () {
      final main = File(mainPath).readAsStringSync();
      expect(
        main,
        contains('on MoodAudioRecorderException catch (e)'),
        reason:
            '主 service startRecording 应 catch MoodAudioRecorderException 转 MoodAudioException 保持 page 层 API 兼容',
      );
      expect(
        main,
        contains('throw MoodAudioException(e.message)'),
        reason: '主 service 应 throw MoodAudioException(e.message) 保持公开 API 不变',
      );
    });
  });
}
