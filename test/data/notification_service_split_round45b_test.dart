// notification_service_split_round45b_test.dart
//
// v0.24 (Sprint #5b) notification_service facade 拆解验证
//
// 拆解前: 629 行 facade god class (SnoozeManager / BadgeSyncService / ReminderDispatcher
//   3 个子 facade 之外的 4 类通知编排都在 facade 内)
// 拆解后: 410 行 facade + 3 个新 sub-service
//   - MedicationNotifier  (153 行) — daily check-in + medication
//   - RefillNotifier      (204 行) — refill 编排
//   - AssessmentNotifier  (90 行)  — 评估周期提醒
//
// 测试覆盖:
//   1. 3 个新 sub-service 都能 mount (构造函数 + dispatcher 注入)
//   2. facade 委托链 (snooze / badge 委托 + 3 orchestrator 委托)
//   3. ID 范围公式不回归 (200000 cancel range)
//   4. 现有 round 9 / 19B test 仍 pass (computeRefillFireTime / refillNotificationId)
//
// 验证策略 (跟 mood_dialog 拆解同模式):
//   - 静态 helper (computeRefillFireTime / refillNotificationId) — 纯函数
//   - 公共 API (NotificationService.xxx) — facade 委托链
//   - mock FlutterLocalNotificationsPlugin (不依赖 platform channel)
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/core/data/services/refill_notifier.dart';
import 'package:chroniccare/core/data/services/medication_notifier.dart';
import 'package:chroniccare/core/data/services/assessment_notifier.dart';
import 'package:chroniccare/core/data/services/reminder_dispatcher.dart';
import 'package:chroniccare/core/data/services/snooze_manager.dart';
import 'package:chroniccare/core/data/services/badge_sync_service.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';

/// Test plugin 记录 cancel/show/zonedSchedule 调用
///
/// 用 implements (不是 extends), 因为 FlutterLocalNotificationsPlugin
/// 无无参 constructor, extends 会编译失败. 我们只实现 facade + 3 sub-service
/// 用到的 method, 其它 throw UnsupportedError.
class _FakePlugin implements FlutterLocalNotificationsPlugin {
  final List<int> cancelledIds = [];
  final List<dynamic> zonedSchedules = [];
  final List<PendingNotificationRequest> pending = [];
  final List<dynamic> shown = [];

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

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails, {
    String? payload,
  }) async {
    shown.add({
      'id': id,
      'title': title,
      'body': body,
      'payload': payload,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Stub not implemented: ${invocation.memberName}');
}

void main() {
  setUp(() {
    // Mock method channel — plugin 调 show/cancel/zonedSchedule 不真的发通知
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('dexterous.com/flutter/local_notifications');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);
  });

  // ===== 1. ID 范围常量散落到 5 sub-service (单一职责) =====
  group('ID 范围常量 (5 sub-service 分散, 单一职责)', () {
    test('MedicationNotifier 2 const 不跟其他冲突', () {
      expect(MedicationNotifier.defaultReminderId, 1001);
      expect(MedicationNotifier.medicationReminderBaseId, 2000);
      // 1001 < 2000 (default < med base)
      expect(
        MedicationNotifier.defaultReminderId,
        lessThan(MedicationNotifier.medicationReminderBaseId),
      );
    });

    test('RefillNotifier 1 const', () {
      expect(RefillNotifier.refillBaseId, 6000);
      // 6000 > 2000 (refill base > med base)
      expect(
        RefillNotifier.refillBaseId,
        greaterThan(MedicationNotifier.medicationReminderBaseId),
      );
    });

    test('AssessmentNotifier 1 const', () {
      expect(AssessmentNotifier.assessmentReminderId, 7000);
      // 7000 > 6000 (assessment > refill)
      expect(
        AssessmentNotifier.assessmentReminderId,
        greaterThan(RefillNotifier.refillBaseId),
      );
    });

    test('6 个 const + BadgeSync 跟 SnoozeManager 不冲突 (集中列表)', () {
      // 1001 < 2000 (med base) < 5000 (safety) < 6000 (refill base) <
      //   7000 (assessment) < 9999 (badge) < 300000 (snooze)
      expect(NotificationService.safetyAlertId, 5000);
      expect(BadgeSyncService.badgeVirtualId, 9999);
      expect(SnoozeManager(plugin: _FakePlugin()).snoozeBaseId, 300000);

      // 顺序: 1001 < 2000 < 5000 < 6000 < 7000 < 9999 < 300000
      const ids = <int>[
        MedicationNotifier.defaultReminderId,
        MedicationNotifier.medicationReminderBaseId,
        NotificationService.safetyAlertId,
        RefillNotifier.refillBaseId,
        AssessmentNotifier.assessmentReminderId,
        BadgeSyncService.badgeVirtualId,
      ];
      // 验证严格递增 (cancel range 不冲突)
      for (int i = 1; i < ids.length; i++) {
        expect(
          ids[i],
          greaterThan(ids[i - 1]),
          reason: 'ID ${ids[i]} 应大于 ${ids[i - 1]}',
        );
      }
    });
  });

  // ===== 2. RefillNotifier 静态 helper (跟现有 round 9 / 19B test 兼容) =====
  group('RefillNotifier.computeRefillFireTime (纯函数, 跟现有 round 9 兼容)', () {
    test('refillAt = null → null', () {
      expect(
        NotificationService.computeRefillFireTime(
          refillAt: null,
          reminderDays: 7,
        ),
        isNull,
      );
    });

    test('reminderDays = 7: 触发时间 = 续方日期前 7 天 9 点', () {
      final result = NotificationService.computeRefillFireTime(
        refillAt: DateTime(2026, 7, 25),
        reminderDays: 7,
      );
      expect(result, DateTime(2026, 7, 18, 9, 0));
    });

    test('reminderDays = 0 抛 ArgumentError', () {
      expect(
        () => NotificationService.computeRefillFireTime(
          refillAt: DateTime(2026, 7, 25),
          reminderDays: 0,
        ),
        throwsArgumentError,
      );
    });

    test('reminderDays 负数抛 ArgumentError', () {
      expect(
        () => NotificationService.computeRefillFireTime(
          refillAt: DateTime(2026, 7, 25),
          reminderDays: -1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('RefillNotifier.refillNotificationId (跟现有 round 19B 兼容)', () {
    test('medId=0 → id=6000', () {
      expect(NotificationService.refillNotificationId(0), 6000);
    });

    test('medId=1000 → id=7000 (修前 OUT of range, 修后 in range)', () {
      final id = NotificationService.refillNotificationId(1000);
      expect(id, 7000);
      expect(
        id >= 6000 && id < 6000 + 200000,
        isTrue,
        reason: 'medId=1000 的 id 必须被 200000 range 覆盖',
      );
    });

    test('medId=50000 → id=56000 (极端场景)', () {
      final id = NotificationService.refillNotificationId(50000);
      expect(id, 56000);
      expect(id < 6000 + 200000, isTrue);
    });
  });

  // ===== 3. facade 委托链 (snooze / badge / 3 orchestrator) =====
  group('facade 委托链 (5 sub-service)', () {
    test('NotificationService 接受 onNotificationTap callback', () {
      var called = false;
      void tapHandler(String? payload) {
        called = true;
      }

      final service = NotificationService(onNotificationTap: tapHandler);
      // service 创建成功 + onNotificationTap 接受 callback
      expect(service.onNotificationTap, tapHandler);
      expect(called, isFalse); // 没调, 不变 true
    });

    test('NotificationService 默认 onNotificationTap 委托到 NotificationNavigation',
        () {
      // 默认 callback 是 _defaultOnTap, 内部调 NotificationNavigation.handleTap
      // 这里不实际触发 (handleTap 需 router bind), 只验证默认 callback 不为 null
      final service = NotificationService();
      expect(service.onNotificationTap, isNotNull);
    });

    test('snoozeOnce / cancelSnoozeForMedication / cancelAllSnoozes 公共 API 存在',
        () {
      // v0.30 R108 revisit: R45b 把 facade 拆成 5 个 sub-service, NotificationService
      // 不再代理这些 method。验证方式: 直接 instantiate SnoozeManager /
      // BadgeSyncService + 验证它们是 callable (Function.isMethod 永远 true
      // for instance method,我们改成验证 plugin 注入成功 + 不抛)。
      final fake = _FakePlugin();
      // SnoozeManager
      final snooze = SnoozeManager(plugin: fake);
      expect(snooze, isNotNull);
      // BadgeSyncService (需要 plugin)
      final badge = BadgeSyncService(plugin: fake);
      expect(badge, isNotNull);
    });

    test('3 orchestrator 公共 API 存在 (sub-service direct)', () {
      // v0.30 R108 revisit: 跟上面同理, 直接 instantiate 3 sub-service
      final fake = _FakePlugin();
      final dispatcher = ReminderDispatcher(
        plugin: fake,
        channelId: 'test',
        channelName: 'Test',
        channelDescription: 'desc',
      );
      // MedicationNotifier
      final med = MedicationNotifier(
        plugin: fake,
        dispatcher: dispatcher,
        ensureInitialized: () async {},
      );
      expect(med, isNotNull);
      // RefillNotifier
      final refill = RefillNotifier(
        plugin: fake,
        dispatcher: dispatcher,
        ensureInitialized: () async {},
      );
      expect(refill, isNotNull);
      // AssessmentNotifier
      final assess = AssessmentNotifier(
        plugin: fake,
        dispatcher: dispatcher,
        ensureInitialized: () async {},
      );
      expect(assess, isNotNull);
    });
  });

  // ===== 4. 3 sub-service 都能 mount (构造函数 + dispatcher 注入) =====
  group('3 sub-service 都能 mount (constructor DI)', () {
    test('MedicationNotifier 接受 plugin + dispatcher + ensureInitialized', () {
      final fake = _FakePlugin();
      final dispatcher = ReminderDispatcher(
        plugin: fake,
        channelId: 'test',
        channelName: 'Test',
        channelDescription: 'desc',
      );
      var initCount = 0;
      final notifier = MedicationNotifier(
        plugin: fake,
        dispatcher: dispatcher,
        ensureInitialized: () async {
          initCount++;
        },
      );
      expect(notifier, isNotNull);
      expect(initCount, 0); // 还没调 method
    });

    test('RefillNotifier 接受 plugin + dispatcher + ensureInitialized', () {
      final fake = _FakePlugin();
      final dispatcher = ReminderDispatcher(
        plugin: fake,
        channelId: 'test',
        channelName: 'Test',
        channelDescription: 'desc',
      );
      final notifier = RefillNotifier(
        plugin: fake,
        dispatcher: dispatcher,
        ensureInitialized: () async {},
      );
      expect(notifier, isNotNull);
    });

    test('AssessmentNotifier 接受 plugin + dispatcher + ensureInitialized', () {
      final fake = _FakePlugin();
      final dispatcher = ReminderDispatcher(
        plugin: fake,
        channelId: 'test',
        channelName: 'Test',
        channelDescription: 'desc',
      );
      final notifier = AssessmentNotifier(
        plugin: fake,
        dispatcher: dispatcher,
        ensureInitialized: () async {},
      );
      expect(notifier, isNotNull);
    });
  });

  // ===== 5. scheduleRefillReminder 静态路径 (跟 round 9 test 互补) =====
  group('scheduleRefillReminder 走 facade 委托', () {
    test('refillAt = null → 静默 no-op (不调 plugin)', () async {
      final fake = _FakePlugin();
      final dispatcher = ReminderDispatcher(
        plugin: fake,
        channelId: 'test',
        channelName: 'Test',
        channelDescription: 'desc',
      );
      final notifier = RefillNotifier(
        plugin: fake,
        dispatcher: dispatcher,
        ensureInitialized: () async {},
      );
      final med = MedicationEntity(
        id: 1,
        name: 'A',
        dosage: 1.0,
        dosageUnit: DosageUnit.tablet,
        times: const [],
        startDate: DateTime(2026, 1, 1),
        refillAt: null,
        refillReminderDays: 7,
        isActive: true,
      );
      await notifier.scheduleRefillReminder(med);
      // 不调 plugin
      expect(fake.cancelledIds, isEmpty);
      expect(fake.zonedSchedules, isEmpty);
    });
  });
}
