// v0.25 round 56c' (spen P0 #15 TDD 续): RefillNotifier test
//
// 之前 0 test (v0.24 round 45 拆 sub-service 时只加 facade, 没补 sub test).
// R56c' 补 2 个 static 公式 + 6 个 computeRefillFireTime + 2 个 scheduleRefillReminder
// instance 测. 共 10 test cases.
//
// 设计要点:
// - mock 走 ReminderDispatcher interface (不直接 mock plugin),
//   因为主 service 业务编排只调 dispatcher, plugin 调用是 dispatcher 内部
// - flutter_local_notifications 的 platform channel 用全局 setMockMethodCallHandler
//   屏蔽, 防止 _plugin.cancel() 在 test 抛 MissingPluginException
// - "已过期" test 验证 zonedAtCalled==0 (核心意图: 不调度过期提醒)
//   旁路 cancel 走 _plugin.cancel 不走 dispatcher, 不验证 cancelCalled
//   (cancel 路径单独测, 见 medication_repository_refill_round9_test.dart)
import 'package:chroniccare/core/data/services/reminder_dispatcher.dart';
import 'package:chroniccare/core/data/services/refill_notifier.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 屏蔽 flutter_local_notifications platform channel, 让 _plugin.cancel()
  // 在 test 环境不会抛 MissingPluginException.
  // 注: 主 service (RefillNotifier) 走 _dispatcher.zonedAt 调 plugin,
  // 我们的 mock dispatcher 不实际调 plugin, 所以这条 mock 只为
  // _plugin.cancel(id) 兜底 (cancelRefillReminder 路径).
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

  group('RefillNotifier.refillNotificationId (id 公式)', () {
    test('id = refillBase + medId', () {
      expect(RefillNotifier.refillNotificationId(1), 6001);
      expect(RefillNotifier.refillNotificationId(42), 6042);
      expect(RefillNotifier.refillNotificationId(0), 6000);
    });

    test('id 范围 base 6000-206000 (200000 range, v0.16 round 19B)', () {
      // 最大 medId < 200000
      expect(RefillNotifier.refillNotificationId(199999), 205999);
      // 验证 range 至少 200000 (配套 cancel 范围)
      expect(
        RefillNotifier.refillNotificationId(200000) -
            RefillNotifier.refillBaseId,
        200000,
      );
    });
  });

  group('RefillNotifier.computeRefillFireTime (纯函数)', () {
    test('refillAt = 2026-09-15, reminderDays = 7 → 2026-09-08 09:00', () {
      final refillAt = DateTime(2026, 9, 15);
      final result = RefillNotifier.computeRefillFireTime(
        refillAt: refillAt,
        reminderDays: 7,
      );
      expect(result, DateTime(2026, 9, 8, 9, 0));
    });

    test('refillAt = 2026-09-15, reminderDays = 1 → 2026-09-14 09:00', () {
      final result = RefillNotifier.computeRefillFireTime(
        refillAt: DateTime(2026, 9, 15),
        reminderDays: 1,
      );
      expect(result, DateTime(2026, 9, 14, 9, 0));
    });

    test('refillAt = null → 返 null (no-op)', () {
      final result = RefillNotifier.computeRefillFireTime(
        refillAt: null,
        reminderDays: 7,
      );
      expect(result, isNull);
    });

    test('reminderDays < 1 → 抛 ArgumentError', () {
      expect(
        () => RefillNotifier.computeRefillFireTime(
          refillAt: DateTime(2026, 9, 15),
          reminderDays: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => RefillNotifier.computeRefillFireTime(
          refillAt: DateTime(2026, 9, 15),
          reminderDays: -1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('refillAt 带时分秒 → 忽略时分秒, 只用日期部分', () {
      // refillAt = 2026-09-15 23:59:59, reminderDays=7 → 2026-09-08 09:00
      // (实现: refillAt 拆成 day 0:00, 再 subtract reminderDays, 再 + 9h)
      final result = RefillNotifier.computeRefillFireTime(
        refillAt: DateTime(2026, 9, 15, 23, 59, 59),
        reminderDays: 7,
      );
      expect(result, DateTime(2026, 9, 8, 9, 0));
    });

    test('reminderDays = 14 (大值, 提前 2 周) → 2026-09-01 09:00', () {
      final result = RefillNotifier.computeRefillFireTime(
        refillAt: DateTime(2026, 9, 15),
        reminderDays: 14,
      );
      expect(result, DateTime(2026, 9, 1, 9, 0));
    });
  });

  group('RefillNotifier.scheduleRefillReminder (instance)', () {
    test('medication.refillAt = null → no-op (不调 dispatcher.zonedAt)',
        () async {
      // Mock 计数: 验证没调 zonedAt
      var zonedAtCalled = 0;
      final mockDispatcher = _MockReminderDispatcher(
        onZonedAt: () => zonedAtCalled++,
      );

      final notifier = RefillNotifier(
        plugin: FlutterLocalNotificationsPlugin(),
        dispatcher: mockDispatcher,
        ensureInitialized: () async {},
      );

      final medWithoutRefill = MedicationEntity(
        id: 42,
        name: '舍曲林',
        dosage: 50,
        dosageUnit: DosageUnit.mg,
        times: const [HourMinute(hour: 8, minute: 0)],
        startDate: DateTime(2026, 1, 1),
        endDate: null,
        isActive: true,
        refillAt: null, // 没设 refillAt
        refillReminderDays: 7,
      );

      await notifier.scheduleRefillReminder(medWithoutRefill);

      expect(zonedAtCalled, 0, reason: 'refillAt=null 应 no-op, 不调 zonedAt');
    });

    test('medication.refillAt 已过 → 跳过 (不调 zonedAt)', () async {
      // 已过期时: fireAt.isBefore(now) 走 cancel 路径 (调 _plugin.cancel)
      // 不会调 _dispatcher.zonedAt
      var zonedAtCalled = 0;
      final mockDispatcher = _MockReminderDispatcher(
        onZonedAt: () => zonedAtCalled++,
      );

      final notifier = RefillNotifier(
        plugin: FlutterLocalNotificationsPlugin(),
        dispatcher: mockDispatcher,
        ensureInitialized: () async {},
      );

      final expiredMed = MedicationEntity(
        id: 99,
        name: '已过期',
        dosage: 10,
        dosageUnit: DosageUnit.mg,
        times: const [HourMinute(hour: 8, minute: 0)],
        startDate: DateTime(2025, 1, 1),
        endDate: null,
        isActive: true,
        refillAt: DateTime(2025, 1, 15), // 已过期
        refillReminderDays: 7,
      );

      await notifier.scheduleRefillReminder(expiredMed);

      expect(zonedAtCalled, 0, reason: '已过期 refillAt 应跳过, 不调 zonedAt');
      // 注: 已过期会调 cancelRefillReminder → _plugin.cancel(id) (走 plugin, 不走 dispatcher)
      // cancel 行为单独在 medication_repository_refill_round9_test.dart 覆盖
    });
  });

  // ============ v0.26 round 57 (spen P0 TDD 续): systematic-debugging 5 类 regression ============
  //
  // 锁 1+2: 跨 midnight race (DateTime.now() 多次调用) + 隐式 fire-time
  // computeRefillFireTime 是纯函数, 测跨月/跨年 + 边界时间 (00:00:00 / 23:59:59)

  group('RefillNotifier systematic-debugging regression guards', () {
    test('跨 midnight: refillAt 在 00:00:00 → fireTime 不变 (不走前一天)', () {
      // bug 模式: 之前 `_daysUntilRefill` 用 `DateTime(y,m,d)` 拼 today
      // 跟 `DateTime.now()` 调多次, 跨 midnight 后 today 可能漂移到前一天
      // → daysLeft 算错, fireTime 也错
      // 锁: refillAt 本身就是 00:00:00, compute 不退化
      final fireTime = RefillNotifier.computeRefillFireTime(
        refillAt: DateTime(2026, 9, 15, 0, 0, 0),
        reminderDays: 7,
      );
      // refillAt 当天 0:00 - 7 天 + 9 小时 = 9月8日 9:00
      expect(fireTime, DateTime(2026, 9, 8, 9, 0));
    });

    test('跨 midnight: refillAt 在 23:59:59 → fireTime 仍是 9:00 当天 (不漂移)', () {
      // 反向: refillAt 23:59:59 时, 整日期部分仍是 9/15, fireTime 应 = 9/8 9:00
      final fireTime = RefillNotifier.computeRefillFireTime(
        refillAt: DateTime(2026, 9, 15, 23, 59, 59),
        reminderDays: 7,
      );
      expect(fireTime, DateTime(2026, 9, 8, 9, 0));
    });

    test('跨月: refillAt = 月底 (9/30) - 7 天 → 9/23 9:00 (DateTime 自动处理月/30/31 天)',
        () {
      // 跨月边界: 9/30 - 7 = 9/23 (本月末-7天不会跨月)
      final fireTime = RefillNotifier.computeRefillFireTime(
        refillAt: DateTime(2026, 9, 30),
        reminderDays: 7,
      );
      expect(fireTime, DateTime(2026, 9, 23, 9, 0));
    });

    test('跨年: refillAt = 2026/01/05, reminderDays=7 → 2025/12/29 9:00 (上一年)',
        () {
      // 跨年边界: 1/5 - 7 = 上一年 12/29
      final fireTime = RefillNotifier.computeRefillFireTime(
        refillAt: DateTime(2026, 1, 5),
        reminderDays: 7,
      );
      expect(fireTime, DateTime(2025, 12, 29, 9, 0));
    });
  });
}

/// 简易 mock: 只跟踪关键调用, 不实际调 plugin
///
/// 实现 ReminderDispatcher 全 4 个 method (zonedAt / zonedDaily /
/// buildChannelDetails / cancelByIdRange) 以满足 interface 实现约束。
class _MockReminderDispatcher implements ReminderDispatcher {
  final void Function() onZonedAt;

  _MockReminderDispatcher({this.onZonedAt = _noop});

  static void _noop() {}

  @override
  Future<void> zonedAt({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    required NotificationDetails details,
    String? payload,
  }) async {
    onZonedAt();
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
    // 不追踪, 只 no-op
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
    // 本测试不覆盖 cancelByIdRange 路径 (走 _plugin.cancel 旁路),
    // 实现满足 interface 即可
  }

  // ReminderDispatcher 3 个 final 字段 (channelId/Name/Description),
  // mock 不真用, 返 stub 字符串
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
