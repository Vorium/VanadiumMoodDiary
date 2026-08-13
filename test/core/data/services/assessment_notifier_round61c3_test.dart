// v0.25 round 56c''' (spen P0 #15 TDD 续): AssessmentNotifier test
//
// 之前 0 test (v0.24 round 45 拆 sub-service 时只加 facade).
// R56c''' 补 1 const + 2 instance method 测, 共 4 test cases.
//
// 设计要点:
// - mock 走 ReminderDispatcher interface (跟 refill_notifier_round61c_test 同模式)
// - flutter_local_notifications platform channel 全局 mock 让 _plugin.cancel()
//   在 test 不抛 MissingPluginException
import 'package:chroniccare/core/data/services/assessment_notifier.dart';
import 'package:chroniccare/core/data/services/reminder_dispatcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pluginChannel =
      MethodChannel('dexterous.com/flutter/local_notifications');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pluginChannel, (call) async {
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pluginChannel, null);
  });

  group('AssessmentNotifier ID 常量', () {
    test('assessmentReminderId = 5000001 (R110 5M+ 固定带)', () {
      expect(AssessmentNotifier.assessmentReminderId, 5000001);
    });
  });

  group('AssessmentNotifier.scheduleAssessmentReminder (instance)', () {
    test('fireAt = 未来 → zonedAt 调 1 次, id=7000', () async {
      final mockDispatcher = _MockReminderDispatcher();
      final notifier = AssessmentNotifier(
        plugin: FlutterLocalNotificationsPlugin(),
        dispatcher: mockDispatcher,
        ensureInitialized: () async {},
      );

      final futureFire = DateTime.now().add(const Duration(days: 7));
      await notifier.scheduleAssessmentReminder(
        fireAt: futureFire,
        scaleId: 'phq9',
        days: 14,
      );

      expect(mockDispatcher.zonedAtCalls.length, 1);
      final call = mockDispatcher.zonedAtCalls.single;
      expect(call.id, 5000001);
      expect(call.fireAt, futureFire);
    });

    // v0.32 R110 round 6 (B1-7): 过去 fireAt 不再静默跳过 — catch-up 重排
    test('fireAt = 过去 → catch-up 重排 now+1h (不静默丢)', () async {
      final mockDispatcher = _MockReminderDispatcher();
      final notifier = AssessmentNotifier(
        plugin: FlutterLocalNotificationsPlugin(),
        dispatcher: mockDispatcher,
        ensureInitialized: () async {},
      );

      final pastFire = DateTime.now().subtract(const Duration(days: 1));
      await notifier.scheduleAssessmentReminder(fireAt: pastFire);

      expect(mockDispatcher.zonedAtCalls, hasLength(1),
          reason: '过去 fireAt 必须重排, 不能静默丢弃 (B1-7)',);
      final call = mockDispatcher.zonedAtCalls.single;
      expect(call.id, 5000001);
      expect(
        call.fireAt.isAfter(DateTime.now().add(const Duration(minutes: 59))),
        isTrue,
        reason: 'catch-up 落点 = now+1h 附近 (跟 policy 语义一致)',
      );
    });
  });

  group('AssessmentNotifier.cancelAssessmentReminder (instance)', () {
    test('cancel → 调 1 次 (id=7000 走 plugin 通道)', () async {
      // 计数 _plugin.cancel 调用次数 (通过 platform channel method 名称)
      var cancelCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pluginChannel, (call) async {
        if (call.method == 'cancel') cancelCount++;
        return null;
      });

      final notifier = AssessmentNotifier(
        plugin: FlutterLocalNotificationsPlugin(),
        dispatcher: _MockReminderDispatcher(),
        ensureInitialized: () async {},
      );

      await notifier.cancelAssessmentReminder();

      expect(cancelCount, 1, reason: 'cancel 应调 1 次 plugin.cancel(5000001)');
    });
  });
}

class _ZonedAtCall {
  final int id;
  final DateTime fireAt;
  _ZonedAtCall({required this.id, required this.fireAt});
}

class _MockReminderDispatcher implements ReminderDispatcher {
  final List<_ZonedAtCall> zonedAtCalls = [];
  final List<int> cancelByIdRangeCalls = [];

  @override
  Future<void> zonedAt({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    required NotificationDetails details,
    String? payload,
  }) async {
    zonedAtCalls.add(_ZonedAtCall(id: id, fireAt: fireAt));
  }

  @override
  Future<void> zonedDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required NotificationDetails details,
    String? payload,
  }) async {
    // not used in this test
  }

  @override
  NotificationDetails buildChannelDetails({bool high = true}) {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'mock_channel',
        'mock_channel_name',
        channelDescription: 'mock',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  @override
  Future<void> cancelByIdRange(int base) async {
    cancelByIdRangeCalls.add(base);
  }

  @override
  String get channelId => 'mock_channel';

  @override
  String get channelName => 'mock_channel_name';

  @override
  String get channelDescription => 'mock channel description';

  @override
  bool get useExactAllowWhileIdle => true;

  @override
  void setExactMode(bool value) {
    // Mock: no-op
  }
}
