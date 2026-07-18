// 趋势页（v0.7 新增，v0.8 加量表折线图，v0.9 加情绪折线图，
//        v0.12 / Round 6 加 list ↔ calendar 切换 + mood 入日历，
//        v0.13 / Round 10 展开"选中日详情"）
// - 顶部：当前连续天数 / 最长连续 / 总打卡 / 总天数
// - list 视图：30 天热力图 + 6 个月柱状图 + 心理评估 + 情绪历史
// - calendar 视图：当月 7×6 日历 + 选中日详情（所有事件列表）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/domain/logic/assessment_record.dart';
import 'package:chroniccare/domain/logic/day_detail.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:chroniccare/domain/logic/trend_calculator.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// v0.12 (Round 6) 视图模式
enum _TrendView { list, calendar }

class TrendPage extends ConsumerStatefulWidget {
  const TrendPage({super.key});

  @override
  ConsumerState<TrendPage> createState() => _TrendPageState();
}

class _TrendPageState extends ConsumerState<TrendPage> {
  _TrendView _view = _TrendView.list;
  // 日历视图：当前查看的月份（1 号 0 点）
  // v0.16 round 19 fix: 之前用 2 次 DateTime.now() 跨 midnight 时 year/month 可能不一致
  // （23:59:59.999 返回 (2026, 12)，00:00:00.001 返回 (2027, 1) → 错误的 month）
  DateTime _calendarMonth = _initialCalendarMonth();

  static DateTime _initialCalendarMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  @override
  Widget build(BuildContext context) {
    final checkInsAsync = ref.watch(allCheckInsProvider);
    final moodAsync = ref.watch(allMoodProvider);

    return PageScaffold(
      title: '我的趋势',
      child: checkInsAsync.when(
        data: (List<CheckInEntity> checkIns) {
          final moodEntries = moodAsync.maybeWhen(
            data: (m) => m,
            orElse: () => <MoodEntryEntity>[],
          );
          return _buildBody(context, checkIns, moodEntries);
        },
        loading: () => LoadingSkeleton.fullScreen(),
        error: (Object e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<CheckInEntity> checkIns,
    List<MoodEntryEntity> moodEntries,
  ) {
    final summary = TrendCalculator.streakSummary(checkIns: checkIns);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTokens.spacingMd),
          // 顶部统计 + 视图切换
          _SummaryCard(summary: summary),
          const SizedBox(height: AppTokens.spacingMd),
          _ViewToggle(
            current: _view,
            onChanged: (v) => setState(() => _view = v),
          ),
          const SizedBox(height: AppTokens.spacingMd),
          if (_view == _TrendView.list)
            _buildListView(context, checkIns)
          else
            _buildCalendarView(context, checkIns, moodEntries),
          const SizedBox(height: AppTokens.spacingXl),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<CheckInEntity> checkIns) {
    final daily = TrendCalculator.dailyBreakdown(checkIns: checkIns, days: 30);
    final monthly =
        TrendCalculator.monthlyBreakdown(checkIns: checkIns, months: 6);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '最近 30 天',
          style: TextStyle(
            fontSize: AppTokens.fontSizeLabel,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTokens.spacingSm),
        _HeatmapGrid(daily: daily),
        const SizedBox(height: AppTokens.spacingLg),
        Text(
          '最近 6 个月',
          style: TextStyle(
            fontSize: AppTokens.fontSizeLabel,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTokens.spacingSm),
        _MonthlyChart(monthly: monthly),
        const SizedBox(height: AppTokens.spacingLg),
        Text(
          '心理评估历史',
          style: TextStyle(
            fontSize: AppTokens.fontSizeLabel,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTokens.spacingSm),
        Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(assessmentsProvider);
            return async.when(
              data: (raw) {
                final records = raw
                    .map(AssessmentRecord.tryFromEntity)
                    .whereType<AssessmentRecord>()
                    .toList();
                return _AssessmentHistory(records: records);
              },
              loading: () => const SizedBox(
                height: 200,
                child: LoadingSkeleton.fullScreen(),
              ),
              error: (e, _) => Text('加载失败: $e'),
            );
          },
        ),
        const SizedBox(height: AppTokens.spacingLg),
        Text(
          '情绪日记历史',
          style: TextStyle(
            fontSize: AppTokens.fontSizeLabel,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTokens.spacingSm),
        Consumer(
          builder: (context, ref, _) {
            final async = ref.watch(allMoodProvider);
            return async.when(
              data: _MoodHistoryChart.new,
              loading: () => const SizedBox(
                height: 200,
                child: LoadingSkeleton.fullScreen(),
              ),
              error: (e, _) => Text('加载失败: $e'),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCalendarView(
    BuildContext context,
    List<CheckInEntity> checkIns,
    List<MoodEntryEntity> moodEntries,
  ) {
    final cm = TrendCalculator.monthlyCalendar(
      month: _calendarMonth,
      checkIns: checkIns,
      moodEntries: moodEntries,
    );
    // v0.13 (Round 10): 全集传给 CalendarView，用于"选中日详情"
    // v0.13 (Round 11): 返回 MedicationEntity 而非 Drift row
    final allMedications = ref.watch(allMedicationsProvider).maybeWhen(
          data: (m) => m,
          orElse: () => const <MedicationEntity>[],
        );
    return _CalendarView(
      calendar: cm,
      allCheckIns: checkIns,
      moodEntries: moodEntries,
      medications: allMedications,
      onPrevMonth: () {
        setState(() {
          _calendarMonth = TrendCalculator.shiftMonth(_calendarMonth, -1);
        });
      },
      onNextMonth: () {
        setState(() {
          _calendarMonth = TrendCalculator.shiftMonth(_calendarMonth, 1);
        });
      },
    );
  }
}

/// 顶部数据汇总卡片
class _SummaryCard extends StatelessWidget {
  final StreakSummary summary;
  const _SummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Row(
          children: [
            _Stat(label: '当前连续', value: '${summary.currentStreak} 天'),
            const SizedBox(width: AppTokens.spacingMd),
            _Stat(label: '最长连续', value: '${summary.longestStreak} 天'),
            const SizedBox(width: AppTokens.spacingMd),
            _Stat(label: '总打卡', value: '${summary.totalCheckIns}'),
            const SizedBox(width: AppTokens.spacingMd),
            _Stat(label: '总天数', value: '${summary.totalDays}'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeHeadline,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 30 天热力图（GitHub contribution style：6 行 × 5 列）
class _HeatmapGrid extends StatelessWidget {
  final List<DailyCheckIn> daily;
  const _HeatmapGrid({required this.daily});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 用 Wrap，每格 40x40，间距 4
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
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

/// 月度柱状图（fl_chart BarChart）
class _MonthlyChart extends StatelessWidget {
  final List<MonthlyCheckIn> monthly;
  const _MonthlyChart({required this.monthly});

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
              borderRadius: BorderRadius.circular(4),
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
                  style: const TextStyle(fontSize: 11),
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
                    '${m.month}月',
                    style: const TextStyle(fontSize: 11),
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

/// 多量表历史折线图
///
/// 设计：
/// - x 轴：相对天数（最早一次评估 = 0），底部 label 显示 MM/DD
/// - y 轴：归一化百分比 0-100（不同量表 totalRange 不同，0-100 统一可比）
/// - 每个有数据的量表一条线，颜色按注册表顺序分配
/// - 至少 2 个数据点才连成线
class _AssessmentHistory extends StatelessWidget {
  final List<AssessmentRecord> records;
  const _AssessmentHistory({required this.records});

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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppTokens.spacingSm),
              const Text(
                '还没有评估记录',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                '完成一次心理评估后，折线图会自动出现在这里',
                style: TextStyle(
                  fontSize: AppTokens.fontSizeCaption,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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

    // 找到所有评估里最早的日期，作为 x=0
    final sortedAll = [...records]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final firstMs = sortedAll.first.timestamp.millisecondsSinceEpoch;
    final lastMs = sortedAll.last.timestamp.millisecondsSinceEpoch;
    // 用"距离首日的秒数"作为 x 值（精度高于"天数"，避免同日多次评估重叠）
    double xOf(DateTime t) =>
        t.millisecondsSinceEpoch / 1000.0 / 86400.0 -
        firstMs / 1000.0 / 86400.0;

    final xMax = (lastMs - firstMs) / 1000.0 / 86400.0;
    // 至少留 0.5 天的余量，避免最新点贴边
    final xMaxDisplay = xMax == 0 ? 1.0 : xMax + 0.5;

    // 颜色：注册表顺序
    final palette = [
      Theme.of(context).colorScheme.primary,
      AppTokens.warning,
      AppTokens.error,
    ];

    // 构造每条线
    final lines = <LineChartBarData>[];
    final legendItems = <Widget>[];
    int colorIdx = 0;
    // B2 + B5 fix: 提前构造 (x, y) → record 元数据的反向索引。
    // tooltip 直接 O(1) 查原 record,避免浮点 == 几乎永远不匹配,
    // 也避免 tooltip 里再扫一遍 allScales。
    final spotMeta = <_SpotKey,
        ({
      AssessmentRecord rec,
      int rawMax,
      String name,
    })>{};
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
        final key = _SpotKey(spots[i].x, spots[i].y);
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
              strokeColor: Colors.white,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: color.withValues(alpha: 0.12),
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
            // 图例
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
                          style: const TextStyle(fontSize: 11),
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
                            // 全部在一天内：显示 HH:mm
                            final dt = DateTime.fromMillisecondsSinceEpoch(
                              (firstMs + (value * 86400 * 1000).round()),
                            ); // B5: round
                            return Text(
                              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          // 多天：显示 MM/DD
                          final dt = DateTime.fromMillisecondsSinceEpoch(
                            (firstMs + (value * 86400 * 1000).round()),
                          ); // B5: round
                          return Text(
                            '${dt.month}/${dt.day}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touched) {
                        return touched.map((t) {
                          // B2 fix: 用 spotMeta 反向索引查原 record
                          // 原来用整数除法 + 浮点 ==，几乎永远不匹配
                          final dtMs = (firstMs + (t.x * 86400 * 1000).round());
                          final dt = DateTime.fromMillisecondsSinceEpoch(dtMs);
                          final meta = spotMeta[_SpotKey(t.x, t.y)];
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
                              fontSize: 12,
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
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// =============================================================
// 情绪日记折线图（v0.9 新增）
// =============================================================

/// 情绪日记历史折线图
///
/// - x 轴：相对天数（最早一次记录 = 0）
/// - y 轴：分数 1-5，标签显示 emoji + "很差/差/一般/好/很好"
/// - 颜色按分数映射（差=蓝灰，好=绿）
/// - 至少 2 个点才连成线
class _MoodHistoryChart extends StatelessWidget {
  final List<MoodEntryEntity> entries;
  const _MoodHistoryChart(this.entries);

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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppTokens.spacingSm),
              const Text(
                '还没有情绪记录',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Text(
                '在主页点击「记一下情绪」开始记录',
                style: TextStyle(
                  fontSize: AppTokens.fontSizeCaption,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // x 轴：相对首日的天数（精度到秒，避免同日多次重叠）
    final sorted = [...entries]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final firstMs = sorted.first.timestamp.millisecondsSinceEpoch;
    final lastMs = sorted.last.timestamp.millisecondsSinceEpoch;
    double xOf(DateTime t) =>
        t.millisecondsSinceEpoch / 1000.0 / 86400.0 -
        firstMs / 1000.0 / 86400.0;

    final xMax = (lastMs - firstMs) / 1000.0 / 86400.0;
    final xMaxDisplay = xMax == 0 ? 1.0 : xMax + 0.5;

    // 多点用平均分颜色；单点用单色
    final spots = sorted
        .map((e) => FlSpot(xOf(e.timestamp), e.score.toDouble()))
        .toList();
    // N22 fix: 反向索引 spot → 原 entry,tooltip 用真实时间戳,
    // 避免浮点 round 误差导致时间标签错位
    final spotEntryIndex = <_SpotKey, MoodEntryEntity>{};
    for (int i = 0; i < sorted.length; i++) {
      spotEntryIndex[_SpotKey(spots[i].x, spots[i].y)] = sorted[i];
    }
    // P8 fix: 触摸在两个 spot 之间时,找 x 最接近的 spot。
    // 之前 fallback 到 t.y.round() 会取两个 spot 间的插值,误导用户。
    // 排序 spot 列表后用二分查找。
    final nearestLookup = sorted.length == 1
        ? (double _) => sorted.first
        : _NearestByX(spots, sorted).lookup;

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
            // 图例：1-5 颜色条
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
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        MoodVisual.labelFor(s),
                        style: const TextStyle(fontSize: 11),
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
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
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
                            style: const TextStyle(fontSize: 14),
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
                            ); // B5: round
                            return Text(
                              '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          final dt = DateTime.fromMillisecondsSinceEpoch(
                            (firstMs + (value * 86400 * 1000).round()),
                          ); // B5: round
                          return Text(
                            '${dt.month}/${dt.day}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touched) {
                        return touched.map((t) {
                          // N22 fix: 用 spotEntryIndex 反向查原 entry,
                          // 显示真实时间戳,不依赖浮点 round
                          final entry = spotEntryIndex[_SpotKey(t.x, t.y)];
                          // P8 fix: 用户触摸在两个 spot 之间时,反向索引查不到,
                          // 用 nearestLookup 找 x 最接近的 spot,
                          // 而不是用 t.y.round() (会取插值,误导)
                          final nearest = entry ?? nearestLookup(t.x);
                          final dt = nearest.timestamp;
                          final score = nearest.score.clamp(1, 5);
                          return LineTooltipItem(
                            '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}\n'
                            '${MoodVisual.emojiFor(score)} ${MoodVisual.labelFor(score)}',
                            TextStyle(
                              color: Color(MoodVisual.colorArgbFor(score)),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
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

/// 折线图 spot 的复合 key（B2 fix）
///
/// fl_chart 的 tooltip 只给 t.x / t.y，原代码用整数除法 + 浮点 ==
/// 反向查 record，几乎永远不匹配。这里用 round 后的整数做 key。
class _SpotKey {
  final int x; // round(x * 1e6) 微秒级精度
  final int y; // round(y * 100) 2 位小数
  _SpotKey(double x, double y)
      : x = (x * 1e6).round(),
        y = (y * 100).round();

  @override
  bool operator ==(Object other) =>
      other is _SpotKey && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// P8 fix: 给定 x 值,在按 x 升序排列的 spots/entries 中找 x 最接近的 entry
class _NearestByX {
  final List<double> _xs;
  final List<MoodEntryEntity> _entries;
  _NearestByX(List<FlSpot> spots, List<MoodEntryEntity> entries)
      : _xs = spots.map((s) => s.x).toList(),
        _entries = entries;

  MoodEntryEntity lookup(double x) {
    int lo = 0, hi = _xs.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_xs[mid] < x) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    // 比较 lo 和 lo-1,取更接近的
    if (lo > 0 && (x - _xs[lo - 1]).abs() < (_xs[lo] - x).abs()) {
      return _entries[lo - 1];
    }
    return _entries[lo];
  }
}

// =============================================================
// v0.12 (Round 6) 视图切换 + 日历视图
// =============================================================

/// 视图切换 SegmentedButton（list ↔ calendar）
class _ViewToggle extends StatelessWidget {
  final _TrendView current;
  final ValueChanged<_TrendView> onChanged;
  const _ViewToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_TrendView>(
      segments: const [
        ButtonSegment(
          value: _TrendView.list,
          label: Text('列表'),
          icon: Icon(Icons.view_list, size: 18),
        ),
        ButtonSegment(
          value: _TrendView.calendar,
          label: Text('日历'),
          icon: Icon(Icons.calendar_month, size: 18),
        ),
      ],
      selected: {current},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

/// 日历视图
///
/// - 7×6 网格
/// - 周一开头
/// - 上月/下月灰显
/// - 选中日有边框高亮
/// - 下方显示选中日详情（v0.13 Round 10 展开）
class _CalendarView extends StatefulWidget {
  final CalendarMonth calendar;
  final List<CheckInEntity> allCheckIns;
  final List<MoodEntryEntity> moodEntries;
  final List<MedicationEntity> medications;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  const _CalendarView({
    required this.calendar,
    required this.allCheckIns,
    required this.moodEntries,
    required this.medications,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  late DateTime _selected;
  final _today = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 默认选中今天（如果今天在当月），否则选当月 1 号
    final today = DateTime(_today.year, _today.month, _today.day);
    if (today.year == widget.calendar.month.year &&
        today.month == widget.calendar.month.month) {
      _selected = today;
    } else {
      _selected = widget.calendar.month;
    }
  }

  @override
  void didUpdateWidget(covariant _CalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切月后,如果 selected 不在当月了,重置到当月 1 号
    if (_selected.year != widget.calendar.month.year ||
        _selected.month != widget.calendar.month.month) {
      _selected = widget.calendar.month;
    }
  }

  static const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 月份切换头
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: widget.onPrevMonth,
              tooltip: '上个月',
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${widget.calendar.month.year} 年 '
                  '${widget.calendar.month.month} 月',
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: widget.onNextMonth,
              tooltip: '下个月',
            ),
          ],
        ),
        // 周标签
        Row(
          children: [
            for (final l in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    l,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.spacingXs),
        // 6 行 × 7 列
        for (int row = 0; row < 6; row++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                for (int col = 0; col < 7; col++)
                  Expanded(
                    child: _CalendarCell(
                      day: widget.calendar.cells[row * 7 + col],
                      inMonth:
                          widget.calendar.cells[row * 7 + col].date.month ==
                                  widget.calendar.month.month &&
                              widget.calendar.cells[row * 7 + col].date.year ==
                                  widget.calendar.month.year,
                      selected: _sameDate(
                        widget.calendar.cells[row * 7 + col].date,
                        _selected,
                      ),
                      isToday: _sameDate(
                        widget.calendar.cells[row * 7 + col].date,
                        DateTime(_today.year, _today.month, _today.day),
                      ),
                      onTap: () {
                        setState(() {
                          _selected = widget.calendar.cells[row * 7 + col].date;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppTokens.spacingMd),
        // 选中日详情（v0.13 Round 10 展开）
        _DayDetailCard(
          date: _selected,
          allCheckIns: widget.allCheckIns,
          moodEntries: widget.moodEntries,
          medications: widget.medications,
        ),
      ],
    );
  }

  static bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// 日历单元格
class _CalendarCell extends StatelessWidget {
  final CalendarDay day;
  final bool inMonth;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;
  const _CalendarCell({
    required this.day,
    required this.inMonth,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color? bg;
    if (selected) {
      bg = theme.colorScheme.primary.withValues(alpha: 0.18);
    } else if (day.hasNormalCheckIn) {
      bg = theme.colorScheme.primary.withValues(alpha: 0.85);
    } else if (day.moodScore != null) {
      bg = Color(MoodVisual.colorArgbFor(day.moodScore!));
    } else {
      bg = null;
    }

    final fg =
        day.hasNormalCheckIn ? Colors.white : theme.colorScheme.onSurface;
    final opacity = inMonth ? 1.0 : 0.35;

    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: bg ?? theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            side: isToday
                ? BorderSide(color: theme.colorScheme.primary, width: 1.5)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: opacity,
                    child: Text(
                      '${day.date.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: fg,
                      ),
                    ),
                  ),
                  if (day.moodScore != null && inMonth)
                    Positioned(
                      right: 2,
                      bottom: 1,
                      child: Text(
                        MoodVisual.emojiFor(day.moodScore!),
                        style: const TextStyle(fontSize: 8),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 选中日详情卡片（v0.13 Round 10 重写）
///
/// 列出当天所有 checkIns / moodEntries / assessments，
/// 按时间正序。空状态友好提示。
class _DayDetailCard extends StatelessWidget {
  final DateTime date;
  final List<CheckInEntity> allCheckIns;
  final List<MoodEntryEntity> moodEntries;
  final List<MedicationEntity> medications;
  const _DayDetailCard({
    required this.date,
    required this.allCheckIns,
    required this.moodEntries,
    required this.medications,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = DayDetailCalculator.fromData(
      date: date,
      checkIns: allCheckIns,
      moodEntries: moodEntries,
      medications: medications,
    );
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题：日期 + 完成状态徽章
            Row(
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeLabel,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                if (detail.hasNormalCheckIn)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                    ),
                    child: const Text(
                      '已打卡',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTokens.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.divider,
                      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                    ),
                    child: const Text(
                      '未打卡',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTokens.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const Spacer(),
                // 汇总：N 个事件
                if (detail.events.isNotEmpty)
                  Text(
                    '${detail.events.length} 个事件',
                    style: const TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textHint,
                    ),
                  ),
              ],
            ),
            // 情绪统计摘要（仅当有时显示）
            if (detail.bestMoodScore != null &&
                detail.worstMoodScore != null) ...[
              const SizedBox(height: AppTokens.spacingXs),
              Row(
                children: [
                  Icon(
                    Icons.mood_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    detail.bestMoodScore == detail.worstMoodScore
                        ? '${detail.totalMoodEntries} 条情绪记录 · ${MoodVisual.emojiFor(detail.bestMoodScore!)}'
                        : '情绪 ${detail.totalMoodEntries} 条 · '
                            '${MoodVisual.emojiFor(detail.worstMoodScore!)}→'
                            '${MoodVisual.emojiFor(detail.bestMoodScore!)}',
                    style: const TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppTokens.spacingSm),
            const Divider(height: 1),
            const SizedBox(height: AppTokens.spacingSm),
            // 事件列表
            if (detail.events.isEmpty)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppTokens.spacingSm),
                child: Row(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '这一天没有记录',
                      style: TextStyle(
                        color: AppTokens.textHint,
                        fontSize: AppTokens.fontSizeBody,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  for (int i = 0; i < detail.events.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 32),
                    _EventRow(event: detail.events[i]),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 单条事件行
class _EventRow extends StatelessWidget {
  final DayEvent event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color, timePrefix) = _kindVisuals(event, theme);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 时间
          SizedBox(
            width: 36,
            child: Text(
              timePrefix,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: AppTokens.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 图标
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          // 标题 + 副标题
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (event.subtitle != null && event.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.subtitle!,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _kindVisuals(DayEvent e, ThemeData theme) {
    final time = '${e.time.hour.toString().padLeft(2, '0')}:'
        '${e.time.minute.toString().padLeft(2, '0')}';
    switch (e.kind) {
      case DayEventKind.checkInNormal:
        return (
          Icons.check_circle,
          AppTokens.primary,
          time,
        );
      case DayEventKind.checkInTemp:
        return (
          Icons.healing_outlined,
          AppTokens.warning,
          time,
        );
      case DayEventKind.assessment:
        return (
          Icons.psychology_outlined,
          theme.colorScheme.tertiary,
          time,
        );
      case DayEventKind.mood:
        return (
          Icons.mood_outlined,
          e.moodScore != null
              ? Color(MoodVisual.colorArgbFor(e.moodScore!))
              : theme.colorScheme.onSurfaceVariant,
          time,
        );
    }
  }
}
