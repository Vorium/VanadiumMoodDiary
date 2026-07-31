// v0.27 round 67 (C-3 重构): DialogActionsRow 集中器测试
//
// 验证 4 个 dialog caller 抽到 DialogActionsRow 集中器后行为完全一致:
// - cancel TextButton 正常态
// - confirm LoadingTextButton 正常态
// - isLoading=true 时 cancel + confirm 都 disabled
// - onCancel / onConfirm null 时按钮 disabled

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/widgets/dialog_actions_row.dart';

void main() {
  group('DialogActionsRow (R67 C-3)', () {
    testWidgets('1. cancel + confirm 按钮都渲染 + 文字正确', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogActionsRow(
              cancelLabel: '取消',
              onCancel: () {},
              confirmLabel: '保存',
              onConfirm: () {},
            ),
          ),
        ),
      );
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('保存'), findsOneWidget);
    });

    testWidgets(
        '2. isLoading=true: cancel + confirm 都 disabled (onPressed=null)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogActionsRow(
              cancelLabel: '取消',
              onCancel: () {},
              confirmLabel: '保存',
              onConfirm: () {},
              isLoading: true,
            ),
          ),
        ),
      );
      // TextButton onPressed: null when isLoading
      final cancelButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '取消'),
      );
      expect(cancelButton.onPressed, isNull);
      // LoadingTextButton 显示 spinner (icon stack 覆盖 text) — 这里只验 onPressed: null
      final filledButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '保存'),
      );
      expect(filledButton.onPressed, isNull);
    });

    testWidgets('3. onCancel=null: cancel 按钮 disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogActionsRow(
              cancelLabel: '取消',
              // onCancel: null = disabled
              confirmLabel: '保存',
              onConfirm: () {},
            ),
          ),
        ),
      );
      final cancelButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '取消'),
      );
      expect(cancelButton.onPressed, isNull);
    });

    testWidgets('4. onConfirm=null: confirm 按钮 disabled (不依赖 isLoading)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DialogActionsRow(
              cancelLabel: '取消',
              onCancel: () {},
              confirmLabel: '保存',
              // onConfirm: null = disabled
            ),
          ),
        ),
      );
      final filledButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '保存'),
      );
      expect(filledButton.onPressed, isNull);
    });
  });
}
