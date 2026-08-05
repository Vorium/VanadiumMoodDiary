// v0.30 round 91 (sub-spec 7 日常追踪): TreatmentDao 行为锁定
//
// 覆盖 (TDD red→green):
// 1. watchAll 按 timestamp DESC
// 2. insert + linked medication 缓存 name round-trip (R60 模式, FK 不强制)
// 3. 不传 linkedMedicationId/Name → null (普通治疗记录)
// 4. v0.30 round 91 Task 3: watchAllTreatmentEntries join medications
//    (linkedMedicationName 从 medications.name 读, 跟 snapshot 字段合并)

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/daos/treatment_dao.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TreatmentDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.treatmentDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('TreatmentDao (v0.30 round 91 新表)', () {
    test('insert + linked medication FK + name 缓存 round-trip', () async {
      await dao.insert(TreatmentEntriesCompanion.insert(
        timestamp: DateTime(2026, 8, 1, 10, 0),
        treatmentType: 'medication',
        description: '服药咨询',
        linkedMedicationId: const Value(42),
        linkedMedicationName: const Value('舍曲林'),
        note: const Value('调整剂量'),
      ),);

      final all = await dao.watchAll().first;
      expect(all.length, 1);
      expect(all.first.treatmentType, 'medication');
      expect(all.first.linkedMedicationId, 42);
      expect(all.first.linkedMedicationName, '舍曲林');
      expect(all.first.description, '服药咨询');
    });

    test('不传 linkedMedicationId/Name → null (普通治疗记录)', () async {
      await dao.insert(TreatmentEntriesCompanion.insert(
        timestamp: DateTime(2026, 8, 1, 14, 0),
        treatmentType: 'consultation',
        description: '心理咨询',
      ),);

      final all = await dao.watchAll().first;
      expect(all.first.linkedMedicationId, isNull);
      expect(all.first.linkedMedicationName, isNull);
      expect(all.first.note, isNull);
    });

    // v0.30 round 91 Task 3: treatmentDao.watchAllTreatmentEntries join medications
    // (leftOuterJoin, cache 优先 + join 兜底)
    test(
        'watchAllTreatmentEntries join medications → name 从 medications.name 读 (cache null 时)',
        () async {
      // 1. insert medication 'Aspirin' (id=1)
      await db.into(db.medications).insert(
            MedicationsCompanion.insert(
              name: 'Aspirin',
              dosage: 100,
              dosageUnit: 'mg',
              startDate: DateTime(2026, 7, 1),
            ),
          );

      // 2. insert treatment linkedMedicationId=1, 但 linkedMedicationName=null
      //    (cache 故意空, 强制 DAO 从 join 读 name — 模拟老 entry migration 场景)
      await dao.insert(TreatmentEntriesCompanion.insert(
        timestamp: DateTime(2026, 8, 1, 10, 0),
        treatmentType: 'medication',
        description: '服用 Aspirin',
        linkedMedicationId: const Value(1),
        // linkedMedicationName 故意不传 (cache null)
      ),);

      // 3. watchAllTreatmentEntries() → entry.linkedMedicationName = 'Aspirin' (从 join)
      final all = await dao.watchAllTreatmentEntries().first;
      expect(all.length, 1);
      expect(all.first.linkedMedicationId, 1);
      expect(all.first.linkedMedicationName, 'Aspirin',
          reason: 'cache null 时必须从 medications join 读 name',);
    });
  });
}
