// v0.13 (Round 8) AssessmentComparisonCalculator 纯函数测试
import 'package:chroniccare/domain/logic/assessment_comparison.dart';
import 'package:chroniccare/domain/logic/assessment_record.dart';
import 'package:flutter_test/flutter_test.dart';

AssessmentRecord _rec({
  required String scaleId,
  required int total,
  required DateTime timestamp,
  List<int>? scores,
}) {
  return AssessmentRecord(
    scaleId: scaleId,
    timestamp: timestamp,
    total: total,
    scores: scores ?? List.filled(scaleId == 'phq9' ? 9 : 7, 0),
  );
}

void main() {
  group('severityRankFor - PHQ-9', () {
    test('0-4 → 0 (minimal)', () {
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'phq9', total: 0,),
        0,
      );
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'phq9', total: 4,),
        0,
      );
    });

    test('5-9 → 1 (mild)', () {
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'phq9', total: 5,),
        1,
      );
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'phq9', total: 9,),
        1,
      );
    });

    test('10-14 → 2 (moderate)', () {
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'phq9', total: 10,),
        2,
      );
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'phq9', total: 14,),
        2,
      );
    });

    test('15-19 → 3 (moderatelySevere)', () {
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'phq9', total: 15,),
        3,
      );
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'phq9', total: 19,),
        3,
      );
    });

    test('20-27 → 4 (severe)', () {
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'phq9', total: 20,),
        4,
      );
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'phq9', total: 27,),
        4,
      );
    });
  });

  group('severityRankFor - GAD-7', () {
    test('0-4 → 0', () {
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'gad7', total: 0,),
        0,
      );
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'gad7', total: 4,),
        0,
      );
    });

    test('5-9 → 1', () {
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'gad7', total: 5,),
        1,
      );
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'gad7', total: 9,),
        1,
      );
    });

    test('10-14 → 2', () {
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'gad7', total: 10,),
        2,
      );
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'gad7', total: 14,),
        2,
      );
    });

    test('15-21 → 3', () {
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'gad7', total: 15,),
        3,
      );
      expect(
        AssessmentComparisonCalculator.severityRankFor(
            scaleId: 'gad7', total: 21,),
        3,
      );
    });
  });

  group('severityLabelFor', () {
    test('PHQ-9 各档中文名', () {
      expect(
        AssessmentComparisonCalculator.severityLabelFor(
            scaleId: 'phq9', total: 2,),
        '几乎没有抑郁',
      );
      expect(
        AssessmentComparisonCalculator.severityLabelFor(
            scaleId: 'phq9', total: 12,),
        '中度抑郁',
      );
      expect(
        AssessmentComparisonCalculator.severityLabelFor(
            scaleId: 'phq9', total: 25,),
        '重度抑郁',
      );
    });

    test('GAD-7 各档中文名', () {
      expect(
        AssessmentComparisonCalculator.severityLabelFor(
            scaleId: 'gad7', total: 2,),
        '几乎没有焦虑',
      );
      expect(
        AssessmentComparisonCalculator.severityLabelFor(
            scaleId: 'gad7', total: 18,),
        '重度焦虑',
      );
    });
  });

  group('fromRecords', () {
    test('空 records 抛 ArgumentError', () {
      expect(
        () => AssessmentComparisonCalculator.fromRecords(
          records: const [],
          scaleId: 'phq9',
        ),
        throwsArgumentError,
      );
    });

    test('只有 1 条记录 → firstAssessment', () {
      final records = [
        _rec(
          scaleId: 'phq9',
          total: 8,
          timestamp: DateTime(2026, 7, 1),
        ),
      ];
      final cmp = AssessmentComparisonCalculator.fromRecords(
        records: records,
        scaleId: 'phq9',
        now: DateTime(2026, 7, 15),
      );
      expect(cmp.trend, ComparisonTrend.firstAssessment);
      expect(cmp.previous, isNull);
      expect(cmp.scoreDelta, isNull);
      expect(cmp.currentSeverityRank, 1); // 8 = mild
      expect(cmp.previousSeverityRank, isNull);
      expect(cmp.daysSincePrevious, isNull);
    });

    test('2 条记录：分数下降 + 严重度下降 = improved', () {
      final records = [
        _rec(scaleId: 'phq9', total: 15, timestamp: DateTime(2026, 7, 1)),
        _rec(scaleId: 'phq9', total: 8, timestamp: DateTime(2026, 7, 15)),
      ];
      final cmp = AssessmentComparisonCalculator.fromRecords(
        records: records,
        scaleId: 'phq9',
        now: DateTime(2026, 7, 15),
      );
      expect(cmp.trend, ComparisonTrend.improved);
      expect(cmp.scoreDelta, -7);
      expect(cmp.currentSeverityRank, 1); // 8
      expect(cmp.previousSeverityRank, 3); // 15
      expect(cmp.daysSincePrevious, 14);
    });

    test('2 条记录：分数上升 + 严重度上升 = worsened', () {
      final records = [
        _rec(scaleId: 'phq9', total: 6, timestamp: DateTime(2026, 7, 1)),
        _rec(scaleId: 'phq9', total: 18, timestamp: DateTime(2026, 7, 15)),
      ];
      final cmp = AssessmentComparisonCalculator.fromRecords(
        records: records,
        scaleId: 'phq9',
        now: DateTime(2026, 7, 15),
      );
      expect(cmp.trend, ComparisonTrend.worsened);
      expect(cmp.scoreDelta, 12);
      expect(cmp.currentSeverityRank, 3); // 18 = moderatelySevere
      expect(cmp.previousSeverityRank, 1); // 6 = mild
    });

    test('2 条记录：分数上升但严重度不变 = unchanged', () {
      // 8 → 9 都在 mild band
      final records = [
        _rec(scaleId: 'phq9', total: 8, timestamp: DateTime(2026, 7, 1)),
        _rec(scaleId: 'phq9', total: 9, timestamp: DateTime(2026, 7, 15)),
      ];
      final cmp = AssessmentComparisonCalculator.fromRecords(
        records: records,
        scaleId: 'phq9',
        now: DateTime(2026, 7, 15),
      );
      expect(cmp.trend, ComparisonTrend.unchanged);
      expect(cmp.scoreDelta, 1);
    });

    test('2 条记录：分数下降但严重度不变 = unchanged', () {
      // 14 → 10 都在 moderate band
      final records = [
        _rec(scaleId: 'phq9', total: 14, timestamp: DateTime(2026, 7, 1)),
        _rec(scaleId: 'phq9', total: 10, timestamp: DateTime(2026, 7, 15)),
      ];
      final cmp = AssessmentComparisonCalculator.fromRecords(
        records: records,
        scaleId: 'phq9',
        now: DateTime(2026, 7, 15),
      );
      expect(cmp.trend, ComparisonTrend.unchanged);
      expect(cmp.scoreDelta, -4);
    });

    test('3+ 条记录：取最后两条', () {
      final records = [
        _rec(scaleId: 'phq9', total: 20, timestamp: DateTime(2026, 6, 1)),
        _rec(scaleId: 'phq9', total: 10, timestamp: DateTime(2026, 7, 1)),
        _rec(scaleId: 'phq9', total: 5, timestamp: DateTime(2026, 8, 1)),
      ];
      final cmp = AssessmentComparisonCalculator.fromRecords(
        records: records,
        scaleId: 'phq9',
        now: DateTime(2026, 8, 1),
      );
      expect(cmp.previous!.total, 10);
      expect(cmp.current.total, 5);
      expect(cmp.scoreDelta, -5);
      expect(cmp.daysSincePrevious, 31);
    });

    test('GAD-7 量表独立工作', () {
      final records = [
        _rec(scaleId: 'gad7', total: 14, timestamp: DateTime(2026, 7, 1)),
        _rec(scaleId: 'gad7', total: 5, timestamp: DateTime(2026, 7, 15)),
      ];
      final cmp = AssessmentComparisonCalculator.fromRecords(
        records: records,
        scaleId: 'gad7',
        now: DateTime(2026, 7, 15),
      );
      expect(cmp.trend, ComparisonTrend.improved);
      // 14 = moderate (rank 2), 5 = mild (rank 1)
      expect(cmp.currentSeverityRank, 1);
      expect(cmp.previousSeverityRank, 2);
    });

    test('跨边界：4 → 5 算 improved（rank 0 → 1）', () {
      final records = [
        _rec(scaleId: 'phq9', total: 4, timestamp: DateTime(2026, 7, 1)),
        _rec(scaleId: 'phq9', total: 5, timestamp: DateTime(2026, 7, 15)),
      ];
      final cmp = AssessmentComparisonCalculator.fromRecords(
        records: records,
        scaleId: 'phq9',
        now: DateTime(2026, 7, 15),
      );
      // 注意：rank 4=0, 5=1 — 严重度上升 = worsened
      expect(cmp.trend, ComparisonTrend.worsened);
    });

    test('同一时间多次评估：用 records.last（最晚）作为 current', () {
      final records = [
        _rec(scaleId: 'phq9', total: 5, timestamp: DateTime(2026, 7, 15, 8)),
        _rec(scaleId: 'phq9', total: 8, timestamp: DateTime(2026, 7, 15, 20)),
      ];
      final cmp = AssessmentComparisonCalculator.fromRecords(
        records: records,
        scaleId: 'phq9',
        now: DateTime(2026, 7, 15, 22),
      );
      expect(cmp.current.total, 8);
      expect(cmp.previous!.total, 5);
    });
  });

  group('AssessmentHistory', () {
    test('空 records', () {
      final h = AssessmentComparisonCalculator.historyFromRecords(const []);
      expect(h.records, isEmpty);
      expect(h.totals, isEmpty);
      expect(h.average, isNull);
      expect(h.min, isNull);
      expect(h.max, isNull);
    });

    test('多条记录的平均/最小/最大', () {
      final records = [
        _rec(scaleId: 'phq9', total: 5, timestamp: DateTime(2026, 7, 1)),
        _rec(scaleId: 'phq9', total: 10, timestamp: DateTime(2026, 7, 15)),
        _rec(scaleId: 'phq9', total: 15, timestamp: DateTime(2026, 8, 1)),
      ];
      final h = AssessmentComparisonCalculator.historyFromRecords(records);
      expect(h.totals, [5, 10, 15]);
      expect(h.timestamps.length, 3);
      expect(h.average, closeTo(10.0, 0.001));
      expect(h.min, 5);
      expect(h.max, 15);
    });

    test('单条记录', () {
      final records = [
        _rec(scaleId: 'phq9', total: 8, timestamp: DateTime(2026, 7, 1)),
      ];
      final h = AssessmentComparisonCalculator.historyFromRecords(records);
      expect(h.average, 8.0);
      expect(h.min, 8);
      expect(h.max, 8);
    });
  });

  group('AssessmentComparison getters (UI helper)', () {
    test('trendLabel 中文', () {
      expect(
        AssessmentComparison(
          current:
              _rec(scaleId: 'phq9', total: 5, timestamp: DateTime(2026, 7, 15)),
          previous: null,
          scoreDelta: null,
          trend: ComparisonTrend.firstAssessment,
          currentSeverityRank: 0,
          previousSeverityRank: null,
          daysSincePrevious: null,
        ).trendLabel,
        '首次评估',
      );
    });

    test('trendSymbol 箭头', () {
      AssessmentComparison mk(ComparisonTrend t) => AssessmentComparison(
            current: _rec(
                scaleId: 'phq9', total: 5, timestamp: DateTime(2026, 7, 15),),
            previous: null,
            scoreDelta: null,
            trend: t,
            currentSeverityRank: 0,
            previousSeverityRank: null,
            daysSincePrevious: null,
          );

      expect(mk(ComparisonTrend.improved).trendSymbol, '↓');
      expect(mk(ComparisonTrend.worsened).trendSymbol, '↑');
      expect(mk(ComparisonTrend.unchanged).trendSymbol, '→');
      expect(mk(ComparisonTrend.firstAssessment).trendSymbol, '★');
    });

    test('deltaLabel：null 当无 previous', () {
      final cmp = AssessmentComparison(
        current:
            _rec(scaleId: 'phq9', total: 5, timestamp: DateTime(2026, 7, 15)),
        previous: null,
        scoreDelta: null,
        trend: ComparisonTrend.firstAssessment,
        currentSeverityRank: 0,
        previousSeverityRank: null,
        daysSincePrevious: null,
      );
      expect(cmp.deltaLabel, isNull);
    });

    test('deltaLabel：上升 / 下降 / 不变', () {
      AssessmentComparison mk(int delta) => AssessmentComparison(
            current: _rec(
                scaleId: 'phq9', total: 8, timestamp: DateTime(2026, 7, 15),),
            previous: _rec(
                scaleId: 'phq9',
                total: 8 - delta,
                timestamp: DateTime(2026, 7, 1),),
            scoreDelta: delta,
            trend: delta == 0
                ? ComparisonTrend.unchanged
                : (delta > 0
                    ? ComparisonTrend.worsened
                    : ComparisonTrend.improved),
            currentSeverityRank: 1,
            previousSeverityRank: 1,
            daysSincePrevious: 14,
          );

      expect(mk(0).deltaLabel, '和上次一样（0）');
      expect(mk(3).deltaLabel, '比上次高 3 分');
      expect(mk(-3).deltaLabel, '比上次低 3 分');
    });
  });
}
