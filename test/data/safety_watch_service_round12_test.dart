import 'package:chroniccare/core/data/repositories/check_in/check_in_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/contact/contact_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/user_profile/user_profile_repository_impl.dart';
import 'package:chroniccare/core/data/services/safety_alert_builder.dart';
import 'package:chroniccare/core/data/services/safety_alert_sender_impl.dart';
import 'package:chroniccare/core/data/services/safety_config_service.dart';
import 'package:chroniccare/core/data/services/safety_watch_service.dart';
import 'package:chroniccare/core/data/services/sms_service.dart';
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/usecases/dispatch_safety_alert.dart';
import 'package:chroniccare/domain/repositories/contact_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/app_localizations_zh.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'safety_test_helpers.dart';

/// v0.27 round 60 (P0-3 修正): test helper - 拿 test 用的 mock l10n
///
/// `AppLocalizations` 是 abstract, 不能直接 new, 用 `AppLocalizationsZh()` 拿
/// 中文实例。具体文案在 widget test / i18n test 里覆盖, 这里只测业务逻辑。
AppLocalizations _testL10n() => AppLocalizationsZh();

/// 内存数据库 + mock services，跑 SafetyWatch 逻辑测试
void main() {
  // 2026-07-31 联系人软隐藏: 失联通信业务默认 disabled,
  // test 期间临时 enable 走真实业务,tearDown 恢复避免污染其他 test。
  setUp(FeatureFlags.enableForTest);
  tearDown(FeatureFlags.resetForTest);

  // SharedPreferences 静态初始化（SafetyWatch 用）
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  late AppDatabase db;
  late SafetyWatchService safety;
  // v0.27 round 61 (P1-12 拆分收尾): 改用 SafetyConfigService 直接
  // 配置 SharedPreferences, 不再走 safety.setEnabled / setThresholdDays facade
  late SafetyConfigService safetyConfig;
  late MockSmsService sms;
  // v0.32 R109 round 6 part 2: 改 CountingNotificationService (helper) 跟踪
  //   showSafetyAlert 调用次数 + 入参, 替代 R108 跨期 NotificationService
  //   抽象空 mock (无法 track 调用).
  late CountingNotificationService notif;
  late CheckInRepositoryImpl checkInRepo;
  late ContactRepositoryImpl contactRepo;
  late UserProfileRepositoryImpl userProfileRepo;
  late DispatchSafetyAlertUseCase dispatchUseCase;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    checkInRepo = CheckInRepositoryImpl(db);
    contactRepo = ContactRepositoryImpl(db);
    userProfileRepo = UserProfileRepositoryImpl(db);
    sms = MockSmsService();
    notif = CountingNotificationService();
    safetyConfig = SafetyConfigService();
    // v0.32 R109 round 6 part 2: 改用真 use case + SafetyAlertSenderImpl
    //   (sms + notif + config + builder) 替代 R108 NoOp dispatch — 之前 NoOp
    //   早返, 测不到 `notif.alertsShown hasLength(1)` 这种业务行为断言.
    //   这里 sender impl 持有上面 `sms` / `notif` / `safetyConfig`, 走完整
    //   业务链, test 能验真发.
    dispatchUseCase = DispatchSafetyAlertUseCase(
      SafetyAlertSenderImpl(
        smsService: sms,
        notificationService: notif,
        config: safetyConfig,
        builder: const SafetyAlertBuilder(),
      ),
    );
    safety = SafetyWatchService(
      checkInRepo: checkInRepo,
      contactRepo: contactRepo,
      userProfileRepo: userProfileRepo,
      smsService: sms,
      notificationService: notif,
      dispatchUseCase: dispatchUseCase,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> setupProfile({required String name}) async {
    await db.userProfileDao.upsert(
      UserProfilesCompanion.insert(
        // v0.21 Round 23 (P1-24): userName 改 nullable
        userName: Value(name),
        checkInCycleHours: const Value(48),
        firstLaunchAt: DateTime(2026, 1, 1),
      ),
    );
  }

  Future<void> setupContact({required String phone}) async {
    // v0.27 round 61: 改用 safetyConfig 直接写 SharedPreferences
    await db.contactDao
        .insert(ContactsCompanion.insert(name: '妈妈', phone: phone));
  }

  Future<void> checkInAt(DateTime at) async {
    await db.checkInDao.insert(
      CheckInsCompanion.insert(
        timestamp: at,
        type: 'normal',
      ),
    );
  }

  group('SafetyWatch 关闭时', () {
    test('不触发,即使长期没打卡', () async {
      await setupProfile(name: '张三');
      await setupContact(phone: '13800138000');
      // 5 天前打卡
      await checkInAt(DateTime.now().subtract(const Duration(days: 5)));
      // 默认关闭
      final result = await safety.checkNow(l10n: _testL10n());
      expect(result.kind, SafetyCheckKind.disabled);
      expect(sms.sent, isEmpty);
      expect(notif.alertsShown, isEmpty);
    });
  });

  group('SafetyWatch 开启时', () {
    setUp(() async {
      // v0.27 round 61: 改用 safetyConfig 直接写 SharedPreferences
      await safetyConfig.setEnabled(true);
      await safetyConfig.setThresholdDays(2);
    });

    test('正常(<阈值) → ok', () async {
      await setupProfile(name: '张三');
      await setupContact(phone: '13800138000');
      // P0-4 fix: 显式锚定 now,避免跨 midnight (00:00-06:00) 跑时
      // `DateTime.now().subtract(hours: 6)` 落到前一天 → _daysBetween = 1
      // 期望 0 实际 1 → flake。
      final fixedNow = DateTime(2026, 7, 17, 10, 0);
      await checkInAt(fixedNow.subtract(const Duration(hours: 6)));
      final result = await safety.checkNow(l10n: _testL10n(), now: fixedNow);
      expect(result.kind, SafetyCheckKind.ok);
      expect(result.daysSinceLast, 0);
    });

    test('新用户(没数据) → noData', () async {
      await setupProfile(name: '张三');
      // 没联系人 + 没打卡
      final result = await safety.checkNow(l10n: _testL10n());
      expect(result.kind, SafetyCheckKind.noData);
    });

    test('超过阈值 + 有联系人 → 触发告警 + 发短信 + 推本地', () async {
      await setupProfile(name: '张三');
      await setupContact(phone: '13800138000');
      // 3 天前打卡（> 2 阈值）
      await checkInAt(DateTime.now().subtract(const Duration(days: 3)));
      final result = await safety.checkNow(l10n: _testL10n());
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
      final r1 = await safety.checkNow(l10n: _testL10n());
      expect(r1.kind, SafetyCheckKind.alerted);
      // 第二次
      final r2 = await safety.checkNow(l10n: _testL10n());
      expect(r2.kind, SafetyCheckKind.alertedToday);
      expect(sms.sent, hasLength(1), reason: '同一天不应该重复发短信');
    });

    test('DND 时段内 → dndSuppressed', () async {
      await setupProfile(name: '张三');
      await setupContact(phone: '13800138000');
      // 设置 DND 为覆盖现在的小时段
      final hour = DateTime.now().hour;
      await safetyConfig.setDoNotDisturb(
        startHour: hour, // 当前小时
        endHour: (hour + 1) % 24,
      );
      await checkInAt(DateTime.now().subtract(const Duration(days: 3)));
      final result = await safety.checkNow(l10n: _testL10n());
      expect(result.kind, SafetyCheckKind.dndSuppressed);
      expect(sms.sent, isEmpty, reason: 'DND 时段不应该发短信');
    });

    test('超阈值但没联系人 → noContacts', () async {
      await setupProfile(name: '张三');
      // 没添加联系人
      await checkInAt(DateTime.now().subtract(const Duration(days: 3)));
      final result = await safety.checkNow(l10n: _testL10n());
      expect(result.kind, SafetyCheckKind.noContacts);
    });

    test('SMS 全失败 → contactsFailed > 0', () async {
      await setupProfile(name: '张三');
      await setupContact(phone: '13800138000');
      sms.shouldFail = true;
      await checkInAt(DateTime.now().subtract(const Duration(days: 3)));
      final result = await safety.checkNow(l10n: _testL10n());
      expect(result.kind, SafetyCheckKind.alerted);
      expect(result.contactsFailed, 1);
    });
  });

  group('阈值合法性', () {
    test('拒绝 < 1 天的阈值', () async {
      // v0.27 round 61: 改测 SafetyConfigService.setThresholdDays 校验
      expect(
        () => safetyConfig.setThresholdDays(0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('拒绝 > 14 天的阈值', () async {
      expect(
        () => safetyConfig.setThresholdDays(15),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('displayMessageL10n', () {
    test('各 kind 都有非空文案', () {
      // R100: 旧 displayMessage getter 已删, 改测 l10n 版 (编译期强制走翻译)
      for (final kind in SafetyCheckKind.values) {
        final r = SafetyCheckResult(kind: kind);
        expect(
          r.displayMessageL10n(_testL10n()),
          isNotEmpty,
          reason: '$kind 没有 displayMessageL10n 文案',
        );
      }
    });
  });

  group('onCheckIn 集成', () {
    test('onCheckIn 在阈值内 → ok,不发短信', () async {
      await setupProfile(name: '张三');
      await setupContact(phone: '13800138000');
      await safetyConfig.setEnabled(true);
      await safetyConfig.setThresholdDays(2);
      await checkInAt(DateTime.now().subtract(const Duration(hours: 1)));
      final result = await safety.onCheckIn(l10n: _testL10n());
      expect(result.kind, SafetyCheckKind.ok);
    });
  });

  group('v0.17 round 14 (P3-3) 边界 case', () {
    test('阈值 = 1, daysSinceLast = 1 → 触发 (inclusive 边界)', () async {
      await setupProfile(name: '张三');
      await setupContact(phone: '13800138000');
      await safetyConfig.setEnabled(true);
      await safetyConfig.setThresholdDays(1);
      // 24 小时前打卡 (跨 midnight 之后恰好 1 天)
      await checkInAt(DateTime.now().subtract(const Duration(hours: 24)));
      final result = await safety.checkNow(l10n: _testL10n());
      // 阈值 1, days = 1 满足 "days >= threshold" → 触发
      expect(result.kind, SafetyCheckKind.alerted);
      expect(result.daysSinceLast, 1);
    });

    test('阈值 = 1, daysSinceLast = 0 → OK (0 < 1 不触发)', () async {
      await setupProfile(name: '张三');
      await setupContact(phone: '13800138000');
      await safetyConfig.setEnabled(true);
      await safetyConfig.setThresholdDays(1);
      // 1 小时前打卡
      await checkInAt(DateTime.now().subtract(const Duration(hours: 1)));
      final result = await safety.checkNow(l10n: _testL10n());
      expect(result.kind, SafetyCheckKind.ok);
    });

    test('DND 跨天 (22-08): 当前 hour 在范围内 → dndSuppressed', () async {
      await setupProfile(name: '张三');
      await setupContact(phone: '13800138000');
      await safetyConfig.setEnabled(true);
      await safetyConfig.setThresholdDays(2);
      // DND 跨天: 22:00 - 08:00
      // 拿当前 hour,如果是 22-23 或 0-7,直接是 dnd
      // 否则选一个 in-range 区间
      final hour = DateTime.now().hour;
      int start;
      int end;
      if (hour >= 22 || hour < 8) {
        // 当前已经在 dnd 跨天区间,用现有 22-08
        start = 22;
        end = 8;
      } else {
        // 白天: 用 hour 跨天包住现在 (e.g. hour=15, 设 14-16 同日, 但 14<16 是同一天
        // 我们用 hour-1 到 hour+1 跨天: hour-1 ~ 24 + hour+1
        start = (hour - 1 + 24) % 24;
        end = (hour + 1) % 24;
        // start > end 必为跨天
      }
      await safetyConfig.setDoNotDisturb(startHour: start, endHour: end);
      await checkInAt(DateTime.now().subtract(const Duration(days: 3)));
      final result = await safety.checkNow(l10n: _testL10n());
      expect(result.kind, SafetyCheckKind.dndSuppressed);
      expect(sms.sent, isEmpty);
    });
  });

  group('v0.23 round 38 (P0-3) — _contactRepo.watchAll().first timeout 降级', () {
    test('watchAll() 永不 emit → 5s timeout → 降级 noContacts (用 50ms 注入)',
        () async {
      // 注入一个永不 emit 的 stream,timeout 50ms 触发
      final hangingRepo = _HangingContactRepo();
      final localSafety = SafetyWatchService(
        checkInRepo: checkInRepo,
        contactRepo: hangingRepo,
        userProfileRepo: userProfileRepo,
        smsService: sms,
        dispatchUseCase: NoOpDispatchSafetyAlertUseCase(),
        notificationService: notif,
        contactWatchTimeout: const Duration(milliseconds: 50),
      );
      await setupProfile(name: '张三');
      // 触发条件: 3 天没打卡
      await checkInAt(DateTime.now().subtract(const Duration(days: 3)));
      await safetyConfig.setEnabled(true);
      await safetyConfig.setThresholdDays(2);
      // 不应 hang,50ms 内返 noContacts
      final result = await localSafety.checkNow(l10n: _testL10n());
      expect(result.kind, SafetyCheckKind.noContacts);
      expect(sms.sent, isEmpty); // 没真发
    });

    test('watchAll() 抛异常 → catch 降级 noContacts', () async {
      final errorRepo = _ErrorContactRepo();
      final localSafety = SafetyWatchService(
        checkInRepo: checkInRepo,
        contactRepo: errorRepo,
        userProfileRepo: userProfileRepo,
        smsService: sms,
        dispatchUseCase: NoOpDispatchSafetyAlertUseCase(),
        notificationService: notif,
        contactWatchTimeout: const Duration(milliseconds: 50),
      );
      await setupProfile(name: '张三');
      await checkInAt(DateTime.now().subtract(const Duration(days: 3)));
      await safetyConfig.setEnabled(true);
      await safetyConfig.setThresholdDays(2);
      final result = await localSafety.checkNow(l10n: _testL10n());
      expect(result.kind, SafetyCheckKind.noContacts);
      expect(sms.sent, isEmpty);
    });
  });
}

/// 永不 emit 的 ContactRepository mock
class _HangingContactRepo implements ContactRepository {
  @override
  Stream<List<ContactEntity>> watchAll() async* {
    // 永不 emit
    await Future<void>.delayed(const Duration(days: 1));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// emit 异常的 ContactRepository mock
class _ErrorContactRepo implements ContactRepository {
  @override
  Stream<List<ContactEntity>> watchAll() async* {
    throw StateError('mock db lock');
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  bool get isProductionReady => true;

  @override
  Future<bool> send({
    required String to,
    required String body,
    String? templateId,
  }) async {
    return true;
  }
}


