// v0.29 round 84 (CBT 思维记录): CbtThreeColumnMode widget 测试
//
// 覆盖: 3 栏 mode 渲染 score + situation + automaticThought 三个 section
//
// 模式: 跟 R84 cbt_widgets_round84_test 同款 — ProviderScope + MaterialApp +
// tester.pumpAndSettle
//
// 注: 不在 build 内调 setLevel (Riverpod 禁止 build 期间改 provider) —
// CbtThreeColumnMode 本就只渲染 3 栏 mode (走 cbtDraftProvider 默认 level=three)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_three_column_mode.dart';

void main() {
  testWidgets('3 栏 mode 显示 score + situation + automaticThought 三个 section',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: Scaffold(
            body: CbtThreeColumnMode(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('你现在的感受？'), findsOneWidget);
    expect(find.text('发生了什么？'), findsOneWidget);
    expect(find.text('那一刻脑海里闪过什么想法？'), findsOneWidget);
    // v0.30 R101: ChoiceChip 改为 Slider + emoji, 断言 Slider 存在
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('😢'), findsOneWidget);
    expect(find.text('😄'), findsOneWidget);
  });
}
