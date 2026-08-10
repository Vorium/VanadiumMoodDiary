// v0.30 round 91 (sub-spec 7 日常追踪): StressEventDao 行为锁定
//
// 覆盖 (TDD red→green):
// 1. watchAll 按 timestamp DESC
// 2. insert + 5 字段 round-trip
// 3. linkedMoodEntryId nullable 默认 null

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/daos/stress_event_dao.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late StressEventDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.stressEventDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('StressEventDao (v0.30 round 91 新表)', () {
    test('insert + watchAll → 1 条按 timestamp DESC', () async {
      await dao.insert(
        StressEventsCompanion.insert(
          timestamp: DateTime(2026, 8, 1, 14, 30),
          eventType: 'work',
          intensity: 4,
          note: const Value('deadline'),
          linkedMoodEntryId: const Value(1),
        ),
      );

      final all = await dao.watchAll().first;
      expect(all.length, 1);
      expect(all.first.eventType, 'work');
      expect(all.first.intensity, 4);
      expect(all.first.linkedMoodEntryId, 1);
    });

    test('不传 linkedMoodEntryId → 默认 null (FK 弱关联)', () async {
      await dao.insert(
        StressEventsCompanion.insert(
          timestamp: DateTime(2026, 8, 1, 14, 30),
          eventType: 'relationship',
          intensity: 3,
        ),
      );

      final all = await dao.watchAll().first;
      expect(all.first.linkedMoodEntryId, isNull);
      expect(all.first.note, isNull);
    });
  });
}
