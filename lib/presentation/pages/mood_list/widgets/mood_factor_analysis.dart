// v0.30 R101: 因素关联分析 widget — 参照 Apple Health State of Mind
//
// 遍历所有有影响因素的 entry，按因素分组计算平均分。
// 输出: [{factor: "家人", avg: 4.2, count: 15}, ...]
// 按平均分排序。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/influence_category.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/services/influence_factor_l10n.dart';

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
        // v0.32 R112-03: 归一化成 i18n key 再分组 (兼容存量中文数据),
        // 展示侧走 influenceFactorL10nLabel ARB 派发
        final key = influenceFactorNormalizeKey(factor);
        factorScores.putIfAbsent(key, () => []);
        factorScores[key]!.add(e.score);
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
    // 指示条颜色走浅色状态色 (装饰用)
    final color = avgScore >= 4
        ? AppColors.success
        : avgScore >= 3
            ? AppColors.warning
            : AppColors.error;
    // v0.32 round 8 (R112 EM-16b fix): 状态色只作指示条/装饰,
    // 文字色走深色档 token (浅色状态色白底对比度 2.3~3.0:1 不达标):
    // - ≥4 → fgOnSuccess 深绿 #2E7D32
    // - 3   → fgOnWarning 深橙 #E65100 (R111 EM-16)
    // - <3  → fgError 深红 #C62828
    final textColor = avgScore >= 4
        ? AppColors.fgOnSuccess
        : avgScore >= 3
            ? AppColors.fgOnWarning
            : AppColors.fgError;

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
          // 因素名 (key → locale 文案, 未知自定义值原样上屏)
          Expanded(
            child: Text(
              influenceFactorL10nLabel(l10n, factor),
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
              color: textColor,
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
