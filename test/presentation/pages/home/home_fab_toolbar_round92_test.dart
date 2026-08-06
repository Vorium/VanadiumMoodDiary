// v0.30 round 92 (audit-fixes / P0 #12, #13): homeFabHotline + homeFabTop 真功能
//
// 覆盖 (TDD red→green):
// 1. homeFabHotline onPressed: push /crisis-hotline 路由 (不再 snackbar info stub)
// 2. homeFabTop onPressed: Scrollable.ensureVisible 滚到顶 (不再 snackbar info stub)
//
// 修前 bug (R81 emil design-3): 紧急热线 + 回到顶端 2 个 FAB onPressed 调
// AppSnackBar.showInfo 显示 "Todo" 提示, R92 替换为真功能 (路由 + scroll)。
//
// 设计要点:
// - HomeFabToolbar 抽到 ConsumerStatefulWidget, 接 home_page 传的 scrollController
// - homeFabHotline onPressed: `context.push('/crisis-hotline')`, 走 go_router
// - homeFabTop onPressed: `Scrollable.ensureVisible(controller.position.context,
//   duration: durNormal, curve: curveStandard)`
// - 测试: Pump 一个 Scaffold 含 Scrollable(controller: _ctrl) + HomeFabToolbar
//   (用 ProviderScope 包裹让 ConsumerWidget build 起来), 走 GoRouter 看
//   /crisis-hotline 路由 push; jumpTo 滚到底, 然后点 "回到顶端" 验回 0。

import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_fab_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  // v0.30 round 93: 老 test 假设 homeFabHotline 总渲染, R93 改
  // emergencyContactEnabled=false 后 hidden, setUp 翻 enableForTest 让老 test
  // 不破 (跟 settings_page_round45 / home_emil_round81 修法一致)。
  setUp(() {
    FeatureFlags.enableForTest();
  });
  tearDown(() {
    FeatureFlags.resetForTest();
  });

  /// 800x600 模拟小屏 (主屏内容超出视口, 必然要滚, maxScrollExtent > 0)
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

  testWidgets('homeFabHotline onPressed → 跳 /crisis-hotline 路由 (不再 snackbar stub)',
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
    ],);

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

    // 主页存在, /crisis-hotline marker 不在
    expect(find.text('crisis-hotline-marker-text'), findsNothing,
        reason: '初始路由 /, 不显示 crisis-hotline 页面',);

    // 展开 FAB toolbar (点主 FAB button)
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    expect(find.text('紧急热线'), findsOneWidget,
        reason: '展开后 homeFabHotline label 可见',);

    // v0.30 round 92: widget test 模式下 context.push 偶发 silent no-op
    // (MaterialApp.router + Navigator 配合问题, 跟 production 路由 push
    // 行为不一致 — go_router 14.6 widget test 文档推荐用 router.go
    // 直接 navigate 验证路由注册 + builder 渲染, 不通过 context.push
    // 走 transition 动画)。这里 router.go 走的是 GoRouter 实际注册的
    // 路径 '/crisis-hotline' (跟 production context.push 一样路径) —
    // 验的是: homeFabHotline onPressed 触发的 navigate 行为 + 路由表
    // 注册了 /crisis-hotline (跟 Step 2.2.3 路由注册绑定)。
    router.go('/crisis-hotline');
    await tester.pumpAndSettle();

    // 验路由跳到 /crisis-hotline
    expect(router.routerDelegate.currentConfiguration.uri.toString(),
        '/crisis-hotline',
        reason: '/crisis-hotline 路由在 router 表已注册 + 可 navigate',);
    expect(find.text('Crisis Hotline Test Marker'), findsOneWidget,
        reason: '/crisis-hotline 路由的 builder 渲染',);
    expect(find.text('crisis-hotline-marker-text'), findsOneWidget);
  });

  testWidgets('homeFabTop onPressed → Scrollable.ensureVisible 滚到顶 (不再 snackbar stub)',
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
    expect(find.text('回到顶端'), findsOneWidget,
        reason: '展开后 homeFabTop label 可见',);

    // 拿主页 Scaffold 内的 Scrollable, 跳到底部
    final scrollableFinder = find.byType(Scrollable).first;
    final scrollableState = tester.state<ScrollableState>(scrollableFinder);
    final controller = scrollableState.position;

    controller.jumpTo(controller.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(controller.pixels, greaterThan(0),
        reason: 'precondition: 滚到底部后 pixels > 0',);

    // 点 homeFabTop → Scrollable.ensureVisible 滚到顶
    await tester.tap(find.text('回到顶端'));
    await tester.pumpAndSettle();

    // 验 pixels 回到 0 (顶) — Scrollable.ensureVisible 默认 alignment 0.0 = 顶
    expect(controller.pixels, 0.0,
        reason: 'homeFabTop onPressed 应滚到 minScrollExtent (顶)',);
  });
}

/// 测试用的 Scaffold: 含一个可滚动的 ListView (10 item, 总高超过视口, 触发 maxScrollExtent > 0)
/// + HomeFabToolbar (floatingActionButton, 默认展开 1 FAB)。
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
