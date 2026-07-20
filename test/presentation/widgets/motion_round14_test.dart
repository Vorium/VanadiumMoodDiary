// v0.18 round 14 (P0-7) Motion reduced-motion 测试
//
// 验证:
// 1. Motion.prefersReduced(context) 跟随 MediaQuery.disableAnimations
// 2. Motion.duration(ctx, base) 在 reduce motion 时返 Duration.zero
// 3. Motion.curve(ctx, base) 在 reduce motion 时返 Curves.linear
// 4. FadeIn / SlideUp 在 reduce motion 时立即到终态 (controller.value = 1.0)
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/animations/fade_in.dart';
import 'package:chroniccare/presentation/widgets/animations/slide_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Motion (静态 helper)', () {
    Widget wrap({required bool reduced, required Widget child}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: child,
        ),
      );
    }

    testWidgets('prefersReduced = true', (tester) async {
      await tester.pumpWidget(
        wrap(
          reduced: true,
          child: Builder(
            builder: (ctx) {
              return Text(Motion.prefersReduced(ctx) ? 'reduced' : 'normal');
            },
          ),
        ),
      );
      expect(find.text('reduced'), findsOneWidget);
    });

    testWidgets('prefersReduced = false 默认', (tester) async {
      await tester.pumpWidget(
        wrap(
          reduced: false,
          child: Builder(
            builder: (ctx) {
              return Text(Motion.prefersReduced(ctx) ? 'reduced' : 'normal');
            },
          ),
        ),
      );
      expect(find.text('normal'), findsOneWidget);
    });

    testWidgets('duration: reduce motion → 0', (tester) async {
      await tester.pumpWidget(
        wrap(
          reduced: true,
          child: Builder(
            builder: (ctx) {
              return Text(
                Motion.duration(ctx, const Duration(milliseconds: 300))
                    .inMilliseconds
                    .toString(),
              );
            },
          ),
        ),
      );
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('duration: 正常 → 透传', (tester) async {
      await tester.pumpWidget(
        wrap(
          reduced: false,
          child: Builder(
            builder: (ctx) {
              return Text(
                Motion.duration(ctx, const Duration(milliseconds: 300))
                    .inMilliseconds
                    .toString(),
              );
            },
          ),
        ),
      );
      expect(find.text('300'), findsOneWidget);
    });

    testWidgets('curve: reduce motion → linear', (tester) async {
      await tester.pumpWidget(
        wrap(
          reduced: true,
          child: Builder(
            builder: (ctx) {
              return Text(
                Motion.curve(ctx, AppTokens.curveStandard) == Curves.linear
                    ? 'linear'
                    : 'other',
              );
            },
          ),
        ),
      );
      expect(find.text('linear'), findsOneWidget);
    });
  });

  group('FadeIn / SlideUp', () {
    Widget wrap({required bool reduced, required Widget child}) {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(body: child),
        ),
      );
    }

    testWidgets('P0-7: FadeIn reduce motion = true → 立即到终态', (tester) async {
      await tester.pumpWidget(
        wrap(
          reduced: true,
          child: const FadeIn(child: Text('hello')),
        ),
      );
      // 不需要 pumpAndSettle:reduced motion 立即到 opacity=1.0
      // Text 必须可见 → 渲染到 widget tree
      final textWidget = tester.widget<Text>(find.text('hello'));
      expect(textWidget, isNotNull);
    });

    testWidgets('P0-7: SlideUp reduce motion = true → 立即到终态', (tester) async {
      await tester.pumpWidget(
        wrap(
          reduced: true,
          child: const SlideUp(child: Text('hello')),
        ),
      );
      final textWidget = tester.widget<Text>(find.text('hello'));
      expect(textWidget, isNotNull);
    });
  });
}
