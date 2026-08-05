// scale_registry 中心化测试
// v0.30 round 90 (Task 2): 扩 10 量表 + NSESSS/CRDPSS unavailable
//
// 覆盖:
// - allScales() 长度 = 10 (PHQ-9 / GAD-7 R60 + ISI / PSS R60 补全 + 6 公开新)
// - scaleById('phq9' | 'gad7' | 'isi') 返对应单例
// - scaleById(unknown) 返 null
// - isScaleAvailable(phq9) true
// - isScaleAvailable(nsesss | crdpss) false (TODO, v0.31+ 决定)
// - unavailableScaleIds = [nsesss, crdpss]

import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';

void main() {
  group('allScales 中心化', () {
    test('allScales 长度 = 10 (PHQ-9/GAD-7/ISI/PSS/WHODAS/Level2×4/ASRM, [0]=PHQ-9)', () {
      expect(allScales().length, 10);
      expect(allScales()[0].id, 'phq9'); // 顺序固定: PHQ-9 临床优先
    });
  });

  group('scaleById 查表', () {
    test('scaleById(phq9) → phq9Scale', () {
      expect(scaleById('phq9')?.id, 'phq9');
    });

    test('scaleById(gad7) → gad7Scale', () {
      expect(scaleById('gad7')?.id, 'gad7');
    });

    test('scaleById(isi) → isiScale (R60 补全)', () {
      expect(scaleById('isi')?.id, 'isi');
    });

    test('scaleById(unknown) → null', () {
      expect(scaleById('xxx_unknown_xxx'), isNull);
    });
  });

  group('isScaleAvailable 开放判定', () {
    test('isScaleAvailable(phq9) → true (开放)', () {
      expect(isScaleAvailable('phq9'), true);
    });

    test('isScaleAvailable(nsesss) → false (TODO, v0.31+ 决定)', () {
      expect(isScaleAvailable('nsesss'), false);
    });

    test('isScaleAvailable(crdpss) → false (TODO, v0.31+ 决定)', () {
      expect(isScaleAvailable('crdpss'), false);
    });
  });

  group('unavailableScaleIds 黑名单', () {
    test('unavailableScaleIds = [nsesss, crdpss]', () {
      expect(unavailableScaleIds, ['nsesss', 'crdpss']);
    });
  });
}
