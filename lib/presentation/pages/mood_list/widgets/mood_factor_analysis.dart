// v0.30 R101: 因素关联分析 widget — 参照 Apple Health State of Mind
//
// 遍历所有有影响因素的 entry，按因素分组计算平均分。
// 输出: [{factor: "家人", avg: 4.2, count: 15}, ...]
// 按平均分排序。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';

/// 因素关联分析卡片
class MoodFactorAnalysis extends ConsumerWidget {
  const MoodFactorAnalysis({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final moodsAsync = ref.watch(allMoodProvider);

    return moodsAsync.when(
      data: (entries) {
        final analysis = _analyze(entries);
        if (analysis.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: AppTokens.edgeInsetsMd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.moodFactorAnalysis,
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTokens.spacingSm),
                ...analysis.take(10).map(
                      (item) => _FactorRow(
                        factor: item.factor,
                        avgScore: item.avgScore,
                        count: item.count,
                      ),
                    ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  List<_FactorStats> _analyze(List<MoodEntryEntity> entries) {
    final factorScores = <String, List<int>>{};

    for (final e in entries) {
      if (!e.hasInfluenceFactors) continue;
      for (final factor in e.influenceFactors) {
        factorScores.putIfAbsent(factor, () => []);
        factorScores[factor]!.add(e.score);
      }
    }

    final stats = factorScores.entries.map((entry) {
      final scores = entry.value;
      final avg = scores.reduce((a, b) => a + b) / scores.length;
      return _FactorStats(entry.key, avg, scores.length);
    }).toList();

    // 按平均分降序排列
    stats.sort((a, b) => b.avgScore.compareTo(a.avgScore));
    return stats;
  }
}

class _FactorStats {
  final String factor;
  final double avgScore;
  final int count;
  const _FactorStats(this.factor, this.avgScore, this.count);
}

class _FactorRow extends StatelessWidget {
  const _FactorRow({
    required this.factor,
    required this.avgScore,
    required this.count,
  });

  final String factor;
  final double avgScore;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = avgScore >= 4
        ? AppColors.success
        : avgScore >= 3
            ? AppColors.warning
            : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 分数指示条
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppTokens.spacingSm),
          // 因素名
          Expanded(
            child: Text(
              factor,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeBodySm,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 平均分
          Text(
            avgScore.toStringAsFixed(1),
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: AppTokens.spacingXs),
          // 记录数
          Text(
            l10n.factorAnalysisCount(count),
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textHintColor(context),
            ),
          ),
        ],
      ),
    );
  }
}
