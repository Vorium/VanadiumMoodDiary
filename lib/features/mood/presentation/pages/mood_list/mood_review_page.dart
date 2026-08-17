// 1.1.0 round 5e (emotion-first refactor · Task 15): MoodReviewPage
//
// 情绪回顾页 — 周/月统计摘要。消费 Task 3 的纯函数聚合器
// (filterByRange / summarize / MoodReviewSummary):
// - SegmentedButton 周/月 切换 (月度窗口 = 本月 1 日 ~ now)
// - AppleListSection 分组: 记录天数/均分/delta → 高频标签 → 高频影响因素
//   → 心境时段 → CBT 记录数
// - footer: 鼓励文案 (domain 层产 tier, 显示层 localizedEncouragement 走 ARB)
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
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/mood_period_aggregator.dart';
import 'package:chroniccare/domain/logic/mood_review_aggregator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/preset_content_l10n.dart';
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

  /// 时段 key → 本地化标签 (复用 mood_detail_page._periodLabel 同款映射 +
  /// ARB moodPeriod* key, 不新增重复 key; round 5e fix 1)
  String _periodLabel(AppLocalizations l10n, String period) {
    switch (period) {
      case MoodPeriod.morning:
        return l10n.moodPeriodMorning;
      case MoodPeriod.noon:
      case 'afternoon':
        return l10n.moodPeriodAfternoon;
      case MoodPeriod.evening:
        return l10n.moodPeriodEvening;
      case MoodPeriod.night:
        return l10n.moodPeriodNight;
      default:
        return period;
    }
  }

  /// 稳定显示序: morning → noon → evening → night, 未知 key 按字母序垫底
  /// (Map 迭代序不保证, 直接遍历会闪烁/乱序; round 5e fix 1)
  List<MapEntry<String, int>> _orderedPeriodEntries(
    Map<String, int> counts,
  ) {
    final entries = counts.entries.toList();
    final ordered = <MapEntry<String, int>>[];
    for (final p in MoodPeriod.fourPeriods) {
      final i = entries.indexWhere((e) => e.key == p);
      if (i >= 0) {
        ordered.add(entries.removeAt(i));
      }
    }
    entries.sort((a, b) => a.key.compareTo(b.key));
    return [...ordered, ...entries];
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
          // Wave 7 (Task B, R113): 修前 widget.now ?? DateTime.now() 跨
          // midnight 不 rebuild → 周/月窗口 stale 到次日。改 ?? 右侧
          // ref.watch(todayProvider) (watch dayChangeTickProvider, AppRoot
          // 跨日 tick 自动刷新)。widget.now 测试注入优先, 行为不变。
          // (`!`: ?? 的 LUB 把非空右值又变回可空类型)
          final now = widget.now ?? ref.watch(todayProvider)!;
          final start =
              _monthly ? DateTime(now.year, now.month, 1) : _weekStart(now);
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
                    for (final e in _orderedPeriodEntries(s.periodCounts))
                      ListTile(
                        title: Text(_periodLabel(l10n, e.key)),
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
                  localizedEncouragement(context, s.encouragement),
                  textAlign: TextAlign.center,
                  style: AppTokens.textStyleCaption(context),
                ),
              ),
              // round 7c: /mood-trend 死路由入口补齐 (P2 gatekeeper blind spot)
              Center(
                child: TextButton(
                  onPressed: () => context.push('/mood-trend'),
                  child: Text(l10n.moodReviewViewTrend),
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
