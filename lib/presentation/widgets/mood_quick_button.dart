import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/mood_label.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/secondary_button.dart';

/// 主页情绪快捷按钮
///
/// 显示规则：
/// - 今日已记录 → emoji + "今日情绪：好／差／一般／..."
/// - 今日未记录 → "记一下情绪 ✏️"
///
/// v0.23 P1 refactor: 从 presentation/pages/mood/ 移到 widgets/，
/// 解除 home → mood 跨 feature import。
class MoodQuickButton extends ConsumerWidget {
  final VoidCallback onTap;
  const MoodQuickButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayMoodProvider);
    final latest = todayAsync.maybeWhen(
      data: (list) => list.isEmpty ? null : list.first,
      orElse: () => null,
    );
    final hasToday = latest != null;

    if (hasToday) {
      // v0.24 round 48 (emil P1-7): 改用接管 tap 模式
      // 之前 PressFeedback(child: SecondaryButton(onPressed: onTap)) 嵌套
      // PressFeedback scale 160ms + InkWell ripple 300ms 叠 → pointer 抬起时 scale 先恢复 + ripple 还在扩散 → 体感"分裂"
      // 现在 PressFeedback 接管 tap + SecondaryButton onPressed: () {} 不重复触发
      return PressFeedback(
        onTap: onTap,
        child: SecondaryButton(
          onPressed: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                MoodVisual.emojiFor(latest.score),
                style: const TextStyle(fontSize: AppTokens.fontSizeBodySm),
              ),
              const SizedBox(width: AppTokens.spacingXs),
              Text(
                // v0.32 round 8 (R112-06 emil): 参数化 ARB key
                // (moodTodayLabelWithValue), 修前字符串拼接
                // `'${l10n.moodTodayLabel}${moodLabel(...)}'` 对 zh 是 "今日情绪：好"
                // 自然, 但 en "Mood: Good" 靠 moodTodayLabel 带尾随空格硬拼,
                // 空格在 ARB 里不可见容易漂移。走 placeholder 后 3 语独立控制。
                AppLocalizations.of(context).moodTodayLabelWithValue(
                  moodLabel(AppLocalizations.of(context), latest.score),
                ),
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeLabel,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return PressFeedback(
      onTap: onTap,
      child: SecondaryButton(
        onPressed: () {},
        child: Text(
          AppLocalizations.of(context).moodRecordButton,
          style: const TextStyle(
            fontSize: AppTokens.fontSizeButton,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
