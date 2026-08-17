// assessment_widgets.dart — 心理评估页拆分出的独立组件
//
// 从 assessment_page.dart 拆分，v0.19 (P1-15 + Q3)
//
// v0.32 R112 (EM-02/AH-04, spec §5.7): 历史对比 Card → AppleListSection
// (ComparisonCard / AssessmentSparkline); QuestionCard (答题页) 保留
// Card 方言 (spec §5.7 "题目页保留")。
import 'package:flutter/material.dart';

import 'package:chroniccare/features/assessment/domain/logic/assessment_comparison.dart';
import 'package:chroniccare/features/assessment/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/app_semantics.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 评估趋势 sparkline（简易自绘，避免再引第三方）
class AssessmentSparkline extends StatelessWidget {
  final AssessmentHistory history;
  final String scaleId;
  const AssessmentSparkline({
    super.key,
    required this.history,
    required this.scaleId,
  });

  /// v0.32 round 8 (R112-06 fix): sparkline Y 轴上限走量表 totalRange
  ///
  /// 修前写死 `scaleId == 'phq9' ? 27 : 21` — WHODAS (48) / PSS (40) /
  /// ISI (28) / ASRM (20) 等总分超上限时 y 坐标为负画出界。走 domain
  /// scale_registry 单一数据源, 未知量表 / 0 防御回退 21 (跟旧行为一致)。
  static int sparklineMaxTotalFor(String scaleId) {
    final range = scaleById(scaleId)?.totalRange;
    if (range == null || range <= 0) return 21;
    return range;
  }

  @override
  Widget build(BuildContext context) {
    // v0.32 R112 (spec §5.7): Card → AppleListSection (margin zero,
    // 结果页 SingleChildScrollView 自带 padding)
    return AppleListSection(
      title: AppLocalizations.of(context).assessmentHistoryTrend,
      margin: EdgeInsets.zero,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (history.average != null)
              Padding(
                padding: const EdgeInsets.only(
                  bottom: AppTokens.spacingXxs,
                ),
                child: Text(
                  AppLocalizations.of(context).assessmentAverageScore(
                    history.average!.toStringAsFixed(1),
                  ),
                  style: AppTokens.textStyleCaption(context),
                ),
              ),
            SizedBox(
              height: AppTokens.spacingXl,
              child: CustomPaint(
                size: Size.infinite,
                painter: SparklinePainter(
                  totals: history.totals,
                  timestamps: history.timestamps,
                  // v0.32 round 8 (R112-06 fix): 走量表 totalRange
                  // (修前写死 phq9 27/其他 21 → WHODAS 48 等画出界)
                  maxTotal: sparklineMaxTotalFor(scaleId),
                  lineColor: AppTokens.primaryColor(context),
                  averageLine: history.average,
                  averageColor: AppTokens.textHintColor(context),
                  // v0.22 round 36: dot stroke 用 fgOnPrimary (dark mode 反白)
                  dotStrokeColor: AppTokens.fgOnPrimary(context),
                ),
              ),
            ),
            const SizedBox(height: AppTokens.spacingXxs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)
                      .assessmentTotalRecords(history.records.length),
                  style: AppTokens.textStyleCaptionHint(context),
                ),
                if (history.min != null && history.max != null)
                  Text(
                    AppLocalizations.of(context)
                        .assessmentScoreRange(history.min!, history.max!),
                    style: AppTokens.textStyleCaptionHint(context),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<int> totals;
  final List<DateTime> timestamps;
  final int maxTotal;
  final Color lineColor;
  final double? averageLine;
  final Color averageColor;
  // v0.22 round 36: dot stroke 色从 build() 传进来 (paint() 方法无 context)
  final Color dotStrokeColor;

  SparklinePainter({
    required this.totals,
    required this.timestamps,
    required this.maxTotal,
    required this.lineColor,
    required this.averageLine,
    required this.averageColor,
    required this.dotStrokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totals.isEmpty) return;
    final n = totals.length;

    if (averageLine != null) {
      final avgY = size.height - (averageLine! / maxTotal) * size.height;
      final avgPaint = Paint()
        ..color = averageColor
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      const dashWidth = 4.0;
      const dashSpace = 3.0;
      double startX = 0;
      while (startX < size.width) {
        canvas.drawLine(
          Offset(startX, avgY),
          Offset(startX + dashWidth, avgY),
          avgPaint,
        );
        startX += dashWidth + dashSpace;
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()..color = lineColor;
    // v0.22 round 36: dot stroke 用 app_tokens surface 色, dark mode 兼容
    // (之前 Colors.white 在 dark mode 下不反白)
    final dotStrokePaint = Paint()
      ..color = dotStrokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = n == 1 ? size.width / 2 : (i / (n - 1)) * size.width;
      final y = size.height - (totals[i] / maxTotal) * size.height;
      points.add(Offset(x, y));
    }

    if (n >= 2) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    for (final p in points) {
      canvas.drawCircle(p, 3.5, dotPaint);
      canvas.drawCircle(p, 3.5, dotStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SparklinePainter old) {
    return old.totals != totals ||
        old.maxTotal != maxTotal ||
        old.averageLine != averageLine;
  }
}

/// 单题卡片
class QuestionCard extends StatelessWidget {
  final int index;
  final AssessmentItem item;
  final Map<int, String> options;
  final int? selected;
  final ValueChanged<int> onChanged;

  const QuestionCard({
    super.key,
    required this.index,
    required this.item,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // v0.22 round 28 (emil-bug-05): Semantics container 让读屏用户知道
    // 4 个 ChoiceChip 是同题选项,题号+题文+当前选择 1 次性念出
    // v0.22 round 30 (sp-zh P2-5): '未选' 走 l10n, en 模式可用
    // v0.24 round 43 (emil D-07 P2): 评估题 Semantics 标签走 l10n
    // (en 模式 TalkBack 读 "Question 1: ...", 不再硬编码中文)
    final l10n = AppLocalizations.of(context);
    final selectedLabel =
        selected != null ? options[selected!]! : l10n.commonOptionNotSelected;
    return AppSemantics.container(
      label: l10n.assessmentQuestionLabel(index, item.text, selectedLabel),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppTokens.spacingSm),
        child: Padding(
          padding: AppTokens.edgeInsetsMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Q$index. ${item.text}',
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Wrap(
                spacing: AppTokens.spacingXs,
                runSpacing: AppTokens.spacingXs,
                children: [
                  for (final entry in options.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: selected == entry.key,
                      onSelected: (_) => onChanged(entry.key),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// v0.13 (Round 8) 评估历史对比 widget
// =============================================================

/// "对比上次" 卡片
///
/// - 首次评估：显示提示
/// - 有上次：显示 Δ 分数 + 严重度变化方向 + 距上次天数
class ComparisonCard extends StatelessWidget {
  final AssessmentComparison comparison;
  const ComparisonCard({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    final cmp = comparison;
    final isFirst = cmp.trend == ComparisonTrend.firstAssessment;

    Color trendColor;
    IconData trendIcon;
    switch (cmp.trend) {
      case ComparisonTrend.improved:
        trendColor = AppTokens.primaryColor(context);
        trendIcon = Icons.arrow_downward;
      case ComparisonTrend.worsened:
        trendColor = AppTokens.errorColor(context);
        trendIcon = Icons.arrow_upward;
      case ComparisonTrend.unchanged:
        trendColor = AppTokens.textSecondaryColor(context);
        trendIcon = Icons.horizontal_rule;
      case ComparisonTrend.firstAssessment:
        trendColor = AppTokens.primaryColor(context);
        trendIcon = Icons.fiber_new;
    }

    // v0.32 R112 (spec §5.7): Card → AppleListSection (header Row 的
    // icon + title 改 section title, content 平铺)
    return AppleListSection(
      title: AppLocalizations.of(context).assessmentComparePrevious,
      margin: EdgeInsets.zero,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFirst)
              Row(
                children: [
                  Icon(trendIcon, color: trendColor, size: 28),
                  const SizedBox(width: AppTokens.spacingXs),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)
                          .assessmentFirstAssessmentHint,
                      style: TextStyle(
                        fontSize: AppTokens.fontSizeBody,
                        color: AppTokens.textSecondaryColor(context),
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).assessmentPrevious,
                          style: AppTokens.textStyleCaption(context),
                        ),
                        const SizedBox(height: AppTokens.spacingXxxs),
                        Text(
                          '${cmp.previous!.total}',
                          style: TextStyle(
                            fontSize: AppTokens.fontSizeScoreXl,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.textSecondaryColor(context),
                          ),
                        ),
                        Text(
                          _dateLabel(cmp.previous!.timestamp),
                          style: AppTokens.textStyleCaptionHint(context),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    // 趋势指示箭头 (中间色, 暗示'从 X 到 Y'过渡)
                    // trendColor 由 assessment score 动态算出, AppColors.tintChartLine alpha 0.6 表达"非极端值"
                    // v0.27 round 65 (alibaba B8 magic alpha): 抽 token 消除 0.6 硬编码
                    color: AppColors.tintChartLine(context, trendColor),
                  ),
                  const SizedBox(width: AppTokens.spacingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).assessmentCurrent,
                          style: AppTokens.textStyleCaption(context),
                        ),
                        const SizedBox(height: AppTokens.spacingXxxs),
                        Text(
                          '${cmp.current.total}',
                          style: TextStyle(
                            fontSize: AppTokens.fontSizeScoreXl,
                            fontWeight: FontWeight.w600,
                            color: trendColor,
                          ),
                        ),
                        Text(
                          _dateLabel(cmp.current.timestamp),
                          style: AppTokens.textStyleCaptionHint(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Row(
                children: [
                  Icon(
                    trendIcon,
                    color: trendColor,
                    size: AppTokens.iconSizeInline,
                  ),
                  const SizedBox(width: AppTokens.spacingXxs),
                  Text(
                    '${cmp.trendSymbol} ${cmp.trendLabel(
                      improvedOverride: AppLocalizations.of(context)
                          .assessmentComparisonImproved,
                      worsenedOverride: AppLocalizations.of(context)
                          .assessmentComparisonWorsened,
                      unchangedOverride: AppLocalizations.of(context)
                          .assessmentComparisonUnchanged,
                      firstAssessmentOverride: AppLocalizations.of(context)
                          .assessmentComparisonFirst,
                    )} · ${cmp.deltaLabel(
                      sameOverride: AppLocalizations.of(context)
                          .assessmentDeltaSame(cmp.scoreDelta ?? 0),
                      higherOverride: AppLocalizations.of(context)
                          .assessmentDeltaHigher(cmp.scoreDelta ?? 0),
                      lowerOverride: AppLocalizations.of(context)
                          .assessmentDeltaLower(-(cmp.scoreDelta ?? 0)),
                    )}',
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeBody,
                      fontWeight: FontWeight.w500,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
              if (cmp.daysSincePrevious != null) ...[
                const SizedBox(height: AppTokens.spacingXxs),
                Text(
                  AppLocalizations.of(context)
                      .assessmentDaysSincePrevious(cmp.daysSincePrevious!),
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHintColor(context),
                  ),
                ),
              ],
            ],
          ],
        ),
      ],
    );
  }

  static String _dateLabel(DateTime t) {
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }
}
