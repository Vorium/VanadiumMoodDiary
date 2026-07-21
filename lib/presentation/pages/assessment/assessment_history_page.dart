// v0.14 (Round 13B) 心理评估历史完整页面
//
// 独立页面：列出所有 PHQ-9 / GAD-7 评估 + 折线图 + 与上次对比
// 入口：home_page 心理评估图标（之前直接跳 phq9 答题）
// 入口：settings → "心理评估" section
// 入口：trend_page 评估历史小节（点击查看全部）
//
// 数据流：assessmentsProvider → AssessmentRecord.tryFromEntity → UI
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/logic/assessment_comparison.dart';
import 'package:chroniccare/domain/logic/assessment_record.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

class AssessmentHistoryPage extends ConsumerWidget {
  const AssessmentHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(assessmentsProvider);
    return PageScaffold(
      title: AppLocalizations.of(context).settingsAssessmentHistory,
      child: async.when(
        data: (all) {
          final records = all
              .map(AssessmentRecord.tryFromEntity)
              .whereType<AssessmentRecord>()
              .toList();
          if (records.isEmpty) {
            return _AssessmentHistoryEmptyState();
          }
          return _buildBody(context, ref, records);
        },
        loading: () => const LoadingSkeleton.fullScreen(),
        // v0.22 round 29 (emil-44): 改用 ErrorState 集中器, 加 retry 入口
        error: (e, _) => ErrorState(
          title: AppLocalizations.of(context).commonLoadFailed(''),
          detail: e.toString(),
          onRetry: () => ref.invalidate(assessmentsProvider),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<AssessmentRecord> records,
  ) {
    // 按时间倒序
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 分组：phq9 / gad7
    final phq9 = records.where((r) => r.scaleId == 'phq9').toList();
    final gad7 = records.where((r) => r.scaleId == 'gad7').toList();

    // v0.21 Round 23 (P1-27): 下拉刷新 — emil 决策: occasional 频度
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(assessmentsProvider);
        await Future<void>.delayed(const Duration(milliseconds: 400));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
        const SizedBox(height: AppTokens.spacingMd),
        // 顶部汇总
        _SummaryStrip(records: records),
        const SizedBox(height: AppTokens.spacingMd),
        // 折线图（每个量表一张）
        if (phq9.isNotEmpty) ...[
          _ChartCard(scaleId: 'phq9', records: phq9),
          const SizedBox(height: AppTokens.spacingSm),
        ],
        if (gad7.isNotEmpty) ...[
          _ChartCard(scaleId: 'gad7', records: gad7),
          const SizedBox(height: AppTokens.spacingSm),
        ],
        // 完整列表
        _HistoryList(records: records),
        const SizedBox(height: AppTokens.spacingLg),
      ],
      ),
    );
  }
}

/// v0.21 Round 22 (P0-11 修复): 改用统一 EmptyState
class _AssessmentHistoryEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.psychology_outlined,
      title: AppLocalizations.of(context).assessmentHistoryEmpty,
      subtitle: AppLocalizations.of(context).assessmentHistoryEmptyHint,
      actionLabel: AppLocalizations.of(context).assessmentHistoryStartFirst,
      onAction: () => context.push('/assessment/phq9'),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final List<AssessmentRecord> records;
  const _SummaryStrip({required this.records});

  @override
  Widget build(BuildContext context) {
    // 最近一次：每个量表独立
    final latestPhq9 = _latest(records, 'phq9');
    final latestGad7 = _latest(records, 'gad7');
    final totalCount = records.length;
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Row(
          children: [
            Expanded(
              child: _Stat(
                label: l10n.assessmentHistoryTotalAssessments,
                value: '$totalCount',
                sub: l10n.assessmentHistoryTimes,
              ),
            ),
            Expanded(
              child: _Stat(
                label: l10n.assessmentHistoryLatestPhq9,
                value: latestPhq9 == null ? '—' : '${latestPhq9.total}',
                sub: latestPhq9 == null
                    ? l10n.assessmentHistoryNotDone
                    : _severityStyle('phq9', latestPhq9.total, l10n).label,
                severity: latestPhq9 == null
                    ? null
                    : _severityStyle('phq9', latestPhq9.total, l10n).color,
              ),
            ),
            Expanded(
              child: _Stat(
                label: l10n.assessmentHistoryLatestGad7,
                value: latestGad7 == null ? '—' : '${latestGad7.total}',
                sub: latestGad7 == null
                    ? l10n.assessmentHistoryNotDone
                    : _severityStyle('gad7', latestGad7.total, l10n).label,
                severity: latestGad7 == null
                    ? null
                    : _severityStyle('gad7', latestGad7.total, l10n).color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  AssessmentRecord? _latest(List<AssessmentRecord> records, String scaleId) {
    final filtered = records.where((r) => r.scaleId == scaleId).toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered.first;
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color? severity; // null = 灰色，otherwise 严重度配色
  const _Stat({
    required this.label,
    required this.value,
    this.sub,
    this.severity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTokens.fontSizeCaption,
            color: AppTokens.textHintColor(context),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTokens.textStyleHeadline(context),
        ),
        if (sub != null)
          Text(
            sub!,
            style: TextStyle(
              fontSize: 12,
              color: severity ?? AppTokens.textHintColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String scaleId;
  final List<AssessmentRecord> records;
  const _ChartCard({required this.scaleId, required this.records});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (records.length < 2) {
      return Card(
        child: ListTile(
          leading: Icon(_iconForScale(scaleId), color: AppTokens.primary),
          title: Text(_nameForScale(scaleId, l10n)),
          subtitle: Text(
            records.isEmpty
                ? l10n.assessmentChartNoData
                : l10n.assessmentChartNeedMore,
          ),
        ),
      );
    }
    // 排序：最早在前（折线图从左到右时间正序）
    final sorted = [...records]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final maxScore = _maxScoreForScale(scaleId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconForScale(scaleId), color: AppTokens.primary),
                const SizedBox(width: AppTokens.spacingSm),
                Text(
                  _nameForScale(scaleId, l10n),
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  AppLocalizations.of(context)
                      .assessmentChartRecordCount(sorted.length),
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHintColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingMd),
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
                        interval: _bottomInterval(sorted.length),
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
                      color: AppTokens.primary,
                      barWidth: 2.5,
                      isCurved: false,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                          radius: 4,
                          color: _severityStyle(scaleId, spot.y.toInt(), l10n)
                              .color,
                          strokeWidth: 1.5,
                          strokeColor: Colors.white,
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
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<AssessmentRecord> records;
  const _HistoryList({required this.records});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spacingMd,
              AppTokens.spacingMd,
              AppTokens.spacingMd,
              AppTokens.spacingSm,
            ),
            child: Row(
              children: [
                const Icon(Icons.history, color: AppTokens.primary, size: 20),
                const SizedBox(width: AppTokens.spacingSm),
                Text(
                  AppLocalizations.of(context).assessmentHistoryFullRecord,
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < records.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 56),
            _HistoryItem(
              record: records[i],
              // v0.14 fix: 找上一条**同量表**的记录，而不是 list 里前一条
              // 旧实现：PHQ-9 和 GAD-7 混排时，diff 会拿不同量表对比（无意义）
              previous: _findPreviousSameScale(records, i),
            ),
          ],
        ],
      ),
    );
  }

  /// 找 index i 之前，最近一条同 scaleId 的记录
  ///
  /// records 已按时间倒序排列
  AssessmentRecord? _findPreviousSameScale(
    List<AssessmentRecord> records,
    int i,
  ) {
    final scaleId = records[i].scaleId;
    for (int j = i + 1; j < records.length; j++) {
      if (records[j].scaleId == scaleId) return records[j];
    }
    return null;
  }
}

class _HistoryItem extends StatelessWidget {
  final AssessmentRecord record;
  final AssessmentRecord? previous;
  const _HistoryItem({required this.record, this.previous});

  @override
  Widget build(BuildContext context) {
    final diff = previous == null ? null : record.total - previous!.total;
    final sev = _severityStyle(
        record.scaleId, record.total, AppLocalizations.of(context),);
    final color = sev.color;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMd,
        vertical: AppTokens.spacingSm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              // v0.22 round 30 (sp-zh P2-3): 走 tintedXxxDeep 集中器
              color: color == AppTokens.primary
                  ? AppTokens.tintedPrimaryDeep(context)
                  : AppTokens.tintedErrorDeep(context),
              borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            ),
            child: Center(
              child: Text(
                '${record.total}',
                style: AppTokens.textStyleCaption(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _nameForScale(
                          record.scaleId, AppLocalizations.of(context),),
                      style: AppTokens.textStyleCaptionStrong(context),
                    ),
                    const SizedBox(width: AppTokens.spacingSm),
                    _SeverityChip(scaleId: record.scaleId, score: record.total),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(record.timestamp),
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHintColor(context),
                  ),
                ),
              ],
            ),
          ),
          if (diff != null && diff != 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacingXs,
                vertical: AppTokens.spacingXxxs,
              ),
              decoration: BoxDecoration(
                // v0.22 round 30 (sp-zh P2-3): 走 tintedXxxDeep 集中器
                color: diff < 0
                    ? AppTokens.tintedPrimaryDeep(context)
                    : AppTokens.tintedErrorDeep(context),
                borderRadius: BorderRadius.circular(AppTokens.radiusChip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    diff < 0 ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 12,
                    color: diff < 0 ? AppTokens.primary : AppTokens.error,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${diff.abs()}',
                    style: AppTokens.textStyleMicro(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: diff < 0 ? AppTokens.primary : AppTokens.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SeverityChip extends StatelessWidget {
  final String scaleId;
  final int score;
  const _SeverityChip({required this.scaleId, required this.score});

  @override
  Widget build(BuildContext context) {
    final sev = _severityStyle(scaleId, score, AppLocalizations.of(context));
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingChipGap,
        vertical: AppTokens.spacingXxxs,
      ),
      decoration: BoxDecoration(
        // v0.22 round 30 (sp-zh P2-3): 走 tintedXxxDeep 集中器
        color: sev.color == AppTokens.primary
            ? AppTokens.tintedPrimaryDeep(context)
            : AppTokens.tintedErrorDeep(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      ),
      child: Text(
        sev.label,
        style: AppTokens.textStyleMicro(context).copyWith(
          color: sev.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 严重度样式（label + color），统一一处
///
/// - 底层用 domain 的 `severityRankFor`（临床标准，不是百分比）
/// - PHQ-9 5 档：正常 / 轻度 / 中度 / 中重度 / 重度
/// - GAD-7 4 档：正常 / 轻度 / 中度 / 重度
/// - 配色（4 档色阶，绿/黄/橙/红）：
///   - rank 0 (正常) → primary
///   - rank 1 (轻度) → warning
///   - rank 2 (中度) → warningStrong
///   - rank 3+ (重度) → error
_SeverityStyle _severityStyle(
    String scaleId, int score, AppLocalizations l10n,) {
  final rank = AssessmentComparisonCalculator.severityRankFor(
    scaleId: scaleId,
    total: score,
  );
  final labels = switch (scaleId) {
    'phq9' => [
        l10n.assessmentSeverityNormal,
        l10n.assessmentSeverityMild,
        l10n.assessmentSeverityModerate,
        l10n.assessmentSeverityModeratelySevere,
        l10n.assessmentSeveritySevere,
      ],
    'gad7' => [
        l10n.assessmentSeverityNormal,
        l10n.assessmentSeverityMild,
        l10n.assessmentSeverityModerate,
        l10n.assessmentSeveritySevere,
      ],
    _ => [l10n.assessmentSeverityUnknown],
  };
  final label = rank < labels.length ? labels[rank] : labels.last;
  final color = switch (rank) {
    0 => AppTokens.primary,
    1 => AppTokens.warning,
    2 => AppTokens.warningStrong,
    _ => AppTokens.error,
  };
  return _SeverityStyle(rank: rank, label: label, color: color);
}

class _SeverityStyle {
  final int rank;
  final String label;
  final Color color;
  const _SeverityStyle({
    required this.rank,
    required this.label,
    required this.color,
  });
}

/// chart 底轴 label 间距 — 限制最多约 6 个标签，避免 90 个点挤一起
double _bottomInterval(int n) {
  if (n <= 1) return 1;
  if (n <= 6) return 1;
  return (n / 6).floorToDouble();
}

IconData _iconForScale(String scaleId) {
  return scaleId == 'phq9'
      ? Icons.psychology_outlined
      : Icons.psychology_alt_outlined;
}

String _nameForScale(String scaleId, AppLocalizations l10n) {
  return scaleId == 'phq9'
      ? l10n.assessmentScalePhq9
      : l10n.assessmentScaleGad7;
}

int _maxScoreForScale(String scaleId) {
  return scaleId == 'phq9' ? 27 : 21;
}
