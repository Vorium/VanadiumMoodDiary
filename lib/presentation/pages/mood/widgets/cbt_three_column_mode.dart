// v0.29 round 84 (CBT 思维记录): 3 栏 mode 内容布局
//
// 单屏长表式: 情绪分数 (1-5) + 情境 + 自动思维
// 录音 + 标签 + 保存按钮由 mood_recorder_page 在底部/顶部提供
//
// 频度: tens/day (mood 录入核心路径)
//
// 设计要点:
// 1. 复用 Task 4 公共 widget CbtSectionField (5/7 栏 wizard 也用)
// 2. score chip 用 ChoiceChip + 数字 (Task 8 集成时换为 DimensionRow IP emoji 风格)
// 3. onChanged 走 cbtDraftProvider.updateField / updateScore
// 4. ConsumerWidget — 跟随 cbtDraftProvider 状态
// 5. Column 而非 ListView — 嵌入 mood_recorder_page dialog 的 SingleChildScrollView
//    (ListView 嵌套 SingleChildScrollView 会触发 unbounded height 错误)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_section_field.dart';

class CbtThreeColumnMode extends ConsumerWidget {
  const CbtThreeColumnMode({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cbtDraftProvider);
    final notifier = ref.read(cbtDraftProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ① 情绪分数 1-5 (v0.29 round 84 Task 6 fix: 走 notifier.updateScore)
        Text('你现在的感受？', style: AppTokens.textStyleLabel(context)),
        const SizedBox(height: AppTokens.spacingXs),
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

        // ② 情境
        CbtSectionField(
          title: '发生了什么？',
          hint: '触发这个想法的事件是什么？发生在哪里、什么时候、有谁？',
          prompts: const [],
          initialValue: state.draft.situation,
          onChanged: (v) => notifier.updateField(situation: v),
        ),
        const SizedBox(height: AppTokens.spacingMd),

        // ③ 自动思维
        CbtSectionField(
          title: '那一刻脑海里闪过什么想法？',
          hint: '那一瞬间脑中闪过的想法、印象或意象是什么？',
          prompts: const [
            '如果你的好朋友遇到这事, 你会怎么想？',
            '最坏 / 最好 / 最现实的结果是什么？',
            '一年后你还会这么想吗？',
          ],
          initialValue: state.draft.automaticThought,
          onChanged: (v) => notifier.updateField(automaticThought: v),
        ),
      ],
    );
  }
}
