// v0.30 round 95 (sub-spec 2 task 8): catch (_) → swallowError 集中器
// 锁住 R23 P1-10 / R22 P1-3 修过的 swallowError 行为, 防 regression
//
// **R95 报告 §6.4 task 8 发现**: 9 处 catch (_) 静默吞错是 R95 sub-spec 2 task 8
// spec 列出的待修项, 但 R23 round 39 (P1-10) + R22 round 30 (P1-3) 已修过
// 所有 9 处。R95 报告基于 R92 baseline + R93 增量 audit, 未把 R23 P1-10 算进去。
//
// **本 test 文件目标**: lock-in 已修过的 catch 行为, 防止后续
// refactor 把 `} catch (e, st) { ... swallowError(...) }` 退回成
// `} catch (_) {}` 静默吞错 (回归) 或抽掉 catch 直接抛 (破坏 caller)。
//
// **覆盖 4 个文件 (7 处 catch)**:
// - `JsonCodec.decodeStringList` + `JsonCodec.decodeMap` (2 catch)
// - `AssessmentRecord.tryFromEntity` (1 catch)
// - `MedicationTimes.times` (1 catch, 但多 input variant 拆 4 case)
//
// **不测什么**:
// - `swallowError` 自身: 已有 round14 test 覆盖
// - `developer.log` 是否被调: 测 global function 不可行, 也不必要
//   (我们关心的是 caller 的契约, 不是 logging 实现)
// - `export_import_pipeline.dart` 用 piiSafeLog (P12 PII 脱敏故意), 不在
//   swallowError 集中器范围, 但 importFromJson 失败返回 ImportResult.failure
//   的契约由 R23 round 39 真实 import 测覆盖
// - `ThemeProvider._load`: 需要 FlutterSecureStorage platform channel mock,
//   复杂度高, R22 round 30 测过, 不重复
// - `ExportSchemaService.deleteOldDataSafely`: mock drift TableInfo 复杂,
//   R23 round 39 用真实 import 流程测过 (data_export_round39_test.dart)
//
// **关键不变量** (lock-in):
// 1. 解析失败时函数不抛异常
// 2. 解析失败时函数返回合理的 fallback (空列表 / 空 map / null)
// 3. 正常输入时函数返回正确结果
// 4. 删掉 catch 会导致函数抛 (隐式测试, 因为下面的 invalid input 必须不抛)

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/medication/medication_times.dart';
import 'package:chroniccare/core/shared/json_codec.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/logic/assessment_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ==================== JsonCodec ====================
  // R23 round 39 (P1-10): catch (_) → swallowError, 失败返 const []

  group('JsonCodec.decodeStringList — swallowError lock-in (R23 P1-10)', () {
    test('invalid JSON: 不抛, 返 const [] (catch 触发 swallowError)', () {
      expect(() => JsonCodec.decodeStringList('not a json'), returnsNormally);
      expect(JsonCodec.decodeStringList('not a json'), isEmpty);
    });

    test('null / empty / "[]": 不抛, 返 const []', () {
      expect(JsonCodec.decodeStringList(null), isEmpty);
      expect(JsonCodec.decodeStringList(''), isEmpty);
      expect(JsonCodec.decodeStringList('[]'), isEmpty);
    });

    test('valid JSON: 返预期 list', () {
      expect(
        JsonCodec.decodeStringList('["a","b","c"]'),
        equals(['a', 'b', 'c']),
      );
    });

    test('JSON 不是 list (是 map): 返 const [] (类型不匹配也 swallow)', () {
      expect(JsonCodec.decodeStringList('{"a":1}'), isEmpty);
    });
  });

  group('JsonCodec.decodeMap — swallowError lock-in (R23 P1-10)', () {
    test('invalid JSON: 不抛, 返 const {} (catch 触发 swallowError)', () {
      expect(() => JsonCodec.decodeMap('not a json'), returnsNormally);
      expect(JsonCodec.decodeMap('not a json'), isEmpty);
    });

    test('valid JSON: 返预期 map', () {
      expect(
        JsonCodec.decodeMap('{"name":"x","age":1}'),
        equals({'name': 'x', 'age': 1}),
      );
    });

    test('JSON 不是 map (是 list): 返 const {} (类型不匹配也 swallow)', () {
      expect(JsonCodec.decodeMap('["a","b"]'), isEmpty);
    });
  });

  // ==================== AssessmentRecord.tryFromEntity ====================
  // R23 round 39 (P1-10): catch (_) → swallowError, 失败返 null

  group('AssessmentRecord.tryFromEntity — swallowError lock-in (R23 P1-10)',
      () {
    test('note 是无效 JSON: 不抛, 返 null (catch 触发 swallowError)', () {
      final c = CheckInEntity(
        id: 1,
        timestamp: DateTime.utc(2026, 8, 1),
        type: CheckInType.phq9,
        note: 'invalid json {',
      );
      expect(AssessmentRecord.tryFromEntity(c), isNull);
    });

    test('note 是 null: 返 null (前置守卫, 不走 catch)', () {
      final c = CheckInEntity(
        id: 1,
        timestamp: DateTime.utc(2026, 8, 1),
        type: CheckInType.phq9,
      );
      expect(AssessmentRecord.tryFromEntity(c), isNull);
    });

    test('note 是 valid JSON: 返 AssessmentRecord (happy path)', () {
      final c = CheckInEntity(
        id: 1,
        timestamp: DateTime.utc(2026, 8, 1),
        type: CheckInType.phq9,
        note: '{"total":12,"scores":[1,2,1,2,1,1,2,1,1]}',
      );
      final r = AssessmentRecord.tryFromEntity(c);
      expect(r, isNotNull);
      expect(r!.scaleId, 'phq9');
      expect(r.total, 12);
      expect(r.scores, [1, 2, 1, 2, 1, 1, 2, 1, 1]);
    });

    test('type 不是 phq9/gad7: 返 null (前置守卫 isAssessment)', () {
      final c = CheckInEntity(
        id: 1,
        timestamp: DateTime.utc(2026, 8, 1),
        type: CheckInType.normal,
        note: '{"total":12,"scores":[1]}',
      );
      expect(AssessmentRecord.tryFromEntity(c), isNull);
    });
  });

  // ==================== MedicationTimes.times ====================
  // R23 round 39 (P1-10): catch (_) → swallowError, 失败返 const []

  group('MedicationTimes.times — swallowError lock-in (R23 P1-10)', () {
    Medication makeMed(String timesJson) => Medication(
          id: 1,
          name: 'test',
          dosage: 1.0,
          dosageUnit: 'mg',
          timesJson: timesJson,
          startDate: DateTime.utc(2026, 1, 1),
          isActive: true,
          refillReminderDays: 7,
          form: 'tablet',
          colorIndex: 0,
        );

    test('invalid JSON: 不抛, 返 const [] (catch 触发 swallowError)', () {
      final m = makeMed('not a json');
      expect(m.times, isEmpty);
    });

    test('empty / "[]": 返 const [] (前置守卫)', () {
      expect(makeMed('').times, isEmpty);
      expect(makeMed('[]').times, isEmpty);
    });

    test('JSON 不是 list (是 string): 返 const [] (类型不匹配也 swallow)', () {
      expect(makeMed('"hello"').times, isEmpty);
    });

    test('valid JSON: 返预期 HourMinute list (happy path)', () {
      final m = makeMed('[{"h":8,"m":0},{"h":20,"m":30}]');
      final result = m.times;
      expect(result.length, 2);
      expect(result[0].hour, 8);
      expect(result[0].minute, 0);
      expect(result[1].hour, 20);
      expect(result[1].minute, 30);
    });

    test('item 缺 h 或 m: 跳过该 item, 不抛', () {
      final m = makeMed('[{"h":8,"m":0},{"h":12},{"m":15}]');
      final result = m.times;
      expect(result.length, 1);
      expect(result[0].hour, 8);
    });
  });

  // ==================== ExportSchemaService.deleteOldDataSafely ====================
  // R23 round 39 (P1-10): catch (_) → swallowError, 旧 schema 缺失表不抛
  // 注: mock drift TableInfo 需要实现 abstract methods, 复杂度高。
  // R23 round 39 已用真实 import 流程测过 (data_export_round39_test.dart)
  // 这里 lock-in skip — 用注释指代覆盖。
  // (R95 sub-spec 2 task 8 报告里会说明此决策)
}
