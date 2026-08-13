// v0.32 round 8 (R111 SP-111-14 fix): reminders_hub 失联通知卡 flag gate 0 测试
//
// 背景: R110 round 3 (AS-07 gate) 给失联通知卡挂 emergencyContactEnabled
// flag (false = 生产默认, 整段不渲染, App Store 5.1.1 抽审安全), 但
// round12c 老测试只在 setUp enableForTest() 翻 true 后断言卡渲染,
// gate 的 false 路径 (隐藏) 0 覆盖 — flag 回归 true / gate 被误删都测不出。
//
// 覆盖:
// 1. flag=false (生产默认) → 失联通知卡不渲染, 其余 4 卡照常
// 2. flag=true → 失联通知卡渲染 (跟 round12c 一致, 独立 gate 验证)
// 3. gate 只影响失联卡, 不影响评估卡 (隔离性)
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/reminders_hub_page.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';

class _NoopNotificationService extends NotificationService {
  @override
  Future<void> init() async {}
}

void _setBigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrap() {
  return ProviderScope(
    overrides: [
      notificationServiceProvider.overrideWithValue(_NoopNotificationService()),
      medicationsProvider.overrideWith((ref) => Stream.value(const [])),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: RemindersHubPage()),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(FeatureFlags.resetForTest);

  group('v0.32 round 8 (SP-111-14) — 失联通知卡 flag gate', () {
    testWidgets('1. flag=false (生产默认) → 失联通知卡不渲染, 其余 4 卡照常',
        (tester) async {
      // resetForTest 已在 tearDown 清 override; 这里显式确认生产默认 false
      expect(FeatureFlags.emergencyContactEnabled, isFalse,
          reason: '生产默认 false (失联业务暂停, App Store 5.1.1 抽审安全)',);

      _setBigView(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 失联通知卡整段不渲染 (gate 生效)
      expect(find.text('失联通知（安全开关）'), findsNothing,
          reason: 'flag=false 时失联通知卡必须整段不渲染 (AS-07 gate)',);
      // 其余 4 卡照常
      expect(find.text('每日打卡提醒'), findsOneWidget);
      expect(find.text('用药提醒'), findsOneWidget);
      expect(find.text('续方提醒'), findsOneWidget);
      expect(find.text('周期评估提醒'), findsOneWidget);
    });

    testWidgets('2. flag=true → 失联通知卡渲染 (跟 round12c 独立 gate 验证)',
        (tester) async {
      FeatureFlags.enableForTest();
      expect(FeatureFlags.emergencyContactEnabled, isTrue);

      _setBigView(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('失联通知（安全开关）'), findsOneWidget,
          reason: 'flag=true 时失联通知卡渲染',);
    });

    testWidgets('3. gate 隔离性: flag=false 只影响失联卡, 评估卡不受影响',
        (tester) async {
      expect(FeatureFlags.emergencyContactEnabled, isFalse);

      _setBigView(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('周期评估提醒'), findsOneWidget,
          reason: '评估卡不走 emergencyContactEnabled gate',);
      expect(find.text('失联通知（安全开关）'), findsNothing);
    });
  });
}
