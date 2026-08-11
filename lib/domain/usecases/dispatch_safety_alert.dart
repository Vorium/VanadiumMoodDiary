// v0.32 R109 (god class 拆 round 2): 抽 DispatchSafetyAlertUseCase
//
// 改前: `SafetyAlertDispatcher.dispatchAlert` 141L 业务编排
//   (feature flag 守卫 + 批量发 SMS + 推本地通知 + 写 audit log + piiSafeLog),
//   直接 import `SmsService` / `NotificationService` / `SafetyConfigService`
//   (data 层), 跟业务规则混.
// 改后: use case 编排层提到 domain/usecases, 拿 `SafetyAlertSender` abstract
//   + `SafetyAlertPolicy` 纯函数, 0 副作用 0 Flutter 0 Drift 0 data import.
//   l10n 走 `SafetyAlertL10nResolver` tear-off 闭包, use case 0 l10n import.
//   跟 R109 round 1 (ScheduleAssessmentReminderUseCase) 模式一致.
//
// 4 层架构: domain/usecases/ 放 0 Flutter / 0 Drift / 0 data / 0 l10n
//   import 的纯编排, AGENTS.md 必读.

import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/logic/safety_alert_policy.dart';
import 'package:chroniccare/domain/repositories/safety_alert_sender.dart';

/// 失联告警派发 use case
///
/// R109 (god class 拆 round 2): use case 层厚化模板 round 2.
///
/// 输入: contacts / userName / daysSinceLast / lastCheckIn / now / trigger / bodyOverride / l10nResolver
/// 编排:
///   1. SafetyAlertPolicy.isEnabled false → 返 0 outcome (feature flag 守卫)
///   2. body = bodyOverride ?? policy.buildAlertSms
///   3. sender.send(...) 批量发 + 推通知 + 写 audit
///
/// 0 副作用: 不调 service, 不发通知, 不写 audit log (sender 负责)
/// 0 Flutter / 0 Drift / 0 l10n: 只依赖 domain abstract + policy
class DispatchSafetyAlertUseCase {
  final SafetyAlertSender _sender;

  const DispatchSafetyAlertUseCase(this._sender);

  /// 派发失联告警 (编排主入口)
  ///
  /// 返回 `SmsDispatchOutcome` (smsOk / smsFail / smsMock 计数), caller
  /// (SafetyWatchService) 把它塞进 `SafetyCheckResult`, UI 跟通知都看
  /// 这个 outcome 决定 3 态显示.
  ///
  /// 3 态 body 文案决策 (sent/mocked/failed) 在 sender impl 内部 (它有
  /// l10n + outcome), use case 不参与, 0 l10n import.
  Future<SmsDispatchOutcome> call({
    required List<ContactEntity> contacts,
    required String? userName,
    required int daysSinceLast,
    required DateTime? lastCheckIn,
    required DateTime now,
    required String trigger,
    String? bodyOverride,
    required SafetyAlertL10nResolver l10nResolver,
  }) async {
    // Feature flag 早返 — 暂停整个失联通信业务
    if (!SafetyAlertPolicy.isEnabled) {
      return (smsOk: 0, smsFail: 0, smsMock: 0);
    }
    // body 计算 (优先 bodyOverride, 跟原 dispatcher 行为 100% 一致)
    final body = SafetyAlertPolicy.buildAlertSms(
      userName: userName,
      daysSinceLast: daysSinceLast,
      bodyOverride: bodyOverride,
    );
    // 委派 sender: 批量发 SMS + 推本地通知 + 写 audit log
    return _sender.send(
      contacts: contacts,
      body: body,
      daysSinceLast: daysSinceLast,
      lastCheckIn: lastCheckIn,
      effectiveNow: now,
      userName: userName,
      l10nResolver: l10nResolver,
    );
  }
}
