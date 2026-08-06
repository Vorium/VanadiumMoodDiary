// v0.29 round 84 (CBT 思维记录): 栏位持久化 provider + draft 状态
//
// - 读: SharedPreferences key "mood.thought_record_level" (int 3/5/7)
// - 写: 用户在 settings 页改后立时同步
// - 默认: 3 (新手友好)
// - 异常: SP 读失败 fallback 3 (fail-safe)
//
// v0.29 round 84 (state) 扩展:
// - CbtDraftState: 当前 dialog 内的 CBT draft 状态 (level/step/draft/showExplainer)
// - CbtDraftNotifier: 切换档位保留已有字段 / 跳转 step / 折叠说明卡
// - cbtDraftProvider: dialog 内 UI 唯一 state 源
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/domain/entities/mood_entry_draft.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';

const _kThoughtRecordLevelKey = 'mood.thought_record_level';

/// 启动时一次性读 SP, 给 provider 用
///
/// 公开命名 (无下划线) 让 [ProviderScope] override 入口可见;
/// 默认 throw 是 fail-loud — 不在 bootstrap 调 `SharedPreferences.getInstance()`
/// 就会立刻崩, 跟"显式初始化"的项目约定一致 (跟 [databaseProvider] /
/// [notificationServiceProvider] 同款模式, 都是 main.dart 注入)。
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override at app boot'),
);

/// v0.29 round 84: 思维记录栏位 (3/5/7)
class ThoughtRecordLevelNotifier extends Notifier<ThoughtRecordLevel> {
  @override
  ThoughtRecordLevel build() {
    final sp = ref.read(sharedPreferencesProvider);
    final raw = sp.getInt(_kThoughtRecordLevelKey);
    return ThoughtRecordLevel.fromInt(raw ?? 3);
  }

  /// 设置栏位 (settings 页调用)
  Future<void> setLevel(ThoughtRecordLevel level) async {
    state = level;
    final sp = ref.read(sharedPreferencesProvider);
    await sp.setInt(_kThoughtRecordLevelKey, level.columnCount);
  }
}

final thoughtRecordLevelProvider =
    NotifierProvider<ThoughtRecordLevelNotifier, ThoughtRecordLevel>(
  ThoughtRecordLevelNotifier.new,
);

/// v0.29 round 84 (state): 当前 dialog 内的 CBT draft 状态
///
/// - level: 当前档位 (3/5/7)
/// - stepIndex: wizard 步骤 (3 栏 mode 固定 0)
/// - draft: 完整 MoodEntryDraft (含 8 个 CBT 字段)
/// - showExplainer: 顶部 〔?〕 折叠卡是否展开
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

  /// 初始 state: 3 栏 / step 0 / 空 draft / 折叠卡显示
  factory CbtDraftState.initial() => const CbtDraftState(
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

  /// 计算"第一个未填的 step" (5/7 栏 wizard 用, 3 栏返回 0)
  ///
  /// 5 栏 5 步 (0-4):
  ///   0 = situation
  ///   1 = automaticThought
  ///   2 = score + evidenceFor + evidenceAgainst (任一空算空)
  ///   3 = alternativeThought + reratedScore (任一空算空)
  ///   4 = 确认 (5 步全填了 → 跳到确认页)
  ///
  /// 7 栏 7 步 (0-6, setStep maxStep=6):
  ///   0-3 同 5 栏
  ///   4 = coreBelief
  ///   5 = behaviorResponse
  ///   6 = 确认 (7 步全填了 → 跳到确认页)
  static int firstEmptyStep(MoodEntryDraft d, ThoughtRecordLevel level) {
    if (level == ThoughtRecordLevel.three) return 0;
    if (_isEmpty(d.situation)) return 0;
    if (_isEmpty(d.automaticThought)) return 1;
    if (_isEmpty(d.evidenceFor) ||
        _isEmpty(d.evidenceAgainst) ||
        d.score < 1) {
      return 2;
    }
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

/// v0.29 round 84 (state): CbtDraftState notifier
///
/// - setLevel: 切档 + 跳到第一个未填 step (3 栏固定 0)
/// - setStep: 跳到指定 step (5/7 栏用, 范围 clamp)
/// - updateField: 改单个 CBT 字段
/// - toggleExplainer: 折叠卡展开/收起
class CbtDraftNotifier extends Notifier<CbtDraftState> {
  @override
  CbtDraftState build() => CbtDraftState.initial();

  /// 切档 (dialog 顶部 SegmentedButton 调)
  void setLevel(ThoughtRecordLevel newLevel) {
    final newStep = CbtDraftState.firstEmptyStep(state.draft, newLevel);
    state = state.copyWith(level: newLevel, stepIndex: newStep);
  }

  /// 跳到指定 step (5/7 栏 wizard 用, 范围 check)
  void setStep(int step) {
    final maxStep = state.level == ThoughtRecordLevel.five ? 4 : 6;
    final clamped = step.clamp(0, maxStep);
    state = state.copyWith(stepIndex: clamped);
  }

  /// 改单个 CBT 字段
  ///
  /// v0.30 round 91 增 `period` (morning / noon / evening / night /
  /// unspecified): mood_dialog PeriodField dropdown onChanged 调, 跟
  /// score 一样是 overwrite (用户显式选, null=保持)。透传到 save → DB。
  void updateField({
    String? situation,
    String? automaticThought,
    String? evidenceFor,
    String? evidenceAgainst,
    String? alternativeThought,
    int? reratedScore,
    String? coreBelief,
    String? behaviorResponse,
    String? period,
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
        period: period ?? state.draft.period,
      ),
    );
  }

  /// 改情绪分数 (1-5) — 5/7 栏 wizard step 2 + 3 栏 mode 顶部 chip
  ///
  /// v0.29 round 84 (Task 6 fix): 之前 step 2 的 score chip 是占位
  /// (onSelected 空实现),用户点 1-5 不写 state.draft.score, 所有 5/7 栏
  /// mood 记录都保存 score=3。修法: 显式 overwrite, 不 ??-coalesce
  /// (跟 updateField 的 nullable-field 模式相反 — score 必有值)。
  ///
  /// 范围 1-5: 不在范围直接 no-op (UI 已限制, 防御性)。
  void updateScore(int score) {
    if (score < 1 || score > 5) return;
    state = state.copyWith(
      draft: MoodEntryDraft(
        score: score,
        tags: state.draft.tags,
        at: state.draft.at,
        note: state.draft.note,
        energy: state.draft.energy,
        sleep: state.draft.sleep,
        anxiety: state.draft.anxiety,
        audioPath: state.draft.audioPath,
        audioTranscript: state.draft.audioTranscript,
        audioDurationMs: state.draft.audioDurationMs,
        situation: state.draft.situation,
        automaticThought: state.draft.automaticThought,
        evidenceFor: state.draft.evidenceFor,
        evidenceAgainst: state.draft.evidenceAgainst,
        alternativeThought: state.draft.alternativeThought,
        reratedScore: state.draft.reratedScore,
        coreBelief: state.draft.coreBelief,
        behaviorResponse: state.draft.behaviorResponse,
        period: state.draft.period,
      ),
    );
  }

  /// 折叠卡展开/收起
  void toggleExplainer() {
    state = state.copyWith(showExplainer: !state.showExplainer);
  }

  /// 重置 (dialog 关闭时调)
  void reset() {
    state = CbtDraftState.initial();
  }
}

final cbtDraftProvider =
    NotifierProvider<CbtDraftNotifier, CbtDraftState>(
  CbtDraftNotifier.new,
);
