// v0.28 Round 93 (#72 修复): medication_draft 草稿值对象 0 测试补齐
//
// 覆盖:
// - 必填 4 字段 (name/dosage/dosageUnit/times)
// - 5 个 optional + 2 个默认值 (refillReminderDays=7, isActive=true)
// - copyWith: nullable 字段用 DomainValue 区分 "保持" / "清空"
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/shared/domain_value.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_draft.dart';

void main() {
  group('MedicationDraft 必填 + 默认值', () {
    test('最小构造: name + dosage + dosageUnit + times', () {
      const draft = MedicationDraft(
        name: '舍曲林',
        dosage: 50.0,
        dosageUnit: DosageUnit.mg,
        times: [HourMinute(hour: 8, minute: 0)],
      );
      expect(draft.name, '舍曲林');
      expect(draft.dosage, 50.0);
      expect(draft.dosageUnit, DosageUnit.mg);
      expect(draft.times.length, 1);
    });

    test('refillReminderDays 默认 7', () {
      const draft = MedicationDraft(
        name: 'X',
        dosage: 1.0,
        dosageUnit: DosageUnit.tablet,
        times: [],
      );
      expect(draft.refillReminderDays, 7);
    });

    test('isActive 默认 true', () {
      const draft = MedicationDraft(
        name: 'X',
        dosage: 1.0,
        dosageUnit: DosageUnit.tablet,
        times: [],
      );
      expect(draft.isActive, isTrue);
    });

    test('startDate / refillAt / endDate 默认 null', () {
      const draft = MedicationDraft(
        name: 'X',
        dosage: 1.0,
        dosageUnit: DosageUnit.tablet,
        times: [],
      );
      expect(draft.startDate, isNull);
      expect(draft.refillAt, isNull);
      expect(draft.endDate, isNull);
    });
  });

  group('MedicationDraft.copyWith', () {
    test('改 dosage 不动其他字段', () {
      const draft = MedicationDraft(
        name: '舍曲林',
        dosage: 50.0,
        dosageUnit: DosageUnit.mg,
        times: [HourMinute(hour: 8, minute: 0)],
      );
      final draft2 = draft.copyWith(dosage: 100.0);
      expect(draft2.dosage, 100.0);
      expect(draft2.name, '舍曲林');
      expect(draft2.dosageUnit, DosageUnit.mg);
    });

    test('nullable 字段传 null = 保持原值', () {
      final startDate = DateTime(2026, 8, 3);
      final draft = MedicationDraft(
        name: 'X',
        dosage: 1.0,
        dosageUnit: DosageUnit.tablet,
        times: [],
        startDate: startDate,
      );
      final draft2 = draft.copyWith(name: 'Y');
      expect(draft2.startDate, startDate);
    });

    test('nullable 字段传 DomainValue(null) = 显式清空', () {
      final startDate = DateTime(2026, 8, 3);
      final draft = MedicationDraft(
        name: 'X',
        dosage: 1.0,
        dosageUnit: DosageUnit.tablet,
        times: [],
        startDate: startDate,
      );
      final draft2 = draft.copyWith(startDate: const DomainValue(null));
      expect(draft2.startDate, isNull);
    });

    test('nullable 字段传 DomainValue(date) = 设置新值', () {
      const draft = MedicationDraft(
        name: 'X',
        dosage: 1.0,
        dosageUnit: DosageUnit.tablet,
        times: [],
      );
      final newDate = DateTime(2026, 12, 1);
      final draft2 = draft.copyWith(refillAt: DomainValue(newDate));
      expect(draft2.refillAt, newDate);
    });

    test('refillAt DomainValue(null) 显式清空续方', () {
      final refillAt = DateTime(2026, 12, 1);
      final draft = MedicationDraft(
        name: 'X',
        dosage: 1.0,
        dosageUnit: DosageUnit.tablet,
        times: [],
        refillAt: refillAt,
      );
      final draft2 = draft.copyWith(refillAt: const DomainValue(null));
      expect(draft2.refillAt, isNull);
    });

    test('isActive 改 false', () {
      const draft = MedicationDraft(
        name: 'X',
        dosage: 1.0,
        dosageUnit: DosageUnit.tablet,
        times: [],
      );
      final draft2 = draft.copyWith(isActive: false);
      expect(draft2.isActive, isFalse);
    });
  });
}
