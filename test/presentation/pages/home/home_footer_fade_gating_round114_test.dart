// R114 Wave B2: home footer 入场门控 + 高频列表 FadeIn 降档 (B2-8)
//
// emil F2: HomeFooter 2 项 FadeIn 用默认 durSlow 400ms + 30ms stagger,
// 且未接 homeEntryPlayedProvider 门控 — 每次 tab 切回主页重播 (Wave 7
// 门控了 header/checkin/summary 漏掉 footer)。树洞列表行 (tens/day) +
// 用药日历行 + FAB 工具栏 4 按钮也用默认 400ms。
//
// 修法: HomeFooter 加 entryDuration / entryDelay (Wave 7 同款门控);
// vent_list / medication_calendar_grid / home_fab_toolbar 的 FadeIn 显式
// duration: AppTokens.durFast (200ms, tens/day 列表入场 150-250ms 档)。

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_footer.dart';
import 'package:chroniccare/presentation/widgets/animations/fade_in.dart';

Future<void> _pumpFooter(WidgetTester tester, HomeFooter footer) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(body: footer),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('B2-8: HomeFooter 门控', () {
    testWidgets('默认 (首次入场): FadeIn duration = durSlow + 第 2 项 30ms stagger',
        (tester) async {
      await _pumpFooter(
        tester,
        const HomeFooter(
          lastCheckIn: null,
          nextReminder: null,
          showStreakBroken: false,
        ),
      );

      final fades = tester.widgetList<FadeIn>(find.byType(FadeIn)).toList();
      expect(fades.length, 2);
      expect(fades[0].duration, AppTokens.durSlow);
      expect(fades[1].duration, AppTokens.durSlow);
      expect(
        fades[1].delay,
        const Duration(milliseconds: AppTokens.staggerStepMs),
        reason: '首次入场保留 30ms stagger (emil 主页"逐项落入")',
      );
    });

    testWidgets('entryPlayed (tab 切回): duration + delay 都 zero, 不重播',
        (tester) async {
      await _pumpFooter(
        tester,
        const HomeFooter(
          lastCheckIn: null,
          nextReminder: null,
          showStreakBroken: false,
          entryDuration: Duration.zero,
          entryDelay: Duration.zero,
        ),
      );

      final fades = tester.widgetList<FadeIn>(find.byType(FadeIn)).toList();
      expect(fades.length, 2);
      for (final f in fades) {
        expect(
          f.duration,
          Duration.zero,
          reason: '修前 footer 不接门控, tab 切回重播 400ms+30ms',
        );
        expect(f.delay, Duration.zero);
      }
    });
  });

  group('B2-8: lock-in — 高频列表 FadeIn 显式 durFast', () {
    Future<String> read(String path) => File('lib/$path').readAsString();

    test('vent_list_page 树洞行 FadeIn duration: durFast', () async {
      // v1.1.0+159 R121 P1-2 续抽 _EntryList → widgets/vent_entry_list.dart
      // FadeIn 在子文件, 主壳和子文件都需验证
      final main = await read('features/vent/presentation/pages/vent/vent_list_page.dart');
      final listFile = await read(
        'features/vent/presentation/pages/vent/widgets/vent_entry_list.dart',
      );
      expect(
        main.contains('duration: AppTokens.durFast') ||
            listFile.contains('duration: AppTokens.durFast'),
        isTrue,
      );
    });

    test('medication_calendar_grid 行 FadeIn duration: durFast', () async {
      final src = await read(
        'features/medication/presentation/pages/medication/widgets/medication_calendar_grid.dart',
      );
      expect(src.contains('duration: AppTokens.durFast'), isTrue);
    });

    test('home_fab_toolbar 4 按钮 FadeIn duration: durFast', () async {
      final src =
          await read('features/home/presentation/pages/home/widgets/home_fab_toolbar.dart');
      expect(src.contains('duration: AppTokens.durFast'), isTrue);
    });
  });
}
