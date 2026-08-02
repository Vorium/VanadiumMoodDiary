// v0.27 round 66: FeatureFlags 守卫 + 联系人软隐藏业务暂停回归 test
//
// 验证内容:
// 1. FeatureFlags.emergencyContactEnabled 默认 false (生产安全)
// 2. SafetyWatchService._checkAndAlert 在 flag=false 时早返 disabled
//    (3 个入口: onAppStart / onCheckIn / checkNow 都过这道关)
// 3. SafetyAlertDispatcher.dispatchAlert 在 flag=false 时早返空 outcome
//    (双层防御, 防止 caller 绕过 facade 直接调 dispatcher)
//
// 配合 R66 (2026-07-31 联系人软隐藏) 落地。
// 后续 R55 真接阿里云 SMS 时, 把 flag 改 true 即可重新启用全部失联通信。
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/core/data/repositories/check_in/check_in_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/contact/contact_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/user_profile/user_profile_repository_impl.dart';
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/core/data/services/safety_alert_dispatcher.dart';
import 'package:chroniccare/core/data/services/safety_config_service.dart';
import 'package:chroniccare/core/data/services/safety_watch_service.dart';
import 'package:chroniccare/core/data/services/sms_service.dart';
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/app_localizations_zh.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/data/database/app_database.dart';

/// v0.27 round 66 helper
AppLocalizations _testL10n() => AppLocalizationsZh();

void main() {
  // R66 设计: 整个文件测 production (flag=false) 行为, **不** enableForTest。
  // override FeatureFlags.resetForTest 是为了防 setUp 之前有别的 test leak。
  setUp(() {
    FeatureFlags.resetForTest();
  });

  group('FeatureFlags 默认值 (R66 联系人软隐藏)', () {
    test('emergencyContactEnabled 默认 false (生产安全)', () {
      // resetForTest 后, flag 应该是 production 默认值
      expect(
        FeatureFlags.emergencyContactEnabled,
        isFalse,
        reason: 'R66 设计: 失联通信业务默认 paused, 不会给联系人发任何 SMS',
      );
    });
  });

  group('SafetyWatchService 入口在 flag=false 时早返 disabled', () {
    // R66: 测 facade 入口的 flag 守卫, 用 in-memory DB + mock service
    // 让 facade 内部逻辑即使跑也能正常返回 (但 flag 早返截胡, 根本不会跑)
    late AppDatabase db;
    late SafetyWatchService service;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      service = SafetyWatchService(
        checkInRepo: CheckInRepositoryImpl(db),
        contactRepo: ContactRepositoryImpl(db),
        userProfileRepo: UserProfileRepositoryImpl(db),
        smsService: SmsService(),
        notificationService: _CountingNotificationService(),
        contactWatchTimeout: const Duration(milliseconds: 50),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('onAppStart → kind = disabled (不查 config / 不查 contacts)', () async {
      final result = await service.onAppStart(l10n: _testL10n());
      expect(
        result.kind,
        SafetyCheckKind.disabled,
        reason: 'R66: flag=false 时 facade 入口早返, 不走 detector / dispatcher',
      );
    });

    test('onCheckIn → kind = disabled', () async {
      final result = await service.onCheckIn(l10n: _testL10n());
      expect(result.kind, SafetyCheckKind.disabled);
    });

    test('checkNow → kind = disabled', () async {
      final result =
          await service.checkNow(l10n: _testL10n(), now: DateTime(2026, 7, 31));
      expect(result.kind, SafetyCheckKind.disabled);
    });
  });

  group('SafetyAlertDispatcher.dispatchAlert 在 flag=false 时早返空 outcome', () {
    test('空 outcome + 不发 SMS + 不调 showSafetyAlert + 不写 audit log', () async {
      // 传 mock 计数 service, flag 早返应该全 0
      final notifService = _CountingNotificationService();
      final config = _CountingConfigService();
      final dispatcher = SafetyAlertDispatcher(
        smsService: SmsService(),
        notificationService: notifService,
        config: config,
      );

      final result = await dispatcher.dispatchAlert(
        contacts: [
          _makeContact(id: 1, phone: '13800000001'),
        ],
        userName: '张三',
        daysSinceLast: 3,
        lastCheckIn: DateTime(2026, 7, 20),
        effectiveNow: DateTime(2026, 7, 23, 10, 0),
        trigger: 'threshold',
        l10n: _testL10n(),
      );

      expect(result.smsOk, 0);
      expect(result.smsFail, 0);
      expect(result.smsMock, 0);
      expect(
        notifService.showSafetyAlertCalls,
        0,
        reason: 'R66: flag=false 时不推本地通知',
      );
      expect(
        config.setLastAlertAtCalls,
        0,
        reason: 'R66: flag=false 时不写 audit log (同日重复检测)',
      );
    });
  });
}

// ============== Mock 服务 (跟 dispatcher_round61c3_test 同模式) ==============

/// 计数 showSafetyAlert 调几次 — 跳过父类 init() timezone/plugin 副作用
class _CountingNotificationService extends NotificationService {
  int showSafetyAlertCalls = 0;
  _CountingNotificationService() : super();
  @override
  Future<void> showSafetyAlert({
    String? userName,
    required int daysWithoutCheckIn,
    required DateTime? lastCheckIn,
    required SmsDispatchOutcome outcome,
    required AppLocalizations l10n,
  }) async {
    showSafetyAlertCalls++;
  }
}

/// 计数 setLastAlertAt 调几次 — 跳过 SharedPreferences 静态 API
class _CountingConfigService extends SafetyConfigService {
  int setLastAlertAtCalls = 0;
  @override
  Future<void> setLastAlertAt(DateTime when) async {
    setLastAlertAtCalls++;
  }
}

/// R66 helper: 构造 mock ContactEntity
ContactEntity _makeContact({
  required int id,
  required String phone,
}) {
  return ContactEntity(
    id: id,
    name: '测试联系人 $id',
    phone: phone,
    sortOrder: 0,
    isActive: true,
  );
}
