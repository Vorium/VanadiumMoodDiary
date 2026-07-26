// v0.25 round 56c'' (spen P0 #15 TDD 续): MedicationNotifier test
//
// 之前 0 test (v0.24 round 45 拆 sub-service 时只加 facade).
// R56c'' 补 2 个 const ID + 6 个 instance method 测, 共 8 test cases.
//
// 设计要点:
// - mock 走 ReminderDispatcher interface, 跟踪 zonedDaily / cancelByIdRange 调用
// - flutter_local_notifications platform channel 全局 mock 让 _plugin.cancel()
//   (scheduleDailyReminder 第 2 行) 在 test 不抛 MissingPluginException
// - payload 是 chroniccare://check-in/today (daily) 或 chroniccare://check-in/med/N (per-med)
import 'package:chroniccare/core/data/services/medication_notifier.dart';
import 'package:chroniccare/core/data/services/reminder_dispatcher.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
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

  group('MedicationNotifier ID 常量', () {
    test('defaultReminderId = 1001 (跟 medication id 公式不冲突)', () {
      expect(MedicationNotifier.defaultReminderId, 1001);
    });

    test('medicationReminderBaseId = 2000 (v0.16 round 19/19B 公式 base)', () {
      expect(MedicationNotifier.medicationReminderBaseId, 2000);
    });
  });

  group('MedicationNotifier.scheduleDailyReminder (instance)', () {
    test('默认 hour=20 minute=0 → zonedDaily 调 1 次, id=1001', () async {
      final mockDispatcher = _MockReminderDispatcher();

      final notifier = MedicationNotifier(
        plugin: FlutterLocalNotificationsPlugin(),
        dispatcher: mockDispatcher,
        ensureInitialized: () async {},
      );

      await notifier.scheduleDailyReminder();

      expect(mockDispatcher.zonedDailyCalls.length, 1);
      final call = mockDispatcher.zonedDailyCalls.single;
      expect(call.id, 1001);
      expect(call.hour, 20);
      expect(call.minute, 0);
    });

    test('自定义 hour=8 minute=30 → zonedDaily 收到 8:30', () async {
      final mockDispatcher = _MockReminderDispatcher();

      final notifier = MedicationNotifier(
        plugin: FlutterLocalNotificationsPlugin(),
        dispatcher: mockDispatcher,
        ensureInitialized: () async {},
      );

      await notifier.scheduleDailyReminder(hour: 8, minute: 30);

      expect(mockDispatcher.zonedDailyCalls.length, 1);
      final call = mockDispatcher.zonedDailyCalls.single;
      expect(call.hour, 8);
      expect(call.minute, 30);
      expect(call.id, 1001);
    });

    test('zonedDaily 抛错 → 不传播 (web 平台 UnsupportedError 兜底)', () async {
      final mockDispatcher = _MockReminderDispatcher(
        throwOnZonedDaily: true,
      );

      final notifier = MedicationNotifier(
        plugin: FlutterLocalNotificationsPlugin(),
        dispatcher: mockDispatcher,
        ensureInitialized: () async {},
      );

      // 不应抛
      await expectLater(
        notifier.scheduleDailyReminder(),
        completes,
      );
    });
  });

  group('MedicationNotifier.rescheduleMedicationReminders (instance)', () {
    test('空 medications → cancel 旧 + 不调 zonedDaily', () async {
      final mockDispatcher = _MockReminderDispatcher();

      final notifier = MedicationNotifier(
        plugin: FlutterLocalNotificationsPlugin(),
        dispatcher: mockDispatcher,
        ensureInitialized: () async {},
      );

      await notifier.rescheduleMedicationReminders(const []);

      expect(mockDispatcher.cancelByIdRangeCalls, [2000]);
      expect(mockDispatcher.zonedDailyCalls, isEmpty);
    });

    test('!isActive 的 medication → 跳过, 不调 zonedDaily', () async {
      final mockDispatcher = _MockReminderDispatcher();

      final notifier = MedicationNotifier(
        plugin: FlutterLocalNotificationsPlugin(),
        dispatcher: mockDispatcher,
        ensureInitialized: () async {},
      );

      final meds = [
        _makeMedication(id: 1, isActive: false, times: const [
          HourMinute(hour: 8, minute: 0),
        ],),
        _makeMedication(id: 2, isActive: true, times: const [
          HourMinute(hour: 9, minute: 0),
        ],),
      ];

      await notifier.rescheduleMedicationReminders(meds);

      // med 1 (isActive=false) 跳过, 只 med 2 调度 1 次
      expect(mockDispatcher.zonedDailyCalls.length, 1);
      final call = mockDispatcher.zonedDailyCalls.single;
      expect(call.id, 2000 + 2 * 10 + 0); // 2020
      expect(call.hour, 9);
      expect(call.minute, 0);
    });

    test('多 times → 每 time 调 zonedDaily, id = 2000 + medId*10 + i', () async {
      final mockDispatcher = _MockReminderDispatcher();

      final notifier = MedicationNotifier(
        plugin: FlutterLocalNotificationsPlugin(),
        dispatcher: mockDispatcher,
        ensureInitialized: () async {},
      );

      final meds = [
        _makeMedication(id: 5, isActive: true, times: const [
          HourMinute(hour: 8, minute: 0),
          HourMinute(hour: 14, minute: 30),
          HourMinute(hour: 22, minute: 0),
        ],),
      ];

      await notifier.rescheduleMedicationReminders(meds);

      expect(mockDispatcher.zonedDailyCalls.length, 3);
      expect(mockDispatcher.zonedDailyCalls[0].id, 2000 + 5 * 10 + 0); // 2050
      expect(mockDispatcher.zonedDailyCalls[0].hour, 8);
      expect(mockDispatcher.zonedDailyCalls[1].id, 2000 + 5 * 10 + 1); // 2051
      expect(mockDispatcher.zonedDailyCalls[1].hour, 14);
      expect(mockDispatcher.zonedDailyCalls[1].minute, 30);
      expect(mockDispatcher.zonedDailyCalls[2].id, 2000 + 5 * 10 + 2); // 2052
      expect(mockDispatcher.zonedDailyCalls[2].hour, 22);
    });

    test('多 medications → cancel 1 次, 然后逐个调度 (cancel range=200000)', () async {
      final mockDispatcher = _MockReminderDispatcher();

      final notifier = MedicationNotifier(
        plugin: FlutterLocalNotificationsPlugin(),
        dispatcher: mockDispatcher,
        ensureInitialized: () async {},
      );

      final meds = [
        _makeMedication(id: 1, isActive: true, times: const [
          HourMinute(hour: 8, minute: 0),
        ],),
        _makeMedication(id: 2, isActive: true, times: const [
          HourMinute(hour: 9, minute: 0),
          HourMinute(hour: 21, minute: 0),
        ],),
      ];

      await notifier.rescheduleMedicationReminders(meds);

      // cancelByIdRange(2000) 调 1 次 (一次性清空所有 medication id 槽)
      expect(mockDispatcher.cancelByIdRangeCalls, [2000]);
      // med 1: 1 time → 1 call
      // med 2: 2 times → 2 calls
      expect(mockDispatcher.zonedDailyCalls.length, 3);
    });

    test('per-med zonedDaily 抛错 → 后续 med 仍调度 (loop 不中断)', () async {
      // Mock: 第 1 个 zonedDaily call 抛错, 后续不抛
      final mockDispatcher = _MockReminderDispatcher(
        failOnFirstZonedDaily: true,
      );

      final notifier = MedicationNotifier(
        plugin: FlutterLocalNotificationsPlugin(),
        dispatcher: mockDispatcher,
        ensureInitialized: () async {},
      );

      final meds = [
        _makeMedication(id: 1, isActive: true, times: const [
          HourMinute(hour: 8, minute: 0),
        ],),
        _makeMedication(id: 2, isActive: true, times: const [
          HourMinute(hour: 9, minute: 0),
        ],),
      ];

      // 不应抛
      await expectLater(
        notifier.rescheduleMedicationReminders(meds),
        completes,
      );

      // 2 个 zonedDaily call 都被尝试 (med 1 抛但循环继续到 med 2)
      expect(mockDispatcher.zonedDailyCalls.length, 2);
    });
  });
}

/// 构造测试用 MedicationEntity (避免每处重复 boilerplate)
MedicationEntity _makeMedication({
  required int id,
  required bool isActive,
  required List<HourMinute> times,
  String name = '测试药',
  double dosage = 50,
  DosageUnit dosageUnit = DosageUnit.mg,
  DateTime? refillAt,
  int refillReminderDays = 7,
}) {
  return MedicationEntity(
    id: id,
    name: name,
    dosage: dosage,
    dosageUnit: dosageUnit,
    times: times,
    startDate: DateTime(2026, 1, 1),
    endDate: null,
    isActive: isActive,
    refillAt: refillAt,
    refillReminderDays: refillReminderDays,
  );
}

/// 详细 mock: 跟踪 zonedDaily 和 cancelByIdRange 的调用 + 参数
class _MockReminderDispatcher implements ReminderDispatcher {
  /// 全部 zonedDaily 调用记录
  final List<_ZonedDailyCall> zonedDailyCalls = [];

  /// 全部 cancelByIdRange 调用参数
  final List<int> cancelByIdRangeCalls = [];

  /// 全部 zonedAt 调用计数 (不记录内容)
  final List<int> zonedAtCalls = [];

  /// 设为 true 时, zonedDaily 第 1 次调用抛 Exception (用于测 loop 不中断)
  final bool failOnFirstZonedDaily;

  /// 设为 true 时, 每次 zonedDaily 都抛 (用于测 catch 兜底)
  final bool throwOnZonedDaily;

  _MockReminderDispatcher({
    this.failOnFirstZonedDaily = false,
    this.throwOnZonedDaily = false,
  });

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
    if (throwOnZonedDaily) {
      throw Exception('mock zonedDaily always throws');
    }
    if (failOnFirstZonedDaily && zonedDailyCalls.isEmpty) {
      // 标记 + 抛错, 但仍记录 call (mock 已经走到这步)
      zonedDailyCalls.add(_ZonedDailyCall(
        id: id,
        title: title,
        body: body,
        hour: hour,
        minute: minute,
      ),);
      throw Exception('mock zonedDaily first call throws');
    }
    zonedDailyCalls.add(_ZonedDailyCall(
      id: id,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
    ),);
  }

  @override
  Future<void> zonedAt({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    required NotificationDetails details,
    String? payload,
  }) async {
    zonedAtCalls.add(id);
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
}

class _ZonedDailyCall {
  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;

  _ZonedDailyCall({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
  });

  @override
  String toString() => 'ZonedDailyCall(id=$id, $hour:$minute)';
}
