// v0.17 round 14 (P1-7): AppSnackBar widget test
//
// 覆盖:
// 1. error() 返回 SnackBar, content 用 zh ARB 模板 (action + error)
// 2. info() 返回 SnackBar, content 跟传入一致
// 3. duration 区别: error 4s, info 2s

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';

Future<void> _pumpWithL10n(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('zh'),
      home: Scaffold(body: SizedBox.shrink()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AppSnackBar.error', () {
    testWidgets('returns SnackBar with action+error template', (tester) async {
      await _pumpWithL10n(tester);
      final ctx = tester.element(find.byType(Scaffold));
      final bar = AppSnackBar.error(ctx, action: '保存', error: '网络异常');
      expect(bar, isA<SnackBar>());
      final text = (bar.content as Text).data;
      expect(text, '保存失败：网络异常');
    });

    testWidgets('uses 4s duration', (tester) async {
      await _pumpWithL10n(tester);
      final ctx = tester.element(find.byType(Scaffold));
      final bar = AppSnackBar.error(ctx, action: '删除', error: 'x');
      expect(bar.duration, const Duration(seconds: 4));
    });

    testWidgets('null error → "unknown" placeholder', (tester) async {
      await _pumpWithL10n(tester);
      final ctx = tester.element(find.byType(Scaffold));
      final bar = AppSnackBar.error(ctx, action: '导出');
      final text = (bar.content as Text).data;
      expect(text, '导出失败：unknown');
    });
  });

  group('AppSnackBar.info', () {
    testWidgets('returns SnackBar with given message', (tester) async {
      await _pumpWithL10n(tester);
      final ctx = tester.element(find.byType(Scaffold));
      final bar = AppSnackBar.info(ctx, '已复制到剪贴板');
      expect(bar, isA<SnackBar>());
      expect((bar.content as Text).data, '已复制到剪贴板');
    });

    testWidgets('uses 2s duration', (tester) async {
      await _pumpWithL10n(tester);
      final ctx = tester.element(find.byType(Scaffold));
      final bar = AppSnackBar.info(ctx, 'hello');
      expect(bar.duration, const Duration(seconds: 2));
    });
  });
}
