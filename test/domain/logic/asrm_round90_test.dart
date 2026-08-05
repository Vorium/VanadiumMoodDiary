// Altman 自评躁狂量表 (ASRM) 测试
// v0.30 round 90 (Task 1): 6 公开新增量表之一
// source: Altman et al. 1997 - The Altman Self-Rating Mania Scale

import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/asrm.dart';

void main() {
  group('AsrmScale.computeResult', () {
    test('全部 0 → 总分 0, 无躁狂 (rank 0)', () {
      final scale = asrmScale;
      final result = scale.computeResult(List.filled(5, 0));
      expect(result.total, 0);
      expect(result.recommendDoctorVisit, isFalse);
      expect(result.urgentDoctorVisit, isFalse);
    });

    test('全部 4 → 总分 20, 极重度躁狂 (rank 4)', () {
      final scale = asrmScale;
      final result = scale.computeResult(List.filled(5, 4));
      expect(result.total, 20);
      expect(result.recommendDoctorVisit, isTrue);
      expect(result.urgentDoctorVisit, isTrue);
    });
  });

  group('AsrmScale 接口契约', () {
    test('id / displayName / totalRange / items 数量', () {
      expect(asrmScale.id, 'asrm');
      expect(asrmScale.id.length, lessThanOrEqualTo(20));
      expect(asrmScale.displayName, contains('ASRM'));
      expect(asrmScale.totalRange, 20);
      expect(asrmScale.items.length, 5);
    });
  });
}
