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
import 'package:go_router/go_router.dart';

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

  // round 7c: /mood-trend 入口补齐 → tap 导航断言用 router 包装
  Widget wrapWithRouter({List<MoodEntryEntity> entries = const []}) {
    final router = GoRouter(
      initialLocation: '/mood-review',
      routes: [
        GoRoute(
          path: '/mood-review',
          builder: (context, state) => MoodReviewPage(now: now),
        ),
        GoRoute(
          path: '/mood-trend',
          builder: (context, state) =>
              const Scaffold(body: Text('mood-trend-stub')),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        allMoodProvider.overrideWith((ref) => Stream.value(entries)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
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

      // round 7b: domain 层产 tier, footer 走 localizedEncouragement → zh ARB
      expect(find.text('这周还没记录心情，从现在开始吧'), findsOneWidget);
    });

    testWidgets('7. 时段分组显示本地化标签 (复用 mood_detail 时段 l10n)', (tester) async {
      // 本周 2 条带时段: morning + night (全部落在周窗口 08-10 ~ 08-15)
      final entries = [
        MoodEntryEntity(
          id: 5,
          timestamp: DateTime(2026, 8, 12, 9, 0),
          score: 3,
          period: 'morning',
        ),
        MoodEntryEntity(
          id: 6,
          timestamp: DateTime(2026, 8, 13, 23, 0),
          score: 3,
          period: 'night',
        ),
      ];
      await tester.pumpWidget(wrap(entries: entries));
      await tester.pumpAndSettle();

      // 本地化标签渲染 (moodPeriodMorning=morning→早上, moodPeriodNight=night→夜间)
      expect(find.text('早上'), findsOneWidget);
      expect(find.text('夜间'), findsOneWidget);
      // 裸 key 不再泄露给用户
      expect(find.text('morning'), findsNothing);
      expect(find.text('night'), findsNothing);
      // 稳定显示序: morning 在 night 上方
      expect(
        tester.getTopLeft(find.text('早上')).dy,
        lessThan(tester.getTopLeft(find.text('夜间')).dy),
      );
    });

    testWidgets('8. footer 下显示 查看趋势图 按钮 (round 7c /mood-trend 入口)',
        (tester) async {
      await tester.pumpWidget(wrap(entries: makeEntries()));
      await tester.pumpAndSettle();

      // footer 在 ListView 底部 (lazy 未构建), 先滚动到可见
      await tester.scrollUntilVisible(find.text('查看趋势图'), 200);
      expect(find.text('查看趋势图'), findsOneWidget);
    });

    testWidgets('9. tap 查看趋势图 → /mood-trend 路由到达 (round 7c 死路由入口补齐)',
        (tester) async {
      await tester.pumpWidget(wrapWithRouter(entries: makeEntries()));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('查看趋势图'), 200);
      await tester.tap(find.text('查看趋势图'));
      await tester.pumpAndSettle();

      expect(
        find.text('mood-trend-stub'),
        findsOneWidget,
        reason: 'tap 查看趋势图应 push /mood-trend 路由',
      );
    });
  });
}
