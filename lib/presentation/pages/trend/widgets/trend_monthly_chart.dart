// v0.24 round 46 (emil B-12 god class 续拆): 月度柱状图
//
// 从 trend_charts.dart 拆出
//
// 高内聚：只关心 monthly → 柱状图
// 低耦合：被 trend_page 调
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/trend_calculator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

class MonthlyChart extends StatelessWidget {
  final List<MonthlyCheckIn> monthly;
  const MonthlyChart({super.key, required this.monthly});

  @override
  Widget build(BuildContext context) {
    if (monthly.isEmpty) return const SizedBox.shrink();
    final groups = <BarChartGroupData>[];
    for (int i = 0; i < monthly.length; i++) {
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: monthly[i].rate * 100,
              width: 18,
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(AppTokens.radiusCellLg),
            ),
          ],
        ),
      );
    }
    final maxY = (monthly
        .map((m) => m.rate * 100)
        .fold<double>(0, (a, b) => a > b ? a : b)).clamp(10, 100).toDouble();
    return SizedBox(
      // v0.26 round 57 (emil C-10): 走 chartPlaceholderHeight 集中器
      // 替代 inline height: 200 magic (BarChart 标准高度)
      height: AppTokens.chartPlaceholderHeight,
      child: BarChart(
        BarChartData(
          maxY: maxY,
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
                getTitlesWidget: (value, _) => Text(
                  '${value.toInt()}%',
                  style: AppTokens.textStyleMicro(context),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= monthly.length) {
                    return const SizedBox.shrink();
                  }
                  final m = monthly[idx].month;
                  return Text(
                    AppLocalizations.of(context).trendMonthLabel(m.month),
                    style: AppTokens.textStyleMicro(context),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
