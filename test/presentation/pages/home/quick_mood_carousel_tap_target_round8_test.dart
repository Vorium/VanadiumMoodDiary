// v0.32 round 8 (R112-02 fix): quick_mood_carousel "more" tune icon tap target
//
// 背景: quick_mood_carousel.dart:122-129 PressFeedback 直接包
// `Icon(Icons.tune, size: 18)` — 全库唯一 18pt 裸 icon 交互点, 无最小
// tap 区域 (实际 ~18-24px < Apple HIG 44pt)。精神心理患者触控精度差时
// 更难命中。
//
// 修: PressFeedback 包 SizedBox(44×44) + Center(Icon 18pt) —
// 44pt 最小 tap target 达标, 视觉 icon 大小不变。
//
// 测试 2 case:
// 1. tune icon 外包 44×44 SizedBox (最小 tap target)
// 2. tap 44×44 区域 (icon 中心) → onOpenFullDialog 触发
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/home/widgets/quick_mood_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      );

  group('QuickMoodCarousel tune icon tap target (R112-02)', () {
    testWidgets('1. tune icon 外包 44×44 SizedBox (最小 tap target)',
        (tester) async {
      await tester.pumpWidget(
        wrap(QuickMoodCarousel(onOpenFullDialog: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.tune), findsOneWidget);

      // 找 tune icon 最近的 SizedBox ancestor
      final sized = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.byIcon(Icons.tune),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(
        sized.width,
        44,
        reason: 'tune icon tap target 宽 44pt (Apple HIG 最小)',
      );
      expect(
        sized.height,
        44,
        reason: 'tune icon tap target 高 44pt (Apple HIG 最小)',
      );

      // icon 本身仍是 18pt (视觉不变, 只扩 tap 区)
      final icon = tester.widget<Icon>(find.byIcon(Icons.tune));
      expect(icon.size, 18, reason: 'icon 视觉大小保持 18pt');
    });

    testWidgets('2. tap tune 区域 → onOpenFullDialog 触发', (tester) async {
      var opened = 0;
      await tester.pumpWidget(
        wrap(QuickMoodCarousel(onOpenFullDialog: () => opened++)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      expect(opened, 1, reason: 'tap 44×44 区域应触发完整 MoodDialog 回调');
    });
  });
}
