// v0.31 round 9a (Apple Health redesign · Phase 3 Task 3.1): TodaySummaryCard 重设
//
// 历史:
// - v0.30 R101: 今日数据概览卡 — 参照 Apple Health Summary Pinned Favorites
// - v0.31 R9a: 4 个 StatCard 2x2 网格 (今日打卡 / 连续天数 / 用药进度 / 心情)
//
// v1.1.0 round 11 (R115 视觉重构): 4 指标换血 — 删 用药 / streak (streak
// 已被 CheckInButton 表达), 留 情绪 / 树洞 / 睡眠 / 烦恼。
// emotion-first refactor 续作: 「今日指标」4 项全部是 vent / mood 周边,
// 跟双主卡语义一致, 不再出现「用药」「量表」字样。
//
// 4 个 StatCard 顺序: 情绪 (mood 粉色 emoji) / 烦恼 (worry 橙色数字) /
// 树洞 (vent 紫色数字) / 睡眠 (sleep 蓝色时长)。
// spacingSm 12 紧凑 2x2 grid, Row[Col[Stat1, Stat2], Col[Stat3, Stat4]]。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/presentation/providers/worry_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/stat_card.dart';

/// 主页"今日指标" 4 项 2x2 网格 (Apple Health 风格 AppleListSection)
///
/// v0.31 round 9a: 4 个 StatCard。
/// v1.1.0 round 11 (R115): 换血为 情绪 / 树洞 / 睡眠 / 烦恼 (emotion-first)。
class TodaySummaryCard extends ConsumerWidget {
  const TodaySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final latestMoodAsync = ref.watch(latestMoodProvider);
    final sleepAsync = ref.watch(sleepEntriesProvider);
    final worryOpenAsync = ref.watch(worryOpenProvider);
    final ventAsync = ref.watch(ventEntriesProvider);

    // 最新心情 (DB 级 LIMIT 1)
    final latestMood = latestMoodAsync.value;

    // 最新睡眠时长 (小时) — sleepEntriesProvider 已按 date 倒序, 取首条即最新
    final sleepEntries = (sleepAsync.value ?? const <SleepEntryEntity>[]);
    final latestSleepMin =
        sleepEntries.isEmpty ? null : sleepEntries.first.durationMin;
    final latestSleepHours =
        latestSleepMin != null ? (latestSleepMin / 60.0) : null;

    // 进行中烦恼数
    final worryOpenCount = worryOpenAsync.value?.length ?? 0;

    // 树洞数 — ventEntriesProvider autoDispose
    final ventCount = ventAsync.value?.length ?? 0;

    return AppleListSection(
      title: l10n.homeTodayOverview, // "今日概览" / "Today"
      margin: EdgeInsets.zero,
      children: [
        // 2x2 网格: Row[Col[Stat1, Stat2], Col[Stat3, Stat4]]
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    StatCard(
                      label: l10n.todaySummaryMood, // "心情"
                      value: latestMood != null
                          ? MoodVisual.emojiFor(latestMood.score)
                          : '—',
                      valueColor: latestMood != null
                          ? AppColors.moodScoreColor(latestMood.score)
                          : AppTokens.textHintColor(context),
                    ),
                    const SizedBox(height: AppTokens.spacingSm),
                    StatCard(
                      label: l10n.todaySummaryWorry, // "烦恼"
                      value: worryOpenCount.toString(),
                      valueColor: worryOpenCount > 0
                          ? AppColors.fgOnWarning
                          : AppTokens.textHintColor(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.spacingSm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    StatCard(
                      label: l10n.homeVentHeroTitle, // "树洞"
                      value: ventCount.toString(),
                      valueColor: ventCount > 0
                          ? const Color(0xFFAF52DE) // iOS systemPurple
                          : AppTokens.textHintColor(context),
                    ),
                    const SizedBox(height: AppTokens.spacingSm),
                    StatCard(
                      label: l10n.todaySummarySleep, // "睡眠"
                      value: latestSleepHours != null
                          ? latestSleepHours.toStringAsFixed(1)
                          : '—',
                      valueColor: latestSleepHours != null
                          ? AppTokens.primaryColor(context)
                          : AppTokens.textHintColor(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
