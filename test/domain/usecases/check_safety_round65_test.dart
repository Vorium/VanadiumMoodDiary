// v0.27 round 65 (spen 1.2.2 + alibaba 1.2 use case 层补):
// CheckSafetyUseCase 单元测试 (SafetyDetector 的 domain 层薄包装)
//
// 5 case 覆盖 8 类 decision 的关键子集:
// 1. enabled=false → SafetyDecisionDisabled
// 2. lastCheckInAt=null → SafetyDecisionNoData
// 3. daysSinceLast<threshold → SafetyDecisionOk (含 daysSinceLast 字段)
// 4. lastAlertAt same day + 漏 3 天 → SafetyDecisionAlertedToday
// 5. contacts 空 (stream timeout 降级) → SafetyDecisionNoContacts

import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/logic/safety_detector.dart';
import 'package:chroniccare/domain/usecases/check_safety.dart';
import 'package:flutter_test/flutter_test.dart';

UserProfileEntity _profile() => UserProfileEntity(
      id: 1,
      userName: 'tester',
      firstLaunchAt: DateTime(2026, 1, 1),
      checkInCycleHours: 48,
      userAgreementVersion: null,
      privacyPolicyVersion: null,
      sensitiveDataConsentAt: null,
      consentRevokedAt: null,
    );

ContactEntity _contact({String name = 'Mama'}) => ContactEntity(
      id: 1,
      name: name,
      phone: '13800138000',
      sortOrder: 0,
      isActive: true,
    );

void main() {
  group('CheckSafetyUseCase', () {
    const usecase = CheckSafetyUseCase();
    final now = DateTime(2026, 7, 15, 10, 0);
    final lastCheckIn = now.subtract(const Duration(days: 1));

    test('enabled=false → SafetyDecisionDisabled', () {
      final d = usecase(
        CheckSafetyInput(
          enabled: false,
          threshold: 2,
          lastCheckInAt: lastCheckIn,
          now: now,
          lastAlertAt: null,
          inDnd: false,
          profile: _profile(),
          contacts: [_contact()],
        ),
      );
      expect(d, isA<SafetyDecisionDisabled>());
    });

    test('lastCheckInAt=null → SafetyDecisionNoData (新用户)', () {
      final d = usecase(
        CheckSafetyInput(
          enabled: true,
          threshold: 2,
          lastCheckInAt: null,
          now: now,
          lastAlertAt: null,
          inDnd: false,
          profile: _profile(),
          contacts: [_contact()],
        ),
      );
      expect(d, isA<SafetyDecisionNoData>());
    });

    test('daysSinceLast<threshold → SafetyDecisionOk (24h<2day)', () {
      final d = usecase(
        CheckSafetyInput(
          enabled: true,
          threshold: 2,
          lastCheckInAt: now.subtract(const Duration(hours: 24)),
          now: now,
          lastAlertAt: null,
          inDnd: false,
          profile: _profile(),
          contacts: [_contact()],
        ),
      );
      expect(d, isA<SafetyDecisionOk>());
      expect((d as SafetyDecisionOk).daysSinceLast, 1);
    });

    test('lastAlertAt same day + 漏 3 天 → SafetyDecisionAlertedToday', () {
      final d = usecase(
        CheckSafetyInput(
          enabled: true,
          threshold: 2,
          lastCheckInAt: now.subtract(const Duration(days: 3)),
          now: now,
          lastAlertAt: now.subtract(const Duration(hours: 2)),
          inDnd: false,
          profile: _profile(),
          contacts: [_contact()],
        ),
      );
      expect(d, isA<SafetyDecisionAlertedToday>());
    });

    test('contacts 空 (stream timeout 降级) → SafetyDecisionNoContacts', () {
      final d = usecase(
        CheckSafetyInput(
          enabled: true,
          threshold: 2,
          lastCheckInAt: now.subtract(const Duration(days: 3)),
          now: now,
          lastAlertAt: null,
          inDnd: false,
          profile: _profile(),
          contacts: const [],
        ),
      );
      expect(d, isA<SafetyDecisionNoContacts>());
    });
  });
}
