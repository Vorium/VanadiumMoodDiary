// v0.17 round 14 (P2-8): user_profile mapper 抽离
// v0.23 round 44: 函数风格 → extension 风格，与其他 mapper 统一

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';

/// Drift row → domain entity
extension UserProfileToEntity on UserProfile {
  UserProfileEntity toEntity() => UserProfileEntity(
        id: id,
        userName: userName,
        checkInCycleHours: checkInCycleHours,
        firstLaunchAt: firstLaunchAt,
        lastCheckInAt: lastCheckInAt,
        userAgreementVersion: userAgreementVersion,
        privacyPolicyVersion: privacyPolicyVersion,
        sensitiveDataConsentAt: sensitiveDataConsentAt,
        consentRevokedAt: consentRevokedAt,
      );
}

/// Nullable Drift row → nullable domain entity
UserProfileEntity? userProfileFromRow(UserProfile? row) => row?.toEntity();
