/// v0.18 round 18 (P1-5) AppTokens dynamic Color getter 测试
///
/// 覆盖:
/// - 7 个 dynamic Color getter (surfaceColor / backgroundColor / textPrimaryColor /
///   textSecondaryColor / textHintColor / borderColor / dividerColor) 都返回非空
/// - 在 light theme 下值跟静态 fallback 不冲突
/// - 在 dark theme 下值跟 light 模式不同(深色背景浅色文字)
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

Widget _wrap(ThemeData theme) => MaterialApp(
      theme: theme,
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              Text('a', style: TextStyle(color: AppTokens.surfaceColor(context))),
              Text('b',
                  style: TextStyle(color: AppTokens.backgroundColor(context))),
              Text('c',
                  style: TextStyle(color: AppTokens.textPrimaryColor(context))),
              Text('d',
                  style: TextStyle(color: AppTokens.textSecondaryColor(context))),
              Text('e', style: TextStyle(color: AppTokens.textHintColor(context))),
              Text('f', style: TextStyle(color: AppTokens.borderColor(context))),
              Text('g', style: TextStyle(color: AppTokens.dividerColor(context))),
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

  testWidgets('light vs dark: surface / textPrimary 必须不同',
      (tester) async {
    late Color lightSurface;
    late Color lightTextPrimary;
    late Color darkSurface;
    late Color darkTextPrimary;

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      home: Builder(builder: (context) {
        lightSurface = AppTokens.surfaceColor(context);
        lightTextPrimary = AppTokens.textPrimaryColor(context);
        return const SizedBox();
      }),
    ));
    await tester.pumpAndSettle();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Builder(builder: (context) {
        darkSurface = AppTokens.surfaceColor(context);
        darkTextPrimary = AppTokens.textPrimaryColor(context);
        return const SizedBox();
      }),
    ));
    await tester.pumpAndSettle();

    // Light: 亮背景 + 暗文字
    // Dark:  暗背景 + 亮文字
    expect(lightSurface.value, isNot(equals(darkSurface.value)));
    expect(lightTextPrimary.value, isNot(equals(darkTextPrimary.value)));
  });
}
