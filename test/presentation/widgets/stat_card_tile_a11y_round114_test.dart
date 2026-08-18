// R114 Wave B2: StatCard tabularFigures + AppleHealthTile Dynamic Type (B2-6)
//
// apple F-09: StatCard/TweenNumber 大数字无 tabularFigures — 数字变化时
// 比例数字宽度跳动 (1 vs 8), Apple Health 大数字 (SF 等宽数字) 不抖;
// 全 lib 仅 2 处 audio 计时器用了。
//
// apple F-07: AppleHealthTile 固定 110×140 + textScaler 0 处理 —
// textScaler 2.0 时 label 13→26pt + value 28→56pt 溢出 110pt 高容器。
// 修法: tile 内容 MediaQuery textScaler clamp 1.3 (140pt 宽 tile 物理
// 上限, 大字号场景 label/value ellipsis 兜底; 全动态支持留 v1.0 布局弹性)。

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/apple_health_tile.dart';
import 'package:chroniccare/presentation/widgets/stat_card.dart';

void main() {
  group('B2-6: StatCard 大数字 tabularFigures', () {
    testWidgets('int 数字 (TweenNumber 路径) → fontFeatures 含 tabularFigures',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: StatCard(label: 'label', value: '5')),
        ),
      );
      final text = tester.widget<Text>(find.text('5'));
      expect(
        text.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
        reason: '修前数字变化时字符宽度跳动 (比例数字 1 vs 8 宽度不同)',
      );
    });

    testWidgets('非 int 数字 (静态 Text 路径) 同样 tabularFigures', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: StatCard(label: 'label', value: '1.2kg')),
        ),
      );
      final text = tester.widget<Text>(find.text('1.2kg'));
      expect(text.style?.fontFeatures,
          contains(const FontFeature.tabularFigures()));
    });
  });

  group('B2-6: AppleHealthTile Dynamic Type clamp', () {
    testWidgets('textScaler 2.0 → 不溢出 (clamp 1.3)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2.0)),
            child: child!,
          ),
          home: const Scaffold(
            body: AppleHealthTile(
              metricId: 'medication',
              label: '今日用药',
              value: '5',
            ),
          ),
        ),
      );

      expect(
        tester.takeException(),
        isNull,
        reason: '修前 label 26pt + value 56pt + padding 32 溢出 110pt 高容器',
      );

      // lock-in: tile 内容走 withClampedTextScaling(1.3)
      final clamped = tester
          .widgetList<MediaQuery>(find.byType(MediaQuery))
          .where((m) => m.data.textScaler == const TextScaler.linear(1.3));
      expect(clamped, isNotEmpty, reason: 'tile 内容应 clamp textScaler 到 1.3');
    });

    testWidgets('正常 textScaler 1.0 → 行为不变', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AppleHealthTile(
              metricId: 'medication',
              label: '今日用药',
              value: '5',
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('今日用药'), findsOneWidget);
    });
  });
}
