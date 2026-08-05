# Task 3 Brief — CbtDraftState + cbtDraftProvider

> 这是 implementer 的 source-of-truth。读这个文件,不要读 plan 全文。

## 项目背景

- 工作目录: 当前 git worktree `feat/cbt-thought-record`
- Branch HEAD: e604847 (task 1+2 完成)
- Task 1+2 已完成: schema 16→17 + ThoughtRecordLevel enum + provider
- 4 层架构: presentation → domain ← data
- AGENTS.md 已读

## Global Constraints (binding)

- Flutter 3.41.9 / Dart 3.12.2
- Riverpod 3.3.2 (NotifierProvider pattern)
- 4-layer architecture: domain 0 flutter 0 drift
- TDD: 1 commit per step
- 守门员: `flutter analyze` 0 error

## 已有文件 / 上下文

- `lib/domain/entities/thought_record_level.dart` (Task 2)
- `lib/presentation/providers/cbt_providers.dart` (Task 2, 包含 sharedPreferencesProvider)
- `lib/domain/entities/mood_entry_draft.dart` (Task 1, 含 8 nullable CBT fields)
- 新增到 cbt_providers.dart: CbtDraftState class + CbtDraftNotifier + cbtDraftProvider

## TDD 流程

每个 step: 1) 写失败测试 2) 跑测试 FAIL 3) 实现 4) 跑测试 PASS 5) commit。
Task 3 内部有 2 个 step (state 切档保留数据 / Notifier 实现)。

## Report 文件

详细报告写到: `.superpowers/sdd/task-3-report.md`
回信只给 4 行: Status + commits + 一行测试摘要 + concerns。

---
### Task 3: CbtDraftState + cbtDraftProvider

**Files:**
- Modify: `lib/presentation/providers/cbt_providers.dart`
- Test: `test/domain/entities/cbt_draft_state_round84_test.dart`

**Interfaces:**
- Consumes: `ThoughtRecordLevel`, `MoodEntryDraft`
- Produces:
  - `class CbtDraftState` (涓嶅彲鍙?
  - `class CbtDraftNotifier extends Notifier<CbtDraftState>`
  - `cbtDraftProvider` (NotifierProvider<CbtDraftNotifier, CbtDraftState>)

- [ ] **Step 1: 鍐欏け璐ユ祴璇?鈥?state 鍒囨。淇濈暀鏁版嵁**

`test/domain/entities/cbt_draft_state_round84_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';

void main() {
  group('CbtDraftState (v0.29 round 84)', () {
    test('鍒濆? state level=three, stepIndex=0, draft 8 瀛楁?鍏?null', () {
      final s = CbtDraftState.initial();
      expect(s.level, ThoughtRecordLevel.three);
      expect(s.stepIndex, 0);
      expect(s.draft.situation, isNull);
      expect(s.draft.automaticThought, isNull);
    });

    test('3 鈫?5 鍒囨。淇濈暀宸叉湁 situation/automaticThought 瀛楁?', () {
      var s = CbtDraftState.initial().copyWith(
        level: ThoughtRecordLevel.three,
        draft: const MoodEntryDraft(
          score: 4, tags: [],
          situation: 's1', automaticThought: 'at1',
        ),
      );
      final next = s.copyWith(level: ThoughtRecordLevel.five);
      expect(next.draft.situation, 's1');
      expect(next.draft.automaticThought, 'at1');
    });

    test('5 鈫?7 鍒囨。淇濈暀鎵€鏈?5 鏍忓瓧娈?, () {
      final s = CbtDraftState.initial().copyWith(
        level: ThoughtRecordLevel.five,
        draft: const MoodEntryDraft(
          score: 4, tags: [],
          situation: 's', automaticThought: 'at',
          evidenceFor: 'ef', evidenceAgainst: 'ea',
          alternativeThought: 'alt', reratedScore: 3,
        ),
      );
      final next = s.copyWith(level: ThoughtRecordLevel.seven);
      expect(next.draft.evidenceFor, 'ef');
      expect(next.draft.alternativeThought, 'alt');
      expect(next.draft.reratedScore, 3);
    });

    test('7 鈫?5 鍒囨。淇濈暀 core/behavior 瀛楁? (UI 闅愯棌浣?state 淇濈暀)', () {
      final s = CbtDraftState.initial().copyWith(
        level: ThoughtRecordLevel.seven,
        draft: const MoodEntryDraft(
          score: 4, tags: [],
          situation: 's', automaticThought: 'at',
          evidenceFor: 'ef', evidenceAgainst: 'ea',
          alternativeThought: 'alt', reratedScore: 3,
          coreBelief: 'cb', behaviorResponse: 'br',
        ),
      );
      final next = s.copyWith(level: ThoughtRecordLevel.five);
      expect(next.draft.coreBelief, 'cb');
      expect(next.draft.behaviorResponse, 'br');
    });

    test('firstEmptyStep 5 鏍? 鍏ㄧ┖ 鈫?0, situation 绌?鈫?0, 閮藉～浜?鈫?4', () {
      expect(CbtDraftState.firstEmptyStep(
        const MoodEntryDraft(score: 3, tags: []),
        ThoughtRecordLevel.five,
      ), 0);
      expect(CbtDraftState.firstEmptyStep(
        const MoodEntryDraft(score: 3, tags: [], situation: 's'),
        ThoughtRecordLevel.five,
      ), 1);
      final allFilled = const MoodEntryDraft(
        score: 4, tags: [],
        situation: 's', automaticThought: 'at',
        evidenceFor: 'ef', evidenceAgainst: 'ea',
        alternativeThought: 'alt', reratedScore: 3,
      );
      expect(CbtDraftState.firstEmptyStep(allFilled, ThoughtRecordLevel.five), 4);
    });

    test('3 鏍?firstEmptyStep 姘歌繙杩斿洖 0 (鍗曞睆妯″紡鏃?step)', () {
      expect(CbtDraftState.firstEmptyStep(
        const MoodEntryDraft(score: 3, tags: []),
        ThoughtRecordLevel.three,
      ), 0);
    });
  });
}
```

- [ ] **Step 2: 璺戞祴璇曢獙璇佸け璐?*

```bash
flutter test test/domain/entities/cbt_draft_state_round84_test.dart
```

Expected: FAIL 鈥?`CbtDraftState` 涓嶅瓨鍦ㄣ€?
- [ ] **Step 3: 鍦?cbt_providers.dart 鍔?CbtDraftState + Notifier**

`lib/presentation/providers/cbt_providers.dart` 鏈?熬鍔狅細

```dart
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';

/// v0.29 round 84: 褰撳墠 dialog 鍐呯殑 CBT draft 鐘舵€?///
/// - level: 褰撳墠妗ｄ綅 (3/5/7)
/// - stepIndex: wizard 姝ラ? (3 妗?mode 鍥哄畾 0)
/// - draft: 瀹屾暣 MoodEntryDraft (鍚?8 涓?CBT 瀛楁?)
/// - showExplainer: 椤堕儴 鈩癸笍 鎶樺彔鍗℃槸鍚﹀睍寮€
class CbtDraftState {
  final ThoughtRecordLevel level;
  final int stepIndex;
  final MoodEntryDraft draft;
  final bool showExplainer;

  const CbtDraftState({
    required this.level,
    required this.stepIndex,
    required this.draft,
    required this.showExplainer,
  });

  /// 鍒濆? state: 3 妗?/ step 0 / 绌?draft / 鎶樺彔鍗℃樉绀?  factory CbtDraftState.initial() => const CbtDraftState(
        level: ThoughtRecordLevel.three,
        stepIndex: 0,
        draft: MoodEntryDraft(score: 3, tags: []),
        showExplainer: true,
      );

  CbtDraftState copyWith({
    ThoughtRecordLevel? level,
    int? stepIndex,
    MoodEntryDraft? draft,
    bool? showExplainer,
  }) {
    return CbtDraftState(
      level: level ?? this.level,
      stepIndex: stepIndex ?? this.stepIndex,
      draft: draft ?? this.draft,
      showExplainer: showExplainer ?? this.showExplainer,
    );
  }

  /// 璁＄畻"绗?竴涓?湭濉?殑 step" (5/7 鏍?wizard 鐢? 3 妗ｈ繑鍥?0)
  ///
  /// 5 鏍?5 姝?
  ///   0 = situation
  ///   1 = automaticThought
  ///   2 = score + evidenceFor + evidenceAgainst (浠讳竴绌虹畻绌?
  ///   3 = alternativeThought + reratedScore (浠讳竴绌虹畻绌?
  ///   4 = 纭?? (5 姝ョ储寮? 鍏?5 姝?
  ///
  /// 7 鏍?7 姝?
  ///   0-4 鍚?5 鏍?  ///   5 = coreBelief
  ///   6 = behaviorResponse
  static int firstEmptyStep(MoodEntryDraft d, ThoughtRecordLevel level) {
    if (level == ThoughtRecordLevel.three) return 0;
    if (_isEmpty(d.situation)) return 0;
    if (_isEmpty(d.automaticThought)) return 1;
    if (_isEmpty(d.evidenceFor) || _isEmpty(d.evidenceAgainst) || d.score < 1) return 2;
    if (_isEmpty(d.alternativeThought) || d.reratedScore == null) return 3;
    if (level == ThoughtRecordLevel.seven) {
      if (_isEmpty(d.coreBelief)) return 4;
      if (_isEmpty(d.behaviorResponse)) return 5;
      return 6;
    }
    return 4;
  }

  static bool _isEmpty(String? s) => s == null || s.trim().isEmpty;
}

/// v0.29 round 84: CbtDraftState notifier
///
/// - setLevel: 鍒囨。 + 璺冲埌绗?竴涓?湭濉?step (3 妗ｅ浐瀹?0)
/// - setStep: 璺冲埌鎸囧畾 step (5/7 鏍忕敤)
/// - updateField: 鏀瑰崟涓?CBT 瀛楁?
/// - toggleExplainer: 鎶樺彔鍗″睍寮€/鏀惰捣
class CbtDraftNotifier extends Notifier<CbtDraftState> {
  @override
  CbtDraftState build() => CbtDraftState.initial();

  /// 鍒囨。 (dialog 椤堕儴 SegmentedButton 璋?
  void setLevel(ThoughtRecordLevel newLevel) {
    final newStep = CbtDraftState.firstEmptyStep(state.draft, newLevel);
    state = state.copyWith(level: newLevel, stepIndex: newStep);
  }

  /// 璺冲埌鎸囧畾 step (5/7 鏍?wizard 鐢? 鑼冨洿 check)
  void setStep(int step) {
    final maxStep = state.level == ThoughtRecordLevel.five ? 4 : 6;
    final clamped = step.clamp(0, maxStep);
    state = state.copyWith(stepIndex: clamped);
  }

  /// 鏀瑰崟涓?CBT 瀛楁?
  void updateField({
    String? situation,
    String? automaticThought,
    String? evidenceFor,
    String? evidenceAgainst,
    String? alternativeThought,
    int? reratedScore,
    String? coreBelief,
    String? behaviorResponse,
  }) {
    state = state.copyWith(
      draft: MoodEntryDraft(
        score: state.draft.score,
        tags: state.draft.tags,
        at: state.draft.at,
        note: state.draft.note,
        energy: state.draft.energy,
        sleep: state.draft.sleep,
        anxiety: state.draft.anxiety,
        audioPath: state.draft.audioPath,
        audioTranscript: state.draft.audioTranscript,
        audioDurationMs: state.draft.audioDurationMs,
        situation: situation ?? state.draft.situation,
        automaticThought: automaticThought ?? state.draft.automaticThought,
        evidenceFor: evidenceFor ?? state.draft.evidenceFor,
        evidenceAgainst: evidenceAgainst ?? state.draft.evidenceAgainst,
        alternativeThought: alternativeThought ?? state.draft.alternativeThought,
        reratedScore: reratedScore ?? state.draft.reratedScore,
        coreBelief: coreBelief ?? state.draft.coreBelief,
        behaviorResponse: behaviorResponse ?? state.draft.behaviorResponse,
      ),
    );
  }

  /// 鎶樺彔鍗″睍寮€/鏀惰捣
  void toggleExplainer() {
    state = state.copyWith(showExplainer: !state.showExplainer);
  }

  /// 閲嶇疆 (dialog 鍏抽棴鏃惰皟)
  void reset() {
    state = CbtDraftState.initial();
  }
}

final cbtDraftProvider =
    NotifierProvider<CbtDraftNotifier, CbtDraftState>(
  CbtDraftNotifier.new,
);
```

- [ ] **Step 4: 璺戞祴璇曢獙璇侀€氳繃**

```bash
flutter test test/domain/entities/cbt_draft_state_round84_test.dart
```

Expected: PASS 6/6銆?
- [ ] **Step 5: 璺戝叏閲?analyze + test**

```bash
flutter analyze
flutter test
```

Expected: 0 error, 1172 + 6 = 1178 cases pass銆?
- [ ] **Step 6: Commit**

```bash
git add lib/presentation/providers/cbt_providers.dart \
        test/domain/entities/cbt_draft_state_round84_test.dart
git commit -m 'v0.29 round 84 (state): CbtDraftState + cbtDraftProvider + 鍒囨。淇濈暀'
```

---


