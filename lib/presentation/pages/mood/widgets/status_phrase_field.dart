// v1.1.0 round 5d (Task 14): 状态短语选择器 — 预设 chips + "全部" 展开 + 自定义输入
//
// 与 MoodTags 同款设计: 选中态由 parent 持有 (state-hoisting), 子 widget
// 只负责渲染 + 回调。
//
// 交互:
// - 预设组 (StatusPhraseLibrary.phrasesForScore(score)) 按当前 score 方向
//   优先展示; "全部" 展开显示 StatusPhraseLibrary.all 全 17 条
// - 已选 chip 再 tap → onChanged(null) (清除)
// - TextField 自定义输入, submit → onChanged(trimmed)
// - 自定义值 (不在预设 all 内) 渲染为额外已选 chip, tap → 清除
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/status_phrase_library.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 情绪状态短语选择器（预设 chip + 自定义输入）
///
/// [score] 决定优先展示的短语组 (1-2 低落+疲惫 / 3 平静 / 4-5 积极)。
/// [value] 当前选中短语 (null = 未选), 由 parent 持有。
/// [onChanged] 选中 / 清除 / 自定义提交回调。
class StatusPhraseField extends StatefulWidget {
  final int score;
  final String? value;
  final ValueChanged<String?> onChanged;

  const StatusPhraseField({
    super.key,
    required this.score,
    required this.value,
    required this.onChanged,
  });

  @override
  State<StatusPhraseField> createState() => _StatusPhraseFieldState();
}

class _StatusPhraseFieldState extends State<StatusPhraseField> {
  bool _showAll = false;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pick(String phrase) {
    final isSelected = widget.value == phrase;
    _controller.clear();
    widget.onChanged(isSelected ? null : phrase);
  }

  void _clearCustom() {
    _controller.clear();
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final value = widget.value;
    final presets = _showAll
        ? StatusPhraseLibrary.all
        : StatusPhraseLibrary.phrasesForScore(widget.score);
    final isCustom =
        value != null && !StatusPhraseLibrary.all.contains(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.moodStatusPhraseTitle,
                style: AppTokens.textStyleLabelStrong(context),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(l10n.moodStatusPhraseShowAll),
            ),
          ],
        ),
        Wrap(
          // 跟 MoodTags 同款 (runSpacing: 4 是 FilterChip 内部行间距, 保留)
          spacing: AppTokens.spacingXs,
          runSpacing: 4,
          children: [
            for (final phrase in presets)
              FilterChip(
                label: Text(phrase),
                selected: value == phrase,
                onSelected: (_) => _pick(phrase),
              ),
            if (isCustom)
              FilterChip(
                label: Text(value),
                selected: true,
                onSelected: (_) => _clearCustom(),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.spacingXs),
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: l10n.moodStatusPhraseHint,
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (text) {
            final trimmed = text.trim();
            if (trimmed.isEmpty) return;
            widget.onChanged(trimmed);
          },
        ),
      ],
    );
  }
}
