// v0.30 round 91 (sub-spec 7 日常追踪 / Task 2): mood list 时段 chip filter
//
// 6 chip (全部 / 早 / 中 / 晚 / 夜 / 未指定) — 单选, ChoiceChip selected 视觉
// 区分当前 bucket。点 chip → moodListFilterProvider.setPeriod(bucket)
//
// 设计要点 (跟 R87 MoodListFilterBar / R90 AssessmentMultiLineChipRow 同款):
// - ConsumerWidget (跟 R87 filter bar 模式, ref.watch state + ref.read notifier)
// - ChoiceChip 配 selected + onSelected 走 toggle (再点同一 chip 取消 → 全部)
// - 走 l10n.moodListFilterPeriod + moodPeriodXxx (5 段 + 1 "全部" label)
// - 横排 SingleChildScrollView, 跟 R87 filter bar 一样的横向布局风格
// - 4 层架构: 只引 flutter material + theme tokens + l10n + domain (via provider)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/mood_period_aggregator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/mood_list_filter_provider.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// mood list 顶部的心境时段 chip filter
///
/// 6 chip (全部 / 早 / 中 / 晚 / 夜 / 未指定) — 单选。
/// 任何 chip 操作直接改 moodListFilterProvider state (setPeriod),
/// 上层 MoodListPage 用 ref.watch(filteredMoodEntriesProvider) 自动重渲染。
class MoodListPeriodFilterBar extends ConsumerWidget {
  const MoodListPeriodFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filter = ref.watch(moodListFilterProvider);
    final notifier = ref.read(moodListFilterProvider.notifier);
    final currentBucket = filter.period; // null = 全部

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.pageMarginH,
        vertical: AppTokens.spacingXs,
      ),
      child: Row(
        children: [
          // "全部" chip (null = 不过滤)
          PressFeedback(
            child: ChoiceChip(
              label: Text(l10n.moodListPeriodAll),
              selected: currentBucket == null,
              onSelected: (_) => notifier.setPeriod(null),
            ),
          ),
          const SizedBox(width: AppTokens.spacingXs),

          // 5 段 chip (morning/noon/evening/night/unspecified)
          for (final p in MoodPeriod.all) ...[
            ChoiceChip(
              label: Text(_labelFor(l10n, p)),
              selected: currentBucket == p,
              onSelected: (selected) {
                // 再点同一 chip 取消 (返回 null = 全部)
                notifier.setPeriod(selected ? p : null);
              },
            ),
            const SizedBox(width: AppTokens.spacingXs),
          ],
        ],
      ),
    );
  }

  String _labelFor(AppLocalizations l10n, String period) {
    switch (period) {
      case MoodPeriod.morning:
        return l10n.moodPeriodMorning;
      case MoodPeriod.noon:
        return l10n.moodPeriodNoon;
      case MoodPeriod.evening:
        return l10n.moodPeriodEvening;
      case MoodPeriod.night:
        return l10n.moodPeriodNight;
      case MoodPeriod.unspecified:
        return l10n.moodPeriodUnspecified;
    }
    return period;
  }
}
