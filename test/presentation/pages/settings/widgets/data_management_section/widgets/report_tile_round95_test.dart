// v0.30 round 95 (sub-spec 1 task 4a): report_tile widget 测试
//
// 覆盖 (跟 brief §1.4 步骤 4a 测试 3 case 一致):
// 1. 渲染 AppListTile (icon / title / subtitle)
// 2. onTap → ChooseWindowDialog (3 个 RadioListTile 选项)
// 3. onShow callback 注入 — 跳过完整链路
//
// 模式 (跟项目其它 settings widget test 一致, R95 步骤 2-3 模式):
// - MaterialApp + AppLocalizations.localizationsDelegates + locale: Locale('zh')
// - ConsumerWidget 自包含 _chooseAndShowReport 完整流程
// - onShow 回调: 留测试可跳过 ChooseWindowDialog + MedicationReport 完整链路
// - 完整 _showMedicationReport 链路需 mock database + 3 stream provider, 端到端
//   测在 settings_page_round45_test.dart 覆盖。本测试只验 ConsumerWidget 渲染 + 入口。
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/report_tile.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void _setBigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrap({Future<void> Function()? onShow}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: ReportTile(onShow: onShow),
      ),
    ),
  );
}

void main() {
  // ============================================================
  // 1. 渲染 AppListTile (icon / title / subtitle)
  // ============================================================
  testWidgets(
    '1) 渲染: AppListTile + summarize_outlined icon + "用药报告" title + subtitle',
    (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // AppListTile 渲染
      expect(find.byType(AppListTile), findsOneWidget);

      // icon: Icons.summarize_outlined
      expect(find.byIcon(Icons.summarize_outlined), findsOneWidget);

      // title: settingsMedReport = "用药报告"
      expect(find.text('用药报告'), findsOneWidget);

      // subtitle: settingsMedReportSubtitle = "选时间窗口（7／14／30 天），给医生看"
      expect(find.text('选时间窗口（7／14／30 天），给医生看'), findsOneWidget);
    },
  );

  // ============================================================
  // 2. onTap → ChooseWindowDialog (3 个 RadioListTile 选项)
  // ============================================================
  testWidgets(
    '2) onTap → ChooseWindowDialog 弹 Dialog (3 RadioListTile: 7/14/30 天)',
    (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // tap AppListTile → ChooseWindowDialog
      await tester.tap(find.byType(AppListTile));
      await tester.pumpAndSettle();

      // AlertDialog 出现 (ChooseWindowDialog 内部走 AlertDialog)
      expect(find.byType(AlertDialog), findsOneWidget);

      // ChooseWindowDialog title (settingsMedReportChooseTitle = "选择时间窗口")
      expect(find.text('选择时间窗口'), findsOneWidget);

      // 3 RadioListTile (7/14/30 天)
      expect(
        find.byType(RadioListTile<int>),
        findsNWidgets(3),
        reason: 'ChooseWindowDialog 应有 3 个 RadioListTile 选项 (7/14/30 天)',
      );
    },
  );

  // ============================================================
  // 3. onShow callback 注入 — 跳过完整链路
  // ============================================================
  testWidgets(
    '3) onShow 回调: 注入时 onTap 调回调, 不走 _chooseAndShowReport',
    (tester) async {
      _setBigView(tester);
      int callCount = 0;
      await tester.pumpWidget(
        _wrap(
          onShow: () async {
            callCount++;
          },
        ),
      );
      await tester.pumpAndSettle();

      // tap AppListTile
      await tester.tap(find.byType(AppListTile));
      await tester.pumpAndSettle();

      // 验证: onShow 被调用 1 次
      expect(callCount, 1, reason: 'onShow 回调应被调用 1 次');

      // 验证: 没有 ChooseWindowDialog AlertDialog (跳过完整链路)
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: 'onShow 模式下, 不应弹 ChooseWindowDialog',
      );
    },
  );
}
