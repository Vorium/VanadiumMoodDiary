// v0.16 (Round 19) UserProfileRepositoryImpl — Drift 实现
//
// UI 只看到 domain entity，不直接碰 Drift row。

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/repositories/user_profile_repository.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/user_profile_mapper.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final AppDatabase _db;

  UserProfileRepositoryImpl(this._db);

  @override
  Stream<UserProfileEntity?> watch() {
    return _db.userProfileDao.watch().map(userProfileFromRow);
  }

  @override
  Future<UserProfileEntity?> get() async {
    final row = await _db.userProfileDao.get();
    return userProfileFromRow(row);
  }

  @override
  Future<void> save({
    // v0.21 Round 23 (P1-24): userName 改 nullable
    // 调用方可传 null (用户跳过填姓名)
    String? userName,
    int checkInCycleHours = 48,
  }) async {
    await _db.transaction(() async {
      final existing = await _db.userProfileDao.get();
      await _db.userProfileDao.upsert(
        UserProfilesCompanion.insert(
          userName: Value(userName),
          checkInCycleHours: Value(checkInCycleHours),
          firstLaunchAt: existing?.firstLaunchAt ?? DateTime.now(),
        ),
      );
    });
  }

  @override
  Future<void> updateLastCheckIn(DateTime time) async {
    await _db.transaction(() async {
      final existing = await _db.userProfileDao.get();
      if (existing != null) {
        await _db.userProfileDao.upsert(
          UserProfilesCompanion.insert(
            userName: Value(existing.userName),
            checkInCycleHours: Value(existing.checkInCycleHours),
            firstLaunchAt: existing.firstLaunchAt,
            lastCheckInAt: Value(time),
          ),
        );
      }
    });
  }

  // v0.21 Round 22 (P1-22 修复): PIPL §14 consent 记录方法

  @override
  Future<void> recordConsent({
    required String userAgreementVersion,
    required String privacyPolicyVersion,
  }) async {
    await _db.transaction(() async {
      final existing = await _db.userProfileDao.get();
      if (existing == null) return;
      await _db.userProfileDao.upsert(
        UserProfilesCompanion.insert(
          userName: Value(existing.userName),
          checkInCycleHours: Value(existing.checkInCycleHours),
          firstLaunchAt: existing.firstLaunchAt,
          lastCheckInAt: Value(existing.lastCheckInAt),
          userAgreementVersion: Value(userAgreementVersion),
          privacyPolicyVersion: Value(privacyPolicyVersion),
          sensitiveDataConsentAt: Value(DateTime.now()),
          consentRevokedAt: const Value.absent(),
        ),
      );
    });
  }

  @override
  Future<void> withdrawConsent() async {
    await _db.transaction(() async {
      final existing = await _db.userProfileDao.get();
      if (existing == null) return;
      await _db.userProfileDao.upsert(
        UserProfilesCompanion.insert(
          userName: Value(existing.userName),
          checkInCycleHours: Value(existing.checkInCycleHours),
          firstLaunchAt: existing.firstLaunchAt,
          lastCheckInAt: Value(existing.lastCheckInAt),
          userAgreementVersion: Value(existing.userAgreementVersion),
          privacyPolicyVersion: Value(existing.privacyPolicyVersion),
          sensitiveDataConsentAt: Value(existing.sensitiveDataConsentAt),
          consentRevokedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> resetConsent() async {
    await _db.transaction(() async {
      final existing = await _db.userProfileDao.get();
      if (existing == null) return;
      await _db.userProfileDao.upsert(
        UserProfilesCompanion.insert(
          userName: Value(existing.userName),
          checkInCycleHours: Value(existing.checkInCycleHours),
          firstLaunchAt: existing.firstLaunchAt,
          lastCheckInAt: Value(existing.lastCheckInAt),
          userAgreementVersion: Value(existing.userAgreementVersion),
          privacyPolicyVersion: Value(existing.privacyPolicyVersion),
          sensitiveDataConsentAt: Value(DateTime.now()),
          consentRevokedAt: const Value.absent(),
        ),
      );
    });
  }
}
