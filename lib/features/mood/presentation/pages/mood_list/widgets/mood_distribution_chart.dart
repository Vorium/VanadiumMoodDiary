// v1.1.0 R116 (god class 拆): 情绪分数分布直方图
//
// 历史:
// - v0.30 R101: 5 档 (1-5) 分布图
// - v0.32 R32 (P0-10 集中器): 5 元素 mood 色板移到 AppColors.kMoodScoreColors
// - v1.1.0 R114 (B2-5): 分布图语义摘要 (最常见分 + 总条数)
// - v1.1.0 R116: 从 mood_trend_page.dart 653L god class 拆出
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/features/mood/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 情绪分数分布直方图 (1-5 档)
class MoodDistributionChart extends StatelessWidget {
  const MoodDistributionChart({
    super.key,
    required this.entries,
    required this.title,
  });

  final List<MoodEntryEntity> entries;
  final String title;

  @override
  Widget build(BuildContext context) {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final e in entries) {
      distribution[e.score] = (distribution[e.score] ?? 0) + 1;
    }
    final maxCount = distribution.values.fold<int>(0, (a, b) => a > b ? a : b);
    // R32 (P0-10 集中器): 5 元素 mood 色板移到 AppColors.kMoodScoreColors
    const colors = AppColors.kMoodScoreColors;

    // R114 Wave B2 (B2-5): 分布图语义摘要 (最常见分 + 总条数)
    final total = entries.length;
    final mostCommon = maxCount == 0
        ? null
        : distribution.entries.firstWhere((e) => e.value == maxCount).key;
    final l10n = AppLocalizations.of(context);

    return RepaintBoundary(
      child: Semantics(
        container: true,
        label: mostCommon == null
            ? null
            : l10n.moodTrendSemanticsDist(mostCommon, total),
        child: Padding(
          padding: AppTokens.edgeInsetsMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeBody,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTokens.spacingMd),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxCount > 0 ? maxCount.toDouble() * 1.2 : 5,
                    barGroups: List.generate(5, (i) {
                      return BarChartGroupData(
                        x: i + 1,
                        barRods: [
                          BarChartRodData(
                            toY: (distribution[i + 1] ?? 0).toDouble(),
                            color: colors[i],
                            width: 40,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxCount > 0
                          ? (maxCount / 4)
                              .ceilToDouble()
                              .clamp(1, double.infinity)
                          : 1,
                      getDrawingHorizontalLine: (v) => FlLine(
                        color: AppTokens.dividerColor(context),
                        strokeWidth: 0.5,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (v, _) => v != v.roundToDouble()
                              ? const SizedBox()
                              : Text(
                                  v.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: AppTokens.fontSizeCaptionSm,
                                    color: AppTokens.textHintColor(context),
                                  ),
                                ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            const labels = ['', '😢', '😟', '😐', '🙂', '😄'];
                            final idx = v.toInt();
                            if (idx < 1 || idx > 5) return const SizedBox();
                            return Text(
                              labels[idx],
                              // EM-08: chart 横轴 emoji 刻度装饰性 20,
                              // deliberate 保留 (emoji 有 size cap)
                              style: const TextStyle(fontSize: 20),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
