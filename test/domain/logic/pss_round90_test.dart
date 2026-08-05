// PSS 压力量表测试
// v0.30 round 90 (Task 1): R60 已有 const 补全, 4 题反向计分
// source: Cohen, S. (1983) - Perceived Stress Scale (10 题, 4, 5, 7, 8 题反向)

import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/pss.dart';

void main() {
  group('PssScale.computeResult 含反向计分', () {
    // 10 题中 index 3, 4, 6, 7 是正向 (reverse = 4 - score)
    // 6 题负向 (kept as-is): index 0, 1, 2, 5, 8, 9

    test('极端低压力 (neg=0, pos=4) → 总分 0 (4 pos × (4-4)=0)', () {
      // 所有 10 题, 负向题 0 分, 正向题 4 分
      final scale = pssScale;
      final scores = [0, 0, 0, 4, 4, 0, 4, 4, 0, 0];
      final result = scale.computeResult(scores);
      expect(result.total, 0);
      expect(result.recommendDoctorVisit, isFalse);
    });

    test('极端高压力 (neg=4, pos=0) → 总分 40 (6 neg × 4 + 4 pos × (4-0)=16)', () {
      // 所有 10 题, 负向题 4 分, 正向题 0 分
      final scale = pssScale;
      final scores = [4, 4, 4, 0, 0, 4, 0, 0, 4, 4];
      final result = scale.computeResult(scores);
      expect(result.total, 40);
      expect(result.recommendDoctorVisit, isTrue);
    });
  });

  group('PssScale 接口契约', () {
    test('id / displayName / totalRange / items 数量', () {
      expect(pssScale.id, 'pss');
      expect(pssScale.id.length, lessThanOrEqualTo(20));
      expect(pssScale.displayName, contains('PSS'));
      expect(pssScale.totalRange, 40);
      expect(pssScale.items.length, 10);
    });
  });
}
