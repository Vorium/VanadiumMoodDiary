// v0.31.1 R109 (god class 专项 round 1):
// 抽 AssessmentReminderSender abstract interface
//
// 改前: `assessment_reminder_service` 直接依赖 `NotificationService`,
//   `onAppStart` / `onAssessmentCompleted` 调
//   `notification_service.delegate.scheduleAssessmentReminder(...)`,
//   use case 层无法注入 (NotificationService 是 data 层).
// 改后: 抽 abstract interface, use case 拿这个 (domain 0 依赖),
//   data 层写 AssessmentReminderSenderImpl 包 NotificationService 实际发.
//
// 4 层架构: domain/repositories/ 放 abstract, 0 实现, AGENTS.md 必读.
// 跟 `ReminderChecker` 同款 (R16 round 7 抽的, use case 拿这个).

/// 心理评估提醒发送器 (abstract)
///
/// R109 (god class 拆): use case 编排层调这个发/取消, 不直接拿
/// `NotificationService` (data 层, 依赖 Flutter plugin).
///
/// 3 个实现位置:
/// - `data/services/assessment_reminder_sender_impl.dart`:
///   真接 `NotificationService.delegate` (生产环境)
/// - widget test: mock 实现, 不发真通知
/// - 未来 R55+ 多渠道: email / SMS sender
abstract class AssessmentReminderSender {
  /// 调度一次提醒
  ///
  /// [fireAt] 触发时间 (本地时间)
  /// [scaleId] 评估 ID (phq9 / gad7), 跟通知渠道绑定
  /// [days] 间隔天数, 跟通知文案 / 链接触发关联
  Future<void> schedule({
    required DateTime fireAt,
    required String scaleId,
    required int days,
  });

  /// 取消待响的评估提醒
  ///
  /// 用户关闭开关 / 卸载 app 时调.
  Future<void> cancel();
}
