// lib/domain/logic/mood_review_aggregator.dart
// 情绪回顾聚合器（v1.1.0）— 周/月统计摘要纯函数
//
// 0 Flutter / 0 Drift 依赖, 输入 entity 列表输出摘要。
import 'package:chroniccare/core/shared/json_codec.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

/// 鼓励文案分档 (1.1.0 round 7b)
///
/// domain 层只产 tier (0 中文文案), 显示层按 locale 走
/// `localizedEncouragement` (lib/l10n/preset_content_l10n.dart) 拿 ARB 文案。
enum MoodReviewEncouragementTier { empty, low, mid, high, noAvg }

/// 周/月情绪摘要
class MoodReviewSummary {
  final int entriesCount;
  final double? avgScore;
  final double? avgEnergy;
  final double? avgSleep;
  final double? avgAnxiety;

  /// 本周均分 - 上周均分, 上周无数据 = null
  final double? scoreDelta;
  final List<String> topTags;
  final List<String> topInfluenceFactors;
  final Map<String, int> periodCounts;
  final int cbtCount;

  /// 鼓励文案分档 (按均分分档, 显示层按 tier 本地化)
  final MoodReviewEncouragementTier encouragement;

  const MoodReviewSummary({
    required this.entriesCount,
    this.avgScore,
    this.avgEnergy,
    this.avgSleep,
    this.avgAnxiety,
    this.scoreDelta,
    this.topTags = const [],
    this.topInfluenceFactors = const [],
    this.periodCounts = const {},
    this.cbtCount = 0,
    this.encouragement = MoodReviewEncouragementTier.noAvg,
  });
}

/// 过滤 [start, endInclusive] 闭区间内的 entries
List<MoodEntryEntity> filterByRange(
  List<MoodEntryEntity> entries,
  DateTime start,
  DateTime endInclusive,
) {
  return entries
      .where(
        (e) =>
            !e.timestamp.isBefore(start) && !e.timestamp.isAfter(endInclusive),
      )
      .toList(growable: false);
}

double? _mean(List<int?> values) {
  final nonNull = values.whereType<int>().toList();
  if (nonNull.isEmpty) return null;
  return nonNull.reduce((a, b) => a + b) / nonNull.length;
}

List<String> _topN(List<String> values, int n) {
  final counts = <String, int>{};
  for (final v in values) {
    counts[v] = (counts[v] ?? 0) + 1;
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final c = b.value.compareTo(a.value);
      // Dart sort 不稳定: 同频次加字典序 tie-break 保证确定性
      return c != 0 ? c : a.key.compareTo(b.key);
    });
  return sorted.take(n).map((e) => e.key).toList(growable: false);
}

MoodReviewEncouragementTier _encouragement(double? avgScore, int entriesCount) {
  if (entriesCount == 0) return MoodReviewEncouragementTier.empty;
  if (avgScore == null) return MoodReviewEncouragementTier.noAvg;
  if (avgScore < 2.5) return MoodReviewEncouragementTier.low;
  if (avgScore < 3.5) return MoodReviewEncouragementTier.mid;
  return MoodReviewEncouragementTier.high;
}

MoodReviewSummary summarize(
  List<MoodEntryEntity> current,
  List<MoodEntryEntity> previous,
) {
  final avgScore = _mean(current.map((e) => e.score).toList());
  final avgEnergy = _mean(current.map((e) => e.energy).toList());
  final avgSleep = _mean(current.map((e) => e.sleep).toList());
  final avgAnxiety = _mean(current.map((e) => e.anxiety).toList());
  final prevAvgScore = _mean(previous.map((e) => e.score).toList());

  final allTags = <String>[
    for (final e in current) ...JsonCodec.decodeStringList(e.tagsJson),
  ];
  final allFactors = <String>[
    for (final e in current)
      ...JsonCodec.decodeStringList(e.influenceFactorsJson),
  ];
  final periodCounts = <String, int>{};
  for (final e in current) {
    final p = e.period;
    if (p == null || p == 'unspecified') continue;
    periodCounts[p] = (periodCounts[p] ?? 0) + 1;
  }
  final cbtCount = current
      .where(
        (e) =>
            e.situation != null ||
            e.automaticThought != null ||
            e.evidenceFor != null ||
            e.evidenceAgainst != null ||
            e.alternativeThought != null ||
            e.reratedScore != null ||
            e.coreBelief != null ||
            e.behaviorResponse != null,
      )
      .length;

  return MoodReviewSummary(
    entriesCount: current.length,
    avgScore: avgScore,
    avgEnergy: avgEnergy,
    avgSleep: avgSleep,
    avgAnxiety: avgAnxiety,
    scoreDelta: (avgScore != null && prevAvgScore != null)
        ? avgScore - prevAvgScore
        : null,
    topTags: _topN(allTags, 5),
    topInfluenceFactors: _topN(allFactors, 5),
    periodCounts: periodCounts,
    cbtCount: cbtCount,
    encouragement: _encouragement(avgScore, current.length),
  );
}
