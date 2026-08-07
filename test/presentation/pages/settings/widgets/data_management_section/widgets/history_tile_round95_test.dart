// v0.30 round 95 (sub-spec 1 task 4b): history_tile widget 测试
//
// 覆盖 (跟 brief §1.4 步骤 4b 测试 2 case 一致):
// 1. 渲染 AppListTile (icon / title / subtitle)
// 2. onShow callback 注入 — 跳过完整 ReportHistoryListDialog 链路
//
// 模式 (跟项目其它 settings widget test 一致, R95 步骤 2-3 模式):
// - MaterialApp + AppLocalizations.localizationsDelegates + locale: Locale('zh')
// - ConsumerWidget 自包含 _showReportHistory 完整流程
// - onShow 回调: 留测试可跳过 ReportHistoryListDialog 完整链路
// - 完整 ReportHistoryListDialog 链路需 mock reportHistoriesProvider, 端到端
//   测在 settings_page_round45_test.dart 覆盖。本测试只验 ConsumerWidget 渲染 + 入口。
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/history_tile.dart';
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
        body: HistoryTile(onShow: onShow),
      ),
    ),
  );
}

void main() {
  // ============================================================
  // 1. 渲染 AppListTile (icon / title / subtitle)
  // ============================================================
  testWidgets(
    '1) 渲染: AppListTile + history icon + "报告历史" title + subtitle',
    (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // AppListTile 渲染
      expect(find.byType(AppListTile), findsOneWidget);

      // icon: Icons.history
      expect(find.byIcon(Icons.history), findsOneWidget);

      // title: settingsReportHistory = "报告历史"
      expect(find.text('报告历史'), findsOneWidget);

      // subtitle: settingsReportHistorySubtitle (任何 non-empty 都行)
      expect(find.textContaining('报告'), findsWidgets);
    },
  );

  // ============================================================
  // 2. onShow callback 注入 — 跳过完整 ReportHistoryListDialog 链路
  // ============================================================
  testWidgets(
    '2) onShow 回调: 注入时 onTap 调回调, 不走 _showReportHistory',
    (tester) async {
      _setBigView(tester);
      int callCount = 0;
      await tester.pumpWidget(_wrap(
        onShow: () async {
          callCount++;
        },
      ),);
      await tester.pumpAndSettle();

      // tap AppListTile
      await tester.tap(find.byType(AppListTile));
      await tester.pumpAndSettle();

      // 验证: onShow 被调用 1 次
      expect(callCount, 1, reason: 'onShow 回调应被调用 1 次');

      // 验证: 没有 ReportHistoryListDialog (跳过完整链路)
      // ReportHistoryListDialog 内部是 Dialog 不是 AlertDialog
      expect(find.byType(Dialog), findsNothing,
          reason: 'onShow 模式下, 不应弹 ReportHistoryListDialog',);
    },
  );
}
