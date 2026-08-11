// v0.31.1 R109 (god class 专项 round 1):
// 抽 AssessmentReminderSenderImpl (data 层, 包 NotificationService)
//
// 改前: use case / service 直接 import `NotificationService` 调
//   `delegate.scheduleAssessmentReminder / cancelAssessmentReminder`.
// 改后: data 层薄包装, 实现 `AssessmentReminderSender` abstract
//   (domain), 实际发通知还是走 `NotificationService.delegate`.
//
// 4 层架构: data 层可以依赖 domain interface, 不可以反过来.
// 跟 `ReminderChecker` 隐式实现 / `SafetyAlertDispatcher` 同款.

import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/domain/repositories/assessment_reminder_sender.dart';

/// 心理评估提醒发送器 (NotificationService 实现)
///
/// R109 (god class 拆): 唯一职责 = 把 use case 编排的"发 / 取消" 翻译成
/// `NotificationService.delegate` 调用. 后续 R55+ 接 email / SMS 渠道
/// 时, 写 `AssessmentReminderSenderEmail` 同接口, use case 0 改动.
class AssessmentReminderSenderImpl implements AssessmentReminderSender {
  final NotificationService _notificationService;

  const AssessmentReminderSenderImpl(this._notificationService);

  @override
  Future<void> schedule({
    required DateTime fireAt,
    required String scaleId,
    required int days,
  }) {
    return _notificationService.delegate.scheduleAssessmentReminder(
      fireAt: fireAt,
      scaleId: scaleId,
      days: days,
    );
  }

  @override
  Future<void> cancel() {
    return _notificationService.delegate.cancelAssessmentReminder();
  }
}
