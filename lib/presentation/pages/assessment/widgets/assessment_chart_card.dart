// v0.24 round 46 (emil B-11 god class 续拆): ChartCard 抽到独立文件
//
// 每个量表一张折线图（PHQ-9 / GAD-7 各自一张）
//
// 高内聚：只关心 scaleId + records → 折线图
// 低耦合：被 AssessmentHistoryPage orchestrator 调，靠 assessment_severity_style 配色
//
// v0.32 R112 (EM-02/AH-04, spec §5.7): Card / AppListTile.carded →
// AppleListSection (iOS 群组列表)
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/assessment_record.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/assessment/widgets/assessment_severity_style.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

class AssessmentChartCard extends StatelessWidget {
  final String scaleId;
  final List<AssessmentRecord> records;
  const AssessmentChartCard({
    super.key,
    required this.scaleId,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (records.length < 2) {
      // v0.26 round 57 (emil C-12) 走 AppListTile.carded 集中器
      // v0.32 R112 (spec §5.7): carded → AppleListSection cell
      return AppleListSection(
        title: nameForScale(scaleId, l10n),
        margin: EdgeInsets.zero,
        children: [
          Row(
            children: [
              Icon(
                iconForScale(scaleId),
                color: AppTokens.primaryColor(context),
              ),
              const SizedBox(width: AppTokens.spacingSm),
              Expanded(
                child: Text(
                  records.isEmpty
                      ? l10n.assessmentChartNoData
                      : l10n.assessmentChartNeedMore,
                  style: AppTokens.textStyleCaption(context)
                      .copyWith(color: AppTokens.textSecondaryColor(context)),
                ),
              ),
            ],
          ),
        ],
      );
    }
    // 排序：最早在前（折线图从左到右时间正序）
    final sorted = [...records]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final maxScore = maxScoreForScale(scaleId);

    return AppleListSection(
      title: nameForScale(scaleId, l10n),
      margin: EdgeInsets.zero,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                AppLocalizations.of(context)
                    .assessmentChartRecordCount(sorted.length),
                style: TextStyle(
                  fontSize: AppTokens.fontSizeCaption,
                  color: AppTokens.textHintColor(context),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxScore.toDouble(),
                  minX: 0,
                  maxX: (sorted.length - 1).toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxScore / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppTokens.dividerColor(context),
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
                        interval: maxScore / 4,
                        getTitlesWidget: (value, _) => Text(
                          value.toInt().toString(),
                          style: AppTokens.textStyleMicro(context),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        // Bug I fix: 限制底轴 label 密度，最多约 6 个
                        interval: chartBottomInterval(sorted.length),
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i < 0 || i >= sorted.length) {
                            return const SizedBox.shrink();
                          }
                          final dt = sorted[i].timestamp;
                          return Text(
                            '${dt.month}/${dt.day}',
                            style: AppTokens.textStyleMicro(context),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < sorted.length; i++)
                          FlSpot(i.toDouble(), sorted[i].total.toDouble()),
                      ],
                      color: AppTokens.primaryColor(context),
                      barWidth: 2.5,
                      isCurved: false,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                          radius: 4,
                          color: assessmentSeverityStyle(
                            context,
                            scaleId,
                            spot.y.toInt(),
                            l10n,
                          ).color,
                          strokeWidth: 1.5,
                          strokeColor: AppTokens.fgOnPrimary(context),
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touched) {
                        return touched.map((t) {
                          final i = t.x.toInt();
                          if (i < 0 || i >= sorted.length) {
                            return null;
                          }
                          final r = sorted[i];
                          return LineTooltipItem(
                            '${r.timestamp.month}/${r.timestamp.day} '
                            '${r.timestamp.hour.toString().padLeft(2, '0')}:${r.timestamp.minute.toString().padLeft(2, '0')}\n'
                            '${AppLocalizations.of(context).assessmentChartTotalScore(r.total, maxScore)}',
                            TextStyle(
                              color: AppTokens.fgOnPrimary(context),
                              fontSize: AppTokens.fontSizeLabelSm,
                              fontWeight: FontWeight.w500,
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
      ],
    );
  }
}
