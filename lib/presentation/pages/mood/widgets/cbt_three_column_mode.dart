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

import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
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
        // ① 情绪分数 1-5 (v0.30 R101: Slider + 颜色渐变, 参照 Apple Health)
        Text(
          l10n.moodCbtThreeScoreTitle,
          style: AppTokens.textStyleLabel(context),
        ),
        const SizedBox(height: AppTokens.spacingXs),
        Row(
          children: [
            // EM-08: 装饰性 emoji 刻度 (😢/😄), 20 是 slider 两端视觉
            // 配重字号 (无对应 token 档位), deliberate 保留
            const Text('😢', style: TextStyle(fontSize: 20)),
            Expanded(
              child: Slider(
                value: state.draft.score.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '${state.draft.score}',
                activeColor: _scoreColor(state.draft.score),
                onChanged: (v) => notifier.updateScore(v.round()),
              ),
            ),
            // EM-08: 同上 😄 装饰性 emoji 20, deliberate 保留
            const Text('😄', style: TextStyle(fontSize: 20)),
          ],
        ),
        Center(
          child: Text(
            '${state.draft.score}/5',
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              fontWeight: FontWeight.w600,
              color: _scoreTextColor(state.draft.score),
            ),
          ),
        ),
        const SizedBox(height: AppTokens.spacingMd),

        // ② 情境
        CbtSectionField(
          title: l10n.moodCbtThreeSituationTitle,
          hint: l10n.moodCbtFieldHintSituation,
          prompts: const [],
          initialValue: state.draft.situation,
          onChanged: (v) => notifier.updateField(situation: v),
        ),
        const SizedBox(height: AppTokens.spacingMd),

        // ③ 自动思维
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

  Color _scoreColor(int score) {
    switch (score) {
      case 1:
        return AppColors.error; // 红
      case 2:
        return AppColors.warningStrong; // 橙
      case 3:
        return AppColors.warning; // 黄
      case 4:
        return AppColors.success; // 浅绿
      case 5:
        return AppColors.primary; // 蓝
      default:
        return AppColors.disabled;
    }
  }

  /// v0.32 round 8 (R112 EM-16b fix): 分数文字色 — 浅色状态色白底对比度
  /// 2.3~3.0:1 不达标 (R111 EM-16 只修了 warning 档), 文字统一走深色档
  /// token; slider 轨道仍走 _scoreColor (浅色装饰)
  /// - 1 → fgError 深红 #C62828
  /// - 2 → fgWarningStrong 深橙 #BF360C
  /// - 3 → fgOnWarning 深橙 #E65100 (R111 EM-16)
  /// - 4 → fgOnSuccess 深绿 #2E7D32
  /// - 5 → primaryDark (品牌深绿 #248A3D; primary #34C759 白底 2.1:1
  ///   不达标, R112 EM-16b 补丁)
  Color _scoreTextColor(int score) => switch (score) {
        1 => AppColors.fgError,
        2 => AppColors.fgWarningStrong,
        3 => AppColors.fgOnWarning,
        4 => AppColors.fgOnSuccess,
        5 => AppColors.primaryDark,
        _ => AppColors.disabled,
      };
}
