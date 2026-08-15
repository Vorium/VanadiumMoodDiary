// v0.31.1 R109 (god class 专项 round 1):
// 抽 AssessmentReminderSenderImpl (data 层, 包 NotificationService)
//
// 改前: use case / service 直接 import `NotificationService` 调
//   `delegate.scheduleAssessmentReminder / cancelAssessmentReminder`.
// 改后: data 层薄包装, 实现 `AssessmentReminderSender` abstract
//   (domain), 实际发通知还是走 `NotificationService.delegate`.
//
// 4 层架构: data 层可以依赖 domain interface, 不可以反过来.
// 跟 `ReminderChecker` 隐式实现同款 (1.1.0 round 4b: 后者已随外联整摘).

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

/// v0.32 R109 round 6 part 2: 心理评估提醒发送器 (空实现, 给 test 复用)
///
/// test 跨期 helper, 替代原 R108 之前的 `StubNotificationService extends NotificationService`
/// 内部子类 (R109 round 1 拆 `AssessmentReminderService` 接受 sender interface 后
/// `notificationService` 参数移除, 旧 test helper 失效).
///
/// 0 副作用, 0 业务行为 — 真实测试用 mock 行为可以扩展 (`scheduled` / `cancelCount` 列表
/// 跟旧 StubNotificationService 同款, 用于 assertion).
///
/// 跟 R108 R109 round 1 use case 模板同款 — interface + impl + noop 三件套.
///
/// **不能 const**: 类有 mutable field (`scheduled` 列表 + `cancelCount` 计数器),
///   const constructor 强制要求 final, 跟 list literal 冲突.
class NoOpAssessmentReminderSender implements AssessmentReminderSender {
  /// 真实测试时记录的 schedule 调用
  final List<({DateTime fireAt, String scaleId, int days})> scheduled = [];

  /// 真实测试时记录的 cancel 调用计数
  int cancelCount = 0;

  NoOpAssessmentReminderSender();

  @override
  Future<void> schedule({
    required DateTime fireAt,
    required String scaleId,
    required int days,
  }) async {
    scheduled.add((fireAt: fireAt, scaleId: scaleId, days: days));
  }

  @override
  Future<void> cancel() async {
    cancelCount++;
  }
}
