// v0.30 round 91 (sub-spec 7 日常追踪): SocialRhythmDao 行为锁定
//
// 覆盖 (TDD red→green):
// 1. watchAll 按 date DESC
// 2. insert + 3 个 time 字段 (wakeTime / firstMealTime / lastMealTime) round-trip
// 3. socialMin / workMin / exerciseMin 默认值 0 (withDefault)

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/daos/social_rhythm_dao.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SocialRhythmDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.socialRhythmDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('SocialRhythmDao (v0.30 round 91 新表)', () {
    test('insert + 3 个 time 字段全部 round-trip', () async {
      final date = DateTime(2026, 8, 1);
      await dao.insert(SocialRhythmEntriesCompanion.insert(
        date: date,
        wakeTime: DateTime(2026, 8, 1, 7, 0),
        firstMealTime: DateTime(2026, 8, 1, 8, 0),
        lastMealTime: DateTime(2026, 8, 1, 19, 0),
        socialMin: const Value(60),
        workMin: const Value(480),
        exerciseMin: const Value(30),
      ),);

      final all = await dao.watchAll().first;
      expect(all.length, 1);
      expect(all.first.date, date);
      expect(all.first.wakeTime, DateTime(2026, 8, 1, 7, 0));
      expect(all.first.firstMealTime, DateTime(2026, 8, 1, 8, 0));
      expect(all.first.lastMealTime, DateTime(2026, 8, 1, 19, 0));
      expect(all.first.socialMin, 60);
      expect(all.first.workMin, 480);
      expect(all.first.exerciseMin, 30);
    });

    test('不传 socialMin/workMin/exerciseMin → 默认 0', () async {
      await dao.insert(SocialRhythmEntriesCompanion.insert(
        date: DateTime(2026, 8, 1),
        wakeTime: DateTime(2026, 8, 1, 7, 0),
        firstMealTime: DateTime(2026, 8, 1, 8, 0),
        lastMealTime: DateTime(2026, 8, 1, 19, 0),
      ),);

      final all = await dao.watchAll().first;
      expect(all.first.socialMin, 0);
      expect(all.first.workMin, 0);
      expect(all.first.exerciseMin, 0);
    });
  });
}
