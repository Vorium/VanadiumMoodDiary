// trend_event_row_round95_test.dart — R95 sub-spec 4 task 6 EventRow widget test
//
// 覆盖:
// 1. checkIn normal event → check_circle icon + primary color + time "08:30" + 标题
// 2. checkIn temp event → healing_outlined icon + warning color
// 3. mood event with score 4 → mood_outlined icon + mood color
// 4. kindVisuals() 静态方法返回 4 种 kind 各自的正确 icon/color
// 5. event.subtitle 非空时显示, 空时不显示
//
// v0.30 round 95 (sub-spec 4 task 6): EventRow 从 trend_calendar.dart 拆出后,
// 改成 public, 加 widget test 锁住:
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/logic/day_detail.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/trend/widgets/trend_event_row.dart';

void main() {
  group('EventRow widget (R95 sub-spec 4 task 6 拆解)', () {
    Widget wrap(Widget child) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('zh'),
          home: Scaffold(body: child),
        );

    testWidgets('checkIn normal event 渲染 check_circle + primary + 标题',
        (tester) async {
      final event = DayEvent(
        kind: DayEventKind.checkInNormal,
        time: DateTime(2026, 8, 6, 8, 30),
        title: '利培酮 2mg',
        subtitle: '08:30 / 1 片',
      );
      await tester.pumpWidget(wrap(EventRow(event: event)));
      // time col 显示 "08:30"
      expect(find.text('08:30'), findsOneWidget);
      // title 显示
      expect(find.text('利培酮 2mg'), findsOneWidget);
      // subtitle 显示
      expect(find.text('08:30 / 1 片'), findsOneWidget);
      // check_circle icon
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('checkIn temp event 渲染 healing_outlined + warning color',
        (tester) async {
      final event = DayEvent(
        kind: DayEventKind.checkInTemp,
        time: DateTime(2026, 8, 6, 14, 15),
        title: '临时用药: 阿普唑仑',
      );
      await tester.pumpWidget(wrap(EventRow(event: event)));
      expect(find.text('14:15'), findsOneWidget);
      expect(find.text('临时用药: 阿普唑仑'), findsOneWidget);
      expect(find.byIcon(Icons.healing_outlined), findsOneWidget);
    });

    testWidgets('mood event 渲染 mood_outlined + mood score', (tester) async {
      final event = DayEvent(
        kind: DayEventKind.mood,
        time: DateTime(2026, 8, 6, 20, 0),
        title: '心情: 4',
        moodScore: 4,
      );
      await tester.pumpWidget(wrap(EventRow(event: event)));
      expect(find.text('20:00'), findsOneWidget);
      expect(find.text('心情: 4'), findsOneWidget);
      expect(find.byIcon(Icons.mood_outlined), findsOneWidget);
    });

    testWidgets('assessment event 渲染 psychology_outlined + tertiary color',
        (tester) async {
      final event = DayEvent(
        kind: DayEventKind.assessment,
        time: DateTime(2026, 8, 6, 10, 0),
        title: 'PHQ-9',
        subtitle: '12 / 27',
      );
      await tester.pumpWidget(wrap(EventRow(event: event)));
      expect(find.text('10:00'), findsOneWidget);
      expect(find.text('PHQ-9'), findsOneWidget);
      expect(find.text('12 / 27'), findsOneWidget);
      expect(find.byIcon(Icons.psychology_outlined), findsOneWidget);
    });

    testWidgets('event.subtitle 空时只显示标题不显示 subtitle 行', (tester) async {
      final event = DayEvent(
        kind: DayEventKind.checkInNormal,
        time: DateTime(2026, 8, 6, 8, 30),
        title: '利培酮 2mg',
        subtitle: null,
      );
      await tester.pumpWidget(wrap(EventRow(event: event)));
      expect(find.text('利培酮 2mg'), findsOneWidget);
    });

    test('kindVisuals() 4 kind 返回正确 icon/颜色映射', () {
      // 构造 dummy BuildContext 用 ThemeData
      final context = _TestContext();
      // checkIn normal
      var (icon, _, _) = EventRow.kindVisuals(
        DayEvent(
          kind: DayEventKind.checkInNormal,
          time: DateTime(2026, 8, 6, 8, 30),
          title: 'x',
        ),
        context,
      );
      expect(icon, Icons.check_circle);
      // checkIn temp
      (icon, _, _) = EventRow.kindVisuals(
        DayEvent(
          kind: DayEventKind.checkInTemp,
          time: DateTime(2026, 8, 6, 8, 30),
          title: 'x',
        ),
        context,
      );
      expect(icon, Icons.healing_outlined);
      // assessment
      (icon, _, _) = EventRow.kindVisuals(
        DayEvent(
          kind: DayEventKind.assessment,
          time: DateTime(2026, 8, 6, 8, 30),
          title: 'x',
        ),
        context,
      );
      expect(icon, Icons.psychology_outlined);
      // mood
      (icon, _, _) = EventRow.kindVisuals(
        DayEvent(
          kind: DayEventKind.mood,
          time: DateTime(2026, 8, 6, 8, 30),
          title: 'x',
          moodScore: 3,
        ),
        context,
      );
      expect(icon, Icons.mood_outlined);
    });
  });
}

/// Test stub: 给 kindVisuals() 一个 minimal BuildContext
///
/// kindVisuals 内部只读 Theme.of(context).colorScheme.tertiary (assessment 分支),
/// 其它分支用 AppTokens / MoodVisual 集中器 (不读 Theme)。所以 dummy BuildContext
/// 足够让 4 个 case 都跑通。
class _TestContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
