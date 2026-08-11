// v0.31.1 R109 (god class 专项 round 1):
// 抽 ScheduleAssessmentReminderUseCase (use case 厚化模板 round 1)
//
// 改前: `AssessmentReminderService.onAppStart / onAssessmentCompleted`
//   直接调 `NotificationService.delegate.scheduleAssessmentReminder(...)`,
//   业务编排 (算 fire time + 决定发还是取消) 跟 IO (调 plugin) 混在 service.
// 改后: use case 拿 `AssessmentReminderSender` abstract (domain), 编排
//   "enabled 切换 + 算 fire time + 调 sender" 3 件事, 0 副作用 0 Flutter
//   0 service import. 跟 `ScheduleRefillReminderUseCase` / `CheckSafetyUseCase`
//   同款 (R27 抽的, 模式一致).
//
// 4 层架构: domain/usecases/ 放 0 Flutter / 0 Drift / 0 data import 的
//   纯编排, AGENTS.md 必读.

import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:chroniccare/domain/logic/assessment_reminder_policy.dart';
import 'package:chroniccare/domain/repositories/assessment_reminder_sender.dart';

/// 心理评估提醒排程 use case
///
/// R109 (god class 拆): use case 层厚化模板 round 1.
///
/// 输入: enabled / days / lastAssessmentAt
/// 编排:
///   - enabled=false → 调 [AssessmentReminderSender.cancel]
///   - enabled=true → 调 policy 算 fire time → 调 sender.schedule
///
/// 0 副作用: 不调 service, 不写 DB, 不读 prefs (prefs 由 service 处理)
/// 0 Flutter / 0 Drift: 只依赖 domain abstract + policy
class ScheduleAssessmentReminderUseCase {
  final AssessmentReminderSender _sender;

  const ScheduleAssessmentReminderUseCase(this._sender);

  /// 算下次 fire time (透传 policy, 给 caller 显式调)
  ///
  /// [now] 注入方便 widget / unit test, 默认 [DateTime.now]
  @visibleForTesting
  static DateTime? resolveFireTime({
    required bool enabled,
    required int days,
    required DateTime? lastAssessmentAt,
    DateTime? now,
  }) =>
      AssessmentReminderPolicy.computeNextFireTime(
        enabled: enabled,
        days: days,
        lastAssessmentAt: lastAssessmentAt,
        now: now,
      );

  /// 重排评估提醒 (编排主入口)
  ///
  /// 流程:
  ///   1. enabled=false → sender.cancel() 返
  ///   2. enabled=true → resolveFireTime 拿 fire time
  ///      - fire time null → 返 (政策不允许, 例如 days 非法)
  ///      - fire time 非 null → sender.schedule(fire time, scaleId, days)
  ///
  /// [scaleId] 默认 'phq9' (跟旧 service 行为一致, 未来 PHQ-9 / GAD-7
  ///   多档时 caller 显式传).
  Future<void> reschedule({
    required bool enabled,
    required int days,
    required DateTime? lastAssessmentAt,
    String scaleId = AssessmentReminderPolicy.defaultScaleId,
    DateTime? now,
  }) async {
    if (!enabled) {
      await _sender.cancel();
      return;
    }
    final fireAt = AssessmentReminderPolicy.computeNextFireTime(
      enabled: enabled,
      days: days,
      lastAssessmentAt: lastAssessmentAt,
      now: now,
    );
    if (fireAt == null) return;
    await _sender.schedule(fireAt: fireAt, scaleId: scaleId, days: days);
  }
}
