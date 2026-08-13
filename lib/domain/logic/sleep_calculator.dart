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

  /// 7 天 bedtime 规律性评分 (1-5) — v0.32 R110 round 7a (B1-3) 圆形统计
  ///
  /// 修复前: 线性 mean/stdDev (hour*60+minute) — 跨午夜交替作息
  /// (23:50/00:10 每天轮流 = 极规律) 被算成 ~710min 巨大 stdDev → 1。
  /// 修复后: Mardia 圆形标准差 (circular statistics standard approach):
  /// 1. 把一天 1440min 映射到 0..2π 圆周
  /// 2. 合向量长度 R = √(Σsinθ)²+(Σcosθ)² / N (R=1 全聚一点, R=0 均匀散开)
  /// 3. 圆形 std = √(−2·ln R) 弧度 → 换算分钟 (Mardia & Jupp 2000)
  ///
  /// 评分 bands (跟修复前一致, 单位分钟):
  /// - stdDev < 30 → 5 (最规律)
  /// - stdDev < 60 → 4
  /// - stdDev < 90 → 3
  /// - stdDev < 120 → 2
  /// - else → 1
  ///
  /// 圆形性质: 23:50/00:10 交替 → R≈1 → 10min → 5；
  /// 均匀分布 (00/08/16) → R≈0 → 363min → 1。
  /// < 3 天 → null (样本太小)。
  static int? regularityScore(List<DateTime> last7DaysBedtimes) {
    if (last7DaysBedtimes.length < 3) return null;
    final n = last7DaysBedtimes.length;
    const minutesPerDay = 24 * 60;
    final sinSum = last7DaysBedtimes.fold<double>(
        0, (a, d) => a + math.sin(_toAngle(d)),);
    final cosSum = last7DaysBedtimes.fold<double>(
        0, (a, d) => a + math.cos(_toAngle(d)),);
    final r = math.sqrt(sinSum * sinSum + cosSum * cosSum) / n;
    // Mardia circular standard deviation: σ = √(−2·ln R) 弧度
    final stdDevRad = math.sqrt(-2 * math.log(r));
    final stdDevMin = stdDevRad / (2 * math.pi) * minutesPerDay;
    if (stdDevMin < 30) return 5;
    if (stdDevMin < 60) return 4;
    if (stdDevMin < 90) return 3;
    if (stdDevMin < 120) return 2;
    return 1;
  }

  static double _toAngle(DateTime d) =>
      (d.hour * 60 + d.minute) / (24 * 60) * 2 * math.pi;
}
