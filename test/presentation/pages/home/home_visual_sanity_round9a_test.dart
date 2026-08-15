// v0.31 round 9a (Apple Health redesign · Phase 3 Task 3.1):
// home_page 视觉 sanity test (PrimaryActionRow)
//
// 覆盖 spec §5.1 第 4 块 (快捷操作 2x2 AppleHealthTile)
//
// 1.1.0 round 5b (Task 12): SecondaryActionRow 删除 → 本文件删 SecondaryActionRow
// 测试组; PrimaryActionRow 4 tile 换血 (用药/量表/情绪回顾/日常追踪) +
// 回调改 onMedicationTap / onAssessmentTap / onMoodReviewTap /
// onDailyTrackingTap, tile 断言同步。
//
// 设计选择:
// - 只测无 provider 依赖的 widget (PrimaryActionRow), 复杂 widget
//   (TodaySummaryCard / MoodHeroCard) 需 DB stream mock, 走 round 5b 测试
// - AppleListSection 结构断言: section title + Container padding + chevron 16pt
// - 不依赖 Material 3 darkTheme, 走默认 lightMode (跟 R8a AppleListSection 一致)
// - 跳过 navigation context.push 实际跳转验证 (go_router 需 ProviderScope 全套
//   + GoRouter setup, 留给 round 5b 集成测)
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/apple_health_tile.dart';
import 'package:chroniccare/presentation/pages/home/widgets/primary_action_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 找指定 IconData 的 28pt icon (AppleHealthTile 内部 metric icon,
/// 跟 chevron 16pt / 24pt 区分)
Finder findMetricIcon(IconData icon) => find.byWidgetPredicate(
      (w) => w is Icon && w.icon == icon && w.size == 28,
    );

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(body: child),
      );

  group('PrimaryActionRow 2x2 彩色 tile 网格 (R9a spec §5.1 第 4 块)', () {
    testWidgets('1. AppleListSection("快捷操作") 标题渲染', (tester) async {
      await tester.pumpWidget(
        wrap(
          PrimaryActionRow(
            onMedicationTap: () {},
            onAssessmentTap: () {},
            onMoodReviewTap: () {},
            onDailyTrackingTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "快捷操作" section title (ALL CAPS — 中文无大小写, 视觉不变)
      expect(
        find.text('快捷操作'),
        findsOneWidget,
        reason: 'AppleListSection title "快捷操作" 应渲染',
      );
    });

    testWidgets(
        '2. 4 个 AppleHealthTile 渲染 (medication / assessment / mood / trend)',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          PrimaryActionRow(
            onMedicationTap: () {},
            onAssessmentTap: () {},
            onMoodReviewTap: () {},
            onDailyTrackingTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 4 个 AppleHealthTile widget
      expect(
        find.byType(AppleHealthTile),
        findsNWidgets(4),
        reason: '应渲染 4 个 AppleHealthTile (用药/量表/情绪回顾/日常追踪)',
      );

      // 4 个 metric icon (28pt) 各自渲染
      // 1.1.0 round 5b: vent tile 换 日常追踪 (trend)
      expect(
        findMetricIcon(Icons.medication),
        findsOneWidget,
        reason: 'medication tile icon 渲染',
      );
      expect(
        findMetricIcon(Icons.assignment),
        findsOneWidget,
        reason: 'assessment tile icon 渲染',
      );
      expect(
        findMetricIcon(Icons.mood),
        findsOneWidget,
        reason: 'mood tile icon 渲染',
      );
      expect(
        findMetricIcon(Icons.show_chart),
        findsOneWidget,
        reason: 'trend tile icon 渲染',
      );
    });

    testWidgets('3. 4 个 metric icon 颜色 = Apple Health iOS system colors',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          PrimaryActionRow(
            onMedicationTap: () {},
            onAssessmentTap: () {},
            onMoodReviewTap: () {},
            onDailyTrackingTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 4 个 metric 色跟 healthMetricsColors 1:1 对应
      final medIcon = tester.widget<Icon>(findMetricIcon(Icons.medication));
      final assessIcon = tester.widget<Icon>(findMetricIcon(Icons.assignment));
      final moodIcon = tester.widget<Icon>(findMetricIcon(Icons.mood));
      final trendIcon = tester.widget<Icon>(findMetricIcon(Icons.show_chart));

      expect(
        medIcon.color,
        AppColors.healthMetricsColorFor('medication'),
        reason: 'medication icon = systemRed',
      );
      expect(
        assessIcon.color,
        AppColors.healthMetricsColorFor('assessment'),
        reason: 'assessment icon = systemIndigo',
      );
      expect(
        moodIcon.color,
        AppColors.healthMetricsColorFor('mood'),
        reason: 'mood icon = systemPink',
      );
      expect(
        trendIcon.color,
        AppColors.healthMetricsColorFor('trend'),
        reason: 'trend icon = systemBlue',
      );
    });

    testWidgets('4. 4 个 tile label 走新 homeAction* key (用药/量表/情绪回顾/日常追踪)',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          PrimaryActionRow(
            onMedicationTap: () {},
            onAssessmentTap: () {},
            onMoodReviewTap: () {},
            onDailyTrackingTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1.1.0 round 5b: label 换血 homeAction*
      expect(find.text('用药'), findsOneWidget);
      expect(find.text('量表'), findsOneWidget);
      expect(find.text('情绪回顾'), findsOneWidget);
      expect(find.text('日常追踪'), findsOneWidget);
    });
  });
}
