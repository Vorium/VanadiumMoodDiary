// v0.31 round 9a (Apple Health redesign · Phase 3 Task 3.1): TodaySummaryCard 重设
//
// 历史:
// - v0.30 R101: 今日数据概览卡 — 参照 Apple Health Summary Pinned Favorites
//
// v0.31 R9a 改造 (Apple Health 4 指标 2x2 网格):
// - 4 个 StatCard 2x2 网格 (今日打卡 / 连续天数 / 用药进度 / 心情)
// - 包装 AppleListSection("今日指标") 章节 (iOS 群组列表风格)
// - 4 个 StatCard 顺序: 今日打卡 (checkIn 绿色) / 连续天数 (streak 警示色) /
//   用药进度 (medication 红色, value="2/3") / 心情 (mood 粉色 emoji)
// - 间距 12 (spacingSm) — 紧凑 2x2 grid
// - Row[Col[Stat1, Stat2], Col[Stat3, Stat4]] 结构 + 中间 spacingMd 16 gap
//
// 设计选择:
// - 4 个 metric 顺序按用户最关心度: 打卡 > streak > 用药 > 心情
// - 打卡 / 心情用文字值 (✓ / emoji), streak / 用药用数字 (触发 StatCard tween)
// - 沿用原有 providers (todayAllCheckInsProvider / streakSummaryProvider /
//   medicationsProvider / latestMoodProvider) 不改业务数据流

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/stat_card.dart';

/// 主页"今日指标" 4 项 2x2 网格 (Apple Health 风格 AppleListSection)
///
/// v0.31 round 9a: 用 4 个 StatCard 替代原 4 列横排, 信息密度提升一档
/// (Apple Health Pinned Favorites 风格)。
class TodaySummaryCard extends ConsumerWidget {
  const TodaySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final todayCheckInsAsync = ref.watch(todayAllCheckInsProvider);
    final medsAsync = ref.watch(medicationsProvider);
    final latestMoodAsync = ref.watch(latestMoodProvider);
    final streakAsync = ref.watch(streakSummaryProvider);

    // 今日是否打卡
    final todayCheckIns = todayCheckInsAsync.value ?? [];
    final hasCheckedIn = todayCheckIns.any((c) => c.isNormal);

    // 今日药物进度
    final activeMeds = (medsAsync.value ?? []).where((m) => m.isInUse).toList();
    final todayMedIds = <int>{};
    for (final c in todayCheckIns) {
      if (c.isNormal && c.medicationId != null) {
        todayMedIds.add(c.medicationId!);
      }
    }
    final medDone = todayMedIds.length;
    final medTotal = activeMeds.length;

    // 最新心情 (DB 级 LIMIT 1)
    final latestMood = latestMoodAsync.value;

    // 连续天数
    final streak = streakAsync.value;
    final streakValue = streak?.streak ?? 0;

    return AppleListSection(
      // AppleListSection 自己 ALL CAPS 渲染, 中文不变
      // (但 iOS section header 标准做法是 13pt w500 ALL CAPS letterSpacing 0.6;
      //  中文是 case-less, 视觉等同 13pt w500 letterSpacing 0.6 textHint)
      title: '今日指标',
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
                      label: l10n.todaySummaryCheckIn,
                      value: hasCheckedIn ? '✓' : '—',
                      valueColor: hasCheckedIn
                          ? AppTokens.primaryColor(context)
                          : AppTokens.textHintColor(context),
                    ),
                    const SizedBox(height: AppTokens.spacingSm),
                    StatCard(
                      label: l10n.todaySummaryStreak,
                      value: streakValue.toString(),
                      valueColor: streakValue > 0
                          ? AppColors.warning
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
                      label: l10n.todaySummaryMeds,
                      value: medTotal > 0 ? '$medDone/$medTotal' : '—',
                      valueColor: (medDone == medTotal && medTotal > 0)
                          ? AppTokens.primaryColor(context)
                          : AppTokens.textHintColor(context),
                    ),
                    const SizedBox(height: AppTokens.spacingSm),
                    StatCard(
                      label: l10n.todaySummaryMood,
                      value: latestMood != null
                          ? MoodVisual.emojiFor(latestMood.score)
                          : '—',
                      valueColor: latestMood != null
                          ? Color(MoodVisual.colorArgbFor(latestMood.score))
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
