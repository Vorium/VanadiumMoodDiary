import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/app_semantics.dart';
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
    final l10n = AppLocalizations.of(context);
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
        AppSemantics.container(
          label: l10n.moodRatingSemantics,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (int s = 1; s <= 5; s++)
                PressFeedback(
                  child: AppSemantics.button(
                    inMutuallyExclusiveGroup: true,
                    selected: s == value,
                    label: l10n.moodRatingButtonSemantics(s, s == value ? 'true' : 'false'),
                    child: Material(
                      color: Colors.transparent,
                      child: AnimatedContainer(
                        // v0.24 round 48 (emil P1-5): 之前用 AppTokens.durFast / curveStandard 直拼
                        // 系统开了 reduce-motion → 仍有 200ms 动画,违反 P0-7 reduce-motion non-negotiable
                        // 精神心理患者前庭敏感用户直接触发不适
                        // 现在走 Motion.duration / Motion.curve 包装,reduce-motion 自动归零
                        duration: Motion.duration(context, AppTokens.durFast),
                        curve: Motion.curve(context, AppTokens.curveStandard),
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
                              horizontal: AppTokens.spacingSm,
                              vertical: AppTokens.spacingXs,
                            ),
                            child: AnimatedDefaultTextStyle(
                              duration: Motion.duration(context, AppTokens.durFast),
                              curve: Motion.curve(context, AppTokens.curveStandard),
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
