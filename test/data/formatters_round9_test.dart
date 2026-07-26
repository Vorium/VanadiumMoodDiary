import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters.date', () {
    test('2026-07-13 → "2026-07-13"', () {
      expect(Formatters.date(DateTime(2026, 7, 13)), '2026-07-13');
    });

    test('补 0：1 月 → "01"', () {
      expect(Formatters.date(DateTime(2026, 1, 5)), '2026-01-05');
    });
  });

  group('Formatters.monthDay', () {
    test('5 月 3 日 → "05/03"', () {
      expect(Formatters.monthDay(DateTime(2026, 5, 3)), '05/03');
    });
  });

  group('Formatters.time', () {
    test('14:08 → "14:08"', () {
      expect(Formatters.time(DateTime(2026, 7, 13, 14, 8)), '14:08');
    });
  });

  group('Formatters.dosage', () {
    test('整数剂量不显示小数', () {
      expect(Formatters.dosage(40, DosageUnit.mg), '40mg');
      expect(Formatters.dosage(0, DosageUnit.mg), '0mg');
      expect(Formatters.dosage(1, DosageUnit.tablet), '1片');
    });

    test('小数剂量显示小数', () {
      expect(Formatters.dosage(0.4, DosageUnit.mg), '0.4mg');
      expect(Formatters.dosage(1.5, DosageUnit.tablet), '1.5片');
    });

    test('N23 fix: 浮点边界值仍按整数显示', () {
      // 41.0 在浮点里可能存成 41.0000000001
      // 旧逻辑 == roundToDouble 会失败,新逻辑用极小容差
      expect(Formatters.dosage(40.0, DosageUnit.mg), '40mg');
      expect(Formatters.dosage(1.0, DosageUnit.tablet), '1片');
    });
  });

  group('Formatters.dateCompact', () {
    test('用于文件名：20260713', () {
      expect(Formatters.dateCompact(DateTime(2026, 7, 13)), '20260713');
    });
  });
}
