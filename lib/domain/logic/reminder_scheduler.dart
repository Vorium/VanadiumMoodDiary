import 'package:chroniccare/domain/entities/contact_entity.dart';

/// 失联检测调度器
///
/// 业务规则：
/// - 距离最后打卡 ≥ checkInCycleHours（默认 48h）= 触发通知
/// - 已经发送过的"周期"内不重复发送（避免邮件轰炸）
class ReminderScheduler {
  ReminderScheduler._();

  /// 判断是否应该发送停药通知
  ///
  /// 返回：true = 应该发送；false = 不应该
  ///
  /// 规则：
  /// - 没最后打卡时间 → false
  /// - 距离最后打卡 < cycleHours → false
  /// - 距离最后打卡 ≥ cycleHours → true
  /// - 距离最后打卡 ≥ cycleHours × 2 → 继续返回 true（让用户能改时间）
  static bool shouldSendAlert({
    required DateTime? lastCheckIn,
    required int cycleHours,
    required DateTime now,
  }) {
    if (lastCheckIn == null) return false;

    final minutesSinceLast = now.difference(lastCheckIn).inMinutes;
    return minutesSinceLast >= cycleHours * 60;
  }

  /// 计算距离最后打卡的小时数
  static int hoursSinceLastCheckIn({
    required DateTime? lastCheckIn,
    required DateTime now,
  }) {
    if (lastCheckIn == null) return -1;
    return now.difference(lastCheckIn).inHours;
  }

  /// 选择第一个要通知的联系人
  ///
  /// MVP 阶段：按 sortOrder 顺序发给第一个启用的联系人
  /// v1.0+：可扩展为同时发给所有联系人
  static ContactEntity? selectFirstContact(List<ContactEntity> contacts) {
    if (contacts.isEmpty) return null;
    final active = contacts.where((c) => c.isActive).toList();
    if (active.isEmpty) return null;
    active.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return active.first;
  }

  /// 选择所有启用的联系人
  static List<ContactEntity> selectAllActiveContacts(
    List<ContactEntity> contacts,
  ) {
    final active = contacts.where((c) => c.isActive).toList();
    active.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return active;
  }
}
