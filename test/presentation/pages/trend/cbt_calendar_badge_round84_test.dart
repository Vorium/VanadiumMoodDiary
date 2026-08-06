// v0.29 round 84 (CBT 思维记录): DayDetailCard CBT 摘要测试
//
// 覆盖:
// 1. 5 栏 mood entry (有 situation + automaticThought + evidenceFor/Against +
//    alternativeThought + reratedScore) → 显示 "CBT 5 栏" badge + 字段
// 2. 3 栏 mood entry (只 score + note, 无 CBT 字段) → 不显示 "CBT 5 栏" badge
//
// 注: DayDetailCard 原本私有 (underscore prefix _DayDetailCard),为了让本测试
//    能 import, round 84 改成 public `DayDetailCard`。这是测试 isolation 的最
//    小代价。命名风格跟 MoodHistoryChart / HeatmapGrid 等其它 public widget
//    对齐。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/presentation/pages/trend/widgets/trend_day_detail_card.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

void main() {
  testWidgets('5 栏 mood entry 在 DayDetailCard 显示 CBT 摘要', (tester) async {
    final entries = [
      MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 8, 4, 14, 32),
        score: 4,
        situation: '开会迟到',
        automaticThought: '大家觉得我不靠谱',
        evidenceFor: '上次也迟到',
        evidenceAgainst: '过去一年只迟到一次',
        alternativeThought: '偶尔一次正常',
        reratedScore: 3,
      ),
    ];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 600,
          child: TestDayDetailCard(
            date: DateTime(2026, 8, 4),
            moodEntries: entries,
          ),
        ),
      ),
    ),);
    expect(find.text('CBT 5 栏'), findsOneWidget);
    expect(find.text('情境: 开会迟到'), findsOneWidget);
    expect(find.text('自动思维: 大家觉得我不靠谱'), findsOneWidget);
  });

  testWidgets('3 栏 mood entry 不显示 CBT 角标', (tester) async {
    final entries = [
      MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 8, 4, 14, 32),
        score: 3,
        note: '普通记录',
      ),
    ];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 600,
          child: TestDayDetailCard(
            date: DateTime(2026, 8, 4),
            moodEntries: entries,
          ),
        ),
      ),
    ),);
    expect(find.text('CBT 5 栏'), findsNothing);
  });
}

class TestDayDetailCard extends StatelessWidget {
  final DateTime date;
  final List<MoodEntryEntity> moodEntries;
  const TestDayDetailCard({
    super.key,
    required this.date,
    required this.moodEntries,
  });
  @override
  Widget build(BuildContext context) {
    return DayDetailCard(
      date: date,
      allCheckIns: const [],
      moodEntries: moodEntries,
      medications: const [],
    );
  }
}
