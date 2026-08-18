// v0.30 round 100: 今日追踪汇总头部
//
// Apple Health 风格: 环形进度 + "已追踪 X/Y 项"
// 点击展开今日已追踪项列表

import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 今日追踪汇总头部
class TodayTrackingSummary extends StatelessWidget {
  final int trackedCount;
  final int totalCount;
  final List<String> trackedNames;

  const TodayTrackingSummary({
    super.key,
    required this.trackedCount,
    required this.totalCount,
    this.trackedNames = const [],
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final progress = totalCount > 0 ? trackedCount / totalCount : 0.0;

    return Card(
      elevation: 0,
      color: AppTokens.primaryColor(context).withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Row(
          children: [
            // 环形进度
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor:
                        AppTokens.primaryColor(context).withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTokens.primaryColor(context),
                    ),
                  ),
                  Text(
                    '$trackedCount',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTokens.primaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.spacingMd),
            // 文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.todayTrackingSummary(trackedCount, totalCount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (trackedNames.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      trackedNames.join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTokens.textHintColor(context),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
