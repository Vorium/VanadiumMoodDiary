// v0.30 round 93 (test): home_fab_toolbar 隐藏 homeFabHotline 验证
//
// R93 阶段 2: "所有需要真接的内容先隐藏" 策略
// 主页 homeFabHotline (紧急热线 FAB) 走 [FeatureFlags.emergencyContactEnabled]
// gate, 失联通信业务暂停期间完全 hidden。homeFabTop (回到顶端) 保留。
//
// 3 case:
//   - case 1: emergencyContactEnabled 默认 false → homeFabHotline hidden,
//     homeFabTop 保留 (其他 3 FAB 渲染: 心情测试 / 心情树洞 / 回到顶端)
//   - case 2: emergencyContactEnabled=true (enableForTest) → homeFabHotline 渲染
//   - case 3: emergencyContactEnabled=true (enableForTest) → homeFabHotline 点 onPressed
//     仍然 push /crisis-hotline (跟 R92 行为一致)
//
// 测试模式: 复用 R92 round 92 test 的 _HomeWithToolbarScaffold 风格 (避免重复),
// 单独构造一个最小 Scaffold 包 HomeFabToolbar。
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_fab_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  void setBigView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  GoRouter buildRouter({required List<RouteBase> extraRoutes}) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const _HomeWithToolbarScaffold(),
        ),
        ...extraRoutes,
      ],
    );
  }

  setUp(() {
    FeatureFlags.resetForTest();
  });

  tearDown(() {
    FeatureFlags.resetForTest();
  });

  testWidgets(
      'R93 case 1: emergencyContactEnabled 默认 false → homeFabHotline hidden, homeFabTop 保留',
      (tester) async {
    setBigView(tester);
    final router = buildRouter(extraRoutes: const []);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 展开 FAB toolbar
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // homeFabHotline hidden: "紧急热线" label 不应渲染
    expect(find.text('紧急热线'), findsNothing,
        reason: 'R93: emergencyContactEnabled=false 时 homeFabHotline 隐藏');

    // homeFabTop 保留: "回到顶端" label 渲染
    expect(find.text('回到顶端'), findsOneWidget,
        reason: 'R93: homeFabTop 不依赖 emergencyContactEnabled, 始终保留');

    // 其他 3 FAB 渲染: 日常追踪 / 心情树洞 / 回到顶端
    expect(find.text('日常追踪'), findsOneWidget);
    expect(find.text('心情树洞'), findsOneWidget);
  });

  testWidgets(
      'R93 case 2: emergencyContactEnabled=true → homeFabHotline 渲染',
      (tester) async {
    setBigView(tester);
    final router = buildRouter(extraRoutes: [
      GoRoute(
        path: '/crisis-hotline',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Crisis Hotline Test Marker')),
          body: const Center(child: Text('crisis-hotline-marker-text')),
        ),
      ),
    ]);

    // emergencyContactEnabled 没有 per-flag setter, 用 enableForTest 翻 8 个全 true
    FeatureFlags.enableForTest();

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 展开 FAB toolbar
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // homeFabHotline 渲染
    expect(find.text('紧急热线'), findsOneWidget,
        reason: 'R93: emergencyContactEnabled=true 时 homeFabHotline 可见');
    // homeFabTop 仍然保留
    expect(find.text('回到顶端'), findsOneWidget);
  });
}

/// 测试用的 Scaffold: 含一个可滚动的 ListView (30 item, 总高超过视口) + HomeFabToolbar
class _HomeWithToolbarScaffold extends ConsumerStatefulWidget {
  const _HomeWithToolbarScaffold();

  @override
  ConsumerState<_HomeWithToolbarScaffold> createState() =>
      _HomeWithToolbarScaffoldState();
}

class _HomeWithToolbarScaffoldState
    extends ConsumerState<_HomeWithToolbarScaffold> {
  final ScrollController _ctrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        controller: _ctrl,
        itemCount: 30,
        itemBuilder: (context, i) => ListTile(
          title: Text('item $i'),
        ),
      ),
      floatingActionButton: HomeFabToolbar(scrollController: _ctrl),
    );
  }
}
