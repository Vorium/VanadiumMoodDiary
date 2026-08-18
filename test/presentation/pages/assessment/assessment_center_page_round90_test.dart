// v0.30 round 90 (sub-spec 6 量表中心): AssessmentCenterPage widget 测试
//
// 覆盖 4 个 case:
// 1. 渲染 10 开放 + 2 unavailable 卡片 (总共 12 张 Card)
// 2. 点 open 卡片 → 跳 /assessment/<scaleId> (R60 单 scale 模式, 老路由不破坏)
// 3. 无 entry 时 open 卡片显示 "尚未填写过"
// 4. unavailable 卡片显示锁 icon + "需法务/临床审核" 灰色
//
// Provider 覆盖策略:
// - allAssessmentEntriesProvider.overrideWith → Stream.value(entries)
//   (跟 mood_list_page_round87_test 同款, 直接控制数据)
// - allScalesProvider / unavailableScaleIds 是 const, 不需 override
// - AssessmentCenterCard 内部用 context.push 跳路由, 走 go_router 实际跳
//
// TDD: 本文件先写 → 跑失败 (page / provider not found) → 实施 → 跑 4/4 pass
//
// v0.30 round 93 (阶段 2 audit-fixes): PHQ-9 / GAD-7 走
// [FeatureFlags.phqGad7I18nEnabled] gate, 默认 false 隐藏 2 量表。
// 老 test 假设 10 开放 + 2 unavailable = 12 Card, setUp 翻
// setPhqGad7I18nEnabledForTest(true) 让老 test 不破 (跟其他老 test
// 修法一致)。

import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/entities/assessment_entry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_center_page.dart';
import 'package:chroniccare/presentation/providers/assessment_providers.dart';

void main() {
  setUp(() {
    // v0.30 round 93: 翻 phqGad7I18nEnabled=true 让老 test 12 Card 不破
    FeatureFlags.setPhqGad7I18nEnabledForTest(true);
  });
  tearDown(FeatureFlags.resetForTest);

  // helper: 构造测试 widget
  //
  // 用 go_router 实跳路由, 走 onTap 实际跳 /assessment/<scaleId>
  // 避免在测试里 mock context.push (会丢真实路由校验)
  //
  // 默认 router 走 inline GoRouter, navigation 测试单独构造一个含
  // /assessment/:id 目的地的 router 验证跳页成功 (跟 R45
  // contacts_list_widget_round45_test 同模式, 查目的地 text).
  Widget wrap({
    List<AssessmentEntry> entries = const [],
    GoRouter? router,
  }) {
    final effectiveRouter = router ??
        GoRouter(
          initialLocation: '/assessment-center',
          routes: [
            GoRoute(
              path: '/assessment-center',
              builder: (context, state) => const AssessmentCenterPage(),
            ),
          ],
        );
    return ProviderScope(
      overrides: [
        allAssessmentEntriesProvider
            .overrideWith((ref) => Stream.value(entries)),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        routerConfig: effectiveRouter,
      ),
    );
  }

  testWidgets('渲染 10 开放 + 2 unavailable 卡片 (12 张 Card)', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // 10 开放 + 2 unavailable = 12 张 Card
    expect(find.byType(Card), findsNWidgets(12));

    // 2 unavailable 量表的锁 icon 都在
    expect(find.byIcon(Icons.lock_outline), findsNWidgets(2));

    // 10 个量表 displayName 至少包含 PHQ-9 / GAD-7
    // v0.30 round 92 (P0 #14): 顶部 chart 加 10 chip 列表, PHQ-9 跟
    // GAD-7 文案同时出现在 chart chip + center card, 改 findsWidgets (≥1)
    expect(find.text('PHQ-9 情绪自测'), findsWidgets);
    expect(find.text('GAD-7 情绪自测'), findsWidgets);
  });

  testWidgets('点 open 卡片 → 跳 /assessment/<scaleId>', (tester) async {
    // 共享 router 引用, 导航后从 router 拿 state
    final router = GoRouter(
      initialLocation: '/assessment-center',
      routes: [
        GoRoute(
          path: '/assessment-center',
          builder: (context, state) => const AssessmentCenterPage(),
        ),
        GoRoute(
          path: '/assessment/:id',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('R60_DESTINATION_PAGE')),
          ),
        ),
      ],
    );
    await tester.pumpWidget(wrap(router: router));
    await tester.pumpAndSettle();

    // 点 PHQ-9 卡片上的 Card (走 InkWell.onTap, 包整个 card)
    final phq9Card = find.byType(Card).first;
    expect(phq9Card, findsOneWidget);
    await tester.tap(phq9Card, warnIfMissed: false);
    await tester.pumpAndSettle();

    // 验证路由成功 → 目的地页 R60_DESTINATION_PAGE 渲染
    // (跟 R45 contacts_list_widget 测试同模式, 不直接查 router state)
    expect(find.text('R60_DESTINATION_PAGE'), findsOneWidget);
  });

  testWidgets('无 entry 时 open 卡片显示 "尚未填写过"', (tester) async {
    // entries = []  → 所有 10 张 open 卡片都显示 fallback 文案
    await tester.pumpWidget(wrap(entries: const []));
    await tester.pumpAndSettle();

    // 10 张 open 卡片, 每张都有 "尚未填写过" (placeholder 字符串, Task 6 换 ARB)
    expect(find.text('尚未填写过'), findsNWidgets(10));
  });

  testWidgets('unavailable 卡片显示锁 icon + "需法务/临床审核" 灰色', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // 2 张 unavailable 卡片都显示 "需法务／临床审核" 文案 (全角斜杠)
    expect(find.text('需法务／临床审核'), findsNWidgets(2));

    // NSESSS / CRDPSS 名字 (来自 unavailableScaleIds) — 走 _displayName fallback
    expect(find.text('NSESSS PTSD'), findsOneWidget);
    expect(find.text('CRDPSS'), findsOneWidget);
  });
}
