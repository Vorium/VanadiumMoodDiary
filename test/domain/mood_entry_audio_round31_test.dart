// v0.23 (Round 31) MoodEntryEntity 3 个 audio 字段 round-trip
//
// 测试:
// - 构造带 audio 字段的 entity
// - copyWith 保留 / 替换 audio 字段
// - hasAudio getter
// - == / hashCode 包含 audio 字段
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/core/shared/domain_value.dart';

void main() {
  group('MoodEntryEntity audio fields (v0.23 Round 31)', () {
    test('老数据 (纯文字) — 3 字段默认 null', () {
      final e = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 21),
        score: 3,
      );
      expect(e.audioPath, isNull);
      expect(e.audioTranscript, isNull);
      expect(e.audioDurationMs, isNull);
      expect(e.hasAudio, isFalse);
    });

    test('带 audio 字段构造 + hasAudio = true', () {
      final e = MoodEntryEntity(
        id: 2,
        timestamp: DateTime(2026, 7, 21),
        score: 4,
        audioPath: '/docs/mood_audio/mood_123.m4a.enc',
        audioTranscript: '今天心情不错',
        audioDurationMs: 12500,
      );
      expect(e.audioPath, '/docs/mood_audio/mood_123.m4a.enc');
      expect(e.audioTranscript, '今天心情不错');
      expect(e.audioDurationMs, 12500);
      expect(e.hasAudio, isTrue);
    });

    test('hasAudio — 空字符串视为无录音 (避免误判)', () {
      final e = MoodEntryEntity(
        id: 3,
        timestamp: DateTime(2026, 7, 21),
        score: 3,
        audioPath: '',
      );
      expect(e.hasAudio, isFalse);
    });

    test('copyWith 不传 audio — 保留原值 (向后兼容)', () {
      final original = MoodEntryEntity(
        id: 4,
        timestamp: DateTime(2026, 7, 21),
        score: 3,
        audioPath: '/a.m4a.enc',
        audioTranscript: 'foo',
        audioDurationMs: 5000,
      );
      final copied = original.copyWith(score: 5);
      expect(copied.score, 5);
      expect(copied.audioPath, '/a.m4a.enc');
      expect(copied.audioTranscript, 'foo');
      expect(copied.audioDurationMs, 5000);
    });

    test('copyWith 用 DomainValue 把 audioPath 设成 null (显式清空)', () {
      final original = MoodEntryEntity(
        id: 5,
        timestamp: DateTime(2026, 7, 21),
        score: 3,
        audioPath: '/a.m4a.enc',
      );
      // DomainValue<String?>(null) 显式置 null
      final cleared = original.copyWith(
        audioPath: const DomainValue<String?>(null),
        audioTranscript: const DomainValue<String?>(null),
        audioDurationMs: const DomainValue<int?>(null),
      );
      expect(cleared.audioPath, isNull);
      expect(cleared.audioTranscript, isNull);
      expect(cleared.audioDurationMs, isNull);
    });

    test('== 比较包含 audioPath / transcript / durationMs', () {
      final base = MoodEntryEntity(
        id: 6,
        timestamp: DateTime(2026, 7, 21),
        score: 3,
        audioPath: '/a.m4a.enc',
        audioTranscript: 'foo',
        audioDurationMs: 5000,
      );
      final sameAsBase = MoodEntryEntity(
        id: 6,
        timestamp: DateTime(2026, 7, 21),
        score: 3,
        audioPath: '/a.m4a.enc',
        audioTranscript: 'foo',
        audioDurationMs: 5000,
      );
      final differentPath = base.copyWith(
        audioPath: const DomainValue<String?>('/b.m4a.enc'),
      );
      final differentTranscript = base.copyWith(
        audioTranscript: const DomainValue<String?>('bar'),
      );
      final differentDuration = base.copyWith(
        audioDurationMs: const DomainValue<int?>(6000),
      );

      expect(base, equals(sameAsBase));
      expect(base, isNot(equals(differentPath)));
      expect(base, isNot(equals(differentTranscript)));
      expect(base, isNot(equals(differentDuration)));
    });

    test('hashCode 包含 audio 字段 (同样字段 == 时 hashCode 相同)', () {
      final a = MoodEntryEntity(
        id: 7,
        timestamp: DateTime(2026, 7, 21),
        score: 3,
        audioPath: '/a.m4a.enc',
      );
      final b = MoodEntryEntity(
        id: 7,
        timestamp: DateTime(2026, 7, 21),
        score: 3,
        audioPath: '/a.m4a.enc',
      );
      expect(a.hashCode, b.hashCode);
    });

    test('toString 不泄露音频内容 (只描述 hasAudio + durationMs)', () {
      final e = MoodEntryEntity(
        id: 8,
        timestamp: DateTime(2026, 7, 21),
        score: 3,
        audioPath: '/secret/audio.m4a.enc',
        audioTranscript: '私密内容',
        audioDurationMs: 3000,
      );
      final s = e.toString();
      // 应当描述 hasAudio 状态但不暴露 transcript 内容
      expect(s, contains('hasAudio=true'));
      expect(s, contains('audioDurationMs=3000'));
      expect(s.contains('私密内容'), isFalse);
    });
  });
}
