// v0.29 round 84 (CBT 思维记录): CbtDraftState 单元测试
//
// 覆盖:
// 1. 初始 state: level=three, stepIndex=0, draft 8 字段全 null
// 2. 3 栏 → 5 栏切换保留已有 situation/automaticThought 字段
// 3. 5 栏 → 7 栏切换保留所有 5 栏字段
// 4. 7 栏 → 5 栏切换保留 core/behavior 字段 (UI 隐藏但 state 保留)
// 5. firstEmptyStep 5 栏: 全空 → 0, situation 空 → 0, 都填 → 4
// 6. 3 栏 firstEmptyStep 永远返回 0 (单屏模式无 step 概念)
// 7. (Task 6 fix) updateScore overwrite score, 其它 draft 字段保留
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CbtDraftState (v0.29 round 84)', () {
    test('初始 state level=three, stepIndex=0, draft 8 字段全 null', () {
      final s = CbtDraftState.initial();
      expect(s.level, ThoughtRecordLevel.three);
      expect(s.stepIndex, 0);
      expect(s.draft.situation, isNull);
      expect(s.draft.automaticThought, isNull);
    });

    test('3 → 5 切换保留已有 situation/automaticThought 字段', () {
      var s = CbtDraftState.initial().copyWith(
        level: ThoughtRecordLevel.three,
        draft: const MoodEntryDraft(
          score: 4,
          tags: [],
          situation: 's1',
          automaticThought: 'at1',
        ),
      );
      final next = s.copyWith(level: ThoughtRecordLevel.five);
      expect(next.draft.situation, 's1');
      expect(next.draft.automaticThought, 'at1');
    });

    test('5 → 7 切换保留所有 5 栏字段', () {
      final s = CbtDraftState.initial().copyWith(
        level: ThoughtRecordLevel.five,
        draft: const MoodEntryDraft(
          score: 4,
          tags: [],
          situation: 's',
          automaticThought: 'at',
          evidenceFor: 'ef',
          evidenceAgainst: 'ea',
          alternativeThought: 'alt',
          reratedScore: 3,
        ),
      );
      final next = s.copyWith(level: ThoughtRecordLevel.seven);
      expect(next.draft.evidenceFor, 'ef');
      expect(next.draft.alternativeThought, 'alt');
      expect(next.draft.reratedScore, 3);
    });

    test('7 → 5 切换保留 core/behavior 字段 (UI 隐藏但 state 保留)', () {
      final s = CbtDraftState.initial().copyWith(
        level: ThoughtRecordLevel.seven,
        draft: const MoodEntryDraft(
          score: 4,
          tags: [],
          situation: 's',
          automaticThought: 'at',
          evidenceFor: 'ef',
          evidenceAgainst: 'ea',
          alternativeThought: 'alt',
          reratedScore: 3,
          coreBelief: 'cb',
          behaviorResponse: 'br',
        ),
      );
      final next = s.copyWith(level: ThoughtRecordLevel.five);
      expect(next.draft.coreBelief, 'cb');
      expect(next.draft.behaviorResponse, 'br');
    });

    test('firstEmptyStep 5 栏: 全空 → 0, situation 空 → 0, 都填 → 4', () {
      expect(
        CbtDraftState.firstEmptyStep(
          const MoodEntryDraft(score: 3, tags: []),
          ThoughtRecordLevel.five,
        ),
        0,
      );
      expect(
        CbtDraftState.firstEmptyStep(
          const MoodEntryDraft(score: 3, tags: [], situation: 's'),
          ThoughtRecordLevel.five,
        ),
        1,
      );
      const allFilled = MoodEntryDraft(
        score: 4,
        tags: [],
        situation: 's',
        automaticThought: 'at',
        evidenceFor: 'ef',
        evidenceAgainst: 'ea',
        alternativeThought: 'alt',
        reratedScore: 3,
      );
      expect(
        CbtDraftState.firstEmptyStep(allFilled, ThoughtRecordLevel.five),
        4,
      );
    });

    test('3 栏 firstEmptyStep 永远返回 0 (单屏模式无 step 概念)', () {
      expect(
        CbtDraftState.firstEmptyStep(
          const MoodEntryDraft(score: 3, tags: []),
          ThoughtRecordLevel.three,
        ),
        0,
      );
    });
  });

  group('CbtDraftNotifier.updateScore (v0.29 round 84 Task 6 fix)', () {
    test('updateScore 改 score, 其它 draft 字段保留', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // 先用 updateField 填一些 CBT 字段
      container.read(cbtDraftProvider.notifier).updateField(situation: 's');
      // 再调 updateScore overwrite score
      container.read(cbtDraftProvider.notifier).updateScore(5);
      final s = container.read(cbtDraftProvider);
      expect(s.draft.score, 5);
      expect(s.draft.situation, 's'); // preserved
    });

    test('updateScore 多次调用以最后一次为准', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(cbtDraftProvider.notifier);
      notifier.updateScore(1);
      notifier.updateScore(3);
      notifier.updateScore(5);
      expect(container.read(cbtDraftProvider).draft.score, 5);
    });

    test('updateScore 越界 (0/6/-1) no-op, state 不变', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(cbtDraftProvider.notifier);
      notifier.updateScore(2);
      notifier.updateScore(0); // 越界
      notifier.updateScore(6); // 越界
      notifier.updateScore(-1); // 越界
      expect(container.read(cbtDraftProvider).draft.score, 2);
    });
  });
}
