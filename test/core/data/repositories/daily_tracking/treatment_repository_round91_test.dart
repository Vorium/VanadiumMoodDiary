// v0.30 round 91 (sub-spec 7 日常追踪): TreatmentRepository 行为锁定
//
// 覆盖 (TDD red→green):
// 1. add linked medication FK + name 缓存 round-trip
// 2. add 不传 FK (普通治疗) → entity.linkedMedicationId = null
//
// v0.30 round 91 Task 3: TreatmentRepositoryImpl.submitEntry (写时 snapshot name):
// 3. submitEntry 不传 linkedMedicationId → entity.linkedMedicationName = null
// 4. submitEntry linkedMedicationId → 写时 snapshot name, medication rename 不影响 history
// 5. submitEntry linkedMedicationId 不存在 → name=null, 不 crash (R60 FK 不强制)

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/treatment_repository_impl.dart';
import 'package:chroniccare/domain/entities/treatment_entry.dart';
import 'package:drift/drift.dart' show Value;
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

  // v0.30 round 91 Task 3: TreatmentRepositoryImpl.submitEntry (写时 snapshot name)
  group('TreatmentRepositoryImpl.submitEntry (R91 Task 3: 写时 snapshot name)', () {
    test('基本 insert (无 linkedMedicationId) → entity.linkedMedicationName = null',
        () async {
      final id = await repo.submitEntry(
        treatmentType: 'consultation',
        description: '心理咨询',
        note: '初次',
      );
      expect(id, greaterThan(0));

      final all = await repo.watchAll().first;
      expect(all.length, 1);
      final e = all.first;
      expect(e, isA<TreatmentEntryEntity>());
      expect(e.linkedMedicationId, isNull);
      expect(e.linkedMedicationName, isNull);
    });

    test(
        'linked insert → snapshot name 写时 (medication rename 不影响 history)',
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

      // 2. submitEntry linkedMedicationId=1 → 写时 snapshot 'Aspirin'
      final id = await repo.submitEntry(
        treatmentType: 'medication',
        description: '服用 Aspirin',
        linkedMedicationId: 1,
      );
      expect(id, greaterThan(0));

      // 3. 改 medication.name = 'Bufferin' (模拟用户改药名)
      await (db.update(db.medications)..where((m) => m.id.equals(1)))
          .write(const MedicationsCompanion(name: Value('Bufferin')));

      // 4. 查 history → entity.linkedMedicationName = 'Aspirin' (历史不变!)
      final all = await repo.watchAll().first;
      expect(all.length, 1);
      expect(all.first.linkedMedicationId, 1);
      expect(all.first.linkedMedicationName, 'Aspirin',
          reason: 'snapshot 写时已存, medication rename 不影响历史治疗记录',);
    });

    test('linkedMedicationId 不存在的 medication_id → name=null 不 crash',
        () async {
      // submitEntry linkedMedicationId=999 (不存在) → snapshot 走 getSingleOrNull 返 null
      final id = await repo.submitEntry(
        treatmentType: 'medication',
        description: '神秘药',
        linkedMedicationId: 999,
      );
      expect(id, greaterThan(0));

      final all = await repo.watchAll().first;
      expect(all.length, 1);
      // R60 模式: FK 不强制, 999 这种孤儿 FK 仍写入, 但 name = null
      expect(all.first.linkedMedicationId, 999);
      expect(all.first.linkedMedicationName, isNull,
          reason: 'medication 不存在时 snapshot = null, 不 crash',);
    });
  });
}
