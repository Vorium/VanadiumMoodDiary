// v0.30 round 91 (sub-spec 7 日常追踪 / Task 2): MoodPeriodAggregator 纯函数 行为锁定
//
// 覆盖 (TDD red→green):
// 1. aggregateByPeriod: 30 entry 4 段聚合 + unspecified 桶, 5 段 count + avg 正确
// 2. aggregateByPeriod: 空 entry → 5 段全 0
// 3. dailyScoreByPeriod: 1 天 4 entry → [morning, noon, evening, night] score
//                         缺时 null 兜 0
//
// 设计要点 (跟 R90 R85 R78 calculator 一致):
// - 0 flutter 0 drift 0 presentation 依赖 (纯 domain 层)
// - 老 entry 兼容: period = null → 'unspecified' 桶, 不 crash
// - aggregateByPeriod(daysWindow) 默认 30 天, 超过窗口的 entry 不进 avg

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/logic/mood_period_aggregator.dart';
import 'package:flutter_test/flutter_test.dart';

/// helper: 造一条 mood entry (period 可选, 默认 null = 老 entry 兼容)
MoodEntryEntity _entry({
  required int id,
  required DateTime at,
  required int score,
  String? period,
}) {
  return MoodEntryEntity(
    id: id,
    timestamp: at,
    score: score,
    period: period,
  );
}

void main() {
  group('MoodPeriodAggregator.aggregateByPeriod (5 段桶, 含 unspecified)', () {
    test('30 entry 4 段 + unspecified: 5 段 count + avg 正确', () {
      // 30 天, 每天 1 条 entry, 周期循环 morning/noon/evening/night
      // 30 / 4 = 7.5 → morning: 8, noon: 8, evening: 7, night: 7
      // 加 4 条 unspecified (period=null 模拟老 entry) → total 34
      final now = DateTime(2026, 8, 5, 12, 0);
      final entries = <MoodEntryEntity>[];

      // 30 天循环 (每天一条, period 循环)
      const periods = ['morning', 'noon', 'evening', 'night'];
      const scores = [3, 4, 5, 2]; // 每段固定 score (算平均简单)
      for (int d = 0; d < 30; d++) {
        final p = periods[d % 4];
        final s = scores[d % 4];
        entries.add(_entry(
          id: d + 1,
          at: now.subtract(Duration(days: d)),
          score: s,
          period: p,
        ));
      }
      // 加 4 条 unspecified (老 entry 模拟, period = null)
      for (int i = 0; i < 4; i++) {
        entries.add(_entry(
          id: 100 + i,
          at: now.subtract(Duration(days: 35 + i)),
          score: 4,
          period: null,
        ));
      }

      // 默认 30 天窗 → unspecified 4 条 (35+ 天前) 全被剔除
      // R95 sub-spec 6 task 6a fix: 传 now 避免 test 漂移 (实跑 today 是
      // 2026-08-07, test 用 2026-08-05, 不传 now 会让 d=29 entry 被剔除)
      final result = MoodPeriodAggregator.aggregateByPeriod(entries, now: now);

      // morning: 8 条, 全 score=3 → avg=3.0
      expect(result['morning']!.count, 8);
      expect(result['morning']!.avg, closeTo(3.0, 0.001));
      // noon: 8 条, 全 score=4 → avg=4.0
      expect(result['noon']!.count, 8);
      expect(result['noon']!.avg, closeTo(4.0, 0.001));
      // evening: 7 条, 全 score=5 → avg=5.0
      expect(result['evening']!.count, 7);
      expect(result['evening']!.avg, closeTo(5.0, 0.001));
      // night: 7 条, 全 score=2 → avg=2.0
      expect(result['night']!.count, 7);
      expect(result['night']!.avg, closeTo(2.0, 0.001));
      // unspecified: 0 条 (全超 30 天窗)
      expect(result['unspecified']!.count, 0);
      expect(result['unspecified']!.avg, 0.0);
    });

    test('空 entry → 5 段全 0 (不 crash, 兜底)', () {
      final result = MoodPeriodAggregator.aggregateByPeriod(const []);

      // 5 段必须有, 全 count=0 + avg=0
      expect(result.length, 5);
      expect(result['morning']!.count, 0);
      expect(result['morning']!.avg, 0.0);
      expect(result['noon']!.count, 0);
      expect(result['noon']!.avg, 0.0);
      expect(result['evening']!.count, 0);
      expect(result['evening']!.avg, 0.0);
      expect(result['night']!.count, 0);
      expect(result['night']!.avg, 0.0);
      expect(result['unspecified']!.count, 0);
      expect(result['unspecified']!.avg, 0.0);
    });

    test('老 entry (period = null) 在窗口内 → 归 unspecified 桶', () {
      // 3 条老 entry (period=null), 都在 30 天内
      final now = DateTime(2026, 8, 5, 12, 0);
      final entries = [
        _entry(id: 1, at: now.subtract(const Duration(days: 1)), score: 3),
        _entry(id: 2, at: now.subtract(const Duration(days: 5)), score: 5),
        _entry(id: 3, at: now.subtract(const Duration(days: 10)), score: 4),
      ];

      final result = MoodPeriodAggregator.aggregateByPeriod(entries, now: now);

      // 3 条全归 unspecified, avg = (3+5+4)/3 = 4.0
      expect(result['unspecified']!.count, 3);
      expect(result['unspecified']!.avg, closeTo(4.0, 0.001));
      // 其它 4 段全空
      expect(result['morning']!.count, 0);
      expect(result['noon']!.count, 0);
      expect(result['evening']!.count, 0);
      expect(result['night']!.count, 0);
    });
  });

  group('MoodPeriodAggregator.dailyScoreByPeriod (1 天 4 段折线)', () {
    test('1 天 4 entry (morning/noon/evening/night) → [m, n, e, ni] score', () {
      // 1 天 = 2026-08-05, 4 entry 各时段
      final day = DateTime(2026, 8, 5);
      final entries = [
        _entry(
          id: 1,
          at: DateTime(2026, 8, 5, 8, 0),
          score: 4,
          period: 'morning',
        ),
        _entry(
          id: 2,
          at: DateTime(2026, 8, 5, 12, 30),
          score: 3,
          period: 'noon',
        ),
        _entry(
          id: 3,
          at: DateTime(2026, 8, 5, 19, 0),
          score: 5,
          period: 'evening',
        ),
        _entry(
          id: 4,
          at: DateTime(2026, 8, 5, 23, 30),
          score: 2,
          period: 'night',
        ),
      ];

      final scores = MoodPeriodAggregator.dailyScoreByPeriod(entries, day);

      // [morning, noon, evening, night] = [4, 3, 5, 2]
      expect(scores.length, 4);
      expect(scores[0], 4.0);
      expect(scores[1], 3.0);
      expect(scores[2], 5.0);
      expect(scores[3], 2.0);
    });

    test('缺时段 → 兜 0 (e.g. 只 morning + evening)', () {
      final day = DateTime(2026, 8, 5);
      final entries = [
        _entry(
          id: 1,
          at: DateTime(2026, 8, 5, 8, 0),
          score: 4,
          period: 'morning',
        ),
        _entry(
          id: 2,
          at: DateTime(2026, 8, 5, 19, 0),
          score: 5,
          period: 'evening',
        ),
      ];

      final scores = MoodPeriodAggregator.dailyScoreByPeriod(entries, day);

      // [4, 0, 5, 0] (noon / night 缺 → 0)
      expect(scores, [4.0, 0.0, 5.0, 0.0]);
    });
  });
}
