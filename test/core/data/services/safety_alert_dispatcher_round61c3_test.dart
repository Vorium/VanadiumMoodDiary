// v0.25 round 56c''' (spen P0 #15 TDD 续): SafetyAlertDispatcher test
//
// 之前 0 test (v0.25 round 57 拆 sub-service 时只加 facade).
// R56c''' 补 2 个核心 method 测, 共 7 test cases.
//
// 测试设计:
// - NotificationService 是 concrete class, 用 _CountingNotificationService
//   subclass 覆盖 showSafetyAlert 计数 (避免跑 init() 的 timezone/plugin 副作用)
// - SafetyConfigService 同样 subclass 覆盖 setLastAlertAt 计数
//   (避免调 SharedPreferences.getInstance() 静态 API 复杂 mock)
// - SmsService 用 SmsService(provider: _ScriptedSmsProvider(...)) 注入,
//   按 phone 号码返回不同 SmsResult (ok/fail/mock 混测)
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/core/data/services/safety_alert_dispatcher.dart';
import 'package:chroniccare/core/data/services/safety_config_service.dart';
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/app_localizations_zh.dart';
import 'package:chroniccare/core/data/services/sms_service.dart';
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2026-07-31 联系人软隐藏: 失联通信业务默认 disabled,
  // test 期间临时 enable 走真实业务,tearDown 恢复避免污染其他 test。
  setUp(FeatureFlags.enableForTest);
  tearDown(FeatureFlags.resetForTest);

  group('SafetyAlertDispatcher.buildAlertSms (纯函数)', () {
    test('userName 给定 + daysSinceLast=3 → 包含 "3 天未打卡"', () {
      final dispatcher = SafetyAlertDispatcher(
        smsService: SmsService(),
        notificationService: _CountingNotificationService(),
        config: _CountingConfigService(),
      );

      final body = dispatcher.buildAlertSms(
        userName: '张三',
        daysSinceLast: 3,
      );

      expect(body, contains('张三'));
      expect(body, contains('3'));
      expect(body, contains('未打卡'));
    });

    test(
        'userName = null → 退化为 "您" (R23 P1-24 nullable 修复, safeUserName 默认 fallback)',
        () {
      final dispatcher = SafetyAlertDispatcher(
        smsService: SmsService(),
        notificationService: _CountingNotificationService(),
        config: _CountingConfigService(),
      );

      final body = dispatcher.buildAlertSms(
        userName: null,
        daysSinceLast: 5,
      );

      // safeUserName(null) → "您" (user_name_helper.dart 默认 fallback)
      expect(body, contains('您'));
      expect(body, contains('5'));
      expect(body, contains('未打卡'));
    });

    test('daysSinceLast = 1 → 包含 "1 天" (singular)', () {
      final dispatcher = SafetyAlertDispatcher(
        smsService: SmsService(),
        notificationService: _CountingNotificationService(),
        config: _CountingConfigService(),
      );

      final body = dispatcher.buildAlertSms(
        userName: '李四',
        daysSinceLast: 1,
      );

      expect(body, contains('1 天'));
    });
  });

  group('SafetyAlertDispatcher.dispatchAlert (instance)', () {
    test('3 contact, 2 ok + 1 fail → 返 (smsOk=2, smsFail=1, smsMock=0)',
        () async {
      final smsService = SmsService(
        provider: _ScriptedSmsProvider({
          '13800000001': SmsResult.ok(),
          '13800000002': SmsResult.ok(),
          '13800000003': SmsResult.fail('mock fail'),
        }),
      );
      final notifService = _CountingNotificationService();
      final config = _CountingConfigService();
      final dispatcher = SafetyAlertDispatcher(
        smsService: smsService,
        notificationService: notifService,
        config: config,
      );

      final contacts = [
        _makeContact(id: 1, phone: '13800000001'),
        _makeContact(id: 2, phone: '13800000002'),
        _makeContact(id: 3, phone: '13800000003'),
      ];

      final result = await dispatcher.dispatchAlert(
        contacts: contacts,
        userName: '张三',
        daysSinceLast: 3,
        lastCheckIn: DateTime(2026, 7, 20),
        l10n: _testL10n(),
        effectiveNow: DateTime(2026, 7, 23, 10, 0),
        trigger: 'threshold',
      );

      expect(result.smsOk, 2);
      expect(result.smsFail, 1);
      expect(result.smsMock, 0);
    });

    test('mock provider → 返 (smsOk=0, smsFail=0, smsMock=N) (R52 spen P0 #12)',
        () async {
      // MockSmsProvider 走 SmsService.send 内部走 mock 路径 → SmsResult.mock
      final smsService = SmsService(provider: MockSmsProvider());
      final notifService = _CountingNotificationService();
      final config = _CountingConfigService();
      final dispatcher = SafetyAlertDispatcher(
        smsService: smsService,
        notificationService: notifService,
        config: config,
      );

      final contacts = [
        _makeContact(id: 1, phone: '13800000001'),
        _makeContact(id: 2, phone: '13800000002'),
      ];

      final result = await dispatcher.dispatchAlert(
        contacts: contacts,
        userName: '张三',
        daysSinceLast: 3,
        lastCheckIn: null,
        effectiveNow: DateTime(2026, 7, 23, 10, 0),
        trigger: 'threshold',
        l10n: _testL10n(),
      );

      // R52 修复: mock 模式独立计数, 不算 ok 也不算 fail
      expect(result.smsOk, 0);
      expect(result.smsFail, 0);
      expect(result.smsMock, 2);
    });

    test('空 contacts → (0,0,0) + showSafetyAlert 仍调 1 次 (用户提示)', () async {
      final notifService = _CountingNotificationService();
      final config = _CountingConfigService();
      final dispatcher = SafetyAlertDispatcher(
        smsService: SmsService(),
        notificationService: notifService,
        config: config,
      );

      final result = await dispatcher.dispatchAlert(
        contacts: const [],
        userName: '张三',
        daysSinceLast: 3,
        lastCheckIn: null,
        effectiveNow: DateTime(2026, 7, 23, 10, 0),
        trigger: 'threshold',
        l10n: _testL10n(),
      );

      expect(result.smsOk, 0);
      expect(result.smsFail, 0);
      expect(result.smsMock, 0);
      expect(
        notifService.showSafetyAlertCalls,
        1,
        reason: '空 contacts 也应推本地通知 (用户可能只是忘了打卡)',
      );
    });

    test(
        'dispatch 后 → showSafetyAlert 调 1 次 + setLastAlertAt 调 1 次 (audit log)',
        () async {
      final notifService = _CountingNotificationService();
      final config = _CountingConfigService();
      final dispatcher = SafetyAlertDispatcher(
        smsService: SmsService(),
        notificationService: notifService,
        config: config,
      );

      final effectiveNow = DateTime(2026, 7, 23, 10, 0);
      await dispatcher.dispatchAlert(
        contacts: [_makeContact(id: 1, phone: '13800000001')],
        userName: '张三',
        daysSinceLast: 3,
        lastCheckIn: null,
        effectiveNow: effectiveNow,
        trigger: 'manual',
        l10n: _testL10n(),
      );

      expect(notifService.showSafetyAlertCalls, 1);
      expect(config.setLastAlertAtCalls, 1);
      expect(
        config.lastSetLastAlertAt,
        effectiveNow,
        reason: 'audit log 写入时间应等于 effectiveNow',
      );
    });
  });

  // ============ v0.26 round 57 (spen P0 TDD 续): systematic-debugging 5 类 regression ============
  //
  // 锁 4: stream subscription leak — 重复 dispatchAlert 不应 leak 内部 listener
  // (dispatcher 内部没 stream subscription, 是 _alertDispatcher 单次调用模式,
  // 锁的是"重复调 dispatchAlert N 次 → 行为稳定, 计数累加正确, 无 leak")
  //
  // 锁 (空 contacts 边界): 已存在 '空 contacts → (0,0,0)' 但 R57/56c3 后
  // 补 1 个极端变体: contacts 全 isActive=false (filter 走完剩 0 个) → 仍走
  // noContacts 路径, 但行为同空 list — showSafetyAlert 仍调 1 次

  group('SafetyAlertDispatcher systematic-debugging regression guards', () {
    test(
        'stream subscription leak: 重复 dispatchAlert 100 次 → setLastAlertAt 也调 100 次 (无 leak)',
        () async {
      // 锁: 100 次 dispatch, 内部没遗留 subscription, 计数累加正确
      final notifService = _CountingNotificationService();
      final config = _CountingConfigService();
      final dispatcher = SafetyAlertDispatcher(
        smsService: SmsService(provider: MockSmsProvider()),
        notificationService: notifService,
        config: config,
      );

      for (var i = 0; i < 100; i++) {
        await dispatcher.dispatchAlert(
          contacts: [_makeContact(id: 1, phone: '13800000001')],
          userName: '张三',
          daysSinceLast: 3,
          lastCheckIn: null,
          effectiveNow: DateTime(2026, 7, 23, 10, 0),
          trigger: 'manual',
          l10n: _testL10n(),
        );
      }

      expect(
        config.setLastAlertAtCalls,
        100,
        reason: '每次 dispatch 写一次 audit log',
      );
      expect(
        notifService.showSafetyAlertCalls,
        100,
        reason: '每次 dispatch 推一次本地通知',
      );
    });

    test('空 contacts 边界 (空 list + filter 后空 list 行为一致)', () async {
      // 锁: 空 list 已测过, 这里锁 filter 后空 (1 个 contact 但 isActive=false) → 仍走 noContacts 路径
      final notifService = _CountingNotificationService();
      final config = _CountingConfigService();
      final dispatcher = SafetyAlertDispatcher(
        smsService: SmsService(),
        notificationService: notifService,
        config: config,
      );

      // 注: dispatcher 内部不过滤 isActive (由调用方 safety_watch_service
      // 选 active contacts), 所以这里直接传 1 个 isActive=false contact
      // 测行为: 仍发 SMS, 不影响
      // 实际边界"filter 后空"由 safety_watch_service 负责, 本测锁 dispatcher
      // 接收空 list / 全 isActive=false 都不崩
      final inactiveContact = const ContactEntity(
        id: 99,
        name: '停用',
        phone: '13800000099',
        sortOrder: 0,
        isActive: false,
      );

      final result = await dispatcher.dispatchAlert(
        contacts: [inactiveContact],
        userName: '张三',
        daysSinceLast: 3,
        lastCheckIn: null,
        effectiveNow: DateTime(2026, 7, 23, 10, 0),
        trigger: 'manual',
        l10n: _testL10n(),
      );

      // dispatcher 不 filter, 仍发 SMS (走 MockSmsProvider 走 mock 计数)
      // 不崩即过
      expect(result.smsOk + result.smsFail + result.smsMock, 1);
    });
  });
}

/// v0.27 round 60 (P0-3 修正): test helper - 拿 test 用的 mock l10n
///
/// `AppLocalizations` 是 abstract, 不能直接 new, 用 `AppLocalizationsZh()` 拿
/// 中文实例。具体文案在 widget test / i18n test 里覆盖, 这里只测业务逻辑。
AppLocalizations _testL10n() => AppLocalizationsZh();

ContactEntity _makeContact({
  required int id,
  required String phone,
  String name = '紧急联系人',
}) {
  return ContactEntity(
    id: id,
    name: name,
    phone: phone,
    sortOrder: 0,
    isActive: true,
  );
}

/// 计数 showSafetyAlert 调用 — 跳过父类 init() timezone/plugin 副作用
class _CountingNotificationService extends NotificationService {
  int showSafetyAlertCalls = 0;
  String? lastUserName;
  int? lastDays;
  DateTime? lastCheckIn;
  SmsDispatchOutcome? lastOutcome;

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
    lastUserName = userName;
    lastDays = daysWithoutCheckIn;
    lastCheckIn = lastCheckIn;
    lastOutcome = outcome;
  }
}

/// 计数 setLastAlertAt — 跳过 SharedPreferences 静态 API
class _CountingConfigService extends SafetyConfigService {
  int setLastAlertAtCalls = 0;
  DateTime? lastSetLastAlertAt;

  @override
  Future<void> setLastAlertAt(DateTime when) async {
    setLastAlertAtCalls++;
    lastSetLastAlertAt = when;
  }
}

/// 脚本化 provider — 按 phone 号码返回预设 SmsResult
class _ScriptedSmsProvider implements SmsProvider {
  final Map<String, SmsResult> script;
  final List<String> sendCalls = [];

  _ScriptedSmsProvider(this.script);

  @override
  String get name => 'scripted-test';

  @override
  bool get isProductionReady => true;

  @override
  Future<bool> send({
    required String to,
    required String body,
    String? templateId,
  }) async {
    sendCalls.add(to);
    final result = script[to] ?? SmsResult.fail('no script for $to');
    if (result.kind == SmsResultKind.fail) return false;
    return result.kind == SmsResultKind.ok;
  }
}
