// v0.30 round 90 (sub-spec 6 量表中心): AssessmentDao + AssessmentRepository 测试
//
// 覆盖 (TDD red→green):
// 1. watchAllAssessmentEntries 跨 10 type 聚合
// 2. getLatestEntryByType 拿最新 entry
// 3. countByType 统计每量表提交次数
// 4. submitEntry(unavailable scale) → 抛 StateError
// 5. submitEntry(unknown scale) → 抛 ArgumentError
// 6. 老格式 free text note 兜底 (R60 legacy data 兼容)

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/daos/assessment_dao.dart';
import 'package:chroniccare/core/data/repositories/assessment/assessment_repository_impl.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AssessmentDao dao;
  late AssessmentRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.assessmentDao;
    repo = AssessmentRepository(db, dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('watchAllAssessmentEntries 跨 10 量表聚合', () {
    test('提交 3 个不同量表 entry → watchAll 返 3 条, scaleId 集合正确', () async {
      await repo.submitEntry(
        scaleId: 'phq9',
        score: 12,
        severityRank: 2,
        answers: [1, 2, 3, 0, 1, 2, 3, 0, 0],
      );
      await repo.submitEntry(
        scaleId: 'whodas',
        score: 24,
        severityRank: 2,
        answers: List.filled(12, 2),
      );
      await repo.submitEntry(
        scaleId: 'asrm',
        score: 8,
        severityRank: 2,
        answers: [1, 2, 1, 2, 2],
      );

      final entries = await dao.watchAllAssessmentEntries().first;
      expect(entries.length, 3);
      expect(entries.map((e) => e.scaleId).toSet(), {'phq9', 'whodas', 'asrm'});
    });
  });

  group('getLatestEntryByType 拿最新 entry', () {
    test('同一 scale 提交 2 次 → 返最新 score / severityRank', () async {
      await repo.submitEntry(
        scaleId: 'phq9',
        score: 5,
        severityRank: 1,
        answers: [0, 0, 1, 1, 0, 0, 1, 1, 0],
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await repo.submitEntry(
        scaleId: 'phq9',
        score: 12,
        severityRank: 2,
        answers: [1, 2, 3, 0, 1, 2, 3, 0, 0],
      );

      final latest = await dao.getLatestEntryByType('phq9');
      expect(latest?.score, 12);
      expect(latest?.severityRank, 2);
    });
  });

  group('countByType 统计', () {
    test('phq9 2 次 + gad7 1 次 → counts 正确', () async {
      await repo.submitEntry(
        scaleId: 'phq9',
        score: 5,
        severityRank: 1,
        answers: const [0, 0, 0, 0, 0, 0, 0, 0, 0],
      );
      await repo.submitEntry(
        scaleId: 'phq9',
        score: 10,
        severityRank: 2,
        answers: const [0, 0, 0, 0, 0, 0, 0, 0, 0],
      );
      await repo.submitEntry(
        scaleId: 'gad7',
        score: 8,
        severityRank: 1,
        answers: const [0, 0, 0, 0, 0, 0, 0],
      );

      final counts = await dao.countByType();
      expect(counts['phq9'], 2);
      expect(counts['gad7'], 1);
    });
  });

  group('submitEntry 校验', () {
    test('unavailable scale nsesss → 抛 StateError', () {
      expect(
        () => repo.submitEntry(
          scaleId: 'nsesss',
          score: 10,
          severityRank: 1,
          answers: [0, 0, 0],
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('unknown scale xxx → 抛 ArgumentError', () {
      expect(
        () => repo.submitEntry(
          scaleId: 'xxx',
          score: 10,
          severityRank: 1,
          answers: [0],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('R60 legacy free text note 兼容', () {
    test('老格式 free text note → 兜底 score=0, answers=空, note 保留原文', () async {
      // 直接插一行老格式 free text note
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: DateTime(2026, 7, 1, 10, 0),
              type: 'phq9',
              note: const Value('用户备注: 状态一般'),
            ),
          );

      final entry = await dao.getLatestEntryByType('phq9');
      expect(entry?.note, '用户备注: 状态一般');
      expect(entry?.score, 0);
      expect(entry?.answers, isEmpty);
    });
  });
}
