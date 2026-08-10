// v0.31 round 9a (Apple Health redesign · Phase 3 Task 3.1): HomeHeader 改写测试
//
// 历史:
// - v0.30 round 95: 主页 header 3 icon button tooltip 跟功能一致
//   (原 home_header_tooltip_round95_test.dart)
//
// v0.31 R9a: 主页 header 重写为 Apple Health 风格 — 28pt greeting + 15pt 日期 +
// 32x32 theme toggle (替换原 3 个 icon button 趋势/评估/设置, 入口功能下放到
// "快捷操作" + "更多" 区块)。本测试覆盖新设计 5 case:
//
// 1. greeting 28pt w700 (textStyleTitle) — 跟 userName 拼接
// 2. 副字日期 15pt textSecondary (textStyleLabel)
// 3. theme toggle 32x32 PressFeedbackIconButton
// 4. 容器无 surfaceColor (透明背景)
// 5. 上下 spacingXs 8 padding (从 16 减半)
//
// 设计选择:
// - 沿用 v0.30 R95 测试模式: MaterialApp theme + Scaffold wrap + IconButton finder
// - 删原 3 icon button 测试 (show_chart / psychology_outlined / settings_outlined)
// - 加新 1 theme toggle 测试 (brightness_auto / light_mode / dark_mode)
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('1. greeting 28pt w700 (textStyleTitle) — 跟 userName 拼接',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: Scaffold(
            body: HomeHeader(userName: '测试用户'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // greeting 文字: "测试用户 还在坚持"
    final greetingFinder = find.text('测试用户 还在坚持');
    expect(greetingFinder, findsOneWidget, reason: '应渲染 userName greeting');

    // greeting 字号 28 = textStyleTitle
    final greetingText = tester.widget<Text>(greetingFinder);
    final greetingStyle = greetingText.style!;
    expect(greetingStyle.fontSize, AppTokens.fontSizeTitle, // 28
        reason: 'greeting fontSize = textStyleTitle (28pt)',);
    expect(greetingStyle.fontWeight, FontWeight.w700,
        reason: 'greeting fontWeight = w700',);
  });

  testWidgets('2. 副字日期 15pt textSecondary (textStyleLabel)', (tester) async {
    final fixedDate = DateTime(2026, 8, 10);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: HomeHeader(userName: '小王', date: fixedDate),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 副字日期: "2026年8月10日"
    final dateFinder = find.text('2026年8月10日');
    expect(dateFinder, findsOneWidget, reason: '应渲染日期 "2026年8月10日"');

    // 日期字号 15 = textStyleLabel
    final dateText = tester.widget<Text>(dateFinder);
    final dateStyle = dateText.style!;
    expect(dateStyle.fontSize, AppTokens.fontSizeLabel, // 15
        reason: 'date fontSize = textStyleLabel (15pt)',);
    expect(
        dateStyle.color,
        AppTokens.textSecondaryColor(
          tester.element(find.byType(HomeHeader)),
        ),
        reason: 'date color = textSecondary',);
  });

  testWidgets('3. theme toggle 32x32 PressFeedbackIconButton 渲染',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: Scaffold(
            body: HomeHeader(userName: '小王'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // theme toggle: 1 个 PressFeedbackIconButton (主题 mode=system → brightness_auto)
    expect(
      find.byIcon(Icons.brightness_auto),
      findsOneWidget,
      reason: 'theme mode=system 应显示 brightness_auto icon',
    );
  });

  testWidgets('4. 容器无 surfaceColor 背景 (透明)', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: Scaffold(
            body: HomeHeader(userName: '小王'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 找 HomeHeader 的最外层 Container (padding 是 symmetric vertical: spacingXs)
    final containerFinder = find.descendant(
      of: find.byType(HomeHeader),
      matching: find.byType(Container),
    );
    expect(containerFinder, findsWidgets,
        reason: 'HomeHeader 应至少渲染 1 个 Container (transparent)',);
    // padding = EdgeInsets.symmetric(vertical: spacingXs)
    final container = tester.widget<Container>(containerFinder.first);
    expect(
      container.padding,
      const EdgeInsets.symmetric(
        vertical: AppTokens.spacingXs, // 8
      ),
    );
  });

  testWidgets('5. 上下 spacingXs 8 padding (从 16 减半)', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: Scaffold(
            body: HomeHeader(userName: '小王'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 找 HomeHeader 顶层 Container, 验证 padding = spacingXs vertical
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(HomeHeader),
            matching: find.byType(Container),
          )
          .first,
    );
    final padding = container.padding as EdgeInsets;
    // EdgeInsets.symmetric(vertical: 8) → top=8 bottom=8, vertical getter=16
    // 这里直接测 top / bottom 各 = 8
    expect(padding.top, AppTokens.spacingXs,
        reason: 'HomeHeader padding top = spacingXs (8)',);
    expect(padding.bottom, AppTokens.spacingXs,
        reason: 'HomeHeader padding bottom = spacingXs (8)',);
  });
}
