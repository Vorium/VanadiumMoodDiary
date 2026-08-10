// v0.30 round 85 (CBT 重评效果图): score vs reratedScore 双线对比
//
// 跟 MoodHistoryChart 同模式 (fl_chart + RepaintBoundary + EmptyState):
// - 数据 < 3 条 → 显示空态 (Card + icon + 2 text)
// - 数据 ≥ 3 条 → 显示双线 fl_chart (原评分实线 + 重评后虚线)
//
// 业务规则:
// - 来自 cbtReratedEntriesProvider (cbtLevel >= 5), 但其中可能有
//   缺 reratedScore 的 partial CBT 记录, 这里在 widget 内部再次 filter
//   (self-contained, 不依赖 caller 已过滤)
//
// 视觉规则:
// - Y 轴固定 1-5 (5 档情绪), X 轴 = 时间戳 (跟 MoodHistoryChart 一致)
// - 原评分: AppTokens.primaryColor 实线
// - 重评后: AppTokens.success 虚线 (视觉对比, 暗示"好转")
// - **Delta 阴影区**: fl_chart 0.69 `BetweenBarsData(fromIndex:0, toIndex:1)`
//   在 score 线跟 reratedScore 线之间填充半透明 success 色, 把
//   "重评效果"做成可视面积 (圆角/特殊色相留给 sub-spec 3 微调)
// - 极简图例: 颜色块 + 短线, 区分实线/虚线, 不加 label 词条 (避免 2 个
//   新 i18n key, 用户从 Y 轴范围 1-5 + 5 档情绪 emoji 已能识别)
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

class ReratedScoreChart extends StatelessWidget {
  final List<MoodEntryEntity> entries;
  const ReratedScoreChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    // 跟 MoodHistoryChart 一致: 整 build 包 RepaintBoundary, 跨 midnight
    // 重建 / 切换月份时 LineChart 不重 paint。
    return RepaintBoundary(
      child: _buildChart(context),
    );
  }

  /// 内部 helper: 拆 2 return 路径为 1, 配合 RepaintBoundary wrap。
  Widget _buildChart(BuildContext context) {
    // self-contained filter: caller 传进来的 entries 可能含 reratedScore == null
    // 的 partial CBT 记录 (cbtLevel=5 但没填完所有字段), 绘图前要剔除。
    final withRerated = entries.where((e) => e.reratedScore != null).toList();
    if (withRerated.length < 3) {
      return _emptyState(context);
    }
    return _fullChart(context, withRerated);
  }

  Widget _emptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppTokens.edgeInsetsLg,
        child: Column(
          children: [
            Icon(
              Icons.insights,
              size: 40,
              color: AppTokens.textSecondaryColor(context),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            Text(
              AppLocalizations.of(context).trendCbtReratedEmptyTitle,
              style: AppTokens.textStyleCaptionStrong(context),
            ),
            const SizedBox(height: AppTokens.spacingXxs),
            Text(
              AppLocalizations.of(context).trendCbtReratedEmptyHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: AppTokens.textSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fullChart(BuildContext context, List<MoodEntryEntity> sorted) {
    // 按时间排序 (production-safe: 隐式 orderBy 是 silent bug, 见 AGENTS.md)
    final ordered = [...sorted]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final firstMs = ordered.first.timestamp.millisecondsSinceEpoch;
    final lastMs = ordered.last.timestamp.millisecondsSinceEpoch;
    double xOf(DateTime t) =>
        t.millisecondsSinceEpoch / 1000.0 / 86400.0 -
        firstMs / 1000.0 / 86400.0;
    final xMaxRaw = (lastMs - firstMs) / 1000.0 / 86400.0;
    final xMaxDisplay = xMaxRaw == 0 ? 1.0 : xMaxRaw + 0.5;

    final originalSpots = ordered
        .map((e) => FlSpot(xOf(e.timestamp), e.score.toDouble()))
        .toList();
    final reratedSpots = ordered
        .map((e) => FlSpot(xOf(e.timestamp), e.reratedScore!.toDouble()))
        .toList();

    return Card(
      child: Padding(
        padding: AppTokens.edgeInsetsLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).trendCbtReratedChartTitle,
              style: AppTokens.textStyleTitle(context),
            ),
            const SizedBox(height: AppTokens.spacingXxs),
            const _Legend(),
            const SizedBox(height: AppTokens.spacingMd),
            SizedBox(
              height: AppTokens.chartPlaceholderHeight,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: xMaxDisplay,
                  minY: 0.5,
                  maxY: 5.5,
                  titlesData: const FlTitlesData(show: false),
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _buildLine(
                      context,
                      spots: originalSpots,
                      color: AppTokens.primaryColor(context),
                      isDashed: false,
                    ),
                    _buildLine(
                      context,
                      spots: reratedSpots,
                      color: AppTokens.success,
                      isDashed: true,
                    ),
                  ],
                  // Delta 阴影: lineBarsData[0] (score) 和 [1] (reratedScore)
                  // 之间的"重评效果"区域, 半透明 success 暗示"好转"方向。
                  // alpha 0.15: 不抢线条, 仍能一眼分辨 delta 厚度。
                  betweenBarsData: [
                    BetweenBarsData(
                      fromIndex: 0,
                      toIndex: 1,
                      color: AppTokens.success.withValues(alpha: 0.15),
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

  LineChartBarData _buildLine(
    BuildContext context, {
    required List<FlSpot> spots,
    required Color color,
    required bool isDashed,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: spots.length > 1,
      barWidth: 2,
      color: color,
      dashArray: isDashed ? const [5, 5] : null,
      dotData: const FlDotData(show: false),
    );
  }
}

/// 极简图例: 颜色块 + 短线, 区分实线/虚线。
/// 不读 i18n label 词条 — 颜色 + 虚实已足够识别, 避免加 2 个新 i18n key。
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendItem(
          color: AppTokens.primaryColor(context),
          isDashed: false,
        ),
        const SizedBox(width: AppTokens.spacingMd),
        const _LegendItem(
          color: AppTokens.success,
          isDashed: true,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final bool isDashed;
  const _LegendItem({required this.color, required this.isDashed});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 颜色块宽度 = 图例项视觉宽度, 高度 = 2 跟 line 宽度一致
        SizedBox(
          width: 24,
          height: 2,
          child: CustomPaint(
            painter: _LegendLinePainter(
              color: color,
              isDashed: isDashed,
            ),
          ),
        ),
      ],
    );
  }
}

/// 用 CustomPaint 画实线 / 虚线, 跟 fl_chart 的 dashArray 视觉一致
class _LegendLinePainter extends CustomPainter {
  final Color color;
  final bool isDashed;
  _LegendLinePainter({required this.color, required this.isDashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.butt;
    final y = size.height / 2;
    if (!isDashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      return;
    }
    const dashWidth = 4.0;
    const dashGap = 3.0;
    double x = 0;
    while (x < size.width) {
      final end = (x + dashWidth).clamp(0.0, size.width);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _LegendLinePainter old) =>
      old.color != color || old.isDashed != isDashed;
}
