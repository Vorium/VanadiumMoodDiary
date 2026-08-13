// v0.31 round 8b (Apple Health redesign · Phase 2 Task 2.4): SectionHeader 3 测试
//
// 验证 (任务清单):
// 1. 基础 (改 1 老 test 期望): 字号 11 (fontSizeCaptionSm) + w500 + textHint
//    (老 test 在 home_emil_round81_test.dart 假设 16pt/textSecondary, R8b 改
//    为 11pt/textHint — 老 test 本身只 find.text 不验字号, 不需要改, 但本 test
//    显式验证新视觉)
// 2. ALL CAPS: title.toUpperCase() 默认 true
// 3. letterSpacing: ALL CAPS 时 0.6, 非 ALL CAPS 时 0
//
// 设计原则:
// - 跟 R7a/R7b/R8a test 风格一致: MaterialApp + Scaffold wrap
// - 中文标题 toUpperCase() 是 no-op, 用 "Test Title" 才能验证 ALL CAPS
//   (有现成 case 在 home_emil_round81_test.dart 用 "近 30 天" — 那是为了 find.text)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/chip_badge.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  group('SectionHeader (R8b 3 cases)', () {
    // ===== 1. 基础 (改 1 老 test 期望): 字号 13 + w500 + textHint =====
    testWidgets('1. 基础: 字号 13 (fontSizeCaption) + w500 + textHint (R8b 改老期望)',
        (tester) async {
      await tester.pumpWidget(
        wrap(const SectionHeader(title: '近 30 天')),
      );

      // Text 渲染
      expect(find.text('近 30 天'), findsOneWidget);

      // R8b 新视觉: 字号 11 (fontSizeCaptionSm) + 字重 w500
      // v0.32 round 8 (R111 EM-02b fix): 11 → 13 跟 AppleListSection 统一
      final style = tester.widget<Text>(find.text('近 30 天')).style!;
      expect(
        style.fontSize, AppTokens.fontSizeCaption, // 13
        reason: 'R8b 改: 字号 16 → 11 (fontSizeCaptionSm); '
            'R111 EM-02b: 11 → 13 (fontSizeCaption) 跟 AppleListSection 统一',
      );
      expect(style.fontWeight, FontWeight.w500, reason: '字重 w500 (不变)');

      // R8b 改颜色: textSecondary → textHint
      final ctx = tester.element(find.byType(SectionHeader));
      expect(
        style.color,
        AppTokens.textHintColor(ctx),
        reason: 'R8b 改: 颜色 textSecondary → textHint (iOS section header 弱化)',
      );
    });

    // ===== 2. ALL CAPS: isAllCaps 默认 true → toUpperCase =====
    testWidgets('2. isAllCaps 默认 true → title.toUpperCase()', (tester) async {
      await tester.pumpWidget(
        wrap(const SectionHeader(title: 'Recent Activity')),
      );

      // 'Recent Activity'.toUpperCase() = 'RECENT ACTIVITY'
      expect(
        find.text('RECENT ACTIVITY'),
        findsOneWidget,
        reason: '默认 isAllCaps=true 应该把 title 转 ALL CAPS',
      );
      expect(
        find.text('Recent Activity'),
        findsNothing,
        reason: '原 title 不应渲染 (被 ALL CAPS 替换)',
      );

      // isAllCaps=false 应该保持原 title
      await tester.pumpWidget(
        wrap(
          const SectionHeader(
            title: 'Recent Activity',
            isAllCaps: false,
          ),
        ),
      );
      expect(
        find.text('Recent Activity'),
        findsOneWidget,
        reason: 'isAllCaps=false 保持原 title 大小写',
      );
      expect(
        find.text('RECENT ACTIVITY'),
        findsNothing,
        reason: 'isAllCaps=false 不应该转 ALL CAPS',
      );
    });

    // ===== 3. letterSpacing: ALL CAPS 时 0.6, 非 ALL CAPS 时 0 =====
    testWidgets('3. letterSpacing: ALL CAPS=0.6 / 默认=0 (跟随 isAllCaps)',
        (tester) async {
      // 3a. 默认 isAllCaps=true → letterSpacing 0.6
      await tester.pumpWidget(
        wrap(const SectionHeader(title: 'Stats')),
      );
      final allCapsStyle = tester.widget<Text>(find.text('STATS')).style!;
      expect(
        allCapsStyle.letterSpacing,
        0.6,
        reason: 'isAllCaps=true → letterSpacing 0.6 (iOS ALL CAPS)',
      );

      // 3b. isAllCaps=false → letterSpacing 0
      await tester.pumpWidget(
        wrap(
          const SectionHeader(
            title: 'Stats',
            isAllCaps: false,
          ),
        ),
      );
      final normalStyle = tester.widget<Text>(find.text('Stats')).style!;
      expect(
        normalStyle.letterSpacing,
        0,
        reason: 'isAllCaps=false → letterSpacing 0 (普通标题无字符间距)',
      );
    });

    // ===== 4. chip → 公共 ChipBadge (v0.32 round 8 EM-09b: 删私有副本) =====
    testWidgets('4. chip 字段走公共 ChipBadge 集中器 (EM-09b)', (tester) async {
      await tester.pumpWidget(
        wrap(const SectionHeader(title: '近 30 天', chip: '5')),
      );
      expect(
        find.byType(ChipBadge),
        findsOneWidget,
        reason: 'EM-09b: 私有 _ChipBadge 副本已删, 走公共 widgets/ChipBadge',
      );
      expect(find.text('5'), findsOneWidget, reason: 'chip 标签文字正常渲染');
    });
  });
}
