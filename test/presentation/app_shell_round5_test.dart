// 1.1.0 round 5 (emotion-first refactor task 11): 导航 4 tab + shell 集成
//
// 背景: /vent 3 路由 + /trend 原本是 ShellRoute 顶层路由
// (app_route_vent.all / app_route_assessment.all), 底栏/rail 不常驻 +
// tab 高亮失效。task 11 把两 feature 移进 app_route_main 的 ShellRoute,
// _destinations 3 → 4 tab (心情/树洞/趋势/设置, 打卡/用药 tab 摘除)。
//
// A. AppShell widget 层 (dummy router, round17 同款):
//    1. 窄屏 NavigationBar 4 destination, label 顺序 = 心情/树洞/趋势/设置
//    2. currentLocation '/vent' → selectedIndex == 1
//    3. currentLocation '/vent/compose' → selectedIndex == 1 (前缀匹配)
//    4. currentLocation '/mood-review' → selectedIndex == 0 (非 tab 路径回落)
//    5. 宽屏 (1200x800) NavigationRail 4 destination
// B. 路由集成层 (真 AppRoutes.all() 路由表 + MaterialApp.router):
//    6. /vent → NavigationBar 可见 + tab 高亮 1 (证明在 shell 内)
//    7. go /trend → NavigationBar 可见 + tab 高亮 2
//    8. go /vent/compose → NavigationBar 可见 + tab 高亮 1

import 'package:audioplayers_platform_interface/src/audioplayers_platform.dart'
    show AudioplayersPlatform;
import 'package:audioplayers_platform_interface/audioplayers_platform_interface.dart'
    show AudioplayersPlatformInterface, GlobalAudioplayersPlatformInterface;
import 'package:audioplayers_platform_interface/src/global_audioplayers_platform.dart'
    show GlobalAudioplayersPlatform;
import 'package:chroniccare/core/data/services/vent_audio_storage.dart';
import 'package:chroniccare/core/routing/app_router.dart';
import 'package:chroniccare/core/routing/app_routes.dart';
import 'package:chroniccare/core/routing/app_shell.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DummyPage extends StatelessWidget {
  final String label;
  const _DummyPage(this.label);
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(label)));
}

void _setSize(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// A 层: dummy router (round17 同款) — 只测 AppShell 的 tab 渲染/高亮逻辑
Widget _wrapShell({required String currentLocation}) {
  final router = GoRouter(
    initialLocation: currentLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentLocation: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const _DummyPage('home')),
          GoRoute(path: '/vent', builder: (_, __) => const _DummyPage('vent')),
          GoRoute(
            path: '/vent/compose',
            builder: (_, __) => const _DummyPage('compose'),
          ),
          GoRoute(
            path: '/trend',
            builder: (_, __) => const _DummyPage('trend'),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const _DummyPage('settings'),
          ),
          GoRoute(
            path: '/mood-review',
            builder: (_, __) => const _DummyPage('mood-review'),
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [routerProvider.overrideWithValue(router)],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      routerConfig: router,
    ),
  );
}

/// vent compose dispose 链 (asyncDisposeAudio) 会碰 audioplayers/record
/// platform channel — 无 mock 时 MissingPluginException 冒到 test zone。
class _FakeVentAudioStorage extends VentAudioStorage {
  @override
  Future<String> newTempRecordPath() async => '/tmp/vent_record_1.m4a';

  @override
  Future<String> newAudioPath() async => '/tmp/vent_1.m4a.enc';

  @override
  Future<void> encryptAndWrite({
    required String plainPath,
    required String encryptedPath,
  }) async {}
}

void _mockAudioChannels() {
  AudioplayersPlatformInterface.instance = AudioplayersPlatform();
  GlobalAudioplayersPlatformInterface.instance = GlobalAudioplayersPlatform();
  final messenger =
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (call) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async {
      if (call.method == 'create') {
        final playerId = (call.arguments as Map)['playerId'] as String;
        messenger.setMockStreamHandler(
          EventChannel('xyz.luan/audioplayers/events/$playerId'),
          MockStreamHandler.inline(
            onListen: (arguments, events) {},
            onCancel: (_) {},
          ),
        );
        return 'test-player';
      }
      return null;
    },
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('com.llfbandit.record/messages'),
    (call) async {
      if (call.method == 'hasPermission') return true;
      return null;
    },
  );
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    return null;
  });
}

/// B 层: 真 AppRoutes.all() 路由表 — 证明 /vent /trend 在 ShellRoute 内
///
/// 页面 provider 全部 override (trend 的 checkIns/mood/medication 流 +
/// vent 条目流), 不碰真 drift isolate (widget test FakeAsync 下真 DB await
/// 会 hang, setup_page_state_round112 同款决策)。
Widget _wrapRealRouter({
  required String initialLocation,
  required SharedPreferences sp,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: AppRoutes.all(),
    errorBuilder: AppRoutes.errorBuilder,
  );
  return ProviderScope(
    overrides: [
      routerProvider.overrideWithValue(router),
      sharedPreferencesProvider.overrideWithValue(sp),
      ventAudioStorageProvider.overrideWithValue(_FakeVentAudioStorage()),
      ventEntriesProvider.overrideWith(
        (ref) => Stream.value(const <VentEntryEntity>[]),
      ),
      allCheckInsProvider.overrideWith(
        (ref) => Stream.value(const <CheckInEntity>[]),
      ),
      allMoodProvider.overrideWith(
        (ref) => Stream.value(const <MoodEntryEntity>[]),
      ),
      assessmentsProvider.overrideWith(
        (ref) => Stream.value(const <CheckInEntity>[]),
      ),
      allMedicationsProvider.overrideWith(
        (ref) => Stream.value(const <MedicationEntity>[]),
      ),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      routerConfig: router,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _mockAudioChannels();
  });

  // ===== A. AppShell widget 层 =====

  testWidgets('A1: 窄屏 NavigationBar 4 destination, 顺序 心情/树洞/趋势/设置', (
    tester,
  ) async {
    _setSize(tester, 400, 800);
    await tester.pumpWidget(_wrapShell(currentLocation: '/'));
    await tester.pumpAndSettle();

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.destinations.length, 4);
    expect(
      (bar.destinations[0] as NavigationDestination).label,
      '心情',
    );
    expect(
      (bar.destinations[1] as NavigationDestination).label,
      '树洞',
    );
    expect(
      (bar.destinations[2] as NavigationDestination).label,
      '趋势',
    );
    expect(
      (bar.destinations[3] as NavigationDestination).label,
      '设置',
    );
  });

  testWidgets('A2: currentLocation /vent → selectedIndex 1', (tester) async {
    _setSize(tester, 400, 800);
    await tester.pumpWidget(_wrapShell(currentLocation: '/vent'));
    await tester.pumpAndSettle();

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 1);
  });

  testWidgets('A3: currentLocation /vent/compose → selectedIndex 1 (前缀匹配)', (
    tester,
  ) async {
    _setSize(tester, 400, 800);
    await tester.pumpWidget(_wrapShell(currentLocation: '/vent/compose'));
    await tester.pumpAndSettle();

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 1);
  });

  testWidgets('A4: currentLocation /mood-review → selectedIndex 0 (心情 tab)', (
    tester,
  ) async {
    _setSize(tester, 400, 800);
    await tester.pumpWidget(_wrapShell(currentLocation: '/mood-review'));
    await tester.pumpAndSettle();

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 0);
  });

  testWidgets('A5: 宽屏 1200x800 走 NavigationRail, 4 destination', (
    tester,
  ) async {
    _setSize(tester, 1200, 800);
    await tester.pumpWidget(_wrapShell(currentLocation: '/'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.destinations.length, 4);
  });

  // ===== B. 路由集成层 (真路由表) =====

  testWidgets('B6: /vent 在 shell 内 — NavigationBar 常驻 + tab 高亮 1', (
    tester,
  ) async {
    _setSize(tester, 400, 800);
    final sp = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrapRealRouter(initialLocation: '/vent', sp: sp));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 1);
  });

  testWidgets('B7: go /trend 后 NavigationBar 常驻 + tab 高亮 2', (
    tester,
  ) async {
    _setSize(tester, 400, 800);
    final sp = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrapRealRouter(initialLocation: '/vent', sp: sp));
    await tester.pumpAndSettle();

    // 从 NavigationBar 拿 context, 走 context.go — 跟 tab 点击同一条路径
    GoRouter.of(tester.element(find.byType(NavigationBar))).go('/trend');
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 2);
  });

  testWidgets('B8: go /vent/compose 后 NavigationBar 常驻 + tab 高亮 1', (
    tester,
  ) async {
    _setSize(tester, 400, 800);
    final sp = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrapRealRouter(initialLocation: '/vent', sp: sp));
    await tester.pumpAndSettle();

    GoRouter.of(tester.element(find.byType(NavigationBar))).go('/vent/compose');
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 1);
  });
}
