// R114 Wave B2: PageScaffold 宽屏顶层路由返回按钮 (B2-3)
//
// apple F-04: 修前 page_scaffold.dart:88 `appBar: (title != null && !isWide)
// ? translucentBar : null` — >= 840pt 宽屏下 push 进去的 /tips/:id
// /worry/:id 等顶层路由 AppBar 整体消失, 无任何返回入口 (只能浏览器 back)。
//
// 修法: 宽屏 + canPop (push 子页) 时保留 AppBar (title + 返回按钮);
// 宽屏 + 不可 pop (shell tab 根) 保持无 AppBar (NavigationRail 负责导航)。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

GoRouter _router(String initial) => GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(body: SizedBox()),
        ),
        GoRoute(
          path: '/child',
          builder: (_, __) => const PageScaffold(
            title: 'child',
            child: Text('child-content'),
          ),
        ),
      ],
    );

Future<void> _pumpWide(WidgetTester tester, GoRouter router) async {
  tester.view.physicalSize = const Size(900 * 3, 600 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('宽屏 + canPop (push 子页) → AppBar 保留 + 返回按钮可见', (tester) async {
    final router = _router('/');
    await _pumpWide(tester, router);
    router.push('/child');
    await tester.pumpAndSettle();

    expect(
      find.byType(AppBar),
      findsOneWidget,
      reason: '修前宽屏顶层路由 AppBar 整体消失 (无返回入口)',
    );
    expect(
      find.byIcon(Icons.arrow_back_rounded),
      findsOneWidget,
      reason: '宽屏 push 子页必须有返回按钮',
    );
    expect(find.text('child'), findsOneWidget);
    expect(find.text('child-content'), findsOneWidget);
  });

  testWidgets('窄屏 + canPop → AppBar 保留 (既有行为不回归)', (tester) async {
    final router = _router('/');
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    router.push('/child');
    await tester.pumpAndSettle();
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
  });

  testWidgets('宽屏 + 不可 pop (shell tab 根) → 无 AppBar (NavigationRail 导航)',
      (tester) async {
    await _pumpWide(tester, _router('/'));
    expect(
      find.byType(AppBar),
      findsNothing,
      reason: '宽屏 tab 根路由仍不显示 AppBar (NavigationRail 负责导航, 既有行为)',
    );
  });

  testWidgets('title=null → 不渲染 AppBar + 不崩 (P3-CLEAN-9)', (tester) async {
    // 修前 translucentBar 无条件 `Text(title!)` — title null 时构建 AppBar
    // 对象即 null-check 崩溃 (哪怕 appBar: null 不会 mount)。
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PageScaffold(
            title: null,
            child: Text('no-title-content'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byType(AppBar),
      findsNothing,
      reason: 'title null → appBar 条件 false, 不显示 AppBar',
    );
    expect(find.text('no-title-content'), findsOneWidget);
  });
}
