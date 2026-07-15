// v0.13 (Round 7) AssessmentReminderService 单元测试
import 'package:chroniccare/data/database/app_database.dart';
import 'package:chroniccare/data/repositories/check_in_repository_impl.dart';
import 'package:chroniccare/data/services/assessment_reminder_service.dart';
import 'package:chroniccare/data/services/notification_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StubNotificationService extends NotificationService {
  final List<({DateTime fireAt, String scaleId, int days})> scheduled = [];
  int cancelCount = 0;

  StubNotificationService() : super(onNotificationTap: (_) {});

  @override
  Future<void> init() async {}

  @override
  Future<void> scheduleAssessmentReminder({
    required DateTime fireAt,
    String scaleId = 'phq9',
    int days = 14,
  }) async {
    scheduled.add((fireAt: fireAt, scaleId: scaleId, days: days));
  }

  @override
  Future<void> cancelAssessmentReminder() async {
    cancelCount++;
  }
}

void main() {
  // SharedPreferences 静态初始化
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('computeNextFireTime (纯函数)', () {
    test('enabled=false → null', () {
      final result = AssessmentReminderService.computeNextFireTime(
        enabled: false,
        days: 14,
        lastAssessmentAt: DateTime(2026, 7, 1),
        now: DateTime(2026, 8, 1),
      );
      expect(result, isNull);
    });

    test('无历史 + enabled → now + days 天, 锁定 10:00', () {
      final now = DateTime(2026, 7, 1, 8, 30);
      final result = AssessmentReminderService.computeNextFireTime(
        enabled: true,
        days: 14,
        lastAssessmentAt: null,
        now: now,
      );
      // 7/1 + 14 = 7/15 锁定 10:00
      expect(result, DateTime(2026, 7, 15, 10, 0));
    });

    test('有历史 + enabled → last + days 天, 锁定 10:00', () {
      final now = DateTime(2026, 8, 1);
      final result = AssessmentReminderService.computeNextFireTime(
        enabled: true,
        days: 14,
        lastAssessmentAt: DateTime(2026, 7, 20, 16, 30),
        now: now,
      );
      // 7/20 + 14 = 8/3 锁定 10:00
      expect(result, DateTime(2026, 8, 3, 10, 0));
    });

    test('last + days 已过 → catch-up 到 now + 1h', () {
      // 假设 30 天前评估过, 设 14 天, 早就该提醒
      final now = DateTime(2026, 8, 1, 10, 0);
      final result = AssessmentReminderService.computeNextFireTime(
        enabled: true,
        days: 14,
        lastAssessmentAt: DateTime(2026, 7, 1),
        now: now,
      );
      // 7/1 + 14 = 7/15 < 8/1 → catch-up
      expect(result, DateTime(2026, 8, 1, 11, 0));
    });

    test('last + days 刚好是今天 9 点 → 锁定 10:00 (仍是今天)', () {
      final now = DateTime(2026, 7, 15, 9, 0);
      final result = AssessmentReminderService.computeNextFireTime(
        enabled: true,
        days: 14,
        lastAssessmentAt: DateTime(2026, 7, 1),
        now: now,
      );
      // 7/1 + 14 = 7/15 9:00 < now(9:00) ? 同等不小于 → 锁定 10:00 = 7/15 10:00
      // 实际: fire = 7/15 10:00, isBefore(now=7/15 9:00)? 不, fire 在后
      // 所以返回 7/15 10:00 (不 catch-up)
      expect(result, DateTime(2026, 7, 15, 10, 0));
    });

    test('days 不在 allowedDays 抛 ArgumentError', () {
      expect(
        () => AssessmentReminderService.computeNextFireTime(
          enabled: true,
          days: 13, // 非法
          lastAssessmentAt: null,
          now: DateTime(2026, 7, 1),
        ),
        throwsArgumentError,
      );
    });

    test('7/14/30/60/90 全部合法', () {
      for (final d in AssessmentReminderService.allowedDays) {
        final r = AssessmentReminderService.computeNextFireTime(
          enabled: true,
          days: d,
          lastAssessmentAt: null,
          now: DateTime(2026, 7, 1, 8, 0),
        );
        expect(r, isNotNull, reason: 'days=$d 应该返回 fireAt');
        expect(r!.hour, 10, reason: 'days=$d 锁定 10:00');
      }
    });
  });

  group('配置 API', () {
    late AppDatabase db;
    late CheckInRepositoryImpl checkInRepo;
    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      checkInRepo = CheckInRepositoryImpl(db);
    });
    tearDown(() async {
      await db.close();
    });

    test('默认 enabled=false', () async {
      final service = AssessmentReminderService(
        checkInRepo: checkInRepo,
        notificationService: StubNotificationService(),
      );
      expect(await service.isEnabled(), isFalse);
    });

    test('默认 days=14', () async {
      final service = AssessmentReminderService(
        checkInRepo: checkInRepo,
        notificationService: StubNotificationService(),
      );
      expect(await service.getDays(), 14);
    });

    test('setEnabled + getEnabled', () async {
      final service = AssessmentReminderService(
        checkInRepo: checkInRepo,
        notificationService: StubNotificationService(),
      );
      await service.setEnabled(true);
      expect(await service.isEnabled(), isTrue);
      await service.setEnabled(false);
      expect(await service.isEnabled(), isFalse);
    });

    test('setDays 接受 7/14/30/60/90', () async {
      final service = AssessmentReminderService(
        checkInRepo: checkInRepo,
        notificationService: StubNotificationService(),
      );
      for (final d in AssessmentReminderService.allowedDays) {
        await service.setDays(d);
        expect(await service.getDays(), d);
      }
    });

    test('setDays 非法值抛 ArgumentError', () async {
      final service = AssessmentReminderService(
        checkInRepo: checkInRepo,
        notificationService: StubNotificationService(),
      );
      expect(() => service.setDays(13), throwsArgumentError);
      expect(() => service.setDays(0), throwsArgumentError);
      expect(() => service.setDays(100), throwsArgumentError);
    });

    test('getDays 对非法值降级到 14', () async {
      SharedPreferences.setMockInitialValues({
        'assessment_reminder_days': 13, // 非法
      });
      final service = AssessmentReminderService(
        checkInRepo: checkInRepo,
        notificationService: StubNotificationService(),
      );
      expect(await service.getDays(), 14);
    });

    test('lastAssessmentAt 读写', () async {
      final service = AssessmentReminderService(
        checkInRepo: checkInRepo,
        notificationService: StubNotificationService(),
      );
      expect(await service.getLastAssessmentAt(), isNull);
      await service.setLastAssessmentAt(DateTime(2026, 7, 15, 16, 30));
      expect(
        await service.getLastAssessmentAt(),
        DateTime(2026, 7, 15, 16, 30),
      );
    });
  });

  group('onAppStart', () {
    late AppDatabase db;
    late CheckInRepositoryImpl checkInRepo;
    late StubNotificationService notif;
    late AssessmentReminderService service;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      checkInRepo = CheckInRepositoryImpl(db);
      notif = StubNotificationService();
      service = AssessmentReminderService(
        checkInRepo: checkInRepo,
        notificationService: notif,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('disabled → 取消任何待响推送', () async {
      await service.onAppStart();
      expect(notif.cancelCount, 1);
      expect(notif.scheduled, isEmpty);
    });

    test('enabled + 无评估 → 调度 now + 14 天', () async {
      await service.setEnabled(true);
      final before = DateTime.now();
      await service.onAppStart();
      expect(notif.scheduled.length, 1);
      final fireAt = notif.scheduled.first.fireAt;
      final days = fireAt.difference(before).inDays;
      // 14 天 ± 1 天
      expect(days, inInclusiveRange(13, 15));
      expect(notif.scheduled.first.days, 14);
      expect(notif.scheduled.first.scaleId, 'phq9');
    });

    test('enabled + 有评估 → 调度 last + 14 天', () async {
      // 用"昨天"作为 lastAssessmentAt，确保 14 天后还在未来，不被 catch-up
      final last = DateTime.now().subtract(const Duration(days: 1));
      await db.insertCheckIn(CheckInsCompanion.insert(
        timestamp: last,
        type: 'phq9',
        note: const Value('{"scale":"phq9","scores":[0],"total":1}'),
      ));
      await service.setEnabled(true);
      await service.onAppStart();
      expect(notif.scheduled.length, 1);
      // 期望: last + 14 天, 锁定 10:00
      final expectedDate = last.add(const Duration(days: 14));
      expect(
        notif.scheduled.first.fireAt,
        DateTime(expectedDate.year, expectedDate.month, expectedDate.day, 10, 0),
      );
    });

    test('有更新评估但 lastAssessmentAt 旧 → 自动同步', () async {
      // 旧 last 是 7/1
      await service.setEnabled(true);
      await service.setLastAssessmentAt(DateTime(2026, 7, 1));
      // 实际 db 写 8/1 又做了一次
      await db.insertCheckIn(CheckInsCompanion.insert(
        timestamp: DateTime(2026, 8, 1, 16, 30),
        type: 'gad7',
        note: const Value('{"scale":"gad7","scores":[0],"total":1}'),
      ));
      await service.onAppStart();
      // lastAssessmentAt 应被覆盖到 8/1 16:30（评估的实际时间）
      expect(
        await service.getLastAssessmentAt(),
        DateTime(2026, 8, 1, 16, 30),
      );
      // 8/1 + 14 = 8/15 10:00
      expect(notif.scheduled.first.fireAt, DateTime(2026, 8, 15, 10, 0));
    });

    test('有更新评估但 lastAssessmentAt 更新 → 不覆盖', () async {
      // last 是 8/15（更新）, db 写 8/1 是更老的
      await service.setEnabled(true);
      await service.setLastAssessmentAt(DateTime(2026, 8, 15));
      await db.insertCheckIn(CheckInsCompanion.insert(
        timestamp: DateTime(2026, 8, 1, 16, 30),
        type: 'phq9',
        note: const Value('{"scale":"phq9","scores":[0],"total":1}'),
      ));
      await service.onAppStart();
      // last 不变（因为 8/1 比 8/15 老）
      expect(await service.getLastAssessmentAt(), DateTime(2026, 8, 15));
      // 8/15 + 14 = 8/29 10:00
      expect(notif.scheduled.first.fireAt, DateTime(2026, 8, 29, 10, 0));
    });
  });

  group('onAssessmentCompleted', () {
    late AppDatabase db;
    late CheckInRepositoryImpl checkInRepo;
    late StubNotificationService notif;
    late AssessmentReminderService service;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      checkInRepo = CheckInRepositoryImpl(db);
      notif = StubNotificationService();
      service = AssessmentReminderService(
        checkInRepo: checkInRepo,
        notificationService: notif,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('disabled → 不调度', () async {
      // 默认 disabled
      await service.onAssessmentCompleted();
      expect(notif.scheduled, isEmpty);
    });

    test('enabled → 写 last = now + 调度 now + 14 天', () async {
      await service.setEnabled(true);
      final before = DateTime.now();
      await service.onAssessmentCompleted();
      expect(notif.scheduled.length, 1);
      final fireAt = notif.scheduled.first.fireAt;
      final days = fireAt.difference(before).inDays;
      expect(days, inInclusiveRange(13, 15));
      // lastAssessmentAt 应该是现场
      final last = await service.getLastAssessmentAt();
      expect(last, isNotNull);
      expect(
        last!.difference(before).inSeconds.abs(),
        lessThan(5),
        reason: 'lastAssessmentAt 应在调用的瞬间',
      );
    });

    test('enabled + 30 天 → 调度 30 天后', () async {
      await service.setEnabled(true);
      await service.setDays(30);
      final before = DateTime.now();
      await service.onAssessmentCompleted();
      final fireAt = notif.scheduled.first.fireAt;
      final days = fireAt.difference(before).inDays;
      expect(days, inInclusiveRange(29, 31));
      expect(notif.scheduled.first.days, 30);
    });
  });

  group('onSettingsChanged', () {
    late AppDatabase db;
    late CheckInRepositoryImpl checkInRepo;
    late StubNotificationService notif;
    late AssessmentReminderService service;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      checkInRepo = CheckInRepositoryImpl(db);
      notif = StubNotificationService();
      service = AssessmentReminderService(
        checkInRepo: checkInRepo,
        notificationService: notif,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('等价于 onAppStart：disabled → cancel', () async {
      // 默认 disabled
      notif.cancelCount = 0;
      await service.onSettingsChanged();
      expect(notif.cancelCount, 1);
      expect(notif.scheduled, isEmpty);
    });

    test('等价于 onAppStart：enabled → 调度', () async {
      await service.setEnabled(true);
      notif.cancelCount = 0;
      notif.scheduled.clear();
      await service.onSettingsChanged();
      expect(notif.scheduled.length, 1);
    });
  });
}
