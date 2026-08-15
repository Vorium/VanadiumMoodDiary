// v0.30 R108 (P1 god class 拆 6 大 F - Fix #2): notification_service facade
// 13 委派合 namespace
//
// **背景 (R107 §3.5)**: NotificationService 426L facade 含 18 public method,
// 其中 12 个是 1-2 行委派 (调用 sub-service 转发), 占 60+ 行 facade 模板残留:
//
// | 委派 method | sub-service |
// |---|---|
// | scheduleDailyReminder | MedicationNotifier |
// | rescheduleMedicationReminders | MedicationNotifier |
// | scheduleMoodReminder | MoodReminderNotifier |
// | scheduleRefillReminder | RefillNotifier |
// | cancelRefillReminder | RefillNotifier |
// | rescheduleRefillReminders | RefillNotifier |
// | scheduleAssessmentReminder | AssessmentNotifier |
// | cancelAssessmentReminder | AssessmentNotifier |
// | snoozeOnce | SnoozeManager |
// | cancelSnoozeForMedication | SnoozeManager |
// | cancelAllSnoozes | SnoozeManager |
// | updateBadgeCount | BadgeSyncService |
//
// **修复**: 抽 NotificationDelegate, 12 委派 method 集中, facade 暴露
// `service.delegate.xxx(...)` 路径。
// - caller: `notif.scheduleDailyReminder(...)` → `notif.delegate.scheduleDailyReminder(...)`
// - facade 自身瘦 60+ 行, 主体保留 5 method:
//   init / requestPermission / showNow / cancelAll / pendingCount
//   + rescheduleAll (orchestrator) + _canScheduleExact (P0#2)
//   (1.1.0 round 4b: showSafetyAlert 随外联服务整摘)
//
// **保留 facade 公开 API**:
// - `NotificationService.onNotificationTap` (v0.11 Round 5, 用户点通知回调)
// - `NotificationService.showNow` (主动 push, NotificationSender 接口)
// - `NotificationService.rescheduleAll` (orchestrator, 调 _canScheduleExact +
//   3 sub-delegate)
// - `NotificationService.cancelAll` / `pendingCount` (pass-through 到 _plugin)
// - `NotificationService.init` / `requestPermission` (R97-P1-6 拆分权限请求)
//
// **R108 P0#2 修复保留**: `_canScheduleExact` 仍在 NotificationService,
// rescheduleAll 仍负责 dispatcher.useExactAllowWhileIdle 同步。
//
// **频度 (emil 决策)**:
// - daily check-in / medication: 启动 + medications 变化时 (低频)
// - snoozeOnce: 1-2 次/打卡 (中频)
// - cancelSnooze: 打卡后 (1 次/打卡, 中频)
// - updateBadge: 状态变化时 (低频)
// - rescheduleAll: 启动 + BootReceiver (极低频)

import 'package:chroniccare/core/data/services/assessment_notifier.dart';
import 'package:chroniccare/core/data/services/badge_sync_service.dart';
import 'package:chroniccare/core/data/services/medication_notifier.dart';
import 'package:chroniccare/core/data/services/mood_reminder_notifier.dart';
import 'package:chroniccare/core/data/services/refill_notifier.dart';
import 'package:chroniccare/core/data/services/snooze_manager.dart';

import 'package:chroniccare/domain/entities/medication_entity.dart';

/// v0.30 R108 (P1 god class 拆 6 大 F - Fix #2): notification_service 12 委派
/// namespace
///
/// 集中 facade 的 1-2 行委派 method, 消除 60+ 行 facade 模板残留。
///
/// **caller 调用方式**:
/// ```dart
/// // 修前 (R107 baseline):
/// await ref.read(notificationServiceProvider).scheduleDailyReminder(hour: 20);
/// await ref.read(notificationServiceProvider).snoozeOnce(medicationId: 1, minutes: 5);
///
/// // 修后 (R108 Fix #2):
/// await ref.read(notificationServiceProvider).delegate.scheduleDailyReminder(hour: 20);
/// await ref.read(notificationServiceProvider).delegate.snoozeOnce(medicationId: 1, minutes: 5);
/// ```
///
/// **设计原则**:
/// 1. 12 method 顺序按原 facade 排 (medication → refill → assessment → snooze
///    → badge), 跟 AGENTS.md 决策表 1:1
/// 2. 完整保留原 method 签名 (参数 / 返回类型 / 默认值), caller 改路径即可
/// 3. 公开的 `refillNotificationId` / `computeRefillFireTime` static 不抽
///    (R65 round 9 兼容访问, 留 facade 静态 method 委托)
/// 4. `rescheduleAll` orchestrator 不在 delegate (在 facade 主体, 因为需要
///    _canScheduleExact + dispatcher 同步)
class NotificationDelegate {
  // ===== 6 sub-service DI =====

  /// 每日打卡 + medication 推送 (id=1001 / 2000+medId*10+i)
  final MedicationNotifier medicationNotifier;

  /// 情绪记录提醒 (id=5000002, R110 B1-1 固定带)
  final MoodReminderNotifier moodReminderNotifier;

  /// 续方提醒 (id=6000+medId)
  final RefillNotifier refillNotifier;

  /// 心理评估周期提醒 (id=5000001, R110 B1-1 固定带)
  final AssessmentNotifier assessmentNotifier;

  /// Snooze 延迟通知 (id=300000+)
  final SnoozeManager snoozeManager;

  /// 角标同步 (iOS badge, id=5000100, R110 B1-1 固定带)
  final BadgeSyncService badgeSync;

  const NotificationDelegate({
    required this.medicationNotifier,
    required this.moodReminderNotifier,
    required this.refillNotifier,
    required this.assessmentNotifier,
    required this.snoozeManager,
    required this.badgeSync,
  });

  // ============== MedicationNotifier 委派 ==============

  /// 设置每天 hour:minute 通用打卡提醒 (id=1001, fallback)
  ///
  /// facade 保留 [NotificationService.rescheduleAll] 调本方法
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) =>
      medicationNotifier.scheduleDailyReminder(hour: hour, minute: minute);

  /// 重排所有 medication 的推送 (id=2000+medId*10+i)
  Future<void> rescheduleMedicationReminders(
    List<MedicationEntity> medications,
  ) =>
      medicationNotifier.rescheduleMedicationReminders(medications);

  // ============== MoodReminderNotifier 委派 ==============

  /// 设置每天 hour:minute 情绪记录提醒 (id=5000002, R110 B1-1 固定带)
  Future<void> scheduleMoodReminder({
    required bool enabled,
    int hour = 20,
    int minute = 0,
  }) =>
      moodReminderNotifier.scheduleMoodReminder(
        enabled: enabled,
        hour: hour,
        minute: minute,
      );

  // ============== RefillNotifier 委派 ==============

  /// 调度一个 medication 的续方提醒
  Future<void> scheduleRefillReminder(MedicationEntity medication) =>
      refillNotifier.scheduleRefillReminder(medication);

  /// 取消一个 medication 的续方提醒
  Future<void> cancelRefillReminder(int medicationId) =>
      refillNotifier.cancelRefillReminder(medicationId);

  /// 重排所有 medication 的续方提醒
  Future<void> rescheduleRefillReminders(
    List<MedicationEntity> medications,
  ) =>
      refillNotifier.rescheduleRefillReminders(medications);

  // ============== AssessmentNotifier 委派 ==============

  /// 调度一条心理评估周期提醒
  Future<void> scheduleAssessmentReminder({
    required DateTime fireAt,
    String scaleId = 'phq9',
    int days = 14,
  }) =>
      assessmentNotifier.scheduleAssessmentReminder(
        fireAt: fireAt,
        scaleId: scaleId,
        days: days,
      );

  /// 取消心理评估周期提醒
  Future<void> cancelAssessmentReminder() =>
      assessmentNotifier.cancelAssessmentReminder();

  // ============== SnoozeManager 委派 ==============

  /// 调度一个一次性延迟通知 (snooze 用)
  Future<void> snoozeOnce({
    required int medicationId,
    required int minutes,
    String? title,
    String? body,
  }) =>
      snoozeManager.snoozeOnce(
        medicationId: medicationId,
        minutes: minutes,
        title: title,
        body: body,
      );

  /// 取消某个药物的所有 snooze (用户真打卡后调)
  Future<void> cancelSnoozeForMedication(int medicationId) =>
      snoozeManager.cancelSnoozeForMedication(medicationId);

  /// 取消所有 snooze (重排 medication reminders 时调)
  Future<void> cancelAllSnoozes() => snoozeManager.cancelAllSnoozes();

  // ============== BadgeSyncService 委派 ==============

  /// 更新角标数字 (iOS badge, count=0 清零)
  Future<void> updateBadgeCount(int count) => badgeSync.updateBadgeCount(count);
}
