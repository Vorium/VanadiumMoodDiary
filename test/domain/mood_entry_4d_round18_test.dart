/// v0.18 round 18 (P1-15) MoodEntryEntity 4 维度测试
///
/// 覆盖:
/// - energy / sleep / anxiety nullable 字段
/// - isFull4D 业务方法
/// - copyWith 保留 4 维
/// - 老数据(只 score)兼容
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

void main() {
  group('MoodEntryEntity 4 维度', () {
    test('老数据(只 score)isFull4D = false', () {
      final e = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 18, 10, 0),
        score: 3,
      );
      expect(e.score, 3);
      expect(e.energy, isNull);
      expect(e.sleep, isNull);
      expect(e.anxiety, isNull);
      expect(e.isFull4D, isFalse);
    });

    test('新数据 4 维全填 isFull4D = true', () {
      final e = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 18, 10, 0),
        score: 4,
        energy: 3,
        sleep: 4,
        anxiety: 2,
      );
      expect(e.score, 4);
      expect(e.energy, 3);
      expect(e.sleep, 4);
      expect(e.anxiety, 2);
      expect(e.isFull4D, isTrue);
    });

    test('部分填(只有 energy)isFull4D = false', () {
      final e = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 18, 10, 0),
        score: 3,
        energy: 4,
      );
      expect(e.energy, 4);
      expect(e.sleep, isNull);
      expect(e.anxiety, isNull);
      expect(e.isFull4D, isFalse);
    });

    test('copyWith 保留 4 维', () {
      final e = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 18, 10, 0),
        score: 3,
        energy: 2,
        sleep: 4,
        anxiety: 3,
      );
      final e2 = e.copyWith(score: 5);
      expect(e2.id, 1);
      expect(e2.score, 5);
      expect(e2.energy, 2);
      expect(e2.sleep, 4);
      expect(e2.anxiety, 3);
    });

    test('== 和 hashCode 包含 4 维', () {
      final e1 = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 18, 10, 0),
        score: 3,
        energy: 4,
        sleep: 4,
        anxiety: 2,
      );
      final e2 = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 18, 10, 0),
        score: 3,
        energy: 4,
        sleep: 4,
        anxiety: 2,
      );
      final e3 = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 18, 10, 0),
        score: 3,
        energy: 5, // 不同
        sleep: 4,
        anxiety: 2,
      );
      expect(e1, equals(e2));
      expect(e1, isNot(equals(e3)));
      expect(e1.hashCode, equals(e2.hashCode));
    });
  });
}
