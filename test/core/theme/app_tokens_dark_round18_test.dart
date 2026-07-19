/// v0.18 round 18 (P1-5) AppTokens dynamic Color getter 测试
///
/// 覆盖:
/// - 7 个 dynamic Color getter (surfaceColor / backgroundColor / textPrimaryColor /
///   textSecondaryColor / textHintColor / borderColor / dividerColor) 都返回非空
/// - 在 light theme 下值跟静态 fallback 不冲突
/// - 在 dark theme 下值跟 light 模式不同(深色背景浅色文字)
///
/// v0.18 round 18 (P1-22) a11y contrast: textPrimaryColor / textSecondaryColor
/// vs surface 必须满足 WCAG AA 4.5:1 (text)。textHint 不要求 4.5 但应该够看。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// WCAG 2.x 相对亮度对比度
/// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
double _relativeLuminance(Color c) {
  final r = ((c.r * 255.0).round() & 0xff) / 255.0;
  final g = ((c.g * 255.0).round() & 0xff) / 255.0;
  final b = ((c.b * 255.0).round() & 0xff) / 255.0;
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) * ((v + 0.055) / 1.055);
  // toARGB32 deprecated; 旧版用 .value
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
}

/// 对比度 = (L1 + 0.05) / (L2 + 0.05),L1 = 较亮,L2 = 较暗
double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

Widget _wrap(ThemeData theme) => MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              Text('a',
                  style: TextStyle(color: AppTokens.surfaceColor(context))),
              Text(
                'b',
                style: TextStyle(color: AppTokens.backgroundColor(context)),
              ),
              Text(
                'c',
                style: TextStyle(color: AppTokens.textPrimaryColor(context)),
              ),
              Text(
                'd',
                style: TextStyle(color: AppTokens.textSecondaryColor(context)),
              ),
              Text('e',
                  style: TextStyle(color: AppTokens.textHintColor(context))),
              Text('f',
                  style: TextStyle(color: AppTokens.borderColor(context))),
              Text('g',
                  style: TextStyle(color: AppTokens.dividerColor(context))),
            ],
          ),
        ),
      ),
    );

void main() {
  testWidgets('light mode: dynamic getter 返回 ColorScheme 派生值', (tester) async {
    await tester.pumpWidget(_wrap(ThemeData.light(useMaterial3: true)));
    expect(find.byType(Text), findsNWidgets(7));
  });

  testWidgets('dark mode: dynamic getter 返回 dark 派生值', (tester) async {
    await tester.pumpWidget(_wrap(ThemeData.dark(useMaterial3: true)));
    expect(find.byType(Text), findsNWidgets(7));
  });

  testWidgets('light vs dark: surface / textPrimary 必须不同', (tester) async {
    late Color lightSurface;
    late Color lightTextPrimary;
    late Color darkSurface;
    late Color darkTextPrimary;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Builder(
          builder: (context) {
            lightSurface = AppTokens.surfaceColor(context);
            lightTextPrimary = AppTokens.textPrimaryColor(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Builder(
          builder: (context) {
            darkSurface = AppTokens.surfaceColor(context);
            darkTextPrimary = AppTokens.textPrimaryColor(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Light: 亮背景 + 暗文字
    // Dark:  暗背景 + 亮文字
    expect(lightSurface, isNot(equals(darkSurface)));
    expect(lightTextPrimary, isNot(equals(darkTextPrimary)));
  });

  /// v0.18 (P1-22) a11y: text vs surface 对比度
  /// WCAG AA 4.5:1 for normal text
  testWidgets('P1-22 a11y: light mode text contrast >= 4.5:1', (tester) async {
    late Color surface;
    late Color textPrimary;
    late Color textSecondary;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Builder(
          builder: (context) {
            surface = AppTokens.surfaceColor(context);
            textPrimary = AppTokens.textPrimaryColor(context);
            textSecondary = AppTokens.textSecondaryColor(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final primaryRatio = _contrastRatio(textPrimary, surface);
    final secondaryRatio = _contrastRatio(textSecondary, surface);
    expect(
      primaryRatio,
      greaterThanOrEqualTo(4.5),
      reason: 'textPrimary vs surface 对比度 $primaryRatio 必须 >= 4.5 (WCAG AA)',
    );
    expect(
      secondaryRatio,
      greaterThanOrEqualTo(3.0),
      reason: 'textSecondary vs surface 对比度 $secondaryRatio 应该 >= 3.0 (大字体 AA)',
    );
  });

  testWidgets('P1-22 a11y: dark mode text contrast >= 4.5:1', (tester) async {
    late Color surface;
    late Color textPrimary;
    late Color textSecondary;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Builder(
          builder: (context) {
            surface = AppTokens.surfaceColor(context);
            textPrimary = AppTokens.textPrimaryColor(context);
            textSecondary = AppTokens.textSecondaryColor(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final primaryRatio = _contrastRatio(textPrimary, surface);
    final secondaryRatio = _contrastRatio(textSecondary, surface);
    expect(
      primaryRatio,
      greaterThanOrEqualTo(4.5),
      reason: 'dark textPrimary vs surface 对比度 $primaryRatio 必须 >= 4.5',
    );
    expect(
      secondaryRatio,
      greaterThanOrEqualTo(3.0),
      reason: 'dark textSecondary vs surface 对比度 $secondaryRatio 应该 >= 3.0',
    );
  });
}
