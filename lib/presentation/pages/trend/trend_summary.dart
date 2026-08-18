// trend_summary.dart — 趋势页顶部汇总卡片
//
// 从 trend_page.dart 拆分，v0.19 (P1-15)
//
// v0.27 round 67 (C-4): 抽 _Stat → StatCard 公共 widget (lib/presentation/widgets/stat_card.dart)
//
// v0.31 round 12 (Apple Health redesign · Phase 4 Task 4.1):
// 汇总卡片改 AppleListSection 风格 (spec §5.4 trend):
// - Card + Padding 模式 → AppleListSection 容器 (iOS 群组列表)
// - 4 StatCard 改 ultralight `large` variant (34pt w200, Phase 2 已重写)
// - 章节走 SectionHeader ALL CAPS (默认 isAllCaps: true, Phase 2 已加)
import 'package:flutter/material.dart';

import 'package:chroniccare/domain/logic/trend_calculator.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/stat_card.dart';

class SummaryCard extends StatelessWidget {
  final StreakSummary summary;
  const SummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // v0.31 round 12: 4 StatCard 装在 AppleListSection 内 (2x2 网格)
    // 跟 refill_manage_page Phase 3 R11a 同款模式 (iOS 群组列表容器)
    // R114 Wave B2 (B2-4): 删 margin: pageMarginH — TrendPage 在
    // PageScaffold 内 (已包 20px), 显式 20 曾叠加成 40px 双重 inset。
    return AppleListSection(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  label: l10n.trendStatCurrentStreak,
                  value: l10n.trendStatDaysValue(summary.currentStreak),
                  variant: StatCardVariant.large,
                ),
              ),
              const SizedBox(width: AppTokens.spacingSm),
              Expanded(
                child: StatCard(
                  label: l10n.trendStatLongestStreak,
                  value: l10n.trendStatDaysValue(summary.longestStreak),
                  variant: StatCardVariant.large,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.spacingSm),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  label: l10n.trendStatTotalCheckIns,
                  value: '${summary.totalCheckIns}',
                  variant: StatCardVariant.large,
                ),
              ),
              const SizedBox(width: AppTokens.spacingSm),
              Expanded(
                child: StatCard(
                  label: l10n.trendStatTotalDays,
                  value: '${summary.totalDays}',
                  variant: StatCardVariant.large,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
