// v0.28 Round 93 (#70 修复): dosage_unit enum 0 测试补齐
//
// 覆盖:
// - 两个 enum 值 (mg / tablet) id 字符串
// - fromId() 已知 / 未知 / null 走 tablet fallback
// - enum 顺序 values
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/entities/dosage_unit.dart';

void main() {
  group('DosageUnit enum 值', () {
    test('mg.id == "mg"', () {
      expect(DosageUnit.mg.id, 'mg');
    });

    test('tablet.id == "片"', () {
      expect(DosageUnit.tablet.id, '片');
    });

    test('values 顺序 [mg, tablet]', () {
      expect(DosageUnit.values, [DosageUnit.mg, DosageUnit.tablet]);
    });
  });

  group('DosageUnit.fromId 反序列化', () {
    test('"mg" → mg', () {
      expect(DosageUnit.fromId('mg'), DosageUnit.mg);
    });

    test('"片" → tablet', () {
      expect(DosageUnit.fromId('片'), DosageUnit.tablet);
    });

    test('null 走 tablet fallback', () {
      expect(DosageUnit.fromId(null), DosageUnit.tablet);
    });

    test('未知 id 走 tablet fallback (v0.22 round 30 行为)', () {
      expect(DosageUnit.fromId('unknown_unit'), DosageUnit.tablet);
      expect(DosageUnit.fromId(''), DosageUnit.tablet);
      expect(DosageUnit.fromId('TABLET'), DosageUnit.tablet);
    });
  });
}
