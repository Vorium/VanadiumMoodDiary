// v0.27 round 67 (C-4 重构): StatCard 集中器测试
//
// 验证 2 处 _Stat widget 抽到 StatCard 集中器后行为一致。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/widgets/stat_card.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

void main() {
  group('StatCard (R67 C-4)', () {
    testWidgets('1. 默认: value 在上 (headline w600), label 在下 (caption secondary)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(label: '连续天数', value: '5'),
          ),
        ),
      );
      expect(find.text('5'), findsOneWidget);
      expect(find.text('连续天数'), findsOneWidget);
      // value 字号 = headline
      final valueText = tester.widget<Text>(find.text('5'));
      expect(valueText.style!.fontSize, equals(AppTokens.fontSizeHeadline));
      expect(valueText.style!.fontWeight, equals(FontWeight.w600));
    });

    testWidgets('2. valueColor 覆盖: warningColor 让 value 变橙', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => StatCard(
                label: '提醒中',
                value: '2',
                valueColor: AppTokens.warningColor(context),
              ),
            ),
          ),
        ),
      );
      expect(find.text('2'), findsOneWidget);
      final valueText = tester.widget<Text>(find.text('2'));
      final ctx = tester.element(find.byType(StatCard));
      expect(
        valueText.style!.color,
        equals(AppTokens.warningColor(ctx)),
      );
    });
  });
}
