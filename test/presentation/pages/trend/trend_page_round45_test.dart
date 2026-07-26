// v0.24 (Round 45): trend_page widget 单测
//
// 之前 v0.22 round 30 P1-37 标的"trend 整片 0 widget 测"残留 2 周。
// v0.24 round 45 (Sprint #6 中段 3 page 0 widget 测补齐之三) 补 2 个 case:
//
// 1. checkIns error → 渲染 ErrorState (error 状态接管)
// 2. checkIns data + mood data + assessments data → 渲染 4 个 section header
//    (trend_30d / trend_6m / trend_assessment_history / trend_mood_history)
//
// 注: loading test 跳过 (Riverpod 3.x StreamProvider.autoDispose + Stream.empty
// 行为不稳, 留 v0.25 续补)
//
// 测试 setup:
// - MaterialApp + AppLocalizations.localizationsDelegates
// - ProviderScope overrides mock 3 个 StreamProvider
// - 测 render / error 状态切换
// - 测 ViewToggle (list ↔ calendar) 切换不在本测试范围 (state 复杂, 留 v0.25 续补)
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/trend/trend_charts.dart';
import 'package:chroniccare/presentation/pages/trend/trend_page.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // helper: 构造测试 widget
  Widget buildTrendPage({
    List<CheckInEntity> checkIns = const [],
    List<MoodEntryEntity> moods = const [],
    List<CheckInEntity> assessments = const [],
    bool checkInsError = false,
  }) {
    return ProviderScope(
      overrides: [
        allCheckInsProvider.overrideWith((ref) {
          if (checkInsError) return Stream.error(Exception('test error'));
          return Stream.value(checkIns);
        }),
        allMoodProvider.overrideWith((ref) => Stream.value(moods)),
        assessmentsProvider.overrideWith((ref) => Stream.value(assessments)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: const TrendPage(),
      ),
    );
  }

  testWidgets('checkIns error → 显示 ErrorState', (tester) async {
    await tester.pumpWidget(buildTrendPage(checkInsError: true));
    await tester.pumpAndSettle();

    // ErrorState 集中器 (v0.22 round 29 emil-44 抽)
    expect(find.byType(ErrorState), findsOneWidget);
  });

  testWidgets('checkIns data 空 + mood + assessments data 空 → list view 4 section',
      (tester) async {
    await tester.pumpWidget(buildTrendPage());
    await tester.pumpAndSettle();

    // 4 个 chart widget 渲染 (l10n 简体, 不依赖 viewport scroll)
    expect(find.byType(HeatmapGrid), findsOneWidget);
    expect(find.byType(MonthlyChart), findsOneWidget);
    expect(find.byType(AssessmentHistoryChart), findsOneWidget);
    expect(find.byType(MoodHistoryChart), findsOneWidget);
  });
}
