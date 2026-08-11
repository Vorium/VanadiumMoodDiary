// v0.32 R109 (god class 拆 round 2): 抽 SafetyAlertSender abstract interface
//
// 改前: `SafetyAlertDispatcher` 类 (141L) 业务编排 + IO 混. 类名误导,
//   实际是 "发出去" 的实现, 不是抽象 dispatcher. 直接 import
//   `SmsService` + `NotificationService` + `SafetyConfigService` (data 层).
// 改后: 抽 abstract interface, use case 拿这个, 不直接拿 service.
//   data 层写 `SafetyAlertSenderImpl` (实现, 包 SmsService +
//   NotificationService + SafetyConfigService 实际发).
//
// 4 层架构: domain/repositories/ 放 abstract, 0 实现, AGENTS.md 必读.
// 跟 `AssessmentReminderSender` (R109 round 1) / `ReminderChecker` (R16) 同款.
//
// l10n 处理: use case 0 l10n import, 用 5 个 `String Function` tear-off
//   闭包 (titleFor / bodySent / bodyMocked / bodyFailed / neverCheckIn)
//   让 caller 注入, sender impl 内部转发给 SafetyAlertBuilder + NotificationService.
//   这是 R29 R87 抽 SafetyAlertL10n interface 失败后的实际可工作模式
//   (Dart nominal typing 强制 nominal subtyping, R29 抽的 interface
//   没人 implements → 死代码, R109 round 2 顺手删了).

import 'package:chroniccare/domain/entities/contact_entity.dart';

/// 失联告警批量 SMS 派发结果 (record typedef, 跨层共享)
///
/// v0.32 R109 (god class 拆 round 2): 抽到 `domain/repositories/` 共享层,
/// use case 跟 sender 都能 import, 不再依赖 data 层 `sms_service.dart`.
/// 原定义位置 `lib/core/data/services/sms_service.dart` (R25 round 52).
///
/// 字段:
/// - [smsOk] 实际发送成功条数
/// - [smsFail] 实际发送失败条数
/// - [smsMock] dev mock 模式条数 (R52 P0 #12 单独计数, 不算 ok 也不算 fail)
///
/// caller 模式: 注入到 `SafetyCheckResult` 决定 UI 3 态显示
/// (sent / mocked / failed).
typedef SmsDispatchOutcome = ({
  int smsOk,
  int smsFail,
  int smsMock,
});

/// 失联告警通知文案 tear-off 闭包集合
///
/// 5 个方法跟原 `AppLocalizations.safetyAlertTitle/BodySent/BodyMocked/
/// BodyFailed/NeverCheckIn` 1:1 对应. caller 注入:
/// ```dart
/// l10nResolver: SafetyAlertL10nResolver(
///   titleFor: l10n.safetyAlertTitle,
///   bodySent: l10n.safetyAlertBodySent,
///   bodyMocked: l10n.safetyAlertBodyMocked,
///   bodyFailed: l10n.safetyAlertBodyFailed,
///   neverCheckIn: () => l10n.safetyAlertNeverCheckIn,
/// )
/// ```
///
/// use case 跟 sender 拿这个, 0 l10n import, 跨层干净.
class SafetyAlertL10nResolver {
  /// 通知标题 (失联天数参数, 跟 l10n.safetyAlertTitle(int) 一致)
  final String Function(int daysWithoutCheckIn) titleFor;

  /// SMS 真发成功 body
  final String Function(Object formattedLastCheckIn) bodySent;

  /// SMS mock body
  final String Function(Object formattedLastCheckIn) bodyMocked;

  /// SMS 失败 body
  final String Function(Object formattedLastCheckIn) bodyFailed;

  /// lastCheckIn==null 时 body 替代文案 (R75 R74-N8 修, 之前硬编码中文)
  final String Function() neverCheckIn;

  const SafetyAlertL10nResolver({
    required this.titleFor,
    required this.bodySent,
    required this.bodyMocked,
    required this.bodyFailed,
    required this.neverCheckIn,
  });
}

/// 失联告警发送器 (abstract)
///
/// R109 (god class 拆 round 2): use case 编排层调这个, 不直接拿
/// `SmsService` / `NotificationService` (data 层).
///
/// 实现位置:
/// - `data/services/safety_alert_sender_impl.dart`: 真接 SMS + 本地通知 (生产)
/// - widget test: mock 实现, 不发真通知
/// - 未来 R55+: 阿里云 SMS 真接时, sender impl 升级, use case 0 改动
abstract class SafetyAlertSender {
  /// 发送失联告警 (含批量 SMS + 本地通知 + audit log)
  ///
  /// 输入:
  /// - [contacts] 紧急联系人列表 (按顺序发 SMS)
  /// - [body] SMS 文本 (call site 算好, 通常走 `SafetyAlertPolicy.buildAlertSms`)
  /// - [daysSinceLast] 失联天数 (通知标题/正文用)
  /// - [lastCheckIn] 上次打卡时间 (通知正文用)
  /// - [effectiveNow] 业务时间 (audit log + piiSafeLog 用)
  /// - [l10nResolver] 通知 3 态文案 tear-off 闭包 (call site 注入)
  /// - [userName] 通知正文可选用户姓名
  ///
  /// 输出: `SmsDispatchOutcome` (smsOk / smsFail / smsMock 计数), caller
  ///   (SafetyWatchService) 把它塞进 `SafetyCheckResult`, UI 跟通知都看
  ///   这个 outcome 决定 3 态显示.
  Future<SmsDispatchOutcome> send({
    required List<ContactEntity> contacts,
    required String body,
    required int daysSinceLast,
    required DateTime? lastCheckIn,
    required DateTime effectiveNow,
    required String? userName,
    required SafetyAlertL10nResolver l10nResolver,
  });
}
