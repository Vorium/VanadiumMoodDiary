// v0.32 R112 (R112-ARCH-02): notification_deep_link_resolver 纯函数单测
//
// 覆盖:
// - 3 类 action → 最终 route path (today / medication / assessment)
//   (1.1.0 round 4b: safety-alert 随外联服务整摘)
// - null / 空 / 非法 payload → null (不跳转)
// - 未知 action / 缺 path segment → null
import 'package:chroniccare/domain/logic/notification_deep_link_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveNotificationDeepLinkRoute — 3 类 action → path', () {
    test('today → /check-in/today', () {
      expect(
        resolveNotificationDeepLinkRoute('chroniccare://today'),
        '/check-in/today',
      );
    });

    test('medication/42 → /check-in/medication/42', () {
      expect(
        resolveNotificationDeepLinkRoute('chroniccare://medication/42'),
        '/check-in/medication/42',
      );
    });

    test('medication/0 (非法 id 兜底 0, 跟 parse 一致) → /check-in/medication/0', () {
      expect(
        resolveNotificationDeepLinkRoute('chroniccare://medication/abc'),
        '/check-in/medication/0',
      );
    });

    test('assessment/gad7 → /assessment/gad7', () {
      expect(
        resolveNotificationDeepLinkRoute('chroniccare://assessment/gad7'),
        '/assessment/gad7',
      );
    });

    test('mood-diary → /mood-diary (R113 BUG 4: 情绪提醒通知点击直达)', () {
      expect(
        resolveNotificationDeepLinkRoute('chroniccare://mood-diary'),
        '/mood-diary',
      );
    });

    test('check-in/today (旧 payload) → /check-in/today (R114 BUG 1)', () {
      expect(
        resolveNotificationDeepLinkRoute('chroniccare://check-in/today'),
        '/check-in/today',
      );
    });

    test('R114 BUG 1: 5 类 payload 全部能 resolve (点击通知不落 null)', () {
      final payloads = <String>[
        'chroniccare://today', // NotificationDeepLink.todayCheckIn().encode()
        'chroniccare://check-in/today', // 旧版硬编码 (已调度旧通知)
        'chroniccare://medication/42',
        'chroniccare://assessment/gad7',
        'chroniccare://mood-diary',
      ];
      for (final payload in payloads) {
        expect(
          resolveNotificationDeepLinkRoute(payload),
          isNotNull,
          reason: 'payload [$payload] 必须 resolve (null = 点击通知死链)',
        );
      }
    });

    test('safety-alert/5 → null (round 4b: safety-alert action 整摘)', () {
      expect(
        resolveNotificationDeepLinkRoute('chroniccare://safety-alert/5'),
        isNull,
      );
    });
  });

  group('resolveNotificationDeepLinkRoute — 非法输入 → null', () {
    test('null payload → null', () {
      expect(resolveNotificationDeepLinkRoute(null), isNull);
    });

    test('空字符串 → null', () {
      expect(resolveNotificationDeepLinkRoute(''), isNull);
    });

    test('非 chroniccare scheme → null', () {
      expect(resolveNotificationDeepLinkRoute('https://example.com'), isNull);
    });

    test('非 URI 字符串 → null', () {
      expect(resolveNotificationDeepLinkRoute('not-a-valid-payload'), isNull);
    });

    test('未知 action → null', () {
      expect(resolveNotificationDeepLinkRoute('chroniccare://unknown'), isNull);
    });

    test('medication 缺 path segment → null', () {
      expect(
        resolveNotificationDeepLinkRoute('chroniccare://medication'),
        isNull,
      );
    });

    test('assessment 缺 path segment → null', () {
      expect(
        resolveNotificationDeepLinkRoute('chroniccare://assessment'),
        isNull,
      );
    });
  });
}
