// v0.27 round 67 (C-5 重构): ChoiceChipWrap 集中器测试
//
// 验证 2 处 Wrap(spacing: 8, runSpacing: 8, [ChoiceChip]) 抽到
// ChoiceChipWrap<T> 集中器后行为一致 + 用 AppTokens.spacingXs 替代硬编码 8。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/widgets/choice_chip_wrap.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

void main() {
  group('ChoiceChipWrap (R67 C-5)', () {
    testWidgets('1. 渲染: options 全部展示, 选中的 chip 是 selected 态', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChoiceChipWrap<int>(
              options: const [3, 5, 7, 14, 30],
              selected: 7,
              labelOf: (d) => '$d 天',
              onSelect: (_) {},
            ),
          ),
        ),
      );
      // 5 个 chip
      expect(find.text('3 天'), findsOneWidget);
      expect(find.text('7 天'), findsOneWidget);
      expect(find.text('30 天'), findsOneWidget);
      // 选中的 chip (7 天) 应该有 selected=true
      final selectedChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '7 天'),
      );
      expect(selectedChip.selected, isTrue);
      // 未选中的 (3 天) 应该有 selected=false
      final unselectedChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '3 天'),
      );
      expect(unselectedChip.selected, isFalse);
    });

    testWidgets('2. onSelect 回调: 点 chip 触发 onSelect(value)', (tester) async {
      int? selectedValue;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChoiceChipWrap<int>(
              options: const [3, 7, 14],
              selected: 3,
              labelOf: (d) => '$d',
              onSelect: (v) => selectedValue = v,
            ),
          ),
        ),
      );
      // 点 7
      await tester.tap(find.widgetWithText(ChoiceChip, '7'));
      await tester.pump();
      expect(selectedValue, equals(7));
    });

    testWidgets('3. disabled=true: 所有 chip onSelected=null (不可点)',
        (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChoiceChipWrap<int>(
              options: const [3, 7, 14],
              selected: 3,
              labelOf: (d) => '$d',
              onSelect: (_) => tapCount++,
              disabled: true,
            ),
          ),
        ),
      );
      // disabled 时所有 chip.onSelected 应为 null
      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, '7'),
      );
      expect(chip.onSelected, isNull);
    });

    testWidgets('4. Wrap 用 AppTokens.spacingXs (替代硬编码 8)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChoiceChipWrap<int>(
              options: const [1, 2],
              selected: 1,
              labelOf: (d) => '$d',
              onSelect: (_) {},
            ),
          ),
        ),
      );
      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.spacing, equals(AppTokens.spacingXs));
      expect(wrap.runSpacing, equals(AppTokens.spacingXs));
    });
  });
}
