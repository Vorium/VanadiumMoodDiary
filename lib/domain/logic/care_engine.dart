/// AI 关怀提醒引擎（v0.7）
///
/// 当前实现：rule-based（基于历史数据的规则触发）
/// 长期目标：接入本地 MedGemma 1.5 / Llama 3 做更智能的上下文理解
///
/// 触发规则：
/// - 持续晚归（连续 3 天 22 点后打卡）→ 主动 push "记得早点休息"
/// - 周末漏打卡 → 主动 push "周末也要记得吃药"
/// - 漏 1 天后第二天 10 点还没打卡 → 主动 push "你还好吗？"（不是通知家人）
/// - 连续 7 天准时 → 庆祝 push "你真棒！"
///
/// v0.18 round 18 (P1-11) fix: 文案集中到 core/shared/care_copy.dart,
/// 不再 const string inline。trigger 4 个文案 + 软提醒共用一份 source of truth,
/// 避免双推 (setup 软提醒 + CareEngine 立即 push 文案重复)。
library;

import 'dart:developer' as developer;

import 'package:chroniccare/core/shared/care_copy.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/repositories/notification_sender.dart';

enum CareTriggerType {
  lateCheckInHabit, // 持续晚归
  weekendMissed, // 周末漏打卡
  secondDayMissed, // 漏 1 天后第二天还没打卡
  weekPerfect, // 连续 7 天准时
  none,
}

class CareTrigger {
  final CareTriggerType type;
  final String title;
  final String body;

  const CareTrigger({
    required this.type,
    required this.title,
    required this.body,
  });

  bool get shouldFire => type != CareTriggerType.none;
}

/// 关怀引擎
///
/// 用法：
/// ```dart
/// final trigger = CareEngine.evaluate(checkIns: ..., now: ...);
/// if (trigger.shouldFire) {
///   await notificationService.showNow(trigger.title, trigger.body);
/// }
/// ```
class CareEngine {
  CareEngine._();

  /// 评估当前状态是否需要关怀
  ///
  /// 业务逻辑：
  /// 1. 漏 1 天后第二天 10 点还没打卡 → 触发 secondDayMissed
  /// 2. 持续晚归（最近 3 天都在 22 点后）→ 触发 lateCheckInHabit
  /// 3. 周末漏打卡 → 触发 weekendMissed
  /// 4. 最近 7 天每天 22 点前都打卡 → 触发 weekPerfect
  static CareTrigger evaluate({
    required List<CheckInEntity> checkIns,
    required DateTime now,
  }) {
    final normal = checkIns.where((c) => c.isNormal).toList();
    if (normal.isEmpty) {
      return const CareTrigger(
        type: CareTriggerType.none,
        title: '',
        body: '',
      );
    }

    // 按时间倒序
    normal.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final lastCheckIn = normal.first.timestamp;
    // P2 fix: 用 inMinutes 替代 inHours,避免 36h 边界整数截断误判
    final minutesSince = now.difference(lastCheckIn).inMinutes;

    // 规则 1: 漏 1 天后第二天 10 点还没打卡
    if (minutesSince >= 36 * 60 && now.hour >= 10) {
      final copy = CareCopy.forTrigger(CareTriggerType.secondDayMissed);
      return CareTrigger(
        type: CareTriggerType.secondDayMissed,
        title: copy.title,
        body: copy.body,
      );
    }

    // 规则 2: 持续晚归（最近 3 天都在 22 点后）
    if (_isLateCheckInHabit(normal, now)) {
      final copy = CareCopy.forTrigger(CareTriggerType.lateCheckInHabit);
      return CareTrigger(
        type: CareTriggerType.lateCheckInHabit,
        title: copy.title,
        body: copy.body,
      );
    }

    // 规则 3: 周末漏打卡
    if (_isWeekendMissed(normal, now)) {
      final copy = CareCopy.forTrigger(CareTriggerType.weekendMissed);
      return CareTrigger(
        type: CareTriggerType.weekendMissed,
        title: copy.title,
        body: copy.body,
      );
    }

    // 规则 4: 最近 7 天每天 22 点前都打卡
    if (_isWeekPerfect(normal, now)) {
      final copy = CareCopy.forTrigger(CareTriggerType.weekPerfect);
      return CareTrigger(
        type: CareTriggerType.weekPerfect,
        title: copy.title,
        body: copy.body,
      );
    }

    return const CareTrigger(
      type: CareTriggerType.none,
      title: '',
      body: '',
    );
  }

  /// 触发关怀（实际推送）
  static Future<void> fire(
    CareTrigger trigger,
    NotificationSender notificationService,
  ) async {
    if (!trigger.shouldFire) return;
    // 关怀通知 id：4000-4099 段，避免和其他通知冲突
    final id = 4000 + trigger.type.index;
    try {
      await notificationService.showNow(
        id: id,
        title: trigger.title,
        body: trigger.body,
      );
      developer.log('✅ 关怀触发: ${trigger.type.name}', name: 'CareEngine');
    } catch (e) {
      developer.log('❌ 关怀触发失败: $e', name: 'CareEngine');
    }
  }

  // ===== 私有规则判断 =====

  /// 最近 3 天都在 22 点后打卡
  static bool _isLateCheckInHabit(
    List<CheckInEntity> sortedDesc,
    DateTime now,
  ) {
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
  static bool _isWeekendMissed(List<CheckInEntity> sortedDesc, DateTime now) {
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
      // 检查这一天有没有打过卡
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
  /// P3 fix: 之前循环 `for (final c in sortedDesc)` 遍历**全部历史**,
  /// 1 年前有 1 次晚打卡就永远返回 false。现在限制为最近 7 天内。
  static bool _isWeekPerfect(List<CheckInEntity> sortedDesc, DateTime now) {
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
}
