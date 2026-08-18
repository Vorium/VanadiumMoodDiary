// trend_utils.dart — 趋势页共享工具类
//
// 从 trend_page.dart 拆分，v0.19 (P1-15)
import 'package:fl_chart/fl_chart.dart';

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

/// 折线图 spot 的复合 key
///
/// fl_chart 的 tooltip 只给 t.x / t.y，原代码用整数除法 + 浮点 ==
/// 反向查 record，几乎永远不匹配。这里用 round 后的整数做 key。
class SpotKey {
  final int x; // round(x * 1e6) 微秒级精度
  final int y; // round(y * 100) 2 位小数
  SpotKey(double x, double y)
      : x = (x * 1e6).round(),
        y = (y * 100).round();

  @override
  bool operator ==(Object other) =>
      other is SpotKey && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// 给定 x 值，在按 x 升序排列的 spots/entries 中找 x 最接近的 entry
class NearestByX {
  final List<double> _xs;
  final List<MoodEntryEntity> _entries;
  NearestByX(List<FlSpot> spots, List<MoodEntryEntity> entries)
      : _xs = spots.map((s) => s.x).toList(),
        _entries = entries;

  MoodEntryEntity lookup(double x) {
    int lo = 0, hi = _xs.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_xs[mid] < x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    if (lo > 0 && (x - _xs[lo - 1]).abs() < (_xs[lo] - x).abs()) {
      return _entries[lo - 1];
    }
    return _entries[lo];
  }
}
