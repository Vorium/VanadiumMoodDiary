// v0.30 round 91 (sub-spec 7 日常追踪 / Task 2): mood 4 段聚合柱状图
//
// 4 柱 (morning / noon / evening / night) — Y 轴 score 1-5。
// 数据源: mood_period_aggregator.aggregateByPeriod (近 30 天窗口)。
//
// 跟 R90 AssessmentMultiLineChart 风格一致 (presentation/widgets/charts
// 那侧经验):
// - 复用 R90 palette: AppTokens 里后续 Task 6 (多指标图) 会加 4 指标色 +
//   4 线型; 本 task 4 柱用 AppTokens 现有 primary, 跟 R13 trend_monthly_chart
//   单色 BarChart 风格一致 (mood 是单指标, 不需要 palette)
// - RepaintBoundary 包 build (R72 P5.4 经验)
// - 标题: "心境 4 段趋势 (近 30 天)" (l10n.moodPeriodChartTitle, 本 task 加的)
// - daysWindow 默认 30, 跟 aggregator 一致
// - 0 entry → SizedBox.shrink (跟 R13 MonthlyChart 同款, 不画空轴)
//
// 用法 (Task 5 整合入口页 / Task 6 多指标图):
// - daily_tracking_page 顶部 mini 趋势图 placeholder
// - trend_assessment_chart 升级 mood 段
// - Card 内部: title (top) + chart (body) + caption (bottom, 各段 count)
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/logic/mood_period_aggregator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// mood 4 段聚合柱状图 (morning / noon / evening / night)
///
/// 数据流:
/// 1. entries → MoodPeriodAggregator.aggregateByPeriod(entries, daysWindow: 30)
/// 2. 4 段 (morning/noon/evening/night) 算 avg, 画 BarChart
/// 3. count 在每柱下方用 caption 显示 (用户想知道数据样本量)
class MoodPeriodAggregatorChart extends StatelessWidget {
  /// mood entries (跨天)
  final List<MoodEntryEntity> entries;

  /// 时间窗 (默认 30 天, 跟 aggregator 默认一致)
  final int daysWindow;

  /// chart 高度 (默认走 AppTokens.chartPlaceholderHeight 集中器)
  final double chartHeight;

  const MoodPeriodAggregatorChart({
    super.key,
    required this.entries,
    this.daysWindow = 30,
    this.chartHeight = AppTokens.chartPlaceholderHeight,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 0 entry → 不画 (跟 R13 MonthlyChart 同款)
    if (entries.isEmpty) return const SizedBox.shrink();

    final aggregates = MoodPeriodAggregator.aggregateByPeriod(
      entries,
      daysWindow: daysWindow,
    );

    // v0.27 R72 (P5.4): 整 build 包 RepaintBoundary
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Text(
            l10n.moodPeriodChartTitle,
            style: AppTokens.textStyleLabelStrong(context),
          ),
          const SizedBox(height: AppTokens.spacingSm),

          // 柱状图主体
          SizedBox(
            height: chartHeight,
            child: BarChart(_buildBarChartData(context, aggregates)),
          ),

          // 底部: 4 段 count caption (用户知道样本量)
          const SizedBox(height: AppTokens.spacingXs),
          _buildCountCaption(context, aggregates),
        ],
      ),
    );
  }

  // ============== 柱状图 BarChart data ==============

  BarChartData _buildBarChartData(
    BuildContext context,
    Map<String, PeriodAggregate> aggregates,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final groups = <BarChartGroupData>[];
    for (int i = 0; i < MoodPeriod.fourPeriods.length; i++) {
      final p = MoodPeriod.fourPeriods[i];
      final avg = aggregates[p]?.avg ?? 0.0;
      final count = aggregates[p]?.count ?? 0;
      // count=0 → 0 柱 (跟 R13 MonthlyChart 同款, 不画空柱骨架)
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: avg,
              width: 18,
              // 4 柱按 period 顺序给 4 个主题色 (m3 调色板顺序, 跟 R90
              // AssessmentColorPalette 4 量表配色思路一致; Task 6 多指标
              // 图会扩成 4 指标色, 本 task 暂时 4 个 primary tint)
              color: count == 0 ? colorScheme.outlineVariant : colorScheme.primary,
              borderRadius: BorderRadius.circular(AppTokens.radiusCellLg),
            ),
          ],
        ),
      );
    }

    return BarChartData(
      // Y 轴 0-5 (mood score 1-5, 含 0 = 无数据 兜底)
      minY: 0,
      maxY: 5,
      barGroups: groups,
      gridData: const FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 1,
            getTitlesWidget: (value, _) => Text(
              '${value.toInt()}',
              style: AppTokens.textStyleMicro(context),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, _) {
              final idx = value.toInt();
              if (idx < 0 || idx >= MoodPeriod.fourPeriods.length) {
                return const SizedBox.shrink();
              }
              final p = MoodPeriod.fourPeriods[idx];
              return Text(
                _periodShortLabel(p),
                style: AppTokens.textStyleMicro(context),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============== caption (count 摘要) ==============

  Widget _buildCountCaption(
    BuildContext context,
    Map<String, PeriodAggregate> aggregates,
  ) {
    final spans = <InlineSpan>[];
    for (int i = 0; i < MoodPeriod.fourPeriods.length; i++) {
      final p = MoodPeriod.fourPeriods[i];
      final count = aggregates[p]?.count ?? 0;
      spans.add(TextSpan(text: _periodShortLabel(p)));
      spans.add(
        TextSpan(
          text: ' $count',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
      if (i < MoodPeriod.fourPeriods.length - 1) {
        spans.add(const TextSpan(text: '  ·  '));
      }
    }
    return RichText(
      text: TextSpan(
        style: AppTokens.textStyleMicro(context),
        children: spans,
      ),
    );
  }

  /// 短标签 (跟 chart 底部 X 轴 label 同步)
  String _periodShortLabel(String period) {
    // 用 l10n 拿短 label — 跟 moodPeriodXxx 对齐
    // 不用 context (build 已传), 走 AppLocalizations.of(context) 在 build 内
    // 这里只 string fallback (跟 R13 MonthlyChart 同款 pattern)
    switch (period) {
      case MoodPeriod.morning:
        return '早';
      case MoodPeriod.noon:
        return '中';
      case MoodPeriod.evening:
        return '晚';
      case MoodPeriod.night:
        return '夜';
    }
    return period;
  }
}

/// 短 label 辅助 (l10n 版, 给 widget 用)
String moodPeriodShortLabel(BuildContext context, String period) {
  final l10n = AppLocalizations.of(context);
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
