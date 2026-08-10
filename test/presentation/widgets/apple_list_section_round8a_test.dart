// v0.31 round 8a (Apple Health redesign · Phase 2 Task 2.4): AppleListSection 5 测试
//
// 验证 (spec §4.5 + 任务清单):
// 1. 基础渲染 (无 title) — children 列表渲染, 圆角 16 容器
// 2. title → ALL CAPS (toUpperCase) + 13pt + textHint + letterSpacing 0.6
// 3. 多 children (3) → 中间夹 2 个 hairline Divider(thickness: 0.5)
// 4. footer → 渲染在 section 下方, 走 textStyleCaptionHint
// 5. dark mode → surface 走 1C1C1E (#1C1C1E surfaceDark)
//
// 设计原则:
// - 跟 R7b AppleHealthTile test 风格一致: MaterialApp theme + Scaffold wrap
// - dark mode 走 ThemeData.dark (跟 R7b 第 9 case 模式一致)
// - ALL CAPS 验证: finder.byWidgetPredicate 找 Text.data = title.toUpperCase()
// - Divider 验证: find.byType(Divider) + thickness 0.5
// - 圆角验证: ClipRRect / Container 走 decoration 链, 找 BorderRadius.circular(16)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

void main() {
  Widget wrap(Widget child, {bool dark = false}) => MaterialApp(
        theme: dark ? ThemeData.dark(useMaterial3: true) : null,
        home: Scaffold(body: Center(child: child)),
      );

  group('AppleListSection (R8a 5 cases)', () {
    // ===== 1. 基础渲染 (无 title, 1 child) =====
    testWidgets('1. 基础: 无 title + 1 child → 渲染 child + 圆角 16 容器',
        (tester) async {
      await tester.pumpWidget(
        wrap(const AppleListSection(
          children: [Text('cell-1')],
        ),),
      );

      // child 渲染
      expect(find.text('cell-1'), findsOneWidget,
          reason: '应该渲染 1 个 child (Text "cell-1")',);

      // 0 个 Divider (单个 child 不需要分隔)
      expect(find.byType(Divider), findsNothing, reason: '1 child 不需要 divider');

      // 圆角 16 验证: 找 ClipRRect + borderRadius 16
      final clipRRect = tester.widgetList<ClipRRect>(find.byType(ClipRRect));
      expect(clipRRect, isNotEmpty, reason: '应该渲染 ClipRRect 圆角');
      final firstClip = clipRRect.first;
      final radius = firstClip.borderRadius as BorderRadius;
      expect(radius.topLeft.x, AppTokens.radiusCard, // 16
          reason: '圆角 = AppTokens.radiusCard (16)',);
    });

    // ===== 2. title → ALL CAPS + 13pt + textHint + letterSpacing 0.6 =====
    testWidgets(
        '2. title → ALL CAPS (toUpperCase) + 13pt w500 + textHint + letterSpacing 0.6',
        (tester) async {
      await tester.pumpWidget(
        wrap(const AppleListSection(
          title: 'recent activity',
          children: [Text('cell')],
        ),),
      );

      // ALL CAPS: 'recent activity'.toUpperCase() = 'RECENT ACTIVITY'
      expect(find.text('RECENT ACTIVITY'), findsOneWidget,
          reason: 'title 应该被 toUpperCase (iOS ALL CAPS section header)',);
      expect(find.text('recent activity'), findsNothing,
          reason: '原 title 不应该渲染 (被 ALL CAPS 替换)',);

      // 验证 13pt w500 textHint + letterSpacing 0.6
      final titleStyle =
          tester.widget<Text>(find.text('RECENT ACTIVITY')).style!;
      expect(titleStyle.fontSize, AppTokens.fontSizeCaption, // 13
          reason: 'title fontSize = fontSizeCaption (13pt)',);
      expect(titleStyle.fontWeight, FontWeight.w500,
          reason: 'title fontWeight = w500',);
      expect(titleStyle.letterSpacing, 0.6,
          reason: 'title letterSpacing = 0.6 (iOS ALL CAPS)',);

      final ctx = tester.element(find.byType(AppleListSection));
      expect(titleStyle.color, AppTokens.textHintColor(ctx),
          reason: 'title color = textHint (iOS section header 弱化色)',);
    });

    // ===== 3. 多 children (3) → 中间夹 2 个 hairline Divider =====
    testWidgets('3. 3 children → 2 个 hairline Divider(thickness: 0.5)',
        (tester) async {
      await tester.pumpWidget(
        wrap(const AppleListSection(
          children: [
            Text('cell-A'),
            Text('cell-B'),
            Text('cell-C'),
          ],
        ),),
      );

      // 3 children 渲染
      expect(find.text('cell-A'), findsOneWidget);
      expect(find.text('cell-B'), findsOneWidget);
      expect(find.text('cell-C'), findsOneWidget);

      // 2 个 Divider (3 children → 2 中间分隔)
      final dividers = tester.widgetList<Divider>(find.byType(Divider));
      expect(dividers.length, 2,
          reason: '3 children 中间应该夹 2 个 hairline divider',);

      // hairline 0.5pt 验证
      for (final d in dividers) {
        expect(d.thickness, 0.5,
            reason: 'divider thickness = 0.5 (iOS hairline)',);
        expect(d.height, 0, reason: 'divider height = 0 (无额外间距)');
      }
    });

    // ===== 4. footer → 渲染在 section 下方, 走 textStyleCaptionHint =====
    testWidgets('4. footer → 渲染在下方, 走 textStyleCaptionHint', (tester) async {
      await tester.pumpWidget(
        wrap(const AppleListSection(
          footer: '点击查看详情',
          children: [Text('cell')],
        ),),
      );

      // footer 渲染
      expect(find.text('点击查看详情'), findsOneWidget, reason: '应该渲染 footer 文字');

      // footer 走 textStyleCaptionHint (caption 13 + textHint color)
      final footerStyle = tester.widget<Text>(find.text('点击查看详情')).style!;
      expect(footerStyle.fontSize, AppTokens.fontSizeCaption, // 13
          reason: 'footer fontSize = fontSizeCaption (13pt)',);

      final ctx = tester.element(find.byType(AppleListSection));
      // textStyleCaptionHint 内部用 textHintColor
      expect(footerStyle.color, AppTokens.textHintColor(ctx),
          reason: 'footer color = textHint (跟 title 弱化色一致)',);
    });

    // ===== 5. dark mode → surface 走 1C1C1E =====
    testWidgets('5. dark mode: 容器 surface 走 1C1C1E (#1C1C1E surfaceDark)',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppleListSection(
            children: [Text('cell')],
          ),
          dark: true,
        ),
      );

      // 找 DecoratedBox → BoxDecoration.color 应该是 surfaceDark (#1C1C1E)
      final decor = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
      final box = decor.decoration as BoxDecoration;
      expect(box.color, const Color(0xFF1C1C1E),
          reason:
              'dark mode 容器 surface = #1C1C1E (iOS secondarySystemGroupedBackground)',);
    });
  });
}
