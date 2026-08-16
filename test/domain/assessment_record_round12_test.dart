// AssessmentRecord 解析测试
// 验证从 CheckInEntity 反序列化的正确性 + 边界 case
//
// v0.14 (Round 12A) 4 层架构：tryFromCheckIn → tryFromEntity
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/logic/assessment_record.dart';

CheckInEntity _ci({
  required int id,
  required String type,
  required DateTime timestamp,
  String? note,
}) {
  return CheckInEntity(
    id: id,
    timestamp: timestamp,
    type: CheckInType.fromWire(type),
    note: note,
    medicationId: null,
  );
}

void main() {
  group('AssessmentRecord.tryFromEntity', () {
    test('type=normal → null（不是量表）', () {
      final c = _ci(
        id: 1,
        type: 'normal',
        timestamp: DateTime(2026, 7, 13, 8, 0),
      );
      expect(AssessmentRecord.tryFromEntity(c), isNull);
    });

    test('type=temp → null', () {
      final c = _ci(
        id: 1,
        type: 'temp',
        timestamp: DateTime(2026, 7, 13, 8, 0),
        note: '布洛芬: 感冒',
      );
      expect(AssessmentRecord.tryFromEntity(c), isNull);
    });

    test('type=phq9 但 note 为空 → null', () {
      final c = _ci(
        id: 1,
        type: 'phq9',
        timestamp: DateTime(2026, 7, 13, 8, 0),
        note: null,
      );
      expect(AssessmentRecord.tryFromEntity(c), isNull);
    });

    test('type=phq9 + 合法 JSON → 正确反序列化', () {
      final c = _ci(
        id: 1,
        type: 'phq9',
        timestamp: DateTime(2026, 7, 13, 8, 0),
        note: '{"scale":"phq9","scores":[1,2,0,3,1,0,2,1,0],"total":10}',
      );
      final r = AssessmentRecord.tryFromEntity(c);
      expect(r, isNotNull);
      expect(r!.scaleId, 'phq9');
      expect(r.total, 10);
      expect(r.scores, [1, 2, 0, 3, 1, 0, 2, 1, 0]);
      expect(r.timestamp, DateTime(2026, 7, 13, 8, 0));
    });

    test('type=gad7 + 合法 JSON → 正确反序列化', () {
      final c = _ci(
        id: 2,
        type: 'gad7',
        timestamp: DateTime(2026, 7, 12, 20, 0),
        note: '{"scale":"gad7","scores":[3,2,2,1,0,1,2],"total":11}',
      );
      final r = AssessmentRecord.tryFromEntity(c);
      expect(r, isNotNull);
      expect(r!.scaleId, 'gad7');
      expect(r.total, 11);
      expect(r.scores.length, 7);
    });

    test('JSON 损坏 → null（不抛异常）', () {
      final c = _ci(
        id: 1,
        type: 'phq9',
        timestamp: DateTime(2026, 7, 13, 8, 0),
        note: 'not-a-json',
      );
      expect(AssessmentRecord.tryFromEntity(c), isNull);
    });

    test('JSON 缺 total 字段 → total=0', () {
      final c = _ci(
        id: 1,
        type: 'phq9',
        timestamp: DateTime(2026, 7, 13, 8, 0),
        note: '{"scale":"phq9","scores":[1,1,1]}',
      );
      final r = AssessmentRecord.tryFromEntity(c);
      expect(r, isNotNull);
      expect(r!.total, 0);
      expect(r.scores, [1, 1, 1]);
    });

    test('JSON 缺 scores 字段 → scores=[]', () {
      final c = _ci(
        id: 1,
        type: 'gad7',
        timestamp: DateTime(2026, 7, 13, 8, 0),
        note: '{"scale":"gad7","total":5}',
      );
      final r = AssessmentRecord.tryFromEntity(c);
      expect(r, isNotNull);
      expect(r!.total, 5);
      expect(r.scores, isEmpty);
    });

    // ===== R114 BUG 3: R90 量表中心 'score'/'answers' key 兼容 =====

    test('R114 BUG 3: R90 新格式 score/answers → 正确反序列化', () {
      final c = _ci(
        id: 3,
        type: 'pss',
        timestamp: DateTime(2026, 8, 10, 9, 0),
        note: '{"score":18,"severity":2,"answers":[2,3,1,2,3,0,2,3,1,1]}',
      );
      final r = AssessmentRecord.tryFromEntity(c);
      expect(r, isNotNull);
      expect(r!.scaleId, 'pss');
      expect(r.total, 18);
      expect(r.scores, [2, 3, 1, 2, 3, 0, 2, 3, 1, 1]);
    });

    test('R114 BUG 3: 8 新量表 score/answers key 全走 score 兜底', () {
      for (final scaleId in [
        'isi',
        'pss',
        'whodas',
        'level2_depression',
        'level2_anxiety',
        'level2_mania',
        'asrm',
        'level2_psychosis',
      ]) {
        final c = _ci(
          id: 1,
          type: scaleId,
          timestamp: DateTime(2026, 8, 10, 9, 0),
          note: '{"score":7,"answers":[1,2,3]}',
        );
        final r = AssessmentRecord.tryFromEntity(c);
        expect(r, isNotNull, reason: '$scaleId 应能解析 (R90 格式)');
        expect(r!.total, 7, reason: '$scaleId total 应读 score key');
        expect(r.scores, [1, 2, 3]);
      }
    });

    test('R114 BUG 3: 两 key 同时存在时 total 优先 (老格式兼容)', () {
      final c = _ci(
        id: 1,
        type: 'phq9',
        timestamp: DateTime(2026, 7, 13, 8, 0),
        note: '{"total":10,"score":99,"scores":[1],"answers":[2,3]}',
      );
      final r = AssessmentRecord.tryFromEntity(c);
      expect(r, isNotNull);
      expect(r!.total, 10, reason: 'total key 存在时应优先');
      expect(r.scores, [1], reason: 'scores key 存在时应优先');
    });
  });
}
