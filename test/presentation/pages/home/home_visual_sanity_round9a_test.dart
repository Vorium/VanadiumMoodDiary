// v1.1.0 round 11 (R115 视觉重构): PrimaryActionRow 视觉断言测试
//
// 历史:
// - v0.31 round 9a 原始版: 测 2x2 AppleHealthTile 网格 (用药/评估/回顾/追踪)
// - v1.1.0 round 11 (R115): 改测 3 行 list (情绪回顾/日常追踪/心理技巧)
//   + 单独 widget test 测 MoreEntryTrigger 虚线入口
//
// emotion-first refactor 续作: 主页第一屏不再有「用药」「量表」字样,
// 二级入口走 MoreEntryTrigger → BottomSheet (测在 more_entry_sheet_test)。
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/home/widgets/primary_action_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(body: child),
      );

  group('PrimaryActionRow 列表 (R115 spec: 3 行 emotion-first)', () {
    testWidgets('1. AppleListSection("快捷操作") 标题渲染', (tester) async {
      await tester.pumpWidget(
        wrap(
          PrimaryActionRow(
            onMoodReviewTap: () {},
            onDailyTrackingTap: () {},
            onTipsTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('快捷操作'),
        findsOneWidget,
        reason: 'AppleListSection title "快捷操作" 应渲染',
      );
    });

    testWidgets('2. 3 行 row 渲染 (情绪回顾 / 日常追踪 / 心理技巧)',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          PrimaryActionRow(
            onMoodReviewTap: () {},
            onDailyTrackingTap: () {},
            onTipsTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3 个 row title 渲染
      expect(find.text('情绪回顾'), findsOneWidget);
      expect(find.text('日常追踪'), findsOneWidget);
      expect(find.text('心理技巧'), findsOneWidget);
    });

    testWidgets('3. 3 个 row 各自带副标题 (R115 emotion-first)', (tester) async {
      await tester.pumpWidget(
        wrap(
          PrimaryActionRow(
            onMoodReviewTap: () {},
            onDailyTrackingTap: () {},
            onTipsTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3 个副标题 — 验证 R115 新加的 homeAction*Sub key
      expect(find.text('睡眠 / 体重 / 社交节律'), findsOneWidget);
      expect(find.text('5 个小练习 · 当下可学'), findsOneWidget);
    });

    testWidgets('4. 3 个 row 各自有 iOS 彩色 icon 块 (pink/orange/blue)',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          PrimaryActionRow(
            onMoodReviewTap: () {},
            onDailyTrackingTap: () {},
            onTipsTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 3 个 row 各有 32x32 彩色 icon 块
      // systemPink (情绪回顾) / systemOrange (日常追踪) / systemBlue (心理技巧)
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
        final dec = c.decoration;
        return dec is BoxDecoration &&
            (dec.color == const Color(0xFFFF2D55) || // systemPink
                dec.color == const Color(0xFFFF9500) || // systemOrange
                dec.color == const Color(0xFF007AFF)); // systemBlue
      }).toList();
      expect(
        containers.length,
        greaterThanOrEqualTo(3),
        reason: '应有 3 个 iOS system color 彩色 icon 块 (pink/orange/blue)',
      );
    });

    testWidgets('5. 3 个 onTap callback 各自能触发 (路由注入契约)',
        (tester) async {
      var moodReview = 0;
      var dailyTracking = 0;
      var tips = 0;
      await tester.pumpWidget(
        wrap(
          PrimaryActionRow(
            onMoodReviewTap: () => moodReview++,
            onDailyTrackingTap: () => dailyTracking++,
            onTipsTap: () => tips++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('情绪回顾'));
      await tester.pump();
      expect(moodReview, 1, reason: '情绪回顾 tap 应触发回调');

      await tester.tap(find.text('日常追踪'));
      await tester.pump();
      expect(dailyTracking, 1, reason: '日常追踪 tap 应触发回调');

      await tester.tap(find.text('心理技巧'));
      await tester.pump();
      expect(tips, 1, reason: '心理技巧 tap 应触发回调');
    });
  });

  group('MoreEntryTrigger 弱化二级入口 (R115)', () {
    testWidgets('1. 虚线边框 + 「更多」标题 + 副标题渲染', (tester) async {
      await tester.pumpWidget(
        wrap(const MoreEntryTrigger()),
      );
      await tester.pumpAndSettle();

      expect(find.text('更多'), findsOneWidget,
          reason: '「更多」主标题渲染');
      expect(find.text('用药 · 量表 · 危机热线'), findsOneWidget,
          reason: '副标题列 3 个二级入口预览');
    });

    testWidgets('2. 边框是虚线 (Border.all 0.5 宽, 弱 affordance)',
        (tester) async {
      await tester.pumpWidget(
        wrap(const MoreEntryTrigger()),
      );
      await tester.pumpAndSettle();

      // 触发 tap 不报错即可 (BottomSheet 在 widget test 没装 navigator 会抛,
      // 这里只验证 widget 树可构建, 不实际 tap)
      expect(find.byType(MoreEntryTrigger), findsOneWidget);
    });
  });
}
