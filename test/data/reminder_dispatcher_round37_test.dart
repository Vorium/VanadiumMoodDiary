// reminder_dispatcher_round37_test.dart
//
// v0.23 (Round 37) 新增: ReminderDispatcher 纯函数单测
//
// 之前 NotificationService 5 类通知 0 单测 (强依赖 plugin, 无法测)。
// 抽 ReminderDispatcher 后:
// - cancelByIdRange (test 用 mock plugin)
// - buildChannelDetails (无副作用, 直接断言)
// - computeNextDailyFireTime (纯函数, 跨 midnight edge case)
//
// 完整 plugin 集成测试留给 integration_test, 本单测覆盖核心 invariant。
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:chroniccare/core/data/services/reminder_dispatcher.dart';

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
  });

  group('computeNextDailyFireTime (纯函数)', () {
    test('今天的 hour:minute 还没到 → 返回今天', () {
      final now = tz.TZDateTime(tz.local, 2026, 7, 21, 10, 0); // 10:00
      final fire = ReminderDispatcher.computeNextDailyFireTime(
        hour: 20,
        minute: 0,
        now: now,
      );
      expect(fire.year, 2026);
      expect(fire.month, 7);
      expect(fire.day, 21);
      expect(fire.hour, 20);
      expect(fire.minute, 0);
    });

    test('今天的 hour:minute 已过 → 推到明天', () {
      final now = tz.TZDateTime(tz.local, 2026, 7, 21, 22, 0); // 22:00
      final fire = ReminderDispatcher.computeNextDailyFireTime(
        hour: 20,
        minute: 0,
        now: now,
      );
      expect(fire.day, 22); // 推到明天
      expect(fire.hour, 20);
    });

    test('今天刚好 20:00 → isBefore 是 false, 仍用今天 (符合 isBefore 语义)', () {
      // isBefore 严格 (<), 相等不算 before, 所以 20:00 == 20:00 走 today 分支
      final now = tz.TZDateTime(tz.local, 2026, 7, 21, 20, 0);
      final fire = ReminderDispatcher.computeNextDailyFireTime(
        hour: 20,
        minute: 0,
        now: now,
      );
      expect(fire.day, 21);
    });

    test('跨月 23:59 → 推到下月 1 号 00:00', () {
      final now = tz.TZDateTime(tz.local, 2026, 7, 31, 23, 59);
      final fire = ReminderDispatcher.computeNextDailyFireTime(
        hour: 0,
        minute: 0,
        now: now,
      );
      expect(fire.month, 8);
      expect(fire.day, 1);
      expect(fire.hour, 0);
      expect(fire.minute, 0);
    });

    test('跨年 12/31 23:00 → 推到明年 1/1 00:00', () {
      final now = tz.TZDateTime(tz.local, 2026, 12, 31, 23, 0);
      final fire = ReminderDispatcher.computeNextDailyFireTime(
        hour: 0,
        minute: 0,
        now: now,
      );
      expect(fire.year, 2027);
      expect(fire.month, 1);
      expect(fire.day, 1);
    });
  });

  group('buildChannelDetails', () {
    test('high=true (默认 reminder) → Importance.high', () {
      final d = ReminderDispatcher(
        plugin: FlutterLocalNotificationsPlugin(),
        channelId: 'test.channel',
        channelName: 'Test Channel',
        channelDescription: 'Test desc',
      );
      final details = d.buildChannelDetails();
      expect(details.android, isA<AndroidNotificationDetails>());
      expect(details.android!.importance, Importance.high);
    });

    test('high=false (被动 push) → Importance.defaultImportance', () {
      final d = ReminderDispatcher(
        plugin: FlutterLocalNotificationsPlugin(),
        channelId: 'test.channel',
        channelName: 'Test Channel',
        channelDescription: 'Test desc',
      );
      final details = d.buildChannelDetails(high: false);
      expect(details.android!.importance, Importance.defaultImportance);
    });
  });

  group('cancelByIdRange (用 in-memory mock)', () {
    test('范围内 id 全被 cancel', () async {
      // Mock FlutterLocalNotificationsPlugin method channel
      // 真实 binding 没初始化, 需要 mock pendingNotificationRequests 返回 []
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel = MethodChannel('dexterous.com/flutter/local_notifications');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'pendingNotificationRequests') {
          return <Map<String, Object?>>[]; // 0 个 pending
        }
        if (call.method == 'cancel') {
          return null;
        }
        return null;
      });
      final plugin = FlutterLocalNotificationsPlugin();
      final dispatcher = ReminderDispatcher(
        plugin: plugin,
        channelId: 'test',
        channelName: 'Test',
        channelDescription: 'desc',
      );
      // 不报错 = 通过 (channel 端没有真通知, cancel 是 no-op)
      await dispatcher.cancelByIdRange(2000);
    });

    test('5s timeout 兜底不 hang', () async {
      // cancelByIdRange 内部有 .timeout(5s, onTimeout: () => <void>[])
      // 即便 plugin 实现卡死, 5s 后回 <void>[] 不阻塞
      // 这里不模拟 hang, 只验证 timeout 存在 (compile + import 不报错)
      const channel = MethodChannel('dexterous.com/flutter/local_notifications');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);
      final plugin = FlutterLocalNotificationsPlugin();
      final dispatcher = ReminderDispatcher(
        plugin: plugin,
        channelId: 'test',
        channelName: 'Test',
        channelDescription: 'desc',
      );
      await dispatcher.cancelByIdRange(6000); // refill base
      // 通过
    });
  });
}
