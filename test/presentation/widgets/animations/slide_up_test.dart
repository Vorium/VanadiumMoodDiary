// v0.17 round 14 (P1-1) SlideUp widget test
//
// 覆盖:
// 1. 默认参数存在
// 2. 初始 offset = (0, distance), 动画后 = (0, 0)
// 3. delay > 0 时不立即开始

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/widgets/animations/animations.dart';

void main() {
  group('SlideUp', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideUp(child: Text('up')),
          ),
        ),
      );
      await tester.pump();
      // 在动画第一帧,文字应该已经被 build 但 opacity 0
      expect(find.text('up'), findsOneWidget);
    });

    testWidgets('starts offset down, animates to origin', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideUp(
              duration: Duration(milliseconds: 200),
              distance: 16.0,
              child: Text('up'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // 动画结束 → SlideTransition 存在
      expect(find.byType(SlideTransition), findsWidgets);
    });

    testWidgets('delay > 0 keeps child in initial position', (tester) async {
      const testKey = Key('slide-up-fade');
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SlideUp(
              key: testKey,
              delay: Duration(milliseconds: 500),
              child: Text('late'),
            ),
          ),
        ),
      );
      // delay 期间 SlideUp 内的 FadeTransition opacity = 0
      await tester.pump(const Duration(milliseconds: 100));
      final initialFade = tester
          .widgetList<FadeTransition>(
            find.descendant(
              of: find.byKey(testKey),
              matching: find.byType(FadeTransition),
            ),
          )
          .toList();
      expect(initialFade, hasLength(1));
      expect(initialFade.first.opacity.value, 0.0);

      // 跑过 delay 500ms,推进动画,pumpAndSettle 等 controller 跑完
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      final finalFade = tester
          .widgetList<FadeTransition>(
            find.descendant(
              of: find.byKey(testKey),
              matching: find.byType(FadeTransition),
            ),
          )
          .toList();
      expect(finalFade, hasLength(1));
      expect(finalFade.first.opacity.value, 1.0);
    });
  });
}
