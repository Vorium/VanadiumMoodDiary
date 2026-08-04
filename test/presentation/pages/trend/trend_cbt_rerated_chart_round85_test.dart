// v0.30 round 85 (CBT 重评效果图): ReratedScoreChart widget 测试
//
// 覆盖:
// 1. 5 条 5/7 栏 entries (> 3) → 渲染标题 "重评效果"
// 2. 1 条 5/7 栏 entry (< 3) → 显示空态, 文案含 "CBT"
//
// 跟 MoodHistoryChart 测试 pattern 平行: MaterialApp + AppLocalizations delegates
// + 硬编码中文 (locale: zh) — 因为 test 只验中文 UI 行为。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/trend/widgets/trend_cbt_rerated_chart.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(body: child),
      );

  testWidgets('5 条 entries > 3 渲染标题', (tester) async {
    final entries = List.generate(
      5,
      (i) => MoodEntryEntity(
        id: i,
        timestamp: DateTime(2026, 8, 1 + i),
        score: 4 - i,
        situation: 's',
        automaticThought: 'at',
        evidenceFor: 'ef',
        evidenceAgainst: 'ea',
        alternativeThought: 'alt',
        reratedScore: 3 - i,
      ),
    );
    await tester.pumpWidget(wrap(ReratedScoreChart(entries: entries)));
    await tester.pumpAndSettle();
    expect(find.text('重评效果'), findsOneWidget);
  });

  testWidgets('5 条 entries < 3 显示空态', (tester) async {
    final entries = [
      MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 8, 1),
        score: 4,
        situation: 's',
        automaticThought: 'at',
        evidenceFor: 'ef',
        evidenceAgainst: 'ea',
        alternativeThought: 'alt',
        reratedScore: 3,
      ),
    ];
    await tester.pumpWidget(wrap(ReratedScoreChart(entries: entries)));
    await tester.pumpAndSettle();
    expect(find.textContaining('CBT'), findsWidgets); // 空态文档
  });
}
