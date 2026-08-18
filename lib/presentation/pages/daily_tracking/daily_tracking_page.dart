// v0.30 round 100: 日常追踪模块化重构
//
// Apple Health 风格:
// - 顶部: 今日追踪汇总 (环形进度 + 已追踪 X/Y)
// - 收藏区: 置顶的追踪项 (横向滚动卡片)
// - 分类区: 按 情绪/身体/行为/医疗 分组, 可折叠
// - 右上角: 自定义按钮 (排序/隐藏/收藏)
//
// v0.32 R110 round 7a (FS-2): 子树隔离 — 任一 entry 流 tick 只重建
// 对应小节 (汇总/图表/单卡片), 不再整页 403L 重建:
// - _LatestSummarySection: 自行 watch 7 个 latest 流 (今日已追踪 X/Y)
// - _MultiChartSection + _MoodChartSection: 自行 watch 自己的 entries 流
// - TrackingItemCard: 卡片自行 watch 自己的 latest 流 (删 lastValue 参数)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/domain/entities/anxiety_agitation_entry.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/domain/entities/social_rhythm_entry.dart';
import 'package:chroniccare/domain/entities/stress_event.dart';
import 'package:chroniccare/domain/entities/tracking_item_config.dart';
import 'package:chroniccare/domain/entities/treatment_entry.dart';
import 'package:chroniccare/domain/entities/weight_entry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/mood_period_aggregator_chart.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/today_summary_header.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/tracking_item_card.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/providers/tracking_config_provider.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/charts/daily_tracking_multi_chart.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

/// 日常追踪模块化入口页
class DailyTrackingPage extends ConsumerWidget {
  const DailyTrackingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final configState = ref.watch(trackingConfigProvider);

    final pinnedItems = configState.pinnedItems;
    final itemsByCategory = configState.itemsByCategory;

    return PageScaffold(
      title: l10n.dailyTrackingTitle,
      actions: [
        // v0.31.1 round 8 (emil P0-C + R108 P1-001 漏修): 改用
        // PressFeedbackIconButton 集中器。
        PressFeedbackIconButton(
          icon: Icons.tune,
          tooltip: l10n.trackingCustomize,
          onPressed: () => context.push('/daily-tracking/customize'),
        ),
      ],
      child: ListView(
        padding: AppTokens.edgeInsetsMd,
        children: [
          // 1. 今日汇总 (自 watch 7 个 latest 流, FS-2)
          const _LatestSummarySection(),

          // 2. 多指标趋势图 (自 watch 自己的 entries 流, FS-2)
          const _MultiChartSection(),

          // 3. 心境 4 段图 (自 watch moodEntries, FS-2)
          const _MoodChartSection(),

          // 4. 收藏区 (横向滚动)
          if (pinnedItems.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spacingMd),
            _PinnedSection(items: pinnedItems),
          ],

          // 5. 分类区 (按类别分组)
          // v0.32 R112 (EM-02/AH-04): TrackingCategoryHeader + Padding(Card)
          // → AppleListSection (iOS 群组列表, 类别名走 ALL CAPS title)
          for (final entry in itemsByCategory.entries) ...[
            AppleListSection(
              title: _categoryLabel(l10n, entry.key),
              margin: EdgeInsets.zero,
              children: [
                for (final item in entry.value)
                  TrackingItemCard(
                    config: item,
                    onRecord: () => context.push(item.route),
                    onLongPress: () => _showItemActions(context, ref, item),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingSm),
          ],

          // 底部间距
          const SizedBox(height: AppTokens.spacingXl),
        ],
      ),
    );
  }

  /// v0.32 R112: 分类名 → l10n (原 TrackingCategoryHeader 私有映射平移)
  String _categoryLabel(AppLocalizations l10n, TrackingCategory cat) {
    switch (cat) {
      case TrackingCategory.emotional:
        return l10n.trackingCategoryEmotional;
      case TrackingCategory.physical:
        return l10n.trackingCategoryPhysical;
      case TrackingCategory.behavioral:
        return l10n.trackingCategoryBehavioral;
      case TrackingCategory.medical:
        return l10n.trackingCategoryMedical;
    }
  }

  /// 长按弹出操作菜单
  void _showItemActions(
    BuildContext context,
    WidgetRef ref,
    DailyTrackingItemConfig item,
  ) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                item.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                color: item.isPinned ? AppTokens.textHintColor(context) : null,
              ),
              title: Text(
                item.isPinned ? l10n.trackingUnpin : l10n.trackingPin,
              ),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(trackingConfigProvider.notifier).togglePin(item.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off_outlined),
              title: Text(l10n.trackingHide),
              onTap: () {
                Navigator.pop(ctx);
                ref.read(trackingConfigProvider.notifier).toggleHide(item.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 今日汇总小节 — 自行 watch 7 个 latest 流 (FS-2 隔离, 原 7 watch 迁入)
///
/// 任一 entry 新写入 → 只有本小节 + 对应卡片重建, 页面主体不动。
class _LatestSummarySection extends ConsumerWidget {
  const _LatestSummarySection();

  /// 判断是否是今天的记录 (从原页面 method 平移, 行为 1:1)
  ///
  /// Wave 7 (Task B, R113): `now` 由 build 的 ref.watch(todayProvider) 传入
  /// (修前内部 DateTime.now(), 跨 midnight 汇总 stale 到次日)。
  static bool _isToday(dynamic entity, DateTime now) {
    if (entity == null) return false;
    try {
      DateTime ts;
      if (entity is MoodEntryEntity) {
        ts = entity.timestamp;
      } else if (entity is AnxietyAgitationEntryEntity) {
        ts = entity.timestamp;
      } else if (entity is SleepEntryEntity) {
        ts = entity.date;
      } else if (entity is SocialRhythmEntryEntity) {
        ts = entity.date;
      } else if (entity is StressEventEntity) {
        ts = entity.timestamp;
      } else if (entity is TreatmentEntryEntity) {
        ts = entity.timestamp;
      } else if (entity is WeightEntryEntity) {
        ts = entity.timestamp;
      } else {
        return false;
      }
      return ts.year == now.year && ts.month == now.month && ts.day == now.day;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Wave 7 (Task B, R113): "今天"基准改 watch(todayProvider), 传给
    // _isToday — 跨 midnight 汇总小节自动刷新 (修前 DateTime.now() stale)。
    final now = ref.watch(todayProvider);
    // R114 B1-7: latestMoodEntryProvider 是 sync 链 (error 会抛) — 改读
    // allMoodProvider.value (error → null → 汇总显示"未记录"不崩)。
    final mood = ref.watch(allMoodProvider).value?.firstOrNull;
    final anxiety = ref.watch(latestAnxietyAgitationEntryProvider);
    final sleep = ref.watch(latestSleepEntryProvider);
    final socialRhythm = ref.watch(latestSocialRhythmEntryProvider);
    final stress = ref.watch(latestStressEventEntryProvider);
    final treatment = ref.watch(latestTreatmentEntryProvider);
    final weight = ref.watch(latestWeightEntryProvider);

    final trackedItems = <String>[];
    if (_isToday(mood, now)) trackedItems.add(l10n.moodDiaryName);
    if (_isToday(anxiety, now)) trackedItems.add(l10n.anxietyAgitationName);
    if (_isToday(sleep, now)) trackedItems.add(l10n.sleepName);
    if (_isToday(socialRhythm, now)) trackedItems.add(l10n.socialRhythmName);
    if (_isToday(stress, now)) trackedItems.add(l10n.stressEventName);
    if (_isToday(treatment, now)) trackedItems.add(l10n.treatmentName);
    if (_isToday(weight, now)) trackedItems.add(l10n.weightName);

    final totalCount = ref.watch(trackingConfigProvider).allVisibleItems.length;

    return TodayTrackingSummary(
      trackedCount: trackedItems.length,
      totalCount: totalCount,
      trackedNames: trackedItems,
    );
  }
}

/// 多指标趋势图小节 — 自 watch 4 个 entries 流 (FS-2)
class _MultiChartSection extends ConsumerWidget {
  const _MultiChartSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // R114 B1-7: moodEntriesProvider sync 链 error 会抛 — 改读
    // allMoodProvider.value (error → 空 → 小节隐藏, 不崩)。
    final moodEntries = ref.watch(allMoodProvider).value ?? const [];
    final weightEntries = ref.watch(weightEntriesProvider).value ?? const [];
    final sleepEntries = ref.watch(sleepEntriesProvider).value ?? const [];
    final stressEvents =
        ref.watch(stressEventEntriesProvider).value ?? const [];

    if (weightEntries.isEmpty &&
        sleepEntries.isEmpty &&
        moodEntries.isEmpty &&
        stressEvents.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTokens.spacingMd),
        DailyTrackingMultiChart(
          weights: weightEntries,
          sleepEntries: sleepEntries,
          moodEntries: moodEntries,
          stressEvents: stressEvents,
        ),
      ],
    );
  }
}

/// 心境 4 段图小节 — 自 watch moodEntries (FS-2)
class _MoodChartSection extends ConsumerWidget {
  const _MoodChartSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // R114 B1-7: moodEntriesProvider sync 链 error 会抛 — 改读
    // allMoodProvider.value (error → 空 → 小节隐藏, 不崩)。
    final moodEntries = ref.watch(allMoodProvider).value ?? const [];
    if (moodEntries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppTokens.spacingMd),
        MoodPeriodAggregatorChart(entries: moodEntries),
      ],
    );
  }
}

/// 收藏区 (横向滚动卡片) — 卡片自 watch 自己的流
class _PinnedSection extends StatelessWidget {
  final List<DailyTrackingItemConfig> items;

  const _PinnedSection({required this.items});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: AppTokens.spacingXs,
            left: AppTokens.spacingXxs,
          ),
          child: Row(
            children: [
              Icon(
                Icons.push_pin,
                size: 14,
                color: AppTokens.textHintColor(context),
              ),
              const SizedBox(width: 4),
              Text(
                l10n.trackingPinned,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppTokens.textHintColor(context),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppTokens.spacingSm),
            itemBuilder: (context, i) {
              final item = items[i];
              return SizedBox(
                width: 260,
                child: TrackingItemCard(
                  config: item,
                  onRecord: () => context.push(item.route),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
