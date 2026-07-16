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

  const UserProfileEntity({
    required this.id,
    required this.userName,
    required this.checkInCycleHours,
    required this.firstLaunchAt,
  });
}
