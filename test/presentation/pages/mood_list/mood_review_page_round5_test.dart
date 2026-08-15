// 1.1.0 round 5e (emotion-first refactor · Task 15): MoodReviewPage widget 测试
//
// 覆盖 6 个 case:
// 1. 标题 moodReviewTitle 渲染 (AppBar + AppleListSection 章节标题)
// 2. 记录天数 2 渲染 (本周 2 条)
// 3. 均分 3.0 渲染 ((2+4)/2)
// 4. delta +0.0 渲染 (本周 3.0 - 上周 3.0)
// 5. SegmentedButton 切 '月' → 过滤范围变化 (entriesCount 2→4,
//    上周无数据 → delta 显示 moodReviewDeltaNoData)
// 6. 空数据 → domain encouragement 空态文案渲染
//
// 测试策略 (跟 mood_list_page_round87_test 一致):
// - MaterialApp + l10n delegates + zh locale
// - allMoodProvider.overrideWith 注入固定 Stream (跳过 DB)
// - 页面构造注入固定 now (DateTime(2026, 8, 15, 10, 0) 周六),
//   周界/月界确定性可测 (不随测试运行日期漂移)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_review_page.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';

void main() {
  // 固定 now: 2026-08-15 (周六) 10:00
  // 周界: 本周 = 08-10 (周一) ~ 08-15, 上周 = 08-03 ~ 08-09
  // 月界: 本月 = 08-01 ~ 08-15, 上月 = 07 月
  final now = DateTime(2026, 8, 15, 10, 0);

  // 固定 4 条:
  // - 本周 2 条: id=1 (08-14, score 4, tags [放松]), id=2 (08-12, score 2, tags [焦虑])
  //   → 均分 (4+2)/2 = 3.0
  // - 上周 1 条: id=3 (08-08, score 3) → delta = 3.0 - 3.0 = 0.0
  // - 本月第 1 周 1 条: id=4 (08-02, score 1) — 只进月窗口不进周窗口
  List<MoodEntryEntity> makeEntries() => [
        MoodEntryEntity(
          id: 1,
          timestamp: DateTime(2026, 8, 14, 18, 0),
          score: 4,
          tagsJson: '["放松"]',
        ),
        MoodEntryEntity(
          id: 2,
          timestamp: DateTime(2026, 8, 12, 9, 0),
          score: 2,
          tagsJson: '["焦虑"]',
        ),
        MoodEntryEntity(
          id: 3,
          timestamp: DateTime(2026, 8, 8, 12, 0),
          score: 3,
        ),
        MoodEntryEntity(
          id: 4,
          timestamp: DateTime(2026, 8, 2, 9, 0),
          score: 1,
        ),
      ];

  Widget wrap({List<MoodEntryEntity> entries = const []}) {
    return ProviderScope(
      overrides: [
        allMoodProvider.overrideWith((ref) => Stream.value(entries)),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: MoodReviewPage(now: now),
      ),
    );
  }

  group('1.1.0 round 5e 情绪回顾页 (MoodReviewPage)', () {
    testWidgets('1. 标题 moodReviewTitle 渲染', (tester) async {
      await tester.pumpWidget(wrap(entries: makeEntries()));
      await tester.pumpAndSettle();

      // AppBar title + AppleListSection 章节 title 各 1 处
      expect(find.text('情绪回顾'), findsNWidgets(2));
    });

    testWidgets('2. 记录天数 2 渲染 (本周 2 条)', (tester) async {
      await tester.pumpWidget(wrap(entries: makeEntries()));
      await tester.pumpAndSettle();

      expect(find.text('记录天数'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('3. 均分 3.0 渲染 ((4+2)/2)', (tester) async {
      await tester.pumpWidget(wrap(entries: makeEntries()));
      await tester.pumpAndSettle();

      expect(find.text('平均心情'), findsOneWidget);
      expect(find.text('3.0'), findsOneWidget);
    });

    testWidgets('4. delta +0.0 渲染 (本周 3.0 - 上周 3.0)', (tester) async {
      await tester.pumpWidget(wrap(entries: makeEntries()));
      await tester.pumpAndSettle();

      expect(find.text('较上期变化'), findsOneWidget);
      expect(find.text('+0.0'), findsOneWidget);
    });

    testWidgets('5. 切 月 → 过滤范围变化 (entriesCount 2→4, delta 无上期数据)',
        (tester) async {
      await tester.pumpWidget(wrap(entries: makeEntries()));
      await tester.pumpAndSettle();

      // 周模式: 2 条
      expect(find.text('2'), findsOneWidget);

      // 切到月
      await tester.tap(find.text('月'));
      await tester.pumpAndSettle();

      // 月模式: 4 条 (08-02 / 08-08 / 08-12 / 08-14 全在 8 月),
      // 上月无数据 → delta 显示 no-data 文案
      expect(find.text('2'), findsNothing);
      expect(find.text('4'), findsOneWidget);
      expect(find.text('暂无上期数据'), findsOneWidget);
    });

    testWidgets('6. 空数据 → domain encouragement 空态文案渲染', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // domain 层空态鼓励文案 (mood_review_aggregator._encouragement)
      expect(find.text('这周还没记录心情，从现在开始吧'), findsOneWidget);
    });
  });
}
