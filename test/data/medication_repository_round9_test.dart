// v0.13 (Round 9) MedicationRepository.setActive + update 路径测试
import 'package:chroniccare/data/database/app_database.dart';
import 'package:chroniccare/data/database/medication_mapper.dart';
import 'package:chroniccare/data/database/medication_times.dart';
import 'package:chroniccare/data/repositories/medication_repository_impl.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late MedicationRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = MedicationRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addMed({
    String name = '氟西汀',
    double dosage = 40,
    String unit = 'mg',
    List<HourMinute> times = const [HourMinute(hour: 8, minute: 0)],
    bool isActive = true,
    DateTime? endDate,
  }) {
    return repo.add(
      name: name,
      dosage: dosage,
      dosageUnit: unit,
      times: times,
      isActive: isActive,
      endDate: endDate,
    );
  }

  Future<Medication> getMed(int id) async {
    return (db.select(db.medications)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  group('setActive - 软停药/恢复', () {
    test('active → stopped: isActive=false, endDate=now', () async {
      final id = await addMed();
      final before = DateTime.now();
      final ok = await repo.setActive(medicationId: id, isActive: false);
      expect(ok, isTrue);
      // 给 100ms 缓冲,避免 clock skew
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final med = await getMed(id);
      expect(med.isActive, isFalse);
      expect(med.endDate, isNotNull);
      // endDate 在 before 之后（差不超过 5 秒）
      expect(
        med.endDate!.difference(before).inSeconds,
        inInclusiveRange(0, 5),
      );
    });

    test('stopped → active: isActive=true, endDate 清空', () async {
      final id = await addMed(
        isActive: false,
        endDate: DateTime(2026, 5, 1),
      );
      final ok = await repo.setActive(medicationId: id, isActive: true);
      expect(ok, isTrue);

      final med = await getMed(id);
      expect(med.isActive, isTrue);
      expect(med.endDate, isNull);
    });

    test('active → active: 幂等（endDate 不变）', () async {
      final id = await addMed();
      final ok = await repo.setActive(medicationId: id, isActive: true);
      expect(ok, isTrue);

      final med = await getMed(id);
      expect(med.isActive, isTrue);
      expect(med.endDate, isNull);
    });

    test('不存在的 id → 返回 false', () async {
      final ok = await repo.setActive(medicationId: 9999, isActive: false);
      expect(ok, isFalse);
    });

    test('watchAll（含 inactive）能监听到 isActive 变化', () async {
      final id = await addMed();
      // 用 allMedicationsProvider 的查询路径（含 inactive）来验证
      final initial = await db.watchAllMedicationsIncludingInactive().first;
      expect(initial.first.isActive, isTrue);

      await repo.setActive(medicationId: id, isActive: false);
      final updated = await db.watchAllMedicationsIncludingInactive().first;
      expect(updated.first.isActive, isFalse);
      expect(updated.first.endDate, isNotNull);
    });
  });

  group('update - 改 name/times/dosage 保留其他字段', () {
    test('改 name + times', () async {
      final id = await addMed();
      final original = await getMed(id).then((m) => m.toEntity());

      final updated = original.copyWith(
        name: '舍曲林',
        times: const [
          HourMinute(hour: 8, minute: 0),
          HourMinute(hour: 20, minute: 0),
        ],
      );
      final ok = await repo.update(updated);
      expect(ok, isTrue);

      final after = await getMed(id);
      expect(after.name, '舍曲林');
      expect(after.times.length, 2);
      expect(after.dosage, original.dosage); // 保留
      expect(after.dosageUnit, original.dosageUnit); // 保留
    });

    test('改 dosage + unit', () async {
      final id = await addMed();
      final original = await getMed(id).then((m) => m.toEntity());

      final updated = original.copyWith(
        dosage: 60,
        dosageUnit: '片',
      );
      final ok = await repo.update(updated);
      expect(ok, isTrue);

      final after = await getMed(id);
      expect(after.dosage, 60);
      expect(after.dosageUnit, '片');
      expect(after.name, original.name); // 保留
    });

    test('改 isActive + endDate（模拟对话框里的停药操作）', () async {
      final id = await addMed();
      final original = await getMed(id).then((m) => m.toEntity());

      final updated = original.copyWith(
        isActive: false,
        endDate: Value(DateTime(2026, 8, 15)),
      );
      await repo.update(updated);

      final after = await getMed(id);
      expect(after.isActive, isFalse);
      expect(after.endDate, DateTime(2026, 8, 15));
    });

    test('多次 update 都成功（id 不变）', () async {
      final id = await addMed();
      var med = await getMed(id).then((m) => m.toEntity());

      med = med.copyWith(name: 'A');
      await repo.update(med);

      med = (await getMed(id)).toEntity().copyWith(name: 'B');
      await repo.update(med);

      med = (await getMed(id)).toEntity().copyWith(name: 'C');
      await repo.update(med);

      final finalMed = await getMed(id);
      expect(finalMed.name, 'C');
      expect(finalMed.id, id);
    });
  });

  group('round 9 集成：完整编辑流程', () {
    test('add → setActive(false) → setActive(true) → update', () async {
      final id = await addMed();

      // 1. 停药
      await repo.setActive(medicationId: id, isActive: false);
      var med = await getMed(id);
      expect(med.isActive, isFalse);
      expect(med.endDate, isNotNull);

      // 2. 恢复
      await repo.setActive(medicationId: id, isActive: true);
      med = await getMed(id);
      expect(med.isActive, isTrue);
      expect(med.endDate, isNull);

      // 3. 改名 + 改时间
      var entity = med.toEntity().copyWith(
        name: '新药名',
        times: const [
          HourMinute(hour: 9, minute: 30),
        ],
      );
      await repo.update(entity);

      med = await getMed(id);
      expect(med.name, '新药名');
      expect(med.times.length, 1);
      expect(med.times.first.hour, 9);
      expect(med.times.first.minute, 30);
      expect(med.isActive, isTrue); // 仍然 active
    });
  });
}
