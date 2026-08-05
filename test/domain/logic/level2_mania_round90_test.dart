// DSM-5 Level 2 躁狂严重程度量表 (成人) 测试
// v0.30 round 90 (Task 1): 6 公开新增量表之一
// source: APA / DSM-5 Level 2 PROMIS Mania (Adult, 5 题)

import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/level2_mania.dart';

void main() {
  group('Level2ManiaScale.computeResult', () {
    test('全部 0 → 总分 0, 无躁狂 (rank 0)', () {
      final scale = level2ManiaScale;
      final result = scale.computeResult(List.filled(5, 0));
      expect(result.total, 0);
      expect(result.recommendDoctorVisit, isFalse);
      expect(result.urgentDoctorVisit, isFalse);
    });

    test('全部 3 → 总分 15, 重度躁狂 (rank 3)', () {
      final scale = level2ManiaScale;
      final result = scale.computeResult(List.filled(5, 3));
      expect(result.total, 15);
      expect(result.recommendDoctorVisit, isTrue);
      expect(result.urgentDoctorVisit, isTrue);
    });
  });

  group('Level2ManiaScale 接口契约', () {
    test('id / displayName / totalRange / items 数量', () {
      expect(level2ManiaScale.id, 'level2_mania');
      expect(level2ManiaScale.id.length, lessThanOrEqualTo(20));
      expect(level2ManiaScale.displayName, contains('躁狂'));
      expect(level2ManiaScale.totalRange, 15);
      expect(level2ManiaScale.items.length, 5);
    });
  });
}
