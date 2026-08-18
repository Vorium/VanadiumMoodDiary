// 心理评估页（v0.8 重构：支持多量表，v0.13 加历史对比 + sparkline）
//
// 路由：/assessment/:id （id = 'phq9' / 'gad7'）
// 用户填题 → 提交 → 显示结果 + 写入 DB
// 总分 ≥ 推荐线 提示就医；自杀念头（PHQ-9 第 9 题）阳性立即弹危机资源
// v0.13 (Round 8) 加：结果页显示"对比上次"面板 + sparkline 趋势

import 'package:chroniccare/presentation/providers/assessment_providers.dart';
import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:chroniccare/presentation/widgets/animations/page_transition_switcher.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/features/assessment/domain/logic/assessment_comparison.dart';
import 'package:chroniccare/features/assessment/domain/logic/assessment_record.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/services/scale_name_l10n.dart';
import 'package:chroniccare/features/assessment/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/pages/assessment/widgets/assessment_quiz_panel.dart';
import 'package:chroniccare/presentation/pages/assessment/widgets/assessment_result_panel.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_widgets.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

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
      return PageScaffold(
        title: AppLocalizations.of(context).settingsAssessment,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LoadingSpinner(),
              const SizedBox(height: AppTokens.spacingSm),
              Text(AppLocalizations.of(context).assessmentLoadingBack),
            ],
          ),
        ),
      );
    }
    return PageScaffold(
      // v0.32 round 8 (R111 R111-02 fix): 走 scaleNameL10n (en 用户不再看
      // 中文量表名, const 单例 displayName 只是 zh fallback)
      title: scaleNameL10n(_scale!.id, AppLocalizations.of(context)),
      // v0.24 round 43 (emil P1-01 H-04 / D-03):
      // 用 PageTransitionSwitcher 让 quiz→result 平滑切换(100ms fade)
      // 精神心理患者对长时动效敏感,只用 fade 不用 slide
      child: PageTransitionSwitcher(
        switchKey: (_submitted && _result != null) ? 'result' : 'quiz',
        child: (_submitted && _result != null)
            ? _buildResultView()
            : _buildQuizView(),
      ),
    );
  }

  Widget _buildQuizView() {
    // v0.30 R92: 拆 god page, QuizPanel 走 props callback 模式
    // 父 widget 持 state, sub-widget 不读全局
    final scale = _scale!;
    final answers = _answers!;
    return AssessmentQuizPanel(
      scale: scale,
      answers: answers,
      answered: _answered,
      canSubmit: _canSubmit,
      onAnswerChanged: (questionIndex, optionIndex) {
        setState(() => answers[questionIndex] = optionIndex);
      },
      onSubmit: _submit,
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final scale = _scale!;
    final scores = _answers!.cast<int>();
    final result = scale.computeResult(scores);
    // v0.30 round 91 (fix): 用 scaleById → severityRankFor 算严重度 rank,
    // 跟 R90 reader (assessment_dao._rowToEntry severity 字段) 对齐,
    // 写入 R90 JSON 格式。
    final severityRank = AssessmentComparisonCalculator.severityRankFor(
      scaleId: scale.id,
      total: result.total,
    );

    bool saveFailed = false;
    try {
      // v0.30 round 91 (fix): 走 R90 AssessmentRepository.submitEntry
      // (老 checkInRepositoryProvider.saveAssessment 是 R60 路径, 写
      // `{"scale","scores","total"}` 格式, R90 reader 解不出 score/answers)
      await ref.read(assessmentRepositoryProvider).submitEntry(
            scaleId: scale.id,
            score: result.total,
            severityRank: severityRank,
            answers: scores,
          );
    } catch (e, st) {
      saveFailed = true;
      swallowError(
        where: 'assessment_page._onSubmit.submitEntry',
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
    // v0.25 round 51: region 默认 cn — 后续 R51b 让用户从设置选 region
    // 或者从 emergency contact phone region 推断
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

    if (saveFailed && mounted) {
      AppSnackBar.showInfo(
        context,
        AppLocalizations.of(context).assessmentSaveFailed,
      );
    }
  }

  Future<void> _showCrisisDialog(CrisisSignal crisis) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppTokens.errorColor(context)),
            const SizedBox(width: AppTokens.spacingXs),
            Expanded(child: Text(crisis.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(crisis.message),
            const SizedBox(height: AppTokens.spacingSm),
            for (final h in crisis.hotlines) ...[
              // v0.22 round 29 (emil-21): 拆 '📞 ${h.label}\n   ${h.number}' emoji hack
              // → Row(Icon(phone), Text(h.label)) + 单独 Text(h.number)
              // (a11y 屏幕阅读器能识别 Icon 跟 Text 是不同元素, 不用解释空格 hack)
              Row(
                children: [
                  const Icon(Icons.phone, size: AppTokens.iconSizeInline),
                  const SizedBox(width: AppTokens.spacingXs),
                  Expanded(
                    child: Text(
                      h.label,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              Padding(
                // v0.24 round 48 (emil P2-13): 修正 3 个裸数字 → spacing token
                // left: 26 ≈ 评估题 1-9 编号对齐 (跟缩进编号文字视觉对齐)
                // top: 2 + bottom: 8 ≈ 跟 options 列表行高对齐
                // 26 不在 token sequence, 加注释说明 design decision (1 处用, 不抽 token)
                padding: const EdgeInsets.only(
                  left: 26, // 编号缩进对齐 (deliberate, 不抽 token)
                  top: AppTokens.spacingXxxs, // 2
                  bottom: AppTokens.spacingXs, // 8
                ),
                child: Text(
                  h.number,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
        actions: [
          PrimaryButton(
            isFullWidth: false,
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context).commonGotIt),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView() {
    // v0.30 R92: 拆 god page, ResultPanel 走 props callback 模式
    // 历史对比 widgets 由父 widget 构造, 通过 historyWidgets 传入
    final scale = _scale!;
    final result = _result!;
    return AssessmentResultPanel(
      result: result,
      scale: scale,
      historyWidgets: _buildComparisonWidgets(scale.id),
      onBack: () => Navigator.of(context).pop(),
      onRetake: () {
        final answers = _answers!;
        setState(() {
          _submitted = false;
          _result = null;
          for (int i = 0; i < answers.length; i++) {
            answers[i] = null;
          }
        });
      },
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
