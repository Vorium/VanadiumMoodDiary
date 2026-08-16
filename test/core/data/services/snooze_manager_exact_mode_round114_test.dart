// R114 B1-2: snooze 硬编码 exactAllowWhileIdle 绕过降级策略 — 回归测试
// (2026-08-16 标准审计 · 10-bottom-core-data 发现 4)
//
// 修前: snoozeOnce 硬编码 AndroidScheduleMode.exactAllowWhileIdle, 绕过
// ReminderDispatcher.setExactMode() 降级 (Android 13+ 用户撤回
// SCHEDULE_EXACT_ALARM 后主提醒走 inexact 兜底, snooze 却静默丢失/延迟)。
// 修后: SnoozeManager 注入 scheduleModeProvider (生产接 dispatcher.scheduleMode
// getter), snooze 与主提醒同进退。
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:chroniccare/core/data/services/reminder_dispatcher.dart';
import 'package:chroniccare/core/data/services/snooze_manager.dart';

/// 记录 androidScheduleMode 的 fake plugin
class _FakePlugin implements FlutterLocalNotificationsPlugin {
  AndroidScheduleMode? lastMode;
  final List<int> cancelledIds = [];

  @override
  Future<void> cancel(int id, {String? tag}) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAll() async {}

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return const [];
  }

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    DateTime? scheduledDate,
    NotificationDetails notificationDetails, {
    required UILocalNotificationDateInterpretation
        uiLocalNotificationDateInterpretation,
    @Deprecated('Deprecated in favor of the androidScheduleMode parameter')
    bool androidAllowWhileIdle = false,
    AndroidScheduleMode? androidScheduleMode,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    lastMode = androidScheduleMode;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Stub not implemented: ${invocation.memberName}');
}

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);
  });

  test('默认 (无 provider) → exactAllowWhileIdle (向后兼容)', () async {
    final fake = _FakePlugin();
    final manager = SnoozeManager(plugin: fake);

    await manager.snoozeOnce(medicationId: 1, minutes: 5);

    expect(fake.lastMode, AndroidScheduleMode.exactAllowWhileIdle);
  });

  test('注入 provider 返回 inexact → snooze 走 inexactAllowWhileIdle', () async {
    final fake = _FakePlugin();
    final manager = SnoozeManager(
      plugin: fake,
      scheduleModeProvider: () => AndroidScheduleMode.inexactAllowWhileIdle,
    );

    await manager.snoozeOnce(medicationId: 1, minutes: 5);

    expect(fake.lastMode, AndroidScheduleMode.inexactAllowWhileIdle);
  });

  test('接 dispatcher.scheduleMode: setExactMode(false) → snooze 跟随降级',
      () async {
    final fake = _FakePlugin();
    final dispatcher = ReminderDispatcher(
      plugin: fake,
      channelId: 'test',
      channelName: 'test',
      channelDescription: 'test',
    );
    dispatcher.setExactMode(false);
    final manager = SnoozeManager(
      plugin: fake,
      scheduleModeProvider: () => dispatcher.scheduleMode,
    );

    await manager.snoozeOnce(medicationId: 1, minutes: 5);
    expect(fake.lastMode, AndroidScheduleMode.inexactAllowWhileIdle);

    // 权限恢复 → snooze 也恢复 exact
    dispatcher.setExactMode(true);
    await manager.snoozeOnce(medicationId: 1, minutes: 10);
    expect(fake.lastMode, AndroidScheduleMode.exactAllowWhileIdle);
  });

  test('ReminderDispatcher.scheduleMode getter: 默认 exact', () {
    final dispatcher = ReminderDispatcher(
      plugin: _FakePlugin(),
      channelId: 'test',
      channelName: 'test',
      channelDescription: 'test',
    );
    expect(dispatcher.scheduleMode, AndroidScheduleMode.exactAllowWhileIdle);
  });
}
