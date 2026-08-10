// v0.30 round 87 (sub-spec 3 mood 列表页): MoodListItem 单行渲染 widget 测试
//
// 覆盖:
// 1. 3 栏 entry (score + note, 无 CBT) → 显示 timestamp + note
// 2. 5 栏 entry (situation/automaticThought/.../reratedScore) → 显示 CBT 5 栏 badge
//
// 跟 trend_calendar DayDetailCard 测试 (cbt_calendar_badge_round84_test.dart)
// 风格一致: MaterialApp + l10n delegates + zh locale,直接 find.text。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood_list/widgets/mood_list_item.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(body: child),
      );

  testWidgets('3 栏 entry: 显示 timestamp + score emoji + note', (tester) async {
    final entry = MoodEntryEntity(
      id: 1,
      timestamp: DateTime(2026, 8, 4, 14, 32),
      score: 4,
      note: '开会迟到',
    );
    await tester.pumpWidget(wrap(MoodListItem(entry: entry)));
    expect(find.text('开会迟到'), findsOneWidget);
    expect(find.textContaining('14:32'), findsOneWidget);
  });

  testWidgets('5 栏 entry: 显示 CBT 5 栏 badge', (tester) async {
    final entry = MoodEntryEntity(
      id: 2,
      timestamp: DateTime(2026, 8, 4),
      score: 3,
      situation: 's',
      automaticThought: 'at',
      evidenceFor: 'ef',
      evidenceAgainst: 'ea',
      alternativeThought: 'alt',
      reratedScore: 4,
    );
    await tester.pumpWidget(wrap(MoodListItem(entry: entry)));
    expect(find.text('CBT 5 栏'), findsOneWidget);
  });
}
