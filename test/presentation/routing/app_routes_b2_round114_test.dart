// R114 Wave B2: 路由过渡统一 + iOS swipe-back (B2-1 / B2-2)
//
// B2-1 (emil F1 + apple F-02 共识): 4 个 shell tab 根路由统一 fadePage —
//   /vent (修前 slideUpPage 400ms 全屏 modal 感) / /trend (修前
//   slideRightPage) 改为 fadePage, 同动作同体感; slideUp/slideRight 只留给
//   push 子页 (/vent/compose /vent/detail /assessment/* ...)。
// B2-2 (apple F-05): CustomTransitionPage 无 iOS interactive pop —
//   slideRightPage / slideUpPage 在 iOS 平台改用 go_router CupertinoPage
//   (原生滑入 + 右滑返回手势 + 33% 视差), 其他平台保留自定义 10% 微滑。
//
// 测试策略: helper 级直接调用 (pump 一个拿 context 的 Builder), 不构建
// 完整 GoRouter (AppShell/pages 依赖 Riverpod providers, 与本次修复无关)。
// iOS 分支用 debugDefaultTargetPlatformOverride。

import 'dart:io';

import 'package:flutter/cupertino.dart' show CupertinoPageRoute;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/routing/app_routes.dart';

Future<(BuildContext, Page<dynamic>)> _pageFor(
  WidgetTester tester,
  Page<dynamic> Function(BuildContext) factory,
) async {
  late BuildContext ctx;
  late Page<dynamic> page;
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) {
          ctx = context;
          page = factory(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return (ctx, page);
}

Widget _transitionSubtree(
  CustomTransitionPage<dynamic> page,
  BuildContext context,
) {
  return KeyedSubtree(
    key: const ValueKey('transition-under-test'),
    child: page.transitionsBuilder(
      context,
      const AlwaysStoppedAnimation(0.5),
      const AlwaysStoppedAnimation(0.5),
      const SizedBox(),
    ),
  );
}

/// 只找被测 transition 子树内的 widget (MaterialApp home route 自带
/// FadeTransition/SlideTransition, 不能全局 find)
Finder _inSubtree(Finder matching) => find.descendant(
      of: find.byKey(const ValueKey('transition-under-test')),
      matching: matching,
    );

void main() {
  group('B2-1: 4 个 shell tab 根路由统一 fadePage', () {
    test('lock-in: /vent 根路由用 fadePage (修前 slideUpPage)', () async {
      final src =
          await File('lib/core/routing/app_route_vent.dart').readAsString();
      expect(
        RegExp(r"path: '/vent',[\s\S]{0,200}?fadePage\(state\.pageKey")
            .hasMatch(src),
        isTrue,
        reason: '/vent 是 shell tab 根路由, 应走 fadePage (同 / /settings 体感)',
      );
      // push 子页保留 slide-up 全屏深页语义
      expect(
        RegExp(r"path: '/vent/compose',[\s\S]{0,200}?slideUpPage")
            .hasMatch(src),
        isTrue,
        reason: '/vent/compose 是 push 子页, 保留 slideUpPage',
      );
    });

    test('lock-in: /trend 根路由用 fadePage (修前 slideRightPage)', () async {
      final src = await File('lib/core/routing/app_route_assessment.dart')
          .readAsString();
      expect(
        RegExp(r"path: '/trend',[\s\S]{0,200}?fadePage\(state\.pageKey")
            .hasMatch(src),
        isTrue,
        reason: '/trend 是 shell tab 根路由, 应走 fadePage',
      );
    });
  });

  group('B2-1/B2-2: transition helper 行为', () {
    testWidgets('fadePage → CustomTransitionPage + 纯 FadeTransition (无 slide)',
        (tester) async {
      final (ctx, page) = await _pageFor(
        tester,
        (c) => AppRoutes.fadePage(const ValueKey('k'), const SizedBox(), c),
      );
      expect(page, isA<CustomTransitionPage<dynamic>>());
      await tester.pumpWidget(
        MaterialApp(
            home:
                _transitionSubtree(page as CustomTransitionPage<dynamic>, ctx)),
      );
      expect(_inSubtree(find.byType(FadeTransition)), findsOneWidget);
      expect(_inSubtree(find.byType(SlideTransition)), findsNothing);
    });

    testWidgets(
        'slideRightPage → CustomTransitionPage + SlideTransition (10% 微滑)',
        (tester) async {
      final (ctx, page) = await _pageFor(
        tester,
        (c) =>
            AppRoutes.slideRightPage(const ValueKey('k'), const SizedBox(), c),
      );
      expect(page, isA<CustomTransitionPage<dynamic>>());
      await tester.pumpWidget(
        MaterialApp(
            home:
                _transitionSubtree(page as CustomTransitionPage<dynamic>, ctx)),
      );
      expect(_inSubtree(find.byType(SlideTransition)), findsOneWidget);
    });

    testWidgets('slideUpPage → CustomTransitionPage + SlideTransition',
        (tester) async {
      final (ctx, page) = await _pageFor(
        tester,
        (c) => AppRoutes.slideUpPage(const ValueKey('k'), const SizedBox(), c),
      );
      expect(page, isA<CustomTransitionPage<dynamic>>());
      await tester.pumpWidget(
        MaterialApp(
            home:
                _transitionSubtree(page as CustomTransitionPage<dynamic>, ctx)),
      );
      expect(_inSubtree(find.byType(SlideTransition)), findsOneWidget);
    });

    testWidgets(
        'B2-2: iOS 平台 slideRightPage → CupertinoPageRoute (原生 swipe-back)',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final (ctx, page) = await _pageFor(
        tester,
        (c) =>
            AppRoutes.slideRightPage(const ValueKey('k'), const SizedBox(), c),
      );
      final route = page.createRoute(ctx);
      debugDefaultTargetPlatformOverride = null;
      expect(
        route,
        isA<CupertinoPageRoute<dynamic>>(),
        reason: 'iOS push 子页应走 CupertinoPageRoute (右滑返回 + 33% 视差)',
      );
      expect((route as CupertinoPageRoute<dynamic>).fullscreenDialog, isFalse);
    });

    testWidgets('B2-2: iOS 平台 slideUpPage 保持 CustomTransitionPage (modal 语义)',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final (_, page) = await _pageFor(
        tester,
        (c) => AppRoutes.slideUpPage(const ValueKey('k'), const SizedBox(), c),
      );
      debugDefaultTargetPlatformOverride = null;
      expect(
        page,
        isA<CustomTransitionPage<dynamic>>(),
        reason:
            'slide-up = 全屏 modal 语义 (/setup /crisis-hotline /vent/compose), '
            '无 swipe-back 是正确平台惯例',
      );
    });

    testWidgets('B2-2: fadePage 各平台保持 CustomTransitionPage (tab 无需手势)',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final (_, page) = await _pageFor(
        tester,
        (c) => AppRoutes.fadePage(const ValueKey('k'), const SizedBox(), c),
      );
      debugDefaultTargetPlatformOverride = null;
      expect(page, isA<CustomTransitionPage<dynamic>>());
    });
  });
}
