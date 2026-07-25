import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 4 维度评分行: label + 1-5 评分按钮
///
/// v0.23 round 44: 从 mood_dialog.dart 抽出为 public widget,
/// 供其他评分场景复用 (如趋势页 inline 评分)。
class DimensionRow extends StatelessWidget {
  final String label;
  final String hint;
  final int value;
  final ValueChanged<int> onChanged;

  const DimensionRow({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTokens.textStyleBodyStrong(context),
            ),
            Text(
              hint,
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: AppTokens.textHintColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.spacingXs),
        Semantics(
          container: true,
          label: '情绪评分，1 到 5 分制，5 分最积极',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int s = 1; s <= 5; s++)
                PressFeedback(
                  child: Semantics(
                    button: true,
                    inMutuallyExclusiveGroup: true,
                    selected: s == value,
                    label: '$s 分${s == value ? "，已选" : ""}',
                    child: Material(
                      color: Colors.transparent,
                      child: AnimatedContainer(
                        duration: AppTokens.durFast,
                        curve: AppTokens.curveStandard,
                        decoration: BoxDecoration(
                          color: s == value
                              ? AppTokens.tintedPrimarySoft(context)
                              : Colors.transparent,
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusChip),
                        ),
                        child: InkWell(
                          onTap: () => onChanged(s),
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusChip),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: AnimatedDefaultTextStyle(
                              duration: AppTokens.durFast,
                              curve: AppTokens.curveStandard,
                              style: TextStyle(
                                fontSize: AppTokens.fontSizeScoreLg,
                                fontWeight: s == value
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: s == value
                                    ? Theme.of(context).colorScheme.primary
                                    : AppTokens.textHintColor(context),
                              ),
                              child: Text('$s'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
