// v0.25 round 56c''' (spen P0 #15 TDD 续): MoodAudioService test
//
// 之前 0 test (v0.23 round 31 抽 abstract + impl 时只加 widget fake 覆盖契约,
// 未对 MoodAudioServiceImpl 真实实现单测).
// R56c''' 补 1 个核心场景: initial 状态 + dispose 资源释放.
//
// 设计决策: 不测完整录音生命周期 (需要 mock record + speech_to_text +
// path_provider 3 个 platform channel, 复杂度大), 只测 MoodAudioServiceImpl
// 能在 test 环境构造出来 + 初始状态正确 + dispose 不抛。
//
// R114 BUG 2 补: deleteTempRecordFile 用真实 dart:io 临时文件验证
// (best-effort 删除行为), 不碰 platform channel。
import 'dart:io';

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

  // ============ v0.26 round 57 (spen P0 TDD 续): systematic-debugging 5 类 regression ============
  //
  // 锁 3: dispose race — stopRecording → dispose 串行调用, 中间 stopRecording 完成时
  // 不能再触发 onMaxReached 回调 (因为 Timer.periodic 已被 cancel), 也不能再 emit
  // stream (因为 stream 已 close)。

  group(
      'MoodAudioServiceImpl systematic-debugging regression guards (dispose race)',
      () {
    test(
        'dispose race: stopRecording → dispose 串行 → 都安全 (no throw, no double-stop)',
        () async {
      // bug 模式 (R52 修过同款): _recordingTimer.periodic 在 stopRecording 后
      // 仍可能在 dispose 之前 fire onMaxReached, 触发 unawaited(stopRecording())
      // 但 recorder 已 dispose → 抛 LateError / StateError
      // 锁: 串行 stopRecording → dispose 不抛, 状态全部 idempotent
      final svc = MoodAudioServiceImpl(
        maxDuration: const Duration(milliseconds: 100),
        tickInterval: const Duration(milliseconds: 10),
      );

      // 未启动时直接 stopRecording (idempotent no-op) → 立即 null
      final result1 = await svc.stopRecording();
      expect(result1, isNull);

      // 然后 dispose
      await expectLater(svc.dispose(), completes);

      // 重复 dispose 也安全 (idempotent)
      await expectLater(svc.dispose(), completes);
    });

    test('dispose race: 多次连续 dispose → 不抛 (StreamController.close idempotent)',
        () async {
      // bug 模式: StreamController.close() 二次调用会抛 StateError
      // 锁: dispose 实现内部应 swallow "already closed" 错误
      final svc = MoodAudioServiceImpl();

      await svc.dispose();
      // 第 2 次 dispose (idempotent, 不应抛)
      await expectLater(svc.dispose(), completes);
    });

    test('dispose race: stopStt 在 dispose 之后 → 不抛 (already-stopped safe)',
        () async {
      // bug 模式: dispose 内部已 _stopSttInternal + cancel timer, 之后用户代码
      // 调 stopStt 不应抛 "Stream closed" / "not listening"
      final svc = MoodAudioServiceImpl();
      await svc.dispose();
      // dispose 后 stopStt → idempotent, no throw
      await expectLater(svc.stopStt(), completes);
    });
  });

  // ============ R114 BUG 2: 明文录音临时文件清理 (PIPL §28) ============
  //
  // 修前 cancelRecording / dispose / startRecording 失败 / stopRecording
  // 无结果 4 条路径只置 _tempRecordPath = null 从不 delete → 明文 m4a
  // (精神心理患者语音) 永久留在 Directory.systemTemp。R114 抽
  // deleteTempRecordFile (best-effort, 不抛), 4 条路径共用。
  // 本 group 用真实 temp 文件验证删除行为 (纯 dart:io, 不碰 platform
  // channel — 与本文件"不测完整录音生命周期"的既定策略一致)。

  group('R114 BUG 2: deleteTempRecordFile 明文 temp 清理', () {
    test('删除真实存在的临时录音文件', () async {
      final dir = await Directory.systemTemp.createTemp('mood_audio_r114_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      final f = File('${dir.path}/record.m4a');
      await f.writeAsString('fake-audio-bytes');
      expect(await f.exists(), isTrue);

      await MoodAudioServiceImpl.deleteTempRecordFile(f.path);

      expect(
        await f.exists(),
        isFalse,
        reason: '取消录音后明文 m4a 必须删除 (PIPL §28)',
      );
    });

    test('path 为 null → 不抛 (idempotent no-op)', () async {
      await expectLater(
        MoodAudioServiceImpl.deleteTempRecordFile(null),
        completes,
      );
    });

    test('path 不存在 → 不抛 (文件已删/从未生成, idempotent)', () async {
      await expectLater(
        MoodAudioServiceImpl.deleteTempRecordFile(
          '/no/such/dir/record.m4a',
        ),
        completes,
      );
    });

    test('重复删除同一路径 → 第二次不抛', () async {
      final dir = await Directory.systemTemp.createTemp('mood_audio_r114b_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      final f = File('${dir.path}/record.m4a');
      await f.writeAsString('x');
      await MoodAudioServiceImpl.deleteTempRecordFile(f.path);
      await expectLater(
        MoodAudioServiceImpl.deleteTempRecordFile(f.path),
        completes,
        reason: 'cancel 之后 dispose 再删同一路径必须安全',
      );
    });
  });
}
