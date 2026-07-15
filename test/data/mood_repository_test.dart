// v0.14 (Round 12A) 测试 MoodVisual 静态 helper + MoodEntryEntity.tags getter
//
// 重构前:MoodRepository.decodeTags / .emojiFor / .labelFor / .colorFor
// 重构后:
//   - decodeTags → MoodEntryEntity.tags getter（解析 tagsJson）
//   - emojiFor / labelFor / colorFor → MoodVisual 静态方法
import 'package:chroniccare/data/utils/json_codec.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/mood_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoodEntryEntity.tags (原 MoodRepository.decodeTags)', () {
    test('空 JSON 返回空列表', () {
      expect(JsonCodec.decodeStringList('[]'), isEmpty);
      expect(JsonCodec.decodeStringList(''), isEmpty);
    });

    test('单标签解析', () {
      final e = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 15),
        score: 3,
        tagsJson: '["焦虑"]',
      );
      expect(e.tags, ['焦虑']);
    });

    test('多标签解析', () {
      final e = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 15),
        score: 3,
        tagsJson: '["焦虑","抑郁","失眠"]',
      );
      expect(e.tags, ['焦虑', '抑郁', '失眠']);
    });

    test('特殊字符正确转义', () {
      final e = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 15),
        score: 3,
        tagsJson: r'["a\"b","c\\d"]',
      );
      expect(e.tags, ['a"b', r'c\d']);
    });

    test('默认空 tagsJson = const []', () {
      final e = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 15),
        score: 3,
      );
      expect(e.tagsJson, '[]');
      expect(e.tags, isEmpty);
    });
  });

  group('MoodVisual 静态映射（原 MoodRepository.xxxFor）', () {
    test('emojiFor 1-5 全覆盖', () {
      expect(MoodVisual.emojiFor(1), isNotEmpty);
      expect(MoodVisual.emojiFor(2), isNotEmpty);
      expect(MoodVisual.emojiFor(3), isNotEmpty);
      expect(MoodVisual.emojiFor(4), isNotEmpty);
      expect(MoodVisual.emojiFor(5), isNotEmpty);
      // 1 和 5 应该是不同的 emoji
      expect(MoodVisual.emojiFor(1), isNot(MoodVisual.emojiFor(5)));
    });

    test('emojiFor 未知分数 fallback', () {
      expect(MoodVisual.emojiFor(0), isNotEmpty);
      expect(MoodVisual.emojiFor(99), isNotEmpty);
    });

    test('labelFor 1=很差, 5=很好', () {
      expect(MoodVisual.labelFor(1), '很差');
      expect(MoodVisual.labelFor(5), '很好');
    });

    test('colorFor 返回有效颜色', () {
      for (int s = 1; s <= 5; s++) {
        final c = MoodVisual.colorFor(s);
        expect(c, isA<Color>());
      }
    });
  });
}
