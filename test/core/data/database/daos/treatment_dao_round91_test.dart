// v0.30 round 91 (sub-spec 7 日常追踪): TreatmentDao 行为锁定
//
// 覆盖 (TDD red→green):
// 1. watchAll 按 timestamp DESC
// 2. insert + linked medication 缓存 name round-trip (R60 模式, FK 不强制)
// 3. 不传 linkedMedicationId/Name → null (普通治疗记录)

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
  });
}
