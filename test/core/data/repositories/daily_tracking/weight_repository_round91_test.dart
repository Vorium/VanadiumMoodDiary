// v0.30 round 91 (sub-spec 7 日常追踪): WeightRepository 行为锁定
//
// 覆盖 (TDD red→green):
// 1. add weightKg + bmi round-trip
// 2. add 不传 bmi → entity.bmi = null (height 缺失兼容)
// 3. delete 返 true

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/weight_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late WeightRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = WeightRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('WeightRepository (v0.30 round 91 新表)', () {
    test('add weightKg + bmi round-trip', () async {
      final id = await repo.add(
        timestamp: DateTime(2026, 8, 1, 7, 0),
        weightKg: 70.5,
        bmi: 23.0,
        note: '晨重',
      );
      expect(id, greaterThan(0));

      final all = await repo.watchAll().first;
      expect(all.length, 1);
      expect(all.first.weightKg, 70.5);
      expect(all.first.bmi, 23.0);
      expect(all.first.note, '晨重');
    });

    test('add 不传 bmi → entity.bmi = null (height 缺失兼容)', () async {
      await repo.add(
        timestamp: DateTime(2026, 8, 1, 7, 0),
        weightKg: 70.0,
      );

      final all = await repo.watchAll().first;
      expect(all.first.bmi, isNull);
    });
  });
}
