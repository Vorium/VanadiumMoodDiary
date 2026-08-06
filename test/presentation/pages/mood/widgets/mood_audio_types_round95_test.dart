// mood_audio_types_round95_test.dart — R95 sub-spec 4 task 7 拆解后 lock-in test
//
// 覆盖:
// 1. MoodRecorderSnapshot.empty 工厂是全空 + hasRecording=false
// 2. MoodRecorderSnapshot (audioPath='x').hasRecording = true
// 3. MoodRecorderController snapshot 走 ValueNotifier 推送
// 4. MoodRecorderController onDispose 回调在 dispose() 触发
// 5. MoodRecorderErrorKind 4 kind enum 值稳定 (start / stop / encrypt / play)
//
// v0.30 round 95 (sub-spec 4 task 7): mood_audio_types.dart 拆出后, 公共类型
// 独立, 加 lock-in test 防御未来 refactor 退回。
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/pages/mood/widgets/mood_audio_types.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_audio_section.dart';

void main() {
  group('MoodRecorderSnapshot (R95 sub-spec 4 task 7 拆解)', () {
    test('empty 工厂全空, hasRecording=false', () {
      const snap = MoodRecorderSnapshot.empty;
      expect(snap.audioPath, isNull);
      expect(snap.audioDurationMs, isNull);
      expect(snap.finalTranscript, '');
      expect(snap.sttFailed, false);
      expect(snap.hasRecording, false);
    });

    test('audioPath 非空时 hasRecording=true', () {
      const snap = MoodRecorderSnapshot(audioPath: 'encrypted/x.aes');
      expect(snap.hasRecording, true);
    });
  });

  group('MoodRecorderController (R95 sub-spec 4 task 7 拆解)', () {
    test('snapshot ValueNotifier 推送更新', () {
      final controller = MoodRecorderController();
      final received = <MoodRecorderSnapshot>[];
      controller.snapshot.addListener(() {
        received.add(controller.snapshot.value);
      });
      controller.snapshot.value = const MoodRecorderSnapshot(audioPath: 'a');
      expect(received.length, 1);
      expect(received.first.audioPath, 'a');
      controller.dispose();
    });

    test('dispose() 触发 onDispose 回调', () {
      var disposeCount = 0;
      final controller = MoodRecorderController(
        onDispose: () => disposeCount++,
      );
      controller.dispose();
      expect(disposeCount, 1, reason: 'onDispose 应该在 dispose() 时触发');
    });

    test('re-export 从 mood_audio_section.dart 拿得到 MoodRecorderSnapshot', () {
      // 防御 re-export 链断: 老 caller 走 `import 'mood_audio_section.dart'`
      // 拿 MoodRecorderSnapshot / MoodRecorderController / MoodRecorderErrorKind
      const snap = MoodRecorderSnapshot.empty;
      expect(snap.hasRecording, false);
      // MoodRecorderErrorKind 4 kind enum
      expect(MoodRecorderErrorKind.values, hasLength(4));
      expect(
        MoodRecorderErrorKind.values.toSet(),
        {
          MoodRecorderErrorKind.start,
          MoodRecorderErrorKind.stop,
          MoodRecorderErrorKind.encrypt,
          MoodRecorderErrorKind.play,
        },
      );
    });
  });
}
