import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:chroniccare/presentation/widgets/secondary_button.dart';

/// 主页情绪快捷按钮
///
/// 显示规则：
/// - 今日已记录 → emoji + "今日情绪：好/差/一般/..."
/// - 今日未记录 → "记一下情绪 ✏️"
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
      return SecondaryButton(
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              MoodVisual.emojiFor(latest.score),
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(width: 8),
            Text(
              '今日情绪：${MoodVisual.labelFor(latest.score)}',
              style: const TextStyle(
                fontSize: AppTokens.fontSizeLabel,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    return SecondaryButton(
      onPressed: onTap,
      child: const Text(
        '记一下情绪 ✏️',
        style: TextStyle(
          fontSize: AppTokens.fontSizeButton,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
