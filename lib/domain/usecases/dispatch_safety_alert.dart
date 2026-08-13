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
///   1. emergencyContactEnabled false → 返 0 outcome (feature flag 守卫,
///      R110 round 3 改构造注入, 本文件 0 data import — 修 purity 违规)
///   2. body = bodyOverride ?? policy.buildAlertSms
///   3. sender.send(...) 批量发 + 推通知 + 写 audit
///
/// 0 副作用: 不调 service, 不发通知, 不写 audit log (sender 负责)
/// 0 Flutter / 0 Drift / 0 l10n: 只依赖 domain abstract + policy
class DispatchSafetyAlertUseCase {
  final SafetyAlertSender _sender;
  final bool emergencyContactEnabled;

  const DispatchSafetyAlertUseCase(
    this._sender, {
    required this.emergencyContactEnabled,
  });

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
    // Feature flag 早返 — 暂停整个失联通信业务 (构造注入, 避免 domain 依赖 data)
    if (!emergencyContactEnabled) {
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

/// v0.32 R109 round 6 part 2: 失联告警派发 use case (空实现, 给 test 复用)
///
/// 跟 `NoOpAssessmentReminderSender` (R109 round 6 part 2 lib 加) 同款:
/// 0 副作用, 0 业务行为. test 跨期 helper, 替代原 R108 之前 test 自定义
/// `_StubNotificationService` / `_CountingNotificationService` 内部子类
/// (R109 round 2 改 service 接受 `DispatchSafetyAlertUseCase` 后, 旧
/// notification service subclass 失效)。
///
/// ⚠️ v0.32 R112 (R112-10): 本类是 **test-only helper 放生产文件**
/// (R109 收尾遗留) — **严禁在生产代码构造**。`@visibleForTesting` marker
/// 因 domain 纯度守门 (check_all domain 0 `package:flutter/`, 含
/// flutter/foundation re-export, 见 R110 round 3 schedule_assessment_reminder
/// 同款先例) 无法加, 用本注释标记; 抽 test 公共 helper 包的大迁移留后续。
class NoOpDispatchSafetyAlertUseCase extends DispatchSafetyAlertUseCase {
  NoOpDispatchSafetyAlertUseCase()
      : super(_NoOpSafetyAlertSenderState(), emergencyContactEnabled: true);

  /// 真实测试时记录 dispatch 调用结果
  final List<SmsDispatchOutcome> outcomes = [];

  @override
  Future<SmsDispatchOutcome> call({
    required contacts,
    required String? userName,
    required int daysSinceLast,
    required DateTime? lastCheckIn,
    required DateTime now,
    required String trigger,
    String? bodyOverride,
    required l10nResolver,
  }) async {
    const outcome = (smsOk: 0, smsFail: 0, smsMock: 0);
    outcomes.add(outcome);
    return outcome;
  }
}

/// _NoOpSafetyAlertSenderState — 给 NoOpDispatchSafetyAlertUseCase 用的空 sender
/// v0.32 round 8 (R111 SP-111-16 fix): 改名 State 后缀, 消除 check_usecase_layer
/// 唯一 warning (R109 命名规范: 类名须以 UseCase/Policy/Input/Output/Config/
/// Result/Schedule/State 结尾)
class _NoOpSafetyAlertSenderState extends SafetyAlertSender {
  _NoOpSafetyAlertSenderState();

  @override
  Future<SmsDispatchOutcome> send({
    required contacts,
    required String body,
    required int daysSinceLast,
    required DateTime? lastCheckIn,
    required DateTime effectiveNow,
    required String? userName,
    required l10nResolver,
  }) async {
    return (smsOk: 0, smsFail: 0, smsMock: 0);
  }
}
