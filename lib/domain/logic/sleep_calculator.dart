// v0.30 round 91 (sub-spec 7 日常追踪): SleepCalculator 纯函数
//
// 4 层架构: domain 0 flutter 0 drift, 跟 R60 R90 calculator 模式一致
// (StreakCalculator / AssessmentComparison 等都是纯函数 + static method)。
//
// 用法:
//   SleepCalculator.durationMin(bedtime, wakeTime) → 分钟
//   SleepCalculator.regularityScore(7DaysBedtimes) → 1-5 / null
import 'dart:math' as math;

/// 睡眠计算器
class SleepCalculator {
  SleepCalculator._();

  /// 计算睡眠时长 (分钟), 跨午夜支持
  ///
  /// 精神心理用户常见晚睡早醒 (e.g. 23:00 入睡, 07:30 起床 = 510 min)。
  /// 当 wakeTime < bedtime (跨午夜) → 自动 +1 天。
  ///
  /// 边界 case: bedtime == wakeTime → 0 min (用户填同时间, 表示"没睡")。
  static int durationMin(DateTime bedtime, DateTime wakeTime) {
    Duration d = wakeTime.difference(bedtime);
    if (d.isNegative) d += const Duration(days: 1);
    return d.inMinutes;
  }

  /// 7 天 bedtime 规律性评分 (1-5)
  ///
  /// 算法: 7 天 bedtime 的 "hour*60 + minute" 算标准差
  /// - stdDev < 30 min → 5 (最规律)
  /// - stdDev < 60 min → 4
  /// - stdDev < 90 min → 3
  /// - stdDev < 120 min → 2
  /// - else → 1 (最不规律)
  ///
  /// < 3 天数据 → null (样本太小, 无统计学意义)。
  ///
  /// 接受 `List<DateTime>` 不用 SleepEntry 是为了 calculator 0 依赖 entity
  /// (0 flutter 0 drift 0 entity) — caller 决定传啥, calculator 只算值。
  static int? regularityScore(List<DateTime> last7DaysBedtimes) {
    if (last7DaysBedtimes.length < 3) return null;
    final minutes = last7DaysBedtimes
        .map((d) => d.hour * 60 + d.minute)
        .toList(growable: false);
    final mean = minutes.reduce((a, b) => a + b) / minutes.length;
    final variance =
        minutes.map((m) => (m - mean) * (m - mean)).reduce((a, b) => a + b) /
            minutes.length;
    final stdDev = math.sqrt(variance);
    if (stdDev < 30) return 5;
    if (stdDev < 60) return 4;
    if (stdDev < 90) return 3;
    if (stdDev < 120) return 2;
    return 1;
  }
}
