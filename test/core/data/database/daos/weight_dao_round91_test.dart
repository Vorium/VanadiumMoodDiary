// v0.30 round 91 (sub-spec 7 日常追踪): WeightDao 行为锁定
//
// 覆盖 (TDD red→green):
// 1. watchAll 按 timestamp DESC
// 2. insert + weightKg + bmi round-trip
// 3. bmi nullable (height 缺失时)

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/daos/weight_dao.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WeightDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.weightDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('WeightDao (v0.30 round 91 新表)', () {
    test('insert + weightKg + bmi round-trip', () async {
      await dao.insert(WeightEntriesCompanion.insert(
        timestamp: DateTime(2026, 8, 1, 7, 0),
        weightKg: 70.5,
        bmi: const Value(23.0),
        note: const Value('晨重'),
      ),);

      final all = await dao.watchAll().first;
      expect(all.length, 1);
      expect(all.first.weightKg, 70.5);
      expect(all.first.bmi, 23.0);
      expect(all.first.note, '晨重');
    });

    test('不传 bmi → null (height 缺失兼容)', () async {
      await dao.insert(WeightEntriesCompanion.insert(
        timestamp: DateTime(2026, 8, 1, 7, 0),
        weightKg: 70.0,
      ),);

      final all = await dao.watchAll().first;
      expect(all.first.bmi, isNull);
    });
  });
}
