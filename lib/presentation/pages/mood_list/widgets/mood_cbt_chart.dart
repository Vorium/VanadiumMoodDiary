// v1.1.0 R116 (god class 拆): CBT 重评效果折线图
//
// 历史:
// - v0.30 R101: CBT 重评图 (5/7 栏思维记录 → score vs reratedScore)
// - v1.1.0 R114 (B2-5): CBT 图语义摘要 (重评条数)
// - v1.1.0 R116: 从 mood_trend_page.dart 653L god class 拆出
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// CBT 重评效果折线图
///
/// 5/7 栏思维记录 (含 situation / automaticThought / evidenceFor /
/// evidenceAgainst / alternativeThought / reratedScore) 的重评效果
/// 可视化, x 轴 = 重评条目 (按时间顺序), y 轴 = (reratedScore - score),
/// 0 上方 = 重评后分数上升 (认知重构有效)。
class MoodCbtEffectChart extends StatelessWidget {
  const MoodCbtEffectChart({
    super.key,
    required this.entries,
    required this.title,
    required this.hint,
    required this.emptyText,
  });

  final List<MoodEntryEntity> entries;
  final String title;
  final String hint;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final cbtEntries = entries
        .where((e) => e.reratedScore != null && e.isCbtRecord)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    if (cbtEntries.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(
            fontSize: AppTokens.fontSizeBody,
            color: AppTokens.textHintColor(context),
          ),
        ),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < cbtEntries.length; i++) {
      final shift =
          (cbtEntries[i].reratedScore! - cbtEntries[i].score).toDouble();
      spots.add(FlSpot(i.toDouble(), shift));
    }

    // R114 Wave B2 (B2-5): CBT 图语义摘要 (重评条数)
    return Semantics(
      container: true,
      label:
          AppLocalizations.of(context).moodTrendSemanticsCbt(cbtEntries.length),
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
            const SizedBox(height: AppTokens.spacingXxs),
            Text(
              hint,
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: AppTokens.textHintColor(context),
              ),
            ),
            const SizedBox(height: AppTokens.spacingMd),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: v == 0
                          ? AppTokens.textHintColor(context)
                          : AppTokens.dividerColor(context),
                      strokeWidth: v == 0 ? 1.5 : 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
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
                        reservedSize: 30,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= cbtEntries.length) {
                            return const SizedBox();
                          }
                          final e = cbtEntries[idx];
                          return Text(
                            '${e.timestamp.month}/${e.timestamp.day}',
                            style: TextStyle(
                              fontSize: AppTokens.fontSizeCaptionSm,
                              color: AppTokens.textHintColor(context),
                            ),
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
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      color: AppTokens.primaryColor(context),
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) {
                          // R32 (P0-10 集中器): mood score 颜色走 AppColors.moodScoreColor
                          final color =
                              AppColors.moodScoreColor(spot.y.round());
                          return FlDotCirclePainter(
                            radius: 4,
                            color: color,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTokens.primaryColor(context)
                            .withValues(alpha: 0.05),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
