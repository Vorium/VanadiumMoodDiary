// v0.30 round 91 (fix): AssessmentDao `_rowToEntry` R60 JSON 兜底 回归测试
//
// final review C1 + I2 fix: 老 PHQ-9 / GAD-7 check_ins entry 写入格式是
// `{"scale":<id>, "scores":<List>, "total":<int>}` (R60 saveAssessment),
// 而 R90 reader 读 `decoded['score']` / `decoded['severity']` /
// `decoded['answers']` — keys 不匹配, 老数据 score=0 看不见。
//
// 修法: `_rowToEntry` 接受 BOTH R60 + R90 keys (R90 优先, R60 兜底)。
//
// TDD red→green: 本文件先写 (看 fail: 老格式 score=0),
// 然后改 `assessment_dao.dart`, 再跑 (看 pass: score=12)。

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/daos/assessment_dao.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AssessmentDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.assessmentDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('C1 fix: _rowToEntry R60 JSON 兜底 (老 PHQ-9 / GAD-7)', () {
    test(
        'R60 格式 {"scale":"phq9","scores":[...], "total":12} → score=12 + 完整 answers',
        () async {
      // 直接插一行 R60 格式 JSON note (模拟 R60 saveAssessment 写入)
      const r60Json =
          '{"scale":"phq9","scores":[0,1,2,0,1,2,3,0,0],"total":12}';
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: DateTime(2026, 7, 1, 10, 0),
              type: 'phq9',
              note: const Value(r60Json),
            ),
          );

      final entry = await dao.getLatestEntryByType('phq9');
      expect(entry, isNotNull);
      expect(entry!.score, 12, reason: 'R60 老格式 total 必须解析为 score');
      expect(entry.answers, [0, 1, 2, 0, 1, 2, 3, 0, 0],
          reason: 'R60 老格式 scores 必须解析为 answers',);
      expect(entry.scaleId, 'phq9');
    });

    test('R90 格式 {"score":12, "severity":2, "answers":[...]} → 仍正常工作',
        () async {
      // R90 写入格式应该继续被支持 (R90 优先)
      const r90Json = '{"score":12,"severity":2,"answers":[0,1,2,0,1,2,3,0,0]}';
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: DateTime(2026, 8, 1, 10, 0),
              type: 'phq9',
              note: const Value(r90Json),
            ),
          );

      final entry = await dao.getLatestEntryByType('phq9');
      expect(entry!.score, 12);
      expect(entry.severityRank, 2);
      expect(entry.answers, [0, 1, 2, 0, 1, 2, 3, 0, 0]);
    });

    test('老格式 free text 兜底仍保留 (note 留原文, score=0, answers=空)', () async {
      // R60 之前 (R53a 之前) 的 free text note
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: DateTime(2026, 1, 1, 10, 0),
              type: 'phq9',
              note: const Value('用户备注: 状态一般'),
            ),
          );

      final entry = await dao.getLatestEntryByType('phq9');
      expect(entry!.note, '用户备注: 状态一般');
      expect(entry.score, 0);
      expect(entry.answers, isEmpty);
    });
  });
}
