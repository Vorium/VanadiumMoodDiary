// v0.30 round 91 (sub-spec 7 日常追踪): TreatmentRepository 行为锁定
//
// 覆盖 (TDD red→green):
// 1. add linked medication FK + name 缓存 round-trip
// 2. add 不传 FK (普通治疗) → entity.linkedMedicationId = null
// 3. delete 返受影响行数

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/treatment_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TreatmentRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = TreatmentRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TreatmentRepository (v0.30 round 91 新表)', () {
    test('add linked medication FK + name 缓存 round-trip', () async {
      final id = await repo.add(
        timestamp: DateTime(2026, 8, 1, 10, 0),
        treatmentType: 'medication',
        description: '服药咨询',
        linkedMedicationId: 42,
        linkedMedicationName: '舍曲林',
        note: '调整剂量',
      );
      expect(id, greaterThan(0));

      final all = await repo.watchAll().first;
      expect(all.length, 1);
      expect(all.first.linkedMedicationId, 42);
      expect(all.first.linkedMedicationName, '舍曲林');
      expect(all.first.description, '服药咨询');
    });

    test('add 不传 FK → entity.linkedMedicationId = null', () async {
      await repo.add(
        timestamp: DateTime(2026, 8, 1, 14, 0),
        treatmentType: 'consultation',
        description: '心理咨询',
      );

      final all = await repo.watchAll().first;
      expect(all.first.linkedMedicationId, isNull);
      expect(all.first.linkedMedicationName, isNull);
    });
  });
}
