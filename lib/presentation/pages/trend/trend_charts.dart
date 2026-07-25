// trend_charts.dart — 趋势页图表组件（热力图 + 月度柱状图 + 评估折线图 + 情绪折线图）
//
// 从 trend_page.dart 拆分，v0.19 (P1-15)
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/domain/logic/assessment_record.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:chroniccare/domain/logic/trend_calculator.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/trend/trend_utils.dart';

// =============================================================
// 30 天热力图
// =============================================================

class HeatmapGrid extends StatelessWidget {
  final List<DailyCheckIn> daily;
  const HeatmapGrid({super.key, required this.daily});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final d in daily)
              _HeatCell(
                date: d.date,
                checked: d.checked,
                size: ((constraints.maxWidth - 4 * 4) / 5).clamp(28.0, 48.0),
              ),
          ],
        );
      },
    );
  }
}

class _HeatCell extends StatelessWidget {
  final DateTime date;
  final bool checked;
  final double size;
  const _HeatCell({
    required this.date,
    required this.checked,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final color = checked
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    return Tooltip(
      message: '${date.month}/${date.day} ${checked ? "✓" : ""}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTokens.radiusCellLg),
        ),
      ),
    );
  }
}

// =============================================================
// 月度柱状图（fl_chart BarChart）
// =============================================================

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
      height: 200,
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

// =============================================================
// 量表评估历史折线图
// =============================================================

class AssessmentHistoryChart extends StatelessWidget {
  final List<AssessmentRecord> records;
  const AssessmentHistoryChart({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingLg),
          child: Column(
            children: [
              Icon(
                Icons.show_chart,
                size: 40,
                color: AppTokens.textSecondaryColor(context),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Text(
                AppLocalizations.of(context).trendNoAssessments,
                style: AppTokens.textStyleCaptionStrong(context),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).trendNoAssessmentsHint,
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

    // 按 scale 分组
    final byScale = <String, List<AssessmentRecord>>{};
    for (final r in records) {
      byScale.putIfAbsent(r.scaleId, () => []).add(r);
    }

    final sortedAll = [...records]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final firstMs = sortedAll.first.timestamp.millisecondsSinceEpoch;
    final lastMs = sortedAll.last.timestamp.millisecondsSinceEpoch;
    double xOf(DateTime t) =>
        t.millisecondsSinceEpoch / 1000.0 / 86400.0 -
        firstMs / 1000.0 / 86400.0;

    final xMax = (lastMs - firstMs) / 1000.0 / 86400.0;
    final xMaxDisplay = xMax == 0 ? 1.0 : xMax + 0.5;

    final palette = [
      Theme.of(context).colorScheme.primary,
      AppTokens.warning,
      AppTokens.error,
    ];

    final lines = <LineChartBarData>[];
    final legendItems = <Widget>[];
    int colorIdx = 0;
    final spotMeta =
        <SpotKey, ({AssessmentRecord rec, int rawMax, String name})>{};
    for (final scale in allScales()) {
      final recs = byScale[scale.id];
      if (recs == null || recs.isEmpty) continue;
      final color = palette[colorIdx % palette.length];
      final spots = recs
          .map(
            (r) => FlSpot(
              xOf(r.timestamp),
              r.total / scale.totalRange * 100,
            ),
          )
          .toList();
      for (int i = 0; i < recs.length; i++) {
        final key = SpotKey(spots[i].x, spots[i].y);
        spotMeta[key] = (
          rec: recs[i],
          rawMax: scale.totalRange,
          name: scale.displayName,
        );
      }
      lines.add(
        LineChartBarData(
          spots: spots,
          color: color,
          barWidth: 2.5,
          isCurved: spots.length > 1,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 3.5,
              color: color,
              strokeWidth: 1.5,
              strokeColor: AppTokens.fgOnPrimary(context),
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            // v0.22 round 29 (emil-01~12): 改用 tintedPrimarySoft 集中器 (0.1 接近原 0.12)
            color: AppTokens.tintedPrimarySoft(context),
          ),
        ),
      );
      legendItems.add(_LegendDot(color: color, label: scale.displayName));
      colorIdx++;
    }

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
              spacing: AppTokens.spacingMd,
              runSpacing: AppTokens.spacingXs,
              children: legendItems,
            ),
            const SizedBox(height: AppTokens.spacingSm),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: xMaxDisplay,
                  minY: 0,
                  maxY: 100,
                  lineBarsData: lines,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
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
                        reservedSize: 32,
                        interval: 25,
                        getTitlesWidget: (value, _) => Text(
                          '${value.toInt()}%',
                          style: AppTokens.textStyleMicro(context),
                        ),
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
                              (firstMs + (value * 86400 * 1000).round()),
                            );
                            return Text(
                              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                              style: AppTokens.textStyleMicro(context),
                            );
                          }
                          final dt = DateTime.fromMillisecondsSinceEpoch(
                            (firstMs + (value * 86400 * 1000).round()),
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
                          final dtMs = (firstMs + (t.x * 86400 * 1000).round());
                          final dt = DateTime.fromMillisecondsSinceEpoch(dtMs);
                          final meta = spotMeta[SpotKey(t.x, t.y)];
                          final rawTotal = meta?.rec.total ?? 0;
                          final rawMax = meta?.rawMax ?? 1;
                          final name = meta?.name ?? '';
                          final pct =
                              (rawMax == 0) ? 0.0 : (rawTotal / rawMax * 100);
                          return LineTooltipItem(
                            '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}\n'
                            '$name $rawTotal/$rawMax (${pct.toStringAsFixed(0)}%)',
                            TextStyle(
                              color: t.bar.color,
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTokens.textStyleLegal(context)),
      ],
    );
  }
}

// =============================================================
// 情绪日记折线图
// =============================================================

class MoodHistoryChart extends StatelessWidget {
  final List<MoodEntryEntity> entries;
  const MoodHistoryChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spacingLg),
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
              const SizedBox(height: 4),
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
                      const SizedBox(width: 2),
                      Text(
                        MoodVisual.labelFor(s),
                        style: AppTokens.textStyleMicro(context),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingSm),
            SizedBox(
              height: 200,
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
                          color: Color(MoodVisual.colorArgbFor(spot.y.round())),
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
                              (firstMs + (value * 86400 * 1000).round()),
                            );
                            return Text(
                              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                              style: AppTokens.textStyleMicro(context),
                            );
                          }
                          final dt = DateTime.fromMillisecondsSinceEpoch(
                            (firstMs + (value * 86400 * 1000).round()),
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
                            '${MoodVisual.emojiFor(score)} ${MoodVisual.labelFor(score)}',
                            TextStyle(
                              color: Color(MoodVisual.colorArgbFor(score)),
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
