/// v0.18 round 18 (P1-28) SnoozeManager 测试
///
/// 覆盖:
/// - snoozeOnce: 稳定 id 公式 (medId * 1440 + minutes)
/// - 同一 (medId, minutes) 二次调用 = 覆盖,不叠加
/// - minutes 越界 (0 / 1441) 静默 no-op
/// - cancelSnoozeForMedication: 只 cancel 该 med 范围
/// - cancelAllSnoozes: cancel 所有 snooze id 范围
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:chroniccare/core/data/services/snooze_manager.dart';

/// Test plugin 记录 cancel/show/zonedSchedule 调用
///
/// 用 implements (不是 extends),因为 FlutterLocalNotificationsPlugin
/// 无无参 constructor,extends 会编译失败。我们只实现 SnoozeManager
/// 用到的 3 个 method,其它 throw UnsupportedError。
class _FakePlugin implements FlutterLocalNotificationsPlugin {
  final List<int> cancelledIds = [];
  final List<dynamic> zonedSchedules = [];
  final List<PendingNotificationRequest> pending = [];

  @override
  Future<void> cancel(int id, {String? tag}) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelledIds.add(-1); // marker
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return pending;
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
    zonedSchedules.add({
      'id': id,
      'title': title,
      'body': body,
      'fireAt': scheduledDate,
      'payload': payload,
    });
  }

  // 其它 method 不实现,SnoozeManager 不会调
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Stub not implemented: ${invocation.memberName}');
}

void main() {
  setUpAll(() {
    // tz.local 必须在 SnoozeManager 用之前初始化
    // production 在 NotificationService.init() 里 init
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.UTC); // 测试用 UTC
  });

  group('SnoozeManager.snoozeOnce', () {
    test('同 (medId, minutes) 二次调用 = 覆盖,id 公式稳定', () async {
      final fake = _FakePlugin();
      final manager = SnoozeManager(plugin: fake);

      await manager.snoozeOnce(medicationId: 5, minutes: 5);
      await manager.snoozeOnce(medicationId: 5, minutes: 5); // 覆盖

      // 两次调用 = 2 次 cancel (前一个 cancel 自身) + 2 次 zonedSchedule
      // 但 cancel 是在 zonedSchedule 之前的:第一次 cancel + schedule,第二次 cancel + schedule
      expect(fake.cancelledIds, [5 * 1440 + 5 + 300000, 5 * 1440 + 5 + 300000]);
      expect(fake.zonedSchedules.length, 2);
      expect(fake.zonedSchedules[0]['id'], 300000 + 5 * 1440 + 5);
    });

    test('不同 (medId, minutes) id 互不干扰', () async {
      final fake = _FakePlugin();
      final manager = SnoozeManager(plugin: fake);

      await manager.snoozeOnce(medicationId: 1, minutes: 5);
      await manager.snoozeOnce(medicationId: 1, minutes: 10);
      await manager.snoozeOnce(medicationId: 2, minutes: 5);

      // 3 个不同 id
      expect(fake.zonedSchedules.length, 3);
      expect(fake.zonedSchedules[0]['id'], 300000 + 1 * 1440 + 5);
      expect(fake.zonedSchedules[1]['id'], 300000 + 1 * 1440 + 10);
      expect(fake.zonedSchedules[2]['id'], 300000 + 2 * 1440 + 5);
    });

    test('medicationId=0 通用 snooze payload = today check-in', () async {
      final fake = _FakePlugin();
      final manager = SnoozeManager(plugin: fake);

      await manager.snoozeOnce(medicationId: 0, minutes: 5);

      expect(fake.zonedSchedules[0]['payload'], 'chroniccare://check-in/today');
    });

    test('medicationId=具体值 payload = medicationCheckIn', () async {
      final fake = _FakePlugin();
      final manager = SnoozeManager(plugin: fake);

      await manager.snoozeOnce(medicationId: 42, minutes: 5);

      // 真实 NotificationDeepLink 序列化内容,这里只验不空
      expect(fake.zonedSchedules[0]['payload'], isNotNull);
      expect(fake.zonedSchedules[0]['payload'], contains('medication'));
    });

    test('minutes=0 越界 → 静默 no-op', () async {
      final fake = _FakePlugin();
      final manager = SnoozeManager(plugin: fake);

      await manager.snoozeOnce(medicationId: 1, minutes: 0);

      expect(fake.zonedSchedules, isEmpty);
      expect(fake.cancelledIds, isEmpty);
    });

    test('minutes=1441 越界 → 静默 no-op', () async {
      final fake = _FakePlugin();
      final manager = SnoozeManager(plugin: fake);

      await manager.snoozeOnce(medicationId: 1, minutes: 1441);

      expect(fake.zonedSchedules, isEmpty);
    });

    test('自定义 title/body 透传', () async {
      final fake = _FakePlugin();
      final manager = SnoozeManager(plugin: fake);

      await manager.snoozeOnce(
        medicationId: 1,
        minutes: 5,
        title: '⏰ 自定义',
        body: '你点了 snooze',
      );

      expect(fake.zonedSchedules[0]['title'], '⏰ 自定义');
      expect(fake.zonedSchedules[0]['body'], '你点了 snooze');
    });

    test('默认 title/body', () async {
      final fake = _FakePlugin();
      final manager = SnoozeManager(plugin: fake);

      await manager.snoozeOnce(medicationId: 1, minutes: 5);

      expect(fake.zonedSchedules[0]['title'], '💊 提醒吃药（snooze）');
      expect(fake.zonedSchedules[0]['body'], contains('稍后提醒'));
    });
  });

  group('SnoozeManager.cancelSnoozeForMedication', () {
    test('只 cancel 该 med 范围的 id', () async {
      final fake = _FakePlugin();
      // 设 pending: med=1 有 snooze 5min/10min,med=2 有 snooze 5min
      fake.pending.addAll([
        const PendingNotificationRequest(300000 + 1 * 1440 + 5, 'a', 'b', null),
        const PendingNotificationRequest(
            300000 + 1 * 1440 + 10, 'c', 'd', null),
        const PendingNotificationRequest(300000 + 2 * 1440 + 5, 'e', 'f', null),
      ]);
      final manager = SnoozeManager(plugin: fake);

      await manager.cancelSnoozeForMedication(1);

      // med=1 的 2 个 snooze 被 cancel,med=2 不动
      expect(
          fake.cancelledIds, [300000 + 1 * 1440 + 5, 300000 + 1 * 1440 + 10]);
    });

    test('pending 没该 med 的 snooze → 静默 no-op', () async {
      final fake = _FakePlugin();
      fake.pending.addAll([
        const PendingNotificationRequest(300000 + 2 * 1440 + 5, 'e', 'f', null),
      ]);
      final manager = SnoozeManager(plugin: fake);

      await manager.cancelSnoozeForMedication(1);

      expect(fake.cancelledIds, isEmpty);
    });
  });

  group('SnoozeManager.cancelAllSnoozes', () {
    test('cancel snooze 范围所有 pending', () async {
      final fake = _FakePlugin();
      fake.pending.addAll([
        const PendingNotificationRequest(300000 + 1 * 1440 + 5, 'a', 'b', null),
        const PendingNotificationRequest(
            300000 + 5 * 1440 + 30, 'c', 'd', null),
        // 非 snooze id (1001 是 daily,3000 是 soft)
        const PendingNotificationRequest(1001, 'e', 'f', null),
        const PendingNotificationRequest(3000, 'g', 'h', null),
      ]);
      final manager = SnoozeManager(plugin: fake);

      await manager.cancelAllSnoozes();

      // 2 个 snooze id 被 cancel,2 个非 snooze 不动
      expect(
        fake.cancelledIds,
        [300000 + 1 * 1440 + 5, 300000 + 5 * 1440 + 30],
      );
    });

    test('pending 空 → 静默 no-op', () async {
      final fake = _FakePlugin();
      final manager = SnoozeManager(plugin: fake);

      await manager.cancelAllSnoozes();

      expect(fake.cancelledIds, isEmpty);
    });
  });
}
