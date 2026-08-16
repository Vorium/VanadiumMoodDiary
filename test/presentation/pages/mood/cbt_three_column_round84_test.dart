// v0.29 round 84 (CBT 思维记录): CbtThreeColumnMode widget 测试
//
// 覆盖: 3 栏 mode 渲染 situation + automaticThought 两个 section
//
// v1.1.0 R114 (Wave D, spec §5.5): score 段移出到 mood_recorder_page
// 情绪评分组 (5 档 72pt 圆形 MoodScoreButtons), 本 widget 只剩 2 section
// — 原 Slider 断言移除。
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
  testWidgets('3 栏 mode 显示 situation + automaticThought 两个 section',
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
    expect(find.text('发生了什么？'), findsOneWidget);
    expect(find.text('那一刻脑海里闪过什么想法？'), findsOneWidget);
  });
}
