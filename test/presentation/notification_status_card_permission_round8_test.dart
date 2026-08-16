// v0.32 round 8 (R111 GP-10 fix): Android 14+ 通知权限拒绝后重新授权 UI
//
// 背景: requestPermission() 在 Android 14+ 被永久拒绝后无法再弹系统框,
// 用户误拒 → 提醒静默失效且 App 内无任何重新授权入口 (GP-10, R110 跨期
// 残留)。修: 测试通知/请求权限返 false 时, 弹引导 dialog (通知权限已关闭
// + "前往系统设置" 按钮走 permission_handler.openAppSettings)。
//
// 覆盖:
// 1. requestPermission=false → 引导 dialog 弹出 + 不发测试通知
// 2. 点"前往系统设置" → openAppSettings 被调 + dialog 关闭
// 3. requestPermission=true → 正常发测试通知 (回归守卫)
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/notification_status_card.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubNotificationService extends NotificationService {
  final bool permissionResult;
  bool showNowCalled = false;

  _StubNotificationService({required this.permissionResult});

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => permissionResult;

  @override
  Future<int> get pendingCount async => 1;

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    showNowCalled = true;
  }

  @override
  Future<void> cancelAll() async {}
}

void _setBigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrap(_StubNotificationService service) {
  return ProviderScope(
    overrides: [
      notificationServiceProvider.overrideWithValue(service),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: NotificationStatusCard()),
    ),
  );
}

void main() {
  group('v0.32 round 8 (GP-10) — 通知权限拒绝重新授权 UI', () {
    testWidgets('1. requestPermission=false → 引导 dialog + 不发测试通知',
        (tester) async {
      _setBigView(tester);
      final service = _StubNotificationService(permissionResult: false);
      await tester.pumpWidget(_wrap(service));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('测试通知'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('通知权限已关闭'),
        findsOneWidget,
        reason: '拒绝权限后应弹引导 dialog',
      );
      expect(
        find.text('前往系统设置'),
        findsOneWidget,
        reason: '给用户系统设置重新授权入口 (GP-10)',
      );
      expect(
        service.showNowCalled,
        isFalse,
        reason: '权限被拒时不发测试通知',
      );
    });

    testWidgets('2. 点"前往系统设置" → openAppSettings 被调 + dialog 关闭',
        (tester) async {
      _setBigView(tester);
      final service = _StubNotificationService(permissionResult: false);

      String? lastMethod;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (call) async {
          lastMethod = call.method;
          return true;
        },
      );
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('flutter.baseflow.com/permissions/methods'),
          null,
        );
      });

      await tester.pumpWidget(_wrap(service));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('测试通知'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('前往系统设置'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        lastMethod,
        'openAppSettings',
        reason: '点前往系统设置应调 openAppSettings',
      );
      expect(
        find.text('通知权限已关闭'),
        findsNothing,
        reason: 'dialog 应关闭',
      );
    });

    testWidgets('3. requestPermission=true → 正常发测试通知 (无 dialog)',
        (tester) async {
      _setBigView(tester);
      final service = _StubNotificationService(permissionResult: true);
      await tester.pumpWidget(_wrap(service));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('测试通知'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('通知权限已关闭'), findsNothing);
      expect(service.showNowCalled, isTrue);
    });
  });
}
