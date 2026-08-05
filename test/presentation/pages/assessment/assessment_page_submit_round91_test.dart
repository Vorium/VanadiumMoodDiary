// v0.30 round 91 (fix): AssessmentPage._submit 走 R90 submitEntry 回归测试
//
// final review C3 fix: `assessment_page._submit` 调 R60 老 `saveAssessment`,
// R90 新 `AssessmentRepository.submitEntry` 是 dead code, 新 8 量表数据
// 走 R60 路径写入, R90 reader 解不出 score / answers。
//
// 修法: 改 `assessment_page._submit` 调 `assessmentRepositoryProvider.submitEntry`,
// 走 R90 JSON 格式。
//
// TDD red→green: 本文件先写 (看 fail: submitEntry 没被调用),
// 然后改 `assessment_page.dart`, 再跑 (看 pass: 被调用, 参数正确)。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/data/repositories/assessment/assessment_repository_impl.dart';
import 'package:chroniccare/domain/entities/assessment_entry.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/repositories/check_in_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_page.dart';
import 'package:chroniccare/presentation/providers/assessment_providers.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';

/// 跟踪 R90 submitEntry 调用的假 AssessmentRepository
class _TrackingAssessmentRepository implements AssessmentRepository {
  final List<
      ({
        String scaleId,
        int score,
        int severityRank,
        List<int> answers,
        String? note,
      })> submitted = [];

  @override
  Future<int> submitEntry({
    required String scaleId,
    required int score,
    required int severityRank,
    required List<int> answers,
    String? note,
  }) async {
    submitted.add((
      scaleId: scaleId,
      score: score,
      severityRank: severityRank,
      answers: List<int>.from(answers),
      note: note,
    ),);
    return submitted.length;
  }

  @override
  Future<AssessmentEntry?> getLatest(String scaleId) async => null;

  @override
  Future<Map<String, int>> countByScale() async => {};

  @override
  Stream<List<AssessmentEntry>> watchAll() =>
      const Stream<List<AssessmentEntry>>.empty();

  @override
  Stream<List<AssessmentEntry>> watchByScale(String scaleId) =>
      const Stream<List<AssessmentEntry>>.empty();
}

/// 假 CheckInRepository — 任何 R60 路径被调就 throw,防止回归到 R60
class _StrictCheckInRepository implements CheckInRepository {
  @override
  Future<int> saveAssessment({
    required String scale,
    required List<int> scores,
    required int total,
    DateTime? at,
  }) async {
    throw StateError(
        'R60 saveAssessment MUST NOT be called after round 91 fix. '
        'Call AssessmentRepository.submitEntry instead.');
  }

  @override
  Stream<List<CheckInEntity>> watchAll() => const Stream<List<CheckInEntity>>.empty();

  @override
  Stream<List<CheckInEntity>> watchAssessments() =>
      const Stream<List<CheckInEntity>>.empty();

  @override
  Stream<CheckInEntity?> watchToday() => Stream<CheckInEntity?>.value(null);

  @override
  Stream<List<CheckInEntity>> watchNormalCheckIns() =>
      const Stream<List<CheckInEntity>>.empty();

  @override
  Future<CheckInEntity?> getLatestNormalCheckIn() async => null;

  @override
  Future<DateTime?> getLatestAssessmentTimestamp() async => null;

  @override
  Future<int> checkIn({DateTime? at, int? medicationId}) async {
    throw UnimplementedError();
  }

  @override
  Future<int> addTempMedication({
    required String name,
    required String note,
    DateTime? at,
  }) async {
    throw UnimplementedError();
  }
}

void main() {
  Widget wrapPage({
    required _TrackingAssessmentRepository assessmentRepo,
  }) {
    return ProviderScope(
      overrides: [
        assessmentRepositoryProvider.overrideWithValue(assessmentRepo),
        // R60 老 saveAssessment 路径如果被调到,会 throw (见上 _StrictCheckInRepository)
        checkInRepositoryProvider.overrideWithValue(_StrictCheckInRepository()),
        // assessmentsProvider → 空流 (不渲染历史)
        assessmentsProvider
            .overrideWith((ref) => const Stream<List<CheckInEntity>>.empty()),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        routerConfig: GoRouter(
          initialLocation: '/assessment/phq9',
          routes: [
            GoRoute(
              path: '/assessment/:id',
              builder: (context, state) =>
                  AssessmentPage(scaleId: state.pathParameters['id']!),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets(
      'C3 fix: PHQ-9 提交后, R90 AssessmentRepository.submitEntry 被调用, R60 saveAssessment 不被调',
      (tester) async {
    // v0.30 round 91 fix: 评估页用 ListView.builder (lazy), 9 题不全在 viewport 内
    // → 用大 viewport 让所有 36 个 chip 一次可见
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final trackingRepo = _TrackingAssessmentRepository();
    await tester.pumpWidget(wrapPage(assessmentRepo: trackingRepo));
    await tester.pumpAndSettle();

    // PHQ-9 有 9 题, 4 个选项 (0=完全不会, 1=几天, 2=一半以上, 3=几乎每天)。
    // 选每题 0 (第 1 个选项 = 完全不会) → total=0, severityRank=0
    //
    // 找到所有 ChoiceChip, 顺序: 每题 4 chip, 共 36 chip
    // 简单做法: 每题点第 1 个 chip (index 0, 4, 8, ..., 32)
    final chips = find.byType(ChoiceChip);
    expect(chips, findsNWidgets(36),
        reason: 'PHQ-9 = 9 题 × 4 选项 = 36 个 ChoiceChip',);

    for (var i = 0; i < 9; i++) {
      await tester.tap(chips.at(i * 4), warnIfMissed: false);
      await tester.pump();
    }

    // 找提交按钮 (PrimaryButton, 文本 "提交并查看结果")
    final submitButton = find.text('提交并查看结果');
    expect(submitButton, findsOneWidget);
    await tester.tap(submitButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    // 验证: R90 submitEntry 被调用 1 次
    expect(trackingRepo.submitted.length, 1,
        reason: 'R90 AssessmentRepository.submitEntry 必须被调用 1 次',);
    final call = trackingRepo.submitted.first;
    expect(call.scaleId, 'phq9');
    expect(call.score, 0);
    expect(call.severityRank, 0);
    expect(call.answers, [0, 0, 0, 0, 0, 0, 0, 0, 0]);
  });
}
