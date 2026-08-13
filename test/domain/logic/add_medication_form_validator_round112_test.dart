// v0.32 R112 (AR-20 批2b): AddMedicationFormValidator 补纯函数 test
//
// R109 (god class 拆 round 4) 抽了 AddMedicationFormValidator 到
// domain/logic (77L), 但 0 直接单测 (SP-111-04 同款 0-test 块)。拆
// add_medication_page 前先把 validator 行为锁死, 拆后回归有据。
//
// 覆盖 (4 method × 边界):
// - validateName: null / '' / 纯空格 / 首尾空格有效名 / 正常名
// - parseDosage: null / '' / 非法 / 整数 / 小数 / 带空格数字
// - canAdvanceFromStep1: 空名 false / 有效名 true
// - toDraft: 字段映射 + name trim 语义

import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_form.dart';
import 'package:chroniccare/domain/logic/add_medication_form_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateName', () {
    test('null → medication_name_required', () {
      expect(
        AddMedicationFormValidator.validateName(null),
        'medication_name_required',
      );
    });

    test('空串 → medication_name_required', () {
      expect(
        AddMedicationFormValidator.validateName(''),
        'medication_name_required',
      );
    });

    test('纯空格 → medication_name_required (trim 后判空)', () {
      expect(
        AddMedicationFormValidator.validateName('   '),
        'medication_name_required',
      );
    });

    test('正常药名 → null (合法)', () {
      expect(AddMedicationFormValidator.validateName('氟西汀'), isNull);
    });

    test('首尾带空格 → null (trim 后非空)', () {
      expect(AddMedicationFormValidator.validateName(' 氟西汀 '), isNull);
    });
  });

  group('parseDosage', () {
    test('null → 0 (兜底)', () {
      expect(AddMedicationFormValidator.parseDosage(null), 0);
    });

    test('空串 → 0 (兜底, 跟原 _save 行为 1:1)', () {
      expect(AddMedicationFormValidator.parseDosage(''), 0);
    });

    test('非法文本 → 0 (兜底)', () {
      expect(AddMedicationFormValidator.parseDosage('abc'), 0);
    });

    test('整数 → 50', () {
      expect(AddMedicationFormValidator.parseDosage('50'), 50);
    });

    test('小数 → 50.5', () {
      expect(AddMedicationFormValidator.parseDosage('50.5'), 50.5);
    });

    test('带空格数字 → 25', () {
      expect(AddMedicationFormValidator.parseDosage(' 25 '), 25);
    });
  });

  group('canAdvanceFromStep1', () {
    test('空名 → false', () {
      expect(AddMedicationFormValidator.canAdvanceFromStep1(''), isFalse);
    });

    test('纯空格 → false', () {
      expect(AddMedicationFormValidator.canAdvanceFromStep1('  '), isFalse);
    });

    test('有效名 → true', () {
      expect(AddMedicationFormValidator.canAdvanceFromStep1('氟西汀'), isTrue);
    });
  });

  group('toDraft', () {
    test('字段映射 + name trim', () {
      final draft = AddMedicationFormValidator.toDraft(
        name: ' 氟西汀 ',
        dosageText: '50',
        dosageUnit: DosageUnit.mg,
        times: const [HourMinute(hour: 8, minute: 0)],
        form: MedicationForm.capsule,
        colorIndex: 3,
      );

      expect(draft.name, '氟西汀');
      expect(draft.dosage, 50);
      expect(draft.dosageUnit, DosageUnit.mg);
      expect(draft.times, const [HourMinute(hour: 8, minute: 0)]);
      expect(draft.form, MedicationForm.capsule);
      expect(draft.colorIndex, 3);
    });

    test('非法剂量文本 → dosage 0 (兜底进 draft)', () {
      final draft = AddMedicationFormValidator.toDraft(
        name: '氟西汀',
        dosageText: 'abc',
        dosageUnit: DosageUnit.mg,
        times: const [HourMinute(hour: 8, minute: 0)],
        form: MedicationForm.tablet,
        colorIndex: 0,
      );

      expect(draft.dosage, 0);
    });
  });
}
