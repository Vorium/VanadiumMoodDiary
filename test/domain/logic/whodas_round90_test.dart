// WHODAS 2.0 (12 题简化) 量表测试
// v0.30 round 90 (Task 1): 6 公开新增量表之一
// source: https://www.who.int/standards/classifications/international-classification-of-functioning-disability-and-health/who-disability-assessment-schedule

import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/whodas.dart';

void main() {
  group('WhodasScale.computeResult', () {
    test('全部 0 → 总分 0, 无残疾 (rank 0)', () {
      const scale = whodasScale;
      final result = scale.computeResult(List.filled(12, 0));
      expect(result.total, 0);
      expect(result.recommendDoctorVisit, isFalse);
      expect(result.urgentDoctorVisit, isFalse);
    });

    test('全部 4 → 总分 48, 极重度残疾 (rank 4)', () {
      const scale = whodasScale;
      final result = scale.computeResult(List.filled(12, 4));
      expect(result.total, 48);
      expect(result.recommendDoctorVisit, isTrue);
      expect(result.urgentDoctorVisit, isTrue);
    });
  });

  group('WhodasScale 接口契约', () {
    test('id / displayName / totalRange / items 数量', () {
      expect(whodasScale.id, 'whodas');
      expect(whodasScale.id.length, lessThanOrEqualTo(20));
      expect(whodasScale.displayName, contains('WHODAS'));
      expect(whodasScale.totalRange, 48);
      expect(whodasScale.items.length, 12);
    });
  });
}
