// 心理评估页（v0.8 重构：支持多量表，v0.13 加历史对比 + sparkline）
//
// 路由：/assessment/:id （id = 'phq9' / 'gad7'）
// 用户填题 → 提交 → 显示结果 + 写入 DB
// 总分 ≥ 推荐线 提示就医；自杀念头（PHQ-9 第 9 题）阳性立即弹危机资源
// v0.13 (Round 8) 加：结果页显示"对比上次"面板 + sparkline 趋势

import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/logic/assessment_comparison.dart';
import 'package:chroniccare/domain/logic/assessment_record.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_widgets.dart';

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
            itemBuilder: (ctx, i) => QuestionCard(
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
    } catch (e, st) {
      swallowError(
        where: 'assessment_page._onSubmit.saveAssessment',
        error: e,
        stack: st,
        note: 'assessment save failed — result still shown to user',
      );
    }

    // v0.13 (Round 7): 评估完成 → 重排下次评估提醒
    // 失败也不影响主流程（用户看到的"结果"和"危机弹窗"优先）
    try {
      await ref.read(assessmentReminderServiceProvider).onAssessmentCompleted();
    } catch (e, st) {
      swallowError(
        where: 'assessment_page._onSubmit',
        error: e,
        stack: st,
        note: 'reschedule assessment reminder failed, main flow unaffected',
      );
    }

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
            child: Text(AppLocalizations.of(context).commonGotIt),
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
      ComparisonCard(comparison: comparison),
      const SizedBox(height: AppTokens.spacingSm),
      // sparkline
      if (history.records.length >= 2)
        AssessmentSparkline(
          history: history,
          scaleId: scaleId,
        ),
    ];
  }
}

