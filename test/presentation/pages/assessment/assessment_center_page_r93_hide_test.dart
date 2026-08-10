// v0.30 round 93 (test): assessment_center_page 隐藏 PHQ-9 / GAD-7 量表
//
// R93 阶段 2: "所有需要真接的内容先隐藏" 策略
// PHQ-9 / GAD-7 16 题 i18n 不完整 (en / zh_Hant 法律责任 + 翻译),
// 走 [FeatureFlags.phqGad7I18nEnabled] gate, 默认 false 隐藏。
//
// 2 case:
//   - case 1: phqGad7I18nEnabled 默认 false → 8 开放 + 2 unavailable = 10 卡片,
//     PHQ-9 / GAD-7 找不到
//   - case 2: phqGad7I18nEnabled=true → 10 开放 + 2 unavailable = 12 卡片,
//     PHQ-9 / GAD-7 渲染
//
// 测试模式: 复用 R90 round 90 test 的 wrap() 风格 (避免重复)。
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_center_page.dart';
import 'package:chroniccare/presentation/providers/assessment_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  // helper: 构造测试 widget
  Widget wrap() {
    final router = GoRouter(
      initialLocation: '/assessment-center',
      routes: [
        GoRoute(
          path: '/assessment-center',
          builder: (context, state) => const AssessmentCenterPage(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        allAssessmentEntriesProvider
            .overrideWith((ref) => Stream.value(const [])),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        routerConfig: router,
      ),
    );
  }

  setUp(FeatureFlags.resetForTest);

  tearDown(FeatureFlags.resetForTest);

  testWidgets(
      'R93 case 1: phqGad7I18nEnabled 默认 false → 8 开放 + 2 unavailable = 10 卡片, PHQ-9 / GAD-7 隐藏',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // 8 开放 (phq9 + gad7 隐藏) + 2 unavailable (nsesss + crdpss) = 10 Card
    expect(find.byType(Card), findsNWidgets(10));

    // PHQ-9 / GAD-7 隐藏
    expect(
      find.text('PHQ-9 抑郁筛查'),
      findsNothing,
      reason: 'R93: phqGad7I18nEnabled=false 时 PHQ-9 隐藏',
    );
    expect(
      find.text('GAD-7 焦虑筛查'),
      findsNothing,
      reason: 'R93: phqGad7I18nEnabled=false 时 GAD-7 隐藏',
    );

    // 其他 8 量表仍渲染 (chart chip + grid card 双重渲染, 走 findsWidgets ≥1)
    expect(find.text('ISI 失眠严重指数'), findsWidgets);
    expect(find.text('PSS 压力量表'), findsWidgets);
    expect(find.text('WHODAS 2.0 残疾评定'), findsWidgets);
    expect(find.text('ASRM 自评躁狂量表'), findsWidgets);

    // 2 unavailable 仍渲染
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));
  });

  testWidgets(
      'R93 case 2: phqGad7I18nEnabled=true → 10 开放 + 2 unavailable = 12 卡片, PHQ-9 / GAD-7 渲染',
      (tester) async {
    // phqGad7I18nEnabled 有 setPhqGad7I18nEnabledForTest setter (R65b 阶段)
    FeatureFlags.setPhqGad7I18nEnabledForTest(true);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // 10 开放 + 2 unavailable = 12 Card
    expect(find.byType(Card), findsNWidgets(12));

    // PHQ-9 / GAD-7 渲染
    expect(find.text('PHQ-9 抑郁筛查'), findsWidgets);
    expect(find.text('GAD-7 焦虑筛查'), findsWidgets);
  });
}
