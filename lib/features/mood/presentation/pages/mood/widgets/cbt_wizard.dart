// v0.29 round 84 (CBT 思维记录): 5/7 栏 wizard
//
// 步骤式布局: 进度条 + 步数指示 + 当前 step section + 上一/下一步按钮
// 5 栏 5 步, 7 栏 7 步。切档由父组件 (mood_recorder_page) 通过
// SegmentedButton 触发, wizard 自身只读 cbtDraftProvider.
//
// 5 栏 5 步 (default level=three 时 wizard 不显示, 单屏长表式走
// CbtThreeColumnMode):
//   0 = 情境 (situation)
//   1 = 那一刻脑海中闪过的想法 (automatic thought)
//   2 = 情绪 + 证据 (score + evidenceFor + evidenceAgainst)
//   3 = 替代思维 + 重新评分 (alternativeThought + reratedScore)
//   4 = 确认
//
// 7 栏 7 步 (在 5 栏基础上, step 4 由"确认"变为"核心信念"):
//   4 = 核心信念 (coreBelief) — 覆盖 5 栏 step 4 确认
//   5 = 行为应对 (behaviorResponse)
//   6 = 确认
//
// 频度: 切到 5/7 栏时显示,tens/day
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_section_field.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_explainer_card.dart';
import 'package:chroniccare/presentation/widgets/mood_score_buttons.dart';

class CbtWizard extends ConsumerWidget {
  /// v0.30 round 92 (audit-fixes / P0 #11): 5/7 栏 "完成" 按钮回调
  ///
  /// 修前 bug: `FilledButton` onPressed 写死 `Navigator.pop(context)`,父组件
  /// (MoodRecorderPage) 的 `_save()` 没被调 → 5/7 栏 CBT 字段全部丢库。
  /// 修法: 父组件 build `CbtWizard` 时传 `onSaveRequested: _save`,
  /// wizard 末步 "完成" 按钮调 `onSaveRequested?.call()` 替代直接 pop。
  /// 父 `_save()` 内部走 `moodRepository.add()` + 成功后 pop + 错误 snackbar。
  final VoidCallback? onSaveRequested;

  const CbtWizard({super.key, this.onSaveRequested});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(cbtDraftProvider);
    final notifier = ref.read(cbtDraftProvider.notifier);

    final totalSteps = state.level.columnCount;
    final isLastStep = state.stepIndex == totalSteps - 1;

    return Column(
      children: [
        // 进度条
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
          child: LinearProgressIndicator(
            value: (state.stepIndex + 1) / totalSteps,
            minHeight: 4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
          child: Text(
            l10n.moodCbtStepOf(state.stepIndex + 1, totalSteps),
            style: AppTokens.textStyleMicro(context),
          ),
        ),
        // 顶部 ℹ️ 折叠卡
        Padding(
          padding: AppTokens.edgeInsetsMd,
          child: CbtExplainerCard(
            title: l10n.moodCbtExpandExplain,
            body: l10n.moodCbtExplainerBody,
            expanded: state.showExplainer,
            onToggle: notifier.toggleExplainer,
          ),
        ),
        // 当前 step section
        // v0.29 round 84 (final review fix): 去掉 Expanded — 父组件
        // (mood_recorder_page Dialog) 已包 SingleChildScrollView, 给的是
        // unbounded height, 内层 Expanded 拿不到 bounded 高度会触发
        // RenderFlex layout exception。父 SCV 自然滚动, 这里 SCV 仅留
        // 水平 padding 即可。
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
          child: _buildStep(context, state, notifier, l10n),
        ),
        // 上一/下一步
        Padding(
          padding: AppTokens.edgeInsetsMd,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: state.stepIndex == 0
                    ? null
                    : () => notifier.setStep(state.stepIndex - 1),
                child: Text(l10n.moodCbtPrevStep),
              ),
              FilledButton(
                onPressed: () {
                  if (isLastStep) {
                    // v0.30 round 92 (audit-fixes / P0 #11): 末步 "完成" 按钮
                    // 调父组件 onSaveRequested (MoodRecorderPage._save) →
                    // moodRepository.add 把 5/7 栏 CBT 字段落库, 然后父
                    // _save 内部 snackbar + Navigator.pop。
                    //
                    // 修前 bug: onPressed 写死 Navigator.pop(context), 父
                    // _save 没被调, 5/7 栏所有 CBT 字段 (situation /
                    // automaticThought / evidenceFor / evidenceAgainst /
                    // alternativeThought / reratedScore / coreBelief /
                    // behaviorResponse) 都丢库。
                    onSaveRequested?.call();
                  } else {
                    notifier.setStep(state.stepIndex + 1);
                  }
                },
                child: Text(
                  isLastStep ? l10n.moodCbtComplete : l10n.moodCbtNextStep,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep(
    BuildContext context,
    CbtDraftState state,
    CbtDraftNotifier notifier,
    AppLocalizations l10n,
  ) {
    final step = state.stepIndex;
    final level = state.level;

    // 5 栏 5 步 / 7 栏 7 步 映射
    if (step == 0) {
      return CbtSectionField(
        title: l10n.moodCbtSectionSituation,
        hint: l10n.moodCbtFieldHintSituation,
        prompts: const [],
        initialValue: state.draft.situation,
        onChanged: (v) => notifier.updateField(situation: v),
      );
    }
    if (step == 1) {
      return CbtSectionField(
        title: l10n.moodCbtSectionAutomaticThought,
        hint: l10n.moodCbtFieldHintAutomaticThought,
        prompts: [
          l10n.moodCbtAutoThoughtPrompt0,
          l10n.moodCbtAutoThoughtPrompt1,
          l10n.moodCbtAutoThoughtPrompt2,
        ],
        initialValue: state.draft.automaticThought,
        onChanged: (v) => notifier.updateField(automaticThought: v),
      );
    }
    if (step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.moodCbtStep2Header,
            style: AppTokens.textStyleLabel(context),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          // score 选择 (5 档:1-5) — v1.1.0 R114 (Wave D, spec §5.5):
          // ChoiceChip 改 5 档 72pt 圆形 MoodScoreButtons (跟 3 栏评分组同款)
          // v0.29 round 84 (Task 6 fix): 现在写 notifier.updateScore
          // (overwrite, 走 CBT 路径保留 8 个 CBT 字段)。
          MoodScoreButtons(
            value: state.draft.score,
            onChanged: (score) {
              notifier.updateScore(score);
            },
          ),
          const SizedBox(height: AppTokens.spacingMd),
          CbtSectionField(
            title: l10n.moodCbtSectionEvidenceFor,
            hint: l10n.moodCbtFieldHintEvidenceFor,
            prompts: const [],
            initialValue: state.draft.evidenceFor,
            onChanged: (v) => notifier.updateField(evidenceFor: v),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          CbtSectionField(
            title: l10n.moodCbtSectionEvidenceAgainst,
            hint: l10n.moodCbtFieldHintEvidenceAgainst,
            prompts: const [],
            initialValue: state.draft.evidenceAgainst,
            onChanged: (v) => notifier.updateField(evidenceAgainst: v),
          ),
        ],
      );
    }
    if (step == 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CbtSectionField(
            title: l10n.moodCbtSectionAlternative,
            hint: l10n.moodCbtFieldHintAlternative,
            prompts: [
              l10n.moodCbtAlternativePrompt0,
              l10n.moodCbtAlternativePrompt1,
            ],
            initialValue: state.draft.alternativeThought,
            onChanged: (v) => notifier.updateField(alternativeThought: v),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          Text(
            l10n.moodCbtScoreReratedLabel,
            style: AppTokens.textStyleLabel(context),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          // v1.1.0 R114 (Wave D, spec §5.5): 重新评分同样走 5 档圆形按钮
          // reratedScore 可空 (未评) → 0 = 无选中 (MoodScoreButtons 容忍越界值)
          MoodScoreButtons(
            value: state.draft.reratedScore ?? 0,
            onChanged: (score) {
              notifier.updateField(reratedScore: score);
            },
          ),
        ],
      );
    }
    if (step == 4 && level == ThoughtRecordLevel.five) {
      return Text(
        '${l10n.moodCbtConfirm}: ${state.draft.situation ?? l10n.moodCbtConfirmEmpty}',
        style: AppTokens.textStyleBody(context),
      );
    }
    if (step == 4 && level == ThoughtRecordLevel.seven) {
      return CbtSectionField(
        title: l10n.moodCbtSectionCoreBelief,
        hint: l10n.moodCbtFieldHintCoreBelief,
        prompts: const [],
        initialValue: state.draft.coreBelief,
        onChanged: (v) => notifier.updateField(coreBelief: v),
      );
    }
    if (step == 5) {
      return CbtSectionField(
        title: l10n.moodCbtSectionBehavior,
        hint: l10n.moodCbtFieldHintBehavior,
        prompts: [
          l10n.moodCbtBehaviorPrompt0,
          l10n.moodCbtBehaviorPrompt1,
          l10n.moodCbtBehaviorPrompt2,
        ],
        initialValue: state.draft.behaviorResponse,
        onChanged: (v) => notifier.updateField(behaviorResponse: v),
      );
    }
    if (step == 6) {
      return Text(
        '${l10n.moodCbtConfirm}: ${state.draft.situation ?? l10n.moodCbtConfirmEmpty}',
        style: AppTokens.textStyleBody(context),
      );
    }
    return const SizedBox.shrink();
  }
}
