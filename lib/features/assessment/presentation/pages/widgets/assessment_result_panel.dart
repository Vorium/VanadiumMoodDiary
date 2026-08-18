// v0.30 R92 (audit-fixes task 6): AssessmentResultPanel
// 拆 assessment_page.dart god page (436 行) 第 3 步
// - 结果 widget: 大数字 + ComparisonCard + Sparkline + 推荐就医 + 免责声明 + 2 button
// - 接受 props: result, scale, recommendCard / sparkline, onBack, onRetake
// - 之前在 _buildResultView L296-416 内联, 120 行
// - 跟 ProgressHeader 配套使用

import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/features/assessment/domain/logic/assessment_scale.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

/// 答题结果 widget
///
/// 显示大数字 + 严重度 + ComparisonCard + sparkline + 推荐就医 + 免责声明 + 2 button。
/// 历史对比 widget 列表由父 widget 传 [historyWidgets] 进来 (ComparisonCard + Sparkline 列表)。
class AssessmentResultPanel extends StatelessWidget {
  const AssessmentResultPanel({
    super.key,
    required this.result,
    required this.scale,
    required this.historyWidgets,
    required this.onBack,
    required this.onRetake,
  });

  /// 评估结果 (含 total / summary / urgentDoctorVisit / recommendDoctorVisit)
  final AssessmentResult result;

  /// 量表定义 (含 totalRange 显示)
  final AssessmentScale scale;

  /// 历史对比 widget 列表 (ComparisonCard + 可选 Sparkline, 由父 widget 构造)
  final List<Widget> historyWidgets;

  /// 返回按钮 onPressed
  final VoidCallback onBack;

  /// 重测按钮 onPressed
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // R128e 医疗声称降级: 删 isUrgent/recommend 医疗警示逻辑
    // (urgentDoctorVisit 红色 + recommendDoctorVisit 就医建议 = 诊断行为)

    return SingleChildScrollView(
      padding: AppTokens.edgeInsetsMd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 大数字 + 总分范围 (删严重度解读文案)
          Container(
            padding: AppTokens.edgeInsetsLg,
            decoration: BoxDecoration(
              color: AppTokens.primaryLightColor(context),
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            ),
            child: Column(
              children: [
                Text(
                  '${result.total}',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeScoreXxl,
                    fontWeight: FontWeight.bold,
                    color: AppTokens.primaryColor(context),
                  ),
                ),
                Text(
                  l10n.assessmentScoreTotal(scale.totalRange),
                  style: AppTokens.textStyleBody(context)
                      .copyWith(color: AppTokens.textSecondaryColor(context)),
                ),
              ],
            ),
          ),
          // v0.13 (Round 8): 历史对比 + sparkline (父 widget 传入)
          ...historyWidgets,
          const SizedBox(height: AppTokens.spacingMd),
          // 免责声明 (R128e 强化: 仅供参考, 不构成诊断)
          Card(
            child: Padding(
              padding: AppTokens.edgeInsetsMd,
              child: Text(
                l10n.assessmentDisclaimer,
                style: AppTokens.textStyleBody(context)
                    .copyWith(color: AppTokens.textSecondaryColor(context)),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingLg),
          // 2 button
          Row(
            children: [
              Expanded(
                // v0.31 round 12 (Apple Health redesign · Phase 4 Task 4.1):
                // OutlinedButton → PrimaryButton(secondary) Apple Pill 风。
                // 跟同 Row PrimaryButton(主) 走同一集中器, 自动获得
                // PressFeedback scale 反馈 + FilledButton.tonal 视觉。
                child: PrimaryButton(
                  variant: PrimaryButtonVariant.secondary,
                  isFullWidth: true,
                  onPressed: onBack,
                  child: Text(l10n.assessmentBack),
                ),
              ),
              const SizedBox(width: AppTokens.spacingSm),
              Expanded(
                child: PrimaryButton(
                  isFullWidth: false,
                  onPressed: onRetake,
                  child: Text(l10n.assessmentRetake),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
