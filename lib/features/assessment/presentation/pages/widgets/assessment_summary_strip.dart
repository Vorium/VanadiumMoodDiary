// v0.24 round 46 (emil B-11 god class 续拆): SummaryStrip 抽到独立文件
//
// 顶部汇总条：总次数 / 最新 PHQ-9 / 最新 GAD-7
//
// 高内聚：只关心 records → 3 stat 卡片
// 低耦合：被 AssessmentHistoryPage orchestrator 调，靠 assessmentSeverityStyle 算颜色
//
// v0.32 R112 (EM-02/AH-04, spec §5.7): Card → AppleListSection
import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/features/assessment/domain/logic/assessment_record.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
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
                // R128e 医疗声称降级: sub 不再显示"轻度／中度／重度"
                // 临床严重度，改显示最近一次日期（中性信息）
                sub: latestPhq9 == null
                    ? l10n.assessmentHistoryNotDone
                    : _formatDate(latestPhq9.timestamp),
              ),
            ),
            Expanded(
              child: _Stat(
                label: l10n.assessmentHistoryLatestGad7,
                value: latestGad7 == null ? '—' : '${latestGad7.total}',
                sub: latestGad7 == null
                    ? l10n.assessmentHistoryNotDone
                    : _formatDate(latestGad7.timestamp),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
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
  const _Stat({
    required this.label,
    required this.value,
    this.sub,
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
              color: AppTokens.textHintColor(context),
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
