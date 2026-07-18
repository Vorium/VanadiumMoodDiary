/// 用户档案（domain 实体）
///
/// 对应 Drift 表 `user_profiles`。
class UserProfileEntity {
  /// 永远只有 1 行（id=1）
  final int id;
  final String userName;

  /// 失联检测周期（小时），默认 48
  final int checkInCycleHours;

  /// 首次启动时间（不可变）
  final DateTime firstLaunchAt;

  /// 最后一次每日打卡时间（v0.17 P0-10 接上,反范式冗余列）。
  /// 由 `RecordCheckInUseCase` 在 check-in 时写入。
  /// 失联检测优先读 `check_ins.last_timestamp`,这个字段给 UI 快查用。
  final DateTime? lastCheckInAt;

  const UserProfileEntity({
    required this.id,
    required this.userName,
    required this.checkInCycleHours,
    required this.firstLaunchAt,
    this.lastCheckInAt,
  });
}
