// 心理评估页（v0.8 重构：支持多量表，v0.13 加历史对比 + sparkline）
//
// 路由：/assessment/:id （id = 'phq9' / 'gad7'）
// 用户填题 → 提交 → 显示结果 + 写入 DB
// 总分 ≥ 推荐线 提示就医；自杀念头（PHQ-9 第 9 题）阳性立即弹危机资源
// v0.13 (Round 8) 加：结果页显示"对比上次"面板 + sparkline 趋势

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/logic/assessment_comparison.dart';
import '../../../domain/logic/assessment_record.dart';
import '../../../domain/logic/assessment_scale.dart';
import '../../../domain/logic/scale_registry.dart';
import '../../../theme/app_tokens.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/page_scaffold.dart';

class AssessmentPage extends ConsumerStatefulWidget {
  final String scaleId; // 'phq9' / 'gad7'

  const AssessmentPage({super.key, required this.scaleId});

  @override
  ConsumerState<AssessmentPage> createState() => _AssessmentPageState();
}

class _AssessmentPageState extends ConsumerState<AssessmentPage> {
  AssessmentScale? _scale;
  List<int?>? _answers;
  bool _submitted = false;
  AssessmentResult? _result;

  @override
  void initState() {
    super.initState();
    final scale = scaleById(widget.scaleId);
    if (scale == null) {
      // 路由给错 id,下帧退回上一页 + 显示错误态
      _scale = null;
      _answers = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
    } else {
      _scale = scale;
      _answers = List.filled(_scale!.items.length, null);
    }
  }

  int get _answered => _answers?.where((a) => a != null).length ?? 0;
  bool get _canSubmit => _scale != null && _answered == _scale!.items.length;

  @override
  Widget build(BuildContext context) {
    // P5 fix: 路由给错 id 时显示 loading(下一帧 pop),而不是渲染 PHQ-9 替代
    if (_scale == null) {
      return const PageScaffold(
        title: '心理评估',
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在返回上一页...'),
            ],
          ),
        ),
      );
    }
    return PageScaffold(
      title: _scale!.displayName,
      child: _submitted && _result != null
          ? _buildResultView(_result!)
          : _buildQuizView(),
    );
  }

  Widget _buildQuizView() {
    final scale = _scale!;
    final answers = _answers!;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTokens.spacingMd),
          color: AppTokens.primaryLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scale.instruction,
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppTokens.spacingXs),
              Text(
                '已答 $_answered / ${scale.items.length}',
                style: const TextStyle(
                  color: AppTokens.textSecondary,
                  fontSize: AppTokens.fontSizeCaption,
                ),
              ),
              const SizedBox(height: AppTokens.spacingXs),
              LinearProgressIndicator(
                value: _answered / scale.items.length,
                backgroundColor: AppTokens.divider,
                color: AppTokens.primary,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppTokens.spacingMd),
            itemCount: scale.items.length,
            itemBuilder: (ctx, i) => _QuestionCard(
              index: i + 1,
              item: scale.items[i],
              options: scale.options,
              selected: answers[i],
              onChanged: (v) => setState(() => answers[i] = v),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spacingMd),
            child: SizedBox(
              width: double.infinity,
              height: AppTokens.buttonHeight,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                child: const Text('提交并查看结果'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final scale = _scale!;
    final scores = _answers!.cast<int>();
    final result = scale.computeResult(scores);

    try {
      await ref.read(checkInRepositoryProvider).saveAssessment(
            scale: scale.id,
            scores: scores,
            total: result.total,
          );
    } catch (_) {
      // 静默失败——结果仍展示
    }

    // v0.13 (Round 7): 评估完成 → 重排下次评估提醒
    // 失败也不影响主流程（用户看到的"结果"和"危机弹窗"优先）
    try {
      await ref.read(assessmentReminderServiceProvider).onAssessmentCompleted();
    } catch (_) {}

    // 危机检测（PHQ-9 第 9 题阳性等）
    final crisis = scale.detectCrisis(scores, result);
    if (crisis != null) {
      if (!mounted) return;
      await _showCrisisDialog(crisis);
    }

    if (!mounted) return;
    setState(() {
      _submitted = true;
      _result = result;
    });
  }

  Future<void> _showCrisisDialog(CrisisSignal crisis) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber, color: AppTokens.error),
            const SizedBox(width: 8),
            Expanded(child: Text(crisis.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(crisis.message),
            const SizedBox(height: 16),
            for (final h in crisis.hotlines) ...[
              Text(
                '📞 ${h.label}\n   ${h.number}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('我知道了'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(AssessmentResult result) {
    final scale = _scale!;
    final isUrgent = result.urgentDoctorVisit;
    final recommend = result.recommendDoctorVisit;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTokens.spacingLg),
            decoration: BoxDecoration(
              color: isUrgent
                  ? AppTokens.error.withValues(alpha: 0.1)
                  : AppTokens.primaryLight,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            ),
            child: Column(
              children: [
                Text(
                  '${result.total}',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: isUrgent ? AppTokens.error : AppTokens.primary,
                  ),
                ),
                Text(
                  '总分（0-${scale.totalRange}）',
                  style: const TextStyle(color: AppTokens.textSecondary),
                ),
                const SizedBox(height: AppTokens.spacingSm),
                Text(
                  result.summary,
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeHeadline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // v0.13 (Round 8): 历史对比 + sparkline
          ..._buildComparisonWidgets(scale.id),
          const SizedBox(height: AppTokens.spacingMd),
          if (recommend)
            Card(
              color: AppTokens.warning.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.spacingMd),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.medical_services_outlined,
                      color: AppTokens.warning,
                    ),
                    const SizedBox(width: AppTokens.spacingSm),
                    Expanded(
                      child: Text(
                        isUrgent ? '强烈建议你尽快联系医生或心理治疗师。' : '建议你联系医生做进一步评估。',
                        style: const TextStyle(
                          color: AppTokens.textPrimary,
                          fontSize: AppTokens.fontSizeBody,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppTokens.spacingMd),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppTokens.spacingMd),
              child: Text(
                '⚠️ 本评估仅供参考，不能代替专业诊断。\n'
                '如感到困扰，请咨询医生。',
                style: TextStyle(color: AppTokens.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingLg),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('返回'),
                ),
              ),
              const SizedBox(width: AppTokens.spacingSm),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final answers = _answers!;
                    setState(() {
                      _submitted = false;
                      _result = null;
                      for (int i = 0; i < answers.length; i++) {
                        answers[i] = null;
                      }
                    });
                  },
                  child: const Text('再做一次'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// v0.13 (Round 8) 历史对比 widget 列表
  ///
  /// - 有 1 条记录：显示"首次评估"提示
  /// - 有 ≥2 条记录：显示"对比上次"卡 + sparkline
  List<Widget> _buildComparisonWidgets(String scaleId) {
    final async = ref.watch(assessmentsProvider);
    final records = async.maybeWhen(
      data: (all) {
        return all
            .map(AssessmentRecord.tryFromEntity)
            .whereType<AssessmentRecord>()
            .where((r) => r.scaleId == scaleId)
            .toList();
      },
      orElse: () => <AssessmentRecord>[],
    );
    if (records.isEmpty) {
      return const [];
    }
    final comparison = AssessmentComparisonCalculator.fromRecords(
      records: records,
      scaleId: scaleId,
    );
    final history = AssessmentComparisonCalculator.historyFromRecords(records);

    return [
      const SizedBox(height: AppTokens.spacingMd),
      // 对比上次
      _ComparisonCard(comparison: comparison),
      const SizedBox(height: AppTokens.spacingSm),
      // sparkline
      if (history.records.length >= 2)
        _AssessmentSparkline(
          history: history,
          scaleId: scaleId,
        ),
    ];
  }
}

// =============================================================
// v0.13 (Round 8) 评估历史对比 widget
// =============================================================

/// "对比上次" 卡片
///
/// - 首次评估：显示提示
/// - 有上次：显示 Δ 分数 + 严重度变化方向 + 距上次天数
class _ComparisonCard extends StatelessWidget {
  final AssessmentComparison comparison;
  const _ComparisonCard({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final cmp = comparison;
    final isFirst = cmp.trend == ComparisonTrend.firstAssessment;

    Color trendColor;
    IconData trendIcon;
    switch (cmp.trend) {
      case ComparisonTrend.improved:
        trendColor = AppTokens.primary;
        trendIcon = Icons.arrow_downward;
        break;
      case ComparisonTrend.worsened:
        trendColor = AppTokens.error;
        trendIcon = Icons.arrow_upward;
        break;
      case ComparisonTrend.unchanged:
        trendColor = AppTokens.textSecondary;
        trendIcon = Icons.horizontal_rule;
        break;
      case ComparisonTrend.firstAssessment:
        trendColor = AppTokens.primary;
        trendIcon = Icons.fiber_new;
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.compare_arrows,
                    color: AppTokens.primary, size: 20,),
                SizedBox(width: AppTokens.spacingXs),
                Text(
                  '对比上次',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeLabel,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingSm),
            if (isFirst)
              Row(
                children: [
                  Icon(trendIcon, color: trendColor, size: 28),
                  const SizedBox(width: AppTokens.spacingXs),
                  const Expanded(
                    child: Text(
                      '这是你的第一次评估。下次评估后会显示和这次的对比。',
                      style: TextStyle(
                        fontSize: AppTokens.fontSizeBody,
                        color: AppTokens.textSecondary,
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
                        const Text(
                          '上次',
                          style: TextStyle(
                            fontSize: AppTokens.fontSizeCaption,
                            color: AppTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${cmp.previous!.total}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.textSecondary,
                          ),
                        ),
                        Text(
                          _dateLabel(cmp.previous!.timestamp),
                          style: const TextStyle(
                            fontSize: AppTokens.fontSizeCaption,
                            color: AppTokens.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward,
                      color: trendColor.withValues(alpha: 0.6),),
                  const SizedBox(width: AppTokens.spacingSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '本次',
                          style: TextStyle(
                            fontSize: AppTokens.fontSizeCaption,
                            color: AppTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${cmp.current.total}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: trendColor,
                          ),
                        ),
                        Text(
                          _dateLabel(cmp.current.timestamp),
                          style: const TextStyle(
                            fontSize: AppTokens.fontSizeCaption,
                            color: AppTokens.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Row(
                children: [
                  Icon(trendIcon, color: trendColor, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${cmp.trendSymbol} ${cmp.trendLabel} · ${cmp.deltaLabel}',
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeBody,
                      fontWeight: FontWeight.w500,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
              if (cmp.daysSincePrevious != null) ...[
                const SizedBox(height: 4),
                Text(
                  '距上次 ${cmp.daysSincePrevious} 天',
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHint,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static String _dateLabel(DateTime t) {
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }
}

/// 评估趋势 sparkline（简易自绘，避免再引第三方）
class _AssessmentSparkline extends StatelessWidget {
  final AssessmentHistory history;
  final String scaleId;
  const _AssessmentSparkline({required this.history, required this.scaleId});

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
                const Icon(Icons.show_chart,
                    color: AppTokens.primary, size: 20,),
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
                painter: _SparklinePainter(
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

class _SparklinePainter extends CustomPainter {
  final List<int> totals;
  final List<DateTime> timestamps;
  final int maxTotal;
  final Color lineColor;
  final double? averageLine;
  final Color averageColor;

  _SparklinePainter({
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

    // 平均线（虚线）
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

    // 主线 + 圆点
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
  bool shouldRepaint(covariant _SparklinePainter old) {
    return old.totals != totals ||
        old.maxTotal != maxTotal ||
        old.averageLine != averageLine;
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final AssessmentItem item;
  final Map<int, String> options;
  final int? selected;
  final ValueChanged<int> onChanged;

  const _QuestionCard({
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

// P5 fix: 之前 `phq9ScaleFallback` 是死代码,直接调 `scaleById('phq9')!`,
// 如果 phq9 不存在就 throw,实际意义是 0。现在 initState 改成 _scale = null
// + 下一帧 pop,这个 fallback 不再需要。删了。
// 如果未来真的需要"路由给错时返回某个默认量表",应该传具体 id: scaleById('phq9')!,
// 不要在 null safety 之上再加一层 wrapper。
