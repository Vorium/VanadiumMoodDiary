// v0.32 R109 (god class 拆 round 2): 抽 SafetyAlertSenderImpl (data 层)
//
// 改前: `SafetyAlertDispatcher` 类 (141L) 业务编排 + IO 混. 类名误导,
//   实际是 "发出去" 的实现, 不是抽象 dispatcher.
// 改后: 改名为 `SafetyAlertSenderImpl`, 实现 `SafetyAlertSender` abstract
//   (domain), 业务编排 0 副作用逻辑搬到 use case, 本类只负责:
//   1. 批量调 SmsService.send
//   2. 调 SafetyAlertBuilder.buildFor 构造 3 态通知
//   3. 调 NotificationService.showSafetyAlert 推本地通知
//   4. 调 SafetyConfigService.setLastAlertAt 写 audit log
//   5. piiSafeLog 业务监控
//
// 4 层架构: data 层依赖 domain interface, 不可以反过来.
// 跟 `AssessmentReminderSenderImpl` (R109 round 1) 同款.

import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/data/services/safety_alert_builder.dart';
import 'package:chroniccare/core/data/services/safety_config_service.dart';
import 'package:chroniccare/core/data/services/sms_service.dart';
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/repositories/safety_alert_sender.dart';

/// 失联告警发送器 (data 层, 真接 SmsService + NotificationService)
///
/// R109 (god class 拆 round 2): 替代原 `SafetyAlertDispatcher`, 实现
/// `SafetyAlertSender` abstract. 业务编排 (feature flag + body 计算)
/// 在 use case 编排层, 本类只做 IO 协调.
class SafetyAlertSenderImpl implements SafetyAlertSender {
  final SmsService _smsService;
  final NotificationService _notificationService;
  final SafetyConfigService _config;
  final SafetyAlertBuilder _builder;

  const SafetyAlertSenderImpl({
    required SmsService smsService,
    required NotificationService notificationService,
    required SafetyConfigService config,
    required SafetyAlertBuilder builder,
  })  : _smsService = smsService,
        _notificationService = notificationService,
        _config = config,
        _builder = builder;

  @override
  Future<SmsDispatchOutcome> send({
    required List<ContactEntity> contacts,
    required String body,
    required int daysSinceLast,
    required DateTime? lastCheckIn,
    required DateTime effectiveNow,
    required String? userName,
    required SafetyAlertL10nResolver l10nResolver,
  }) async {
    int smsOk = 0;
    int smsFail = 0;
    int smsMock = 0;

    for (final c in contacts) {
      // v0.27 round 61: 当前 MockSmsProvider 抛 UnimplementedError, 实际
      // 不真发。R55 真接阿里云时, 此处应传 l10n 化 bodyOverride (含 "回复
      // 1 确认" 业务逻辑的 i18n 模板)。当前保持原 hardcode 模板。
      final result = await _smsService.send(to: c.phone, body: body);
      switch (result.kind) {
        case SmsResultKind.ok:
          smsOk++;
        case SmsResultKind.fail:
          smsFail++;
        case SmsResultKind.mock:
          smsMock++;
      }
    }

    // 推本地通知 (用户可能只是忘了打卡, 提示后能补)
    // v0.27 round 60 (P0-3 修正): 把 outcome 传给通知, 通知文案走 3 态分流
    final outcome = (
      smsOk: smsOk,
      smsFail: smsFail,
      smsMock: smsMock,
    );
    await _notificationService.showSafetyAlert(
      userName: userName,
      daysWithoutCheckIn: daysSinceLast,
      lastCheckIn: lastCheckIn,
      outcome: outcome,
      // v0.32 R109: tear-off 闭包 (跨期 R29 R87 抽 interface 失败, Dart
      // nominal typing 不允许 AppLocalizations 隐式 implements, 改用
      // 函数 tear-off 走通, 0 死代码).
      // builder.buildFor 接受 AppLocalizations, 实际只调 5 个 getter, 用
      // 适配 adapter 转 SafetyAlertL10nResolver → AppLocalizations.
      l10n: _resolveL10n(l10nResolver),
    );

    // 写 audit log (避免短时间内重复打扰)
    await _config.setLastAlertAt(effectiveNow);

    piiSafeLog(
      'SafetyAlertSenderImpl',
      '🚨 SafetyWatch 触发: days=$daysSinceLast '
          'smsOk=$smsOk smsFail=$smsFail smsMock=$smsMock',
    );

    return outcome;
  }

  /// SafetyAlertL10nResolver tear-off 闭包 → 适配 AppLocalizations 给 builder
  ///
  /// R109: 适配层, 5 个 String Function 跟 AppLocalizations 同名方法
  /// 1:1 对应. 这里建 1 个轻量 adapter class (`_AppLocalizationsAdapter`)
  /// 包装 tear-off, 内部用 noSuchMethod forward 调闭包. 0 reflection
  /// 开销, 5 个 getter 显式 override.
  AppLocalizations _resolveL10n(SafetyAlertL10nResolver r) =>
      _AppLocalizationsAdapter.fromResolver(r);
}

/// SafetyAlertL10nResolver tear-off → AppLocalizations 适配器
///
/// R109: 跨期 R29 R87 抽 SafetyAlertL10n interface 失败 (Dart nominal
/// typing), R109 改用 tear-off 闭包 + 这个 adapter 转回 AppLocalizations
/// 给 `SafetyAlertBuilder.buildFor` (它签名要求 AppLocalizations).
///
/// 只实现 builder 实际调的 5 个 getter, 0 reflection, 0 dart:mirrors.
class _AppLocalizationsAdapter implements AppLocalizations {
  final SafetyAlertL10nResolver _r;

  _AppLocalizationsAdapter(this._r);

  factory _AppLocalizationsAdapter.fromResolver(SafetyAlertL10nResolver r) =>
      _AppLocalizationsAdapter(r);

  // 5 个 builder 实际调的 getter
  @override
  String safetyAlertTitle(int days) => _r.titleFor(days);

  @override
  String safetyAlertBodySent(String date) => _r.bodySent(date);

  @override
  String safetyAlertBodyMocked(String date) => _r.bodyMocked(date);

  @override
  String safetyAlertBodyFailed(String date) => _r.bodyFailed(date);

  @override
  String get safetyAlertNeverCheckIn => _r.neverCheckIn();

  // 其它未实现的方法会抛 NoSuchMethodError, builder 不会调到,
  // 测试覆盖已验证 (notification_service.showSafetyAlert 流程不变).
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw NoSuchMethodError(
        this,
        invocation.memberName,
        invocation.positionalArguments,
        invocation.namedArguments,
      );
}
