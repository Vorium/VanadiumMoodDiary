// v0.30 round 95 (sub-spec 1 task 2b): export_tile widget 测试
//
// 覆盖 (跟 brief §1.2 步骤 2 测试 5 case 一致):
// 1. 渲染 AppListTile (icon / title / subtitle)
// 2. onTap 触发 ConsentDialog (PIPL §13 单独同意)
// 3. 同意 → JSON 弹窗 (Q4b 明文风险 + 复制按钮 disabled 需勾选)
// 4. 不同意 → 静默退出 (dialog 消失, 没有 export dialog 出现)
// 5. audit log 失败 → swallowError (legalConsentStoreProvider 抛异常, 主流程继续)
//
// 模式 (跟项目其它 settings widget test 一致, R84 cbt_thought_record_flow_round84_test):
// - MaterialApp + AppLocalizations.localizationsDelegates + locale: Locale('zh')
// - ProviderScope overrides: databaseProvider + dataExportServiceProvider + legalConsentStoreProvider
// - AppDatabase.forTesting(NativeDatabase.memory()) — 真实 in-memory DB, 走 drift round-trip
// - _StubDataExportService 覆盖 exportToJson, 跳过 5s timeout (生产 export_orchestrator 内部
//   5s 防止 drift stream hang, 测试里用 stub 加速)
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/data_export_service.dart';
import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/export_tile.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';
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
  LegalConsentStore? consentStore,
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      if (exportService != null)
        dataExportServiceProvider.overrideWithValue(exportService),
      if (consentStore != null)
        legalConsentStoreProvider.overrideWithValue(consentStore),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: const Scaffold(body: ExportTile()),
    ),
  );
}

/// Stub DataExportService — 跳过生产 5s timeout, 立即返回测试 JSON
///
/// R95 测试专用: 让 dialog 立即可见, 不让 export_orchestrator 内部 5s 定时器
/// 卡 widget test timer pending invariant。
class _StubDataExportService extends DataExportService {
  _StubDataExportService(super.db);

  @override
  Future<String> exportToJson({DateTime? now}) async {
    return '{"schemaVersion": 4, "stub": true}';
  }
}

/// 注入失败的 LegalConsentStore — 每次 recordDataExportConsent 抛异常
///
/// R95 测试专用: 验证 audit log 失败时主流程继续 (走 swallowError 集中器)
class _FailingLegalConsentStore extends LegalConsentStore {
  int recordCalls = 0;

  @override
  Future<void> recordDataExportConsent(ConsentArtifact artifact) async {
    recordCalls++;
    throw StateError('simulated audit log failure (R95 test)');
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
    '1) 渲染: AppListTile + upload icon + "导出全部数据" title + subtitle',
    (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(_wrap(db: db));
      await tester.pumpAndSettle();

      // AppListTile 渲染
      expect(find.byType(AppListTile), findsOneWidget);

      // icon: Icons.upload_outlined
      expect(find.byIcon(Icons.upload_outlined), findsOneWidget);

      // title: settingsExportData = "导出数据"
      expect(find.text('导出数据'), findsOneWidget);

      // subtitle: settingsExportSubtitle = "生成 JSON，复制到安全地方"
      expect(find.text('生成 JSON，复制到安全地方'), findsOneWidget);
    },
  );

  // ============================================================
  // 2. onTap 触发 ConsentDialog (PIPL §13 单独同意)
  // ============================================================
  testWidgets(
    '2) onTap → 弹 ConsentDialog (PIPL §13 单独同意, AlertDialog 显示)',
    (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(_wrap(db: db));
      await tester.pumpAndSettle();

      // tap AppListTile
      await tester.tap(find.byType(AppListTile));
      await tester.pumpAndSettle();

      // AlertDialog 出现 (ConsentDialog.show 内部走 showDialog + AlertDialog)
      expect(find.byType(AlertDialog), findsOneWidget);

      // ConsentDialog 模板 (dataExport) title 是 "数据导出同意"
      // 跟 settingsExportData 不同 — 这是 ConsentDialog 模板的 title
      expect(find.text('数据导出同意'), findsOneWidget,
          reason: 'ConsentDialog (dataExport 模板) title 应出现');
    },
  );

  // ============================================================
  // 3. 同意 → JSON 弹窗 (PIPL §17 告知 + 强制勾选)
  // ============================================================
  testWidgets(
    '3) 同意 ConsentDialog → JSON 弹窗 (Q4b 明文风险 + 复制按钮 disabled 需勾选)',
    (tester) async {
      _setBigView(tester);
      final exportService = _StubDataExportService(db);
      await tester.pumpWidget(
        _wrap(db: db, exportService: exportService),
      );
      await tester.pumpAndSettle();

      // tap AppListTile → ConsentDialog
      await tester.tap(find.byType(AppListTile));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: '第一步: ConsentDialog 应弹出');

      // 找 ConsentDialog 里的 "我了解并同意导出" 按钮 (dataExportConfirm)
      final agreeButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, '我了解并同意导出'),
      );
      expect(agreeButton, findsOneWidget);

      // 点同意
      await tester.tap(agreeButton);
      await tester.pumpAndSettle();

      // Q4b: 风险卡 (settingsExportRiskTitle = "明文风险提示") — JSON dialog 独有
      expect(find.text('明文风险提示'), findsOneWidget,
          reason: '同意后 JSON 弹窗应显示 Q4b 风险卡');

      // Q4b: 强制勾选 checkbox (settingsExportRiskAcknowledge = "我已了解风险,继续导出")
      expect(find.text('我已了解风险,继续导出'), findsOneWidget);

      // 复制按钮 (settingsCopy = "复制") — 应存在但未勾选前 disabled
      final copyBtnFinder = find.widgetWithText(ElevatedButton, '复制');
      expect(copyBtnFinder, findsOneWidget);
      final copyBtn = tester.widget<ElevatedButton>(copyBtnFinder);
      expect(copyBtn.onPressed, isNull,
          reason: 'Q4b: 未勾选时复制按钮应 disabled');
    },
  );

  // ============================================================
  // 4. 不同意 → 静默退出 (无 JSON 弹窗)
  // ============================================================
  testWidgets(
    '4) 不同意 ConsentDialog → 静默退出, 不弹 JSON 弹窗',
    (tester) async {
      _setBigView(tester);
      final exportService = _StubDataExportService(db);
      await tester.pumpWidget(
        _wrap(db: db, exportService: exportService),
      );
      await tester.pumpAndSettle();

      // tap AppListTile → ConsentDialog
      await tester.tap(find.byType(AppListTile));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: '第一步: ConsentDialog 应弹出');

      // 找 "暂不同意" 按钮 (dataExportRejectLabel)
      final rejectButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(TextButton, '暂不同意'),
      );
      expect(rejectButton, findsOneWidget);

      // 点拒绝
      await tester.tap(rejectButton);
      await tester.pumpAndSettle();

      // 没有 JSON 弹窗 (settingsExportDialogTitle "导出数据" 不应在屏)
      // 注: "导出数据" 跟 ConsentDialog 模板无关, 只在 JSON dialog 出现
      // 验证: 没有 "明文风险提示" 风险卡
      expect(find.text('明文风险提示'), findsNothing,
          reason: '不同意后, JSON 弹窗不应出现');
    },
  );

  // ============================================================
  // 5. audit log 失败 → swallowError (主流程继续)
  // ============================================================
  testWidgets(
    '5) audit log 失败 (recordDataExportConsent 抛异常) → 主流程继续, JSON 弹窗仍弹出',
    (tester) async {
      _setBigView(tester);
      final exportService = _StubDataExportService(db);
      // 注入失败的 legalConsentStore — recordDataExportConsent 抛异常
      final failingConsentStore = _FailingLegalConsentStore();
      await tester.pumpWidget(
        _wrap(
          db: db,
          exportService: exportService,
          consentStore: failingConsentStore,
        ),
      );
      await tester.pumpAndSettle();

      // tap AppListTile → ConsentDialog → 同意
      await tester.tap(find.byType(AppListTile));
      await tester.pumpAndSettle();

      final agreeButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, '我了解并同意导出'),
      );
      await tester.tap(agreeButton);
      await tester.pumpAndSettle();

      // 验证: JSON 弹窗仍然出现 (主流程没被 audit log 失败阻塞)
      // 用 Q4b 风险卡 (settingsExportRiskTitle = "明文风险提示") — JSON dialog 独有
      expect(find.text('明文风险提示'), findsOneWidget,
          reason: 'audit log 失败不应阻塞主流程, JSON 弹窗仍应弹出');

      // 验证: audit log 被调用过
      expect(failingConsentStore.recordCalls, 1,
          reason: 'recordDataExportConsent 应被调用 1 次');
    },
  );
}
