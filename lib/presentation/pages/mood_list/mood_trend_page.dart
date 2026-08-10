// v0.30 R101: 情绪趋势图页 — 参照 Apple Health State of Mind
//
// 3 个 tab: 趋势(带时间范围选择器) / 分数分布 / CBT重评效果
// 时间范围: 7天 / 30天 / 6月 / 1年

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 时间范围
enum _TimeRange {
  week(7, '7D'),
  month(30, '30D'),
  halfYear(180, '6M'),
  year(365, '1Y');

  const _TimeRange(this.days, this.label);
  final int days;
  final String label;
}

class MoodTrendPage extends ConsumerStatefulWidget {
  const MoodTrendPage({super.key});

  @override
  ConsumerState<MoodTrendPage> createState() => _MoodTrendPageState();
}

class _MoodTrendPageState extends ConsumerState<MoodTrendPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  _TimeRange _timeRange = _TimeRange.week;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final moodsAsync = ref.watch(allMoodProvider);

    return PageScaffold(
      title: l10n.moodTrendTitle,
      appBarBottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: l10n.moodTrendWeek),
          Tab(text: l10n.moodTrendDistribution),
          const Tab(text: 'CBT'),
        ],
      ),
      child: moodsAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Text(
                l10n.moodTrendNoData,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeBody,
                  color: AppTokens.textHintColor(context),
                ),
              ),
            );
          }
          return TabBarView(
            controller: _tabController,
            children: [
              // 趋势 tab: 时间范围选择器 + 折线图
              _TrendTab(
                entries: entries,
                timeRange: _timeRange,
                onTimeRangeChanged: (r) => setState(() => _timeRange = r),
              ),
              _DistributionChart(
                  entries: entries, title: l10n.moodTrendDistTitle,),
              _CbtEffectChart(
                entries: entries,
                title: l10n.moodTrendCbtTitle,
                hint: l10n.moodTrendCbtHint,
                emptyText: l10n.moodTrendCbtEmpty,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 趋势 Tab: 时间范围选择器 + 折线图
// ═══════════════════════════════════════════════════════════════
class _TrendTab extends StatelessWidget {
  const _TrendTab({
    required this.entries,
    required this.timeRange,
    required this.onTimeRangeChanged,
  });

  final List<MoodEntryEntity> entries;
  final _TimeRange timeRange;
  final ValueChanged<_TimeRange> onTimeRangeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTokens.edgeInsetsMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间范围选择器
          _TimeRangeSelector(
            selected: timeRange,
            onChanged: onTimeRangeChanged,
          ),
          const SizedBox(height: AppTokens.spacingMd),
          // 折线图
          Expanded(
            child: _MoodLineChart(
              entries: entries,
              days: timeRange.days,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeRangeSelector extends StatelessWidget {
  const _TimeRangeSelector({
    required this.selected,
    required this.onChanged,
  });

  final _TimeRange selected;
  final ValueChanged<_TimeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SegmentedButton<_TimeRange>(
        segments: _TimeRange.values
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

// ═══════════════════════════════════════════════════════════════
// 通用折线图 (支持 7/30/180/365 天)
// ═══════════════════════════════════════════════════════════════
class _MoodLineChart extends StatelessWidget {
  const _MoodLineChart({required this.entries, required this.days});
  final List<MoodEntryEntity> entries;
  final int days;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: days - 1));
    final dailyAvg = <DateTime, double>{};
    for (final e in entries) {
      if (e.timestamp.isBefore(cutoff)) continue;
      final day =
          DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      dailyAvg[day] = (dailyAvg[day] ?? 0) == 0
          ? e.score.toDouble()
          : ((dailyAvg[day]! + e.score) / 2);
    }

    final spots = <FlSpot>[];
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      spots.add(FlSpot((days - 1 - i).toDouble(), dailyAvg[day] ?? 0));
    }

    // 底部标签间隔
    final labelInterval = days <= 7 ? 1.0 : (days <= 30 ? 5.0 : 30.0);

    return LineChart(
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
                final day =
                    DateTime(now.year, now.month, now.day - (days - 1 - idx));
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
              color: AppTokens.primaryColor(context).withValues(alpha: 0.1),
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// 分数分布直方图
// ═══════════════════════════════════════════════════════════════
class _DistributionChart extends StatelessWidget {
  const _DistributionChart({required this.entries, required this.title});
  final List<MoodEntryEntity> entries;
  final String title;

  @override
  Widget build(BuildContext context) {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final e in entries) {
      distribution[e.score] = (distribution[e.score] ?? 0) + 1;
    }
    final maxCount = distribution.values.fold<int>(0, (a, b) => a > b ? a : b);
    const colors = [
      Color(0xFFFF3B30),
      Color(0xFFFF9500),
      Color(0xFFFFCC00),
      Color(0xFF34C759),
      Color(0xFF007AFF),
    ];

    return Padding(
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
                            top: Radius.circular(6),),
                      ),
                    ],
                  );
                }),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxCount > 0
                      ? (maxCount / 4).ceilToDouble().clamp(1, double.infinity)
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CBT 重评趋势图
// ═══════════════════════════════════════════════════════════════
class _CbtEffectChart extends StatelessWidget {
  const _CbtEffectChart({
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

    return Padding(
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
                        final color = spot.y >= 0
                            ? const Color(0xFF34C759)
                            : const Color(0xFFFF3B30);
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
    );
  }
}
