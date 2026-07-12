import '../../data/database/app_database.dart';

/// 连续打卡天数计算器
///
/// 业务规则（死了么模式 + 精神心理宽容）：
/// - 每天打卡 = 连续天数 +1
/// - 距上次打卡 > 36h = 整个 streak 归 0
/// - calendar day 连续无 gap = streak +1
/// - 漏 1 calendar day = streak 归 0（不算完全连续）
///
/// 通知逻辑独立：48h 触发（看 ReminderScheduler，不归 0 触发）
///
/// 临时吃药（type='temp'）**不计入** streak
class StreakCalculator {
  StreakCalculator._();

  /// 阈值（小时）：超过这个时间没打卡，streak 视为 0
  static const int expiryThresholdHours = 36;

  /// 计算当前连续天数
  ///
  /// 算法：
  /// 1. 过滤 normal 类型
  /// 2. 提取去重的 calendar day（一个 day 只算 1 次）
  /// 3. 倒序遍历，gap = 1 day 算连续，gap > 1 day 算中断
  /// 4. 距今天 > 36h 视为过期，streak 0
  static int calculate({
    required List<CheckIn> checkIns,
    required DateTime now,
  }) {
    if (checkIns.isEmpty) return 0;

    final normal = checkIns.where((c) => c.type == 'normal').toList();
    if (normal.isEmpty) return 0;

    // 1. 检查最新打卡是否在 36h 内
    final latest = normal.first;
    if (now.difference(latest.timestamp).inHours > expiryThresholdHours) {
      return 0;
    }

    // 2. 提取去重的 calendar day（倒序）
    final days = <DateTime>[];
    final seen = <String>{};
    for (final c in normal) {
      final day = DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day);
      final key = '${day.year}-${day.month}-${day.day}';
      if (seen.add(key)) {
        days.add(day);
      }
    }
    // days 已经按时间倒序（因为 normal 倒序）

    // 3. 计算连续
    int streak = 1;
    for (int i = 1; i < days.length; i++) {
      final prev = days[i - 1];  // 较新的
      final curr = days[i];      // 较老的
      final daysDiff = prev.difference(curr).inDays;

      if (daysDiff == 1) {
        streak += 1;
      } else {
        // gap > 1 = 中断
        break;
      }
    }

    return streak;
  }

  /// 判断是否需要显示"少 1 次没关系"提示
  /// 即：今天还没打卡
  static bool shouldShowStreakBroken({
    required List<CheckIn> checkIns,
    required DateTime now,
  }) {
    final normal = checkIns.where((c) => c.type == 'normal').toList();
    if (normal.isEmpty) return false;

    final lastCheckIn = normal.first;
    final hoursSinceLast = now.difference(lastCheckIn.timestamp).inHours;
    return hoursSinceLast >= 24;
  }
}
