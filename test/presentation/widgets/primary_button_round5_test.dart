// v0.31 round 5 (Apple Health redesign · Phase 2 Task 2.1): PrimaryButton 3 variant 测试
//
// 验证:
// 1. primary variant (默认) → FilledButton, 背景 = colorScheme.primary
// 2. secondary variant → FilledButton.tonal, 背景 = colorScheme.secondaryContainer
// 3. tertiary variant → TextButton (无填充背景)
// 4. leadingIcon 显示在文字前 (Row[IconTheme, SizedBox, Text])
// 5. 包 PressFeedback 提供 scale(0.97) 100ms 反馈
// 6. token 应用: textStyle fontSize=17 (AppTokens.fontSizeButton), w600
//
// 保留: primary_button_round65_test.dart 4 个老 case 继续过 (caller 无需迁移)

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
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

  testWidgets('R5-PB-V1: primary variant (默认) → FilledButton 背景=primary',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        child: PrimaryButton(
          variant: PrimaryButtonVariant.primary,
          onPressed: () {},
          child: const Text('立即升级'),
        ),
      ),
    );

    // primary → FilledButton (不是 TextButton)
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);

    // 验证背景 = colorScheme.primary
    final ctx = tester.element(find.byType(PrimaryButton));
    final material = tester.widget<Material>(
      find.descendant(
          of: find.byType(FilledButton), matching: find.byType(Material)),
    );
    expect(material.color, Theme.of(ctx).colorScheme.primary);
  });

  testWidgets(
      'R5-PB-V2: secondary variant → FilledButton.tonal 背景=secondaryContainer',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        child: PrimaryButton(
          variant: PrimaryButtonVariant.secondary,
          onPressed: () {},
          child: const Text('取消'),
        ),
      ),
    );

    // secondary → FilledButton.tonal (仍是 FilledButton 实例, 背景色不同)
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);

    // 验证背景 = colorScheme.secondaryContainer (区别于 primary)
    final ctx = tester.element(find.byType(PrimaryButton));
    final material = tester.widget<Material>(
      find.descendant(
          of: find.byType(FilledButton), matching: find.byType(Material)),
    );
    expect(material.color, Theme.of(ctx).colorScheme.secondaryContainer);
  });

  testWidgets('R5-PB-V3: tertiary variant → TextButton', (tester) async {
    await tester.pumpWidget(
      wrap(
        child: PrimaryButton(
          variant: PrimaryButtonVariant.tertiary,
          onPressed: () {},
          child: const Text('跳过'),
        ),
      ),
    );

    // tertiary → TextButton (无 FilledButton)
    expect(find.byType(TextButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('R5-PB-DEFAULT: variant 默认值 = primary', (tester) async {
    // 不传 variant → 应该是 FilledButton (跟 primary 一样)
    await tester.pumpWidget(
      wrap(
        child: PrimaryButton(
          onPressed: () {},
          child: const Text('默认'),
        ),
      ),
    );

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('R5-PB-ICON: leadingIcon 显示在文字前 (Row + IconTheme)',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        child: PrimaryButton(
          leadingIcon: const Icon(Icons.check),
          onPressed: () {},
          child: const Text('已完成'),
        ),
      ),
    );

    // icon + text 都渲染
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('已完成'), findsOneWidget);

    // leadingIcon 走 Row[IconTheme, SizedBox, child]
    expect(
      find.descendant(
          of: find.byType(PrimaryButton), matching: find.byType(Row)),
      findsOneWidget,
      reason: 'leadingIcon 应该把 icon + child 包装成 Row',
    );

    // IconTheme 应用了 iconSizeInline (17)
    // 注意: MaterialApp 默认包一层 IconTheme, 用 predicate 精确匹配 size=17 那个
    final iconTheme = tester.widget<IconTheme>(
      find.byWidgetPredicate(
        (w) => w is IconTheme && w.data.size == AppTokens.iconSizeInline,
      ),
    );
    expect(iconTheme.data.size, AppTokens.iconSizeInline);
  });

  testWidgets('R5-PB-PRESSFEEDBACK: PrimaryButton 内部包 PressFeedback',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        child: PrimaryButton(
          onPressed: () {},
          child: const Text('press me'),
        ),
      ),
    );

    // PrimaryButton 内有 PressFeedback (接管 scale 视觉反馈)
    expect(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.byType(PressFeedback),
      ),
      findsOneWidget,
      reason: 'PrimaryButton 内部包 PressFeedback 提供 scale(0.97) 反馈',
    );
  });

  testWidgets('R5-PB-TOKEN: textStyle 走 AppTokens (fontSize=17, w600)',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        child: PrimaryButton(
          onPressed: () {},
          child: const Text('token test'),
        ),
      ),
    );

    // 拿 button 内部 Text (在 child 位置), 验证它继承自 button textStyle
    // M3 FilledButton 把 textStyle 合并到 DefaultTextStyle,
    // 拿 DefaultTextStyle.style 验证 fontSize / fontWeight
    final defaultTextStyle = tester.widget<DefaultTextStyle>(
      find
          .descendant(
            of: find.byType(FilledButton),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );

    final style = defaultTextStyle.style;
    expect(
      style.fontSize,
      AppTokens.fontSizeButton,
      reason: '按钮字号应走 AppTokens.fontSizeButton (=17, iOS standard)',
    );
    expect(
      style.fontWeight,
      FontWeight.w600,
      reason: '按钮字重应 = w600 (iOS standard)',
    );
  });
}
