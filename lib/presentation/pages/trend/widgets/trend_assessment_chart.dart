// v0.24 round 46 (emil B-12 god class 续拆): 量表评估历史折线图
//
// 从 trend_charts.dart 拆出
//
// 高内聚：只关心 AssessmentRecord 列表 → 折线图（按 scale 分组）
// 低耦合：被 trend_page 调
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/assessment_record.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/trend/trend_utils.dart';

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
              const SizedBox(height: AppTokens.spacingXxs),
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
      AppTokens.warningColor(context),
      AppTokens.errorColor(context),
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

    // v0.27 R72 (P5.4): 主 chart 包 RepaintBoundary
    // 跨 midnight 重建 / 切换月份时 LineChart 不重 paint
    // (空 records 走 early return 不包, 一次性 fallback 不影响性能)
    return RepaintBoundary(
      child: Card(
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
              // v0.26 round 57 (emil C-10): 走 chartPlaceholderHeight 集中器
              // 替代 inline height: 200 magic (LineChart 标准高度)
              SizedBox(
                height: AppTokens.chartPlaceholderHeight,
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
                            final dtMs =
                                (firstMs + (t.x * 86400 * 1000).round());
                            final dt =
                                DateTime.fromMillisecondsSinceEpoch(dtMs);
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
          width: AppTokens.legendDotSizeSm,
          height: AppTokens.legendDotSizeSm,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTokens.spacingChipGap),
        Text(label, style: AppTokens.textStyleLegal(context)),
      ],
    );
  }
}
