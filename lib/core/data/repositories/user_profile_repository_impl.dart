// v0.16 (Round 19) UserProfileRepositoryImpl — Drift 实现
//
// UI 只看到 domain entity，不直接碰 Drift row。

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/repositories/user_profile_repository.dart';
import 'package:chroniccare/core/data/database/app_database.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final AppDatabase _db;

  UserProfileRepositoryImpl(this._db);

  UserProfileEntity? _toEntity(UserProfile? row) {
    if (row == null) return null;
    return UserProfileEntity(
      id: row.id,
      userName: row.userName,
      checkInCycleHours: row.checkInCycleHours,
      firstLaunchAt: row.firstLaunchAt,
    );
  }

  @override
  Stream<UserProfileEntity?> watch() {
    return _db.watchUserProfile().map(_toEntity);
  }

  @override
  Future<UserProfileEntity?> get() async {
    final row = await _db.getUserProfile();
    return _toEntity(row);
  }

  @override
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

  @override
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
