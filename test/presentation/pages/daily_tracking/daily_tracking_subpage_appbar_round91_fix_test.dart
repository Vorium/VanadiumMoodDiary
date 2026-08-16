// v0.30 round 91 (sub-spec 7 日常追踪 / Fix Round 1): I-1 + I-2 regression 测试
//
// Final review 2 Important fix:
// - I-1: 主页 FAB label "全部趋势" 跟 /daily-tracking 整合入口页语义不匹配
//        → 改 dailyTrackingFab = "日常追踪" / "Daily Tracking" / "日常追蹤"
//        (跟 l10n.dailyTrackingTitle 一致)
// - I-2: 7 子页面 AppBar title 硬编码中文 (非 l10n)
//        → 6 子 widget 自己用 PageScaffold(title: l10n.xxxName, ...) 包
//        (跟 R87 MoodListPage 同 pattern), 路由 file 去掉 PageScaffold wrapper
//        → /mood-diary 路由去 wrapper, MoodListPage 已自带 PageScaffold
//
// 覆盖 (TDD red→green):
// 1. I-1: l10n.dailyTrackingFab 3 lang 值 (unit test, no widget)
// 2. I-2: 6 sub-widgets 在 en locale 下, AppBar 显示 English name (不显示 Chinese)
// 3. I-2: /mood-diary 走 MoodListPage 自带 PageScaffold, en locale 显示
//    "Mood history" (l10n.moodListPageTitle — R87 已用)
//
// 4 层架构: test 只引 flutter test + l10n + presentation widgets + 同
// presentation providers, 0 跨 feature import.
//
// R97-P1-12 (2026-08-07): close_sinks 误报 — 6 个 _FakeXxxRepo 的 _ctrl 字段
// 在 tearDown → repos.close() 里统一 .close(), 但 analyzer 无法跨 _FakeRepos
// 间接层追踪到。close 模式已 verify (tearDown line 221-223)。
// ignore_for_file: close_sinks
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/data/repositories/daily_tracking/anxiety_agitation_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/sleep_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/social_rhythm_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/stress_event_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/treatment_repository_impl.dart';
import 'package:chroniccare/core/data/repositories/daily_tracking/weight_repository_impl.dart';
import 'package:chroniccare/domain/entities/anxiety_agitation_entry.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/domain/entities/social_rhythm_entry.dart';
import 'package:chroniccare/domain/entities/stress_event.dart';
import 'package:chroniccare/domain/entities/treatment_entry.dart';
import 'package:chroniccare/domain/entities/weight_entry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/app_localizations_en.dart';
import 'package:chroniccare/l10n/app_localizations_zh.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/treatment_page.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/anxiety_agitation_widgets.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/sleep_widgets.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/social_rhythm_widgets.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/stress_event_widgets.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/weight_widgets.dart';
import 'package:chroniccare/presentation/pages/mood_list/mood_list_page.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/providers/worry_providers.dart';

/// Fake repo 集合: 6 sub-feature 共享 (StreamController + 空 entries, 跟 R91
/// sleep/social_rhythm 等 5 widget test 同款 pattern, 避免 StreamProvider 跟
/// drift 联动挂起). tearDown 统一 close.
class _FakeRepos {
  final sleep = _FakeSleepRepo();
  final socialRhythm = _FakeSocialRhythmRepo();
  final stressEvent = _FakeStressEventRepo();
  final weight = _FakeWeightRepo();
  final anxiety = _FakeAnxietyAgitationRepo();
  final treatment = _FakeTreatmentRepo();

  Future<void> close() async {
    await sleep._ctrl.close();
    await socialRhythm._ctrl.close();
    await stressEvent._ctrl.close();
    await weight._ctrl.close();
    await anxiety._ctrl.close();
    await treatment._ctrl.close();
  }
}

class _FakeSleepRepo implements SleepRepositoryImpl {
  final _ctrl = StreamController<List<SleepEntryEntity>>.broadcast();
  @override
  Stream<List<SleepEntryEntity>> watchAll() async* {
    yield const [];
    yield* _ctrl.stream;
  }

  @override
  Future<int> add({
    required DateTime date,
    required DateTime bedtime,
    required DateTime wakeTime,
    required int durationMin,
    int? regularityScore,
    String? note,
  }) async =>
      1;
  @override
  Future<int> delete(int id) async => 1;
}

class _FakeSocialRhythmRepo implements SocialRhythmRepositoryImpl {
  final _ctrl = StreamController<List<SocialRhythmEntryEntity>>.broadcast();
  @override
  Stream<List<SocialRhythmEntryEntity>> watchAll() async* {
    yield const [];
    yield* _ctrl.stream;
  }

  @override
  Future<int> add({
    required DateTime date,
    required DateTime wakeTime,
    required DateTime firstMealTime,
    required DateTime lastMealTime,
    int socialMin = 0,
    int workMin = 0,
    int exerciseMin = 0,
  }) async =>
      1;
  @override
  Future<int> delete(int id) async => 1;
}

class _FakeStressEventRepo implements StressEventRepositoryImpl {
  final _ctrl = StreamController<List<StressEventEntity>>.broadcast();
  @override
  Stream<List<StressEventEntity>> watchAll() async* {
    yield const [];
    yield* _ctrl.stream;
  }

  @override
  Future<int> add({
    required DateTime timestamp,
    required String eventType,
    required int intensity,
    String? note,
    int? linkedMoodEntryId,
  }) async =>
      1;
  @override
  Future<int> delete(int id) async => 1;
}

class _FakeWeightRepo implements WeightRepositoryImpl {
  final _ctrl = StreamController<List<WeightEntryEntity>>.broadcast();
  @override
  Stream<List<WeightEntryEntity>> watchAll() async* {
    yield const [];
    yield* _ctrl.stream;
  }

  @override
  Future<int> add({
    required DateTime timestamp,
    required double weightKg,
    double? bmi,
    String? note,
  }) async =>
      1;
  @override
  Future<int> delete(int id) async => 1;
}

class _FakeAnxietyAgitationRepo implements AnxietyAgitationRepositoryImpl {
  final _ctrl = StreamController<List<AnxietyAgitationEntryEntity>>.broadcast();
  @override
  Stream<List<AnxietyAgitationEntryEntity>> watchAll() async* {
    yield const [];
    yield* _ctrl.stream;
  }

  @override
  Future<int> add({
    required DateTime timestamp,
    required int anxietyScore,
    required int agitationScore,
    String? note,
  }) async =>
      1;
  @override
  Future<int> delete(int id) async => 1;
}

class _FakeTreatmentRepo implements TreatmentRepositoryImpl {
  final _ctrl = StreamController<List<TreatmentEntryEntity>>.broadcast();
  @override
  Stream<List<TreatmentEntryEntity>> watchAll() async* {
    yield const [];
    yield* _ctrl.stream;
  }

  @override
  Future<int> add({
    required DateTime timestamp,
    required String treatmentType,
    required String description,
    int? linkedMedicationId,
    String? linkedMedicationName,
    String? note,
  }) async =>
      1;
  @override
  Future<int> submitEntry({
    required String treatmentType,
    required String description,
    int? linkedMedicationId,
    String? note,
  }) async =>
      1;
  @override
  Future<int> delete(int id) async => 1;
}

void main() {
  // ============== I-1: l10n.dailyTrackingFab 3 lang 值 ==============
  group('I-1: l10n.dailyTrackingFab 3 lang 值', () {
    test('zh: "日常追踪" (跟 l10n.dailyTrackingTitle 一致)', () {
      expect(
        AppLocalizationsZh().dailyTrackingFab,
        '日常追踪',
        reason: 'FAB label 必须跟 /daily-tracking 整合入口页 title 语义一致',
      );
    });
    test('en: "Daily Tracking"', () {
      expect(
        AppLocalizationsEn().dailyTrackingFab,
        'Daily Tracking',
        reason: 'FAB label 英文跟 dailyTrackingTitle 保持一致',
      );
    });
    test('zh_Hant: "日常追蹤"', () {
      expect(
        AppLocalizationsZhHant().dailyTrackingFab,
        '日常追蹤',
        reason: 'FAB label 繁体跟 dailyTrackingTitle 保持一致',
      );
    });
  });

  // ============== I-2: 6 sub-widgets AppBar title 走 l10n ==============
  group('I-2: 6 sub-widgets AppBar title 走 l10n (en locale)', () {
    late _FakeRepos repos;

    setUp(() {
      repos = _FakeRepos();
    });

    tearDown(() async {
      await repos.close();
    });

    Future<void> pump(
      WidgetTester tester,
      Widget child,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sleepRepositoryProvider.overrideWithValue(repos.sleep),
            socialRhythmRepositoryProvider
                .overrideWithValue(repos.socialRhythm),
            stressEventRepositoryProvider.overrideWithValue(repos.stressEvent),
            weightRepositoryProvider.overrideWithValue(repos.weight),
            anxietyAgitationRepositoryProvider.overrideWithValue(repos.anxiety),
            treatmentRepositoryProvider.overrideWithValue(repos.treatment),
            // R114 B1-7: MoodListPage 直接 watch allMoodProvider —
            // override 真源 Stream (修前 override moodEntriesProvider sync 包装)
            allMoodProvider
                .overrideWith((ref) => Stream.value(const <MoodEntryEntity>[])),
            // v1.1.0 round 9 (F1): MoodListPage 内嵌 WorrySection
            worryOpenProvider.overrideWith((ref) => Stream.value(const [])),
            worryResolvedProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: child,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('SleepListWidget → AppBar title "Sleep"', (tester) async {
      await pump(tester, const SleepListWidget());
      expect(
        find.text('Sleep'),
        findsOneWidget,
        reason: 'SleepListWidget AppBar title 必须走 l10n.sleepName = "Sleep"',
      );
      // 同时验证不显示硬编码中文 "睡眠"
      expect(
        find.text('睡眠'),
        findsNothing,
        reason: '切到 en locale 后, AppBar 不应再显示硬编码中文',
      );
    });

    testWidgets('SocialRhythmListWidget → AppBar title "Social Rhythm"',
        (tester) async {
      await pump(tester, const SocialRhythmListWidget());
      expect(
        find.text('Social Rhythm'),
        findsOneWidget,
        reason: 'SocialRhythmListWidget AppBar title 走 l10n.socialRhythmName',
      );
      expect(find.text('社会节律'), findsNothing);
    });

    testWidgets('StressEventListWidget → AppBar title "Stress Events"',
        (tester) async {
      await pump(tester, const StressEventListWidget());
      expect(
        find.text('Stress Events'),
        findsOneWidget,
        reason: 'StressEventListWidget AppBar title 走 l10n.stressEventName',
      );
      expect(find.text('应激源'), findsNothing);
    });

    testWidgets('WeightListWidget → AppBar title "Weight"', (tester) async {
      await pump(tester, const WeightListWidget());
      expect(
        find.text('Weight'),
        findsOneWidget,
        reason: 'WeightListWidget AppBar title 走 l10n.weightName',
      );
      expect(find.text('体重'), findsNothing);
    });

    testWidgets(
        'AnxietyAgitationListWidget → AppBar title "Anxiety & Agitation"',
        (tester) async {
      await pump(tester, const AnxietyAgitationListWidget());
      expect(
        find.text('Anxiety & Agitation'),
        findsOneWidget,
        reason:
            'AnxietyAgitationListWidget AppBar title 走 l10n.anxietyAgitationName',
      );
      expect(find.text('焦虑急躁'), findsNothing);
    });

    testWidgets('TreatmentPage → AppBar title "Treatment"', (tester) async {
      // v0.30 round 92 (audit-fixes / P0 #15): TreatmentPlaceholderPage
      // 替换为 TreatmentPage (4 字段 AddTreatmentDialog + 真 page)。
      await pump(tester, const TreatmentPage());
      expect(
        find.text('Treatment'),
        findsOneWidget,
        reason: 'TreatmentPage AppBar title 走 l10n.treatmentName',
      );
      expect(find.text('治疗'), findsNothing);
    });

    testWidgets('MoodListPage (复用 /mood-diary) → AppBar title "Mood history"',
        (tester) async {
      // /mood-diary 走 MoodListPage (R87 已加 PageScaffold(title: l10n.moodListPageTitle))
      // 这里测试 en locale 下不显示硬编码 "情绪日记" (来自 /mood-diary 旧路由 wrapper)
      await pump(tester, const MoodListPage());
      expect(
        find.text('Mood history'),
        findsOneWidget,
        reason: 'MoodListPage AppBar title 走 l10n.moodListPageTitle',
      );
      expect(
        find.text('情绪日记'),
        findsNothing,
        reason: 'en locale 下 MoodListPage 不应显示硬编码中文 "情绪日记"',
      );
    });
  });
}
