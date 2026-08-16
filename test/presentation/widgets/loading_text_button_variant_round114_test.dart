// R114 Wave C (P3-CLEAN-10): LoadingTextButton spinner 色按 variant 语义映射
//
// 修前: _ChildStack spinner 硬编码 AppTokens.fgOnPrimary (白) —
// outlined/text/tonal 浅底 + isLoading 时白 spinner 不可见 (潜伏,
// 当时 isLoading caller 恰好都是 filled)。
//
// 修后: filled → onPrimary / tonal → onSecondaryContainer /
// outlined & text → primary (跟各 variant 正常态 foreground 一致)。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/widgets/loading_text_button.dart';

Future<void> _pump(
    WidgetTester tester, LoadingTextButtonVariant variant) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LoadingTextButton(
          label: '保存',
          isLoading: true,
          onPressed: () {},
          variant: variant,
        ),
      ),
    ),
  );
  // 不用 pumpAndSettle: LoadingSpinner 内部是 1.2s 永久循环
  await tester.pump();
}

Color _spinnerColor(WidgetTester tester) {
  final spinner = tester.widget<CircularProgressIndicator>(
    find.byType(CircularProgressIndicator),
  );
  return spinner.valueColor!.value!;
}

void main() {
  testWidgets('filled + loading → spinner = onPrimary', (tester) async {
    await _pump(tester, LoadingTextButtonVariant.filled);
    final theme = Theme.of(tester.element(find.byType(LoadingTextButton)));
    expect(_spinnerColor(tester), theme.colorScheme.onPrimary);
  });

  testWidgets('tonal + loading → spinner = onSecondaryContainer',
      (tester) async {
    await _pump(tester, LoadingTextButtonVariant.tonal);
    final theme = Theme.of(tester.element(find.byType(LoadingTextButton)));
    expect(_spinnerColor(tester), theme.colorScheme.onSecondaryContainer);
  });

  testWidgets('outlined + loading → spinner = primary (修前白 spinner 不可见)',
      (tester) async {
    await _pump(tester, LoadingTextButtonVariant.outlined);
    final theme = Theme.of(tester.element(find.byType(LoadingTextButton)));
    expect(_spinnerColor(tester), theme.colorScheme.primary);
  });

  testWidgets('text + loading → spinner = primary', (tester) async {
    await _pump(tester, LoadingTextButtonVariant.text);
    final theme = Theme.of(tester.element(find.byType(LoadingTextButton)));
    expect(_spinnerColor(tester), theme.colorScheme.primary);
  });
}
