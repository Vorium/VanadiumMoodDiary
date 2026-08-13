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

  const SafetyAlertSenderImpl({
    required SmsService smsService,
    required NotificationService notificationService,
    required SafetyConfigService config,
  })  : _smsService = smsService,
        _notificationService = notificationService,
        _config = config;

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
    // v0.32 R109 round 6: notification_service.showSafetyAlert
    //   + safety_alert_builder.buildFor 都已接受 SafetyAlertL10nResolver
    //   (R109 round 2 末尾改动), 删原 _AppLocalizationsAdapter + _resolveL10n
    //   适配器 (56 fail 修). 0 死代码, adapter 是 R109 round 2 临时桥, 后续
    //   改 builder 接口后已不需要.
    // v0.32 R112 (R112-09): userName 死参数已删 (body 0 引用).
    await _notificationService.showSafetyAlert(
      daysWithoutCheckIn: daysSinceLast,
      lastCheckIn: lastCheckIn,
      outcome: outcome,
      l10nResolver: l10nResolver,
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
}

// v0.32 R109 round 6: 删 _AppLocalizationsAdapter (56 fail 修, 死代码).
//   之前 R109 round 2 改 builder/showSafetyAlert 接受 SafetyAlertL10nResolver
//   时, 漏删这里. 现在 sender_impl 直接传 l10nResolver 给 showSafetyAlert.
