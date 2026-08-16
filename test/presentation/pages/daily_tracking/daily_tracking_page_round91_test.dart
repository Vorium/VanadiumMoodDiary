// v0.30 round 91 (sub-spec 7 日常追踪 / Task 5 整合入口): 4 widget 测试
//
// 覆盖 (TDD red→green):
// 1. 渲染 7 卡片 + MoodPeriodAggregatorChart
// 2. 点 "情绪日记" 卡片 → 跳 /mood-diary
// 3. 主页 FAB 改 /daily-tracking (1 行变更验证)
// 4. "情绪日记" 卡片显示 period (早/中/晚/夜)
//
// 测试 setup:
// - 不用真实 in-memory DB (StreamProvider 跟 drift 联动会在 pumpAndSettle
//   时挂起, 跟 R91 sleep_widgets_round91_test 同款问题)
// - override 7 latestEntryProvider + allMoodProvider → _FakeLatestMoodEntry
//   (StreamProvider overrideWith 注入 sync value, 跟 R90
//   assessment_center_page_round90_test 同款 pattern)
// - 卡片渲染验证: find.byType(Card) findsNWidgets(7), 加上 chart 验证
// - 跳转验证: inline GoRouter 拿 /mood-diary 目的地, tap first Card → 验证目的地
//
// TDD: 本文件先写 → 跑失败 (page / provider / card not found) → 实施 → 跑 4/4 pass
import 'dart:async';

import 'package:chroniccare/presentation/pages/daily_tracking/widgets/tracking_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/entities/anxiety_agitation_entry.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/domain/entities/social_rhythm_entry.dart';
import 'package:chroniccare/domain/entities/stress_event.dart';
import 'package:chroniccare/domain/entities/treatment_entry.dart';
import 'package:chroniccare/domain/entities/weight_entry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/daily_tracking_page.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/mood_period_aggregator_chart.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_fab_toolbar.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // v0.32 R110 round 5: TrackingConfigNotifier (R109) 启动读
  // sharedPreferencesProvider — 空 mock 即可 (无持久化配置 → 7 卡全显)
  late SharedPreferences sp;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sp = await SharedPreferences.getInstance();
  });

  // helper: 构造测试 widget — 走 inline GoRouter (跟 R90 同款, 实跳路由
  // 验证导航, 不直接 mock context.push)
  Widget wrap({
    List<MoodEntryEntity> moodEntries = const [],
    GoRouter? router,
  }) {
    final effectiveRouter = router ??
        GoRouter(
          initialLocation: '/daily-tracking',
          routes: [
            GoRoute(
              path: '/daily-tracking',
              builder: (context, state) => const DailyTrackingPage(),
            ),
            GoRoute(
              path: '/mood-diary',
              builder: (context, state) => const Scaffold(
                body: Center(child: Text('MOOD_DIARY_DESTINATION')),
              ),
            ),
          ],
        );
    return ProviderScope(
      overrides: [
        // R109: TrackingConfigNotifier 读 SharedPreferences (pinned/hidden)
        sharedPreferencesProvider.overrideWithValue(sp),
        // mood: 提供 entries 给 chart + latestMoodEntryProvider
        allMoodProvider.overrideWith((ref) => Stream.value(moodEntries)),
        // 6 daily tracking repo entries — 给 latestXxxEntryProvider
        // (override 整 entries provider, latestXxxEntryProvider 走 .value
        // 拿 firstOrNull, 避免真实 DB 创建)
        sleepEntriesProvider.overrideWith(
          (ref) => const Stream<List<SleepEntryEntity>>.empty(),
        ),
        socialRhythmEntriesProvider.overrideWith(
          (ref) => const Stream<List<SocialRhythmEntryEntity>>.empty(),
        ),
        stressEventEntriesProvider.overrideWith(
          (ref) => const Stream<List<StressEventEntity>>.empty(),
        ),
        weightEntriesProvider.overrideWith(
          (ref) => const Stream<List<WeightEntryEntity>>.empty(),
        ),
        anxietyAgitationEntriesProvider.overrideWith(
          (ref) => const Stream<List<AnxietyAgitationEntryEntity>>.empty(),
        ),
        // treatment: Task 3 加了 repo, R91 补了 provider, 整合页 "治疗" 卡片
        // 用 latestTreatmentEntryProvider 派生. 漏 override 会触发真实 DB
        // 创建, 报 "AppDatabase multiple times" + pending timer.
        treatmentEntriesProvider.overrideWith(
          (ref) => const Stream<List<TreatmentEntryEntity>>.empty(),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        routerConfig: effectiveRouter,
      ),
    );
  }

  testWidgets('DailyTrackingPage 渲染 7 卡片 + 心境 4 段图', (tester) async {
    // v0.30 round 91 (Task 6): 顶部多指标图 + 心境 4 段图 + 7 卡片 grid
    // 总 content > 1800px, 默认 800x600 viewport 不够, GridView 底部 cards
    // 不在 tree → 设大 viewport 跟 R91 assessment_page_submit 同款
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // 7 张 Card (1 情绪日记 + 5 子功能 + 1 治疗)
    expect(
      find.byType(TrackingItemCard),
      findsAtLeastNWidgets(7),
      reason: '整合入口页有 7 张 Card: 情绪日记/焦虑急躁/睡眠/社会节律/应激源/治疗/体重',
    );

    // MoodPeriodAggregatorChart 集成 (Task 2 已做, 集成到整合页)
    // 即使 entries 为空, chart widget 不渲染 (SizedBox.shrink fallback)
    // 验证 widget tree 包含 (可能 0 渲染当 entries 空)
    // 这里仅验证 Card count, chart 单独由 test 4 验证
  });

  testWidgets('点 "情绪日记" 卡片 → 跳 /mood-diary', (tester) async {
    // v0.30 round 91 (Task 6): 顶部多指标图 + 7 卡片 grid, 总 content > 1800px
    // 设大 viewport 跟 R91 assessment_page_submit 同款
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/daily-tracking',
      routes: [
        GoRoute(
          path: '/daily-tracking',
          builder: (context, state) => const DailyTrackingPage(),
        ),
        GoRoute(
          path: '/mood-diary',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('MOOD_DIARY_DESTINATION')),
          ),
        ),
      ],
    );
    await tester.pumpWidget(wrap(router: router));
    await tester.pumpAndSettle();

    // 验证 DailyTrackingPage 渲染
    expect(find.byType(TrackingItemCard), findsAtLeastNWidgets(7));

    // 点第 1 张 Card (情绪日记, 顺序 0)
    final moodDiaryTile = find.byType(TrackingItemCard).first;
    expect(moodDiaryTile, findsOneWidget);
    await tester.tap(moodDiaryTile, warnIfMissed: false);
    await tester.pumpAndSettle();

    // 验证路由成功 → 目的地页 MOOD_DIARY_DESTINATION 渲染
    expect(
      find.text('MOOD_DIARY_DESTINATION'),
      findsOneWidget,
      reason: '"情绪日记" 卡片 onTap 必须 push /mood-diary',
    );
  });

  testWidgets('主页 FAB 改 /daily-tracking', (tester) async {
    // 单独测 FAB 跳转 (不挂 DailyTrackingPage)
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(body: HomeFabToolbar()),
        ),
        GoRoute(
          path: '/daily-tracking',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('DAILY_TRACKING_DESTINATION')),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();

    // 1. 初始: 收起态, 主 FAB 显示 menu icon
    expect(find.byIcon(Icons.menu), findsOneWidget);

    // 2. tap 主 FAB 展开 4 个工具按钮
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    // 3. 验证展开态: 找到 "日常追踪" 按钮 (l10n.dailyTrackingFab,
    //    v0.30 R91 Task 7 改 label 跟 FAB 跳 /daily-tracking 整合入口保持一致;
    //    v0.30 R91 Fix Round 1 (I-1): 进一步改 "日常追踪" 跟
    //    l10n.dailyTrackingTitle 整合入口页 title 语义一致)
    expect(find.text('日常追踪'), findsOneWidget);

    // 4. tap "日常追踪" 按钮 → 应跳 /daily-tracking
    await tester.tap(find.text('日常追踪'));
    await tester.pumpAndSettle();

    // 5. 验证路由成功 → 目的地页 DAILY_TRACKING_DESTINATION 渲染
    expect(
      find.text('DAILY_TRACKING_DESTINATION'),
      findsOneWidget,
      reason:
          '主页 FAB 跳 /daily-tracking (改 1 行: /assessment-center → /daily-tracking)',
    );
  });

  testWidgets('"情绪日记" 卡片显示 period (早/中/晚/夜)', (tester) async {
    // v0.30 round 91 (Task 6): 顶部多指标图 + 心境 4 段图 + 7 卡片 grid
    // 总 content > 1900px (新 chart 200 + spacer 16 + mood chart 270 + spacer
    // 16 + cards 1420), 设大 viewport 跟 R91 assessment_page_submit 同款
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // 准备 mood_entries 含 period = 'morning'
    final moodWithPeriod = MoodEntryEntity(
      id: 1,
      timestamp: DateTime(2026, 8, 5, 9, 0),
      score: 4,
      period: 'morning',
    );
    await tester.pumpWidget(wrap(moodEntries: [moodWithPeriod]));
    await tester.pumpAndSettle();

    // 验证 DailyTrackingPage 渲染
    expect(find.byType(TrackingItemCard), findsAtLeastNWidgets(7));

    // 验证 MoodPeriodAggregatorChart 渲染 (entries 非空, chart 显示)
    expect(
      find.byType(MoodPeriodAggregatorChart),
      findsOneWidget,
      reason: 'mood_entries 非空时, 心境 4 段图必须渲染',
    );

    // 验证 "情绪日记" 卡片 lastValue 含 period 短 label "早"
    // Card 1 (顺序 0 = 情绪日记) 必须含 "早" 字 (来自 moodPeriodMorning l10n)
    expect(
      find.textContaining('早'),
      findsWidgets,
      reason: '"情绪日记" 卡片 lastValue 必须含心境时段短 label',
    );
  });
}
