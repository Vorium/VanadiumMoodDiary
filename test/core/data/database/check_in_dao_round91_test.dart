// v0.30 round 91 (fix): CheckInDao.getLatestAssessmentTimestamp 跨 10 量表
//
// final review C4 fix: `getLatestAssessmentTimestamp` hardcode phq9|gad7,
// 只用新量表 (isi/pss/whodas/level2_xxx/asrm) 的用户的评估提醒周期永远
// 不启动。
//
// 修法: 跟 `watchAssessments()` 对齐, 用 10 type IN 列表。
//
// TDD red→green: 本文件先写 (看 fail: 新量表用户 timestamp = null),
// 然后改 `check_in_dao.dart`, 再跑 (看 pass: timestamp 正确)。

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/daos/check_in_dao.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late CheckInDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = db.checkInDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('C4 fix: getLatestAssessmentTimestamp 跨 10 量表', () {
    test('用户只做 whodas → 返 whodas timestamp (老代码返 null)', () async {
      final ts = DateTime(2026, 8, 1, 10, 0);
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: ts,
              type: 'whodas',
              note: const Value(
                '{"score":24,"severity":2,"answers":[1,2,3,0,1,2,3,0,1,2,3,0]}',
              ),
            ),
          );

      final result = await dao.getLatestAssessmentTimestamp();
      expect(
        result,
        isNotNull,
        reason: 'whodas 是 10 量表之一, timestamp 必须返回非 null',
      );
      expect(result, ts);
    });

    test('用户只做 level2_psychosis → 返 level2_psychosis timestamp', () async {
      final ts = DateTime(2026, 8, 2, 14, 30);
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: ts,
              type: 'level2_psychosis',
            ),
          );

      final result = await dao.getLatestAssessmentTimestamp();
      expect(result, isNotNull);
      expect(result, ts);
    });

    test('用户做 asrm → 返 asrm timestamp', () async {
      final ts = DateTime(2026, 8, 3, 9, 0);
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: ts,
              type: 'asrm',
            ),
          );

      final result = await dao.getLatestAssessmentTimestamp();
      expect(result, isNotNull);
      expect(result, ts);
    });

    test('老 phq9 / gad7 用户 → 仍正确 (回归)', () async {
      final phq9Ts = DateTime(2026, 7, 1, 10, 0);
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: phq9Ts,
              type: 'phq9',
            ),
          );

      final result = await dao.getLatestAssessmentTimestamp();
      expect(result, phq9Ts);
    });

    test('多个量表混合 → 返最新 timestamp', () async {
      // 用户做过 phq9 + whodas + asrm, 应该返回最新的 (asrm)
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: DateTime(2026, 7, 1),
              type: 'phq9',
            ),
          );
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: DateTime(2026, 7, 15),
              type: 'whodas',
            ),
          );
      final asrmTs = DateTime(2026, 8, 1);
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: asrmTs,
              type: 'asrm',
            ),
          );

      final result = await dao.getLatestAssessmentTimestamp();
      expect(result, asrmTs);
    });

    test('没做过任何量表 → 返 null (回归)', () async {
      // 只插 normal / temp, 不插任何 assessment
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: DateTime(2026, 8, 1),
              type: 'normal',
            ),
          );
      await db.into(db.checkIns).insert(
            CheckInsCompanion.insert(
              timestamp: DateTime(2026, 8, 2),
              type: 'temp',
            ),
          );

      final result = await dao.getLatestAssessmentTimestamp();
      expect(result, isNull);
    });
  });
}
