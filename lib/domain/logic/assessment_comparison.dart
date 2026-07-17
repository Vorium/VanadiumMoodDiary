// v0.13 (Round 8) 评估历史对比
//
// 思路：
// - 用户在 result 页能看到"对比上次"（Δ 分数 + 严重度变化方向）
// - 提供 sparkline 数据给结果页画趋势
// - 纯函数，不依赖 Flutter；方便测试
//
// 严重度等级（不同量表的分段数不一样）：
// - PHQ-9 (0-27): 5 档 → 0-4 / 5-9 / 10-14 / 15-19 / 20+
// - GAD-7 (0-21): 4 档 → 0-4 / 5-9 / 10-14 / 15+
// 我们用 rank（0..N-1）来量化，等级下降 = 好转。
library;

import 'assessment_record.dart';

/// 严重度排名方向
enum ComparisonTrend {
  /// 严重度下降（好转）
  improved,

  /// 严重度上升（恶化）
  worsened,

  /// 严重度不变
  unchanged,

  /// 没有上次记录，无法对比
  firstAssessment,
}

/// 单次对比结果
class AssessmentComparison {
  /// 当前评估
  final AssessmentRecord current;

  /// 上次评估（null = 首次评估）
  final AssessmentRecord? previous;

  /// 分数差：current.total - previous.total（null = 无上次）
  final int? scoreDelta;

  /// 严重度方向
  final ComparisonTrend trend;

  /// 当前严重度 rank（0..N-1，rank 越大越严重）
  final int currentSeverityRank;

  /// 上次严重度 rank
  final int? previousSeverityRank;

  /// 距离上次评估多少天（null = 无上次）
  final int? daysSincePrevious;

  const AssessmentComparison({
    required this.current,
    required this.previous,
    required this.scoreDelta,
    required this.trend,
    required this.currentSeverityRank,
    required this.previousSeverityRank,
    required this.daysSincePrevious,
  });

  /// UI 用的趋势文案
  String get trendLabel {
    switch (trend) {
      case ComparisonTrend.improved:
        return '好转';
      case ComparisonTrend.worsened:
        return '恶化';
      case ComparisonTrend.unchanged:
        return '持平';
      case ComparisonTrend.firstAssessment:
        return '首次评估';
    }
  }

  /// UI 用的趋势符号
  String get trendSymbol {
    switch (trend) {
      case ComparisonTrend.improved:
        return '↓';
      case ComparisonTrend.worsened:
        return '↑';
      case ComparisonTrend.unchanged:
        return '→';
      case ComparisonTrend.firstAssessment:
        return '★';
    }
  }

  /// UI 用的"和上次比"完整文案
  String? get deltaLabel {
    if (previous == null || scoreDelta == null) return null;
    final d = scoreDelta!;
    if (d == 0) return '和上次一样（$d）';
    if (d > 0) return '比上次高 $d 分';
    return '比上次低 ${-d} 分';
  }
}

/// 历史数据（sparkline 用）
class AssessmentHistory {
  /// 按时间正序的所有评估
  final List<AssessmentRecord> records;

  /// 同步提取的总分序列
  List<int> get totals => records.map((r) => r.total).toList(growable: false);

  /// 同步的时间戳
  List<DateTime> get timestamps =>
      records.map((r) => r.timestamp).toList(growable: false);

  /// 平均分（null = 无记录）
  double? get average {
    if (records.isEmpty) return null;
    final s = totals.fold<int>(0, (a, b) => a + b);
    return s / records.length;
  }

  /// 最高分（null = 无记录）
  int? get max =>
      records.isEmpty ? null : totals.reduce((a, b) => a > b ? a : b);

  /// 最低分
  int? get min =>
      records.isEmpty ? null : totals.reduce((a, b) => a < b ? a : b);

  const AssessmentHistory({required this.records});
}

/// 评估对比计算器（纯函数集合）
class AssessmentComparisonCalculator {
  AssessmentComparisonCalculator._();

  /// 计算给定 [total] 在 [scaleId] 量表中的严重度 rank
  ///
  /// rank 越大越严重。
  static int severityRankFor({
    required String scaleId,
    required int total,
  }) {
    if (scaleId == 'phq9') {
      if (total <= 4) return 0; // minimal
      if (total <= 9) return 1; // mild
      if (total <= 14) return 2; // moderate
      if (total <= 19) return 3; // moderatelySevere
      return 4; // severe
    }
    if (scaleId == 'gad7') {
      if (total <= 4) return 0; // minimal
      if (total <= 9) return 1; // mild
      if (total <= 14) return 2; // moderate
      return 3; // severe
    }
    // 未知量表 — 兜底：按 totalRange 5 等分
    throw ArgumentError('未知量表: $scaleId');
  }

  /// 严重度档位名（中文）
  static String severityLabelFor({
    required String scaleId,
    required int total,
  }) {
    final rank = severityRankFor(scaleId: scaleId, total: total);
    if (scaleId == 'phq9') {
      return const ['几乎没有抑郁', '轻度抑郁', '中度抑郁', '中重度抑郁', '重度抑郁'][rank];
    }
    if (scaleId == 'gad7') {
      return const ['几乎没有焦虑', '轻度焦虑', '中度焦虑', '重度焦虑'][rank];
    }
    return '等级 $rank';
  }

  /// 从历史 records 提取最近一次 + 上一次的对比
  ///
  /// [records] 应为同一量表的全部历史，**按时间正序**（最早在前）
  /// [scaleId] 用于查 severityRank
  /// [now] 默认 DateTime.now()，可注入测试
  static AssessmentComparison fromRecords({
    required List<AssessmentRecord> records,
    required String scaleId,
    DateTime? now,
  }) {
    if (records.isEmpty) {
      throw ArgumentError('records 不能为空');
    }
    final current = records.last;
    final previous = records.length >= 2 ? records[records.length - 2] : null;

    final currentRank = severityRankFor(
      scaleId: scaleId,
      total: current.total,
    );

    if (previous == null) {
      return AssessmentComparison(
        current: current,
        previous: null,
        scoreDelta: null,
        trend: ComparisonTrend.firstAssessment,
        currentSeverityRank: currentRank,
        previousSeverityRank: null,
        daysSincePrevious: null,
      );
    }

    final previousRank = severityRankFor(
      scaleId: scaleId,
      total: previous.total,
    );
    final delta = current.total - previous.total;
    final ComparisonTrend trend;
    if (currentRank < previousRank) {
      trend = ComparisonTrend.improved;
    } else if (currentRank > previousRank) {
      trend = ComparisonTrend.worsened;
    } else {
      trend = ComparisonTrend.unchanged;
    }
    final days = _daysBetween(previous.timestamp, now ?? DateTime.now());
    return AssessmentComparison(
      current: current,
      previous: previous,
      scoreDelta: delta,
      trend: trend,
      currentSeverityRank: currentRank,
      previousSeverityRank: previousRank,
      daysSincePrevious: days,
    );
  }

  /// 提取历史 sparkline 数据
  static AssessmentHistory historyFromRecords(List<AssessmentRecord> records) {
    return AssessmentHistory(records: List.unmodifiable(records));
  }

  /// 跨日天数（同 trend_calculator 的逻辑）
  static int _daysBetween(DateTime a, DateTime b) {
    final aDay = DateTime(a.year, a.month, a.day);
    final bDay = DateTime(b.year, b.month, b.day);
    return bDay.difference(aDay).inDays;
  }
}
