// v0.24 round 46 (emil B-11 god class 续拆): assessment_severity_style 抽到独立文件
//
// 严重度样式（label + color），统一一处
// - 底层用 domain 的 `severityRankFor`（临床标准，不是百分比）
// - PHQ-9 5 档：正常 / 轻度 / 中度 / 中重度 / 重度
// - GAD-7 4 档：正常 / 轻度 / 中度 / 重度
// - 配色（4 档色阶，绿/黄/橙/红）：
//   - rank 0 (正常) → primary
//   - rank 1 (轻度) → warning
//   - rank 2 (中度) → warningStrong
//   - rank 3+ (重度) → error
//
// 高内聚：只关心 scaleId + score → (label, color) 映射
// 低耦合：被 SummaryStrip / ChartCard / HistoryItem / SeverityChip 共用
import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

class AssessmentSeverityStyle {
  final int rank;
  final String label;
  final Color color;
  const AssessmentSeverityStyle({
    required this.rank,
    required this.label,
    required this.color,
  });
}

AssessmentSeverityStyle assessmentSeverityStyle(
  BuildContext context,
  String scaleId,
  int score,
  AppLocalizations l10n,
) {
  // R128e 医疗声称降级: 不再返回临床严重度 (轻度/中度/重度 = 诊断行为)。
  // 统一中性: label 空字符串 + primary 配色。
  // 调用方 (summary_strip/history_list/chart_card) 自动中性化, 不用逐处改。
  return AssessmentSeverityStyle(
    rank: 0,
    label: '',
    color: AppTokens.primaryColor(context),
  );
}

/// chart 底轴 label 间距 — 限制最多约 6 个标签，避免 90 个点挤一起
double chartBottomInterval(int n) {
  if (n <= 1) return 1;
  if (n <= 6) return 1;
  return (n / 6).floorToDouble();
}

IconData iconForScale(String scaleId) {
  return scaleId == 'phq9'
      ? Icons.psychology_outlined
      : Icons.psychology_alt_outlined;
}

String nameForScale(String scaleId, AppLocalizations l10n) {
  return scaleId == 'phq9'
      ? l10n.assessmentScalePhq9
      : l10n.assessmentScaleGad7;
}

int maxScoreForScale(String scaleId) {
  return scaleId == 'phq9' ? 27 : 21;
}
