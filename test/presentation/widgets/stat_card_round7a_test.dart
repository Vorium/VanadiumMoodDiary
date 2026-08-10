// v0.31 round 7a (Apple Health redesign · Phase 2 Task 2.3): StatCard 4 variant 测试
//
// 验证:
// 1. variant=default → metricLg 28 ultralight
// 2. variant=large  → metricXl 34 ultralight (最大)
// 3. variant=xl     → 28 ultralight + letterSpacing -0.5 (textStyleTitle 改 w200)
// 4. variant=inline → metricMd 22 ultralight
// 5. 默认无 variant 参数 → 自动走 defaultVariant (fontSize = metricLg 28)
//
// 额外验证 ultralight (w200) — 跟老 headline w600 区分, 是 R7a 核心视觉。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/widgets/stat_card.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  TextStyle valueStyle(WidgetTester tester, String text) {
    return tester.widget<Text>(find.text(text)).style!;
  }

  group('StatCard (R7a 4 variant + ultralight)', () {
    testWidgets('1. variant=default → metricLg 28 ultralight', (tester) async {
      await tester.pumpWidget(
        wrap(const StatCard(
          label: '今日',
          value: '3',
          variant: StatCardVariant.defaultVariant,
        )),
      );
      final style = valueStyle(tester, '3');
      expect(style.fontSize, AppTokens.fontSizeMetricLg); // 28
      expect(style.fontWeight, AppTokens.fontWeightUltralight); // w200
    });

    testWidgets('2. variant=large → metricXl 34 ultralight (最大)',
        (tester) async {
      await tester.pumpWidget(
        wrap(const StatCard(
          label: '总打卡',
          value: '128',
          variant: StatCardVariant.large,
        )),
      );
      final style = valueStyle(tester, '128');
      expect(style.fontSize, AppTokens.fontSizeMetricXl); // 34 (max)
      expect(style.fontWeight, AppTokens.fontWeightUltralight); // w200
    });

    testWidgets(
        '3. variant=xl → textStyleTitle 改 w200 (28 + letterSpacing -0.5)',
        (tester) async {
      await tester.pumpWidget(
        wrap(const StatCard(
          label: '评估',
          value: '12',
          variant: StatCardVariant.xl,
        )),
      );
      final style = valueStyle(tester, '12');
      // xl = textStyleTitle 字号 28 + 改 w200
      expect(style.fontSize, AppTokens.fontSizeTitle); // 28
      expect(style.fontWeight, AppTokens.fontWeightUltralight); // w200
      // letterSpacing 来自 textStyleTitle 默认 -0.5 (大字 Apple SF Pro Display 收紧)
      expect(style.letterSpacing, -0.5);
    });

    testWidgets('4. variant=inline → metricMd 22 ultralight (最小)',
        (tester) async {
      await tester.pumpWidget(
        wrap(const StatCard(
          label: '简报',
          value: '7',
          variant: StatCardVariant.inline,
        )),
      );
      final style = valueStyle(tester, '7');
      expect(style.fontSize, AppTokens.fontSizeMetricMd); // 22 (min)
      expect(style.fontWeight, AppTokens.fontWeightUltralight); // w200
    });

    testWidgets('5. 默认无 variant 参数 → 走 defaultVariant (R7a 隐式 default)',
        (tester) async {
      await tester.pumpWidget(
        wrap(const StatCard(label: '默认', value: '9')),
      );
      // 隐式 default 应该跟 explicit defaultVariant 一致
      final style = valueStyle(tester, '9');
      expect(style.fontSize, AppTokens.fontSizeMetricLg); // 28
      expect(
        style.fontWeight,
        AppTokens.fontWeightUltralight,
        reason: 'R7a 核心: 数字必须 ultralight w200 (Apple Health 风格)',
      );
      // 字号不是旧 headline 24 (sanity 验 R7a 升级生效)
      expect(style.fontSize, isNot(AppTokens.fontSizeHeadline));
    });
  });
}
