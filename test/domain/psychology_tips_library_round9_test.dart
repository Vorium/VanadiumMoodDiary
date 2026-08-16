// 1.1.0 round 9 (论文落地 F3 心理技巧知识库): domain 库测试
//
// 覆盖:
// 1. all 恰 5 条技巧 (正念呼吸/情绪命名/认知重构/5-4-3-2-1/渐进式肌肉放松)
// 2. id 唯一 + 全部非空字段 (title/summary/steps)
// 3. byId 命中 / 未知 id 返回 null

import 'package:chroniccare/domain/logic/psychology_tips_library.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PsychologyTipsLibrary', () {
    test('all 恰 5 条 + id 唯一', () {
      final ids = PsychologyTipsLibrary.all.map((t) => t.id).toList();
      expect(ids, [
        'mindfulBreathing',
        'nameEmotion',
        'cognitiveReframing',
        'grounding54321',
        'progressiveMuscleRelaxation',
      ]);
      expect(ids.toSet().length, ids.length, reason: 'id 必须唯一');
    });

    test('每条非空 + 至少 2 步', () {
      for (final tip in PsychologyTipsLibrary.all) {
        expect(tip.title.trim(), isNotEmpty, reason: '${tip.id} title');
        expect(tip.summary.trim(), isNotEmpty, reason: '${tip.id} summary');
        expect(
          tip.steps.length,
          greaterThanOrEqualTo(2),
          reason: '${tip.id} steps',
        );
        for (final s in tip.steps) {
          expect(s.trim(), isNotEmpty, reason: '${tip.id} step 内容');
        }
      }
    });

    test('byId 命中各技巧', () {
      for (final tip in PsychologyTipsLibrary.all) {
        expect(PsychologyTipsLibrary.byId(tip.id), same(tip));
      }
    });

    test('byId 未知 id → null', () {
      expect(PsychologyTipsLibrary.byId('no-such-tip'), isNull);
    });
  });
}
