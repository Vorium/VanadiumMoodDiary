// R114 B1-3: medication / refill cancel 带互杀 — 回归测试
// (2026-08-16 标准审计 · 10-bottom-core-data 发现 5)
//
// 修前: medication cancel [2000, 202000) 完全覆盖所有 refill id (6000+medId);
// refill cancel [6000, 206000) 覆盖 medication id (2000+medId*10+i, medId ≥ 400)。
// `rescheduleAll` 顺序 (med→refill) 自愈, 但单侧 reschedule
// (medications_list_widget 软停药只调 rescheduleRefillReminders) 会静默杀另一类。
//
// 修后: refill base 迁 2,500,000 (cancel [2500000, 2700000), 与 medication
// [2000,202000) / snooze [300000,2300000) / 固定带 5M+ 全不相交);
// 老 base 6000 的 legacy refill id 在 refill 侧按 med 精确取消 (升级兼容)。
//
// 本测试断言: 单侧 reschedule 互不 cancel 对方的 id。
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

import 'package:chroniccare/core/data/services/medication_notifier.dart';
import 'package:chroniccare/core/data/services/refill_notifier.dart';
import 'package:chroniccare/core/platform/notification/reminder_dispatcher.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';

/// 记录 cancel 调用 + 提供 pending 列表的 fake plugin
class _FakePlugin implements FlutterLocalNotificationsPlugin {
  final List<int> cancelledIds = [];
  final List<int> scheduledIds = [];
  final List<PendingNotificationRequest> pending = [];

  @override
  Future<void> cancel(int id, {String? tag}) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAll() async {
    cancelledIds.add(-1);
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
    scheduledIds.add(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Stub not implemented: ${invocation.memberName}');
}

MedicationEntity _med(int id) {
  return MedicationEntity(
    id: id,
    name: 'med$id',
    dosage: 1,
    dosageUnit: DosageUnit.tablet,
    times: const [HourMinute(hour: 8, minute: 0)],
    startDate: DateTime(2026, 1, 1),
    isActive: true,
    refillReminderDays: 7,
  );
}

void main() {
  setUpAll(tz_data.initializeTimeZones);

  test('medication reschedule 不 cancel refill 新 id (2500000+)', () async {
    final fake = _FakePlugin();
    final dispatcher = ReminderDispatcher(
      plugin: fake,
      channelId: 'test',
      channelName: 'test',
      channelDescription: 'test',
    );
    final medNotifier = MedicationNotifier(
      plugin: fake,
      dispatcher: dispatcher,
      ensureInitialized: () async {},
    );
    fake.pending.addAll([
      // med 1 i=0 → 2010; med 2 i=0 → 2020
      const PendingNotificationRequest(2010, 'a', 'b', null),
      const PendingNotificationRequest(2020, 'a', 'b', null),
      // refill 新 id (med 1 → 2500001)
      const PendingNotificationRequest(2500001, 'a', 'b', null),
      // badge 固定带
      const PendingNotificationRequest(5000100, 'a', 'b', null),
    ]);

    await medNotifier.rescheduleMedicationReminders([_med(1), _med(2)]);

    expect(fake.cancelledIds, contains(2010));
    expect(fake.cancelledIds, contains(2020));
    expect(
      fake.cancelledIds,
      isNot(contains(2500001)),
      reason: 'refill 新 id 不得被 medication cancel 杀',
    );
    expect(fake.cancelledIds, isNot(contains(5000100)));
  });

  test('refill reschedule 不 cancel medication id (2000+medId*10+i)', () async {
    final fake = _FakePlugin();
    final dispatcher = ReminderDispatcher(
      plugin: fake,
      channelId: 'test',
      channelName: 'test',
      channelDescription: 'test',
    );
    final refillNotifier = RefillNotifier(
      plugin: fake,
      dispatcher: dispatcher,
      ensureInitialized: () async {},
    );
    fake.pending.addAll([
      // med 1 用药提醒 (id 2010)
      const PendingNotificationRequest(2010, 'a', 'b', null),
      // refill 新 id (med 1)
      const PendingNotificationRequest(2500001, 'a', 'b', null),
      // legacy refill id (med 1, 升级前 6000 段)
      const PendingNotificationRequest(6001, 'a', 'b', null),
      // snooze id (med 1, 5min) — 不应被 refill cancel 碰
      const PendingNotificationRequest(300000 + 1 * 1440 + 5, 'a', 'b', null),
    ]);

    await refillNotifier.rescheduleRefillReminders([_med(1)]);

    expect(fake.cancelledIds, contains(2500001));
    expect(
      fake.cancelledIds,
      contains(6001),
      reason: 'legacy refill id 精确取消 (升级兼容, 防重复提醒)',
    );
    expect(
      fake.cancelledIds,
      isNot(contains(2010)),
      reason: 'medication 提醒不得被 refill cancel 杀',
    );
    expect(
      fake.cancelledIds,
      isNot(contains(300000 + 1 * 1440 + 5)),
      reason: 'snooze 不得被 refill cancel 杀',
    );
  });

  test('id 空间 lock-in: 四个 cancel 带互不相交', () {
    // medication [2000, 202000) / refill 新 [2500000, 2700000) /
    // snooze [300000, 2300000) / 固定带 ≥ 5000001
    const medMin = MedicationNotifier.medicationReminderBaseId;
    const medMax = medMin + kReminderCancelRange;
    const refillMin = RefillNotifier.refillBaseId;
    const refillMax = refillMin + kReminderCancelRange;
    const snoozeMin = 300000;
    const snoozeMax = snoozeMin + 2000000;
    const fixedMin = 5000001;

    expect(refillMin, greaterThan(medMax), reason: 'refill 下界 > med 上界');
    expect(refillMin, greaterThan(snoozeMax), reason: 'refill 下界 > snooze 上界');
    expect(refillMax, lessThan(fixedMin), reason: 'refill 上界 < 固定带下界');
    expect(medMax, lessThan(snoozeMin), reason: 'med 上界 < snooze 下界');
  });

  test('cancelRefillReminder 同时清新 id + legacy id', () async {
    final fake = _FakePlugin();
    final dispatcher = ReminderDispatcher(
      plugin: fake,
      channelId: 'test',
      channelName: 'test',
      channelDescription: 'test',
    );
    final refillNotifier = RefillNotifier(
      plugin: fake,
      dispatcher: dispatcher,
      ensureInitialized: () async {},
    );

    await refillNotifier.cancelRefillReminder(7);

    expect(fake.cancelledIds, containsAll([2500007, 6007]));
  });
}
