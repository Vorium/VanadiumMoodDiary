// v0.30 round 87 (sub-spec 3 mood 列表页): MoodListPage orchestrator widget 测试
//
// 覆盖 3 个 case:
// 1. 有数据: 渲染 search TextField + 3 filter chip + N 条 MoodListItem
// 2. 空数据: 渲染 EmptyState (moodListEmpty 文案)
// 3. search "难" 实时过滤 → 只剩 1 条
//
// 跟 Task 1-3 (filter provider / Item / FilterBar) 风格一致:
// - MaterialApp + l10n delegates + zh locale
// - moodEntriesProvider.overrideWith 注 sync list (跳过 allMoodProvider StreamProvider)
// - find.text 用于断言显示文案
// - find.byType(TextField) + enterText 模拟用户输入
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_list_page.dart';
import 'package:chroniccare/presentation/providers/cbt_rerated_entries_provider.dart';

void main() {
  // helper: 3 条 mood entries (覆盖不同 score / note)
  List<MoodEntryEntity> makeEntries() => [
        MoodEntryEntity(
          id: 1,
          timestamp: DateTime(2026, 8, 5, 9, 0),
          score: 5,
          note: '今天很开心',
        ),
        MoodEntryEntity(
          id: 2,
          timestamp: DateTime(2026, 8, 4, 18, 30),
          score: 2,
          note: '感觉很难受',
        ),
        MoodEntryEntity(
          id: 3,
          timestamp: DateTime(2026, 8, 3, 12, 0),
          score: 3,
          note: '一般般',
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

  testWidgets('有数据: 显示 search + filter chips + N 条 entry', (tester) async {
    await tester.pumpWidget(wrap(entries: makeEntries()));
    await tester.pumpAndSettle();

    // 顶部: 1 个 search TextField (含 hint "搜索 note…")
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('搜索 note…'), findsOneWidget);

    // 3 filter chip (复用 Task 3 的 l10n key)
    expect(find.widgetWithText(ActionChip, '日期'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '分数'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'CBT 档位'), findsOneWidget);

    // 列表: 3 条 note 都应可见
    expect(find.text('今天很开心'), findsOneWidget);
    expect(find.text('感觉很难受'), findsOneWidget);
    expect(find.text('一般般'), findsOneWidget);
  });

  testWidgets('空数据: 显示 EmptyState', (tester) async {
    await tester.pumpWidget(wrap(entries: const []));
    await tester.pumpAndSettle();

    // EmptyState 文案 (l10n.moodListEmpty)
    expect(find.text('还没有 mood 记录'), findsOneWidget);
    // 没数据 → 0 条 MoodListItem
    expect(find.text('今天很开心'), findsNothing);
  });

  testWidgets('search "难" 实时过滤 → 只剩 1 条', (tester) async {
    await tester.pumpWidget(wrap(entries: makeEntries()));
    await tester.pumpAndSettle();

    // 初始 3 条都在
    expect(find.text('今天很开心'), findsOneWidget);
    expect(find.text('感觉很难受'), findsOneWidget);
    expect(find.text('一般般'), findsOneWidget);

    // 在 search field 输入 "难"
    await tester.enterText(find.byType(TextField), '难');
    await tester.pumpAndSettle();

    // 只剩 id=2 ("感觉很难受")
    expect(find.text('感觉很难受'), findsOneWidget);
    expect(find.text('今天很开心'), findsNothing);
    expect(find.text('一般般'), findsNothing);
  });
}
