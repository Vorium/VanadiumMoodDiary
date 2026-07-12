import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 用户档案仓库
class UserProfileRepository {
  final AppDatabase _db;

  UserProfileRepository(this._db);

  /// 监听用户档案
  Stream<UserProfile?> watch() => _db.watchUserProfile();

  /// 获取用户档案
  Future<UserProfile?> get() => _db.getUserProfile();

  /// 创建或更新用户档案
  Future<void> save({
    required String userName,
    int checkInCycleHours = 48,
  }) async {
    final existing = await _db.getUserProfile();
    await _db.upsertUserProfile(
      UserProfilesCompanion.insert(
        userName: userName,
        checkInCycleHours: Value(checkInCycleHours),
        firstLaunchAt: existing?.firstLaunchAt ?? DateTime.now(),
      ),
    );
  }

  /// 更新最后打卡时间
  Future<void> updateLastCheckIn(DateTime time) async {
    final existing = await _db.getUserProfile();
    if (existing != null) {
      await _db.upsertUserProfile(
        UserProfilesCompanion.insert(
          userName: existing.userName,
          checkInCycleHours: Value(existing.checkInCycleHours),
          firstLaunchAt: existing.firstLaunchAt,
          lastCheckInAt: Value(time),
        ),
      );
    }
  }
}
