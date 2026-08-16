// v1.1.0 R116 (god class 拆): mood_trend_page 纯逻辑抽取
//
// 历史:
// - v0.30 R101: 情绪趋势图页 — 参照 Apple Health State of Mind
// - v0.32 R112-01: 按天计算情绪分真均值 (sum/count)
// - v1.1.0 R113 (BUG 9): 无数据日 = nullSpot (fl_chart 折线断开)
// - v1.1.0 R116: 653L god class → 拆 4 文件, 本文件装纯函数 + enum
//
// 0 Flutter 0 drift 依赖, 跟 lib/domain/logic/ 同款。
// 拆分前在 mood_trend_page.dart 内联, 单元测试直接 import top-level
// 函数 (computeDailyAverages / computeTrendSpots), 拆后路径不变。
import 'package:fl_chart/fl_chart.dart';

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

/// 趋势时间范围 (4 档)
enum MoodTrendTimeRange {
  week(7, '7D'),
  month(30, '30D'),
  halfYear(180, '6M'),
  year(365, '1Y');

  const MoodTrendTimeRange(this.days, this.label);
  final int days;
  final String label;
}

/// v0.32 R112-01: 按天计算情绪分真均值 (sum/count)
///
/// 修前 bug: 老实现 `(dailyAvg[day]! + score) / 2` 是加权衰减平均
/// (第 n 条权重 1/2^(n-1)), [5,1,1] 算出 2.0 而非真均值 2.33。
/// 本函数用 (sum, count) 累计再除, 同日多条每条等权。
/// 早于 [cutoff] 的条目直接跳过。
Map<DateTime, double> computeDailyAverages(
  List<MoodEntryEntity> entries,
  DateTime cutoff,
) {
  final sums = <DateTime, (int sum, int count)>{};
  for (final e in entries) {
    if (e.timestamp.isBefore(cutoff)) continue;
    final day = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
    final cur = sums[day];
    sums[day] = cur == null ? (e.score, 1) : (cur.$1 + e.score, cur.$2 + 1);
  }
  return sums.map((day, acc) => MapEntry(day, acc.$1 / acc.$2));
}

/// v1.1.0 R113 (BUG 9): 生成近 [days] 天趋势折线 spots
///
/// 修前 bug: 无数据日 `dailyAvg[day] ?? 0` 画在 y=0 (minY 0.5 之下) —
/// 没记录的日子看起来像 0 分抑郁日。修: 无数据日放 [FlSpot.nullSpot]
/// (fl_chart 0.69 `splitByNullSpots` 把折线在缺口断开, touch/dot/paint
/// 全跳过 null spot), 有数据日 x = 距今天数 (0 = 今天)。
///
/// public 供 unit test 直接断言 spots, 不依赖图表渲染。
List<FlSpot> computeTrendSpots(
  List<MoodEntryEntity> entries,
  DateTime now,
  int days,
) {
  final cutoff = now.subtract(Duration(days: days - 1));
  final dailyAvg = computeDailyAverages(entries, cutoff);
  final spots = <FlSpot>[];
  for (int i = days - 1; i >= 0; i--) {
    final day = DateTime(now.year, now.month, now.day - i);
    final avg = dailyAvg[day];
    spots.add(
      avg == null ? FlSpot.nullSpot : FlSpot((days - 1 - i).toDouble(), avg),
    );
  }
  return spots;
}
