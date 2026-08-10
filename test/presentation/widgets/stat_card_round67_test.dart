// v0.27 round 67 (C-4 重构): StatCard 集中器测试
//
// 验证 2 处 _Stat widget 抽到 StatCard 集中器后行为一致。
//
// v0.31 R7a (Apple Health redesign · Phase 2 Task 2.3): 适配新视觉
// - 默认 value 字号从 headline 24/w600 → metricLg 28/w200 ultralight
// - label 颜色从 textSecondary → textHint (更弱, 跟 ultralight 数字形成对比)
// - 数字 tween (int 字符串触发, 非 int static)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/widgets/stat_card.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

void main() {
  group('StatCard (R67 C-4 / R7a Apple Health 视觉)', () {
    testWidgets('1. 默认: value 28/w200 ultralight + label textHint',
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
      // value 字号 = metricLg 28 (ultralight)
      final valueText = tester.widget<Text>(find.text('5'));
      expect(valueText.style!.fontSize, equals(AppTokens.fontSizeMetricLg));
      expect(
        valueText.style!.fontWeight,
        equals(AppTokens.fontWeightUltralight),
      );
      // label 颜色 = textHint (R7a 升级, 改前是 textSecondary)
      final ctx = tester.element(find.byType(StatCard));
      final labelText = tester.widget<Text>(find.text('连续天数'));
      expect(labelText.style!.color, equals(AppTokens.textHintColor(ctx)));
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
