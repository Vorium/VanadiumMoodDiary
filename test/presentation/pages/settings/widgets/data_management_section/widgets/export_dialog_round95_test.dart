// v0.30 round 95 (sub-spec 1 task 6.5): export_dialog widget 测试
// v0.30 R95 sub-spec 8 task 19: 5→3 步 — checkbox 默认勾选 + 不可取消,
// 复制按钮始终 enable (点 copy = 主动 ack 行为)
//
// 覆盖 (跟 brief §1.6.5 步骤 6.5 测试 3 case 一致):
// 1. 渲染 JSON (mock json string) — checkbox 默认勾选, 复制按钮 enable
// 2. 点复制按钮 → onCopy 回调 (无需手动勾选)
// 3. 关闭按钮 → 静默退出
//
// 模式 (跟项目其它 settings widget test 一致):
// - MaterialApp + AppLocalizations.localizationsDelegates + locale: Locale('zh')
// - ExportDialog 直接构造 widget (不走 ExportTile → ConsentDialog → export 流程)
// - onCopy 回调: 留测试可跳过真实 Clipboard.setData (避免 test 环境读写剪贴板)
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/export_dialog.dart';
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

const _mockJson =
    '{"schemaVersion": 4, "stub": true, "data": "R95 export_dialog test"}';

Widget _wrap({Future<void> Function(String json)? onCopy}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () =>
                  ExportDialog.show(ctx, json: _mockJson, onCopy: onCopy),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  // ============================================================
  // 1. 渲染 JSON (mock json string) — task 19: checkbox 默认勾选, 复制 enable
  // ============================================================
  testWidgets(
    '1) 渲染: Q4b 风险卡 + 强制勾选 checkbox (默认勾选) + JSON 容器 (mock json)',
    (tester) async {
      _setBigView(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // 点 "open" 弹 ExportDialog
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // AlertDialog 出现
      expect(find.byType(AlertDialog), findsOneWidget);

      // Q4b 风险卡 (settingsExportRiskTitle = "明文风险提示")
      expect(find.text('明文风险提示'), findsOneWidget);

      // Q4b 强制勾选 checkbox (settingsExportRiskAcknowledge = "我已了解风险，继续导出")
      expect(find.text('我已了解风险，继续导出'), findsOneWidget);

      // JSON 容器渲染 (SelectableText 含 mock json)
      expect(
        find.textContaining('R95 export_dialog test'),
        findsOneWidget,
        reason: 'SelectableText 应渲染 mock json 字符串',
      );

      // v0.30 R95 sub-spec 8 task 19: 5→3 步 — checkbox 默认勾选, 复制按钮
      // 始终 enable (用户点 copy = 主动 ack 行为, Q4b 责任划界走风险告知文字)
      final copyBtnFinder = find.widgetWithText(FilledButton, '复制');
      expect(copyBtnFinder, findsOneWidget);
      final copyBtn = tester.widget<FilledButton>(copyBtnFinder);
      expect(
        copyBtn.onPressed,
        isNotNull,
        reason: 'task 19: 默认勾选后复制按钮应 enable (点 copy = 主动 ack)',
      );
    },
  );

  // ============================================================
  // 2. 点复制按钮 → onCopy 回调 (无需手动勾选, task 19 简化流程)
  // ============================================================
  testWidgets(
    '2) 点复制按钮 → onCopy 回调 (task 19: 5→3 步, 无需手动勾选)',
    (tester) async {
      _setBigView(tester);
      int copyCallCount = 0;
      await tester.pumpWidget(
        _wrap(
          onCopy: (_) async {
            copyCallCount++;
          },
        ),
      );
      await tester.pumpAndSettle();

      // 弹 ExportDialog
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // v0.30 R95 sub-spec 8 task 19: checkbox 默认勾选, 复制按钮 enable
      final copyBtn = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '复制'),
      );
      expect(
        copyBtn.onPressed,
        isNotNull,
        reason: 'task 19: 默认勾选, 复制按钮 enable',
      );

      // 点复制 → 触发 onCopy 回调
      await tester.tap(find.widgetWithText(FilledButton, '复制'));
      await tester.pumpAndSettle();

      // 验证: onCopy 被调用 1 次
      expect(copyCallCount, 1, reason: 'onCopy 回调应被调用 1 次');
    },
  );

  // ============================================================
  // 3. 关闭按钮 (commonClose) → 静默退出
  // ============================================================
  testWidgets(
    '3) 关闭按钮 → 静默退出 (dialog 关闭, 不调 onCopy)',
    (tester) async {
      _setBigView(tester);
      int copyCallCount = 0;
      await tester.pumpWidget(
        _wrap(
          onCopy: (_) async {
            copyCallCount++;
          },
        ),
      );
      await tester.pumpAndSettle();

      // 弹 ExportDialog
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      // 点关闭按钮 (commonClose = "关闭")
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();

      // 验证: dialog 关闭
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: '关闭后 dialog 应消失',
      );

      // 验证: onCopy 没被调用
      expect(
        copyCallCount,
        0,
        reason: '关闭按钮不应触发 onCopy',
      );
    },
  );
}
