// v0.32 R112-01: 日均情绪值真均值算法回归测试
//
// 背景: _MoodLineChart 用 `(dailyAvg[day]! + e.score) / 2` 递推, 是加权衰减
// 平均 (第 n 条权重 1/2^(n-1)), [5,1,1] 算出 2.0 而非真均值 2.33。
// 修复: 抽 computeDailyAverages 纯函数 (sum/count 累计), 同日多条求真均值。
//
// 覆盖:
// 1. 同日 3 条 [5,1,1] → 真均值 7/3 ≈ 2.333 (老算法得 2.0)
// 2. 多日分组: day1 [5] / day2 [1,1] → 5.0 / 1.0
// 3. 同日多条乱序输入 → 结果与顺序无关
// 4. cutoff 之前条目排除
// 5. 单条 → 原值
// 6. 同日 2 条 [3,5] → 4.0 (老算法同值, 3 条案例才暴露偏差)

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
// v1.1.0 R116 (god class 拆): computeDailyAverages 纯函数从 mood_trend_page
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
  final cutoff = DateTime(2026, 8, 10);

  test('1) 同日 3 条 [5,1,1] → 真均值 2.333 (老算法得 2.0)', () {
    final entries = [
      _mood(id: 1, timestamp: DateTime(2026, 8, 11, 9), score: 5),
      _mood(id: 2, timestamp: DateTime(2026, 8, 11, 12), score: 1),
      _mood(id: 3, timestamp: DateTime(2026, 8, 11, 20), score: 1),
    ];
    final avg = computeDailyAverages(entries, cutoff);
    expect(avg[DateTime(2026, 8, 11)], closeTo(7 / 3, 0.001));
    expect(avg.length, 1);
  });

  test('2) 多日分组: day1 [5] / day2 [1,1] → 5.0 / 1.0', () {
    final entries = [
      _mood(id: 1, timestamp: DateTime(2026, 8, 11, 9), score: 5),
      _mood(id: 2, timestamp: DateTime(2026, 8, 12, 8), score: 1),
      _mood(id: 3, timestamp: DateTime(2026, 8, 12, 21), score: 1),
    ];
    final avg = computeDailyAverages(entries, cutoff);
    expect(avg[DateTime(2026, 8, 11)], 5.0);
    expect(avg[DateTime(2026, 8, 12)], 1.0);
  });

  test('3) 同日多条乱序输入 → 结果与顺序无关', () {
    final sorted = [
      _mood(id: 1, timestamp: DateTime(2026, 8, 11, 9), score: 5),
      _mood(id: 2, timestamp: DateTime(2026, 8, 11, 12), score: 1),
      _mood(id: 3, timestamp: DateTime(2026, 8, 11, 20), score: 1),
    ];
    final shuffled = [
      _mood(id: 2, timestamp: DateTime(2026, 8, 11, 12), score: 1),
      _mood(id: 1, timestamp: DateTime(2026, 8, 11, 9), score: 5),
      _mood(id: 3, timestamp: DateTime(2026, 8, 11, 20), score: 1),
    ];
    final a = computeDailyAverages(sorted, cutoff);
    final b = computeDailyAverages(shuffled, cutoff);
    expect(b[DateTime(2026, 8, 11)], closeTo(a[DateTime(2026, 8, 11)]!, 0.001));
  });

  test('4) cutoff 之前条目排除', () {
    final entries = [
      _mood(id: 1, timestamp: DateTime(2026, 8, 9, 23), score: 5),
    ];
    final avg = computeDailyAverages(entries, cutoff);
    expect(avg, isEmpty);
  });

  test('5) 单条 → 原值', () {
    final entries = [
      _mood(id: 1, timestamp: DateTime(2026, 8, 11, 9), score: 4),
    ];
    final avg = computeDailyAverages(entries, cutoff);
    expect(avg[DateTime(2026, 8, 11)], 4.0);
  });

  test('6) 同日 2 条 [3,5] → 4.0', () {
    final entries = [
      _mood(id: 1, timestamp: DateTime(2026, 8, 11, 9), score: 3),
      _mood(id: 2, timestamp: DateTime(2026, 8, 11, 20), score: 5),
    ];
    final avg = computeDailyAverages(entries, cutoff);
    expect(avg[DateTime(2026, 8, 11)], 4.0);
  });
}
