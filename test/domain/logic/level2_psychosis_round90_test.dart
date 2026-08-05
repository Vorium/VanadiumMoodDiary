// DSM-5 Level 2 精神病性症状量表 (成人) 测试
// v0.30 round 90 (Task 1): 6 公开新增量表之一
// source: APA / DSM-5 Level 2 Psychosis (Adult, 8 题)

import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/level2_psychosis.dart';

void main() {
  group('Level2PsychosisScale.computeResult', () {
    test('全部 0 → 总分 0, 无精神病性症状 (rank 0)', () {
      final scale = level2PsychosisScale;
      final result = scale.computeResult(List.filled(8, 0));
      expect(result.total, 0);
      expect(result.recommendDoctorVisit, isFalse);
      expect(result.urgentDoctorVisit, isFalse);
    });

    test('全部 3 → 总分 24, 重度精神病性症状 (rank 3)', () {
      final scale = level2PsychosisScale;
      final result = scale.computeResult(List.filled(8, 3));
      expect(result.total, 24);
      expect(result.recommendDoctorVisit, isTrue);
      expect(result.urgentDoctorVisit, isTrue);
    });
  });

  group('Level2PsychosisScale 接口契约', () {
    test('id / displayName / totalRange / items 数量', () {
      expect(level2PsychosisScale.id, 'level2_psychosis');
      expect(level2PsychosisScale.id.length, lessThanOrEqualTo(20));
      expect(level2PsychosisScale.displayName, contains('精神病'));
      expect(level2PsychosisScale.totalRange, 24);
      expect(level2PsychosisScale.items.length, 8);
    });
  });
}
