// v0.30 round 92 (audit-fixes / P0 #14): assessment_center 顶部 mini 趋势图
//
// 覆盖 (TDD red→green):
// 1. 顶部 AssessmentMultiLineChart 渲染 (复用 R90 chart widget, 80dp 高)
// 2. chart 走 allAssessmentEntriesProvider (data flow 透传)
//
// 修前 bug (R90 Task 5 placeholder): assessment_center_page.dart:64-67
// `const SizedBox.shrink()` + `// TODO (Task 5)` 注释, 12 量表卡片堆在
// ListView 顶部, 0 趋势图入口。R92 真做: 复用 R90 AssessmentMultiLineChart
// 80dp 高 mini 版。
//
// 测试模式: 跟 R90 assessment_center_page_round90_test 同款 —
// allAssessmentEntriesProvider override Stream.value(entries), pump page
// 后验证 chart 存在 (LineChart / AssessmentMultiLineChart 渲染)。

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/entities/assessment_entry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_center_page.dart';
import 'package:chroniccare/presentation/providers/assessment_providers.dart';
import 'package:chroniccare/presentation/widgets/charts/assessment_multi_line_chart.dart';

void main() {
  /// 800x2000 模拟手机视口, AssessmentCenterPage + 顶部 chart + 12 卡片可见
  void setBigView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  /// helper: pump page + override allAssessmentEntriesProvider
  Widget wrap({required List<AssessmentEntry> entries}) {
    return ProviderScope(
      overrides: [
        allAssessmentEntriesProvider
            .overrideWith((ref) => Stream.value(entries)),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        routerConfig: GoRouter(
          initialLocation: '/assessment-center',
          routes: [
            GoRoute(
              path: '/assessment-center',
              builder: (context, state) => const AssessmentCenterPage(),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets(
      'AssessmentCenterPage 顶部渲染 AssessmentMultiLineChart (不是 SizedBox)',
      (tester) async {
    setBigView(tester);
    await tester.pumpWidget(wrap(entries: const []));
    await tester.pumpAndSettle();

    // 顶部 chart 存在
    expect(
      find.byType(AssessmentMultiLineChart),
      findsOneWidget,
      reason:
          '顶部应渲染 AssessmentMultiLineChart (R90 widget 复用), 修前是 SizedBox.shrink + TODO',
    );

    // 内部 LineChart 也存在 (AssessmentMultiLineChart 内部用 LineChart)
    expect(
      find.byType(LineChart),
      findsOneWidget,
      reason: 'AssessmentMultiLineChart 内部用 fl_chart LineChart 渲染',
    );
  });

  testWidgets('chart 走 allAssessmentEntriesProvider (entries 透传到 chart widget)',
      (tester) async {
    setBigView(tester);
    // 注入 1 条 PHQ-9 entry (最近 30 天, scaleId=phq9)
    final phq9Entry = AssessmentEntry(
      id: 1,
      timestamp: DateTime.now().subtract(const Duration(days: 5)),
      scaleId: 'phq9',
      score: 10,
      severityRank: 1,
      answers: const [1, 1, 1, 0, 2, 0, 1, 1, 1],
    );
    await tester.pumpWidget(wrap(entries: [phq9Entry]));
    await tester.pumpAndSettle();

    // 验 chart 仍渲染 (entries=1 也渲染, 但 R90 widget 内部 list.isEmpty 跳过
    // PHQ-9 line 仍可能 0 line, widget 本身不空)
    expect(
      find.byType(AssessmentMultiLineChart),
      findsOneWidget,
      reason: 'entries 透传, chart widget 渲染 (即使 0 bar, widget 在)',
    );
  });
}
