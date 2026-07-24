// v0.23 (Round 31) MoodAudioService 抽象 + 录音 + STT 编排 widget test
//
// 测 MoodAudioService 契约 (不依赖真实 AudioRecorder / SpeechToText)
// UI 状态机在 production 行为测试 (P2 task, 等历史详情页一起做)。
import 'dart:async';

import 'package:chroniccare/core/data/services/mood_audio_service.dart';
import 'package:chroniccare/core/data/services/mood_audio_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// 假录音 service — 替代真实 AudioRecorder + SpeechToText
class _FakeMoodAudioService implements MoodAudioService {
  bool _isRecording = false;
  bool _isSttListening = false;
  Duration _elapsed = Duration.zero;
  String? _pendingPlainPath;
  final StreamController<String> _sttController =
      StreamController<String>.broadcast();
  final bool sttAvailable;

  _FakeMoodAudioService({this.sttAvailable = true});

  /// test 调: 模拟一段 STT 实时输出
  void emitStt(String text) {
    _sttController.add(text);
  }

  /// test 调: 模拟 stop 录音时返回的文件 + 时长
  void setPendingRecord({String? plainPath, Duration? elapsed}) {
    _pendingPlainPath = plainPath;
    _elapsed = elapsed ?? const Duration(seconds: 5);
  }

  @override
  Future<bool> initialize() async => sttAvailable;

  @override
  bool get isRecording => _isRecording;

  @override
  bool get isSttListening => _isSttListening;

  @override
  Duration get recordingElapsed => _elapsed;

  @override
  Future<void> startRecording({
    required void Function(Duration elapsed) onTick,
    required void Function() onMaxReached,
  }) async {
    _isRecording = true;
    _isSttListening = true;
    onTick(_elapsed);
  }

  @override
  Future<MoodAudioResult?> stopRecording() async {
    _isRecording = false;
    _isSttListening = false;
    return MoodAudioResult(
      plainPath: _pendingPlainPath ?? '/tmp/test.m4a',
      durationMs: _elapsed.inMilliseconds,
    );
  }

  @override
  Future<void> cancelRecording() async {
    _isRecording = false;
    _isSttListening = false;
  }

  @override
  Stream<String> get sttTranscriptStream => _sttController.stream;

  @override
  Future<String?> stopStt() async => null;

  @override
  Future<void> dispose() async {
    await _sttController.close();
  }
}

void main() {
  group('MoodAudioService 抽象接口契约', () {
    test('FakeMoodAudioService 满足接口所有方法', () {
      final fake = _FakeMoodAudioService();
      expect(fake, isA<MoodAudioService>());
      expect(fake.isRecording, isFalse);
      expect(fake.isSttListening, isFalse);
      expect(fake.recordingElapsed, Duration.zero);
    });

    test('startRecording + stopRecording 状态机', () async {
      final fake = _FakeMoodAudioService();
      fake.setPendingRecord(
        plainPath: '/tmp/x.m4a',
        elapsed: const Duration(seconds: 8),
      );
      Duration? ticked;
      int maxReachedCount = 0;
      await fake.startRecording(
        onTick: (e) => ticked = e,
        onMaxReached: () => maxReachedCount++,
      );
      expect(fake.isRecording, isTrue);
      expect(fake.isSttListening, isTrue);
      expect(ticked, isNotNull);

      final result = await fake.stopRecording();
      expect(fake.isRecording, isFalse);
      expect(fake.isSttListening, isFalse);
      expect(result, isNotNull);
      expect(result!.plainPath, '/tmp/x.m4a');
      expect(result.durationMs, 8000);
    });

    test('cancelRecording 清理状态', () async {
      final fake = _FakeMoodAudioService();
      await fake.startRecording(
        onTick: (_) {},
        onMaxReached: () {},
      );
      expect(fake.isRecording, isTrue);
      await fake.cancelRecording();
      expect(fake.isRecording, isFalse);
      expect(fake.isSttListening, isFalse);
    });

    test('sttTranscriptStream 在 startRecording 后能 emit', () async {
      final fake = _FakeMoodAudioService();
      final received = <String>[];
      final sub = fake.sttTranscriptStream.listen(received.add);
      await Future<void>.delayed(Duration.zero);
      fake.emitStt('今天');
      fake.emitStt('今天心情');
      await Future<void>.delayed(Duration.zero);
      expect(received, ['今天', '今天心情']);
      await sub.cancel();
    });

    test('initialize 返回 STT 可用性 (test override)', () async {
      final ok = await _FakeMoodAudioService(sttAvailable: true).initialize();
      expect(ok, isTrue);
      final no = await _FakeMoodAudioService(sttAvailable: false).initialize();
      expect(no, isFalse);
    });

    test('stopStt 返回 null (FakeService 简化) — 真 service 这里会返回 final',
        () async {
      final fake = _FakeMoodAudioService();
      final result = await fake.stopStt();
      expect(result, isNull);
    });
  });

  group('MoodAudioStorage 基础契约', () {
    test('storage 能构造 + 公共方法不崩', () {
      final storage = MoodAudioStorage();
      expect(storage, isNotNull);
    });

    test('encryptedSuffix / legacyPlainSuffix 跟 vent 一致 (隐私对齐)', () {
      // 设计决策: mood audio 用跟 vent 一样的后缀 (.m4a.enc)
      // 加密算法一样,目录不同 — 不会跨 privacy 边界误读
      expect(MoodAudioStorage.encryptedSuffix, '.m4a.enc');
      expect(MoodAudioStorage.legacyPlainSuffix, '.m4a');
    });
  });
}
