// v0.25 round 57: SafetyAlertDispatcher 抽离 (safety_watch_service god class 拆分)
//
// 装 3 个职责: 1) 构造 SMS body  2) 批量发 SMS + 推本地通知  3) 写 audit log
// (setLastAlertAt)
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/data/services/safety_config_service.dart';
import 'package:chroniccare/core/data/services/sms_service.dart';
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/logic/lost_contact_sms.dart';
import 'package:chroniccare/l10n/app_localizations.dart'
    show AppLocalizations;

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
  ///
  /// v0.27 round 61 (P0-2): 加 `bodyOverride` 参数支持 i18n override。
  /// 修正前 hardcode 中文模板含"如确认安全请回复 1"业务逻辑 (家属确认
  /// 患者安全的关键设计)。R55 真接阿里云后 en 用户失联, dispatchAlert
  /// caller (SafetyWatchService._checkAndAlert) 需注入 l10n 化版本。
  ///
  /// v0.27 round 62 (P1-5 修复): 改走 `buildLostContactSms` 单一 source,
  /// 跟 ReminderService 共享模板逻辑, 措辞一致 + 模板集中维护。
  /// bodyOverride 优先 → 否则走 `LostContactSmsKind.safetyAlert` 模板。
  String buildAlertSms({
    String? userName,
    required int daysSinceLast,
    String? bodyOverride,
  }) {
    if (bodyOverride != null) return bodyOverride;
    return buildLostContactSms(
      kind: LostContactSmsKind.safetyAlert,
      userName: userName,
      daysSince: daysSinceLast,
      hoursSince: daysSinceLast * 24,
    );
  }

  /// 批量发 SMS + 推本地通知 + 写 audit log
  ///
  /// 返回 `SmsDispatchOutcome` (smsOk / smsFail / smsMock 计数) — caller
  /// (`SafetyWatchService._checkAndAlert`) 把它塞进 `SafetyCheckResult`,
  /// UI 跟通知都看这个 outcome 决定 3 态显示。
  ///
  /// v0.25 round 52 (spen P0 #12): mock 模式单独计数, 不算 ok 也不算 fail
  ///
  /// v0.27 round 60 (P0-3 修正): 通知入参加 outcome + `AppLocalizations`,
  /// 文案走 3 态分流 (sent / mocked / failed) + 走 l10n。修正前通知 hardcode
  /// "已自动通知紧急联系人", 即便 SMS mock / 失败也这么说, 对精神心理
  /// 患者形成"谎言"。
  Future<SmsDispatchOutcome> dispatchAlert({
    required List<ContactEntity> contacts,
    required String? userName,
    required int daysSinceLast,
    required DateTime? lastCheckIn,
    required DateTime effectiveNow,
    required String trigger,
    required AppLocalizations l10n,
  }) async {
    int smsOk = 0;
    int smsFail = 0;
    int smsMock = 0;

    for (final c in contacts) {
      // v0.27 round 61: 当前 MockSmsProvider 抛 UnimplementedError, 实际
      // 不真发。R55 真接阿里云时, 此处应传 l10n 化 bodyOverride (含 "回复
      // 1 确认" 业务逻辑的 i18n 模板)。当前保持原 hardcode 模板。
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
      l10n: l10n,
    );

    // 写 audit log (避免短时间内重复打扰)
    await _config.setLastAlertAt(effectiveNow);

    piiSafeLog(
      'SafetyAlertDispatcher',
      '🚨 SafetyWatch 触发: trigger=$trigger days=$daysSinceLast '
      'smsOk=$smsOk smsFail=$smsFail smsMock=$smsMock',
    );

    return outcome;
  }
}
