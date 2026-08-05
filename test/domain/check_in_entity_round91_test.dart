// v0.30 round 91 (fix): CheckInEntity.isAssessment 跨 10 量表 回归测试
//
// final review C2 fix: `isAssessment` 只识别 phq9/gad7,
// 新量表 (isi/pss/whodas/level2_depression/level2_anxiety/level2_mania/
// asrm/level2_psychosis) entry 在 day_detail / assessment_history 看不见。
//
// 修法: 改用 const `_assessmentScaleIds` set (10 个 wire string) 检查。
// 8 个新 CheckInType enum value 加进去, 让 mapper `fromWire` 正确解析
// 老 unknown type 仍 fallback 到 normal。
//
// TDD red→green: 本文件先写 (看 fail: whodas/level2_psychosis isAssessment = false),
// 然后改 `check_in_entity.dart`, 再跑 (看 pass: true)。

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/check_in/check_in_mapper.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

CheckIn _driftRow({int id = 1, String type = 'normal'}) {
  return CheckIn(
    id: id,
    timestamp: DateTime(2026, 8, 5, 10, 0),
    type: type,
    medicationId: null,
    note: null,
  );
}

void main() {
  group('C2 fix: isAssessment 跨 10 量表', () {
    test('新量表 whodas → isAssessment = true', () {
      final e = CheckInEntity(
        id: 1,
        timestamp: DateTime(2026),
        type: CheckInType.whodas,
      );
      expect(e.isAssessment, isTrue,
          reason: 'whodas 是新量表, isAssessment 必须为 true',);
    });

    test('新量表 level2_depression → isAssessment = true', () {
      final e = CheckInEntity(
        id: 1,
        timestamp: DateTime(2026),
        type: CheckInType.level2Depression,
      );
      expect(e.isAssessment, isTrue);
    });

    test('新量表 level2_psychosis → isAssessment = true', () {
      final e = CheckInEntity(
        id: 1,
        timestamp: DateTime(2026),
        type: CheckInType.level2Psychosis,
      );
      expect(e.isAssessment, isTrue);
    });

    test('新量表 asrm → isAssessment = true', () {
      final e = CheckInEntity(
        id: 1,
        timestamp: DateTime(2026),
        type: CheckInType.asrm,
      );
      expect(e.isAssessment, isTrue);
    });

    test('老 phq9 / gad7 仍 isAssessment = true (回归)', () {
      expect(
        CheckInEntity(
          id: 1,
          timestamp: DateTime(2026),
          type: CheckInType.phq9,
        ).isAssessment,
        isTrue,
      );
      expect(
        CheckInEntity(
          id: 1,
          timestamp: DateTime(2026),
          type: CheckInType.gad7,
        ).isAssessment,
        isTrue,
      );
    });

    test('normal / temp 仍 isAssessment = false (回归)', () {
      expect(
        CheckInEntity(
          id: 1,
          timestamp: DateTime(2026),
          type: CheckInType.normal,
        ).isAssessment,
        isFalse,
      );
      expect(
        CheckInEntity(
          id: 1,
          timestamp: DateTime(2026),
          type: CheckInType.temp,
        ).isAssessment,
        isFalse,
      );
    });
  });

  group('C2 fix: mapper 从 DB wire string → CheckInType 正确解析 10 scale', () {
    test('drift row type=whodas → entity.type=CheckInType.whodas', () {
      // 关键: mapper 必须能解析 R90 新写入的 10 scale id, 否则
      // c.isAssessment 在 day_detail 仍为 false
      expect(
        _driftRow(type: 'whodas').toEntity().type,
        CheckInType.whodas,
      );
    });

    test('drift row type=level2_depression → 正确解析', () {
      expect(
        _driftRow(type: 'level2_depression').toEntity().type,
        CheckInType.level2Depression,
      );
    });

    test('drift row type=asrm → 正确解析', () {
      expect(
        _driftRow(type: 'asrm').toEntity().type,
        CheckInType.asrm,
      );
    });

    test('老 phq9 / gad7 仍正确解析 (回归)', () {
      expect(
        _driftRow(type: 'phq9').toEntity().type,
        CheckInType.phq9,
      );
      expect(
        _driftRow(type: 'gad7').toEntity().type,
        CheckInType.gad7,
      );
    });

    test('未知 type 仍 fallback 到 normal (回归)', () {
      // 防止老数据 / 数据损坏时不崩
      expect(
        _driftRow(type: 'unknown').toEntity().type,
        CheckInType.normal,
      );
    });
  });

  group('C2 fix: DB 集成 round-trip', () {
    test('DB insert type=whodas → read entity.isAssessment = true', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async => await db.close());

      await db.checkInDao.insert(
        CheckInsCompanion.insert(
          timestamp: DateTime(2026, 8, 5, 10, 0),
          type: 'whodas',
        ),
      );

      final rows = await db.checkInDao.watchAll().first;
      expect(rows.length, 1);
      final entity = rows.first.toEntity();
      expect(entity.type, CheckInType.whodas);
      expect(entity.isAssessment, isTrue,
          reason: 'DB→entity round-trip 后, 新量表 isAssessment 必须为 true',);
    });
  });
}
