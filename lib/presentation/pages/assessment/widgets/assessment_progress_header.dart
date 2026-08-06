// v0.30 R92 (audit-fixes task 6): AssessmentProgressHeader
// 拆 assessment_page.dart god page (436 行) 第 1 步
// - 顶部进度 widget: instruction + 已答 N 题 + LinearProgressIndicator
// - 接受 props: instruction, answered, total
// - 之前在 _buildQuizView L101-131 内联, 复用 emil PressFeedback 风格

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 答题顶部进度 widget
///
/// 显示量表指令 + 已答 N 题 + 进度条。
/// 精神心理患者对长时动效敏感, 进度条用 M3 LinearProgressIndicator (无自定义动画)。
class AssessmentProgressHeader extends StatelessWidget {
  const AssessmentProgressHeader({
    super.key,
    required this.instruction,
    required this.answered,
    required this.total,
  });

  final String instruction;
  final int answered;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppTokens.edgeInsetsMd,
      color: AppTokens.primaryLightColor(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            instruction,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeBody,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppTokens.spacingXs),
          // 走 l10n key (R91 已有 assessmentAnsweredProgress, R92 拆 god page 时
          // 误改成字面量 '$answered / $total', R92 task 6 fix 复用 l10n)
          Text(
            AppLocalizations.of(context)
                .assessmentAnsweredProgress(answered, total),
            style: TextStyle(
              color: AppTokens.textSecondaryColor(context),
              fontSize: AppTokens.fontSizeCaption,
            ),
          ),
          const SizedBox(height: AppTokens.spacingXs),
          LinearProgressIndicator(
            value: total == 0 ? 0.0 : answered / total,
            backgroundColor: AppTokens.dividerColor(context),
            color: AppTokens.primaryColor(context),
          ),
        ],
      ),
    );
  }
}
