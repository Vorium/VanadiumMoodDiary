// v0.18 round 18 (P1-28) SnoozeManager — 从 NotificationService 拆出
//
// 设计：facade pattern，NotificationService 公共 API 保持原签名,
// 内部委托给 SnoozeManager。这样:
// - NotificationService 主类减肥 90+ 行
// - Snooze 逻辑独立测试 (不用 mock 整个 notification service)
// - id 公式 + cancel 范围集中在一处
//
// 参考 Pill Reminder (Drugs.com iOS)：
// - 通知来了用户点"Snooze 5min" → 5min 后再响一次
// - 同一 (medId, minutes) 二次触发 = 覆盖原 snooze，不会叠加
// - 打卡后 cancel 该 med 的所有 snooze

import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:chroniccare/core/data/services/notification_payload.dart';

/// Snooze 管理器
///
/// 依赖注入的 plugin（在 NotificationService init 之后才能用），
/// 所以通过 [init] 注入。
class SnoozeManager {
  final FlutterLocalNotificationsPlugin _plugin;

  /// snooze id 起始基数（4000-4999 留给 snooze）
  final int snoozeBaseId;

  /// 每次 1 个 med 最多 1440 个不同 minutes
  final int minutesPerMedication;

  /// 跨 meds 的 cancel 范围（snoozeBaseId + 2000000 足够 medId 几万个）
  final int cancelRange;

  SnoozeManager({
    required FlutterLocalNotificationsPlugin plugin,
    this.snoozeBaseId = 4000,
    this.minutesPerMedication = 1440,
    this.cancelRange = 2000000,
  }) : _plugin = plugin;

  /// 调度一个**一次性**延迟通知（snooze 用）
  ///
  /// 设计：用稳定 hash 把 (medId, minutes) → unique id，
  /// 避免用户连续点 snooze 堆出 10 个通知。
  /// - [minutes] 范围 [1, 1440]（最多 24h 后）
  /// - 同一 (medId, minutes) 二次触发 = 覆盖原 snooze，不会叠加
  ///
  /// v0.11 (Round 5): payload 携带 medId,snooze 触发后点通知直达该药
  Future<void> snoozeOnce({
    required int medicationId,
    required int minutes,
    String? title,
    String? body,
  }) async {
    if (minutes <= 0 || minutes > minutesPerMedication) {
      developer.log(
        '⚠️ snoozeOnce: minutes=$minutes 越界（1..$minutesPerMedication）',
        name: 'SnoozeManager',
      );
      return;
    }

    // 稳定 id：snoozeBase + medId * 1440 + minutes
    // 1440 保证同一 med 不同 minutes 之间不冲突
    final id = snoozeBaseId + (medicationId * minutesPerMedication) + minutes;

    // 取消同 id 的旧 snooze（避免叠加）
    await _plugin.cancel(id);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'chroniccare.medication',
        '吃药提醒',
        channelDescription: '到点提醒你吃药打卡',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final fireAt = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
    final payload = medicationId == 0
        ? 'chroniccare://check-in/today'
        : NotificationDeepLink.medicationCheckIn(medicationId).encode();
    try {
      await _plugin.zonedSchedule(
        id,
        title ?? '💊 提醒吃药（snooze）',
        body ?? '刚才你点了"稍后提醒"，该吃药了',
        fireAt,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // 不加 matchDateTimeComponents：只触发一次
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      developer.log(
        '✅ snooze ${minutes}min 后触发（med=$medicationId）',
        name: 'SnoozeManager',
      );
    } catch (e) {
      developer.log('❌ snooze 调度失败: $e', name: 'SnoozeManager');
    }
  }

  /// 取消某个药物的所有 snooze（用户真打卡后调）
  Future<void> cancelSnoozeForMedication(int medicationId) async {
    final pending = await _plugin.pendingNotificationRequests();
    final baseMin = snoozeBaseId + medicationId * minutesPerMedication;
    final baseMax = baseMin + minutesPerMedication;
    for (final p in pending) {
      if (p.id >= baseMin && p.id <= baseMax) {
        await _plugin.cancel(p.id);
      }
    }
  }

  /// 取消所有 snooze（重排 medication reminders 时调）
  ///
  /// snooze id 公式：snoozeBase + medId * 1440 + minutes
  ///   medId 上限：int32 安全 ~1.5M (medId <= 1000)，按当前用户量足够
  /// v0.16 round 19 fix: 之前用 `snoozeBaseId + 100000` 范围太窄，medId >= 72 时
  ///   id 超过 104000 漏 cancel（虽然 snooze 5min 自动清除，但重排时残留）
  Future<void> cancelAllSnoozes() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= snoozeBaseId && p.id < snoozeBaseId + cancelRange) {
        await _plugin.cancel(p.id);
      }
    }
  }
}
