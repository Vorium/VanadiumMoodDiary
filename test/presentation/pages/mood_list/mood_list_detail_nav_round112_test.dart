// v0.32 R112-02: mood 列表条目点击 → 详情页导航
//
// 背景: mood_detail_page.dart (332 行) 全库 0 caller — 列表条目没有 onTap,
// 详情功能入口不存在。
// 修复: MoodListItem 挂 onTap → context.push('/mood/detail/:id')。
// 注: 生产路由注册在 core/routing/app_route_mood_list.dart (本文件不属于
// 实现 subagent 所有权, 已报告主 agent); 测试用 inline GoRouter 验证导航。
//
// 覆盖:
// 1. 点击第 2 条条目 → 跳 /mood/detail/2 + 详情页显示该条 note/score
// 2. entryId 不存在 → 显示"找不到"兜底文案 (不崩)

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_detail_page.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_list_page.dart';
import 'package:chroniccare/presentation/providers/cbt_rerated_entries_provider.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/providers/worry_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  final entries = [
    MoodEntryEntity(
      id: 1,
      timestamp: DateTime(2026, 8, 5, 9),
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
      timestamp: DateTime(2026, 8, 3, 12),
      score: 3,
      note: '一般般',
    ),
  ];

  Widget wrap({GoRouter? router}) {
    final effectiveRouter = router ??
        GoRouter(
          initialLocation: '/mood-list',
          routes: [
            GoRoute(
                path: '/mood-list', builder: (c, s) => const MoodListPage()),
            GoRoute(
              path: '/mood/detail/:id',
              builder: (c, s) => MoodDetailPage(
                entryId: int.tryParse(s.pathParameters['id'] ?? '') ?? 0,
              ),
            ),
          ],
        );
    return ProviderScope(
      overrides: [
        moodEntriesProvider.overrideWith((ref) => entries),
        allMoodProvider.overrideWith((ref) => Stream.value(entries)),
        // v1.1.0 round 9 (F1): MoodListPage 内嵌 WorrySection, override 空列表
        worryOpenProvider.overrideWith((ref) => Stream.value(const [])),
        worryResolvedProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        routerConfig: effectiveRouter,
      ),
    );
  }

  testWidgets('1) 点击条目 → 详情页显示对应 note', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // 列表页初始状态
    expect(find.text('Mood 历史'), findsOneWidget);
    expect(find.text('感觉很难受'), findsOneWidget);

    // 点击第 2 条 (id=2)
    await tester.tap(find.text('感觉很难受'));
    await tester.pumpAndSettle();

    // 详情页: 标题 + note + 2/5 评分
    expect(find.text('情绪详情'), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget);
    expect(find.text('感觉很难受'), findsOneWidget);
  });

  testWidgets('2) entryId 不存在 → 兜底文案不崩', (tester) async {
    final router = GoRouter(
      initialLocation: '/mood/detail/999',
      routes: [
        GoRoute(path: '/mood-list', builder: (c, s) => const MoodListPage()),
        GoRoute(
          path: '/mood/detail/:id',
          builder: (c, s) => MoodDetailPage(
            entryId: int.tryParse(s.pathParameters['id'] ?? '') ?? 0,
          ),
        ),
      ],
    );
    await tester.pumpWidget(wrap(router: router));
    await tester.pumpAndSettle();

    expect(find.text('情绪详情'), findsOneWidget);
    expect(find.text('找不到这条情绪记录'), findsOneWidget);
  });
}
