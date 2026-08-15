// 1.1.0 round 5e (emotion-first refactor · Task 15): MoodReviewPage
//
// 情绪回顾页 — 周/月统计摘要。消费 Task 3 的纯函数聚合器
// (filterByRange / summarize / MoodReviewSummary):
// - SegmentedButton 周/月 切换 (月度窗口 = 本月 1 日 ~ now)
// - AppleListSection 分组: 记录天数/均分/delta → 高频标签 → 高频影响因素
//   → 心境时段 → CBT 记录数
// - footer: domain 层鼓励文案 (按均分分档, 空数据也有空态文案)
// - loading: LoadingSkeleton.fullScreen
//
// 取数: ref.watch(allMoodProvider) (shared_providers.dart, StreamProvider
// wrap moodRepository.watchAll) — Riverpod 3 watch(StreamProvider) 返回
// AsyncValue<List<MoodEntryEntity>>, 直接 .when 三态渲染。
//
// 设计要点:
// - `now` 可选构造参数 (测试注入固定时钟, 周界/月界确定性可测;
//   生产 null → DateTime.now())
// - 隐私边界 (AGENTS.md): 跟 vent 严格隔离, 数据只来自 mood 表
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/mood_review_aggregator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 情绪回顾页 (周/月统计摘要)
class MoodReviewPage extends ConsumerStatefulWidget {
  const MoodReviewPage({super.key, this.now});

  /// 测试注入用时钟; null → DateTime.now() (生产路径)
  final DateTime? now;

  @override
  ConsumerState<MoodReviewPage> createState() => _MoodReviewPageState();
}

class _MoodReviewPageState extends ConsumerState<MoodReviewPage> {
  bool _monthly = false;

  DateTime _weekStart(DateTime now) {
    final d = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(d.year, d.month, d.day);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // ref.watch(StreamProvider) → AsyncValue<List<MoodEntryEntity>>
    final entriesAsync = ref.watch(allMoodProvider);
    return PageScaffold(
      title: l10n.moodReviewTitle,
      child: entriesAsync.when(
        data: (entries) {
          final now = widget.now ?? DateTime.now();
          final start = _monthly
              ? DateTime(now.year, now.month, 1)
              : _weekStart(now);
          final prevStart = _monthly
              ? DateTime(now.year, now.month - 1, 1)
              : _weekStart(now).subtract(const Duration(days: 7));
          final current = filterByRange(entries, start, now);
          final previous = filterByRange(
            entries,
            prevStart,
            start.subtract(const Duration(milliseconds: 1)),
          );
          final s = summarize(current, previous);
          return ListView(
            padding: const EdgeInsets.only(bottom: AppTokens.spacingLg),
            children: [
              const SizedBox(height: AppTokens.spacingSm),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l10n.moodReviewWeek)),
                  ButtonSegment(value: true, label: Text(l10n.moodReviewMonth)),
                ],
                selected: {_monthly},
                onSelectionChanged: (sel) =>
                    setState(() => _monthly = sel.first),
              ),
              const SizedBox(height: AppTokens.spacingMd),
              AppleListSection(
                title: l10n.moodReviewTitle,
                children: [
                  ListTile(
                    title: Text(l10n.moodReviewEntriesCount),
                    trailing: Text(
                      '${s.entriesCount}',
                      style: AppTokens.textStyleHeadline(context),
                    ),
                  ),
                  if (s.avgScore != null)
                    ListTile(
                      title: Text(l10n.moodReviewAvgScore),
                      trailing: Text(s.avgScore!.toStringAsFixed(1)),
                    ),
                  if (s.scoreDelta != null)
                    ListTile(
                      title: Text(l10n.moodReviewDelta),
                      trailing: Text(
                        s.scoreDelta! >= 0
                            ? '+${s.scoreDelta!.toStringAsFixed(1)}'
                            : s.scoreDelta!.toStringAsFixed(1),
                      ),
                    )
                  else
                    ListTile(
                      title: Text(l10n.moodReviewDelta),
                      trailing: Text(l10n.moodReviewDeltaNoData),
                    ),
                ],
              ),
              if (s.topTags.isNotEmpty)
                AppleListSection(
                  title: l10n.moodReviewTopTags,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: AppTokens.spacingXs,
                        children: [
                          for (final t in s.topTags) Chip(label: Text(t)),
                        ],
                      ),
                    ),
                  ],
                ),
              if (s.topInfluenceFactors.isNotEmpty)
                AppleListSection(
                  title: l10n.moodReviewTopFactors,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: AppTokens.spacingXs,
                        children: [
                          for (final f in s.topInfluenceFactors)
                            Chip(label: Text(f)),
                        ],
                      ),
                    ),
                  ],
                ),
              if (s.periodCounts.isNotEmpty)
                AppleListSection(
                  title: l10n.moodReviewPeriod,
                  children: [
                    for (final e in s.periodCounts.entries)
                      ListTile(
                        title: Text(e.key),
                        trailing: Text('${e.value}'),
                      ),
                  ],
                ),
              if (s.cbtCount > 0)
                AppleListSection(
                  children: [
                    ListTile(
                      title: Text(l10n.moodReviewCbtCount),
                      trailing: Text('${s.cbtCount}'),
                    ),
                  ],
                ),
              const SizedBox(height: AppTokens.spacingMd),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  s.encouragement,
                  textAlign: TextAlign.center,
                  style: AppTokens.textStyleCaption(context),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingSkeleton.fullScreen(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
