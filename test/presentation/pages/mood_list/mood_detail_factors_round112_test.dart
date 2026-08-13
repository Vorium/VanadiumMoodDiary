// v0.32 R112-03: mood 详情页影响因素 i18n 展示
//
// 背景: 录入侧存的是 domain 硬编码中文字面量, 详情页直接 Text(f) 上屏,
// 英文环境也显示中文。修复: 新数据存 key, 展示侧 zh 字面量→key 反查 +
// kInfluenceFactorKeys ARB 派发。
//
// 覆盖:
// 1. 新数据 (key) → zh 显示本地化文案
// 2. 旧中文数据 (字面量) → 反查显示本地化文案 (兼容存量)
// 3. en locale → 显示英文
// 4. 未知自定义值 → 原样显示 (不丢数据)

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  MoodEntryEntity entryWith(String factorsJson) {
    return MoodEntryEntity(
      id: 1,
      timestamp: DateTime(2026, 8, 5, 9),
      score: 4,
      influenceFactorsJson: factorsJson,
    );
  }

  Widget wrap(MoodEntryEntity entry, Locale locale) {
    return ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: MoodDetailPage(entry: entry),
      ),
    );
  }

  testWidgets('1) 新数据 (key) → zh 本地化文案', (tester) async {
    await tester.pumpWidget(
      wrap(entryWith('["influenceFactorFamily","influenceFactorSunny"]'),
          const Locale('zh'),),
    );
    await tester.pumpAndSettle();

    expect(find.text('家人'), findsOneWidget);
    expect(find.text('晴天'), findsOneWidget);
    // 不显示 raw key 名
    expect(find.textContaining('influenceFactor'), findsNothing);
  });

  testWidgets('2) 旧中文数据 → 反查显示本地化文案', (tester) async {
    await tester.pumpWidget(
      wrap(entryWith('["家人","晴天"]'), const Locale('zh')),
    );
    await tester.pumpAndSettle();

    expect(find.text('家人'), findsOneWidget);
    expect(find.text('晴天'), findsOneWidget);
    expect(find.textContaining('influenceFactor'), findsNothing);
  });

  testWidgets('3) en locale → 英文', (tester) async {
    await tester.pumpWidget(
      wrap(entryWith('["家人"]'), const Locale('en')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Family'), findsOneWidget);
    expect(find.text('家人'), findsNothing);
  });

  testWidgets('4) 未知自定义值 → 原样显示', (tester) async {
    await tester.pumpWidget(
      wrap(entryWith('["自定义因素"]'), const Locale('zh')),
    );
    await tester.pumpAndSettle();

    expect(find.text('自定义因素'), findsOneWidget);
  });
}
