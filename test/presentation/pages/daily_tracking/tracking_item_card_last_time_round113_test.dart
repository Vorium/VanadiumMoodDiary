// v1.1.0 R113 (BUG 3): 追踪项卡片 "上次记录: 今天" 无条件显示
//
// 修前: _moodLastValue 无条件 `dailyTrackingLastTime(cardStatusToday)`,
//   3 天前的 mood entry 也标 "今天"。
// 修后: 与今天同日才 "今天", 否则显示日期 (MM/dd)。
//
// 覆盖:
// 1. entry 是今天 → "今天 记录" (回归守卫)
// 2. entry 3 天前 → 显示 "MM/dd 记录", 0 处 "今天"
// 3. 无 entry → 无 lastValue (desc 占位)
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/tracking_item_config.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/tracking_item_card.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _moodConfig = DailyTrackingItemConfig(
  id: 'mood',
  nameKey: 'moodDiaryName',
  descKey: 'moodDiaryShortDesc',
  iconCodePoint: 0xe1db,
  colorValue: 0xFF007AFF,
  category: TrackingCategory.emotional,
  route: '/mood/create',
);

Widget _wrap(MoodEntryEntity? entry) {
  return ProviderScope(
    overrides: [
      // R114 B1-7: card 改读 allMoodProvider.value?.firstOrNull —
      // override 真源 Stream (修前 override latestMoodEntryProvider sync 包装)
      allMoodProvider.overrideWith(
        (ref) => Stream.value(
          entry == null ? const <MoodEntryEntity>[] : <MoodEntryEntity>[entry],
        ),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: const Scaffold(body: TrackingItemCard(config: _moodConfig)),
    ),
  );
}

MoodEntryEntity _mood(DateTime at) {
  return MoodEntryEntity(
    id: 1,
    timestamp: at,
    score: 4,
    period: 'evening',
  );
}

void main() {
  testWidgets('1) entry 今天 → "今天 记录" (回归守卫)', (tester) async {
    await tester.pumpWidget(_wrap(_mood(DateTime.now())));
    await tester.pumpAndSettle();

    expect(find.text('今天 记录 · 心境 4/5 (晚)'), findsOneWidget);
  });

  testWidgets('2) entry 3 天前 → 显示日期, 0 处 "今天"', (tester) async {
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    await tester.pumpWidget(_wrap(_mood(threeDaysAgo)));
    await tester.pumpAndSettle();

    expect(find.text('今天'), findsNothing, reason: '3 天前不应标 "今天"');
    // zh 卡片 lastValue: "MM/dd 记录 · 心境 4/5 (晚)"
    expect(
      find.textContaining('记录 · 心境 4/5 (晚)'),
      findsOneWidget,
      reason: 'lastValue 摘要仍应显示',
    );
    // 日期必须是 3 天前的 MM/dd (用 Formatters 同款格式验证)
    final mm = threeDaysAgo.month.toString().padLeft(2, '0');
    final dd = threeDaysAgo.day.toString().padLeft(2, '0');
    expect(
      find.textContaining('$mm/$dd 记录'),
      findsOneWidget,
      reason: '非今天应显示日期而非 "今天"',
    );
  });

  testWidgets('3) 无 entry → 无 lastValue (desc 占位)', (tester) async {
    await tester.pumpWidget(_wrap(null));
    await tester.pumpAndSettle();

    expect(find.text('今天'), findsNothing);
  });
}
