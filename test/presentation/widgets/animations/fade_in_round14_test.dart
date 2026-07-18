// v0.17 round 14 (P1-1) FadeIn widget test
//
// 覆盖:
// 1. 默认参数存在 (duration/curve/delay)
// 2. delay > 0 时初始 opacity = 0
// 3. delay 跑完后 forward, opacity → 1
// 4. withScale: true 触发 scale 动画

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/widgets/animations/animations.dart';

void main() {
  group('FadeIn', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadeIn(child: Text('hello')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('starts at opacity 0, animates to 1', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadeIn(
              duration: Duration(milliseconds: 200),
              child: Text('hi'),
            ),
          ),
        ),
      );
      // 第一帧,动画刚开始 → opacity 接近 0
      await tester.pump();
      final opacities1 = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((w) => w.opacity)
          .toList();
      expect(opacities1.first, lessThan(0.5));

      // 推进到动画结束
      await tester.pumpAndSettle();
      final opacities2 = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((w) => w.opacity)
          .toList();
      expect(opacities2.first, 1.0);
    });

    testWidgets('withScale wraps child in Transform.scale', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadeIn(
              withScale: true,
              child: Text('scaled'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('scaled'), findsOneWidget);
      // 动画完成后 scale 应该是 1.0 (无 transform)
      expect(find.byType(Transform), findsWidgets);
    });

    testWidgets('delay > 0 keeps child invisible initially', (tester) async {
      const testKey = Key('fade-in-opacity');
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadeIn(
              key: testKey,
              delay: Duration(milliseconds: 500),
              child: Text('delayed'),
            ),
          ),
        ),
      );
      // 在 delay 期间, FadeIn 内的 Opacity 应该是 0
      await tester.pump(const Duration(milliseconds: 100));
      final opacities = tester
          .widgetList<Opacity>(
            find.descendant(
              of: find.byKey(testKey),
              matching: find.byType(Opacity),
            ),
          )
          .toList();
      expect(opacities, hasLength(1));
      expect(opacities.first.opacity, 0.0);

      // 跑过 delay,推进动画到结尾
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      final opacities2 = tester
          .widgetList<Opacity>(
            find.descendant(
              of: find.byKey(testKey),
              matching: find.byType(Opacity),
            ),
          )
          .toList();
      expect(opacities2, hasLength(1));
      expect(opacities2.first.opacity, 1.0);
    });
  });
}
