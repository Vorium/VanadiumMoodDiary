/// 失联检测抽象接口（domain 层）
///
/// ReminderService 实现此接口，domain 层业务逻辑（CareEngine 等）不直接依赖 data 层。

/// 检测结果级别
enum ReminderLevel { none, soft, medium, hard }

/// 检测结果
class ReminderCheckResult {
  final ReminderLevel level;
  const ReminderCheckResult({required this.level});
}

/// 失联检测接口
abstract class ReminderChecker {
  /// 执行一次失联检测 + 发送通知
  Future<ReminderCheckResult> checkAndSend();
}
