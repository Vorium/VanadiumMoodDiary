// v0.24 round 46 (emil B-11 god class 续拆): HistoryList + HistoryItem + SeverityChip 抽到独立文件
//
// 完整历史列表：每条记录 + 与上一条同量表对比
//
// 高内聚：只关心 records → 列表 + diff 标识
// 低耦合：被 AssessmentHistoryPage orchestrator 调，靠 assessment_severity_style 配色
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/assessment_record.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/assessment/widgets/assessment_severity_style.dart';

class AssessmentHistoryList extends StatelessWidget {
  final List<AssessmentRecord> records;
  const AssessmentHistoryList({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spacingMd,
              AppTokens.spacingMd,
              AppTokens.spacingMd,
              AppTokens.spacingSm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: AppTokens.primaryColor(context),
                  size: 20,
                ),
                const SizedBox(width: AppTokens.spacingSm),
                Text(
                  AppLocalizations.of(context).assessmentHistoryFullRecord,
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < records.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 56),
            _HistoryItem(
              record: records[i],
              // v0.14 fix: 找上一条**同量表**的记录，而不是 list 里前一条
              // 旧实现：PHQ-9 和 GAD-7 混排时，diff 会拿不同量表对比（无意义）
              previous: _findPreviousSameScale(records, i),
            ),
          ],
        ],
      ),
    );
  }

  /// 找 index i 之前，最近一条同 scaleId 的记录
  ///
  /// records 已按时间倒序排列
  AssessmentRecord? _findPreviousSameScale(
    List<AssessmentRecord> records,
    int i,
  ) {
    final scaleId = records[i].scaleId;
    for (int j = i + 1; j < records.length; j++) {
      if (records[j].scaleId == scaleId) return records[j];
    }
    return null;
  }
}

class _HistoryItem extends StatelessWidget {
  final AssessmentRecord record;
  final AssessmentRecord? previous;
  const _HistoryItem({required this.record, this.previous});

  @override
  Widget build(BuildContext context) {
    final diff = previous == null ? null : record.total - previous!.total;
    final sev = assessmentSeverityStyle(
      context,
      record.scaleId,
      record.total,
      AppLocalizations.of(context),
    );
    final color = sev.color;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMd,
        vertical: AppTokens.spacingSm,
      ),
      child: Row(
        children: [
          Container(
            width: AppTokens.avatarSizeMd,
            height: AppTokens.avatarSizeMd,
            decoration: BoxDecoration(
              // v0.22 round 30 (sp-zh P2-3): 走 tintedXxxDeep 集中器
              color: color == AppTokens.primaryColor(context)
                  ? AppTokens.tintedPrimaryDeep(context)
                  : AppTokens.tintedErrorDeep(context),
              borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            ),
            child: Center(
              child: Text(
                '${record.total}',
                style: AppTokens.textStyleCaption(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      nameForScale(
                        record.scaleId,
                        AppLocalizations.of(context),
                      ),
                      style: AppTokens.textStyleCaptionStrong(context),
                    ),
                    const SizedBox(width: AppTokens.spacingSm),
                    _SeverityChip(scaleId: record.scaleId, score: record.total),
                  ],
                ),
                const SizedBox(height: AppTokens.spacingXxxs),
                Text(
                  _formatDateTime(record.timestamp),
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHintColor(context),
                  ),
                ),
              ],
            ),
          ),
          if (diff != null && diff != 0)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacingXs,
                vertical: AppTokens.spacingXxxs,
              ),
              decoration: BoxDecoration(
                // v0.22 round 30 (sp-zh P2-3): 走 tintedXxxDeep 集中器
                color: diff < 0
                    ? AppTokens.tintedPrimaryDeep(context)
                    : AppTokens.tintedErrorDeep(context),
                borderRadius: BorderRadius.circular(AppTokens.radiusChip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    diff < 0 ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 12,
                    color: diff < 0
                        ? AppTokens.primaryColor(context)
                        : AppTokens.errorColor(context),
                  ),
                  const SizedBox(width: AppTokens.spacingXxxs),
                  Text(
                    '${diff.abs()}',
                    style: AppTokens.textStyleMicro(context).copyWith(
                      fontWeight: FontWeight.w600,
                      color: diff < 0
                          ? AppTokens.primaryColor(context)
                          : AppTokens.errorColor(context),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _SeverityChip extends StatelessWidget {
  final String scaleId;
  final int score;
  const _SeverityChip({required this.scaleId, required this.score});

  @override
  Widget build(BuildContext context) {
    final sev = assessmentSeverityStyle(
      context,
      scaleId,
      score,
      AppLocalizations.of(context),
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingChipGap,
        vertical: AppTokens.spacingXxxs,
      ),
      decoration: BoxDecoration(
        // v0.22 round 30 (sp-zh P2-3): 走 tintedXxxDeep 集中器
        color: sev.color == AppTokens.primaryColor(context)
            ? AppTokens.tintedPrimaryDeep(context)
            : AppTokens.tintedErrorDeep(context),
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      ),
      child: Text(
        sev.label,
        style: AppTokens.textStyleMicro(context).copyWith(
          color: sev.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
