// v0.24 round 46 (emil B-11 god class 续拆): SummaryStrip 抽到独立文件
//
// 顶部汇总条：总次数 / 最新 PHQ-9 / 最新 GAD-7
//
// 高内聚：只关心 records → 3 stat 卡片
// 低耦合：被 AssessmentHistoryPage orchestrator 调，靠 assessmentSeverityStyle 算颜色
//
// v0.32 R112 (EM-02/AH-04, spec §5.7): Card → AppleListSection
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/features/assessment/domain/logic/assessment_record.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/assessment/widgets/assessment_severity_style.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';

class AssessmentSummaryStrip extends StatelessWidget {
  final List<AssessmentRecord> records;
  const AssessmentSummaryStrip({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    // 最近一次：每个量表独立
    final latestPhq9 = _latest(records, 'phq9');
    final latestGad7 = _latest(records, 'gad7');
    final totalCount = records.length;
    final l10n = AppLocalizations.of(context);
    return AppleListSection(
      margin: EdgeInsets.zero,
      children: [
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: l10n.assessmentHistoryTotalAssessments,
                value: '$totalCount',
                sub: l10n.assessmentHistoryTimes,
              ),
            ),
            Expanded(
              child: _Stat(
                label: l10n.assessmentHistoryLatestPhq9,
                value: latestPhq9 == null ? '—' : '${latestPhq9.total}',
                sub: latestPhq9 == null
                    ? l10n.assessmentHistoryNotDone
                    : assessmentSeverityStyle(
                        context,
                        'phq9',
                        latestPhq9.total,
                        l10n,
                      ).label,
                severity: latestPhq9 == null
                    ? null
                    : assessmentSeverityStyle(
                        context,
                        'phq9',
                        latestPhq9.total,
                        l10n,
                      ).color,
              ),
            ),
            Expanded(
              child: _Stat(
                label: l10n.assessmentHistoryLatestGad7,
                value: latestGad7 == null ? '—' : '${latestGad7.total}',
                sub: latestGad7 == null
                    ? l10n.assessmentHistoryNotDone
                    : assessmentSeverityStyle(
                        context,
                        'gad7',
                        latestGad7.total,
                        l10n,
                      ).label,
                severity: latestGad7 == null
                    ? null
                    : assessmentSeverityStyle(
                        context,
                        'gad7',
                        latestGad7.total,
                        l10n,
                      ).color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  AssessmentRecord? _latest(List<AssessmentRecord> records, String scaleId) {
    final filtered = records.where((r) => r.scaleId == scaleId).toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered.first;
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final Color? severity; // null = 灰色，otherwise 严重度配色
  const _Stat({
    required this.label,
    required this.value,
    this.sub,
    this.severity,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTokens.fontSizeCaption,
            color: AppTokens.textHintColor(context),
          ),
        ),
        const SizedBox(height: AppTokens.spacingXxxs),
        Text(
          value,
          style: AppTokens.textStyleHeadline(context),
        ),
        if (sub != null)
          Text(
            sub!,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaptionSm,
              color: severity ?? AppTokens.textHintColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
