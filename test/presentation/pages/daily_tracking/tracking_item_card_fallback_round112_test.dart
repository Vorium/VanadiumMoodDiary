// v0.32 R112 P3: 追踪项卡片未注册 nameKey 兜底文案
//
// 背景: _getLocalizedName default 分支返 raw ARB key 名 ('moodDiaryName'
// 字面量上屏) — 漏加 switch 分支时用户看到 key 名。
// 修复: default 分支 assert (debug 暴露) + 返回 l10n.trackingUnknownItem
// 兜底文案 (release 不上屏 key 名)。
//
// 覆盖:
// 1. zh locale: 未知 nameKey → '未知项目' (不是 raw key 名)
// 2. en locale: 未知 nameKey → 'Unknown item'

import 'package:chroniccare/domain/entities/tracking_item_config.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/tracking_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // id 用未注册值 → _lastValueFor 走 default 返 null (不需要 override provider)
  const unknownConfig = DailyTrackingItemConfig(
    id: 'unknown_id',
    nameKey: 'fooBarName',
    descKey: 'fooBarShortDesc',
    iconCodePoint: 0xf1e5,
    colorValue: 0xFFFF9500,
    category: TrackingCategory.emotional,
    route: '/unknown',
  );

  Widget wrap(Locale locale) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: const Scaffold(
          body: TrackingItemCard(config: unknownConfig),
        ),
      ),
    );
  }

  testWidgets('1) zh locale: 未知 nameKey → 兜底文案', (tester) async {
    await tester.pumpWidget(wrap(const Locale('zh')));
    await tester.pumpAndSettle();

    expect(find.text('未知项目'), findsOneWidget);
    expect(find.text('fooBarName'), findsNothing);
  });

  testWidgets('2) en locale: 未知 nameKey → Unknown item', (tester) async {
    await tester.pumpWidget(wrap(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Unknown item'), findsOneWidget);
    expect(find.text('fooBarName'), findsNothing);
  });
}
