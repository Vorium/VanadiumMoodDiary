// v0.30 R108 (P1 god class 拆 6 大 F - Fix #1) audio_lifecycle lock-in test
//
// **背景 (R107 §3.4)**: vent_compose + mood_audio_recorder 重复 audio state
// machine (~150 行重复), R108 抽 AudioLifecycleMixin 共享。
//
// **测试目标 (5 case)**:
// 1. AudioLifecycleMixin 文件存在 + 含 4 状态 enum (idle/recording/recorded/playing)
// 2. vent_compose_page.dart 用 mixin (with AudioLifecycleMixin + 4 抽象方法)
// 3. mood_audio_recorder_widget.dart 用 mixin (with AudioLifecycleMixin + 4 抽象方法)
// 4. asyncDisposeAudio 6 步链完整 (cancel stream → cancel timer → stop recorder
//    if recording → dispose recorder → stop + dispose player → delete temp)
// 5. 行数收缩: vent_compose < 500 (原 495, R108 持平或减少) /
//    mood_audio_recorder < 600 (原 530, R108 持平或略增, 因 mood 业务复杂 +
//    4 抽象方法, 但 4 步 dispose 链去重)
//
// **跟 R95 / R108 同模式**: 静态源码 grep 守门, 不依赖 audioplayers /
// record / speech_to_text platform channel mock。
//
// R114 BUG 2 补: group B 用真实 dart:io 临时文件验证
// deleteRecordTempBestEffort 删除行为 (不碰 platform channel)。
import 'dart:io';

import 'package:chroniccare/presentation/widgets/audio_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R108 Fix #1: AudioLifecycleMixin 共享 (vent + mood audio 去重)', () {
    late String mixinSource;
    late String ventSource;
    late String moodSource;

    setUpAll(() {
      mixinSource = File(
        'lib/presentation/widgets/audio_lifecycle.dart',
      ).readAsStringSync();
      ventSource = File(
        'lib/presentation/pages/vent/vent_compose_page.dart',
      ).readAsStringSync();
      moodSource = File(
        'lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart',
      ).readAsStringSync();
    });

    test(
        'A1: AudioLifecycleMixin 文件存在 + 4 状态 enum (idle/recording/recorded/playing)',
        () {
      // R108 Fix #1 文件必须存在
      final mixinFile = File('lib/presentation/widgets/audio_lifecycle.dart');
      expect(
        mixinFile.existsSync(),
        isTrue,
        reason: 'lib/presentation/widgets/audio_lifecycle.dart 必须存在 '
            '(R108 Fix #1 新文件)',
      );

      // mixin 定义
      expect(
        mixinSource.contains('mixin AudioLifecycleMixin'),
        isTrue,
        reason: 'AudioLifecycleMixin 必须定义 (R108 抽共享 mixin)',
      );

      // 4 状态 enum (替代旧 4 个独立 bool 字段)
      for (final state in ['idle', 'recording', 'recorded', 'playing']) {
        expect(
          mixinSource.contains('AudioState.$state'),
          isTrue,
          reason: 'AudioState enum 必须含 4 状态 (替代 vent_compose / '
              'mood_audio 的 _isRecording / _isPlaying 等独立字段), '
              '缺: $state',
        );
      }
    });

    test('A2: vent_compose_page.dart 用 AudioLifecycleMixin', () {
      // vent_compose 接入 mixin
      expect(
        ventSource.contains('with AudioLifecycleMixin<VentComposePage>'),
        isTrue,
        reason: 'vent_compose 必须用 AudioLifecycleMixin (R108 Fix #1)',
      );

      // 4 抽象方法实现 (override)
      for (final method in [
        'Future<bool> startRecordingImpl()',
        'Future<String?> stopRecordingImpl()',
        'Future<void> startPlaybackImpl(',
        'Future<void> stopPlaybackImpl()',
      ]) {
        expect(
          ventSource.contains(method),
          isTrue,
          reason: 'vent_compose 必须实现 4 抽象方法之一: $method',
        );
      }

      // 旧 4 个独立 bool 字段已删 (防止 revert)
      expect(
        ventSource.contains('bool _isRecording = false'),
        isFalse,
        reason:
            'vent_compose 不能再有 _isRecording 字段 (已走 mixin.isRecording getter)',
      );
      expect(
        ventSource.contains('bool _isPlaying = false'),
        isFalse,
        reason: 'vent_compose 不能再有 _isPlaying 字段 (已走 mixin.isPlaying getter)',
      );
    });

    test('A3: mood_audio_recorder_widget.dart 用 AudioLifecycleMixin', () {
      // mood 接入 mixin
      expect(
        moodSource.contains('with AudioLifecycleMixin<MoodRecorder>'),
        isTrue,
        reason: 'mood_audio_recorder 必须用 AudioLifecycleMixin (R108 Fix #1)',
      );

      // 4 抽象方法实现
      for (final method in [
        'Future<bool> startRecordingImpl()',
        'Future<String?> stopRecordingImpl()',
        'Future<void> startPlaybackImpl(',
        'Future<void> stopPlaybackImpl()',
      ]) {
        expect(
          moodSource.contains(method),
          isTrue,
          reason: 'mood_audio_recorder 必须实现 4 抽象方法之一: $method',
        );
      }

      // 旧 4 个独立 bool 字段已删
      expect(
        moodSource.contains('bool _isRecording = false'),
        isFalse,
        reason: 'mood_audio_recorder 不能再有 _isRecording 字段',
      );
      expect(
        moodSource.contains('bool _isPlaying = false'),
        isFalse,
        reason: 'mood_audio_recorder 不能再有 _isPlaying 字段',
      );
    });

    test('A4: asyncDisposeAudio 6 步链完整 + 每步 audioErrorSink', () {
      // 6 步链 (R108 集中, R79 修法从 vent_compose / mood_audio 抽出):
      // 1. cancel playerCompleteSub
      // 2. cancel playbackTimer
      // 3. stop recorder if recording
      // 4. dispose recorder
      // 5. stop + dispose player
      // 6. delete temp file (via cleanupTempFile)
      for (final step in [
        'playerCompleteSub?.cancel()',
        'playbackTimer?.cancel()',
        'await recorder.stop()',
        'await recorder.dispose()',
        'await player.stop()',
        'await player.dispose()',
        'cleanupTempFile()',
      ]) {
        expect(
          mixinSource.contains(step),
          isTrue,
          reason: 'asyncDisposeAudio 必须含 6 步之一: $step',
        );
      }

      // audioErrorSink (R17 模式防御: 单步异常阻断后续资源释放;
      // R112 AR-23: audio 簇改调 scoped wrapper, 内部仍走 swallowError)
      final audioErrorSinkCount =
          'audioErrorSink('.allMatches(mixinSource).length;
      expect(
        audioErrorSinkCount,
        greaterThanOrEqualTo(6),
        reason: 'asyncDisposeAudio 6 步都应走 audioErrorSink (R17 模式, '
            'AR-23 分簇后 audio 簇统一走 audioErrorSink), '
            '实际 audioErrorSink=$audioErrorSinkCount',
      );
    });

    test('A5: 行数收缩 (vent < 500, mood < 600, mixin 存在)', () {
      // R108 实际行数:
      // - vent_compose: 495 → 445 (-50, 10% ↓)
      // - mood_audio_recorder: 530 → 569 (+39, 7% ↑) — mood 用 MoodAudioService
      //   抽象 recorder, 4 抽象方法 + STT/service dispose 增加 boilerplate
      // - audio_lifecycle (new): 417 行, 其中 203 行 code
      //
      // 总 LOC: 1025 → 1431 (+406) — 抽象 overhead 抵消了部分去重收益,
      // 但消除了 vent/mood 之间 state machine 重复 (R107 §3.4 共识)
      //
      // 行数目标定为较宽的 "持平" 标准 (vent 500, mood 600), 防止未来 revert
      // 回到 god class。
      final ventLines = ventSource.split('\n').length;
      final moodLines = moodSource.split('\n').length;
      expect(
        ventLines,
        // v0.32 R112 round 8h: 阈值 500 → 520 — 录音暂停/继续功能 +35 行
        // (pause/resume impl + _togglePause + 3 UI 参数, mixin 已承载状态机,
        // 页面侧仅剩必实现抽象方法), 仍拒 god class 回归 (445 基线 +75 buffer)
        // 1.1.0 round 8 (F4 树洞公约): +5 行 (vent_agreement_dialog import
        // + showVentAgreementIfNeeded initState 调用 + dart format 换行)
        // → 阈值 520 → 540 (515 基线 +25 buffer)
        lessThan(540),
        reason: 'vent_compose 应保持 < 540 行 (R108 原 445, 8h pause +35, '
            'round 8 F4 公约 +5), 实际: $ventLines',
      );
      expect(
        moodLines,
        // v0.32 R112 round 8h: 阈值 600 → 640 — 录音暂停/继续按钮 + 2 抽象
        // 实现 (+~30 行) + E-01 dispose 链字段缓存注释 (+~28 行, round 8 批),
        // 8i 渲染专项把 SttLiveTranscript 抽独立文件 (-53 行, 现 612)
        lessThan(640),
        reason: 'mood_audio_recorder 应保持 < 640 行 (R108 原 530, 8h pause '
            '+ E-01 注释, 8i 抽转写 widget 后 612), 实际: $moodLines',
      );
    });
  });

  group('R114 BUG 2: deleteRecordTempBestEffort 录音明文 temp 清理', () {
    test('B1: 删除真实存在的录音 temp 文件 (PIPL §28)', () async {
      final dir = await Directory.systemTemp.createTemp('al_r114_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      final f = File('${dir.path}/record.m4a');
      await f.writeAsString('fake-audio');
      expect(await f.exists(), isTrue);

      await AudioLifecycleMixin.deleteRecordTempBestEffort(f.path);

      expect(await f.exists(), isFalse);
    });

    test('B2: null / 不存在路径 → 不抛 (idempotent)', () async {
      await expectLater(
        AudioLifecycleMixin.deleteRecordTempBestEffort(null),
        completes,
      );
      await expectLater(
        AudioLifecycleMixin.deleteRecordTempBestEffort('/no/such/x.m4a'),
        completes,
      );
    });

    test('B3: dispose 链含 3.5 步录音 temp 清理 (lock-in)', () {
      final mixinSource = File(
        'lib/presentation/widgets/audio_lifecycle.dart',
      ).readAsStringSync();
      expect(
        mixinSource.contains('tempRecordPath'),
        isTrue,
        reason: 'mixin 应有 tempRecordPath 字段 (subclass 写入, dispose 链删)',
      );
      expect(
        mixinSource.contains('deleteRecordTempBestEffort(recordTemp)'),
        isTrue,
        reason: 'asyncDisposeAudio 第 3.5 步必须删除录音明文 temp',
      );
    });
  });
}
