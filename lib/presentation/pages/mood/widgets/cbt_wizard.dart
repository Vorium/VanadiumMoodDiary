// v0.29 round 84 (CBT 思维记录): 5/7 栏 wizard
//
// 步骤式布局: 进度条 + 步数指示 + 当前 step section + 上一/下一步按钮
// 5 栏 5 步, 7 栏 7 步。切档由父组件 (mood_recorder_page) 通过
// SegmentedButton 触发, wizard 自身只读 cbtDraftProvider.
//
// 5 栏 5 步:
//   0 = 情境 (situation)
//   1 = 那一刻脑海中闪过的想法 (automatic thought)
//   2 = 情绪 + 证据 (score + evidenceFor + evidenceAgainst)
//   3 = 替代思维 + 重新评分 (alternativeThought + reratedScore)
//   4 = 确认
//
// 7 栏 7 步 (在 5 栏基础上):
//   5 = 核心信念 (coreBelief)
//   6 = 行为应对 (behaviorResponse)
//   4 = 核心信念 (覆盖 5 栏 step 4)
//   6 改为确认
//
// 频度: 切到 5/7 栏时显示,tens/day
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/thought_record_level.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_section_field.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_explainer_card.dart';

class CbtWizard extends ConsumerWidget {
  const CbtWizard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            '第 ${state.stepIndex + 1} 步 / 共 $totalSteps 步',
            style: AppTokens.textStyleMicro(context),
          ),
        ),
        // 顶部 ℹ️ 折叠卡
        Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: CbtExplainerCard(
            title: '什么是 CBT 思维记录？',
            body: 'CBT（认知行为疗法）思维记录帮你识别并重构负面自动思维。\n按 5 栏标准:先记录情境与想法,再找证据支持/反对,最后写下更平衡的替代想法。',
            expanded: state.showExplainer,
            onToggle: notifier.toggleExplainer,
          ),
        ),
        // 当前 step section
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
            child: _buildStep(context, state, notifier),
          ),
        ),
        // 上一/下一步
        Padding(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: state.stepIndex == 0
                    ? null
                    : () => notifier.setStep(state.stepIndex - 1),
                child: const Text('上一步'),
              ),
              FilledButton(
                onPressed: () {
                  if (isLastStep) {
                    // v0.29 round 84 (Task 6 fix): 真正的 save 走
                    // mood_recorder_page._save() (M
                    // oodSubmitPanel 调的)。wizard 只负责
                    // 关闭 dialog, 父组件 dispose 会 reset cbtDraftProvider。
                    // label 改 "完成" (不是 "保存") 避免误导用户以为已落库。
                    Navigator.of(context).pop();
                  } else {
                    notifier.setStep(state.stepIndex + 1);
                  }
                },
                child: Text(isLastStep ? '完成' : '下一步'),
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
  ) {
    final step = state.stepIndex;
    final level = state.level;

    // 5 栏 5 步 / 7 栏 7 步 映射
    if (step == 0) {
      return CbtSectionField(
        title: '情境',
        hint: '触发这个想法的事件是什么？发生在哪、什么时候、有谁？',
        prompts: const [],
        initialValue: state.draft.situation,
        onChanged: (v) => notifier.updateField(situation: v),
      );
    }
    if (step == 1) {
      return CbtSectionField(
        title: '那一刻脑海中闪过的想法',
        hint: '那一刻脑海中闪过的想法、印象或信念是什么？',
        prompts: const [
          '如果你的好朋友遇到这事,你会怎么劝TA？',
          '最坏/最好/最现实的结果是什么？',
          '一年后你还会这么想吗？',
        ],
        initialValue: state.draft.automaticThought,
        onChanged: (v) => notifier.updateField(automaticThought: v),
      );
    }
    if (step == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('情绪 + 证据', style: AppTokens.textStyleLabel(context)),
          const SizedBox(height: AppTokens.spacingSm),
          // score 选择 (5 档:1-5)
          // v0.29 round 84 (Task 6 fix): chip 现在写 notifier.updateScore
          // (overwrite, 走 CBT 路径保留 8 个 CBT 字段)。
          Wrap(
            spacing: AppTokens.spacingSm,
            children: List.generate(5, (i) {
              final score = i + 1;
              return ChoiceChip(
                label: Text('$score'),
                selected: state.draft.score == score,
                onSelected: (_) {
                  notifier.updateScore(score);
                },
              );
            }),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          CbtSectionField(
            title: '支持这个想法的证据',
            hint: '什么事支持这个想法？',
            prompts: const [],
            initialValue: state.draft.evidenceFor,
            onChanged: (v) => notifier.updateField(evidenceFor: v),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          CbtSectionField(
            title: '反对这个想法的证据',
            hint: '什么事不支持这个想法？',
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
            title: '替代思维',
            hint: '如果你的好朋友遇到这事,你会怎么劝TA？',
            prompts: const ['一年后你还会这么想吗？', '最现实的结果是什么？'],
            initialValue: state.draft.alternativeThought,
            onChanged: (v) => notifier.updateField(alternativeThought: v),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          Text('重新评分 (1-5)', style: AppTokens.textStyleLabel(context)),
          Wrap(
            spacing: AppTokens.spacingSm,
            children: List.generate(5, (i) {
              final score = i + 1;
              return ChoiceChip(
                label: Text('$score'),
                selected: state.draft.reratedScore == score,
                onSelected: (_) {
                  notifier.updateField(reratedScore: score);
                },
              );
            }),
          ),
        ],
      );
    }
    if (step == 4 && level == ThoughtRecordLevel.five) {
      return Text(
        '确认: ${state.draft.situation ?? "(未填)"}',
        style: AppTokens.textStyleBody(context),
      );
    }
    if (step == 4 && level == ThoughtRecordLevel.seven) {
      return CbtSectionField(
        title: '核心信念',
        hint: '这个想法背后更深层的信念是什么？（如 "我不够好"）',
        prompts: const [],
        initialValue: state.draft.coreBelief,
        onChanged: (v) => notifier.updateField(coreBelief: v),
      );
    }
    if (step == 5) {
      return CbtSectionField(
        title: '行为应对',
        hint: '接下来你打算怎么做？',
        prompts: const ['深呼吸 5 次', '与信任的人聊聊', '做 10 分钟正念'],
        initialValue: state.draft.behaviorResponse,
        onChanged: (v) => notifier.updateField(behaviorResponse: v),
      );
    }
    if (step == 6) {
      return Text(
        '确认: ${state.draft.situation ?? "(未填)"}',
        style: AppTokens.textStyleBody(context),
      );
    }
    return const SizedBox.shrink();
  }
}
