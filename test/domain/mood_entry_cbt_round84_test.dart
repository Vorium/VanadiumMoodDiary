// v0.29 round 84 (CBT thought record) — MoodEntryEntity 业务方法单元测试
//
// 验证 3 个新增 getter:
// - isCbtRecord: 是否 5/7 栏 (任一 CBT 字段非空)
// - cbtLevel: 推断档位 3 / 5 / 7
// - scoreShift: 重评分差值 (reratedScore - score, 5/7 栏有, 3 栏 null)
//
// 不依赖 drift / flutter，纯 domain 业务测试。

import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

void main() {
  group('MoodEntryEntity CBT fields (v0.29 round 84)', () {
    test('3-栏数据（只填 score/note）isCbtRecord=false cbtLevel=null', () {
      final e = MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 8, 4),
        score: 3,
        note: '普通记录',
      );
      expect(e.isCbtRecord, isFalse);
      expect(e.cbtLevel, isNull);
      expect(e.scoreShift, isNull);
    });

    test('5-栏数据 alternativeThought 非空时 cbtLevel=5', () {
      final e = MoodEntryEntity(
        id: 2,
        timestamp: DateTime(2026, 8, 4),
        score: 4,
        situation: '开会迟到',
        automaticThought: '大家觉得我不靠谱',
        evidenceFor: '上次也迟到',
        evidenceAgainst: '过去一年只迟到一次',
        alternativeThought: '偶尔一次正常',
        reratedScore: 3,
      );
      expect(e.isCbtRecord, isTrue);
      expect(e.cbtLevel, 5);
      expect(e.scoreShift, -1.0);
    });

    test('7-栏数据 coreBelief 非空时 cbtLevel=7', () {
      final e = MoodEntryEntity(
        id: 3,
        timestamp: DateTime(2026, 8, 4),
        score: 2,
        situation: 'x',
        automaticThought: 'y',
        evidenceFor: 'a',
        evidenceAgainst: 'b',
        alternativeThought: 'c',
        reratedScore: 4,
        coreBelief: '我不够好',
        behaviorResponse: '深呼吸',
      );
      expect(e.cbtLevel, 7);
      expect(e.isCbtRecord, isTrue);
      expect(e.scoreShift, 2.0); // 4 - 2
    });
  });
}
