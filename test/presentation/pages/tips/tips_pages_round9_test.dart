// 1.1.0 round 9 (论文落地 F3 心理技巧知识库): tips 页面 widget 测试
//
// 覆盖:
// 1. TipsListPage: 渲染 5 条技巧 (localized title) + 点击 → /tips/:id 详情
// 2. TipsDetailPage: 标题 + 摘要 + 步骤编号列表
// 3. 未知 id → 找不到 state (不崩)
//
// 纯静态内容 (0 provider / 0 DB), 只需 MaterialApp + GoRouter + l10n。

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/tips/tips_detail_page.dart';
import 'package:chroniccare/presentation/pages/tips/tips_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  Future<void> pumpRouter(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/tips',
      routes: [
        GoRoute(
          path: '/tips',
          builder: (_, __) => const TipsListPage(),
        ),
        GoRoute(
          path: '/tips/:id',
          builder: (_, state) =>
              TipsDetailPage(tipId: state.pathParameters['id'] ?? ''),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: ThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('1) 列表页渲染 5 条技巧 title', (tester) async {
    await pumpRouter(tester);
    expect(find.byType(TipsListPage), findsOneWidget);
    for (final title in const [
      '正念呼吸',
      '情绪命名',
      '认知重构',
      '5-4-3-2-1 感官接地',
      '渐进式肌肉放松',
    ]) {
      expect(find.text(title), findsOneWidget, reason: '列表应显示 $title');
    }
  });

  testWidgets('2) 点击技巧 → 详情页渲染摘要 + 步骤', (tester) async {
    await pumpRouter(tester);
    await tester.tap(find.text('认知重构'));
    await tester.pumpAndSettle();

    expect(find.byType(TipsDetailPage), findsOneWidget);
    expect(
      find.text('识别并调整不合理的自动思维，可搭配 CBT 思维记录'),
      findsOneWidget,
    );
    // 5 步 + 摘要 (摘要那步无序号)
    expect(find.textContaining('记录引发情绪的具体情境'), findsOneWidget);
    expect(find.textContaining('在情绪日记中使用 5 栏 CBT 记录练习'), findsOneWidget);
  });

  testWidgets('3) 详情页显示步骤序号 (1..5)', (tester) async {
    await pumpRouter(tester);
    await tester.tap(find.text('正念呼吸'));
    await tester.pumpAndSettle();

    for (var i = 1; i <= 5; i++) {
      expect(find.text('$i'), findsWidgets, reason: '步骤序号 $i 应显示');
    }
  });

  testWidgets('4) 未知 id → 找不到 state (不崩)', (tester) async {
    final router = GoRouter(
      initialLocation: '/tips/nope',
      routes: [
        GoRoute(
          path: '/tips/:id',
          builder: (_, state) =>
              TipsDetailPage(tipId: state.pathParameters['id'] ?? ''),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: ThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
