// 1.1.0 round 2b — mood_entries.statusPhrase drift round-trip 测试
//
// 验证 statusPhrase 字段在 drift DB (in-memory) 中能完整 insert → 读出 → toEntity
// 流转,无字段丢失;老数据(未传 statusPhrase)读出 null;buildMoodEntryEntity 透传。

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/mood/mood_entry_mapper.dart';
import 'package:chroniccare/core/shared/domain_value.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() async => db.close());

  test('mood statusPhrase round-trip: insert 带状态短语 → 读出还原', () async {
    final id = await db.moodDao.insert(
      MoodEntryEntity(
        id: 0,
        timestamp: DateTime(2026, 8, 15, 12),
        score: 4,
        statusPhrase: '平稳',
      ).toCompanion(),
    );
    final saved = (await db.moodDao.getAll()).firstWhere((e) => e.id == id);
    expect(saved.statusPhrase, '平稳');
    expect(saved.toEntity().statusPhrase, '平稳');
  });

  test('老数据 statusPhrase = null', () async {
    final id = await db.moodDao.insert(
      MoodEntryEntity(
        id: 0,
        timestamp: DateTime(2026, 8, 15, 12),
        score: 3,
      ).toCompanion(),
    );
    final saved = (await db.moodDao.getAll()).firstWhere((e) => e.id == id);
    expect(saved.statusPhrase, isNull);
    expect(saved.toEntity().statusPhrase, isNull);
  });

  test('buildMoodEntryEntity statusPhrase 透传 (默认 null)', () {
    final e = buildMoodEntryEntity(
      id: 1,
      timestamp: DateTime(2026, 8, 15, 12),
      score: 3,
      tags: const [],
      statusPhrase: '平静',
    );
    expect(e.statusPhrase, '平静');

    final legacy = buildMoodEntryEntity(
      id: 2,
      timestamp: DateTime(2026, 8, 15, 12),
      score: 3,
      tags: const [],
    );
    expect(legacy.statusPhrase, isNull);
  });

  test('copyWith 保留/更新/清除 statusPhrase', () {
    final base = MoodEntryEntity(
      id: 1,
      timestamp: DateTime(2026, 8, 15, 12),
      score: 3,
      statusPhrase: '平稳',
    );
    final updated = base.copyWith(
      statusPhrase: const DomainValue('平静'),
    );
    expect(updated.statusPhrase, '平静');
    expect(base.copyWith().statusPhrase, '平稳');
    final cleared = updated.copyWith(
      statusPhrase: const DomainValue(null),
    );
    expect(cleared.statusPhrase, isNull);
  });
}
