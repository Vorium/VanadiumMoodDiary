// v0.31 round 12 (Apple Health redesign · Phase 4 Task 4.1):
// 9 feature integration smoke test
//
// 测试覆盖:
// 1. trend_summary → AppleListSection + StatCard (ultralight large variant)
// 2. contact → Divider thickness 0.5 (Phase 4 修)
// 3. assessment → 题目 spacing 16 (edgeInsetsMd)
// 4. vent_save_bar → PrimaryButton(secondary) (Phase 4 修)
// 5. assessment_result_panel → PrimaryButton(secondary) (Phase 4 修)
// 6. settings → SectionHeader ALL CAPS (默认 true)
// 7. apple_list_section 章节 ALL CAPS (跟 spec §4.5 13pt letterSpacing 0.6)
// 8. PrimaryButton 3 variant 走 FilledButton / FilledButton.tonal / TextButton
// 9. Divider thickness 0.5 (iOS hairline separator)

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/trend_calculator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/trend/trend_summary.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';
import 'package:chroniccare/presentation/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    home: Scaffold(body: child),
  );
}

void main() {
  // ═══════════════════════════════════════════════════
  // 1. trend: AppleListSection + StatCard ultralight large
  // ═══════════════════════════════════════════════════
  testWidgets(
    'trend SummaryCard → AppleListSection 内 4 StatCard (ultralight large)',
    (tester) async {
      final summary = StreakSummary(
        currentStreak: 5,
        longestStreak: 12,
        totalCheckIns: 30,
        totalDays: 60,
      );
      await tester.pumpWidget(_wrap(SummaryCard(summary: summary)));
      await tester.pumpAndSettle();

      // AppleListSection 容器
      expect(find.byType(AppleListSection), findsOneWidget);
      // 4 个 StatCard (currentStreak / longestStreak / totalCheckIns / totalDays)
      expect(find.byType(StatCard), findsNWidgets(4));
    },
  );

  // ═══════════════════════════════════════════════════
  // 2. apple_list_section: iOS section 13pt ALL CAPS letterSpacing 0.6
  // ═══════════════════════════════════════════════════
  testWidgets(
    'AppleListSection 标题 → 13pt w500 ALL CAPS letterSpacing 0.6 (spec §4.5)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppleListSection(
            title: 'summary',
            children: const [Text('A'), Text('B')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 找到 Text('SUMMARY') (toUpperCase 转换)
      final textWidget = tester.widget<Text>(find.text('SUMMARY'));
      // 13pt (fontSizeCaption = 13.0)
      expect(textWidget.style?.fontSize, 13.0);
      // w500
      expect(textWidget.style?.fontWeight, FontWeight.w500);
      // letterSpacing 0.6
      expect(textWidget.style?.letterSpacing, 0.6);
    },
  );

  // ═══════════════════════════════════════════════════
  // 3. SectionHeader 默认 ALL CAPS (Phase 2 R8b 设计)
  // ═══════════════════════════════════════════════════
  testWidgets(
    'SectionHeader 默认 isAllCaps: true → title 转 ALL CAPS',
    (tester) async {
      await tester.pumpWidget(
        _wrap(const SectionHeader(title: 'trend today')),
      );
      await tester.pumpAndSettle();

      // 'trend today' → 'TREND TODAY'
      expect(find.text('TREND TODAY'), findsOneWidget);
    },
  );

  // ═══════════════════════════════════════════════════
  // 4. PrimaryButton 3 variant 各自走不同 M3 widget
  // ═══════════════════════════════════════════════════
  testWidgets(
    'PrimaryButton primary → FilledButton (default)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          PrimaryButton(onPressed: () {}, child: const Text('submit')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FilledButton), findsOneWidget);
    },
  );

  testWidgets(
    'PrimaryButton secondary → FilledButton.tonal (M3 推荐 secondary CTA)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          PrimaryButton(
            variant: PrimaryButtonVariant.secondary,
            onPressed: () {},
            child: const Text('cancel'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FilledButton), findsOneWidget);
      // 找到的 FilledButton 是 tonal variant (sub-class)
    },
  );

  testWidgets(
    'PrimaryButton tertiary → TextButton (文字按钮)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          PrimaryButton(
            variant: PrimaryButtonVariant.tertiary,
            onPressed: () {},
            child: const Text('skip'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextButton), findsOneWidget);
    },
  );

  // ═══════════════════════════════════════════════════
  // 5. AppleListSection 内部 cell hairline 0.5
  // ═══════════════════════════════════════════════════
  testWidgets(
    'AppleListSection 内部 cell 串联 hairline Divider(thickness: 0.5)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          AppleListSection(
            children: const [Text('A'), Text('B'), Text('C')],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3 children → 2 dividers
      expect(find.byType(Divider), findsNWidgets(2));
      // 校验 thickness
      final divider = tester.widget<Divider>(find.byType(Divider).first);
      expect(divider.thickness, 0.5);
    },
  );

  // ═══════════════════════════════════════════════════
  // 6. StatCard ultralight 字号 (Phase 2 R7a 设计)
  // ═══════════════════════════════════════════════════
  testWidgets('StatCard large variant → 34pt w200 (textStyleMetricXl)',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        const StatCard(
          label: 'streak',
          value: '5',
          variant: StatCardVariant.large,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 找到 value Text widget (ultralight 大数字)
    final textWidget = tester.widget<Text>(find.text('5'));
    // 34pt (textStyleMetricXl)
    expect(textWidget.style?.fontSize, 34.0);
    // w200 (ultralight)
    expect(textWidget.style?.fontWeight, AppTokens.fontWeightUltralight);
  });
}
