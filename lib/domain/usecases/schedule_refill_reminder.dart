// v0.27 round 65 (spen 1.2.2 + alibaba 1.2 use case 层补):
// 抽 ScheduleRefillReminderUseCase (RefillNotifier 重排纯函数化)
//
// 之前 RefillNotifier.rescheduleRefillReminders 在 lib/core/data/services/
// refill_notifier.dart:191-208 混合 3 件事:
//   - cancel all (dispatcher.cancelByIdRange)
//   - for each med: scheduleRefillReminder (有副作用: plugin + dispatcher)
//   - 计数 + log
//
// "算每个 med 的 fireAt" 是纯计算, 跟 plugin / dispatcher / log 没关系。
// 本 use case 把"算 List<RefillSchedule>" 抽出来, 0 副作用, 0 service 调,
// 让 presentation / test 单独验证时间计算。
//
// 0 副作用: 不调 Plugin / Dispatcher / Notifier, 只算 fireAt + isExpired。
// 0 Flutter 依赖: 只用 MedicationEntity (domain) + RefillScheduler (domain/logic)。
//
// v0.27 round 82 (P0 架构修复): import 从 `refill_notifier.dart` (data 层,
// 间接依赖 flutter plugin) 切到 `refill_scheduler.dart` (domain/logic 纯函数,
// 0 flutter 依赖)。domain use case 现在 0 flutter 间接 import, 4 层架构
// check_all.dart 守门通过。

import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/logic/refill_scheduler.dart';

/// 单个 medication 的续方排程
///
/// v0.27 round 65: 跟 RefillScheduler.computeRefillFireTime 配套, 多带
/// isExpired 标志让 caller 跳过过期。
class RefillSchedule {
  /// 关联 medication id
  final int medicationId;

  /// 续方提醒 fire time (refillAt - reminderDays 当天 9 点)
  ///
  /// null = medication 没设 refillAt (无续方), caller 跳过
  final DateTime? fireAt;

  /// fire time 是否已过 (fireAt < now)
  ///
  /// 已过的不要 schedule (避免给历史数据"补响"), caller 走 cancel 路径
  final bool isExpired;

  const RefillSchedule({
    required this.medicationId,
    required this.fireAt,
    required this.isExpired,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RefillSchedule &&
          other.medicationId == medicationId &&
          other.fireAt == fireAt &&
          other.isExpired == isExpired;

  @override
  int get hashCode => Object.hash(medicationId, fireAt, isExpired);

  @override
  String toString() =>
      'RefillSchedule(medId=$medicationId, fireAt=$fireAt, isExpired=$isExpired)';
}

/// 抽 ScheduleRefillReminder 业务编排
///
/// v0.27 round 65: 给 medications 列表 + now, 计算每个 med 的续方 fire time
/// (纯函数), caller 拿 `List<RefillSchedule>` 自行 cancel + zonedSchedule。
///
/// 业务规则:
/// - inactive 药物跳过 (跟 RefillNotifier.rescheduleRefillReminders 1:1)
/// - 无 refillAt 跳过 (fireAt = null)
/// - reminderDays < 1 抛 ArgumentError (跟 RefillScheduler.computeRefillFireTime 1:1)
/// - fireAt < now 标 isExpired = true
///
/// 0 副作用: 不调 Plugin / Dispatcher / Notifier, 不写 DB, 不发通知。
/// 复用 [RefillScheduler.computeRefillFireTime] (R82 抽离, R56c 8 case 行为不变) —
/// 覆盖 reminderDays < 1 / refillAt == null / 跨月 / 跨年 等边界。
class ScheduleRefillReminderUseCase {
  const ScheduleRefillReminderUseCase();

  List<RefillSchedule> call({
    required List<MedicationEntity> medications,
    required DateTime now,
  }) {
    final schedules = <RefillSchedule>[];
    for (final m in medications) {
      if (!m.isActive) continue;
      final fireAt = RefillScheduler.computeRefillFireTime(
        refillAt: m.refillAt,
        reminderDays: m.refillReminderDays,
      );
      schedules.add(
        RefillSchedule(
          medicationId: m.id,
          fireAt: fireAt,
          isExpired: fireAt != null && fireAt.isBefore(now),
        ),
      );
    }
    return schedules;
  }
}
