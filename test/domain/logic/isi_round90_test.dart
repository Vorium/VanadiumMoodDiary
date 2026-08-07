// ISI 失眠严重指数测试
// v0.30 round 90 (Task 1): R60 已有 const 补全, 准备 Task 2 注册
// source: Morin et al. 1993 - Insomnia Severity Index (7 题)

import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/isi.dart';

void main() {
  group('IsiScale.computeResult', () {
    test('全部 0 → 总分 0, 无失眠 (rank 0)', () {
      const scale = isiScale;
      final result = scale.computeResult(List.filled(7, 0));
      expect(result.total, 0);
      expect(result.recommendDoctorVisit, isFalse);
      expect(result.urgentDoctorVisit, isFalse);
    });

    test('全部 4 → 总分 28, 重度失眠 (rank 3)', () {
      const scale = isiScale;
      final result = scale.computeResult(List.filled(7, 4));
      expect(result.total, 28);
      expect(result.recommendDoctorVisit, isTrue);
      expect(result.urgentDoctorVisit, isTrue);
    });
  });

  group('IsiScale 接口契约', () {
    test('id / displayName / totalRange / items 数量', () {
      expect(isiScale.id, 'isi');
      expect(isiScale.id.length, lessThanOrEqualTo(20));
      expect(isiScale.displayName, contains('ISI'));
      expect(isiScale.totalRange, 28);
      expect(isiScale.items.length, 7);
    });
  });
}
