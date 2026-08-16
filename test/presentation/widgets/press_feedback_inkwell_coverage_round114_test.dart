// R114 Wave B2: 裸 InkWell/按钮补 PressFeedback scale 反馈 (B2-9 前半)
//
// emil F4: 全 app 按钮标准 = scale 0.97 100ms + haptic (PressFeedback),
// 但 5 处高频 tile 只有 M3 ripple:
//   - daily_tracking_card.dart:48 (Card > InkWell, 7 卡片 grid tens/day)
//   - assessment_center_card.dart:51 (Card > InkWell)
//   - trend_calendar.dart:248 (日历日 cell InkWell, tens/day)
//   - worry_timeline_page.dart:131/139 + dialog 按钮 (FilledButton/TextButton)
//   - mood_hero_card.dart:56/93/98/104 (主页双主卡入口按钮)
//
// 修法: 统一包 PressFeedback (mode 2, 不接管 tap — child 自带 onTap 正常)。

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/daily_tracking_card.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

void main() {
  group('B2-9: DailyTrackingCard (widget test)', () {
    testWidgets('Card 内 InkWell 外层有 PressFeedback (scale 反馈)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(
            body: DailyTrackingCard(
              title: '睡眠',
              route: '/sleep',
              lastValue: null,
            ),
          ),
        ),
      );

      expect(
        find.ancestor(
          of: find.byType(InkWell),
          matching: find.byType(PressFeedback),
        ),
        findsWidgets,
        reason: '修前卡片只有 ripple 无 scale 0.97 反馈',
      );
    });
  });

  group('B2-9: lock-in — 其余 4 文件裸 InkWell/按钮包 PressFeedback', () {
    Future<String> read(String path) => File('lib/$path').readAsString();

    test('assessment_center_card.dart: Card > PressFeedback > InkWell',
        () async {
      final src = await read(
        'presentation/pages/assessment/widgets/assessment_center_card.dart',
      );
      expect(
        RegExp(r'Card\([\s\S]{0,120}?child: PressFeedback\(\s*child: InkWell\(')
            .hasMatch(src),
        isTrue,
      );
    });

    test('trend_calendar.dart: 日历 cell InkWell 包 PressFeedback', () async {
      final src = await read('presentation/pages/trend/trend_calendar.dart');
      expect(
        RegExp(r'PressFeedback\(\s*child: InkWell\(').hasMatch(src),
        isTrue,
      );
    });

    test(
        'worry_timeline_page.dart: FilledButton/OutlinedButton/TextButton 包 PressFeedback',
        () async {
      final src =
          await read('presentation/pages/worry/worry_timeline_page.dart');
      expect(
        RegExp(r'PressFeedback\(\s*child: (FilledButton|OutlinedButton|TextButton)\(')
            .hasMatch(src),
        isTrue,
      );
    });

    test('mood_hero_card.dart: FilledButton/TextButton 包 PressFeedback',
        () async {
      final src =
          await read('presentation/pages/home/widgets/mood_hero_card.dart');
      expect(
        RegExp(r'PressFeedback\(\s*child: (FilledButton|TextButton)\(')
            .hasMatch(src),
        isTrue,
      );
    });
  });
}
