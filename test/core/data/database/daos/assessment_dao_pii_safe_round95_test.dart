// v0.30 round 95 (sub-spec 7 task 30): assessment_dao._rowToEntry PII 泄露修测试
//
// 覆盖:
// 1. 损坏 JSON (含 PII marker) 触发 _rowToEntry parse 异常 → 走 legacy free text
//    兜底, 返 note 原文, score=0, answers=空 (R60 兼容)
// 2. 多个损坏 JSON row 连续 insert → 全部兜底 (不抛, 不静默吞)
// 3. 解析失败不影响后续 watchAll 行为 (R90 跨 type 聚合仍正常)
//
// **lock-in 验证 PII 修**: 测 assert 损坏 JSON 内容**包含** PII marker,
// 走 _rowToEntry 兜底后, 业务路径返 note 原文 (legacy free text 保留) —
// 修前/修后 行为一致。PII 不进 log 通道靠代码审查 (swallowError 的 note
// 参数已删 rawNote, 跟 R95 sub-spec 5 task 3-4 lock-in 一致)。

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

  group('task 30 PII 泄露修 — 损坏 JSON 兜底 + PII marker 不影响业务', () {
    test('损坏 JSON 含 PII marker → 走 legacy free text 兜底 (note 保留原文, score=0, answers 空)',
        () async {
      // v0.30 R95 task 30 lock-in: 损坏 JSON note 含 PII marker, 验证
      // 1) 兜底路径不抛
      // 2) note 保留原文 (R60 兼容, 不丢用户数据)
      // 3) score=0, answers 空 (损坏 JSON 无法解析的兜底)
      const piiMarker = '用户敏感身份证号 110101199001011234';
      final corruptedNote = '{"score": 5, "user_pii": "$piiMarker"';
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: DateTime(2026, 7, 1, 10, 0),
              type: 'phq9',
              note: const Value('corrupted'), // placeholder, will use raw SQL
            ),
          );
      // 用 raw SQL 插入损坏 JSON (drift typed API 不会让我们传损坏 JSON)
      await db.customStatement(
        "UPDATE check_ins SET note = ? WHERE type = 'phq9'",
        [corruptedNote],
      );

      final entry = await dao.getLatestEntryByType('phq9');
      expect(entry, isNotNull);
      // R60 兼容: 损坏 JSON 走 free text 兜底, note 保留原文
      expect(entry?.note, corruptedNote);
      // 兜底 score/answers 默认
      expect(entry?.score, 0);
      expect(entry?.answers, isEmpty);
      // 锁: 业务行为 (R60 兼容) 0 变化, PII 仅走 log (修复后 log 不带 rawNote)
    });

    test('多个损坏 JSON row 连续 insert → 全部走 legacy 兜底不抛', () async {
      // 模拟老用户升级到 R90 + 多种损坏 note 格式 (走 _rowToEntry 兜底路径)
      // 1) free text (R60 之前老格式)
      // 2) JSON 数组 (合法 JSON 但不是 Map)
      // 3) 半截 JSON (jsonDecode 抛)
      final phq9Id = await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: DateTime(2026, 7, 1),
              type: 'phq9',
            ),
          );
      await db.customStatement(
        "UPDATE check_ins SET note = ? WHERE id = ?",
        ['用户备注: 状态一般', phq9Id], // free text → legacy 兜底
      );

      final gad7Id = await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: DateTime(2026, 7, 2),
              type: 'gad7',
            ),
          );
      await db.customStatement(
        "UPDATE check_ins SET note = ? WHERE id = ?",
        ['[1, 2, 3]', gad7Id], // JSON 数组 → legacy 兜底
      );

      final phq9Id2 = await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: DateTime(2026, 7, 3),
              type: 'phq9',
            ),
          );
      await db.customStatement(
        "UPDATE check_ins SET note = ? WHERE id = ?",
        ['半截 JSON {"score":', phq9Id2], // 半截 → catch 兜底
      );

      // watchAll 跨 2 type 聚合, 应返 3 条 (全部走 legacy 兜底, note 保留原文)
      final entries = await dao.watchAllAssessmentEntries().first;
      expect(entries.length, 3);
      // 锁定: 3 条都应 note 非空 (R60 兼容)
      for (final e in entries) {
        expect(e.note, isNotNull);
        expect(e.note, isNotEmpty);
      }
      // 锁定: phq9 (free text) + gad7 (数组) + phq9 (半截) 3 种格式都保留原文
      final byType = <String, List<String>>{};
      for (final e in entries) {
        byType.putIfAbsent(e.scaleId, () => []).add(e.note!);
      }
      expect(byType['phq9']?.length, 2);
      expect(
        byType['phq9']?.toSet(),
        {'用户备注: 状态一般', '半截 JSON {"score":'},
        reason: 'phq9 两条都应保留原文 (R60 兼容)',
      );
      expect(byType['gad7']?.length, 1);
      expect(byType['gad7']?.first, '[1, 2, 3]');
    });

    test('R90 合法 JSON 不受 PII 修复影响 (R90 业务行为 0 变化)', () async {
      // 验证 R90 正常提交 + R90 reader 解正常 JSON 不走兜底
      await repo.submitEntry(
        scaleId: 'phq9',
        score: 12,
        severityRank: 2,
        answers: [1, 2, 3, 0, 1, 2, 3, 0, 0],
      );

      final entry = await dao.getLatestEntryByType('phq9');
      expect(entry?.score, 12);
      expect(entry?.severityRank, 2);
      expect(entry?.answers, [1, 2, 3, 0, 1, 2, 3, 0, 0]);
    });
  });
}
