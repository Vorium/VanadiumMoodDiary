// v0.32 R110 round 7b-3: assessment_widgets (429L god class) 补 0-test
//
// 覆盖:
// 1. SparklinePainter 纯函数单元测试 (PictureRecorder, 零 Flutter binding)
//    - 空数据 paint 无异常
//    - 单点 / 多点 paint 无异常
//    - shouldRepaint 判据 (totals / maxTotal / averageLine 变化才重绘)
// 2. QuestionCard widget:
//    - 渲染 'Q1. 题文' + 全部选项 chip
//    - 点选项 → onChanged 回调对应分值
//    - selected 高亮
// 3. ComparisonCard widget (3 态):
//    - 首次评估 → 提示文案 (无上次/无 delta/无天数)
//    - 恶化 → 上次/本次分数 + ↑ + 恶化文案
//    - 好转 → ↓ + 好转文案

import 'dart:ui' as ui;

import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/domain/logic/assessment_comparison.dart';
import 'package:chroniccare/domain/logic/assessment_record.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SparklinePainter (纯函数, PictureRecorder)', () {
    ui.Picture draw(SparklinePainter p) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      p.paint(canvas, const Size(200, 40));
      return recorder.endRecording();
    }

    /// 统计实际画上去的非透明像素 — "画了东西" vs "没画" 的硬证据
    Future<int> countDrawnPixels(ui.Picture pic) async {
      final image = await pic.toImage(200, 40);
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      var count = 0;
      final bytes = data!.buffer.asUint8List();
      for (var i = 3; i < bytes.length; i += 4) {
        if (bytes[i] != 0) count++;
      }
      return count;
    }

    SparklinePainter painter({
      List<int> totals = const [5, 10, 15],
      List<DateTime> timestamps = const [],
      int maxTotal = 27,
      double? averageLine = 10,
    }) {
      return SparklinePainter(
        totals: totals,
        timestamps: timestamps,
        maxTotal: maxTotal,
        lineColor: AppColors.primary,
        averageLine: averageLine,
        averageColor: AppColors.textSecondary,
        dotStrokeColor: Colors.white,
      );
    }

    test('空数据 → 无任何绘制像素', () async {
      final pic = draw(painter(totals: const []));
      expect(await countDrawnPixels(pic), 0);
    });

    test('单点 → 画了圆点', () async {
      final pic = draw(painter(totals: const [7]));
      expect(await countDrawnPixels(pic), greaterThan(0));
    });

    test('多点 → 折线 + 圆点都画了', () async {
      final pic = draw(painter(totals: const [3, 12, 21, 9]));
      expect(await countDrawnPixels(pic), greaterThan(0));
    });

    test('averageLine null → 仍画折线', () async {
      final pic = draw(painter(averageLine: null));
      expect(await countDrawnPixels(pic), greaterThan(0));
    });

    test('shouldRepaint: totals/maxTotal/averageLine 变化才 true', () {
      final a = painter();
      expect(a.shouldRepaint(painter(totals: const [1, 2])), isTrue);
      expect(a.shouldRepaint(painter(maxTotal: 21)), isTrue);
      expect(a.shouldRepaint(painter(averageLine: 3)), isTrue);
      // 相同(含相同 totals) → false
      expect(a.shouldRepaint(a), isFalse);
    });
  });

  group('QuestionCard', () {
    Widget wrap(QuestionCard card) {
      return MaterialApp(
        theme: ThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(body: card),
      );
    }

    const options = {0: '完全没有', 1: '偶尔', 2: '经常', 3: '几乎每天'};

    testWidgets('渲染题号 + 题文 + 全部选项', (tester) async {
      await tester.pumpWidget(wrap(const QuestionCard(
        index: 1,
        item: AssessmentItem(0, '感到紧张吗'),
        options: options,
        selected: null,
        onChanged: _noop,
      )));

      expect(find.text('Q1. 感到紧张吗'), findsOneWidget);
      for (final v in options.values) {
        expect(find.text(v), findsOneWidget);
      }
    });

    testWidgets('点选项 → onChanged 回调对应分值', (tester) async {
      int? changed;
      await tester.pumpWidget(wrap(QuestionCard(
        index: 2,
        item: const AssessmentItem(1, '难以入睡吗'),
        options: options,
        selected: null,
        onChanged: (v) => changed = v,
      )));

      await tester.tap(find.text('几乎每天'));
      expect(changed, 3);
    });

    testWidgets('selected 高亮对应 chip', (tester) async {
      await tester.pumpWidget(wrap(const QuestionCard(
        index: 3,
        item: AssessmentItem(2, '容易疲劳吗'),
        options: options,
        selected: 2,
        onChanged: _noop,
      )));

      final chip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.text('经常'),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(chip.selected, isTrue);
    });
  });

  group('ComparisonCard', () {
    Widget wrap(AssessmentComparison comparison) {
      return MaterialApp(
        theme: ThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: ComparisonCard(comparison: comparison),
        ),
      );
    }

    AssessmentRecord rec(int total, DateTime ts) => AssessmentRecord(
          scaleId: 'phq9',
          timestamp: ts,
          total: total,
          scores: [1, 2, 3, 4, 5, 6, 7, 8, 9],
        );

    testWidgets('首次评估 → 提示文案, 无分数对比', (tester) async {
      final current = rec(12, DateTime(2026, 8, 1));
      await tester.pumpWidget(wrap(AssessmentComparison(
        current: current,
        previous: null,
        scoreDelta: null,
        trend: ComparisonTrend.firstAssessment,
        currentSeverityRank: 2,
        previousSeverityRank: null,
        daysSincePrevious: null,
      )));

      expect(find.text('这是您的第一次评估。下次评估后会显示和这次的对比。'),
          findsOneWidget);
      expect(find.text('上次'), findsNothing);
      expect(find.text('本次'), findsNothing);
    });

    testWidgets('恶化 → 上次/本次分数 + ↑ + 恶化文案', (tester) async {
      final previous = rec(5, DateTime(2026, 7, 20));
      final current = rec(18, DateTime(2026, 8, 1));
      await tester.pumpWidget(wrap(AssessmentComparison(
        current: current,
        previous: previous,
        scoreDelta: 13,
        trend: ComparisonTrend.worsened,
        currentSeverityRank: 3,
        previousSeverityRank: 1,
        daysSincePrevious: 12,
      )));

      expect(find.text('上次'), findsOneWidget);
      expect(find.text('本次'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsWidgets);
      expect(find.textContaining('恶化'), findsWidgets);
    });

    testWidgets('好转 → ↓ + 好转文案', (tester) async {
      final previous = rec(16, DateTime(2026, 7, 20));
      final current = rec(4, DateTime(2026, 8, 1));
      await tester.pumpWidget(wrap(AssessmentComparison(
        current: current,
        previous: previous,
        scoreDelta: -12,
        trend: ComparisonTrend.improved,
        currentSeverityRank: 1,
        previousSeverityRank: 3,
        daysSincePrevious: 12,
      )));

      expect(find.byIcon(Icons.arrow_downward), findsWidgets);
      expect(find.textContaining('好转'), findsWidgets);
    });
  });
}

void _noop(int _) {}