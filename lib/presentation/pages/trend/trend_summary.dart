// trend_summary.dart — 趋势页顶部汇总卡片
//
// 从 trend_page.dart 拆分，v0.19 (P1-15)
//
// v0.27 round 67 (C-4): 抽 _Stat → StatCard 公共 widget (lib/presentation/widgets/stat_card.dart)
import 'package:flutter/material.dart';

import 'package:chroniccare/domain/logic/trend_calculator.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/stat_card.dart';

class SummaryCard extends StatelessWidget {
  final StreakSummary summary;
  const SummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Row(
          children: [
            Expanded(
              child: StatCard(
                label: l10n.trendStatCurrentStreak,
                value: l10n.trendStatDaysValue(summary.currentStreak),
              ),
            ),
            const SizedBox(width: AppTokens.spacingMd),
            Expanded(
              child: StatCard(
                label: l10n.trendStatLongestStreak,
                value: l10n.trendStatDaysValue(summary.longestStreak),
              ),
            ),
            const SizedBox(width: AppTokens.spacingMd),
            Expanded(
              child: StatCard(
                label: l10n.trendStatTotalCheckIns,
                value: '${summary.totalCheckIns}',
              ),
            ),
            const SizedBox(width: AppTokens.spacingMd),
            Expanded(
              child: StatCard(
                label: l10n.trendStatTotalDays,
                value: '${summary.totalDays}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
