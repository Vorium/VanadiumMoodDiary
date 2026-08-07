// notification_navigation_round20_test.dart
//
// 测试 NotificationNavigation 的 deep link 路由映射 + 状态管理
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/core/routing/notification_navigation.dart';
import 'package:chroniccare/core/data/services/notification_payload.dart';

void main() {
  setUp(NotificationNavigation.reset);

  group('pathFor (via handleTap + onLink)', () {
    test('todayCheckIn → /check-in/today', () {
      final link = NotificationDeepLink.todayCheckIn();
      NotificationNavigation.handleTap(link.encode());
      expect(NotificationNavigation.onLink.value, isNotNull);
      expect(
        NotificationNavigation.onLink.value!.target,
        DeepLinkTarget.todayCheckIn,
      );
    });

    test('medicationCheckIn → /check-in/medication/{id}', () {
      final link = NotificationDeepLink.medicationCheckIn(42);
      NotificationNavigation.handleTap(link.encode());
      expect(
        NotificationNavigation.onLink.value!.medicationId,
        42,
      );
    });

    test('assessment → /assessment/{scaleId}', () {
      final link = NotificationDeepLink.assessment('gad7');
      NotificationNavigation.handleTap(link.encode());
      expect(
        NotificationNavigation.onLink.value!.scaleId,
        'gad7',
      );
    });

    test('safetyAlert → /check-in/today?reason=safety', () {
      final link = NotificationDeepLink.safetyAlert(5);
      NotificationNavigation.handleTap(link.encode());
      expect(
        NotificationNavigation.onLink.value!.target,
        DeepLinkTarget.safetyAlert,
      );
      expect(
        NotificationNavigation.onLink.value!.daysSince,
        5,
      );
    });
  });

  group('handleTap', () {
    test('null payload → no link set', () {
      NotificationNavigation.handleTap(null);
      expect(NotificationNavigation.onLink.value, isNull);
    });

    test('empty payload → no link set', () {
      NotificationNavigation.handleTap('');
      expect(NotificationNavigation.onLink.value, isNull);
    });

    test('invalid payload → no link set', () {
      NotificationNavigation.handleTap('not-a-valid-payload');
      expect(NotificationNavigation.onLink.value, isNull);
    });
  });

  group('setLaunchPayload', () {
    test('valid payload without router → buffered', () {
      final link = NotificationDeepLink.todayCheckIn();
      NotificationNavigation.setLaunchPayload(link.encode());
      // router 未绑定 → link 被缓冲,不立即跳转
      expect(NotificationNavigation.onLink.value, isNull);
    });

    test('null payload → no-op', () {
      NotificationNavigation.setLaunchPayload(null);
      expect(NotificationNavigation.onLink.value, isNull);
    });
  });

  group('reset', () {
    test('clears all state', () {
      final link = NotificationDeepLink.todayCheckIn();
      NotificationNavigation.handleTap(link.encode());
      expect(NotificationNavigation.onLink.value, isNotNull);

      NotificationNavigation.reset();
      expect(NotificationNavigation.onLink.value, isNull);
    });
  });
}
