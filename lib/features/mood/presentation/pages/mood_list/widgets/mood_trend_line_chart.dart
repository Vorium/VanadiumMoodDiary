// v1.1.0 R116 (god class 拆): 趋势 tab + 时间范围选择器 + 折线图
//
// 历史:
// - v0.30 R101: 折线图 + 4 档时间范围 (7D/30D/6M/1Y)
// - v0.32 R112-01: 日均真均值
// - v1.1.0 R113 (BUG 9): 无数据日 = nullSpot
// - v1.1.0 R114 (B2-5): Semantics 摘要
// - v1.1.0 R116: 从 mood_trend_page.dart 653L god class 拆出
//
// 公开 API:
// - MoodTrendTab: 趋势 tab 整体 (时间范围选择器 + 折线图)
// - MoodTrendTimeRangeSelector: 4 档 SegmentedButton
// - MoodLineChart: 折线图 (含 0 数据日 nullSpot 处理 + Semantics)
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/features/mood/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/logic/mood_trend_calculator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';

/// 趋势 Tab: 时间范围选择器 + 折线图
class MoodTrendTab extends StatelessWidget {
  const MoodTrendTab({
    super.key,
    required this.entries,
    required this.timeRange,
    required this.onTimeRangeChanged,
  });

  final List<MoodEntryEntity> entries;
  final MoodTrendTimeRange timeRange;
  final ValueChanged<MoodTrendTimeRange> onTimeRangeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTokens.edgeInsetsMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MoodTrendTimeRangeSelector(
            selected: timeRange,
            onChanged: onTimeRangeChanged,
          ),
          const SizedBox(height: AppTokens.spacingMd),
          Expanded(
            child: MoodLineChart(
              entries: entries,
              days: timeRange.days,
            ),
          ),
        ],
      ),
    );
  }
}

/// 时间范围选择器 (4 档 SegmentedButton)
class MoodTrendTimeRangeSelector extends StatelessWidget {
  const MoodTrendTimeRangeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final MoodTrendTimeRange selected;
  final ValueChanged<MoodTrendTimeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SegmentedButton<MoodTrendTimeRange>(
        segments: MoodTrendTimeRange.values
            .map((r) => ButtonSegment(value: r, label: Text(r.label)))
            .toList(),
        selected: {selected},
        onSelectionChanged: (s) => onChanged(s.first),
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: AppTokens.fontSizeCaption),
          ),
        ),
      ),
    );
  }
}

/// 折线图 (支持 7/30/180/365 天)
class MoodLineChart extends ConsumerWidget {
  const MoodLineChart({super.key, required this.entries, required this.days});
  final List<MoodEntryEntity> entries;
  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wave 7 (Task B, R113): 修前 build 内 DateTime.now() 跨 midnight 不
    // rebuild → 图表窗口 stale 到次日。改 watch(todayProvider)
    // (watch dayChangeTickProvider, AppRoot 跨日 tick 自动刷新)。
    final now = ref.watch(todayProvider);
    // v1.1.0 R113 (BUG 9): 无数据日 = nullSpot (折线断开),
    // 修前 y=0 画成 0 分抑郁日
    final spots = computeTrendSpots(entries, now, days);

    // R114 Wave B2 (B2-5, 04-engineering A-01): 图表 0 Semantics — 修前
    // 视力障碍用户完全无法读趋势数据 (fl_chart 无内置语义)。外层
    // container label = 图表标题, 内层平均分 label 只在窗口内有数据时
    // 出现 (无数据日不参与均值 — 避免"空窗口 = 平均 0 分"误读,
    // 跟 R113 BUG 9 nullSpot 同原则)。
    final l10n = AppLocalizations.of(context);
    final valid = spots.where((s) => !s.y.isNaN).toList();
    final avg = valid.isEmpty
        ? null
        : valid.map((s) => s.y).reduce((a, b) => a + b) / valid.length;

    // 底部标签间隔
    final labelInterval = days <= 7 ? 1.0 : (days <= 30 ? 5.0 : 30.0);

    // v0.32 R112 round 8i (渲染专项): RepaintBoundary 隔离图表绘制 —
    // 外层 tab/时间范围切换时图表自身 paint 不进父 layer 重绘
    return Semantics(
      container: true,
      label: l10n.moodTrendSemanticsLine(days),
      child: Semantics(
        label: avg == null
            ? null
            : l10n.moodTrendSemanticsAvg(avg.toStringAsFixed(1)),
        child: RepaintBoundary(
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 30,
                    getTitlesWidget: (v, _) => v < 1 || v > 5
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
                    interval: labelInterval,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= days) return const SizedBox();
                      final day = DateTime(
                        now.year,
                        now.month,
                        now.day - (days - 1 - idx),
                      );
                      // 只显示月/日，短格式
                      return Text(
                        '${day.month}/${day.day}',
                        style: TextStyle(
                          fontSize: AppTokens.fontSizeCaptionSm,
                          color: AppTokens.textHintColor(context),
                        ),
                      );
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              minY: 0.5,
              maxY: 5.5,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: days <= 30,
                  color: AppTokens.primaryColor(context),
                  barWidth: days <= 30 ? 3 : 1.5,
                  dotData: FlDotData(
                    show: days <= 7,
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 4,
                      color: AppTokens.primaryColor(context),
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color:
                        AppTokens.primaryColor(context).withValues(alpha: 0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) => spots
                      .map(
                        (s) => LineTooltipItem(
                          s.y.toStringAsFixed(1),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: AppTokens.fontSizeCaption,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
