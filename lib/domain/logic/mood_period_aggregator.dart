// v0.30 round 91 (sub-spec 7 日常追踪 / Task 2): MoodPeriodAggregator 纯函数
//
// 4 段 + unspecified 桶聚合 (近 30 天默认):
// - 5 段: morning / noon / evening / night / unspecified
// - 老 entry 兼容: period = null / 'unspecified' 都归 unspecified 桶, 不 crash
// - 1 天 1 entry 模式 (心境的 4 段折线): dailyScoreByPeriod
//
// 0 flutter 0 drift 0 presentation 依赖 (纯 domain 层 calculator,
// 跟 R90 R85 R78 模式一致)。
//
// 用法 (Task 5 整合入口页 / Task 6 多指标图):
// - aggregateByPeriod(entries) → 5 段 map, 拿 avg + count → 心境卡片 + 柱状图
// - dailyScoreByPeriod(entries, day) → [m, n, e, ni] 4 点 → 1 天 4 段折线
library;

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

/// 一段的聚合结果 (avg + count)
typedef PeriodAggregate = ({double avg, int count});

/// 5 段常量 — UI (chip / chart) 跟业务 (聚合) 共享一份字符串
class MoodPeriod {
  MoodPeriod._();

  static const morning = 'morning';
  static const noon = 'noon';
  static const evening = 'evening';
  static const night = 'night';
  static const unspecified = 'unspecified';

  /// 5 段桶顺序 — 跟 chart / chip list 渲染顺序一致
  static const List<String> all = [morning, noon, evening, night, unspecified];

  /// 4 段 (折线用, 不含 unspecified)
  static const List<String> fourPeriods = [morning, noon, evening, night];

  /// 归一桶: period = null / 空 / 不在 4 段内 → 'unspecified'
  ///
  /// 老 entry 兼容 (period 列 nullable, 业务层把 null 跟 'unspecified' 等价)。
  static String normalize(String? period) {
    if (period == null || period.isEmpty) return unspecified;
    if (fourPeriods.contains(period)) return period;
    return unspecified;
  }
}

/// 心境 4 段聚合
class MoodPeriodAggregator {
  MoodPeriodAggregator._();

  /// 给定 mood entries, 返回 5 段桶的 avg + count
  ///
  /// 行为:
  /// - 时间窗: 默认 30 天 (从 now 倒推), 窗口外 entry 不进聚合
  /// - 5 段 (含 unspecified) 必返, 即使 count=0 也返回 avg=0.0
  /// - 老 entry 兼容: period = null 归 'unspecified' 桶
  /// - daysWindow = null = 全部 entry (不限时间, 给 trend page 用)
  /// - now: 可选时间锚点, 默认 DateTime.now(); 给 test 注入固定时间避免 drift
  ///   (R91 集成遗留 bug fix: test 用 `2026-08-05` 但实跑 today 是 `2026-08-07`
  ///   导致 d=29 entry 在 30 天窗边界外被剔除, noon bucket count 从 8 → 7 fail)
  ///
  /// 例子:
  /// ```dart
  /// final result = MoodPeriodAggregator.aggregateByPeriod(entries);
  /// final morningAvg = result['morning']!.avg;   // 3.2
  /// final morningCount = result['morning']!.count;  // 7
  /// ```
  static Map<String, PeriodAggregate> aggregateByPeriod(
    List<MoodEntryEntity> entries, {
    int? daysWindow = 30,
    DateTime? now,
  }) {
    // 1. 过滤时间窗
    final refNow = now ?? DateTime.now();
    final cutoff =
        daysWindow == null ? null : refNow.subtract(Duration(days: daysWindow));
    final filtered = cutoff == null
        ? entries
        : entries.where((e) => !e.timestamp.isBefore(cutoff)).toList();

    // 2. 按归一桶分组
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final p in MoodPeriod.all) {
      sums[p] = 0.0;
      counts[p] = 0;
    }
    for (final e in filtered) {
      final bucket = MoodPeriod.normalize(e.period);
      sums[bucket] = sums[bucket]! + e.score;
      counts[bucket] = counts[bucket]! + 1;
    }

    // 3. 算 avg
    return {
      for (final p in MoodPeriod.all)
        p: (
          avg: counts[p]! == 0 ? 0.0 : sums[p]! / counts[p]!,
          count: counts[p]!,
        ),
    };
  }

  /// 单日 4 段折线 (1 天 1 entry, 含 unspecified 算 0)
  ///
  /// 给定某天的所有 entry, 返回 [morning, noon, evening, night] 各时段
  /// 的 score (缺时兜 0)。
  ///
  /// 行为:
  /// - 跨多天的 entries, 只取 day 当天 (year + month + day 匹配)
  /// - 每段只取当天第一条 (后续多条覆盖 = 取 first; 心境 1 段 1 天通常 1 条)
  /// - 缺段 → 0.0 (chart 折线断点, 跟 R90 multi-line 0 兜底一致)
  ///
  /// 例子:
  /// ```dart
  /// final scores = MoodPeriodAggregator.dailyScoreByPeriod(entries, DateTime(2026, 8, 5));
  /// // scores[0] = morning (e.g. 4.0)
  /// // scores[1] = noon   (e.g. 3.0)
  /// // scores[2] = evening (e.g. 5.0)
  /// // scores[3] = night  (e.g. 2.0)
  /// ```
  static List<double> dailyScoreByPeriod(
    List<MoodEntryEntity> entries,
    DateTime day,
  ) {
    final scores = <double>[0.0, 0.0, 0.0, 0.0];
    final found = <String, bool>{
      MoodPeriod.morning: false,
      MoodPeriod.noon: false,
      MoodPeriod.evening: false,
      MoodPeriod.night: false,
    };

    for (final e in entries) {
      // 1. 同一天 check
      if (e.timestamp.year != day.year ||
          e.timestamp.month != day.month ||
          e.timestamp.day != day.day) {
        continue;
      }
      // 2. 归一桶 (unspecified 跳, 折线只 4 段)
      final bucket = MoodPeriod.normalize(e.period);
      if (bucket == MoodPeriod.unspecified) continue;
      // 3. 已找到则跳 (first wins)
      if (found[bucket]!) continue;

      // 4. 填值
      final idx = MoodPeriod.fourPeriods.indexOf(bucket);
      scores[idx] = e.score.toDouble();
      found[bucket] = true;
    }

    return scores;
  }
}
