// v0.32 R109 (god class 拆 round 2): 抽 SafetyAlertPolicy 纯函数
//
// 改前: `buildAlertSms` 是 `SafetyAlertDispatcher` 的实例方法, 跟
//   `dispatchAlert` (副作用: 批量发 SMS + 推本地通知 + 写 audit log)
//   混在 1 个 141L service. feature flag 早返 (`FeatureFlags.emergencyContactEnabled`)
//   也是 service 内部散落, 没有集中入口.
// 改后: 纯函数 policy 提到 domain/logic, use case 编排层 0 副作用 0 service
//   调, 跟 R109 round 1 (assessment_reminder_policy) 模式一致.
//
// 4 层架构: domain/logic/ 放 0 副作用 0 Flutter 0 Drift 0 service 调的
//   纯函数, AGENTS.md 必读. 跟 `lib/domain/logic/refill_scheduler.dart`
//   / `lib/domain/logic/assessment_reminder_policy.dart` 同款.

import 'package:chroniccare/domain/logic/lost_contact_sms.dart';

/// 失联告警业务规则
  ///
  /// R109 round 2: 把 `SafetyAlertDispatcher` 里的纯业务规则提到
  /// domain/logic, use case 编排层 0 副作用.
  ///
  /// 业务规则:
  /// - feature flag 关闭 → 不发任何 SMS / 通知 / audit (病耻感 + 失联通信业务暂停,
  ///   flag 值由 use case 构造注入, 本层 0 data import — R110 round 3 修 purity)
  /// - 短信文案优先用 bodyOverride, 否则走 `buildLostContactSms` 模板
  ///
  /// 4 层架构: domain/logic 严禁 import `core/data/`, feature flag 走
  /// `DispatchSafetyAlertUseCase` 构造注入 (`emergencyContactEnabled`).
class SafetyAlertPolicy {

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
  static String buildAlertSms({
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
}
