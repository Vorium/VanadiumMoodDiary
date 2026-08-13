// v0.32 R112-03: 影响因素 chip 选择器 i18n
//
// 背景: mood_influence_chips.dart:91 显示 domain 硬编码中文 (kInfluenceFactors),
// 且 onChanged 返回中文字面量 (DB 存中文)。
// 修复: chip label 走 kInfluenceFactorKeys ARB 派发, onChanged 返回 key
// (录入侧存 key), 选中状态按 key 匹配。
//
// 覆盖:
// 1. zh locale: 渲染本地化 label (家人等), 不出现 raw key 名
// 2. tap "家人" → onChanged 收到 ['influenceFactorFamily'] (key 非中文)
// 3. en locale: 显示英文 label
// 4. selected 传 key → chip 选中态正确 (选中检测走 key)

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/mood_influence_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap({
    required Locale locale,
    required List<String> selected,
    required ValueChanged<List<String>> onChanged,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(
        body: SingleChildScrollView(
          child: MoodInfluenceChips(selected: selected, onChanged: onChanged),
        ),
      ),
    );
  }

  testWidgets('1) zh locale 渲染本地化 label, 无 raw key', (tester) async {
    await tester.pumpWidget(
      wrap(locale: const Locale('zh'), selected: const [], onChanged: (_) {}),
    );
    await tester.pumpAndSettle();

    expect(find.text('家人'), findsOneWidget);
    expect(find.text('运动'), findsOneWidget);
    expect(find.text('晴天'), findsOneWidget);
    // 分类标题
    expect(find.text('关系'), findsOneWidget);
    expect(find.text('天气'), findsOneWidget);
    // 不显示 raw key 名
    expect(find.textContaining('influenceFactor'), findsNothing);
  });

  testWidgets('2) tap 家人 → onChanged 收到 key', (tester) async {
    List<String>? captured;
    await tester.pumpWidget(
      wrap(
        locale: const Locale('zh'),
        selected: const [],
        onChanged: (factors) => captured = factors,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('家人'));
    await tester.pumpAndSettle();

    expect(captured, ['influenceFactorFamily']);
  });

  testWidgets('3) en locale 显示英文 label', (tester) async {
    await tester.pumpWidget(
      wrap(locale: const Locale('en'), selected: const [], onChanged: (_) {}),
    );
    await tester.pumpAndSettle();

    expect(find.text('Family'), findsOneWidget);
    expect(find.text('Exercise'), findsOneWidget);
    expect(find.text('家人'), findsNothing);
  });

  testWidgets('4) selected 传 key → 选中态正确', (tester) async {
    await tester.pumpWidget(
      wrap(
        locale: const Locale('zh'),
        selected: const ['influenceFactorFamily'],
        onChanged: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    final chip = tester.widget<FilterChip>(
      find.ancestor(
        of: find.text('家人'),
        matching: find.byType(FilterChip),
      ),
    );
    expect(chip.selected, isTrue);

    final other = tester.widget<FilterChip>(
      find.ancestor(
        of: find.text('朋友'),
        matching: find.byType(FilterChip),
      ),
    );
    expect(other.selected, isFalse);
  });
}
