// assessment_widgets.dart — 心理评估页拆分出的独立组件
//
// 从 assessment_page.dart 拆分，v0.19 (P1-15)
import 'package:flutter/material.dart';

import 'package:chroniccare/domain/logic/assessment_comparison.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

/// 评估趋势 sparkline（简易自绘，避免再引第三方）
class AssessmentSparkline extends StatelessWidget {
  final AssessmentHistory history;
  final String scaleId;
  const AssessmentSparkline({super.key, required this.history, required this.scaleId});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.show_chart,
                  color: AppTokens.primary,
                  size: 20,
                ),
                const SizedBox(width: AppTokens.spacingXs),
                const Text(
                  '历史趋势',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeLabel,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (history.average != null)
                  Text(
                    '平均 ${history.average!.toStringAsFixed(1)}',
                    style: const TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingSm),
            SizedBox(
              height: 80,
              child: CustomPaint(
                size: Size.infinite,
                painter: SparklinePainter(
                  totals: history.totals,
                  timestamps: history.timestamps,
                  maxTotal: scaleId == 'phq9' ? 27 : 21,
                  lineColor: AppTokens.primary,
                  averageLine: history.average,
                  averageColor: AppTokens.textHint,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '共 ${history.records.length} 次',
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHint,
                  ),
                ),
                if (history.min != null && history.max != null)
                  Text(
                    '最低 ${history.min} / 最高 ${history.max}',
                    style: const TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textHint,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
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

  SparklinePainter({
    required this.totals,
    required this.timestamps,
    required this.maxTotal,
    required this.lineColor,
    required this.averageLine,
    required this.averageColor,
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
    final dotStrokePaint = Paint()
      ..color = Colors.white
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
    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacingSm),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
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
    );
  }
}
