import 'package:chroniccare/domain/entities/user_profile_entity.dart';

/// 用户档案仓库（domain 抽象接口）
///
/// data 层用 Drift 实现，UI 只调 watch / get / save。
abstract class UserProfileRepository {
  /// 监听用户档案（流式，UI 用）
  Stream<UserProfileEntity?> watch();

  /// 一次性获取
  Future<UserProfileEntity?> get();

  /// 创建或更新（setup / 修改用户名 / 改失联周期）
  Future<void> save({
    required String userName,
    int checkInCycleHours = 48,
  });

  /// 更新最后打卡时间（用于失联检测）
  Future<void> updateLastCheckIn(DateTime time);
}
