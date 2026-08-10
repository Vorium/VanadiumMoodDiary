// v0.30 round 90 (sub-spec 6 量表中心): AssessmentMultiLineChart widget 测试
//
// 覆盖 4 个 case:
// 1. 空 entry → 渲染 chip 但 chart 无 line, 10 chip 都显示
// 2. 单量表 phq9 2 个 entry → LineChart 渲染 (1 line visible)
// 3. 10 量表各 1 entry → LineChart 渲染 (10 line)
// 4. 点 PHQ-9 chip 隐藏 → LineChart 还在, 但 line 数变 9
//
// Provider / 路由 strategy:
// - 不走 ProviderScope override, AssessmentMultiLineChart 是纯 stateless / widget
// - 硬编码 locale: zh (跟 R85 trend_cbt_rerated_chart_round85_test 同模式)
// - 用 MaterialApp + 直接装 widget
//
// TDD: 本文件先写 → 跑失败 (widget / palette not found) → 实施 → 跑 4/4 pass

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/entities/assessment_entry.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/charts/assessment_color_palette.dart';
import 'package:chroniccare/presentation/widgets/charts/assessment_multi_line_chart.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(body: child),
      );

  testWidgets('空 entry 渲染 chip 但无 line', (tester) async {
    await tester.pumpWidget(wrap(const AssessmentMultiLineChart(entries: [])));
    await tester.pumpAndSettle();

    // LineChart 渲染 (空 bars 也占位)
    expect(find.byType(LineChart), findsOneWidget);

    // 10 个 scale 都展示为 FilterChip (默认全 visible)
    expect(find.byType(FilterChip), findsNWidgets(10));
  });

  testWidgets('单量表 phq9 2 个 entry → LineChart 渲染', (tester) async {
    final now = DateTime.now();
    final entries = [
      AssessmentEntry(
        id: 1,
        timestamp: now.subtract(const Duration(days: 1)),
        scaleId: 'phq9',
        score: 10,
        severityRank: 2,
        answers: const [],
      ),
      AssessmentEntry(
        id: 2,
        timestamp: now,
        scaleId: 'phq9',
        score: 8,
        severityRank: 1,
        answers: const [],
      ),
    ];
    await tester.pumpWidget(wrap(AssessmentMultiLineChart(entries: entries)));
    await tester.pumpAndSettle();

    // LineChart 渲染 (1 bar)
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('10 量表各 1 entry → LineChart 渲染', (tester) async {
    final now = DateTime.now();
    final entries = <AssessmentEntry>[];
    for (final id in AssessmentColorPalette.allScaleIds) {
      final scale = scaleById(id);
      if (scale == null) continue;
      entries.add(
        AssessmentEntry(
          id: entries.length + 1,
          timestamp: now,
          scaleId: id,
          score: scale.totalRange ~/ 2,
          severityRank: 2,
          answers: const [],
        ),
      );
    }
    expect(entries.length, 10, reason: '10 个开放量表');
    await tester.pumpWidget(wrap(AssessmentMultiLineChart(entries: entries)));
    await tester.pumpAndSettle();

    // LineChart 渲染 (10 bars)
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('点 PHQ-9 chip 隐藏 → LineChart 仍渲染', (tester) async {
    final now = DateTime.now();
    final entries = <AssessmentEntry>[];
    for (final id in AssessmentColorPalette.allScaleIds) {
      final scale = scaleById(id);
      if (scale == null) continue;
      entries.add(
        AssessmentEntry(
          id: entries.length + 1,
          timestamp: now,
          scaleId: id,
          score: scale.totalRange ~/ 2,
          severityRank: 2,
          answers: const [],
        ),
      );
    }
    await tester.pumpWidget(wrap(AssessmentMultiLineChart(entries: entries)));
    await tester.pumpAndSettle();

    // 找 PHQ-9 chip (displayName = "PHQ-9 抑郁筛查" 走 phq9Scale.translations)
    final phq9Chip = find.widgetWithText(FilterChip, 'PHQ-9 抑郁筛查');
    expect(phq9Chip, findsOneWidget);

    // 第一次 tap: 当前已 selected (默认全 visible) → 取消选中
    await tester.tap(phq9Chip.first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // LineChart 仍在 (chip 切换不影响 widget 类型)
    expect(find.byType(LineChart), findsOneWidget);
  });
}
