// v0.24 round 45 (Sprint #5b) — MedicationNotifier 抽类
//
// 从 NotificationService (629 行) 拆出 medication 编排:
//   - 每天 hour:minute 通用打卡提醒 (id=1001, daily check-in fallback)
//   - 每个 medication 每个 time 的 zonedSchedule 推送 (id=2000+medId*10+i)
//
// 设计原则 (跟 mood_dialog 拆解同模式):
//   - 单一职责: 只管 medication 类通知的 schedule / cancel / reschedule
//   - 委托 ReminderDispatcher 处理 cancelByIdRange + zonedDaily
//   - 公开 2 个 method + 2 个 const ID
//   - 保留所有 P0/P1 修复:
//     * 200000 cancel range (v0.16 round 19/19B) — 走 dispatcher
//     * ID 公式 (base + medId * 10 + i) 稳定 (同一药同一时间点复用 id)
//     * 取消旧通知覆盖前一次 (避免叠加)
//
// 频度 (emil 决策):
//   - daily check-in: daily 频度 (无药时 fallback)
//   - medication reminder: per-medication-per-time 频度, 启动时 + medications 表变化时
//
// v0.22 round 37 抽 SnoozeManager / BadgeSyncService / ReminderDispatcher 后的
// 第 4-6 个子 facade。facade 缩到 ~250 行 init + 委托。

import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/l10n/strings.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chroniccare/core/data/services/notification_payload.dart';
import 'package:chroniccare/core/data/services/reminder_dispatcher.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';

/// 药物通知编排 (daily check-in + per-medication reminders)
///
/// 公开 2 个 method:
///   - [scheduleDailyReminder] 每天 hour:minute 通用打卡 (id=1001, fallback)
///   - [rescheduleMedicationReminders] 重排所有 medication 推送 (id=2000+medId*10+i)
///
/// v0.24 round 45: 委托 ReminderDispatcher 处理 cancel/zonedSchedule;
/// 公开 2 个 ID 常量便于测试 + 文档化。
class MedicationNotifier {
  /// 每日打卡 fallback id (无 medication 时用, 不跟 medication id 公式冲突)
  static const int defaultReminderId = 1001;

  /// medication.time 推送的 id 起始基数（避免冲突）
  ///
  /// id 公式：`base + medId * 10 + i`
  /// - 同一药的同一时间点 id 稳定（重排 = 覆盖，不叠加）
  /// - range [2000, 202000) 覆盖 medId 几万个（v0.16 round 19/19B 验证过）
  static const int medicationReminderBaseId = 2000;

  final FlutterLocalNotificationsPlugin _plugin;
  final ReminderDispatcher _dispatcher;

  /// facade 的 init() 包装, 保证 sub-service 调用时主 service 已 init
  final Future<void> Function() _ensureInitialized;

  MedicationNotifier({
    required FlutterLocalNotificationsPlugin plugin,
    required ReminderDispatcher dispatcher,
    required Future<void> Function() ensureInitialized,
  })  : _plugin = plugin,
        _dispatcher = dispatcher,
        _ensureInitialized = ensureInitialized;

  /// 设置每天 hour:minute 通用打卡提醒 (id=1001)
  ///
  /// v0.7 升级保留的"无药时 fallback"提醒。
  /// - 每次调用前 cancel 旧的（覆盖）
  /// - web 平台 `zonedSchedule` 会抛 `UnsupportedError`, 这里吞掉
  Future<void> scheduleDailyReminder({
    int hour = 20,
    int minute = 0,
  }) async {
    await _ensureInitialized();
    await _plugin.cancel(defaultReminderId);

    final details = _dispatcher.buildChannelDetails();

    try {
      // v0.11: payload = "chroniccare://check-in/today"
      const payload = 'chroniccare://check-in/today';
      await _dispatcher.zonedDaily(
        id: defaultReminderId,
        title: Strings.notifDailyCheckInTitle,
        body: Strings.notifDailyCheckInBody,
        hour: hour,
        minute: minute,
        details: details,
        payload: payload,
      );
      piiSafeLog('MedicationNotifier', '✅ 设置每日 $hour:$minute 提醒');
    } catch (e) {
      piiSafeLog('MedicationNotifier', '❌ 设置提醒失败: $e');
    }
  }

  /// 重排所有 medication 的推送
  ///
  /// 每次 medications 表变化（增/删/改）时调用。
  /// 用稳定 hash 生成 notification id（避免冲突 + 同一药同一时间复用 id）。
  ///
  /// v0.18 (P2-P0-2): 改接受 [MedicationEntity] (domain) 而非 [Medication] (Drift row),
  /// 避免 presentation 层 import data mapper (4 层架构违规)。
  ///
  /// cancel 范围走 dispatcher 集中, base 200000 覆盖 medId 几万个
  /// (v0.16 round 19 修, v0.23 round 37 抽 dispatcher)。
  Future<void> rescheduleMedicationReminders(
    List<MedicationEntity> medications,
  ) async {
    await _ensureInitialized();
    await _dispatcher.cancelByIdRange(medicationReminderBaseId);

    piiSafeLog(
      'MedicationNotifier',
      '✅ medication reminders 全部 cancel + 重新调度',
    );

    final details = _dispatcher.buildChannelDetails();

    int scheduled = 0;
    for (final med in medications) {
      if (!med.isActive) continue;
      for (int i = 0; i < med.times.length; i++) {
        final t = med.times[i];
        final id = medicationReminderBaseId + (med.id * 10) + i;
        try {
          // v0.11: payload 携带 medId, 点通知直达该药打卡
          final payload =
              NotificationDeepLink.medicationCheckIn(med.id).encode();
          await _dispatcher.zonedDaily(
            id: id,
            title: Strings.notifMedicationTitle(med.name),
            body: Strings.notifMedicationBody(med.dosage, med.dosageUnit),
            hour: t.hour,
            minute: t.minute,
            details: details,
            payload: payload,
          );
          scheduled++;
        } catch (e) {
          piiSafeLog(
            'MedicationNotifier',
            '❌ 推送调度失败 med=${med.name} t=$t: $e',
          );
        }
      }
    }
    piiSafeLog(
      'MedicationNotifier',
      '✅ 重新调度 $scheduled 个 medication 推送',
    );
  }
}
