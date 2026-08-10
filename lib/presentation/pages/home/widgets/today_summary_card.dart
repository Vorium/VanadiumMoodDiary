// v0.30 R101: 今日数据概览卡 — 参照 Apple Health Summary Pinned Favorites
//
// 主页 Header 下方，汇总今日 3-4 个关键指标:
// - 打卡状态 (✓/✗)
// - 今日药物进度 (2/3)
// - 最新心情分数
// - 连续打卡天数

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';

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

    // 最新心情（DB 级 LIMIT 1，不再全表扫描）
    final latestMood = latestMoodAsync.value;

    // 连续天数
    final streak = streakAsync.value;

    return Card(
      child: Padding(
        padding: AppTokens.edgeInsetsMd,
        child: Row(
          children: [
            _SummaryItem(
              icon: hasCheckedIn
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              iconColor: hasCheckedIn
                  ? AppTokens.primaryColor(context)
                  : AppTokens.textHintColor(context),
              label: l10n.todaySummaryCheckIn,
              value: hasCheckedIn ? '✓' : '—',
            ),
            _divider(context),
            _SummaryItem(
              icon: Icons.medication_outlined,
              iconColor: medDone == medTotal && medTotal > 0
                  ? AppTokens.primaryColor(context)
                  : AppTokens.textHintColor(context),
              label: l10n.todaySummaryMeds,
              value: medTotal > 0 ? '$medDone/$medTotal' : '—',
            ),
            _divider(context),
            _SummaryItem(
              icon: Icons.mood_outlined,
              iconColor: latestMood != null
                  ? Color(MoodVisual.colorArgbFor(latestMood.score))
                  : AppTokens.textHintColor(context),
              label: l10n.todaySummaryMood,
              value: latestMood != null
                  ? MoodVisual.emojiFor(latestMood.score)
                  : '—',
            ),
            _divider(context),
            _SummaryItem(
              icon: Icons.local_fire_department_outlined,
              iconColor: (streak?.streak ?? 0) > 0
                  ? AppColors.warning
                  : AppTokens.textHintColor(context),
              label: l10n.todaySummaryStreak,
              value: l10n.todaySummaryStreakDays(streak?.streak ?? 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: AppTokens.dividerColor(context),
      margin: const EdgeInsets.symmetric(horizontal: AppTokens.spacingXs),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 4),
          AnimatedSwitcher(
            duration: AppTokens.durFast,
            child: Text(
              value,
              key: ValueKey(value),
              style: TextStyle(
                fontSize: AppTokens.fontSizeBody,
                fontWeight: FontWeight.w700,
                color: AppTokens.textPrimaryColor(context),
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaptionSm,
              color: AppTokens.textHintColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
