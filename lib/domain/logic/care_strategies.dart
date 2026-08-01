// v0.23 round 41 (spen P3-34): 抽 care_engine 4 规则为独立 strategy
//
// 之前 care_engine.dart 224 行,3 个 _is* 私有方法 + 1 个 inline 规则
// (secondDayMissed) 都在 evaluate 内部,4 规则互相纠缠不易测。
//
// 抽 4 个 top-level pure function,care_engine 调它们 + 装配 CareTrigger。
// 每个 strategy 独立易测,可单独 enable/disable。

import 'package:chroniccare/domain/entities/check_in_entity.dart';

/// 关怀策略阈值常量
///
/// 与 streak_calculator.dart 的 expiryThresholdHours = 36 有意独立:
/// care_strategies 判定"漏打卡"的阈值可能随业务调整而不同于 streak 过期阈值。
const _lateHourThreshold = 22;
const _lateHabitDays = 3;
const _lateHabitDayRange = 2;
const _weekendGuardHour = 18;
const _secondDayMissedMinutes = 36 * 60;
const _secondDayMissedHour = 10;

/// 最近 3 天都在 22 点后打卡
///
/// 排序: [sortedDesc] 是按 timestamp 倒序的 normal check-ins
///
/// v0.23 round 43 (spen-3) off-by-one fix: 之前 `> 3` break 实际处理 4 天
/// (day 0,1,2,3),跟注释"最近 3 天"不符。改为 `> 2` 处理 3 天 (day 0,1,2)。
bool isLateCheckInHabit(List<CheckInEntity> sortedDesc, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final lateDays = <DateTime>{};
  for (final c in sortedDesc) {
    final d = DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day);
    if (today.difference(d).inDays > _lateHabitDayRange) break;
    if (c.timestamp.hour >= _lateHourThreshold) {
      lateDays.add(d);
    }
  }
  return lateDays.length >= _lateHabitDays;
}

/// 周末漏打卡（最近一个周末没打卡）
///
/// P7 fix: 之前 `day.isBefore(today)` 排除今天，导致周六整天没打卡
/// 要等周日才看到提醒。改为"今天已经过 18 点且没打卡也算漏"。
bool isWeekendMissed(List<CheckInEntity> sortedDesc, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  for (int i = 0; i < 7; i++) {
    final day = today.subtract(Duration(days: i));
    if (day.weekday != DateTime.saturday && day.weekday != DateTime.sunday) {
      continue;
    }
    // 今天（i==0）：必须已经过 18 点且今天没打卡才算漏
    // 避免早上 8 点就误报"今天漏打卡"
    if (i == 0 && now.hour < _weekendGuardHour) {
      continue;
    }
    final hasCheckIn = sortedDesc.any(
      (c) =>
          c.timestamp.year == day.year &&
          c.timestamp.month == day.month &&
          c.timestamp.day == day.day,
    );
    if (!hasCheckIn) return true;
  }
  return false;
}

/// 最近 7 天每天 22 点前都打卡
///
/// P3 fix: 之前循环遍历**全部历史**, 1 年前有 1 次晚打卡就永远返 false。
/// 现在限制为最近 7 天内。
///
/// v0.24 round 48 (sp-en P1-13) 性能验证: 探索过 `Set<DateTime>` 改法
/// (期望 O(N+7)), 实测**反而慢 4 倍** (20000 entry 28ms → 100ms) —
/// DateTime.hashCode + Set.add 开销大。原 .any() 因 short-circuit
/// 实际 O(N+7×k) ≈ O(N), 20000 entry 28ms 已够快 (RTX 4090 desktop)。
/// 改回原实现, 但保留 perf test 作为 regression guard。
bool isWeekPerfect(List<CheckInEntity> sortedDesc, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final sevenDaysAgo = today.subtract(const Duration(days: 6)); // 含今天共 7 天
  for (final c in sortedDesc) {
    // 早于 7 天前：忽略
    if (c.timestamp.isBefore(sevenDaysAgo)) break;
    if (c.timestamp.hour >= _lateHourThreshold) return false; // 22 点后打卡不算"准时"
  }
  // 检查最近 7 天每天都有打卡
  for (int i = 0; i < 7; i++) {
    final day = today.subtract(Duration(days: i));
    final hasOnDay = sortedDesc.any(
      (c) =>
          c.timestamp.year == day.year &&
          c.timestamp.month == day.month &&
          c.timestamp.day == day.day &&
          c.timestamp.hour < _lateHourThreshold,
    );
    if (!hasOnDay) return false;
  }
  return true;
}

/// 漏 1 天后第二天 10 点还没打卡
///
/// 跟 _is* 不同:这条规则 inline 在 evaluate() 第一行,不是独立 strategy
/// 这里抽出来跟其他 3 条规则平级
bool isSecondDayMissed(List<CheckInEntity> sortedDesc, DateTime now) {
  if (sortedDesc.isEmpty) return false;
  final lastCheckIn = sortedDesc.first.timestamp;
  final minutesSince = now.difference(lastCheckIn).inMinutes;
  return minutesSince >= _secondDayMissedMinutes &&
      now.hour >= _secondDayMissedHour;
}
