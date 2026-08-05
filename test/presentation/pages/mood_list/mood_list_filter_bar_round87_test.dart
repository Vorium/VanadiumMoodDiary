// v0.30 round 87 (sub-spec 3 mood 列表页): MoodListFilterBar widget 测试
//
// 覆盖:
// 1. 显示 3 个 filter chip (日期 / 分数 / CBT) + 1 个 sort dropdown
// 2. tap date chip → 弹 date range picker (Dialog)
//
// 跟 mood_list_item_round87_test.dart 风格一致:
// - MaterialApp + l10n delegates + zh locale
// - 真实 ProviderContainer (ProviderScope),让 widget 走 ref.watch 拿 state
// - tap 用 find.widgetWithText(ActionChip, '日期') 而不是 find.text,
//   避免 hit test 警告 (Text 是 chip 内部 widget, 实际 hit 区域在 chip inkwell)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood_list/widgets/mood_list_filter_bar.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(body: child),
        ),
      );

  testWidgets('filter bar 显示 3 chips + sort dropdown', (tester) async {
    await tester.pumpWidget(wrap(const MoodListFilterBar()));

    // 3 filter chips: 日期 / 分数 / CBT (用 widgetWithText 锁到 ActionChip, 避免歧义)
    expect(find.widgetWithText(ActionChip, '日期'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, '分数'), findsOneWidget);
    expect(find.widgetWithText(ActionChip, 'CBT 档位'), findsOneWidget);

    // 1 sort dropdown: 排序 label + 当前选中项 (默认 timestampDesc → "时间倒序")
    expect(find.text('排序'), findsOneWidget);
    expect(find.text('时间倒序'), findsOneWidget);
  });

  testWidgets('tap date chip → 弹 date range picker Dialog', (tester) async {
    await tester.pumpWidget(wrap(const MoodListFilterBar()));

    // tap 日期 chip — find ActionChip 整体而非 Text (Text 区域小, 警告 hit miss)
    await tester.tap(find.widgetWithText(ActionChip, '日期'));
    await tester.pumpAndSettle();

    // showDateRangePicker 是 Material Dialog, 标题含 '选择起止日期' / 'Select dates'
    // 验证 Dialog 已在 overlay (不关心具体标题, 跨 locale 稳定)
    expect(find.byType(Dialog), findsOneWidget);
  });
}
