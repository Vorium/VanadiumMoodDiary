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
  });
}
