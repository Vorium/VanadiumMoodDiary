/// 失联检测抽象接口（domain 层）
///
/// ReminderService 实现此接口，domain 层业务逻辑（CareEngine 等）不直接依赖 data 层。
library;

/// 检测结果级别
enum ReminderLevel { none, soft, medium, hard, urgent }

/// 失联检测结果
///
/// 业务方（CareEngine / SafetyWatch）关心 `level`；UI 关心 `smsResults` 看哪些家人收到通知。
class ReminderCheckResult {
  final ReminderLevel level;
  final List<SmsResultEntry> smsResults;

  const ReminderCheckResult({
    required this.level,
    required this.smsResults,
  });

  factory ReminderCheckResult.empty() => const ReminderCheckResult(
        level: ReminderLevel.none,
        smsResults: [],
      );

  bool get hasSmsFailures => smsResults.any((r) => !r.success);
  int get successCount => smsResults.where((r) => r.success).length;
  int get failCount => smsResults.where((r) => !r.success).length;
}

/// 一条 SMS 发送结果（业务结果，不是 SMS provider 的 transport 细节）
class SmsResultEntry {
  final int contactId;
  final String contactName;
  final String phone;
  final bool success;
  final String? error;

  const SmsResultEntry({
    required this.contactId,
    required this.contactName,
    required this.phone,
    required this.success,
    this.error,
  });
}

/// 失联检测接口
abstract class ReminderChecker {
  /// 执行一次失联检测 + 发送通知
  Future<ReminderCheckResult> checkAndSend();
}
