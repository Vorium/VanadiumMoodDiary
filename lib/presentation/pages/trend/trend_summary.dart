// trend_summary.dart — 趋势页顶部汇总卡片
//
// 从 trend_page.dart 拆分，v0.19 (P1-15)
import 'package:flutter/material.dart';

import 'package:chroniccare/domain/logic/trend_calculator.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

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
            _Stat(label: l10n.trendStatCurrentStreak, value: l10n.trendStatDaysValue(summary.currentStreak)),
            const SizedBox(width: AppTokens.spacingMd),
            _Stat(label: l10n.trendStatLongestStreak, value: l10n.trendStatDaysValue(summary.longestStreak)),
            const SizedBox(width: AppTokens.spacingMd),
            _Stat(label: l10n.trendStatTotalCheckIns, value: '${summary.totalCheckIns}'),
            const SizedBox(width: AppTokens.spacingMd),
            _Stat(label: l10n.trendStatTotalDays, value: '${summary.totalDays}'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeHeadline,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTokens.spacingXxs),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
