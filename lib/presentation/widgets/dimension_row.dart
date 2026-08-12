import 'package:flutter/material.dart';

import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/core/theme/app_colors.dart';
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
                    label: l10n.moodRatingButtonSemantics(
                      s,
                      s == value ? 'true' : 'false',
                    ),
                    child: Material(
                      color: AppColors.transparent,
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
                              : AppColors.transparent,
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
                              duration:
                                  Motion.duration(context, AppTokens.durFast),
                              curve: Motion.curve(
                                context,
                                AppTokens.curveStandard,
                              ),
                              style: TextStyle(
                                fontSize: AppTokens.fontSizeScoreLg,
                                fontWeight: s == value
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: s == value
                                    ? Theme.of(context).colorScheme.primary
                                    : AppTokens.textHintColor(context),
                              ),
                              child: Text(
                                // v0.28 R81: 数字 1-5 改 IP 化太阳 emoji 5 档
                                // (☀️🌤⛅🌧⛈), 跟 B 站"哗哩哗哩能量加油站" 4 情绪
                                // 太阳 + 嘴型风格对齐, 病耻感中性化
                                // (太阳是普遍治愈系符号, 不带疾病标签)
                                // emil 频度: tens/day (mood 录入核心动作)
                                // — standard animation OK
                                MoodVisual.ipEmojiFor(s),
                              ),
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
