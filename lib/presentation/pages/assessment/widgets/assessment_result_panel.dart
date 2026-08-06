// v0.30 R92 (audit-fixes task 6): AssessmentResultPanel
// 拆 assessment_page.dart god page (436 行) 第 3 步
// - 结果 widget: 大数字 + ComparisonCard + Sparkline + 推荐就医 + 免责声明 + 2 button
// - 接受 props: result, scale, recommendCard / sparkline, onBack, onRetake
// - 之前在 _buildResultView L296-416 内联, 120 行
// - 跟 ProgressHeader 配套使用

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/assessment_record.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_widgets.dart';
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
    final isUrgent = result.urgentDoctorVisit;
    final recommend = result.recommendDoctorVisit;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 大数字 + 严重度 + 总分范围
          Container(
            padding: const EdgeInsets.all(AppTokens.spacingLg),
            decoration: BoxDecoration(
              color: isUrgent
                  ? AppTokens.tintedErrorSoft(context)
                  : AppTokens.primaryLightColor(context),
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            ),
            child: Column(
              children: [
                Text(
                  '${result.total}',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeScoreXxl,
                    fontWeight: FontWeight.bold,
                    color: isUrgent
                        ? AppTokens.errorColor(context)
                        : AppTokens.primaryColor(context),
                  ),
                ),
                Text(
                  l10n.assessmentScoreTotal(scale.totalRange),
                  style: AppTokens.textStyleBody(context)
                      .copyWith(color: AppTokens.textSecondaryColor(context)),
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
          // v0.13 (Round 8): 历史对比 + sparkline (父 widget 传入)
          ...historyWidgets,
          const SizedBox(height: AppTokens.spacingMd),
          // 推荐就医
          if (recommend)
            Card(
              color: AppTokens.tintedWarningSoft(context),
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.spacingMd),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.medical_services_outlined,
                      color: AppTokens.warningColor(context),
                    ),
                    const SizedBox(width: AppTokens.spacingSm),
                    Expanded(
                      child: Text(
                        isUrgent
                            ? l10n.assessmentRecommendUrgent
                            : l10n.assessmentRecommend,
                        style: TextStyle(
                          color: AppTokens.textPrimaryColor(context),
                          fontSize: AppTokens.fontSizeBody,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppTokens.spacingMd),
          // 免责声明
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.spacingMd),
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
                child: OutlinedButton(
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
