// DSM-5 Level 2 抑郁严重程度量表 (成人) 测试
// v0.30 round 90 (Task 1): 6 公开新增量表之一
// source: APA / DSM-5 Level 2 PROMIS Emotional Distress - Depression (Adult, 8 题)

import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/level2_depression.dart';

void main() {
  group('Level2DepressionScale.computeResult', () {
    test('全部 0 → 总分 0, 无抑郁 (rank 0)', () {
      const scale = level2DepressionScale;
      final result = scale.computeResult(List.filled(8, 0));
      expect(result.total, 0);
      expect(result.recommendDoctorVisit, isFalse);
      expect(result.urgentDoctorVisit, isFalse);
    });

    test('全部 3 → 总分 24, 重度抑郁 (rank 3)', () {
      const scale = level2DepressionScale;
      final result = scale.computeResult(List.filled(8, 3));
      expect(result.total, 24);
      expect(result.recommendDoctorVisit, isTrue);
      expect(result.urgentDoctorVisit, isTrue);
    });
  });

  group('Level2DepressionScale 接口契约', () {
    test('id / displayName / totalRange / items 数量', () {
      expect(level2DepressionScale.id, 'level2_depression');
      expect(level2DepressionScale.id.length, lessThanOrEqualTo(20));
      expect(level2DepressionScale.displayName, contains('抑郁'));
      expect(level2DepressionScale.totalRange, 24);
      expect(level2DepressionScale.items.length, 8);
    });
  });
}
