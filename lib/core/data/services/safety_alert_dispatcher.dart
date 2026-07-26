// v0.25 round 57: SafetyAlertDispatcher 抽离 (safety_watch_service god class 拆分)
//
// 装 3 个职责: 1) 构造 SMS body  2) 批量发 SMS + 推本地通知  3) 写 audit log
// (setLastAlertAt)
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/data/services/safety_config_service.dart';
import 'package:chroniccare/core/data/services/sms_service.dart';
import 'package:chroniccare/core/shared/user_name_helper.dart';
import 'package:chroniccare/domain/entities/contact_entity.dart';

/// v0.25 round 57 (spen P1 #12 god class 拆分): 失联告警发送器
///
/// safety_watch_service 失联触发后的"发出去"职责:
/// 1. 构造发给联系人的 SMS body (中文, 70 字限制, 1 屏)
/// 2. 批量发 SMS + 推本地通知 (用户可能只是忘了打卡)
/// 3. 写 audit log (setLastAlertAt, 避免同日重复打扰)
class SafetyAlertDispatcher {
  final SmsService _smsService;
  final NotificationService _notificationService;
  final SafetyConfigService _config;

  SafetyAlertDispatcher({
    required SmsService smsService,
    required NotificationService notificationService,
    required SafetyConfigService config,
  })  : _smsService = smsService,
        _notificationService = notificationService,
        _config = config;

  /// 构造发给联系人的短信内容
  ///
  /// 短信有长度限制 (中文 70 字 / 条), 精简到一屏
  ///
  /// v0.21 Round 23 (P1-24): userName 改 nullable
  /// 未填姓名时退化为 "您的家人", 保持短信语法自然
  String buildAlertSms({
    String? userName,
    required int daysSinceLast,
  }) {
    final name = safeUserName(userName);
    return '[慢病管家] $name 已 $daysSinceLast 天未打卡吃药。'
        '如确认安全请回复 1，无回复请联系本人或社区。';
  }

  /// 批量发 SMS + 推本地通知 + 写 audit log
  ///
  /// 返回 (smsOk, smsFail, smsMock) 元组 — caller 算 contactsNotified/
  /// contactsFailed
  ///
  /// v0.25 round 52 (spen P0 #12): mock 模式单独计数, 不算 ok 也不算 fail
  Future<({int smsOk, int smsFail, int smsMock})> dispatchAlert({
    required List<ContactEntity> contacts,
    required String? userName,
    required int daysSinceLast,
    required DateTime? lastCheckIn,
    required DateTime effectiveNow,
    required String trigger,
  }) async {
    int smsOk = 0;
    int smsFail = 0;
    int smsMock = 0;

    for (final c in contacts) {
      final body = buildAlertSms(
        userName: userName,
        daysSinceLast: daysSinceLast,
      );
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
    await _notificationService.showSafetyAlert(
      userName: userName,
      daysWithoutCheckIn: daysSinceLast,
      lastCheckIn: lastCheckIn,
    );

    // 写 audit log (避免短时间内重复打扰)
    await _config.setLastAlertAt(effectiveNow);

    piiSafeLog(
      'SafetyAlertDispatcher',
      '🚨 SafetyWatch 触发: trigger=$trigger days=$daysSinceLast '
      'smsOk=$smsOk smsFail=$smsFail',
    );

    return (smsOk: smsOk, smsFail: smsFail, smsMock: smsMock);
  }
}
