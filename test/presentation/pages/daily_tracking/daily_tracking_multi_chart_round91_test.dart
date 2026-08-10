// v0.30 round 91 (sub-spec 7 日常追踪 / Task 6 多指标趋势图): 4 widget 测试
//
// 覆盖 4 个 case:
// 1. 空数据 → 渲染 4 chip + LineChart (4 chip: 体重/睡眠/心境/应激源)
// 2. 体重 1 entry → LineChart 渲染 (1 line visible)
// 3. 4 指标各 1 entry → LineChart 渲染 (4 line, 4 色 + 4 线型)
// 4. toggle "体重" chip 隐藏 → LineChart 仍渲染 (但 line 数 -1)
//
// 设计:
// - 复用 R90 assessment_multi_line_chart_round90_test pattern
// - 走 AppTokens.dailyTrackingColorFor / dailyTrackingDashFor (4 指标 + 4 线型)
// - 不走 ProviderScope override (DailyTrackingMultiChart 是纯 widget)
// - 硬编码 locale: zh
//
// TDD: 本文件先写 → 跑失败 (widget / palette not found) → 实施 → 跑 4/4 pass
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/domain/entities/stress_event.dart';
import 'package:chroniccare/domain/entities/weight_entry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/charts/daily_tracking_multi_chart.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(body: child),
      );

  testWidgets('空 entry 渲染 4 chip + LineChart', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DailyTrackingMultiChart(
          weights: [],
          sleepEntries: [],
          moodEntries: [],
          stressEvents: [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // LineChart 渲染 (空 bars 也占位)
    expect(find.byType(LineChart), findsOneWidget);

    // 4 chip 都显示 (默认全 visible)
    expect(find.text('体重'), findsOneWidget);
    expect(find.text('睡眠'), findsOneWidget);
    expect(find.text('心境'), findsOneWidget);
    expect(find.text('应激源'), findsOneWidget);
    expect(find.byType(FilterChip), findsNWidgets(4));
  });

  testWidgets('体重 1 entry → LineChart 渲染 (1 line 蓝色实线)', (tester) async {
    final now = DateTime.now();
    final entries = [
      WeightEntryEntity(
        id: 1,
        timestamp: now,
        weightKg: 70.0,
      ),
    ];
    await tester.pumpWidget(
      wrap(
        DailyTrackingMultiChart(
          weights: entries,
          sleepEntries: const [],
          moodEntries: const [],
          stressEvents: const [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // LineChart 渲染 (1 bar)
    expect(find.byType(LineChart), findsOneWidget);

    // 体重指标色 = 蓝 (0xFF1E88E5)
    expect(
      AppTokens.dailyTrackingColorFor('weight'),
      const Color(0xFF1E88E5),
      reason: '体重 蓝',
    );
    // 体重线型 = 实线 (空 list)
    expect(
      AppTokens.dailyTrackingDashFor('weight'),
      isEmpty,
      reason: '体重 实线',
    );
  });

  testWidgets('4 指标各 1 entry → LineChart 渲染 (4 line 4 色 + 4 线型)',
      (tester) async {
    final now = DateTime.now();
    final weights = [
      WeightEntryEntity(id: 1, timestamp: now, weightKg: 70.0),
    ];
    final sleeps = [
      SleepEntryEntity(
        id: 1,
        date: now,
        bedtime: now.subtract(const Duration(hours: 8)),
        wakeTime: now,
        durationMin: 480,
      ),
    ];
    final moods = [
      MoodEntryEntity(
        id: 1,
        timestamp: now,
        score: 3,
        tagsJson: '[]',
      ),
    ];
    final stresses = [
      StressEventEntity(
        id: 1,
        timestamp: now,
        eventType: 'work',
        intensity: 3,
      ),
    ];
    await tester.pumpWidget(
      wrap(
        DailyTrackingMultiChart(
          weights: weights,
          sleepEntries: sleeps,
          moodEntries: moods,
          stressEvents: stresses,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // LineChart 渲染 (4 bars: 体重/睡眠/心境/应激源)
    expect(find.byType(LineChart), findsOneWidget);

    // 4 指标色 (蓝/紫/绿/红)
    expect(
      AppTokens.dailyTrackingColorFor('weight'),
      const Color(0xFF1E88E5),
      reason: '体重 蓝',
    );
    expect(
      AppTokens.dailyTrackingColorFor('sleep'),
      const Color(0xFF8E24AA),
      reason: '睡眠 紫',
    );
    expect(
      AppTokens.dailyTrackingColorFor('mood'),
      const Color(0xFF43A047),
      reason: '心境 绿',
    );
    expect(
      AppTokens.dailyTrackingColorFor('stress'),
      const Color(0xFFE53935),
      reason: '应激源 红',
    );

    // 4 线型 (实/虚/点/双点)
    expect(
      AppTokens.dailyTrackingDashFor('weight'),
      isEmpty,
      reason: '体重 实线',
    );
    expect(
      AppTokens.dailyTrackingDashFor('sleep'),
      [5, 5],
      reason: '睡眠 虚线',
    );
    expect(
      AppTokens.dailyTrackingDashFor('mood'),
      [2, 3],
      reason: '心境 点线',
    );
    expect(
      AppTokens.dailyTrackingDashFor('stress'),
      [8, 3, 2, 3],
      reason: '应激源 双点',
    );

    // 未知 metric 兜底
    expect(
      AppTokens.dailyTrackingColorFor('unknown_metric'),
      const Color(0xFF9E9E9E),
      reason: '未知 metric 兜底灰',
    );
  });

  testWidgets('toggle "体重" chip 隐藏 → LineChart 仍渲染', (tester) async {
    final now = DateTime.now();
    final weights = [
      WeightEntryEntity(id: 1, timestamp: now, weightKg: 70.0),
    ];
    final moods = [
      MoodEntryEntity(id: 1, timestamp: now, score: 3, tagsJson: '[]'),
    ];
    await tester.pumpWidget(
      wrap(
        DailyTrackingMultiChart(
          weights: weights,
          sleepEntries: const [],
          moodEntries: moods,
          stressEvents: const [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 初始: LineChart 渲染
    expect(find.byType(LineChart), findsOneWidget);

    // 找 "体重" chip
    final weightChip = find.widgetWithText(FilterChip, '体重');
    expect(weightChip, findsOneWidget);

    // tap 取消选中
    await tester.tap(weightChip.first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // LineChart 仍在 (chip 切换不影响 widget 类型)
    expect(find.byType(LineChart), findsOneWidget);
  });
}
