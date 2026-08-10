// v0.30 round 91 (sub-spec 7 日常追踪 / Task 2): mood list period chip filter 行为锁定
//
// 覆盖 (TDD red→green):
// 1. chip "早" filter → 只显示 period='morning' 的 entry
//
// 设计要点 (跟 R87 mood_list_page + R87 mood_list_filter_bar 同款):
// - 5 entry (1 morning + 1 noon + 1 evening + 1 night + 1 unspecified) 注
//   moodEntriesProvider
// - 顶部 chip 列表: 全部 / 早 / 中 / 晚 / 夜 / 未指定
// - 点 "早" chip → filteredMoodEntriesProvider 只返 1 条
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_list_page.dart';
import 'package:chroniccare/presentation/providers/cbt_rerated_entries_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 5 条 mood entries (各 1 period)
  List<MoodEntryEntity> makeEntries() => [
        MoodEntryEntity(
          id: 1,
          timestamp: DateTime(2026, 8, 5, 8, 0),
          score: 4,
          note: 'morning entry',
          period: 'morning',
        ),
        MoodEntryEntity(
          id: 2,
          timestamp: DateTime(2026, 8, 5, 12, 30),
          score: 3,
          note: 'noon entry',
          period: 'noon',
        ),
        MoodEntryEntity(
          id: 3,
          timestamp: DateTime(2026, 8, 5, 19, 0),
          score: 5,
          note: 'evening entry',
          period: 'evening',
        ),
        MoodEntryEntity(
          id: 4,
          timestamp: DateTime(2026, 8, 5, 23, 30),
          score: 2,
          note: 'night entry',
          period: 'night',
        ),
        MoodEntryEntity(
          id: 5,
          timestamp: DateTime(2026, 8, 4, 15, 0),
          score: 3,
          note: 'unspecified entry',
          period: 'unspecified',
        ),
      ];

  Widget wrap({List<MoodEntryEntity> entries = const []}) {
    return ProviderScope(
      overrides: [
        moodEntriesProvider.overrideWith((ref) => entries),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: MoodListPage(),
      ),
    );
  }

  testWidgets('chip "早" filter → 只显示 period=morning 的 entry', (tester) async {
    await tester.pumpWidget(wrap(entries: makeEntries()));
    await tester.pumpAndSettle();

    // 初始: 5 条都可见
    expect(find.text('morning entry'), findsOneWidget);
    expect(find.text('noon entry'), findsOneWidget);
    expect(find.text('evening entry'), findsOneWidget);
    expect(find.text('night entry'), findsOneWidget);
    expect(find.text('unspecified entry'), findsOneWidget);

    // 点 chip "早" — 走 moodListFilterProvider.setPeriod('morning')
    await tester.tap(find.text('早'));
    await tester.pumpAndSettle();

    // 验只显示 morning entry
    expect(
      find.text('morning entry'),
      findsOneWidget,
      reason: 'filter=morning 应保留 morning entry',
    );
    expect(
      find.text('noon entry'),
      findsNothing,
      reason: 'filter=morning 应过滤掉 noon entry',
    );
    expect(find.text('evening entry'), findsNothing);
    expect(find.text('night entry'), findsNothing);
    expect(find.text('unspecified entry'), findsNothing);
  });
}
