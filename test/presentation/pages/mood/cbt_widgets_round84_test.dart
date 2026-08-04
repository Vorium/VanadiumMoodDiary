// v0.29 round 84 (CBT 思维记录): 公共 widget 测试
//
// 覆盖:
// 1. CbtSectionField 渲染: 标题 + ℹ️ + 提示 + prompt 库按钮
// 2. CbtExplainerCard 折叠交互: 展开 ↔ 收起
//
// 频度: 5/7 栏 wizard 每步都用 CbtSectionField, 顶部说明卡每次进 dialog 都渲染
// 模式: 跟 R80 mood_recorder widget test 同款 — ProviderScope + MaterialApp +
// tester.pumpAndSettle
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_section_field.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_explainer_card.dart';

void _noopOnChanged(String _) {}

void main() {
  testWidgets('CbtSectionField 显示标题 + ℹ️ + placeholder + prompt 按钮', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CbtSectionField(
          title: '情境',
          hint: '触发这个想法的事件',
          prompts: const ['问题1', '问题2'],
          onChanged: (_) {},
        ),
      ),
    ),);
    expect(find.text('情境'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.text('触发这个想法的事件'), findsOneWidget);
    expect(find.text('?'), findsOneWidget); // prompt 库按钮
  });

  testWidgets(
    'CbtSectionField 父 setState 重建时保留用户输入 (controller leak regression)',
    (tester) async {
      // 父 State 持 trigger, setState 重建整个子树模拟 wizard step 切换 / 主题切换 / 键盘弹出.
      late StateSetter outerSetState;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              outerSetState = setState;
              return const CbtSectionField(
                title: '情境',
                hint: '触发这个想法的事件',
                prompts: ['问题1'],
                onChanged: _noopOnChanged,
              );
            },
          ),
        ),
      ),);

      // 1. 输入文字
      await tester.enterText(find.byType(TextField), 'foo bar');
      await tester.pump();
      expect(find.text('foo bar'), findsOneWidget);

      // 2. 父 setState 触发整棵子树重建
      outerSetState(() {});
      await tester.pump();

      // 3. 文字必须还在 (修复前: build 内 new TextEditingController 会重置为 '')
      expect(find.text('foo bar'), findsOneWidget);
    },
  );

  testWidgets('CbtExplainerCard 默认展开, 点击收起', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: CbtExplainerCard(
          title: '什么是 CBT 思维记录?',
          body: 'CBT 是认知行为疗法...',
        ),
      ),
    ),);
    expect(find.text('什么是 CBT 思维记录?'), findsOneWidget);
    expect(find.text('CBT 是认知行为疗法...'), findsOneWidget);
    await tester.tap(find.text('什么是 CBT 思维记录?'));
    await tester.pumpAndSettle();
    expect(find.text('CBT 是认知行为疗法...'), findsNothing);
  });
}
