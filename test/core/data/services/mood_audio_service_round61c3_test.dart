// v0.25 round 56c''' (spen P0 #15 TDD 续): MoodAudioService test
//
// 之前 0 test (v0.23 round 31 抽 abstract + impl 时只加 widget fake 覆盖契约,
// 未对 MoodAudioServiceImpl 真实实现单测).
// R56c''' 补 1 个核心场景: initial 状态 + dispose 资源释放.
//
// 设计决策: 不测完整录音生命周期 (需要 mock record + speech_to_text +
// path_provider 3 个 platform channel, 复杂度大), 只测 MoodAudioServiceImpl
// 能在 test 环境构造出来 + 初始状态正确 + dispose 不抛.
import 'package:chroniccare/core/data/services/mood_audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoodAudioServiceImpl 基础状态', () {
    test('构造: 不抛 (注入 maxDuration + tickInterval)', () {
      // 验证: 1) 不依赖 platform channel 即可构造
      //       2) 注入短 maxDuration + tickInterval 是为了 spen-4 test helper
      //          (之前手工 _recordingTimer.periodic 没法注入, 现在可)
      expect(
        () => MoodAudioServiceImpl(
          maxDuration: const Duration(milliseconds: 100),
          tickInterval: const Duration(milliseconds: 10),
        ),
        returnsNormally,
      );
    });

    test('初始: isRecording = false', () {
      final svc = MoodAudioServiceImpl();
      expect(svc.isRecording, isFalse);
    });

    test('初始: recordingElapsed = Duration.zero', () {
      final svc = MoodAudioServiceImpl();
      expect(svc.recordingElapsed, Duration.zero);
    });

    test('初始: isSttListening = false', () {
      final svc = MoodAudioServiceImpl();
      expect(svc.isSttListening, isFalse);
    });

    test('sttTranscriptStream 是 Stream<String> (broadcast)', () async {
      final svc = MoodAudioServiceImpl();
      // 验证: stream 类型正确, 可 listen 不抛
      final stream = svc.sttTranscriptStream;
      expect(stream, isA<Stream<String>>());
      // broadcast stream 允许多 listener, 这里短暂 listen + cancel 验证可用
      final sub = stream.listen((_) {});
      await sub.cancel();
    });

    test('未 start 就 stopRecording → 返 null (idempotent no-op)', () async {
      final svc = MoodAudioServiceImpl();
      // 未启动时 stopRecording 直接返 null, 不抛
      final result = await svc.stopRecording();
      expect(result, isNull);
    });

    test('未 start 就 cancelRecording → 不抛 (idempotent no-op)', () async {
      final svc = MoodAudioServiceImpl();
      // 未启动时 cancelRecording 直接返, 不抛
      await expectLater(svc.cancelRecording(), completes);
    });
  });

  group('MoodAudioServiceImpl 资源释放 (dispose)', () {
    test('dispose 不抛 (未 start 直接 dispose 也安全)', () async {
      final svc = MoodAudioServiceImpl();
      await expectLater(svc.dispose(), completes);
    });

    test('dispose 后 stopRecording / cancelRecording 不抛 (idempotent)', () async {
      final svc = MoodAudioServiceImpl();
      await svc.dispose();
      // dispose 后状态都是 false, 调用不应抛
      final stopResult = await svc.stopRecording();
      expect(stopResult, isNull);
      await expectLater(svc.cancelRecording(), completes);
    });

    test('dispose 后 sttTranscriptStream 已 close (新 listen 收 done)', () async {
      final svc = MoodAudioServiceImpl();
      await svc.dispose();
      // dispose 关闭了 _sttController, 新 listen 应立即收到 done
      final received = <String>[];
      var doneReceived = false;
      svc.sttTranscriptStream.listen(
        received.add,
        onDone: () => doneReceived = true,
      );
      // pump microtask 让 onDone 触发
      await Future<void>.delayed(Duration.zero);
      expect(doneReceived, isTrue, reason: 'dispose 后 stream 应已 close');
      expect(received, isEmpty);
    });
  });
}
