// R113 (BUG 2): 打卡失败仍弹成功庆祝 — 回归测试
//
// 修前: _onCheckIn await checkIn() 后无条件 _celebration.show(...),
//   checkIn 用 AsyncValue.guard 把异常吞进 state → 用户同时看到
//   错误 snackbar + 成功庆祝 + streak+1 文案。
// 修后: 打卡失败 → 只有错误 snackbar, 0 庆祝 overlay / 0 streak 文案。
//
// 测试策略: pump 完整 HomePage + ProviderScope overrides,
//   recordCheckInUseCaseProvider 注入抛异常 use case → tap CheckInButton。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/domain/repositories/check_in_repository.dart';
import 'package:chroniccare/domain/repositories/user_profile_repository.dart';
import 'package:chroniccare/domain/usecases/check_in_usecases.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/home/home_page.dart';
import 'package:chroniccare/presentation/providers/check_in_notifier.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/presentation/widgets/animations/celebration_bounce.dart';
import 'package:chroniccare/presentation/widgets/check_in_button.dart';

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

/// 打卡必失败 (模拟 DB 写入失败)
class _FailingCheckInUseCase extends RecordCheckInUseCase {
  _FailingCheckInUseCase() : super(_NoopCheckInRepo(), _NoopProfileRepo());

  @override
  Future<int> call({int? medicationId, DateTime? at}) async {
    throw Exception('db write failed');
  }
}

/// 打卡成功 (baseline, 验证成功路径仍弹庆祝 — 防过度修复)
class _OkCheckInUseCase extends RecordCheckInUseCase {
  _OkCheckInUseCase() : super(_NoopCheckInRepo(), _NoopProfileRepo());
}

Widget wrapHome(RecordCheckInUseCase useCase) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
    ],
  );
  return ProviderScope(
    overrides: [
      recordCheckInUseCaseProvider.overrideWithValue(useCase),
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
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('打卡失败 → 无庆祝 overlay + 无 streak 文案 + 有错误 snackbar',
      (tester) async {
    await tester.pumpWidget(wrapHome(_FailingCheckInUseCase()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckInButton));
    await tester.pumpAndSettle();

    expect(
      find.byType(CelebrationBounce),
      findsNothing,
      reason: '打卡失败不应弹成功庆祝 overlay',
    );
    expect(
      find.text('已记录！第 1 天 🌱'),
      findsNothing,
      reason: '打卡失败不应显示 streak+1 庆祝文案',
    );
    expect(
      find.textContaining('失败'),
      findsOneWidget,
      reason: '应保留错误 snackbar (ref.listen 路径)',
    );
  });

  testWidgets('打卡成功 → 庆祝 overlay 仍正常 (回归守卫, 防过度修复)', (tester) async {
    await tester.pumpWidget(wrapHome(_OkCheckInUseCase()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CheckInButton));
    await tester.pumpAndSettle();

    expect(
      find.byType(CelebrationBounce),
      findsOneWidget,
      reason: '打卡成功仍应弹庆祝 (BUG 2 只修失败路径)',
    );
    expect(find.text('已记录！第 1 天 🌱'), findsOneWidget);
  });
}
