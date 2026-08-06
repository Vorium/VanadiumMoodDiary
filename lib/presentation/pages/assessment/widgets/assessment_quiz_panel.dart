// v0.30 R92 (audit-fixes task 6): AssessmentQuizPanel
// 拆 assessment_page.dart god page (436 行) 第 2 步
// - 答题 widget: 顶部 ProgressHeader + 题列表 + 提交按钮
// - 接受 props: scale, answers, answered, onAnswerChanged, onSubmit, canSubmit
// - 之前在 _buildQuizView L96-161 内联, 65 行
// - 跟 ProgressHeader 配套使用

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_widgets.dart';
import 'package:chroniccare/presentation/pages/assessment/widgets/assessment_progress_header.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

/// 答题 widget
///
/// 显示进度头部 + 题列表 + 提交按钮。
/// 状态由父 widget 管理 (assessment_page.dart _AssessmentPageState),
/// 接受 answers map + onAnswerChanged callback 走 props 模式 (避免 sub-widget 读全局 state)。
class AssessmentQuizPanel extends StatelessWidget {
  const AssessmentQuizPanel({
    super.key,
    required this.scale,
    required this.answers,
    required this.answered,
    required this.onAnswerChanged,
    required this.onSubmit,
    required this.canSubmit,
  });

  /// 量表定义
  final AssessmentScale scale;

  /// 用户答案 map: question index (0-based) → selected option (0-based, nullable)
  final List<int?> answers;

  /// 已答题数 (用于进度显示)
  final int answered;

  /// 用户选择某题答案的回调
  final void Function(int questionIndex, int? optionIndex) onAnswerChanged;

  /// 提交按钮 onPressed
  final VoidCallback onSubmit;

  /// 提交按钮是否可点击 (全部题已答)
  final bool canSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        AssessmentProgressHeader(
          instruction: scale.instruction,
          answered: answered,
          total: scale.items.length,
        ),
        Expanded(
          child: ListView.builder(
            padding: AppTokens.edgeInsetsMd,
            itemCount: scale.items.length,
            itemBuilder: (ctx, i) => QuestionCard(
              index: i + 1,
              item: scale.items[i],
              options: scale.options,
              selected: answers[i],
              onChanged: (v) => onAnswerChanged(i, v),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: AppTokens.edgeInsetsMd,
            child: SizedBox(
              width: double.infinity,
              height: AppTokens.buttonHeight,
              child: PrimaryButton(
                onPressed: canSubmit ? onSubmit : null,
                child: Text(l10n.assessmentSubmit),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
