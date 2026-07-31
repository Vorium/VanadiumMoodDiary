// v0.27 round 67 (C-6 重构): SwipeDeleteBackground 集中器测试
//
// 验证 3 处 Dismissible "红底 + delete icon" 抽到 SwipeDeleteBackground 集中器后
// 行为完全一致。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/widgets/swipe_delete_background.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

void main() {
  group('SwipeDeleteBackground (R67 C-6)', () {
    testWidgets('1. 默认 rounded=false: 无圆角, errorColor 背景 + delete icon',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SwipeDeleteBackground()),
        ),
      );
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      // Container 在 background 装饰 (有 Color, 无 borderRadius)
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, isNull);
    });

    testWidgets('2. rounded=true: 加 radiusCard 圆角 (vent Card 用)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SwipeDeleteBackground(rounded: true)),
        ),
      );
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(
        decoration.borderRadius,
        equals(BorderRadius.circular(AppTokens.radiusCard)),
      );
    });
  });
}
