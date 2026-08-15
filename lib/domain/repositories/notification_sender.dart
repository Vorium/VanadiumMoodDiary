// 通知发送抽象接口（domain 层）
//
// domain 层不依赖 `data/services/notification_service.dart`，
// 主动 push 类业务逻辑用此接口。
// 1.1.0 round 4b: 原 CareEngine / ReminderService 2 个消费者随外联服务整摘。
abstract class NotificationSender {
  /// 立即发送一条本地通知
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  });
}
