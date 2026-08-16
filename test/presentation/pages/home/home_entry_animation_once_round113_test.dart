// R113 Wave 7 (Task A): 主页入场动画只在首次 mount 播放 — 回归测试
//
// 修前: ShellRoute 每次切 tab 会 dispose/recreate HomePage, 入场动画
// (FadeIn durSlow 400ms + stagger 30/60ms + CheckInButton _EntrySpring
// ~0.4s) 每次切回主页都重放 ~650ms。
// 修后: homeEntryPlayedProvider (进程级, 挂根 ProviderScope) 在首次 mount
// postFrame 标记 true; 后续 mount FadeIn duration/delay = Duration.zero
// (直接终态) + CheckInButton animateEntry=false (_EntrySpring 跳到 1.0)。
// 首次启动仍完整播放入场 (首启动自然体验保留)。
//
// 测试策略 (复用 home_checkin_failure_round113_test 的 override harness):
// - ProviderScope overrides 全套 home 依赖 + GoRouter
// - go('/away') → go('/') 模拟 tab 切换 (同 container, HomePage 重新
//   mount, 等价 ShellRoute 分支页重建)
// - 断言用 widget 配置值 (Opacity.opacity / Transform.scale /
//   FadeIn.duration), 不受路由 transition 渲染层影响

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/domain/entities/worry_thread_entity.dart';
import 'package:chroniccare/domain/repositories/check_in_repository.dart';
import 'package:chroniccare/domain/repositories/user_profile_repository.dart';
import 'package:chroniccare/domain/usecases/check_in_usecases.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/home/home_page.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_header.dart';
import 'package:chroniccare/presentation/providers/check_in_notifier.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/presentation/providers/worry_providers.dart';
import 'package:chroniccare/presentation/widgets/animations/fade_in.dart';
import 'package:chroniccare/presentation/widgets/check_in_button.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

class _NoopCheckInRepo implements CheckInRepository {
  @override
  Stream<List<CheckInEntity>> watchAll() => const Stream.empty();
  @override
  Stream<List<CheckInEntity>> watchAssessments() => const Stream.empty();
  @override
  Stream<CheckInEntity?> watchToday() => const Stream.empty();
  @override
  Stream<List<CheckInEntity>> watchTodayAll() => const Stream.empty();
  @override
  Stream<List<CheckInEntity>> watchNormalCheckIns() => const Stream.empty();
  @override
  Future<CheckInEntity?> getLatestNormalCheckIn() async => null;
  @override
  Future<DateTime?> getLatestAssessmentTimestamp() async => null;
  @override
  Future<int> checkIn({DateTime? at, int? medicationId}) async => 1;
  @override
  Future<int> addTempMedication({
    required String name,
    required String note,
    DateTime? at,
  }) async =>
      1;
  @override
  Future<int> saveAssessment({
    required String scale,
    required List<int> scores,
    required int total,
    DateTime? at,
  }) async =>
      1;
}

class _NoopProfileRepo implements UserProfileRepository {
  @override
  Stream<UserProfileEntity?> watch() => const Stream.empty();
  @override
  Future<UserProfileEntity?> get() async => null;
  @override
  Future<void> save({String? userName, int checkInCycleHours = 48}) async {}
  @override
  Future<void> updateLastCheckIn(DateTime time) async {}
  @override
  Future<void> recordConsent({
    required String userAgreementVersion,
    required String privacyPolicyVersion,
  }) async {}
  @override
  Future<void> withdrawConsent() async {}
  @override
  Future<void> resetConsent() async {}
}

class _OkCheckInUseCase extends RecordCheckInUseCase {
  _OkCheckInUseCase() : super(_NoopCheckInRepo(), _NoopProfileRepo());
}

GoRouter makeRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/away',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('away-tab'))),
      ),
    ],
  );
}

Widget wrapHomeApp(GoRouter router) {
  return ProviderScope(
    overrides: [
      recordCheckInUseCaseProvider.overrideWithValue(_OkCheckInUseCase()),
      latestMoodProvider.overrideWith(
        (ref) => Stream<MoodEntryEntity?>.value(null),
      ),
      ventEntriesProvider.overrideWith(
        (ref) => Stream<List<VentEntryEntity>>.value(const []),
      ),
      todayCheckInProvider.overrideWith(
        (ref) => Stream<CheckInEntity?>.value(null),
      ),
      userProfileProvider.overrideWith(
        (ref) => Stream<UserProfileEntity?>.value(null),
      ),
      todayAllCheckInsProvider.overrideWith(
        (ref) => Stream<List<CheckInEntity>>.value(const []),
      ),
      medicationsProvider.overrideWith(
        (ref) => Stream<List<MedicationEntity>>.value(const []),
      ),
      streakSummaryProvider.overrideWith(
        (ref) => const AsyncValue.data(
          StreakSnapshot(streak: 0, shouldShowStreakBroken: false),
        ),
      ),
      // v1.1.0 round 11 (R115): TodaySummaryCard 新增 provider override
      sleepEntriesProvider.overrideWith(
        (ref) => Stream<List<SleepEntryEntity>>.value(const []),
      ),
      worryOpenProvider.overrideWith(
        (ref) => Stream<List<WorryThreadEntity>>.value(const []),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// HomeHeader 外层 FadeIn 的 Opacity (FadeIn 直接包 HomeHeader,
/// 最近祖先 Opacity 即入场 Opacity)
double headerFadeOpacity(WidgetTester tester) {
  return tester
      .widget<Opacity>(
        find
            .ancestor(
              of: find.byType(HomeHeader),
              matching: find.byType(Opacity),
            )
            .first,
      )
      .opacity;
}

/// CheckInButton 内 _EntrySpring 的 Opacity (最近祖先 Opacity of
/// PressFeedback — 入场 spring 直接包 PressFeedback)
double entrySpringOpacity(WidgetTester tester) {
  return tester
      .widget<Opacity>(
        find
            .ancestor(
              of: find.descendant(
                of: find.byType(CheckInButton),
                matching: find.byType(PressFeedback),
              ),
              matching: find.byType(Opacity),
            )
            .first,
      )
      .opacity;
}

/// CheckInButton 内 _EntrySpring 的 scale (最近祖先 Transform of
/// PressFeedback; AnimatedSwitcher 稳定态不建 ScaleTransition)。
/// 读 entry(0,0) — Transform.scale 的 z 轴恒 1.0, getMaxScaleOnAxis 会
/// 误报 1.0。
double entrySpringScale(WidgetTester tester) {
  return tester
      .widget<Transform>(
        find
            .ancestor(
              of: find.descendant(
                of: find.byType(CheckInButton),
                matching: find.byType(PressFeedback),
              ),
              matching: find.byType(Transform),
            )
            .first,
      )
      .transform
      .entry(0, 0);
}

void main() {
  testWidgets('1. 首次 mount: 入场动画从初始态开始播 (首启动自然体验保留)', (tester) async {
    await tester.pumpWidget(wrapHomeApp(makeRouter()));

    // 第一帧: FadeIn opacity 0 / spring scale 0.95 — 动画在播
    expect(
      headerFadeOpacity(tester),
      0.0,
      reason: '首次 mount 第一帧 FadeIn 应从 opacity 0 开始',
    );
    expect(
      entrySpringScale(tester),
      closeTo(0.95, 0.001),
      reason: '首次 mount 第一帧 _EntrySpring 应从 scale 0.95 开始',
    );
    expect(
      entrySpringOpacity(tester),
      0.0,
      reason: '首次 mount 第一帧 _EntrySpring opacity 应从 0 开始',
    );

    // 自然播完 → 全部终态
    await tester.pumpAndSettle();
    expect(headerFadeOpacity(tester), 1.0);
    expect(entrySpringScale(tester), closeTo(1.0, 0.001));
    expect(entrySpringOpacity(tester), 1.0);
  });

  testWidgets('2. 第二次 mount (tab 切回): FadeIn/stagger/spring 直接终态不重播',
      (tester) async {
    final router = makeRouter();
    await tester.pumpWidget(wrapHomeApp(router));
    await tester.pumpAndSettle();

    // 切到别的 tab (等价 ShellRoute 分支切换)
    router.go('/away');
    await tester.pumpAndSettle();
    expect(find.text('away-tab'), findsOneWidget);

    // 切回主页 → HomePage 重新 mount
    router.go('/');
    await tester.pump();
    await tester.pump();

    // FadeIn 配置: duration + delay 都是 zero (stagger 也跳过)
    final headerFade = tester.widget<FadeIn>(
      find.ancestor(of: find.byType(HomeHeader), matching: find.byType(FadeIn)),
    );
    expect(
      headerFade.duration,
      Duration.zero,
      reason: '第二次 mount FadeIn duration 应 = zero (直接终态)',
    );
    expect(
      headerFade.delay,
      Duration.zero,
      reason: '第二次 mount FadeIn delay 应 = zero (无 stagger)',
    );

    // 第一帧即在终态: opacity 1.0 / scale 1.0 (无重播)
    expect(
      headerFadeOpacity(tester),
      1.0,
      reason: '第二次 mount 第一帧 FadeIn 应已在终态 (opacity 1.0)',
    );
    expect(
      entrySpringScale(tester),
      closeTo(1.0, 0.001),
      reason: '第二次 mount 第一帧 _EntrySpring 应已在终态 (scale 1.0)',
    );
    expect(
      entrySpringOpacity(tester),
      1.0,
      reason: '第二次 mount 第一帧 _EntrySpring 应已在终态 (opacity 1.0)',
    );

    // 进程级标记已翻转 (首 mount 后)
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomePage)),
    );
    expect(
      container.read(homeEntryPlayedProvider),
      isTrue,
      reason: '首 mount 后 homeEntryPlayedProvider 应已标记 true',
    );
  });

  testWidgets('3. 第三次 mount 仍跳过 (幂等, 无状态泄漏)', (tester) async {
    final router = makeRouter();
    await tester.pumpWidget(wrapHomeApp(router));
    await tester.pumpAndSettle();

    router.go('/away');
    await tester.pumpAndSettle();
    router.go('/');
    await tester.pumpAndSettle();
    router.go('/away');
    await tester.pumpAndSettle();
    router.go('/');
    await tester.pump();
    await tester.pump();

    expect(headerFadeOpacity(tester), 1.0, reason: '第三次 mount 第一帧仍应直接终态');
    expect(entrySpringScale(tester), closeTo(1.0, 0.001));
    expect(entrySpringOpacity(tester), 1.0);
  });
}
