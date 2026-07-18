/// 通知发送抽象接口（domain 层）
///
/// domain 层不依赖 `data/services/notification_service.dart`，
/// CareEngine / ReminderService 等业务逻辑用此接口。
abstract class NotificationSender {
  /// 立即发送一条本地通知
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  });
}
