// v0.32 round 8 (R112-06 fix): AssessmentSparkline maxTotal 走量表 totalRange
//
// 背景: assessment_widgets.dart:61 写死 `scaleId == 'phq9' ? 27 : 21` —
// WHODAS (48) / PSS (40) / ISI (28) / ASRM (20) 等总分超上限时 y 坐标为负
// 画出界。修: 走 domain scale_registry.scaleById(id)?.totalRange 单一数据源,
// 未知量表 / 0 防御回退 21 (跟旧行为一致)。
//
// 测试 3 组:
// 1. 已知量表 → 各自 totalRange (phq9 27 / whodas 48 / pss 40 / isi 28 /
//    asrm 20 / level2_mania 15 / level2_depression 24 / gad7 21)
// 2. 未知量表 id → 防御 21
// 3. 空串 → 防御 21
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/pages/assessment/assessment_widgets.dart';

void main() {
  group('AssessmentSparkline.sparklineMaxTotalFor (R112-06)', () {
    test('1. 已知量表 → 走各自 totalRange (不再是 27/21 二选一)', () {
      expect(AssessmentSparkline.sparklineMaxTotalFor('phq9'), 27);
      expect(
        AssessmentSparkline.sparklineMaxTotalFor('whodas'),
        48,
        reason: '修前 WHODAS 48 分被 21 上限截断 → 画出界',
      );
      expect(
        AssessmentSparkline.sparklineMaxTotalFor('pss'),
        40,
        reason: '修前 PSS 40 分被 21 上限截断 → 画出界',
      );
      expect(
        AssessmentSparkline.sparklineMaxTotalFor('isi'),
        28,
        reason: '修前 ISI 28 分被 21 上限截断 → 画出界',
      );
      expect(AssessmentSparkline.sparklineMaxTotalFor('asrm'), 20);
      expect(AssessmentSparkline.sparklineMaxTotalFor('level2_mania'), 15);
      expect(AssessmentSparkline.sparklineMaxTotalFor('level2_depression'), 24);
      expect(AssessmentSparkline.sparklineMaxTotalFor('gad7'), 21);
      expect(AssessmentSparkline.sparklineMaxTotalFor('level2_anxiety'), 21);
      expect(AssessmentSparkline.sparklineMaxTotalFor('level2_psychosis'), 24);
    });

    test('2. 未知量表 id → 防御 21 (跟旧行为一致)', () {
      expect(AssessmentSparkline.sparklineMaxTotalFor('unknown_scale'), 21);
    });

    test('3. 空串 → 防御 21', () {
      expect(AssessmentSparkline.sparklineMaxTotalFor(''), 21);
    });
  });
}
