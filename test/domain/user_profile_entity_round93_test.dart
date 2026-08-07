// v0.28 Round 93 (#74 修复): user_profile_entity 0 测试补齐
//
// 覆盖:
// - 必填 3 字段 (id, checkInCycleHours, firstLaunchAt)
// - 6 个 optional 默认 null
// - copyWith: nullable 字段用 DomainValue 区分 "保持" / "清空"
// - hasWithdrawnConsent getter
// - == / hashCode / toString
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/shared/domain_value.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';

void main() {
  final firstLaunch = DateTime(2026, 1, 1);

  group('UserProfileEntity 必填 + 默认值', () {
    test('最小构造', () {
      final e = UserProfileEntity(
        id: 1,
        checkInCycleHours: 48,
        firstLaunchAt: firstLaunch,
      );
      expect(e.id, 1);
      expect(e.checkInCycleHours, 48);
      expect(e.userName, isNull);
      expect(e.lastCheckInAt, isNull);
      expect(e.userAgreementVersion, isNull);
      expect(e.privacyPolicyVersion, isNull);
      expect(e.sensitiveDataConsentAt, isNull);
      expect(e.consentRevokedAt, isNull);
    });
  });

  group('UserProfileEntity.copyWith', () {
    test('改 checkInCycleHours 不动其他', () {
      final e = UserProfileEntity(
        id: 1,
        checkInCycleHours: 48,
        firstLaunchAt: firstLaunch,
        userName: '小李',
      );
      final e2 = e.copyWith(checkInCycleHours: 72);
      expect(e2.checkInCycleHours, 72);
      expect(e2.userName, '小李');
    });

    test('nullable 字段传 null = 保持原值', () {
      final e = UserProfileEntity(
        id: 1,
        checkInCycleHours: 48,
        firstLaunchAt: firstLaunch,
        userName: '小李',
      );
      final e2 = e.copyWith();
      expect(e2.userName, '小李');
    });

    test('DomainValue(null) 显式清空 userName', () {
      final e = UserProfileEntity(
        id: 1,
        checkInCycleHours: 48,
        firstLaunchAt: firstLaunch,
        userName: '小李',
      );
      final e2 = e.copyWith(userName: const DomainValue(null));
      expect(e2.userName, isNull);
    });

    test('DomainValue(date) 设置 lastCheckInAt', () {
      final e = UserProfileEntity(
        id: 1,
        checkInCycleHours: 48,
        firstLaunchAt: firstLaunch,
      );
      final now = DateTime(2026, 8, 3, 10, 0);
      final e2 = e.copyWith(lastCheckInAt: DomainValue(now));
      expect(e2.lastCheckInAt, now);
    });

    test('DomainValue(null) 显式清空敏感同意 (撤回)', () {
      final consentAt = DateTime(2026, 1, 1);
      final e = UserProfileEntity(
        id: 1,
        checkInCycleHours: 48,
        firstLaunchAt: firstLaunch,
      );
      // 构造时用 nullable 字段, 后续 copyWith DomainValue(null) 模拟撤回
      final e2 = e.copyWith(
        sensitiveDataConsentAt: DomainValue(consentAt),
        consentRevokedAt: DomainValue(consentAt),
      );
      expect(e2.hasWithdrawnConsent, isTrue);
      final e3 = e2.copyWith(
        sensitiveDataConsentAt: const DomainValue(null),
        consentRevokedAt: const DomainValue(null),
      );
      expect(e3.hasWithdrawnConsent, isFalse);
    });
  });

  group('UserProfileEntity.hasWithdrawnConsent', () {
    test('consents 全 null → false', () {
      final e = UserProfileEntity(
        id: 1,
        checkInCycleHours: 48,
        firstLaunchAt: firstLaunch,
      );
      expect(e.hasWithdrawnConsent, isFalse);
    });

    test('只 sensitiveDataConsentAt 不算撤回', () {
      final consentAt = DateTime(2026, 1, 1);
      final e = UserProfileEntity(
        id: 1,
        checkInCycleHours: 48,
        firstLaunchAt: firstLaunch,
        sensitiveDataConsentAt: consentAt,
      );
      expect(e.hasWithdrawnConsent, isFalse);
    });

    test('只 consentRevokedAt 不算撤回', () {
      final revokedAt = DateTime(2026, 6, 1);
      final e = UserProfileEntity(
        id: 1,
        checkInCycleHours: 48,
        firstLaunchAt: firstLaunch,
        consentRevokedAt: revokedAt,
      );
      expect(e.hasWithdrawnConsent, isFalse);
    });

    test('两个都 set → true', () {
      final consentAt = DateTime(2026, 1, 1);
      final revokedAt = DateTime(2026, 6, 1);
      final e = UserProfileEntity(
        id: 1,
        checkInCycleHours: 48,
        firstLaunchAt: firstLaunch,
        sensitiveDataConsentAt: consentAt,
        consentRevokedAt: revokedAt,
      );
      expect(e.hasWithdrawnConsent, isTrue);
    });
  });

  group('UserProfileEntity == / hashCode / toString', () {
    test('字段全等 → ==', () {
      final e1 = UserProfileEntity(
        id: 1,
        checkInCycleHours: 48,
        firstLaunchAt: firstLaunch,
        userName: 'A',
      );
      final e2 = UserProfileEntity(
        id: 1,
        checkInCycleHours: 48,
        firstLaunchAt: firstLaunch,
        userName: 'A',
      );
      expect(e1, e2);
      expect(e1.hashCode, e2.hashCode);
    });

    test('id 不同 → !=', () {
      final e1 = UserProfileEntity(
        id: 1,
        checkInCycleHours: 48,
        firstLaunchAt: firstLaunch,
      );
      final e2 = UserProfileEntity(
        id: 2,
        checkInCycleHours: 48,
        firstLaunchAt: firstLaunch,
      );
      expect(e1, isNot(e2));
    });

    test('toString 含 id + userName + consent 摘要', () {
      final e = UserProfileEntity(
        id: 1,
        userName: '小李',
        checkInCycleHours: 48,
        firstLaunchAt: firstLaunch,
        userAgreementVersion: 'v1.0',
        sensitiveDataConsentAt: DateTime(2026, 1, 1),
      );
      final s = e.toString();
      expect(s, contains('1'));
      expect(s, contains('小李'));
      expect(s, contains('v1.0'));
    });
  });
}
