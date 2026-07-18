// trend_summary.dart — 趋势页顶部汇总卡片
//
// 从 trend_page.dart 拆分，v0.19 (P1-15)
import 'package:flutter/material.dart';

import 'package:chroniccare/domain/logic/trend_calculator.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

class SummaryCard extends StatelessWidget {
  final StreakSummary summary;
  const SummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Row(
          children: [
            _Stat(label: '当前连续', value: '${summary.currentStreak} 天'),
            const SizedBox(width: AppTokens.spacingMd),
            _Stat(label: '最长连续', value: '${summary.longestStreak} 天'),
            const SizedBox(width: AppTokens.spacingMd),
            _Stat(label: '总打卡', value: '${summary.totalCheckIns}'),
            const SizedBox(width: AppTokens.spacingMd),
            _Stat(label: '总天数', value: '${summary.totalDays}'),
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
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
