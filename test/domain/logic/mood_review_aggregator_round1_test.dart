// test/domain/logic/mood_review_aggregator_round1_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/logic/mood_review_aggregator.dart';

MoodEntryEntity _e({
  required int id,
  required DateTime ts,
  int score = 3,
  int? energy,
  int? sleep,
  int? anxiety,
  String tagsJson = '[]',
  String influenceFactorsJson = '[]',
  String? period,
  String? situation,
  int? reratedScore,
}) {
  return MoodEntryEntity(
    id: id,
    timestamp: ts,
    score: score,
    energy: energy,
    sleep: sleep,
    anxiety: anxiety,
    tagsJson: tagsJson,
    influenceFactorsJson: influenceFactorsJson,
    period: period,
    situation: situation,
    reratedScore: reratedScore,
  );
}

void main() {
  final start = DateTime(2026, 8, 3);
  final end = DateTime(2026, 8, 9, 23, 59, 59);

  group('filterByRange', () {
    test('边界含 start 和 end', () {
      final entries = [
        _e(id: 1, ts: start),
        _e(id: 2, ts: end),
        _e(id: 3, ts: start.subtract(const Duration(seconds: 1))),
        _e(id: 4, ts: end.add(const Duration(seconds: 1))),
      ];
      final got = filterByRange(entries, start, end);
      expect(got.map((e) => e.id), [1, 2]);
    });
  });

  group('summarize', () {
    test('空集: 计数 0, 均分 null, 鼓励文案空态', () {
      final s = summarize(const [], const []);
      expect(s.entriesCount, 0);
      expect(s.avgScore, isNull);
      expect(s.scoreDelta, isNull);
      expect(s.topTags, isEmpty);
      expect(s.cbtCount, 0);
      expect(s.encouragement, MoodReviewEncouragementTier.empty);
    });

    test('单条: 均分 = 该条分数, delta null', () {
      final s = summarize([_e(id: 1, ts: start, score: 4)], const []);
      expect(s.entriesCount, 1);
      expect(s.avgScore, 4.0);
      expect(s.scoreDelta, isNull);
    });

    test('均分取非 null 维度平均, null 维度忽略', () {
      final s = summarize(
        [
          _e(id: 1, ts: start, score: 2, energy: 2),
          _e(
              id: 2,
              ts: start.add(const Duration(hours: 1)),
              score: 4,
              energy: 4,
              sleep: 5),
        ],
        const [],
      );
      expect(s.avgScore, 3.0);
      expect(s.avgEnergy, 3.0);
      expect(s.avgSleep, 5.0);
      expect(s.avgAnxiety, isNull);
    });

    test('topTags top5 按频次降序, 同频次按字典序稳定', () {
      final s = summarize(
        [
          _e(id: 1, ts: start, tagsJson: '["焦虑","失眠"]'),
          _e(
              id: 2,
              ts: start.add(const Duration(hours: 1)),
              tagsJson: '["焦虑","平静"]'),
          _e(
              id: 3,
              ts: start.add(const Duration(hours: 2)),
              tagsJson: '["焦虑","失眠","易怒","低落","疲惫"]'),
        ],
        const [],
      );
      expect(s.topTags, ['焦虑', '失眠', '低落', '平静', '易怒']);
    });

    test('同频次 tie-break: 字典序确定性 (两次调用结果一致)', () {
      final entries = [
        _e(id: 1, ts: start, tagsJson: '["b"]'),
        _e(id: 2, ts: start.add(const Duration(hours: 1)), tagsJson: '["a"]'),
        _e(
            id: 3,
            ts: start.add(const Duration(hours: 2)),
            tagsJson: '["a","b"]'),
      ];
      // a=2, b=2 同频次 → 字典序 ['a', 'b'], 每次调用结果一致 (sort 不稳定不炸)
      final s1 = summarize(entries, const []);
      final s2 = summarize(entries, const []);
      expect(s1.topTags, ['a', 'b']);
      expect(s2.topTags, ['a', 'b']);
    });

    test('topInfluenceFactors 频次降序', () {
      final s = summarize(
        [
          _e(id: 1, ts: start, influenceFactorsJson: '["工作压力"]'),
          _e(
              id: 2,
              ts: start.add(const Duration(hours: 1)),
              influenceFactorsJson: '["工作压力","睡眠不足"]'),
        ],
        const [],
      );
      expect(s.topInfluenceFactors.first, '工作压力');
    });

    test('periodCounts 统计 4 时段', () {
      final s = summarize(
        [
          _e(id: 1, ts: start, period: 'morning'),
          _e(id: 2, ts: start.add(const Duration(hours: 1)), period: 'morning'),
          _e(id: 3, ts: start.add(const Duration(hours: 2)), period: 'evening'),
        ],
        const [],
      );
      expect(s.periodCounts, {'morning': 2, 'evening': 1});
    });

    test('cbtCount: 任一 CBT 字段非 null 计 1', () {
      final s = summarize(
        [
          _e(id: 1, ts: start),
          _e(id: 2, ts: start.add(const Duration(hours: 1)), situation: '开会'),
        ],
        const [],
      );
      expect(s.cbtCount, 1);
    });

    test('cbtCount: 仅 reratedScore 非 null 也计 1', () {
      final s = summarize(
        [
          _e(id: 1, ts: start),
          _e(id: 2, ts: start.add(const Duration(hours: 1)), reratedScore: 4),
        ],
        const [],
      );
      expect(s.cbtCount, 1);
    });

    test('scoreDelta = 本周均分 - 上周均分', () {
      final prev = [
        _e(id: 1, ts: start.subtract(const Duration(days: 1)), score: 2),
        _e(id: 2, ts: start.subtract(const Duration(days: 2)), score: 4),
      ];
      final s = summarize([_e(id: 3, ts: start, score: 4)], prev);
      expect(s.scoreDelta, closeTo(1.0, 0.001));
    });

    test('上周空 → delta null', () {
      final s = summarize([_e(id: 1, ts: start, score: 3)], const []);
      expect(s.scoreDelta, isNull);
    });

    test('鼓励文案分档: 低/中/高 (1.1.0 round 7b: String → tier)', () {
      final low = summarize([_e(id: 1, ts: start, score: 2)], const []);
      expect(low.encouragement, MoodReviewEncouragementTier.low);
      final mid = summarize([_e(id: 2, ts: start, score: 3)], const []);
      expect(mid.encouragement, MoodReviewEncouragementTier.mid);
      final high = summarize([_e(id: 3, ts: start, score: 4)], const []);
      expect(high.encouragement, MoodReviewEncouragementTier.high);
    });

    test('本月跨日多条: entriesCount 正确', () {
      final s = summarize(
        [
          _e(id: 1, ts: start, score: 3),
          _e(id: 2, ts: start.add(const Duration(days: 1)), score: 3),
          _e(id: 3, ts: start.add(const Duration(days: 6)), score: 3),
        ],
        const [],
      );
      expect(s.entriesCount, 3);
    });
  });
}
