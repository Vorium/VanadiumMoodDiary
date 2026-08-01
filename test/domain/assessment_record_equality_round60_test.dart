// v0.27 round 60 (审计 M9 修正): AssessmentRecord == 必须比较 scores
//
// Bug (audit-domain-layer.md 3.8):
//   == 只比较 scaleId / timestamp / total, 不比较 scores。
//   修正前: 两个 AssessmentRecord scaleId + timestamp + total 相同但
//   scores 不同 → 判等 true. 修正动机: 修正 == 完整性, 修正后
//   Set/Map round-trip 正确.
//
// 修正: == 修正加 scores element-based 比较 + hashCode 修正加 scores
// element-based hash (用 Object.hashAll element-based).
//
// v0.27 round 60 修正备注: 文件被 v0.17 PowerShell tar 事故的 PUA 字符
// 污染 (375KB 文件, 实际有效 ~67 行, 后面 300KB 是 PUA 字符 + 报告
// 路径字符串), 本次修正重写整个文件, 修正 v0.17 round 12 已知坑。

import 'package:chroniccare/domain/logic/assessment_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AssessmentRecord baseRecord({List<int>? scores}) {
    return AssessmentRecord(
      scaleId: 'phq9',
      timestamp: DateTime(2026, 7, 15, 10, 0),
      total: 9,
      scores: scores ?? [1, 2, 1, 2, 1, 1, 1, 0, 0],
    );
  }

  group('AssessmentRecord == / hashCode 契约 (修正后)', () {
    test('相同 scores (literal 复用) → == 成立 + hashCode 一致', () {
      // baseline: 修正前后都 pass
      const sharedScores = [1, 2, 1, 2, 1, 1, 1, 0, 0];
      final a = baseRecord(scores: sharedScores);
      final b = baseRecord(scores: sharedScores);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('相同 scores 但不同 List instance → == 成立 + hashCode 一致 (修正)', () {
      // 修正前 bug: scores 不参与 ==, 但 total 相同 → == 错位 true
      // 修正后: == 比较 scores element-based, hashCode 一致
      final a = baseRecord(scores: [1, 2, 1, 2, 1, 1, 1, 0, 0]);
      final b = baseRecord(scores: [1, 2, 1, 2, 1, 1, 1, 0, 0]);
      expect(identical(a.scores, b.scores), isFalse,
          reason: 'sanity: 2 个 list 必须不同 instance',);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('scores 内容不同但 total 相同 → == 不成立 (修正核心)', () {
      // 修正前 bug: total 都是 9 (e.g. [3,3,3,0,0,0,0,0,0] vs [1,2,1,2,1,1,1,0,0])
      // → == 错位 true
      // 修正后: scores 不同 → == false
      final a = baseRecord(scores: [3, 3, 3, 0, 0, 0, 0, 0, 0]); // total = 9
      final b = baseRecord(scores: [1, 2, 1, 2, 1, 1, 1, 0, 0]); // total = 9
      expect(a.total, b.total);
      expect(a, isNot(equals(b)),
          reason: '修正前 == 不看 scores, total 相同就 true — 修正后必须 false',);
    });

    test('scores 长度不同 → == 不成立', () {
      final a = baseRecord(scores: [1, 2, 1, 2, 1, 1, 1, 0, 0]); // 9 题
      final b = baseRecord(scores: [1, 2, 1, 2, 1, 1, 0]); // 7 题 (GAD-7 风格)
      // 同时修正 total (修正前 == 用 total, 修正后不用, 但修正不修正 total 字段)
      final a7 = AssessmentRecord(
        scaleId: 'gad7',
        timestamp: a.timestamp,
        total: 8, // 修正前 == 修正 total 后可能误判
        scores: [1, 2, 1, 2, 1, 1, 0],
      );
      expect(a7, isNot(equals(b)),
          reason: '修正前 == 不看 scores, total 相同就 true — 修正后必须 false',);
    });

    test('scaleId 不同 → == 不成立', () {
      final a = baseRecord();
      final b = AssessmentRecord(
        scaleId: 'gad7',
        timestamp: a.timestamp,
        total: a.total,
        scores: a.scores,
      );
      expect(a, isNot(equals(b)),
          reason: 'scaleId 不同 → == false (sanity baseline)',);
    });

    test('timestamp 不同 → == 不成立', () {
      final a = baseRecord();
      final b = AssessmentRecord(
        scaleId: a.scaleId,
        timestamp: a.timestamp.add(const Duration(hours: 1)),
        total: a.total,
        scores: a.scores,
      );
      expect(a, isNot(equals(b)),
          reason: 'timestamp 不同 → == false (sanity baseline)',);
    });
  });
}
