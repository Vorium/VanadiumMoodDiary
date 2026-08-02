// v0.27 round 82 (P0 架构修复): RefillScheduler 纯函数抽离
//
// 背景 (P0 架构违规):
//   `lib/domain/usecases/schedule_refill_reminder.dart:17` 之前
//   `import 'package:chroniccare/core/data/services/refill_notifier.dart';`,
//   后者顶部 import `package:flutter_local_notifications/...` (flutter plugin)。
//   Dart import 链整个文件拉入,导致 domain 间接依赖 flutter,违反
//   "domain 0 flutter" 4 层架构。
//
// 修法:
//   抽 `RefillScheduler` 纯函数类到本文件 (domain/logic/), 0 副作用,
//   0 Flutter 依赖, 0 Drift 依赖, 只用 dart:core + dart:collection。
//   `RefillNotifier.computeRefillFireTime` 改为委托本类,保持 backward
//   compatible (老 caller facade import 不动)。
//   `ScheduleRefillReminderUseCase` 改 import 本类,切断 flutter 间接依赖。
//
// 设计原则 (跟 ReminderScheduler / StreakCalculator / DayDetail 一致):
//   - 私有构造 `_()`, 不可实例化
//   - 静态方法, 接受 now (caller 注入防 midnight race)
//   - 返回值不可变 (DateTime 是 immutable, 没事)
//   - 错误走 throws (跟原 computeRefillFireTime 1:1 行为)
//   - dartdoc 详细, 跟 R65/R56c 风格统一

/// v0.27 round 82: 续方提醒时间计算 (domain 层纯函数)
///
/// 业务规则:
/// - fire time = `(refillAt - reminderDays) 当天 9:00 本地时间`
/// - 跨月 / 跨年 / 闰年走 Dart `DateTime.subtract(Duration)`,自动正确
/// - `refillAt == null` → 返回 `null` (caller 跳过此 med, no-op)
/// - `reminderDays < 1` → 抛 [ArgumentError] (跟原
///   `RefillNotifier.computeRefillFireTime` 1:1 行为, 老 test 不破)
///
/// 0 副作用 / 0 Flutter 依赖 / 0 Drift 依赖。
/// 抽出原因: 满足 4 层架构 (domain 0 flutter), 让 use case 层能
/// 单独验证时间计算, 不间接 import flutter plugin。
class RefillScheduler {
  RefillScheduler._();

  /// 续方提醒触发时间 = (refillAt - reminderDays) 当天 9:00
  ///
  /// 参数:
  /// - [refillAt] 续方日期 (DateTime), null = 该 med 无续方计划, 返回 null
  /// - [reminderDays] 提前多少天提醒, 必须 >= 1, 否则抛 [ArgumentError]
  ///
  /// 返回:
  /// - null: [refillAt] 为 null
  /// - [DateTime]: fire time (当天 9:00:00)
  ///
  /// 实现细节:
  /// - `refillAt` 带时分秒时, 忽略时分秒, 只用日期部分
  /// - `subtract(Duration(days: reminderDays))` 自动处理跨月/跨年/闰年
  /// - 最终 `DateTime(y, m, d, 9)` 拼装 9:00:00 本地时间
  ///
  /// 锁 (R82 复测 R56c 8 case 行为不变):
  /// - reminderDays < 1 → ArgumentError
  /// - refillAt = null → null
  /// - 跨月 / 跨年 / 时分秒 (00:00:00 / 23:59:59) → fireTime 一致
  static DateTime? computeRefillFireTime({
    required DateTime? refillAt,
    required int reminderDays,
  }) {
    if (refillAt == null) return null;
    if (reminderDays < 1) {
      throw ArgumentError('reminderDays must be >= 1; got: $reminderDays');
    }
    // 续方日期当天的 0 点, 再 - reminderDays 天, 再 + 9 小时
    final day = DateTime(refillAt.year, refillAt.month, refillAt.day);
    final triggerDay = day.subtract(Duration(days: reminderDays));
    return DateTime(
      triggerDay.year,
      triggerDay.month,
      triggerDay.day,
      9, // 上午 9 点
    );
  }

  /// 按"天"计算 refill 距今多少天 (不直接用 Duration.inDays)
  ///
  /// 不直接用 `Duration.inDays` 的原因:
  /// - 23.98h 会被报成 0 天
  /// - refill day 整天应该算"今天还有 X 天", 不能因时分秒而错
  ///
  /// v0.27 round 82: 从 `RefillNotifier._daysUntilRefill` 抽到本类
  /// (原为 instance method 私有, 外部 use case 拿不到)。抽完后
  /// `ScheduleRefillReminderUseCase` / notification builder / 任何
  /// 业务编排都能用, 不必走 service 间接调。
  static int daysUntilRefill(DateTime refillAt, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final refillDay = DateTime(refillAt.year, refillAt.month, refillAt.day);
    return refillDay.difference(today).inDays;
  }
}
