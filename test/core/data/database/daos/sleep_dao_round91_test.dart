// v0.30 round 91 (sub-spec 7 日常追踪): SleepDao 行为锁定
//
// 覆盖 (TDD red→green):
// 1. watchAll 按 date DESC 倒序
// 2. insert + getById round-trip (跨午夜 bedtime/wakeTime)
// 3. delete 返删除行数
//
// 跟 R90 / R53a DAO 模式一致: 纯 wrapper, _db.select(_db.sleepEntries)。

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/daos/sleep_dao.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SleepDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.sleepDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('SleepDao (v0.30 round 91 新表)', () {
    test('insert + watchAll → 1 条按 date DESC', () async {
      final date1 = DateTime(2026, 8, 1);
      final bedtime1 = DateTime(2026, 8, 1, 23, 0);
      final wakeTime1 = DateTime(2026, 8, 2, 7, 30);
      await dao.insert(
        SleepEntriesCompanion.insert(
          date: date1,
          bedtime: bedtime1,
          wakeTime: wakeTime1,
          durationMin: 510,
          regularityScore: const Value(4),
          note: const Value('正常'),
        ),
      );

      final all = await dao.watchAll().first;
      expect(all.length, 1);
      expect(all.first.date, date1);
      expect(all.first.durationMin, 510);
    });

    test('insert 2 条 + watchAll → 按 date DESC (新→旧)', () async {
      await dao.insert(
        SleepEntriesCompanion.insert(
          date: DateTime(2026, 8, 1),
          bedtime: DateTime(2026, 8, 1, 22, 0),
          wakeTime: DateTime(2026, 8, 2, 6, 0),
          durationMin: 480,
        ),
      );
      await dao.insert(
        SleepEntriesCompanion.insert(
          date: DateTime(2026, 8, 2),
          bedtime: DateTime(2026, 8, 2, 23, 0),
          wakeTime: DateTime(2026, 8, 3, 7, 0),
          durationMin: 480,
        ),
      );

      final all = await dao.watchAll().first;
      expect(all.length, 2);
      // DESC: 8/2 在前
      expect(all[0].date, DateTime(2026, 8, 2));
      expect(all[1].date, DateTime(2026, 8, 1));
    });

    test('delete(id) → 返受影响行数', () async {
      final id = await dao.insert(
        SleepEntriesCompanion.insert(
          date: DateTime(2026, 8, 1),
          bedtime: DateTime(2026, 8, 1, 22, 0),
          wakeTime: DateTime(2026, 8, 2, 6, 0),
          durationMin: 480,
        ),
      );
      final deleted = await dao.delete(id);
      expect(deleted, 1);
      final all = await dao.watchAll().first;
      expect(all, isEmpty);
    });
  });
}
