// DSM-5 Level 2 焦虑严重程度量表 (成人) 测试
// v0.30 round 90 (Task 1): 6 公开新增量表之一
// source: APA / DSM-5 Level 2 PROMIS Anxiety (Adult, 7 题)

import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/level2_anxiety.dart';

void main() {
  group('Level2AnxietyScale.computeResult', () {
    test('全部 0 → 总分 0, 无焦虑 (rank 0)', () {
      final scale = level2AnxietyScale;
      final result = scale.computeResult(List.filled(7, 0));
      expect(result.total, 0);
      expect(result.recommendDoctorVisit, isFalse);
      expect(result.urgentDoctorVisit, isFalse);
    });

    test('全部 3 → 总分 21, 重度焦虑 (rank 3)', () {
      final scale = level2AnxietyScale;
      final result = scale.computeResult(List.filled(7, 3));
      expect(result.total, 21);
      expect(result.recommendDoctorVisit, isTrue);
      expect(result.urgentDoctorVisit, isTrue);
    });
  });

  group('Level2AnxietyScale 接口契约', () {
    test('id / displayName / totalRange / items 数量', () {
      expect(level2AnxietyScale.id, 'level2_anxiety');
      expect(level2AnxietyScale.id.length, lessThanOrEqualTo(20));
      expect(level2AnxietyScale.displayName, contains('焦虑'));
      expect(level2AnxietyScale.totalRange, 21);
      expect(level2AnxietyScale.items.length, 7);
    });
  });
}
