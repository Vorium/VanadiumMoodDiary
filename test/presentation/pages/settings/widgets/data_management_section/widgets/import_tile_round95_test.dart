// v0.30 round 95 (sub-spec 1 task 5): import_tile widget 测试
//
// 覆盖 (跟 brief §1.5 步骤 5 测试 4 case 一致):
// 1. 渲染 AppListTile (icon / title / subtitle)
// 2. onTap → 风险告知 dialog (settingsImportWarning 含 ⚠️)
// 3. onImport callback 注入 — 跳过完整链路
// 4. 完整 import 链路 (dataExportServiceProvider override 注入成功结果)
//
// 模式 (跟项目其它 settings widget test 一致, R95 步骤 2-3 模式):
// - MaterialApp + AppLocalizations.localizationsDelegates + locale: Locale('zh')
// - ProviderScope overrides: databaseProvider + dataExportServiceProvider
// - AppDatabase.forTesting(NativeDatabase.memory()) — 真实 in-memory DB
// - 完整 import 链路 (test 4): _StubImportOkService 注入成功结果
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/data_export_service.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/import_tile.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void _setBigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrap({
  required AppDatabase db,
  DataExportService? exportService,
  Future<void> Function()? onImport,
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      if (exportService != null)
        dataExportServiceProvider.overrideWithValue(exportService),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: ImportTile(onImport: onImport),
      ),
    ),
  );
}

/// Stub DataExportService — 注入成功结果 (test 4 走完整 import 链路)
class _StubImportOkService extends DataExportService {
  _StubImportOkService(super.db);

  @override
  Future<ImportResult> importFromJson(String json) async {
    return const ImportResult(
      success: true,
      medicationCount: 1,
      checkInCount: 7,
      reportHistoryCount: 0,
      moodEntryCount: 0,
      ventEntryCount: 0,
    );
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // ============================================================
  // 1. 渲染 AppListTile (icon / title / subtitle)
  // ============================================================
  testWidgets(
    '1) 渲染: AppListTile + download_outlined icon + "导入数据" title + subtitle',
    (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(_wrap(db: db));
      await tester.pumpAndSettle();

      // AppListTile 渲染
      expect(find.byType(AppListTile), findsOneWidget);

      // icon: Icons.download_outlined
      expect(find.byIcon(Icons.download_outlined), findsOneWidget);

      // title: settingsImportData = "导入数据"
      expect(find.text('导入数据'), findsOneWidget);

      // subtitle: settingsImportSubtitle = "从 JSON 恢复（覆盖现有数据）"
      expect(find.text('从 JSON 恢复（覆盖现有数据）'), findsOneWidget);
    },
  );

  // ============================================================
  // 2. onTap → 风险告知 dialog (settingsImportWarning 含 ⚠️)
  // ============================================================
  testWidgets(
    '2) onTap → 风险告知 dialog (AlertDialog + TextField + 导入覆盖按钮)',
    (tester) async {
      _setBigView(tester);
      final importService = _StubImportOkService(db);
      await tester.pumpWidget(
        _wrap(db: db, exportService: importService),
      );
      await tester.pumpAndSettle();

      // tap AppListTile → 风险告知 dialog
      await tester.tap(find.byType(AppListTile));
      await tester.pumpAndSettle();

      // AlertDialog 出现
      expect(find.byType(AlertDialog), findsOneWidget);

      // 风险告知: settingsImportWarning 含 ⚠️
      expect(
        find.textContaining('⚠️'),
        findsWidgets,
        reason: '风险告知应出现 ⚠️ 警告',
      );

      // settingsImportWarning = "⚠️ 会覆盖现有所有数据，确定后再继续"
      expect(
        find.text('⚠️ 会覆盖现有所有数据，确定后再继续'),
        findsOneWidget,
      );

      // 提示文字: settingsImportHint
      expect(
        find.text('把导出的 JSON 粘贴到这里'),
        findsOneWidget,
      );

      // 导入覆盖按钮: settingsImportAndOverwrite = "导入并覆盖"
      expect(find.text('导入并覆盖'), findsOneWidget);

      // 取消按钮: commonCancel = "取消"
      expect(find.text('取消'), findsOneWidget);
    },
  );

  // ============================================================
  // 3. onImport callback 注入 — 跳过完整链路
  // ============================================================
  testWidgets(
    '3) onImport 回调: 注入时 onTap 调回调, 不走 _showImportDialog',
    (tester) async {
      _setBigView(tester);
      int callCount = 0;
      await tester.pumpWidget(
        _wrap(
          db: db,
          onImport: () async {
            callCount++;
          },
        ),
      );
      await tester.pumpAndSettle();

      // tap AppListTile
      await tester.tap(find.byType(AppListTile));
      await tester.pumpAndSettle();

      // 验证: onImport 被调用 1 次
      expect(callCount, 1, reason: 'onImport 回调应被调用 1 次');

      // 验证: 没有 AlertDialog (跳过完整链路)
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: 'onImport 模式下, 不应弹 import dialog',
      );
    },
  );

  // ============================================================
  // 4. 完整 import 链路 (dataExportServiceProvider override 注入成功结果)
  // ============================================================
  testWidgets(
    '4) 完整链路: TextField 输入 → 导入覆盖 → dialog 关闭 + AppSnackBar',
    (tester) async {
      _setBigView(tester);
      final importService = _StubImportOkService(db);
      await tester.pumpWidget(
        _wrap(db: db, exportService: importService),
      );
      await tester.pumpAndSettle();

      // tap AppListTile → dialog
      await tester.tap(find.byType(AppListTile));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // 找 TextField + 输入 JSON
      await tester.enterText(
        find.byType(TextField),
        '{"schemaVersion": 4, "stub": true}',
      );
      await tester.pumpAndSettle();

      // 点 "导入并覆盖" 按钮
      await tester.tap(find.text('导入并覆盖'));
      await tester.pumpAndSettle();

      // 验证: dialog 关闭 (AlertDialog 消失)
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: '成功导入后, dialog 应关闭',
      );

      // 验证: AppSnackBar 显示导入成功 (含 summary)
      // settingsImportSuccess = "导入完成：{summary}" → 含 "导入完成："
      expect(
        find.textContaining('导入完成：'),
        findsOneWidget,
        reason: '成功导入后, AppSnackBar 应显示导入完成 summary',
      );
    },
  );
}
