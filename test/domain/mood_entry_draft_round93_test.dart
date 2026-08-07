// v0.28 Round 93 (#71 修复): mood_entry_draft 草稿值对象 0 测试补齐
//
// 覆盖:
// - 必填 score + tags 构造
// - 9 个 optional 字段 nullable
// - draft 不可变 (final 字段)
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/entities/mood_entry_draft.dart';

void main() {
  group('MoodEntryDraft 必填字段', () {
    test('最小构造: score + tags=[]', () {
      const draft = MoodEntryDraft(score: 3, tags: []);
      expect(draft.score, 3);
      expect(draft.tags, isEmpty);
    });

    test('带 tags', () {
      const draft = MoodEntryDraft(score: 4, tags: ['calm', 'sleepy']);
      expect(draft.tags, ['calm', 'sleepy']);
    });
  });

  group('MoodEntryDraft 可选字段默认 null', () {
    test('note / at / 4 维 全部默认 null', () {
      const draft = MoodEntryDraft(score: 3, tags: []);
      expect(draft.note, isNull);
      expect(draft.at, isNull);
      expect(draft.energy, isNull);
      expect(draft.sleep, isNull);
      expect(draft.anxiety, isNull);
    });

    test('audio 3 字段默认 null', () {
      const draft = MoodEntryDraft(score: 3, tags: []);
      expect(draft.audioPath, isNull);
      expect(draft.audioTranscript, isNull);
      expect(draft.audioDurationMs, isNull);
    });
  });

  group('MoodEntryDraft 全字段填充', () {
    test('4 维模式 + 语音模式', () {
      final at = DateTime(2026, 8, 3, 10, 30);
      const draft = MoodEntryDraft(
        score: 5,
        tags: ['great'],
        note: '今天睡得好',
        at: null, // explicit null for clarity
        energy: 4,
        sleep: 5,
        anxiety: 4,
        audioPath: '/path/to/audio.m4a.enc',
        audioTranscript: '今天感觉不错',
        audioDurationMs: 60000,
      );
      expect(draft.note, '今天睡得好');
      expect(draft.energy, 4);
      expect(draft.sleep, 5);
      expect(draft.anxiety, 4);
      expect(draft.audioPath, '/path/to/audio.m4a.enc');
      expect(draft.audioTranscript, '今天感觉不错');
      expect(draft.audioDurationMs, 60000);
      // at 显式 null 仍允许
      expect(draft.at, isNull);
      // 显式传 at 也允许
      final draft2 = MoodEntryDraft(
        score: 5,
        tags: [],
        at: at,
      );
      expect(draft2.at, at);
    });
  });
}
