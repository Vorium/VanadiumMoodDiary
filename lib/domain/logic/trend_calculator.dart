/// 趋势数据计算 + 序列化
///
/// 各种时间窗口的打卡数据，用于趋势图展示：
/// - [DailyCheckIn]：30/90 天每天是否打卡（热力图）
/// - [MonthlyCheckIn]：最近 N 个月每月打卡率（柱状图）
/// - [StreakSummary]：当前连续 + 最长连续
/// - [CalendarMonth] / [CalendarDay]：v0.12 (Round 6) 日历视图
library;

import '../entities/check_in_entity.dart';
import '../entities/mood_entry_entity.dart';
import 'streak_calculator.dart';

class DailyCheckIn {
  final DateTime date; // 0 点
  final bool checked;

  const DailyCheckIn({required this.date, required this.checked});
}

class MonthlyCheckIn {
  final DateTime month; // 当月 1 号 0 点
  final int totalDays;
  final int checkedDays;

  const MonthlyCheckIn({
    required this.month,
    required this.totalDays,
    required this.checkedDays,
  });

  double get rate => totalDays == 0 ? 0 : checkedDays / totalDays;
}

class StreakSummary {
  final int currentStreak;
  final int longestStreak;
  final int totalCheckIns;
  final int totalDays;

  const StreakSummary({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCheckIns,
    required this.totalDays,
  });
}

/// v0.12 (Round 6) 日历视图
///
/// 一天的事件集合：打卡数 + 最高情绪分 + 该天是否完成
class CalendarDay {
  final DateTime date; // 当天 0 点
  final int checkInCount; // 当天打卡次数（normal + temp + assessment 都算）
  final int? moodScore; // 当天最高情绪分（1-5），null = 没记录
  final bool hasNormalCheckIn; // 是否完成每日打卡

  const CalendarDay({
    required this.date,
    required this.checkInCount,
    required this.moodScore,
    required this.hasNormalCheckIn,
  });

  bool get isEmpty => checkInCount == 0 && moodScore == null;
}

/// 一个月的日历数据
///
/// cells 长度 = 42（6 行 × 7 列），从周一开始排
class CalendarMonth {
  final DateTime month; // 当月 1 号 0 点
  final List<CalendarDay> cells; // 长度 42，含上月末尾 + 当月 + 下月开头
  final Map<DateTime, CalendarDay> byDate; // 当月每天的快速查表

  const CalendarMonth({
    required this.month,
    required this.cells,
    required this.byDate,
  });
}

/// 趋势数据计算器
class TrendCalculator {
  TrendCalculator._();

  /// 计算每天是否打卡（最近 [days] 天）
  ///
  /// 返回按时间正序的列表（最早在前，最新在后）
  static List<DailyCheckIn> dailyBreakdown({
    required List<CheckInEntity> checkIns,
    required int days,
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final result = <DailyCheckIn>[];
    // 把 checkIns 按 date group
    final byDate = <DateTime, int>{};
    for (final c in checkIns) {
      if (!c.isNormal) continue;
      final d = _dateOnly(c.timestamp);
      byDate[d] = (byDate[d] ?? 0) + 1;
    }
    for (int i = days - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      result.add(
        DailyCheckIn(
          date: d,
          checked: (byDate[d] ?? 0) > 0,
        ),
      );
    }
    return result;
  }

  /// 计算最近 [months] 个月每月打卡率
  static List<MonthlyCheckIn> monthlyBreakdown({
    required List<CheckInEntity> checkIns,
    required int months,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final result = <MonthlyCheckIn>[];
    // 按 (year, month) group
    final checkedByMonth = <String, Set<DateTime>>{};
    for (final c in checkIns) {
      if (!c.isNormal) continue;
      final key = _monthKey(c.timestamp);
      checkedByMonth.putIfAbsent(key, () => <DateTime>{});
      checkedByMonth[key]!.add(_dateOnly(c.timestamp));
    }
    for (int i = months - 1; i >= 0; i--) {
      final m = DateTime(today.year, today.month - i, 1);
      final key = _monthKey(m);
      final nextMonth = DateTime(m.year, m.month + 1, 1);
      final totalDays = nextMonth.difference(m).inDays;
      final checkedDays = checkedByMonth[key]?.length ?? 0;
      result.add(
        MonthlyCheckIn(
          month: m,
          totalDays: totalDays,
          checkedDays: checkedDays,
        ),
      );
    }
    return result;
  }

  /// 计算连续天数 + 总打卡
  static StreakSummary streakSummary({
    required List<CheckInEntity> checkIns,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final normal = checkIns.where((c) => c.isNormal).toList();
    return StreakSummary(
      currentStreak: StreakCalculator.calculate(checkIns: normal, now: today),
      longestStreak: _longestStreak(normal),
      totalCheckIns: normal.length,
      totalDays: _uniqueDays(normal).length,
    );
  }

  static int _longestStreak(List<CheckInEntity> checkIns) {
    final dates = _uniqueDays(checkIns);
    if (dates.isEmpty) return 0;
    dates.sort();
    int longest = 1;
    int current = 1;
    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        current++;
        longest = current > longest ? current : longest;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  static List<DateTime> _uniqueDays(List<CheckInEntity> checkIns) {
    final set = <DateTime>{};
    for (final c in checkIns) {
      set.add(_dateOnly(c.timestamp));
    }
    return set.toList();
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static String _monthKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}';

  // ============== v0.12 (Round 6) 日历视图 ==============

  /// 计算某月（[month] 当月 1 号 0 点）的日历数据
  ///
  /// 返回 6 行 × 7 列 = 42 格（周一开始）。
  /// 上月末尾和下月开头填当月 [CalendarDay] 副本（isEmpty=true），方便 UI
  /// 直接画 7×6 网格。
  static CalendarMonth monthlyCalendar({
    required DateTime month,
    required List<CheckInEntity> checkIns,
    List<MoodEntryEntity> moodEntries = const [],
  }) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    // Monday = 1 ... Sunday = 7
    // Dart weekday: Monday=1, Sunday=7
    // 我们想让周一作为一周的第一列, 所以偏移:
    // 当月 1 号的 weekday - 1 就是它前面有几格
    final leading = firstOfMonth.weekday - 1; // 0..6
    final gridStart = firstOfMonth.subtract(Duration(days: leading));

    // 按天 group
    final byDate = <DateTime, _DailyAgg>{};
    for (final c in checkIns) {
      final d = _dateOnly(c.timestamp);
      final agg = byDate.putIfAbsent(d, () => _DailyAgg());
      agg.checkInCount++;
      if (c.isNormal) agg.hasNormalCheckIn = true;
    }
    for (final m in moodEntries) {
      final d = _dateOnly(m.timestamp);
      final agg = byDate.putIfAbsent(d, () => _DailyAgg());
      // 当天最高分
      if (agg.moodScore == null || m.score > agg.moodScore!) {
        agg.moodScore = m.score;
      }
    }

    final cells = <CalendarDay>[];
    final inMonthByDate = <DateTime, CalendarDay>{};
    for (int i = 0; i < 42; i++) {
      final d = gridStart.add(Duration(days: i));
      final agg = byDate[d];
      final day = CalendarDay(
        date: d,
        checkInCount: agg?.checkInCount ?? 0,
        moodScore: agg?.moodScore,
        hasNormalCheckIn: agg?.hasNormalCheckIn ?? false,
      );
      cells.add(day);
      if (d.month == firstOfMonth.month) {
        inMonthByDate[d] = day;
      }
    }
    return CalendarMonth(
      month: firstOfMonth,
      cells: cells,
      byDate: inMonthByDate,
    );
  }

  /// 月份 shift：返回 [delta] 个月后的当月 1 号 0 点
  /// delta = 1 = 下个月, -1 = 上个月
  static DateTime shiftMonth(DateTime month, int delta) {
    return DateTime(month.year, month.month + delta, 1);
  }
}

class _DailyAgg {
  int checkInCount = 0;
  bool hasNormalCheckIn = false;
  int? moodScore;
}
