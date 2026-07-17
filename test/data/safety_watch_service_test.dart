import 'package:chroniccare/data/repositories/check_in_repository_impl.dart';
import 'package:chroniccare/data/repositories/contact_repository_impl.dart';
import 'package:chroniccare/data/repositories/user_profile_repository_impl.dart';
import 'package:chroniccare/data/services/notification_service.dart';
import 'package:chroniccare/data/services/safety_watch_service.dart';
import 'package:chroniccare/data/services/sms_service.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/data/database/app_database.dart';

/// 内存数据库 + mock services，跑 SafetyWatch 逻辑测试
void main() {
  // SharedPreferences 静态初始化（SafetyWatch 用）
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  late AppDatabase db;
  late SafetyWatchService safety;
  late MockSmsService sms;
  late StubNotificationService notif;
  late CheckInRepositoryImpl checkInRepo;
  late ContactRepositoryImpl contactRepo;
  late UserProfileRepositoryImpl userProfileRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    checkInRepo = CheckInRepositoryImpl(db);
    contactRepo = ContactRepositoryImpl(db);
    userProfileRepo = UserProfileRepositoryImpl(db);
    sms = MockSmsService();
    notif = StubNotificationService();
    safety = SafetyWatchService(
      checkInRepo: checkInRepo,
      contactRepo: contactRepo,
      userProfileRepo: userProfileRepo,
      smsService: sms,
      notificationService: notif,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> setupProfile({required String name}) async {
    await db.upsertUserProfile(UserProfilesCompanion.insert(
      userName: name,
      checkInCycleHours: const Value(48),
      firstLaunchAt: DateTime(2026, 1, 1),
    ));
  }

  Future<void> setupContact({required String phone}) async {
    await db.insertContact(ContactsCompanion.insert(name: '妈妈', phone: phone));
  }

  Future<void> checkInAt(DateTime at) async {
    await db.insertCheckIn(CheckInsCompanion.insert(
      timestamp: at,
      type: 'normal',
    ));
  }

  group('SafetyWatch 关闭时', () {
    test('不触发,即使长期没打卡', () async {
      await setupProfile(name: '张三');
      await setupContact(phone: '13800138000');
      // 5 天前打卡
      await checkInAt(DateTime.now().subtract(const Duration(days: 5)));
      // 默认关闭
      final result = await safety.checkNow();
      expect(result.kind, SafetyCheckKind.disabled);
      expect(sms.sent, isEmpty);
      expect(notif.alertsShown, isEmpty);
    });
  });

  group('SafetyWatch 开启时', () {
    setUp(() async {
      await safety.setEnabled(true);
      await safety.setThresholdDays(2);
    });

    test('正常(<阈值) → ok', () async {
      await setupProfile(name: '张三');
      await setupContact(phone: '13800138000');
      await checkInAt(DateTime.now().subtract(const Duration(hours: 6)));
      final result = await safety.checkNow();
      expect(result.kind, SafetyCheckKind.ok);
      expect(result.daysSinceLast, 0);
    });

    test('新用户(没数据) → noData', () async {
      await setupProfile(name: '张三');
      // 没联系人 + 没打卡
      final result = await safety.checkNow();
      expect(result.kind, SafetyCheckKind.noData);
    });

    test('超过阈值 + 有联系人 → 触发告警 + 发短信 + 推本地', () async {
      await setupProfile(name: '张三');
      await setupContact(phone: '13800138000');
      // 3 天前打卡（> 2 阈值）
      await checkInAt(DateTime.now().subtract(const Duration(days: 3)));
      final result = await safety.checkNow();
      expect(result.kind, SafetyCheckKind.alerted);
      expect(result.daysSinceLast, 3);
      expect(result.contactsNotified, 1);
      expect(sms.sent, hasLength(1));
      expect(sms.sent.first.to, '13800138000');
      expect(sms.sent.first.body, contains('张三'));
      expect(sms.sent.first.body, contains('3 天'));
      expect(notif.alertsShown, hasLength(1));
      expect(notif.alertsShown.first.daysWithoutCheckIn, 3);
    });

    test('同一天第二次触发 → alertedToday（不重复发）', () async {
      await setupProfile(name: '张三');
      await setupContact(phone: '13800138000');
      await checkInAt(DateTime.now().subtract(const Duration(days: 3)));
      final r1 = await safety.checkNow();
      expect(r1.kind, SafetyCheckKind.alerted);
      // 第二次
      final r2 = await safety.checkNow();
      expect(r2.kind, SafetyCheckKind.alertedToday);
      expect(sms.sent, hasLength(1),
          reason: '同一天不应该重复发短信');
    });

    test('DND 时段内 → dndSuppressed', () async {
      await setupProfile(name: '张三');
      await setupContact(phone: '13800138000');
      // 设置 DND 为覆盖现在的小时段
      final hour = DateTime.now().hour;
      await safety.setDoNotDisturb(
        startHour: hour, // 当前小时
        endHour: (hour + 1) % 24,
      );
      await checkInAt(DateTime.now().subtract(const Duration(days: 3)));
      final result = await safety.checkNow();
      expect(result.kind, SafetyCheckKind.dndSuppressed);
      expect(sms.sent, isEmpty,
          reason: 'DND 时段不应该发短信');
    });

    test('超阈值但没联系人 → noContacts', () async {
      await setupProfile(name: '张三');
      // 没添加联系人
      await checkInAt(DateTime.now().subtract(const Duration(days: 3)));
      final result = await safety.checkNow();
      expect(result.kind, SafetyCheckKind.noContacts);
    });

    test('SMS 全失败 → contactsFailed > 0', () async {
      await setupProfile(name: '张三');
      await setupContact(phone: '13800138000');
      sms.shouldFail = true;
      await checkInAt(DateTime.now().subtract(const Duration(days: 3)));
      final result = await safety.checkNow();
      expect(result.kind, SafetyCheckKind.alerted);
      expect(result.contactsFailed, 1);
    });
  });

  group('阈值合法性', () {
    test('拒绝 < 1 天的阈值', () async {
      expect(
        () => safety.setThresholdDays(0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('拒绝 > 14 天的阈值', () async {
      expect(
        () => safety.setThresholdDays(15),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('displayMessage', () {
    test('各 kind 都有非空文案', () {
      for (final kind in SafetyCheckKind.values) {
        final r = SafetyCheckResult(kind: kind);
        expect(r.displayMessage, isNotEmpty,
            reason: '$kind 没有 displayMessage');
      }
    });
  });

  group('onCheckIn 集成', () {
    test('onCheckIn 在阈值内 → ok,不发短信', () async {
      await setupProfile(name: '张三');
      await setupContact(phone: '13800138000');
      await safety.setEnabled(true);
      await safety.setThresholdDays(2);
      await checkInAt(DateTime.now().subtract(const Duration(hours: 1)));
      final result = await safety.onCheckIn();
      expect(result.kind, SafetyCheckKind.ok);
    });
  });
}

// ============== Test Doubles ==============

class MockSmsService extends SmsService {
  MockSmsService() : super(provider: MockSms());

  bool shouldFail = false;
  final List<({String to, String body})> sent = [];

  @override
  Future<SmsResult> send({
    required String to,
    required String body,
  }) async {
    if (shouldFail) return SmsResult.fail('mock fail');
    sent.add((to: to, body: body));
    return SmsResult.ok();
  }
}

class MockSms implements SmsProvider {
  @override
  String get name => 'mock-test';

  @override
  Future<bool> send({
    required String to,
    required String body,
    String? templateId,
  }) async {
    return true;
  }
}

class StubNotificationService implements NotificationService {
  final List<({String userName, int daysWithoutCheckIn, DateTime? lastCheckIn})>
      alertsShown = [];

  @override
  Future<void> showSafetyAlert({
    required String userName,
    required int daysWithoutCheckIn,
    required DateTime? lastCheckIn,
  }) async {
    alertsShown.add((
      userName: userName,
      daysWithoutCheckIn: daysWithoutCheckIn,
      lastCheckIn: lastCheckIn,
    ));
  }

  // 其它方法 stub 掉,测试不调
  @override
  Future<void> init() async {}
  @override
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {}
  @override
  Future<void> cancelAll() async {}
  @override
  Future<void> rescheduleMedicationReminders(List<dynamic> medications) async {}
  @override
  Future<void> scheduleSoftReminder({int hour = 10, int minute = 0}) async {}
  @override
  Future<void> cancelSoftReminder() async {}
  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {}
  @override
  Future<void> snoozeOnce({
    required int medicationId,
    required int minutes,
    String? title,
    String? body,
  }) async {}
  @override
  Future<void> cancelSnoozeForMedication(int medicationId) async {}
  @override
  Future<void> cancelAllSnoozes() async {}
  @override
  Future<void> updateBadgeCount(int count) async {}
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
