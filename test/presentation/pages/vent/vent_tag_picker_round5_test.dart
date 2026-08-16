// 1.1.0 round 5c: VentTagPicker widget 测试 (compose 页标签选择器)
//
// 覆盖:
// 1. 8 个预设 chip 全部渲染 + 传入的 selected 状态正确
// 2. tap 预设 chip → onChanged 收到 toggle 后的 Set
// 3. 自定义输入 + onSubmitted → onChanged 含新标签
// 4. 空/纯空格输入被忽略 (不触发 onChanged)
// 5. 超长 (超过 VentTagLibrary.maxCustomTagLength) 自定义标签被忽略
// 6. 自定义输入 = 已选预设 → 保持选中 (不 toggle 掉), 只清输入 (round 6d)
//
// 纯 widget 测试: 无 repo / 无 platform channel mock 需求。

import 'package:chroniccare/domain/logic/vent_tag_library.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/vent/widgets/vent_tag_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Set<String> selected, ValueChanged<Set<String>> onChanged) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    home:
        Scaffold(body: VentTagPicker(selected: selected, onChanged: onChanged)),
  );
}

void main() {
  testWidgets('1) 8 个预设 chip 全渲染 + selected 状态正确', (tester) async {
    await tester.pumpWidget(_wrap({'家庭'}, (_) {}));

    for (final tag in VentTagLibrary.presetTags) {
      final chip = tester.widget<FilterChip>(
        find.widgetWithText(FilterChip, tag),
      );
      expect(chip.selected, tag == '家庭', reason: '$tag selected 状态不对');
    }
    // 节标题 (zh: 标签)
    expect(find.text('标签'), findsOneWidget);
  });

  testWidgets('2) tap 预设 chip → onChanged 收到 toggle 后的 Set', (tester) async {
    Set<String>? received;
    await tester.pumpWidget(_wrap({'家庭'}, (next) => received = next));

    await tester.tap(find.widgetWithText(FilterChip, '工作'));
    await tester.pump();

    expect(received, {'家庭', '工作'});

    // 再 tap 一次同 chip → 移除
    await tester.pumpWidget(_wrap({'家庭', '工作'}, (next) => received = next));
    await tester.tap(find.widgetWithText(FilterChip, '家庭'));
    await tester.pump();
    expect(received, {'工作'});
  });

  testWidgets('3) 自定义输入 + onSubmitted → onChanged 含新标签 + 输入清空', (tester) async {
    Set<String>? received;
    await tester.pumpWidget(_wrap({}, (next) => received = next));

    await tester.enterText(find.byType(TextField), '考研');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(received, contains('考研'));
    // 输入框被清空
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
  });

  testWidgets('4) 空输入被忽略 → onChanged 不被调用', (tester) async {
    var called = false;
    await tester.pumpWidget(_wrap({}, (_) => called = true));

    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(called, isFalse);
  });

  testWidgets('5) maxLength 截断超长自定义标签 (>maxCustomTagLength)', (tester) async {
    Set<String>? received;
    await tester.pumpWidget(_wrap({}, (next) => received = next));

    final tooLong = '长' * (VentTagLibrary.maxCustomTagLength + 1);
    await tester.enterText(find.byType(TextField), tooLong);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // TextField maxLength formatter 截断到 12 字, onChanged 收到截断后的合法标签
    expect(received, {'长' * VentTagLibrary.maxCustomTagLength});
  });

  testWidgets('6) 自定义输入 = 已选预设 → 保持选中 (不 toggle 掉), 只清输入', (tester) async {
    Set<String>? received;
    await tester.pumpWidget(_wrap({'家庭'}, (next) => received = next));

    await tester.enterText(find.byType(TextField), '家庭');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    // 不触发 onChanged (无 toggle-off), 父级仍持有 {'家庭'}
    expect(received, isNull);
    // 输入框被清空
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
    // chip 仍选中
    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, '家庭'),
    );
    expect(chip.selected, isTrue);
  });
}
