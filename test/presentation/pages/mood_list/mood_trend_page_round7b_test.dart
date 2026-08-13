// v0.32 R110 round 7b-6: mood_trend_page (517L god class) 补 0-test
//
// 覆盖:
// 1. 空数据 → 暂无数据 + 3 个 tab (近 7 天/分数分布/CBT)
// 2. 有数据 → 趋势 tab: SegmentedButton (7D/30D/6M/1Y) + LineChart
// 3. 切换时间范围 7D → 30D → LineChart 正常重绘 (无 crash)
// 4. 切到分数分布 tab → BarChart + 分数分布标题
// 5. 切到 CBT tab (无 CBT 数据) → 暂无 CBT 重评数据
// 6. CBT 数据存在 → CBT 重评效果 + 提示文案 + LineChart 渲染
//
// 注: allMoodProvider 直接 override 为内存 stream, 不碰 DB。

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_trend_page.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

MoodEntryEntity _mood({
  required int id,
  required DateTime timestamp,
  required int score,
  int? reratedScore,
  String? situation,
}) {
  return MoodEntryEntity(
    id: id,
    timestamp: timestamp,
    score: score,
    reratedScore: reratedScore,
    situation: situation,
  );
}

Future<void> _pump(WidgetTester tester, List<MoodEntryEntity> entries) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      allMoodProvider.overrideWith((ref) => Stream.value(entries)),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: const MoodTrendPage(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('1) 空数据 → 暂无数据 + 3 tab', (tester) async {
    await _pump(tester, []);

    expect(find.text('情绪趋势'), findsOneWidget);
    expect(find.text('近 7 天'), findsOneWidget);
    expect(find.text('分数分布'), findsOneWidget);
    expect(find.text('CBT'), findsOneWidget);
    expect(find.text('暂无数据'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('2) 有数据 → 趋势 tab: 时间范围选择器 + LineChart', (tester) async {
    await _pump(tester, [
      _mood(id: 1, timestamp: DateTime(2026, 8, 10), score: 3),
      _mood(id: 2, timestamp: DateTime(2026, 8, 11), score: 4),
      _mood(id: 3, timestamp: DateTime(2026, 8, 12), score: 2),
    ]);

    expect(find.text('7D'), findsOneWidget);
    expect(find.text('30D'), findsOneWidget);
    expect(find.text('6M'), findsOneWidget);
    expect(find.text('1Y'), findsOneWidget);
    expect(find.byType(LineChart), findsWidgets);
    // 默认选中 7D
    final seg = tester.widget<SegmentedButton<dynamic>>(
      find.bySubtype<SegmentedButton<dynamic>>(),
    );
    expect((seg.selected.single as dynamic).days, 7);
  });

  testWidgets('3) 切换时间范围 7D → 30D 不崩', (tester) async {
    await _pump(tester, [
      _mood(id: 1, timestamp: DateTime(2026, 8, 10), score: 3),
      _mood(id: 2, timestamp: DateTime(2026, 8, 11), score: 4),
    ]);

    await tester.tap(find.text('30D'));
    await tester.pumpAndSettle();

    final seg = tester.widget<SegmentedButton<dynamic>>(
      find.bySubtype<SegmentedButton<dynamic>>(),
    );
    expect((seg.selected.single as dynamic).days, 30);
    expect(find.byType(LineChart), findsWidgets);
  });

  testWidgets('4) 分数分布 tab → BarChart + 标题', (tester) async {
    await _pump(tester, [
      _mood(id: 1, timestamp: DateTime(2026, 8, 10), score: 3),
      _mood(id: 2, timestamp: DateTime(2026, 8, 11), score: 4),
      _mood(id: 3, timestamp: DateTime(2026, 8, 12), score: 4),
      _mood(id: 4, timestamp: DateTime(2026, 8, 13), score: 2),
    ]);

    await tester.tap(find.text('分数分布'));
    await tester.pumpAndSettle();

    expect(find.byType(BarChart), findsOneWidget);
    // 分数分布标题出现在 distribution tab 内
    expect(
      find.descendant(
        of: find.byType(BarChart),
        matching: find.byType(Text),
      ),
      findsWidgets,
    );
  });

  testWidgets('5) CBT tab 无数据 → 暂无 CBT 重评数据', (tester) async {
    await _pump(tester, [
      _mood(id: 1, timestamp: DateTime(2026, 8, 10), score: 3),
      _mood(id: 2, timestamp: DateTime(2026, 8, 11), score: 4),
    ]);

    await tester.tap(find.text('CBT'));
    await tester.pumpAndSettle();

    expect(find.text('暂无 CBT 重评数据'), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('6) CBT 数据存在 → 标题 + 提示 + LineChart', (tester) async {
    await _pump(tester, [
      _mood(
        id: 1,
        timestamp: DateTime(2026, 8, 10),
        score: 2,
        reratedScore: 4,
        situation: '测试',
      ),
      _mood(
        id: 2,
        timestamp: DateTime(2026, 8, 11),
        score: 3,
        reratedScore: 3,
        situation: '测试2',
      ),
    ]);

    await tester.tap(find.text('CBT'));
    await tester.pumpAndSettle();

    expect(find.text('CBT 重评效果'), findsOneWidget);
    expect(find.text('正值 = 情绪改善， 负值 = 恶化'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });
}