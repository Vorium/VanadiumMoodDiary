// v1.1.0 R113 (BUG 9): 情绪趋势图无数据日 spot = nullSpot 回归测试
//
// 修前: _MoodLineChart 内联 `FlSpot(x, dailyAvg[day] ?? 0)` — 没记录的日子
// 画在 y=0 (minY 0.5 之下), 看起来像"0 分抑郁日"。
// 修后: 抽 computeTrendSpots 纯函数, 无数据日 = FlSpot.nullSpot
// (x/y 全 NaN, fl_chart splitByNullSpots 折线断开), 有数据日 x = 距今天数。
//
// 覆盖:
// 1. 有数据日 → spot.y == 当日真均值 (同日多条等权), x 按距今天数
// 2. 无数据日 → null spot (x.isNaN && y.isNaN; 修前 y=0)
// 3. 7 天窗口只有 1 条 → 6 null + 1 real
// 4. 排序: 今天 = 最右 (x = days-1), 窗口第一天 = 最左 (x = 0)
// 5. 早于窗口 cutoff 的条目排除 (全 null)

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
// v1.1.0 R116 (god class 拆): computeTrendSpots 纯函数从 mood_trend_page
// 拆到 lib/domain/logic/mood_trend_calculator.dart (0 Flutter 0 drift 依赖)。
import 'package:chroniccare/domain/logic/mood_trend_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

MoodEntryEntity _mood({
  required int id,
  required DateTime timestamp,
  required int score,
}) {
  return MoodEntryEntity(id: id, timestamp: timestamp, score: score);
}

void main() {
  // now 固定 12:00 — cutoff 时间分量一致, 同日 12:00 条目恰好在界内
  final now = DateTime(2026, 8, 16, 12);

  test('1) 有数据日 → y == 真均值, x 按距今天数', () {
    final entries = [
      _mood(id: 1, timestamp: DateTime(2026, 8, 16, 9), score: 5),
      _mood(id: 2, timestamp: DateTime(2026, 8, 16, 10), score: 1),
      _mood(id: 3, timestamp: DateTime(2026, 8, 13, 12), score: 4),
    ];
    final spots = computeTrendSpots(entries, now, 7);
    expect(spots.length, 7);
    // 今天 (i=0): x = 6, 均值 (5+1)/2 = 3
    expect(spots[6].x, 6.0);
    expect(spots[6].y, closeTo(3.0, 0.001));
    // 3 天前 (i=3): x = 3, 单条 4
    expect(spots[3].x, 3.0);
    expect(spots[3].y, 4.0);
  });

  test('2) 无数据日 → null spot (x/y 全 NaN, 修前 y=0)', () {
    final spots = computeTrendSpots(
      [_mood(id: 1, timestamp: DateTime(2026, 8, 16, 9), score: 5)],
      now,
      7,
    );
    for (int i = 0; i < 6; i++) {
      expect(
        spots[i].x.isNaN,
        isTrue,
        reason: '第 $i 天无数据 → x NaN (FlSpot.nullSpot)',
      );
      expect(
        spots[i].y.isNaN,
        isTrue,
        reason: '第 $i 天无数据 → y NaN; 修前 y=0 画成 0 分抑郁日',
      );
    }
  });

  test('3) 7 天窗口只有 1 条 → 6 null + 1 real', () {
    final spots = computeTrendSpots(
      [_mood(id: 1, timestamp: DateTime(2026, 8, 16, 9), score: 5)],
      now,
      7,
    );
    final nullCount = spots.where((s) => s.x.isNaN).length;
    final realCount = spots.where((s) => !s.x.isNaN).length;
    expect(nullCount, 6);
    expect(realCount, 1);
    expect(spots.last.y, 5.0);
  });

  test('4) 排序: 今天 = 最右 (x = days-1), 窗口第一天 = 最左 (x = 0)', () {
    final spots = computeTrendSpots(
      [
        // 窗口第一天 (cutoff 日 12:00, 恰在界内)
        _mood(id: 1, timestamp: DateTime(2026, 8, 10, 12), score: 5),
        // 今天
        _mood(id: 2, timestamp: DateTime(2026, 8, 16, 9), score: 3),
      ],
      now,
      7,
    );
    expect(spots[0].y, 5.0, reason: '窗口第一天在最左 x=0');
    expect(spots[6].y, 3.0, reason: '今天在最右 x=6');
    expect(spots[6].x, 6.0);
  });

  test('5) 早于窗口 cutoff 的条目排除 → 全 null', () {
    final spots = computeTrendSpots(
      [_mood(id: 1, timestamp: DateTime(2026, 8, 1, 12), score: 5)],
      now,
      7,
    );
    expect(spots.every((s) => s.x.isNaN), isTrue);
  });
}
