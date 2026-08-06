// v0.30 round 91 (sub-spec 7 日常追踪): AnxietyAgitationDao 行为锁定
//
// 覆盖 (TDD red→green):
// 1. watchAll 按 timestamp DESC
// 2. insert + anxietyScore + agitationScore 1-5 round-trip
// 3. delete 返删除行数

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/daos/anxiety_agitation_dao.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AnxietyAgitationDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.anxietyAgitationDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('AnxietyAgitationDao (v0.30 round 91 新表)', () {
    test('insert + anxietyScore + agitationScore round-trip', () async {
      await dao.insert(AnxietyAgitationEntriesCompanion.insert(
        timestamp: DateTime(2026, 8, 1, 15, 0),
        anxietyScore: 3,
        agitationScore: 2,
        note: const Value('轻微焦虑'),
      ),);

      final all = await dao.watchAll().first;
      expect(all.length, 1);
      expect(all.first.anxietyScore, 3);
      expect(all.first.agitationScore, 2);
      expect(all.first.note, '轻微焦虑');
    });

    test('不传 note → null', () async {
      await dao.insert(AnxietyAgitationEntriesCompanion.insert(
        timestamp: DateTime(2026, 8, 1, 15, 0),
        anxietyScore: 4,
        agitationScore: 3,
      ),);

      final all = await dao.watchAll().first;
      expect(all.first.note, isNull);
    });

    test('delete(id) → 返 1 + watchAll 返空', () async {
      final id = await dao.insert(AnxietyAgitationEntriesCompanion.insert(
        timestamp: DateTime(2026, 8, 1, 15, 0),
        anxietyScore: 3,
        agitationScore: 3,
      ),);
      final deleted = await dao.delete(id);
      expect(deleted, 1);
      final all = await dao.watchAll().first;
      expect(all, isEmpty);
    });
  });
}
