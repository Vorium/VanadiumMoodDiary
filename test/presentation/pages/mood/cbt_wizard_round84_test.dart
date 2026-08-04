// v0.29 round 84 (CBT 思维记录): CbtWizard widget 测试
//
// 覆盖: 5/7 栏 wizard 步骤式布局 + step 切换
// - step 0 (默认) 渲染 情境 section + 步数指示
// - 点击 下一步 从 情境 (step 0) → 自动思维 (step 1)
//
// 模式: 跟 R84 cbt_three_column_round84_test 同款 —
// ProviderScope + MaterialApp + tester.pumpAndSettle
//
// 注: wizard 真正读的是 cbtDraftProvider (而非 thoughtRecordLevelProvider),
// 切档由父 mood_recorder_page 在 SegmentedButton 回调里做。
// 这里我们不直接调 setLevel,只验 wizard 在 default state 下的 step 0/1
// 切换 — step 0-3 内容在 5/7 栏下都一样,setLevel 不会改变行为。
// 之前尝试在 Consumer.build 里调 setLevel 触发了
// "Tried to modify a provider while building" 错误,删掉。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/pages/mood/widgets/cbt_wizard.dart';

void main() {
  testWidgets('5 栏 wizard step 0 显示 情境 section', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: CbtWizard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('情境'), findsWidgets);
    expect(find.textContaining('第'), findsOneWidget); // Step X / N
  });

  testWidgets('5 栏 wizard step 切换: 点击下一步从 情境 → 自动思维',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: CbtWizard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // step 0: 情境, 填一下触发 next step
    await tester.enterText(find.byType(TextField).first, '开会迟到');
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('那一刻脑海中闪过的想法'), findsOneWidget);
  });
}
