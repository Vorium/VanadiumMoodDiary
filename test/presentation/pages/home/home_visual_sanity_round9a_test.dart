// v0.31 round 9a (Apple Health redesign · Phase 3 Task 3.1):
// home_page 视觉 sanity test (PrimaryActionRow / SecondaryActionRow)
//
// 覆盖 spec §5.1 第 4 块 (快捷操作 2x2 AppleHealthTile) + 第 5 块 (更多 4 cell)
//
// 设计选择:
// - 只测无 provider 依赖的 widget (PrimaryActionRow / SecondaryActionRow),
//   复杂 widget (TodaySummaryCard / QuickMoodCarousel) 需 DB stream mock,
//   留给 Round 9d 单独测
// - AppleListSection 结构断言: section title + Container padding + chevron 16pt
// - 不依赖 Material 3 darkTheme, 走默认 lightMode (跟 R8a AppleListSection 一致)
// - 跳过 navigation context.push 实际跳转验证 (go_router 需 ProviderScope 全套
//   + GoRouter setup, 留给 round 9d 集成测)
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/apple_health_tile.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/pages/home/widgets/primary_action_row.dart';
import 'package:chroniccare/presentation/pages/home/widgets/secondary_action_row.dart';
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
            onMoodTap: () {},
            onVentTap: () {},
            onAssessmentTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "快捷操作" section title (ALL CAPS — 中文无大小写, 视觉不变)
      expect(find.text('快捷操作'), findsOneWidget,
          reason: 'AppleListSection title "快捷操作" 应渲染',);
    });

    testWidgets(
        '2. 4 个 AppleHealthTile 渲染 (medication / mood / vent / assessment)',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          PrimaryActionRow(
            onMedicationTap: () {},
            onMoodTap: () {},
            onVentTap: () {},
            onAssessmentTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 4 个 AppleHealthTile widget
      expect(find.byType(AppleHealthTile), findsNWidgets(4),
          reason: '应渲染 4 个 AppleHealthTile (medication/mood/vent/assessment)',);

      // 4 个 metric icon (28pt) 各自渲染
      expect(findMetricIcon(Icons.medication), findsOneWidget,
          reason: 'medication tile icon 渲染',);
      expect(findMetricIcon(Icons.mood), findsOneWidget,
          reason: 'mood tile icon 渲染',);
      expect(findMetricIcon(Icons.mic), findsOneWidget,
          reason: 'vent tile icon 渲染',);
      expect(findMetricIcon(Icons.assignment), findsOneWidget,
          reason: 'assessment tile icon 渲染',);
    });

    testWidgets('3. 4 个 metric icon 颜色 = Apple Health iOS system colors',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          PrimaryActionRow(
            onMedicationTap: () {},
            onMoodTap: () {},
            onVentTap: () {},
            onAssessmentTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 4 个 metric 色跟 healthMetricsColors 1:1 对应
      final medIcon = tester.widget<Icon>(findMetricIcon(Icons.medication));
      final moodIcon = tester.widget<Icon>(findMetricIcon(Icons.mood));
      final ventIcon = tester.widget<Icon>(findMetricIcon(Icons.mic));
      final assessIcon = tester.widget<Icon>(findMetricIcon(Icons.assignment));

      expect(medIcon.color, AppColors.healthMetricsColorFor('medication'),
          reason: 'medication icon = systemRed',);
      expect(moodIcon.color, AppColors.healthMetricsColorFor('mood'),
          reason: 'mood icon = systemPink',);
      expect(ventIcon.color, AppColors.healthMetricsColorFor('vent'),
          reason: 'vent icon = systemPurple',);
      expect(assessIcon.color, AppColors.healthMetricsColorFor('assessment'),
          reason: 'assessment icon = systemIndigo',);
    });
  });

  group('SecondaryActionRow 4 cell icon-row (R9a spec §5.1 第 5 块)', () {
    testWidgets('4. AppleListSection("更多") 标题渲染', (tester) async {
      await tester.pumpWidget(
        wrap(
          SecondaryActionRow(
            onMoodTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('更多'), findsOneWidget,
          reason: 'AppleListSection title "更多" 应渲染',);
    });

    testWidgets('5. 4 个 cell 渲染 (心情 / Mood 历史 / 树洞 / 设置)', (tester) async {
      await tester.pumpWidget(
        wrap(
          SecondaryActionRow(
            onMoodTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 4 个 cell title
      expect(find.text('心情'), findsOneWidget);
      expect(find.text('Mood 历史'), findsOneWidget);
      expect(find.text('树洞'), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);

      // 4 个 chevron (16pt)
      expect(
          find.byWidgetPredicate(
            (w) => w is Icon && w.icon == Icons.chevron_right && w.size == 16,
          ),
          findsNWidgets(4),
          reason: '4 个 cell 都应该有 chevron 16pt',);
    });

    testWidgets('6. cell 间距 16 (AppleListSection 默认 cell padding 16/12)',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          SecondaryActionRow(
            onMoodTap: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // AppleListSection cell default padding = EdgeInsets.symmetric(
      //   horizontal: spacingMd=16, vertical: spacingSm=12)
      // 验证 Cell padding: 找 Padding widget inside AppleListSection
      final paddings = tester.widgetList<Padding>(
        find.descendant(
          of: find.byType(AppleListSection),
          matching: find.byType(Padding),
        ),
      );
      expect(paddings, isNotEmpty,
          reason: 'AppleListSection 应至少渲染 1 个 Padding cell',);
      // 至少 1 个 cell padding 走 horizontal 16 (跟 R8a 测试模式一致)
      final has16h = paddings.any(
        (p) =>
            p.padding ==
            const EdgeInsets.symmetric(
              horizontal: AppTokens.spacingMd,
              vertical: AppTokens.spacingSm,
            ),
      );
      expect(has16h, isTrue,
          reason: 'AppleListSection cell 至少 1 个走 default padding 16/12',);
    });
  });
}
