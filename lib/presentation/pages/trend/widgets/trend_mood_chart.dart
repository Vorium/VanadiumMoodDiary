// v0.24 round 46 (emil B-12 god class 续拆): 情绪日记折线图
//
// 从 trend_charts.dart 拆出
//
// 高内聚：只关心 MoodEntryEntity 列表 → 折线图（5 档情绪）
// 低耦合：被 trend_page 调
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/trend/trend_utils.dart';
import 'package:chroniccare/presentation/widgets/mood_label.dart';

class MoodHistoryChart extends StatelessWidget {
  final List<MoodEntryEntity> entries;
  const MoodHistoryChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    // v0.27 R72 (P5.4): 整 build 包 RepaintBoundary
    // 跨 midnight 重建 / 切换月份时 LineChart 不重 paint
    return RepaintBoundary(
      child: _buildChart(context),
    );
  }

  /// 内部 helper: 拆 2 return 路径为 1, 配合 RepaintBoundary wrap
  Widget _buildChart(BuildContext context) {
    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: AppTokens.edgeInsetsLg,
          child: Column(
            children: [
              Icon(
                Icons.mood_outlined,
                size: 40,
                color: AppTokens.textSecondaryColor(context),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Text(
                AppLocalizations.of(context).trendNoMoodEntries,
                style: AppTokens.textStyleCaptionStrong(context),
              ),
              const SizedBox(height: AppTokens.spacingXxs),
              Text(
                AppLocalizations.of(context).trendNoMoodEntriesHint,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeCaption,
                  color: AppTokens.textSecondaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final sorted = [...entries]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final firstMs = sorted.first.timestamp.millisecondsSinceEpoch;
    final lastMs = sorted.last.timestamp.millisecondsSinceEpoch;
    double xOf(DateTime t) =>
        t.millisecondsSinceEpoch / 1000.0 / 86400.0 -
        firstMs / 1000.0 / 86400.0;

    final xMax = (lastMs - firstMs) / 1000.0 / 86400.0;
    final xMaxDisplay = xMax == 0 ? 1.0 : xMax + 0.5;

    final spots = sorted
        .map((e) => FlSpot(xOf(e.timestamp), e.score.toDouble()))
        .toList();
    final spotEntryIndex = <SpotKey, MoodEntryEntity>{};
    for (int i = 0; i < sorted.length; i++) {
      spotEntryIndex[SpotKey(spots[i].x, spots[i].y)] = sorted[i];
    }
    final nearestLookup = sorted.length == 1
        ? (double _) => sorted.first
        : NearestByX(spots, sorted).lookup;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.spacingSm,
          AppTokens.spacingMd,
          AppTokens.spacingMd,
          AppTokens.spacingMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppTokens.spacingXs,
              runSpacing: AppTokens.spacingXs,
              children: [
                for (int s = 1; s <= 5; s++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        MoodVisual.emojiFor(s),
                        style: AppTokens.textStyleCaption(context),
                      ),
                      const SizedBox(width: AppTokens.spacingXxxs),
                      Text(
                        moodLabel(AppLocalizations.of(context), s),
                        style: AppTokens.textStyleMicro(context),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingSm),
            // v0.26 round 57 (emil C-10): 走 chartPlaceholderHeight 集中器
            // 替代 inline height: 200 magic (LineChart 标准高度)
            SizedBox(
              height: AppTokens.chartPlaceholderHeight,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: xMaxDisplay,
                  minY: 0.5,
                  maxY: 5.5,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 2.5,
                      isCurved: spots.length > 1,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                          radius: 5,
                          color: AppColors.moodScoreColor(spot.y.round()),
                          strokeWidth: 1.5,
                          strokeColor: AppTokens.fgOnPrimary(context),
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        // v0.22 round 29 (emil-01~12): 改用 tintedPrimarySoft 集中器
                        color: AppTokens.tintedPrimarySoft(context),
                      ),
                    ),
                  ],
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Theme.of(context).dividerColor,
                      strokeWidth: 0.5,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, _) {
                          final s = value.toInt();
                          if (s < 1 || s > 5) return const SizedBox.shrink();
                          return Text(
                            MoodVisual.emojiFor(s),
                            style: AppTokens.textStyleCaption(context),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: xMaxDisplay <= 1
                            ? 0.5
                            : (xMaxDisplay / 4).ceilToDouble(),
                        getTitlesWidget: (value, _) {
                          if (xMaxDisplay <= 1) {
                            final dt = DateTime.fromMillisecondsSinceEpoch(
                              firstMs + (value * 86400 * 1000).round(),
                            );
                            return Text(
                              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                              style: AppTokens.textStyleMicro(context),
                            );
                          }
                          final dt = DateTime.fromMillisecondsSinceEpoch(
                            firstMs + (value * 86400 * 1000).round(),
                          );
                          return Text(
                            '${dt.month}/${dt.day}',
                            style: AppTokens.textStyleMicro(context),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touched) {
                        return touched.map((t) {
                          final entry = spotEntryIndex[SpotKey(t.x, t.y)];
                          final nearest = entry ?? nearestLookup(t.x);
                          final dt = nearest.timestamp;
                          final score = nearest.score.clamp(1, 5);
                          return LineTooltipItem(
                            '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}\n'
                            '${MoodVisual.emojiFor(score)} ${moodLabel(AppLocalizations.of(context), score)}',
                            TextStyle(
                              color: AppColors.moodScoreColor(score),
                              fontWeight: FontWeight.w600,
                              fontSize: AppTokens.fontSizeCaptionSm,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
