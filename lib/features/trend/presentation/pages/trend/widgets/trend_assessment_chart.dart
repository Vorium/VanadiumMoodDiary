// v0.24 round 46 (emil B-12 god class 续拆): 量表评估历史折线图
//
// 从 trend_charts.dart 拆出
//
// 高内聚：只关心 AssessmentRecord 列表 → 折线图（按 scale 分组）
// 低耦合：被 trend_page 调
//
// v0.30 round 90 (sub-spec 6 量表中心): 升级 R13 内部逻辑
// 单线 → 多线 (AssessmentMultiLineChart 接管), 保留 R13 公开接口
// `AssessmentHistoryChart(records: List<AssessmentRecord>)` 不变, 内部
// 把 AssessmentRecord 映射为 AssessmentEntry (1:1, 兜底) 走 R90 新 widget。
//
// 公开接口 backward-compat:
// - constructor: `AssessmentHistoryChart({required List<AssessmentRecord> records})`
// - caller: `trend_page.dart:194 AssessmentHistoryChart(records: records)`
//   (R60 AssessmentRecord.tryFromEntity 转换结果)
import 'package:flutter/material.dart';

import 'package:chroniccare/domain/entities/assessment_entry.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/domain/logic/assessment_record.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/charts/assessment_multi_line_chart.dart';

class AssessmentHistoryChart extends StatelessWidget {
  final List<AssessmentRecord> records;
  const AssessmentHistoryChart({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (records.isEmpty) {
      // 空记录 → 友好空态 (跟 R46 老 chart 同款, 保持视觉一致)
      return Card(
        child: Padding(
          padding: AppTokens.edgeInsetsSm,
          child: Column(
            children: [
              const Icon(Icons.show_chart, size: 40),
              const SizedBox(height: 8),
              Text(
                l10n.trendNoAssessments,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.trendNoAssessmentsHint,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // AssessmentRecord → AssessmentEntry 1:1 映射 (兜底)
    // R60 老格式 (scaleId 限 phq9/gad7) 走 record.total → entry.score
    // R90 新格式 (10 量表) 走 entry.score 直接
    final entries = <AssessmentEntry>[
      for (var i = 0; i < records.length; i++)
        AssessmentEntry(
          id: i + 1, // synthetic id, widget 不依赖
          timestamp: records[i].timestamp,
          scaleId: records[i].scaleId,
          score: records[i].total,
          // R60 AssessmentRecord 没 severityRank / answers, 走 0 / const []
          severityRank: 0,
          answers: const [],
        ),
    ];

    return Card(
      child: Padding(
        padding: AppTokens.edgeInsetsSm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.assessmentCenterMultiLineTitle,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeLabel,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTokens.spacingXs),
            // 委托 R90 新 widget 渲染 (10 量表多色多线型 + chip toggle)
            AssessmentMultiLineChart(entries: entries),
          ],
        ),
      ),
    );
  }
}
