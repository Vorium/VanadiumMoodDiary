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

  /// 最后一次每日打卡时间（v0.17 P0-10 接上，反范式冗余列）。
  /// 由 `RecordCheckInUseCase` 在 check-in 时写入。
  /// 失联检测优先读 `check_ins.last_timestamp`,这个字段给 UI 快查用。
  final DateTime? lastCheckInAt;

  // v0.21 Round 22 (P1-22 修复): PIPL §14 同意记录
  final String? userAgreementVersion;
  final String? privacyPolicyVersion;
  final DateTime? sensitiveDataConsentAt;
  final DateTime? consentRevokedAt;

  const UserProfileEntity({
    required this.id,
    required this.userName,
    required this.checkInCycleHours,
    required this.firstLaunchAt,
    this.lastCheckInAt,
    this.userAgreementVersion,
    this.privacyPolicyVersion,
    this.sensitiveDataConsentAt,
    this.consentRevokedAt,
  });

  UserProfileEntity copyWith({
    int? id,
    String? userName,
    int? checkInCycleHours,
    DateTime? firstLaunchAt,
    DateTime? lastCheckInAt,
    String? userAgreementVersion,
    String? privacyPolicyVersion,
    DateTime? sensitiveDataConsentAt,
    DateTime? consentRevokedAt,
  }) {
    return UserProfileEntity(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      checkInCycleHours: checkInCycleHours ?? this.checkInCycleHours,
      firstLaunchAt: firstLaunchAt ?? this.firstLaunchAt,
      lastCheckInAt: lastCheckInAt ?? this.lastCheckInAt,
      userAgreementVersion: userAgreementVersion ?? this.userAgreementVersion,
      privacyPolicyVersion: privacyPolicyVersion ?? this.privacyPolicyVersion,
      sensitiveDataConsentAt:
          sensitiveDataConsentAt ?? this.sensitiveDataConsentAt,
      consentRevokedAt: consentRevokedAt ?? this.consentRevokedAt,
    );
  }

  /// 当前撤回状态（已撤回 = sensitiveDataConsentAt != null && consentRevokedAt != null）
  bool get hasWithdrawnConsent =>
      consentRevokedAt != null && sensitiveDataConsentAt != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileEntity &&
          other.id == id &&
          other.userName == userName &&
          other.checkInCycleHours == checkInCycleHours &&
          other.firstLaunchAt == firstLaunchAt &&
          other.lastCheckInAt == lastCheckInAt &&
          other.userAgreementVersion == userAgreementVersion &&
          other.privacyPolicyVersion == privacyPolicyVersion &&
          other.sensitiveDataConsentAt == sensitiveDataConsentAt &&
          other.consentRevokedAt == consentRevokedAt;

  @override
  int get hashCode => Object.hash(
        id,
        userName,
        checkInCycleHours,
        firstLaunchAt,
        lastCheckInAt,
        userAgreementVersion,
        privacyPolicyVersion,
        sensitiveDataConsentAt,
        consentRevokedAt,
      );

  @override
  String toString() => 'UserProfileEntity(id: $id, userName: $userName, '
      'consent=${sensitiveDataConsentAt != null ? "v$userAgreementVersion" : "none"}, '
      'revokedAt=$consentRevokedAt)';
}
