// v0.24 Sprint #5 (emil): 抽 MoodTags 子 widget
//
// 从 mood_dialog.dart 抽出 6 个预设标签 (moodTagAnxiety/Depression/Calm/
// Insomnia/Irritable/LowEnergy) 的 FilterChip 多选。
//
// emil 设计决策:
// - 标签是 discrete state, 用 Set<String> (parent 持), onToggle 通知 add/remove
// - 不存到子 widget 内部 (避免 child 状态泄漏到 parent 的 setState)
// - l10n 标签文本在子 widget 内取, 靠近显示位置
import 'package:flutter/material.dart';

import 'package:chroniccare/l10n/app_localizations.dart';

/// 6 个预设情绪标签的多选
///
/// 标签选中态由 parent 持有的 [selected] Set 决定, 子 widget 无状态。
class MoodTags extends StatelessWidget {
  /// 当前已选中的标签集合
  final Set<String> selected;

  /// 标签 toggle 回调 — parent 决定 add/remove
  final ValueChanged<String> onToggle;

  const MoodTags({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final presetTags = <String>[
      l10n.moodTagAnxiety,
      l10n.moodTagDepression,
      l10n.moodTagCalm,
      l10n.moodTagInsomnia,
      l10n.moodTagIrritable,
      l10n.moodTagLowEnergy,
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final tag in presetTags)
          FilterChip(
            label: Text(tag),
            selected: selected.contains(tag),
            onSelected: (sel) => onToggle(tag),
          ),
      ],
    );
  }
}
