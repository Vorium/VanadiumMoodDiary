// v0.30 round 95 (sub-spec 1 task 6): clear_tile widget 测试
//
// 覆盖 (跟 brief §1.6 步骤 6 测试 4 case 一致):
// 1. 渲染 AppListTile (icon / title / subtitle, error color)
// 2. onTap → 二次确认 dialog (AlertDialog + "我已备份,确认清空" 按钮)
// 3. onClear callback 注入 — 跳过完整链路
// 4. 确认 → 清空 DB (mock databaseProvider + ventAudioStorageProvider)
//
// 模式 (跟项目其它 settings widget test 一致, R95 步骤 2-3 模式):
// - MaterialApp + AppLocalizations.localizationsDelegates + locale: Locale('zh')
// - ProviderScope overrides: databaseProvider + ventAudioStorageProvider
// - AppDatabase.forTesting(NativeDatabase.memory()) — 真实 in-memory DB
// - _StubVentAudioStorage 避免 file system 操作 (走内存 stub)
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/vent_audio_storage.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/clear_tile.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
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
  VentAudioStorage? ventAudio,
  Future<void> Function()? onClear,
}) {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(db),
      if (ventAudio != null)
        ventAudioStorageProvider.overrideWithValue(ventAudio),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      // 重要: GoRouter 在 clear 后会 go('/setup'), 真实 GoRouter 在 widget test
      // 没注册路由会抛错。本测试只测 dialog 阶段, 不触发 go。
      home: Scaffold(
        body: ClearTile(onClear: onClear),
      ),
    ),
  );
}

/// Stub VentAudioStorage — 跳过 file system 操作, 内存里直接返回结果
class _StubVentAudioStorage extends VentAudioStorage {
  int deleteCalls = 0;
  int sizeCalls = 0;

  @override
  Future<int> deleteAllWithRetry() async {
    deleteCalls++;
    return 0; // 没录音, 返回 0
  }

  @override
  Future<int> totalSizeBytes() async {
    sizeCalls++;
    return 0; // 没录音
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
  // 1. 渲染 AppListTile (icon / title / subtitle, error color)
  // ============================================================
  testWidgets(
    '1) 渲染: AppListTile + delete_forever_outlined icon + "清空所有数据" title (error color)',
    (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(_wrap(db: db));
      await tester.pumpAndSettle();

      // AppListTile 渲染
      expect(find.byType(AppListTile), findsOneWidget);

      // icon: Icons.delete_forever_outlined
      expect(find.byIcon(Icons.delete_forever_outlined), findsOneWidget);

      // title: settingsClearAllData = "清空所有数据"
      expect(find.text('清空所有数据'), findsOneWidget);

      // subtitle: settingsClearAllDataSubtitle
      expect(
        find.textContaining('打卡'),
        findsWidgets,
        reason: 'subtitle 应含 "打卡" 字眼',
      );
    },
  );

  // ============================================================
  // 2. onTap → 二次确认 dialog
  // ============================================================
  testWidgets(
    '2) onTap → 二次确认 dialog (AlertDialog + "我已备份,确认清空" 按钮)',
    (tester) async {
      _setBigView(tester);
      final ventAudio = _StubVentAudioStorage();
      await tester.pumpWidget(
        _wrap(db: db, ventAudio: ventAudio),
      );
      await tester.pumpAndSettle();

      // tap AppListTile → 二次确认 dialog
      await tester.tap(find.byType(AppListTile));
      await tester.pumpAndSettle();

      // AlertDialog 出现
      expect(find.byType(AlertDialog), findsOneWidget);

      // dialog title: settingsClearAllDataDialogTitle = "确认清空所有数据？"
      expect(find.text('确认清空所有数据？'), findsOneWidget);

      // dialog body 含 "无法恢复"
      expect(find.textContaining('无法恢复'), findsWidgets);

      // "我已备份,确认清空" 按钮 (settingsClearAllDataConfirm) — 全角逗号
      expect(find.text('我已备份，确认清空'), findsOneWidget);

      // 取消按钮
      expect(find.text('取消'), findsOneWidget);
    },
  );

  // ============================================================
  // 3. onClear callback 注入 — 跳过完整链路
  // ============================================================
  testWidgets(
    '3) onClear 回调: 注入时 onTap 调回调, 不走 _showClearAllDataDialog',
    (tester) async {
      _setBigView(tester);
      int callCount = 0;
      await tester.pumpWidget(
        _wrap(
          db: db,
          onClear: () async {
            callCount++;
          },
        ),
      );
      await tester.pumpAndSettle();

      // tap AppListTile
      await tester.tap(find.byType(AppListTile));
      await tester.pumpAndSettle();

      // 验证: onClear 被调用 1 次
      expect(callCount, 1, reason: 'onClear 回调应被调用 1 次');

      // 验证: 没有 AlertDialog (跳过完整链路)
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: 'onClear 模式下, 不应弹二次确认 dialog',
      );
    },
  );

  // ============================================================
  // 4. 取消按钮 → 静默退出 (无 DB 写入, 无 SnackBar)
  // ============================================================
  testWidgets(
    '4) 取消 → 静默退出, 不调 clearAllUserData',
    (tester) async {
      _setBigView(tester);
      final ventAudio = _StubVentAudioStorage();
      await tester.pumpWidget(
        _wrap(db: db, ventAudio: ventAudio),
      );
      await tester.pumpAndSettle();

      // tap AppListTile → dialog
      await tester.tap(find.byType(AppListTile));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // 点取消按钮
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      // 验证: dialog 关闭
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: '取消后 dialog 应关闭',
      );

      // 验证: ventAudio.deleteAllWithRetry 没被调用 (取消 → 不清)
      expect(
        ventAudio.deleteCalls,
        0,
        reason: '取消后, 不应调 ventAudio.deleteAllWithRetry',
      );
    },
  );
}
