// v0.16 (Round 19B) regression test for implicit sort assumption
//
// 之前 reminder_scheduler.dart 和 safety_watch_service.dart 都有：
//   final allCheckIns = await repo.watchAll().first;
//   final normalCheckIns = allCheckIns.where((c) => c.isNormal).toList();
//   final lastCheckIn = normalCheckIns.first.timestamp;  // 假设 DESC!
//
// 修法：显式 sort
//   normalCheckIns.sort((a, b) => b.timestamp.compareTo(a.timestamp));
//   final lastCheckIn = normalCheckIns.first.timestamp;
//
// 这些测试：
// 1. 间接验证：模拟一个 mock repo 返 **unsorted** 数据
// 2. 调 service 后看 lastCheckIn 是否仍是最新（不是 first in order）
//
// 难处：reminder_scheduler / safety_watch 内部 await IO，无法直接 assert "用了 latest"。
// 改测法：直接走完整流程，看 SMS body / alert message 里的 daysSinceLast 是否基于 latest。
//
// 假设数据：[5 天前, 3 天前, 1 天前]（unsorted）
// 修前：如果 mock 返 unsorted 顺序，first = 5 天前 → daysSinceLast 报 5（错的，应该是 1）
// 修后：显式 sort → first = 1 天前 → daysSinceLast 报 1（对）
import 'package:chroniccare/core/data/repositories/check_in/check_in_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/contact/contact_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/user_profile/user_profile_repository_impl.dart';
import 'package:chroniccare/core/data/services/safety_alert_sender_impl.dart';
import 'package:chroniccare/core/data/services/safety_config_service.dart';
import 'package:chroniccare/core/data/services/safety_watch_service.dart';
import 'package:chroniccare/core/data/services/sms_service.dart';
import 'package:chroniccare/domain/repositories/safety_alert_sender.dart';
import 'package:chroniccare/domain/usecases/dispatch_safety_alert.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/app_localizations_zh.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/feature_flags.dart';
import 'safety_test_helpers.dart';

/// v0.27 round 60 (P0-3 修正): test helper
AppLocalizations _testL10n() => AppLocalizationsZh();

/// v0.32 R112 (AR-16): entry point 改拿 SafetyAlertL10nResolver tear-off
/// 闭包 (data 0 依赖 l10n/ 生成 ARB)。
SafetyAlertL10nResolver _testResolver() {
  final l10n = _testL10n();
  return SafetyAlertL10nResolver(
    titleFor: l10n.safetyAlertTitle,
    bodySent: l10n.safetyAlertBodySent,
    bodyMocked: l10n.safetyAlertBodyMocked,
    bodyFailed: l10n.safetyAlertBodyFailed,
    neverCheckIn: () => l10n.safetyAlertNeverCheckIn,
  );
}

void main() {
  // 2026-07-31 联系人软隐藏: 失联通信业务默认 disabled,
  // test 期间临时 enable 走真实业务,tearDown 恢复避免污染其他 test。
  setUp(FeatureFlags.enableForTest);
  tearDown(FeatureFlags.resetForTest);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  late AppDatabase db;
  late SafetyWatchService safety;
  // v0.27 round 61 (P1-12 拆分收尾): 改用 SafetyConfigService 直接配置
  late SafetyConfigService safetyConfig;
  late MockSmsService sms;
  late CountingNotificationService notif;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final checkInRepo = CheckInRepositoryImpl(db);
    final contactRepo = ContactRepositoryImpl(db);
    final userProfileRepo = UserProfileRepositoryImpl(db);
    sms = MockSmsService();
    // R109 round 6 part 2: 改 CountingNotificationService (helper) 替代 R108
    //   跨期空 NotificationService (R109 round 2 改 showSafetyAlert 签名后
    //   失效). 真 use case 委派 sender impl 调 notif.showSafetyAlert,
    //   alertsShown 跟踪记录.
    notif = CountingNotificationService();
    safetyConfig = SafetyConfigService();
    // v0.32 R109 round 6 part 2: 用真 DispatchSafetyAlertUseCase + sender impl,
    //   test 目的是验 lastCheckIn 排序, 必须走真发才能 sms.sent.first.body 含
    //   "3 天" (NoOp 早返连 SMS 都不发, test 失效).
    final dispatchUseCase = DispatchSafetyAlertUseCase(
      SafetyAlertSenderImpl(
        smsService: sms,
        notificationService: notif,
            config: safetyConfig,
      ),
      // R110 round 3: flag 构造注入, 构造时动态读 (test enableForTest → true)
      emergencyContactEnabled: FeatureFlags.emergencyContactEnabled,
    );
    safety = SafetyWatchService(
      checkInRepo: checkInRepo,
      contactRepo: contactRepo,
      userProfileRepo: userProfileRepo,
      dispatchUseCase: dispatchUseCase,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('v0.16 round 19B: explicit sort, no implicit DESC assumption', () {
    test('SafetyWatch 即使数据插入顺序不是按时间,lastCheckIn 仍是最新', () async {
      // 准备：profile + contact + 启用 + 阈值 2 天
      await db.userProfileDao.upsert(
        UserProfilesCompanion.insert(
          // v0.21 Round 23 (P1-24): userName 改 nullable
          userName: const Value('张三'),
          checkInCycleHours: const Value(48),
          firstLaunchAt: DateTime(2026, 1, 1),
        ),
      );
      await db.contactDao.insert(
        ContactsCompanion.insert(name: '妈妈', phone: '13800138000'),
      );
      // v0.27 round 61: 改用 safetyConfig 直接写 SharedPreferences
      await safetyConfig.setEnabled(true);
      await safetyConfig.setThresholdDays(2);

      final now = DateTime.now();
      // **故意 unsorted** 顺序插入 3 条打卡
      // 修前：watchAll 返插入顺序 [old, middle, latest]
      //   first = old → daysSinceLast = 5+ → 触发告警（错!）
      // 修后：显式 sort → first = latest → daysSinceLast = 0 → 不触发（对）
      await db.checkInDao.insert(
        CheckInsCompanion.insert(
          timestamp: now.subtract(const Duration(days: 5)),
          type: 'normal',
        ),
      );
      await db.checkInDao.insert(
        CheckInsCompanion.insert(
          timestamp: now.subtract(const Duration(days: 3)),
          type: 'normal',
        ),
      );
      await db.checkInDao.insert(
        CheckInsCompanion.insert(
          timestamp: now.subtract(const Duration(hours: 1)), // 最新
          type: 'normal',
        ),
      );

      final result = await safety.checkNow(l10nResolver: _testResolver());
      // latest 是 1h 前 → < 2 天阈值 → ok
      expect(result.kind, SafetyCheckKind.ok, reason: 'latest = 1h 前应 < 2 天阈值');
      expect(
        result.daysSinceLast,
        0,
        reason: 'daysSinceLast 应基于最新打卡（1h 前=0 天）',
      );

      // SMS 不应发
      expect(sms.sent, isEmpty, reason: '最新打卡是 1h 前，不应触发告警');
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


