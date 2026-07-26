// v0.12 (Round 6) MedicationRepository.updateRefill 集成测试
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/medication/medication_repository_impl.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_draft.dart';
import 'package:chroniccare/domain/repositories/medication_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MedicationRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MedicationRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addMed({DateTime? refillAt, int refillDays = 7}) async {
    return repo.add(
      MedicationDraft(
        name: '氟西汀',
        dosage: 40,
        dosageUnit: DosageUnit.mg,
        times: const [HourMinute(hour: 8, minute: 0)],
        refillAt: refillAt,
        refillReminderDays: refillDays,
      ),
    );
  }

  group('MedicationRepository.updateRefill', () {
    test('添加时直接设续方日期', () async {
      final id = await addMed(
        refillAt: DateTime(2026, 8, 1),
        refillDays: 7,
      );
      final med = await (db.select(db.medications)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(med.refillAt, DateTime(2026, 8, 1));
      expect(med.refillReminderDays, 7);
    });

    test('不传 refillAt → 存为 null', () async {
      final id = await addMed();
      final med = await (db.select(db.medications)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(med.refillAt, isNull);
      expect(med.refillReminderDays, 7); // 默认
    });

    test('updateRefill 只更新续方日期, 保留其他字段', () async {
      final id = await addMed();
      // 修改 refillAt
      final ok = await repo.updateRefill(
        medicationId: id,
        refillAt: DateTime(2026, 9, 15),
        // 不传 reminderDays = 不变
      );
      expect(ok, isTrue);
      final med = await (db.select(db.medications)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(med.refillAt, DateTime(2026, 9, 15));
      expect(med.refillReminderDays, 7); // 保持默认
      expect(med.name, '氟西汀'); // 名字未变
      expect(med.dosage, 40); // 剂量未变
    });

    test('updateRefill 同时改提醒天数', () async {
      final id = await addMed();
      await repo.updateRefill(
        medicationId: id,
        refillAt: DateTime(2026, 8, 1),
        reminderDays: 14,
      );
      final med = await (db.select(db.medications)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(med.refillAt, DateTime(2026, 8, 1));
      expect(med.refillReminderDays, 14);
    });

    test('updateRefill 传 null 清除续方日期', () async {
      final id = await addMed(refillAt: DateTime(2026, 8, 1));
      // 清空
      await repo.updateRefill(
        medicationId: id,
        refillAt: null,
      );
      final med = await (db.select(db.medications)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(med.refillAt, isNull);
      // reminderDays 保持不变
      expect(med.refillReminderDays, 7);
    });

    test('不存在的 id → 返回 false', () async {
      final ok = await repo.updateRefill(
        medicationId: 9999,
        refillAt: DateTime(2026, 8, 1),
      );
      expect(ok, isFalse);
    });

    test('watchAll 仍能监听到 refillAt 变化', () async {
      final id = await addMed();
      // 等第一帧 stream emit
      final initial = await repo.watchAll().first;
      expect(initial.first.refillAt, isNull);
      // 更新
      await repo.updateRefill(
        medicationId: id,
        refillAt: DateTime(2026, 9, 1),
      );
      final updated = await repo.watchAll().first;
      expect(updated.first.refillAt, DateTime(2026, 9, 1));
    });

    test('多个药各自独立续方设置', () async {
      final id1 = await addMed(refillAt: DateTime(2026, 8, 1), refillDays: 7);
      final id2 = await addMed(refillAt: DateTime(2026, 9, 15), refillDays: 14);
      final meds = await repo.watchAll().first;
      expect(meds.length, 2);
      final m1 = meds.firstWhere((m) => m.id == id1);
      final m2 = meds.firstWhere((m) => m.id == id2);
      expect(m1.refillAt, DateTime(2026, 8, 1));
      expect(m1.refillReminderDays, 7);
      expect(m2.refillAt, DateTime(2026, 9, 15));
      expect(m2.refillReminderDays, 14);
    });
  });

  group('Medication schema v5', () {
    test('medication 包含 refillAt + refillReminderDays 字段', () async {
      final id = await repo.add(
        MedicationDraft(
          name: '氟西汀',
          dosage: 40,
          dosageUnit: DosageUnit.mg,
          times: const [HourMinute(hour: 8, minute: 0)],
        ),
      );
      final med = await (db.select(db.medications)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      // 字段存在 + 类型正确
      expect(med.refillAt, isNull);
      expect(med.refillReminderDays, isA<int>());
    });
  });
}
