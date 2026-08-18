// v0.29 round 84 (CBT 思维记录): 3 栏 mode 内容布局
//
// 情境 + 自动思维 2 个 section。score 选择 v1.1.0 R114 (Wave D, spec §5.5)
// 移出到 mood_recorder_page 情绪评分组 (5 档 72pt 圆形 MoodScoreButtons);
// 录音 + 标签 + 保存按钮由 mood_recorder_page 在底部提供。
//
// 频度: tens/day (mood 录入核心路径)
//
// 设计要点:
// 1. 复用 Task 4 公共 widget CbtSectionField (5/7 栏 wizard 也用)
// 2. onChanged 走 cbtDraftProvider.updateField
// 3. ConsumerWidget — 跟随 cbtDraftProvider 状态
// 4. Column 而非 ListView — 嵌入 mood_recorder_page dialog 的 SingleChildScrollView
//    (ListView 嵌套 SingleChildScrollView 会触发 unbounded height 错误)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/pages/mood/widgets/cbt_section_field.dart';

class CbtThreeColumnMode extends ConsumerWidget {
  const CbtThreeColumnMode({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(cbtDraftProvider);
    final notifier = ref.read(cbtDraftProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ① 情境
        CbtSectionField(
          title: l10n.moodCbtThreeSituationTitle,
          hint: l10n.moodCbtFieldHintSituation,
          prompts: const [],
          initialValue: state.draft.situation,
          onChanged: (v) => notifier.updateField(situation: v),
        ),
        const SizedBox(height: AppTokens.spacingMd),

        // ② 自动思维
        CbtSectionField(
          title: l10n.moodCbtThreeAutoTitle,
          hint: l10n.moodCbtFieldHintAutomaticThought,
          prompts: [
            l10n.moodCbtAutoThoughtPrompt0,
            l10n.moodCbtAutoThoughtPrompt1,
            l10n.moodCbtAutoThoughtPrompt2,
          ],
          initialValue: state.draft.automaticThought,
          onChanged: (v) => notifier.updateField(automaticThought: v),
        ),
      ],
    );
  }
}
