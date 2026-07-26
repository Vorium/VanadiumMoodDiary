// v0.25 round 53a: UserProfileDao 抽离 (单例表, 只有 1 行)

import 'package:chroniccare/core/data/database/app_database.dart';

class UserProfileDao {
  final AppDatabase _db;
  UserProfileDao(this._db);

  /// 监听用户档案 (单例表, 1 行)
  Stream<UserProfile?> watch() {
    return (_db.select(_db.userProfiles)..where((t) => t.id.equals(1)))
        .watchSingleOrNull();
  }

  Future<UserProfile?> get() {
    return (_db.select(_db.userProfiles)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
  }

  Future<void> upsert(UserProfilesCompanion entry) =>
      _db.into(_db.userProfiles).insertOnConflictUpdate(entry);
}
