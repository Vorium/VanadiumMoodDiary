// v0.14 (Round 12A) MoodEntryEntity / mapper 单元测试
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/mood/mood_entry_mapper.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/core/shared/domain_value.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

MoodEntry _driftRow({
  int id = 1,
  DateTime? timestamp,
  int score = 3,
  String tagsJson = '[]',
  String? note,
}) {
  return MoodEntry(
    id: id,
    timestamp: timestamp ?? DateTime(2026, 7, 15, 21, 0),
    score: score,
    tagsJson: tagsJson,
    note: note,
  );
}

void main() {
  group('MoodEntryToEntity (Drift → Entity)', () {
    test('基础字段正确映射', () {
      final row = _driftRow(id: 5, score: 4, note: '工作汇报顺利');
      final entity = row.toEntity();
      expect(entity.id, 5);
      expect(entity.score, 4);
      expect(entity.note, '工作汇报顺利');
      expect(entity.tagsJson, '[]');
    });

    test('tagsJson 完整保留（不解析在 toEntity 阶段）', () {
      final row = _driftRow(tagsJson: '["焦虑","失眠"]');
      final entity = row.toEntity();
      expect(entity.tagsJson, '["焦虑","失眠"]');
    });
  });

  group('MoodEntryEntityToDrift (Entity → Companion)', () {
    test('toCompanion 字段全包', () {
      final e = MoodEntryEntity(
        id: 0,
        timestamp: DateTime(2026, 7, 15),
        score: 5,
        tagsJson: '["平静"]',
        note: '好日子',
      );
      final c = e.toCompanion();
      expect(c.score.value, 5);
      expect(c.tagsJson.value, '["平静"]');
      expect(c.note.value, '好日子');
    });
  });

  group('Round trip (Drift → Entity → Drift)', () {
    test('完整数据无丢失', () {
      final original = _driftRow(
        id: 42,
        timestamp: DateTime(2026, 7, 15, 12, 30),
        score: 2,
        tagsJson: '["焦虑","烦躁"]',
        note: '今天压力大',
      );
      final roundTripped = original.toEntity().toCompanion();
      final row = MoodEntry(
        id: 42,
        timestamp: roundTripped.timestamp.value,
        score: roundTripped.score.value,
        tagsJson: roundTripped.tagsJson.value,
        note: roundTripped.note.value,
      );
      expect(row.id, original.id);
      expect(row.timestamp, original.timestamp);
      expect(row.score, original.score);
      expect(row.tagsJson, original.tagsJson);
      expect(row.note, original.note);
    });
  });

  group('业务方法', () {
    test('tags getter 解析 tagsJson', () {
      final e = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026),
        score: 3,
        tagsJson: '["焦虑","失眠"]',
      );
      expect(e.tags, ['焦虑', '失眠']);
    });

    test('tags getter 非法 JSON 兜底为空', () {
      final e = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026),
        score: 3,
        tagsJson: 'not-a-json',
      );
      expect(e.tags, isEmpty);
    });

    test('tags getter 空 tagsJson 兜底为空', () {
      final e = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026),
        score: 3,
        tagsJson: '',
      );
      expect(e.tags, isEmpty);
    });

    test('isValidScore 1-5 通过', () {
      for (int s = 1; s <= 5; s++) {
        expect(
          MoodEntryEntity(id: 1, timestamp: DateTime(2026), score: s)
              .isValidScore,
          isTrue,
        );
      }
    });

    test('isValidScore 0 / 6 / -1 / 99 不通过', () {
      expect(
        MoodEntryEntity(id: 1, timestamp: DateTime(2026), score: 0)
            .isValidScore,
        isFalse,
      );
      expect(
        MoodEntryEntity(id: 1, timestamp: DateTime(2026), score: 6)
            .isValidScore,
        isFalse,
      );
      expect(
        MoodEntryEntity(id: 1, timestamp: DateTime(2026), score: -1)
            .isValidScore,
        isFalse,
      );
      expect(
        MoodEntryEntity(id: 1, timestamp: DateTime(2026), score: 99)
            .isValidScore,
        isFalse,
      );
    });

    test('copyWith 基础字段', () {
      final original =
          MoodEntryEntity(id: 1, timestamp: DateTime(2026), score: 3);
      final copy = original.copyWith(score: 5);
      expect(copy.score, 5);
      expect(copy.id, original.id);
    });

    test('copyWith 可空 note 用 Value<>, 能"清空"', () {
      final original = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026),
        score: 3,
        note: '备忘',
      );
      final cleared = original.copyWith(note: const DomainValue<String?>(null));
      expect(cleared.note, isNull);
    });

    test('copyWith 不传 note 保留原值', () {
      final original = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026),
        score: 3,
        note: '备忘',
      );
      final copy = original.copyWith(score: 5);
      expect(copy.note, '备忘');
    });

    test('默认值 tagsJson="[]"', () {
      final e = MoodEntryEntity(id: 1, timestamp: DateTime(2026), score: 3);
      expect(e.tagsJson, '[]');
    });
  });

  group('等值', () {
    test('== hashCode 字段全等才相等', () {
      final a = MoodEntryEntity(id: 1, timestamp: DateTime(2026), score: 3);
      final b = MoodEntryEntity(id: 1, timestamp: DateTime(2026), score: 3);
      final c = MoodEntryEntity(id: 1, timestamp: DateTime(2026), score: 4);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('tagsJson 不同则不等', () {
      final a = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026),
        score: 3,
        tagsJson: '[]',
      );
      final b = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026),
        score: 3,
        tagsJson: '["焦虑"]',
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('集成：从 DB 读 MoodEntry → toEntity → UI 流程', () {
    test('内存 DB 写一条 → 读 → 转 entity → 字段一致', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async => db.close());

      final ts = DateTime(2026, 7, 15, 21, 30);
      await db.moodDao.insert(
        MoodEntriesCompanion.insert(
          timestamp: ts,
          score: 4,
          tagsJson: const Value('["平静","能量高"]'),
          note: const Value('今天不错'),
        ),
      );

      final rows = await db.moodDao.watchAll().first;
      expect(rows.length, 1);

      final entity = rows.first.toEntity();
      expect(entity.score, 4);
      expect(entity.tags, ['平静', '能量高']);
      expect(entity.note, '今天不错');
    });
  });
}
