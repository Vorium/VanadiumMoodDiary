// v0.30 round 91 (sub-spec 7 日常追踪 / Task 6): 多指标趋势图 widget
//
// 4 日常追踪指标 (体重 / 睡眠时长 / 心境均值 / 应激源均值) 叠加, 归一化 Y 轴
// (各指标单位不同 → 0-1) + 4 分散色 + 4 线型 + 顶部 FilterChip 列表 toggle
// 显示/隐藏。
//
// 用法:
// - daily_tracking_page 顶部 mini 趋势图 (Task 5 已留 SizedBox 占位,
//   Task 6 实施集成)
//
// 设计要点:
// - 颜色 / 线型 走 AppTokens.dailyTrackingColorFor / dailyTrackingDashFor
//   (放 lib/core/theme/app_tokens.dart facade, 4 指标固定枚举不放单独 palette)
// - Y 轴归一化 (各指标单位不同):
//   - 体重: (kg - 30) / (200 - 30)  → 0-1
//   - 睡眠: min / 720 (12h)         → 0-1
//   - 心境: avg / 5                  → 0-1
//   - 应激源: avg / 5                → 0-1
//   不归一化 → 体重 70kg 跟心境 3/5 在同图视觉错 (kg 满量程, 心境半量程)。
// - 心境 1 天 1 点 (4 段均值): 同日多段 entry 求平均
// - 应激源 1 天 1 点 (intensity 均值): 同日多 event 求平均
// - 30 天时间窗: 过滤 `e.timestamp.isBefore(now - 30d)`
// - chip 列表: SingleChildScrollView horizontal, 4 chip 不 wrap
// - chip avatar: Color 圆点 显示指标色 (色盲友好)
//
// 4 层架构: presentation 合法用 fl_chart / flutter/material。
// 放 presentation/widgets/charts/ (general) — 跟 R90 assessment_multi_line_chart
// 1:1 路径, 避免跨 feature import 边界违规 (v0.17 R12 rule)。

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/domain/entities/stress_event.dart';
import 'package:chroniccare/domain/entities/weight_entry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// v0.30 round 91 (sub-spec 7 日常追踪 / Task 6): 多指标趋势图
///
/// 4 指标 (体重 / 睡眠时长 / 心境均值 / 应激源均值), 复用 R90 chart 模式
/// (fl_chart LineChart + LineChartBarData + FilterChip 列表 toggle)。
///
/// 心境 1 天 1 点 (4 段均值), 应激源 1 天 1 点 (intensity 均值),
/// 体重 / 睡眠 原值。4 指标单位不同 → Y 轴归一化 0-1。
class DailyTrackingMultiChart extends StatefulWidget {
  /// 体重 entry 列表
  final List<WeightEntryEntity> weights;

  /// 睡眠 entry 列表
  final List<SleepEntryEntity> sleepEntries;

  /// 心境 entry 列表 (同日多段会取均值, 1 天 1 点)
  final List<MoodEntryEntity> moodEntries;

  /// 应激源 entry 列表 (同日多 event 会取 intensity 均值, 1 天 1 点)
  final List<StressEventEntity> stressEvents;

  /// 时间窗 (默认 30 天)
  final int daysWindow;

  /// chart 高度 (默认走 AppTokens.chartPlaceholderHeight 集中器)
  final double chartHeight;

  const DailyTrackingMultiChart({
    super.key,
    required this.weights,
    required this.sleepEntries,
    required this.moodEntries,
    required this.stressEvents,
    this.daysWindow = 30,
    this.chartHeight = AppTokens.chartPlaceholderHeight,
  });

  @override
  State<DailyTrackingMultiChart> createState() =>
      _DailyTrackingMultiChartState();
}

class _DailyTrackingMultiChartState extends State<DailyTrackingMultiChart> {
  /// 用户 toggle 隐藏的 metric id (不在集合内 = 显示)
  late Set<String> _hiddenMetrics;

  @override
  void initState() {
    super.initState();
    _hiddenMetrics = <String>{};
  }

  /// fl_chart 0.69 在 empty dashArray 上崩 (CircularIntervalList.next
  /// RangeError: Valid value range is empty: 0)。空 list → null 走"实线"分支。
  /// (跟 R90 assessment_multi_line_chart.dart 已知坑同款)
  static List<int>? _resolveDashArray(List<int> dash) =>
      dash.isEmpty ? null : dash;

  @override
  Widget build(BuildContext context) {
    // v0.27 R72 (P5.4): 整 build 包 RepaintBoundary 隔离 fl_chart 重绘
    final l10n = AppLocalizations.of(context);
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // v0.30 R91 Task 7: 多指标图标题走 l10n
          Text(
            l10n.dailyTrackingMultiChartTitle,
            style: AppTokens.textStyleLabelStrong(context),
          ),
          const SizedBox(height: AppTokens.spacingXs),
          _buildChipRow(context),
          const SizedBox(height: AppTokens.spacingSm),
          SizedBox(
            height: widget.chartHeight,
            child: LineChart(_buildLineChartData()),
          ),
        ],
      ),
    );
  }

  // ===================== 顶部 chip 列表 =====================

  Widget _buildChipRow(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final id in AppTokens.dailyTrackingMetricIds)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacingXxs,
              ),
              child: FilterChip(
                label: Text(_metricName(id, l10n)),
                selected: !_hiddenMetrics.contains(id),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _hiddenMetrics.remove(id);
                    } else {
                      _hiddenMetrics.add(id);
                    }
                  });
                },
                avatar: CircleAvatar(
                  backgroundColor: AppTokens.dailyTrackingColorFor(id),
                  radius: AppTokens.legendDotSizeLg / 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 4 指标 label
  /// R102 (P0-7): 硬编码中文 → 走 ARB (chartMetricWeight/Sleep/Mood/Stress)
  String _metricName(String id, AppLocalizations l10n) {
    switch (id) {
      case 'weight':
        return l10n.chartMetricWeight;
      case 'sleep':
        return l10n.chartMetricSleep;
      case 'mood':
        return l10n.chartMetricMood;
      case 'stress':
        return l10n.chartMetricStress;
    }
    return id;
  }

  // ===================== LineChart data =====================

  /// 提取日期字符串 (yyyy-MM-dd) 作为分组 key
  String _dayKey(DateTime t) {
    final d = t.toLocal();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  LineChartData _buildLineChartData() {
    // 时间窗: 在窗口内的 entry 才画 (避免早期 entry 撑爆 X 轴)
    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: widget.daysWindow));

    final bars = <LineChartBarData>[];

    // 体重: 1 entry 1 spot (直接归一化 weightKg)
    if (!_hiddenMetrics.contains('weight')) {
      final list = widget.weights
          .where((e) => e.timestamp.isAfter(cutoff))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      if (list.isNotEmpty) {
        final spots = list
            .map(
              (e) => FlSpot(
                e.timestamp.millisecondsSinceEpoch.toDouble(),
                _normalizeWeight(e.weightKg),
              ),
            )
            .toList();
        bars.add(
          LineChartBarData(
            spots: spots,
            color: AppTokens.dailyTrackingColorFor('weight'),
            dashArray: _resolveDashArray(
              AppTokens.dailyTrackingDashFor('weight'),
            ),
            isCurved: true,
            barWidth: 2.0,
            dotData: const FlDotData(show: true),
          ),
        );
      }
    }

    // 睡眠: 1 entry 1 spot (直接归一化 durationMin)
    if (!_hiddenMetrics.contains('sleep')) {
      final list = widget.sleepEntries
          .where((e) => e.date.isAfter(cutoff))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (list.isNotEmpty) {
        final spots = list
            .map(
              (e) => FlSpot(
                e.date.millisecondsSinceEpoch.toDouble(),
                _normalizeSleep(e.durationMin),
              ),
            )
            .toList();
        bars.add(
          LineChartBarData(
            spots: spots,
            color: AppTokens.dailyTrackingColorFor('sleep'),
            dashArray: _resolveDashArray(
              AppTokens.dailyTrackingDashFor('sleep'),
            ),
            isCurved: true,
            barWidth: 2.0,
            dotData: const FlDotData(show: true),
          ),
        );
      }
    }

    // 心境: 1 天 1 点 (同日多段 entry 求平均)
    if (!_hiddenMetrics.contains('mood')) {
      final byDay = <String, List<int>>{};
      for (final e
          in widget.moodEntries.where((e) => e.timestamp.isAfter(cutoff))) {
        (byDay[_dayKey(e.timestamp)] ??= <int>[]).add(e.score);
      }
      if (byDay.isNotEmpty) {
        // 显式 sort (v0.16 round 19/19B 已知坑: 不依赖 Map insertion order)
        final dayKeys = byDay.keys.toList()..sort();
        final spots = <FlSpot>[];
        for (final key in dayKeys) {
          final scores = byDay[key]!;
          final avg = scores.reduce((a, b) => a + b) / scores.length;
          // 用 day 00:00:00 作为 X 坐标 (避免同日不同段时间戳顺序影响)
          final parts = key.split('-');
          final dayTs = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          spots.add(
            FlSpot(
              dayTs.millisecondsSinceEpoch.toDouble(),
              _normalizeMood(avg),
            ),
          );
        }
        bars.add(
          LineChartBarData(
            spots: spots,
            color: AppTokens.dailyTrackingColorFor('mood'),
            dashArray: _resolveDashArray(
              AppTokens.dailyTrackingDashFor('mood'),
            ),
            isCurved: true,
            barWidth: 2.0,
            dotData: const FlDotData(show: true),
          ),
        );
      }
    }

    // 应激源: 1 天 1 点 (同日多 event 求 intensity 平均)
    if (!_hiddenMetrics.contains('stress')) {
      final byDay = <String, List<int>>{};
      for (final e
          in widget.stressEvents.where((e) => e.timestamp.isAfter(cutoff))) {
        (byDay[_dayKey(e.timestamp)] ??= <int>[]).add(e.intensity);
      }
      if (byDay.isNotEmpty) {
        final dayKeys = byDay.keys.toList()..sort();
        final spots = <FlSpot>[];
        for (final key in dayKeys) {
          final intensities = byDay[key]!;
          final avg = intensities.reduce((a, b) => a + b) / intensities.length;
          final parts = key.split('-');
          final dayTs = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          spots.add(
            FlSpot(
              dayTs.millisecondsSinceEpoch.toDouble(),
              _normalizeStress(avg),
            ),
          );
        }
        bars.add(
          LineChartBarData(
            spots: spots,
            color: AppTokens.dailyTrackingColorFor('stress'),
            dashArray: _resolveDashArray(
              AppTokens.dailyTrackingDashFor('stress'),
            ),
            isCurved: true,
            barWidth: 2.0,
            dotData: const FlDotData(show: true),
          ),
        );
      }
    }

    return LineChartData(
      lineBarsData: bars,
      minY: 0,
      maxY: 1,
      // 隐藏坐标轴 label (跟 R90 chart + R13 老 chart 一致, Task 6 ARB 暂不接)
      titlesData: const FlTitlesData(show: false),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
    );
  }

  // ===================== 归一化 (4 指标单位不同 → 0-1) =====================

  /// 体重 30-200 kg → 0-1
  double _normalizeWeight(double kg) => ((kg - 30) / (200 - 30)).clamp(0, 1);

  /// 睡眠 0-720 min (12h) → 0-1
  double _normalizeSleep(int min) => (min / (12 * 60)).clamp(0, 1);

  /// 心境 1-5 (均值) → 0-1
  double _normalizeMood(double avg) => (avg / 5).clamp(0, 1);

  /// 应激源 1-5 (均值) → 0-1
  double _normalizeStress(double avg) => (avg / 5).clamp(0, 1);
}
