// v0.27 round 65 (flutter L10 ElevatedButton 迁移): PrimaryButton 集中器测试
//
// 验证:
// 1. isFullWidth=true (默认) 时包 SizedBox(width: double.infinity)
// 2. isFullWidth=false 时直传 FilledButton (用于 dialog / row)
// 3. onPressed 触发回调
// 4. onPressed=null 时按钮 disabled
// 5. child 透传

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap({required Widget child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('R65-PB-1: 默认 (isFullWidth=true) 包 SizedBox 全宽', (tester) async {
    await tester.pumpWidget(
      wrap(
        child: PrimaryButton(
          onPressed: () {},
          child: const Text('立即升级'),
        ),
      ),
    );

    // 找 SizedBox(width: double.infinity) wrapper
    final sizedBox = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(SizedBox),
      ),
    );
    expect(sizedBox.width, double.infinity);

    // 里面包了 FilledButton
    expect(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );
  });

  testWidgets('R65-PB-2: isFullWidth=false 直传 FilledButton, 不包 SizedBox',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        child: PrimaryButton(
          isFullWidth: false,
          onPressed: () {},
          child: const Text('确定'),
        ),
      ),
    );

    // 不应包 SizedBox(width: double.infinity)
    expect(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(SizedBox),
      ),
      findsNothing,
    );

    // 仍然是 FilledButton
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('R65-PB-3: tap → onPressed 触发 + 透传 child', (tester) async {
    int tapCount = 0;
    await tester.pumpWidget(
      wrap(
        child: PrimaryButton(
          onPressed: () => tapCount++,
          child: const Text('tap me'),
        ),
      ),
    );

    // child 透传
    expect(find.text('tap me'), findsOneWidget);

    // 点击
    await tester.tap(find.byType(PrimaryButton));
    await tester.pump();
    expect(tapCount, 1, reason: 'onPressed 应该被调用 1 次');
  });

  testWidgets('R65-PB-4: onPressed=null → FilledButton disabled',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        child: const PrimaryButton(
          onPressed: null,
          child: Text('disabled'),
        ),
      ),
    );

    final filled = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(
      filled.onPressed,
      isNull,
      reason: 'onPressed=null 应透传给 FilledButton (disabled)',
    );
  });
}
