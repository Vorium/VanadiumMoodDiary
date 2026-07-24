// v0.23 round 41 (spen P3-34): 抽 care_engine 4 规则为独立 strategy
//
// 之前 care_engine.dart 224 行,3 个 _is* 私有方法 + 1 个 inline 规则
// (secondDayMissed) 都在 evaluate 内部,4 规则互相纠缠不易测。
//
// 抽 4 个 top-level pure function,care_engine 调它们 + 装配 CareTrigger。
// 每个 strategy 独立易测,可单独 enable/disable。
library;

import 'package:chroniccare/domain/entities/check_in_entity.dart';

/// 最近 3 天都在 22 点后打卡
///
/// 排序: [sortedDesc] 是按 timestamp 倒序的 normal check-ins
bool isLateCheckInHabit(List<CheckInEntity> sortedDesc, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final lateDays = <DateTime>{};
  for (final c in sortedDesc) {
    final d = DateTime(c.timestamp.year, c.timestamp.month, c.timestamp.day);
    if (today.difference(d).inDays > 3) break;
    if (c.timestamp.hour >= 22) {
      lateDays.add(d);
    }
  }
  return lateDays.length >= 3;
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
    if (i == 0 && now.hour < 18) {
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
bool isWeekPerfect(List<CheckInEntity> sortedDesc, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final sevenDaysAgo = today.subtract(const Duration(days: 6)); // 含今天共 7 天
  for (final c in sortedDesc) {
    // 早于 7 天前：忽略
    if (c.timestamp.isBefore(sevenDaysAgo)) break;
    if (c.timestamp.hour >= 22) return false; // 22 点后打卡不算"准时"
  }
  // 检查最近 7 天每天都有打卡
  for (int i = 0; i < 7; i++) {
    final day = today.subtract(Duration(days: i));
    final hasOnDay = sortedDesc.any(
      (c) =>
          c.timestamp.year == day.year &&
          c.timestamp.month == day.month &&
          c.timestamp.day == day.day &&
          c.timestamp.hour < 22,
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
  return minutesSince >= 36 * 60 && now.hour >= 10;
}
