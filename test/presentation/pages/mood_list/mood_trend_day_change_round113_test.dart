// R113 Wave 7 (Task B): 5 处 build 内 DateTime.now() → watch(todayProvider)
// 跨 midnight stale 修复回归测试
//
// 修前 bug: mood_trend / vent_list / daily_tracking / assessment_center_card /
// mood_review 在 build 内直接 `DateTime.now()`, AppRoot 跨 midnight tick 时
// 这些 widget 不 rebuild → "今天/昨天"标签、图表窗口 stale 到次日。
// 修后: 5 处改 `ref.watch(todayProvider)` (watch dayChangeTickProvider,
// 跨日自动刷新)。
//
// 行为测试 (2 个):
// 1. MoodTrendPage: fakeToday 前进 1 天 + dayChangeTick tick →
//    折线窗口随"今天"移动 (spot 数 1 → 2)
// 2. MoodReviewPage: fakeToday 前进 1 周 + tick → entriesCount 1 → 0
//
// lock-in 测试 (5 个, 源码级): 5 个文件不再在 build 内 DateTime.now(),
// 均 watch todayProvider (防回退; R95+ 白盒测试模式)。

import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_review_page.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_trend_page.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';

/// 可控 dayChangeTick (跨 midnight tick 的测试替身) — 继承真实
/// [DayChangeTickNotifier] 拿到 tick() (overrideWith 要求同类型)
class _FakeDayTickNotifier extends DayChangeTickNotifier {
  @override
  int build() => 0;
}

/// 可变的"今天" (override todayProvider 读它; 换值 + tick 触发刷新)
DateTime fakeToday = DateTime(2026, 8, 16, 10);

Widget wrapPage(Widget home, List<MoodEntryEntity> entries) {
  return ProviderScope(
    overrides: [
      dayChangeTickProvider.overrideWith(_FakeDayTickNotifier.new),
      todayProvider.overrideWith((ref) {
        ref.watch(dayChangeTickProvider);
        return fakeToday;
      }),
      allMoodProvider.overrideWith((ref) => Stream.value(entries)),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: home,
    ),
  );
}

MoodEntryEntity _mood(int id, DateTime ts, int score) =>
    MoodEntryEntity(id: id, timestamp: ts, score: score);

int nonNullSpotCount(WidgetTester tester) {
  final chart = tester.widget<LineChart>(find.byType(LineChart).first);
  return chart.data.lineBarsData.first.spots.where((s) => !s.x.isNaN).length;
}

void main() {
  setUp(() {
    fakeToday = DateTime(2026, 8, 16, 10);
  });

  testWidgets('1. MoodTrendPage: 跨日 tick → 折线窗口随"今天"移动 (1 → 2 spot)',
      (tester) async {
    // fakeToday = 08-16 (周日): 7 天窗口 = 08-10 ~ 08-16
    // e1 (08-15) 在窗口内; e2 (08-17) 明天, 不在窗口 → 1 spot
    final entries = [
      _mood(1, DateTime(2026, 8, 15, 18), 4),
      _mood(2, DateTime(2026, 8, 17, 9), 3),
    ];
    await tester.pumpWidget(wrapPage(const MoodTrendPage(), entries));
    await tester.pumpAndSettle();

    expect(
      nonNullSpotCount(tester),
      1,
      reason: 'today=08-16 时 08-17 条目应在窗口外 (1 spot)',
    );

    // "今天"前进到 08-17 + tick → todayProvider 刷新 → 图表窗口移动
    fakeToday = DateTime(2026, 8, 17, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MoodTrendPage)),
    );
    container.read(dayChangeTickProvider.notifier).tick();
    await tester.pumpAndSettle();

    expect(
      nonNullSpotCount(tester),
      2,
      reason: 'today=08-17 时 08-17 条目应进入窗口 (2 spot), '
          '图表应随 watch(todayProvider) 自动重算',
    );
  });

  testWidgets('2. MoodReviewPage: 跨周 tick → entriesCount 1 → 0',
      (tester) async {
    // fakeToday = 08-16 (周日): 本周 = 08-10 ~ 08-16, 08-15 条目 → 1 条
    final entries = [_mood(1, DateTime(2026, 8, 15, 18), 4)];
    await tester.pumpWidget(wrapPage(const MoodReviewPage(), entries));
    await tester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget, reason: '08-15 条目在本周窗口内 → 记录天数 1');

    // "今天"前进到下周一 (08-24): 08-15 变上周 → 本周 0 条
    fakeToday = DateTime(2026, 8, 24, 10);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MoodReviewPage)),
    );
    container.read(dayChangeTickProvider.notifier).tick();
    await tester.pumpAndSettle();

    expect(
      find.text('1'),
      findsNothing,
      reason: '跨周后 08-15 条目不再属于本周窗口',
    );
    expect(
      find.text('0'),
      findsOneWidget,
      reason: '本周 0 条 → 记录天数 0 (watch(todayProvider) 自动重算)',
    );
  });

  group('lock-in: 5 处 build 不再 DateTime.now(), 改 watch(todayProvider)', () {
    Future<String> readSrc(String path) => File('lib/$path').readAsString();

    /// 去 `//` 注释后检查 (跟 scripts/check_datetime_race.py 同语义,
    /// 注释里的 DateTime.now() 字面量不算)
    String stripComments(String src) => src.split('\n').map((l) {
          final i = l.indexOf('//');
          return i >= 0 ? l.substring(0, i) : l;
        }).join('\n');

    test('mood_trend_line_chart.dart (R116 god class 拆: watch 移到这里)',
        () async {
      // v1.1.0 R116: mood_trend_page 653L 拆 4 文件, watch(todayProvider)
      // 从主壳移到 widgets/mood_trend_line_chart.dart (MoodLineChart.build
      // 拿 now 算 spots)。主壳 + 3 个 chart widget 都不应再 DateTime.now()。
      final src = await readSrc(
        'presentation/pages/mood_list/widgets/mood_trend_line_chart.dart',
      );
      expect(stripComments(src).contains('DateTime.now()'), isFalse);
      expect(src.contains('ref.watch(todayProvider)'), isTrue);
    });

    test('mood_trend_page.dart (主壳, R116 拆后无 DateTime.now())', () async {
      final src =
          await readSrc('presentation/pages/mood_list/mood_trend_page.dart');
      expect(stripComments(src).contains('DateTime.now()'), isFalse);
    });

    test('mood_distribution_chart.dart (R116 拆: 无需 watch)', () async {
      final src = await readSrc(
        'presentation/pages/mood_list/widgets/mood_distribution_chart.dart',
      );
      expect(stripComments(src).contains('DateTime.now()'), isFalse);
    });

    test('mood_cbt_chart.dart (R116 拆: 无需 watch)', () async {
      final src = await readSrc(
        'presentation/pages/mood_list/widgets/mood_cbt_chart.dart',
      );
      expect(stripComments(src).contains('DateTime.now()'), isFalse);
    });

    test('vent_list_page.dart', () async {
      final src = await readSrc('presentation/pages/vent/vent_list_page.dart');
      expect(stripComments(src).contains('DateTime.now()'), isFalse);
      expect(src.contains('ref.watch(todayProvider)'), isTrue);
    });

    test('daily_tracking_page.dart (_isToday 收 watched now 参数)', () async {
      final src = await readSrc(
        'presentation/pages/daily_tracking/daily_tracking_page.dart',
      );
      expect(stripComments(src).contains('DateTime.now()'), isFalse);
      expect(src.contains('ref.watch(todayProvider)'), isTrue);
      expect(src.contains('_isToday(dynamic entity, DateTime now)'), isTrue);
    });

    test('assessment_center_card.dart (ConsumerWidget)', () async {
      final src = await readSrc(
        'presentation/pages/assessment/widgets/assessment_center_card.dart',
      );
      expect(stripComments(src).contains('DateTime.now()'), isFalse);
      expect(src.contains('ref.watch(todayProvider)'), isTrue);
      expect(src.contains('extends ConsumerWidget'), isTrue);
    });

    test('mood_review_page.dart (widget.now ?? watch(todayProvider))',
        () async {
      final src =
          await readSrc('presentation/pages/mood_list/mood_review_page.dart');
      expect(src.contains('widget.now ?? ref.watch(todayProvider)!'), isTrue);
    });
  });
}
