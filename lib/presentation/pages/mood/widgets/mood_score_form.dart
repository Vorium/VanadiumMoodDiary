// v0.24 Sprint #5 (emil): 抽 MoodScoreForm 子 widget
//
// 从 mood_dialog.dart 706 行的 _MoodDialogContentState 抽出。
// 4 个 DimensionRow 顺序排列, 纯 stateless, 全 callback 透传。
//
// emil 设计决策:
// - 4 维度评分是 pure data, 无副作用, 不需要 state class
// - 复用 v0.23 round 44 抽的 DimensionRow (已有 PressFeedback + AppSemantics)
// - 8 个 required param (4 值 + 4 回调) 是 emil "decisions should be nameable" 显式化
//   (vs 传一个 struct, 强制 caller 知道有 4 个维度)
//
// 频度: tens/day (mood 录入是核心动作), 沿用 DimensionRow 的 AppSemantics 集中器
import 'package:flutter/material.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/dimension_row.dart';

/// 4 维度评分表单 (mood / energy / sleep / anxiety)
///
/// Stateless, 全 callback 上抛, 父组件持有 4 个 int + 4 个 setter。
class MoodScoreForm extends StatelessWidget {
  final int score;
  final int energy;
  final int sleep;
  final int anxiety;
  final ValueChanged<int> onScoreChanged;
  final ValueChanged<int> onEnergyChanged;
  final ValueChanged<int> onSleepChanged;
  final ValueChanged<int> onAnxietyChanged;

  const MoodScoreForm({
    super.key,
    required this.score,
    required this.energy,
    required this.sleep,
    required this.anxiety,
    required this.onScoreChanged,
    required this.onEnergyChanged,
    required this.onSleepChanged,
    required this.onAnxietyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DimensionRow(
          label: l10n.moodDimensionMood,
          hint: l10n.moodDimensionMoodHint,
          value: score,
          onChanged: onScoreChanged,
        ),
        const SizedBox(height: AppTokens.spacingSm),
        DimensionRow(
          label: l10n.moodDimensionEnergy,
          hint: l10n.moodDimensionEnergyHint,
          value: energy,
          onChanged: onEnergyChanged,
        ),
        const SizedBox(height: AppTokens.spacingSm),
        DimensionRow(
          label: l10n.moodDimensionSleep,
          hint: l10n.moodDimensionSleepHint,
          value: sleep,
          onChanged: onSleepChanged,
        ),
        const SizedBox(height: AppTokens.spacingSm),
        DimensionRow(
          label: l10n.moodDimensionAnxiety,
          hint: l10n.moodDimensionAnxietyHint,
          value: anxiety,
          onChanged: onAnxietyChanged,
        ),
      ],
    );
  }
}
