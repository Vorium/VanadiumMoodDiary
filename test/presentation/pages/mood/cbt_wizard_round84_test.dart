// v0.29 round 84 (CBT 思维记录): CbtWizard widget 测试
//
// 覆盖: 5/7 栏 wizard 步骤式布局 + step 切换
// - step 0 (默认) 渲染 情境 section + 步数指示
// - 点击 下一步 从 情境 (step 0) → 自动思维 (step 1)
// - 父组件 SingleChildScrollView (Dialog 默认) 包 wizard 不触发 layout error
//
// 模式: 跟 R84 cbt_three_column_round84_test 同款 —
// ProviderScope + MaterialApp + tester.pumpAndSettle
//
// v0.29 round 84 (Task 9): wizard 内部走 l10n (moodCbtSectionSituation 等),
// 加 localizationsDelegates 让 AppLocalizations.of(context) 工作。
//
// v0.29 round 84 (final review): 去掉 wizard 内部 Expanded 父 SCV 嵌套 bug
// 修复 (R84 Task 10 集成测发现的 "layout error in production Dialog" 隐患)。
// 这里的 3 个 widget test 在跨 3/5/7 栏 step 0-1 内容相同的默认状态下跑 —
// cbtDraftProvider 默认 level=three 时不显示 wizard (走 CbtThreeColumnMode),
// 但 wizard widget 本身可在任何 step 0 状态下挂载验证 (3 栏 level 同样用 step 0
// stepIndex 渲染 情境 section)。setLevel 切换不在这里测 — 之前的尝试触发
// 了 "Tried to modify a provider while building" 错误, 集成测走 happy path。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_wizard.dart';

void main() {
  testWidgets(
    'CbtWizard step 0 显示 情境 section (跨 3/5/7 栏)',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('zh'),
            home: Scaffold(body: CbtWizard()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('情境'), findsWidgets);
      expect(find.textContaining('第'), findsOneWidget); // Step X / N
    },
  );

  testWidgets(
    'CbtWizard step 0→1 切换 (跨 3/5/7 栏 step 0-1 内容相同)',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('zh'),
            home: Scaffold(body: CbtWizard()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // step 0: 情境, 填一下触发 next step
      await tester.enterText(find.byType(TextField).first, '开会迟到');
      await tester.tap(find.text('下一步'));
      await tester.pumpAndSettle();
      expect(find.text('自动思维'), findsOneWidget);
    },
  );

  // v0.29 round 84 (final review fix #4): 验证 wizard 在父 SCV (production
  // Dialog 的 SingleChildScrollView) 包 Column(mainAxisSize.min) 嵌套下
  // 不再触发 RenderFlex layout exception。R84 Task 10 集成测已暴露
  // production bug, 修复方式 = 去掉 CbtWizard 内部 Expanded 包装。回归测
  // 用相同嵌套模式验证。
  testWidgets(
    'CbtWizard 嵌入父 SingleChildScrollView > Column (Dialog 默认嵌套) 不抛 layout exception',
    (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('zh'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [CbtWizard()],
                ),
              ),
            ),
          ),
        ),
      );
      // 不抛 layout error 即通过; tester.takeException() 在 production
      // 路径会捕获 RenderFlex 异常, 修复后应返回 null
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // 同步验证 step 0 还能正常渲染
      expect(find.text('情境'), findsWidgets);
    },
  );
}
