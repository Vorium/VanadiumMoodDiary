// v0.30 round 100: 日常追踪模块化重构
//
// Apple Health 风格:
// - 顶部: 今日追踪汇总 (环形进度 + 已追踪 X/Y)
// - 收藏区: 置顶的追踪项 (横向滚动卡片)
// - 分类区: 按 情绪/身体/行为/医疗 分组, 可折叠
// - 右上角: 自定义按钮 (排序/隐藏/收藏)
//
// 优化: 不再同时 watch 10 个 provider, 每个卡片独立 watch 自己的数据

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/anxiety_agitation_entry.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/domain/entities/social_rhythm_entry.dart';
import 'package:chroniccare/domain/entities/stress_event.dart';
import 'package:chroniccare/domain/entities/tracking_item_config.dart';
import 'package:chroniccare/domain/entities/treatment_entry.dart';
import 'package:chroniccare/domain/entities/weight_entry.dart';
import 'package:chroniccare/domain/logic/mood_period_aggregator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/mood_period_aggregator_chart.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/today_summary_header.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/tracking_item_card.dart';
import 'package:chroniccare/presentation/providers/cbt_rerated_entries_provider.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/providers/tracking_config_provider.dart';
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

    // 今日汇总数据
    final mood = ref.watch(latestMoodEntryProvider);
    final anxiety = ref.watch(latestAnxietyAgitationEntryProvider);
    final sleep = ref.watch(latestSleepEntryProvider);
    final socialRhythm = ref.watch(latestSocialRhythmEntryProvider);
    final stress = ref.watch(latestStressEventEntryProvider);
    final treatment = ref.watch(latestTreatmentEntryProvider);
    final weight = ref.watch(latestWeightEntryProvider);

    // 计算今日已追踪项
    final trackedItems = <String>[];
    if (_isToday(mood)) trackedItems.add(l10n.moodDiaryName);
    if (_isToday(anxiety)) trackedItems.add(l10n.anxietyAgitationName);
    if (_isToday(sleep)) trackedItems.add(l10n.sleepName);
    if (_isToday(socialRhythm)) trackedItems.add(l10n.socialRhythmName);
    if (_isToday(stress)) trackedItems.add(l10n.stressEventName);
    if (_isToday(treatment)) trackedItems.add(l10n.treatmentName);
    if (_isToday(weight)) trackedItems.add(l10n.weightName);

    final visibleItems = configState.allVisibleItems;
    final pinnedItems = configState.pinnedItems;
    final itemsByCategory = configState.itemsByCategory;

    // 多指标趋势图数据
    final moodEntries = ref.watch(moodEntriesProvider);
    final weightEntries = ref.watch(weightEntriesProvider).value ?? const [];
    final sleepEntries = ref.watch(sleepEntriesProvider).value ?? const [];
    final stressEvents =
        ref.watch(stressEventEntriesProvider).value ?? const [];

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
          // 1. 今日汇总
          TodayTrackingSummary(
            trackedCount: trackedItems.length,
            totalCount: visibleItems.length,
            trackedNames: trackedItems,
          ),

          // 2. 多指标趋势图
          if (weightEntries.isNotEmpty ||
              sleepEntries.isNotEmpty ||
              moodEntries.isNotEmpty ||
              stressEvents.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spacingMd),
            DailyTrackingMultiChart(
              weights: weightEntries,
              sleepEntries: sleepEntries,
              moodEntries: moodEntries,
              stressEvents: stressEvents,
            ),
          ],

          // 3. 心境 4 段图
          if (moodEntries.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spacingMd),
            MoodPeriodAggregatorChart(entries: moodEntries),
          ],

          // 4. 收藏区 (横向滚动)
          if (pinnedItems.isNotEmpty) ...[
            const SizedBox(height: AppTokens.spacingMd),
            _PinnedSection(
              items: pinnedItems,
              getLastValue: (id) => _getLastValue(
                id, l10n, mood, anxiety, sleep, socialRhythm,
                stress, treatment, weight,
              ),
            ),
          ],

          // 5. 分类区 (按类别分组)
          for (final entry in itemsByCategory.entries) ...[
            TrackingCategoryHeader(category: entry.key),
            for (final item in entry.value)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.spacingXs),
                child: TrackingItemCard(
                  config: item,
                  lastValue: _getLastValue(
                    item.id, l10n, mood, anxiety, sleep, socialRhythm,
                    stress, treatment, weight,
                  ),
                  onRecord: () => context.push(item.route),
                  onLongPress: () => _showItemActions(context, ref, item),
                ),
              ),
          ],

          // 底部间距
          const SizedBox(height: AppTokens.spacingXl),
        ],
      ),
    );
  }

  /// 判断是否是今天的记录
  bool _isToday(dynamic entity) {
    if (entity == null) return false;
    final now = DateTime.now();
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

  /// 获取上次记录摘要
  String? _getLastValue(
    String id,
    AppLocalizations l10n,
    MoodEntryEntity? mood,
    AnxietyAgitationEntryEntity? anxiety,
    SleepEntryEntity? sleep,
    SocialRhythmEntryEntity? socialRhythm,
    StressEventEntity? stress,
    TreatmentEntryEntity? treatment,
    WeightEntryEntity? weight,
  ) {
    switch (id) {
      case 'mood':
        return _moodLastValue(mood, l10n);
      case 'anxiety':
        return _anxietyLastValue(anxiety, l10n);
      case 'sleep':
        return _sleepLastValue(sleep, l10n);
      case 'social_rhythm':
        return _socialRhythmLastValue(socialRhythm, l10n);
      case 'stress':
        return _stressLastValue(stress, l10n);
      case 'treatment':
        return _treatmentLastValue(treatment, l10n);
      case 'weight':
        return _weightLastValue(weight, l10n);
    }
    return null;
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

  // ============== lastValue format 辅助 (复用原有逻辑) ==============

  static String? _moodLastValue(MoodEntryEntity? e, AppLocalizations l10n) {
    if (e == null) return null;
    final period = MoodPeriod.normalize(e.period);
    final periodLabel = _periodShortLabel(period, l10n);
    if (periodLabel.isEmpty) {
      return l10n.moodDiaryScore(e.score);
    }
    return l10n.moodDiaryLast(
      l10n.dailyTrackingLastTime(l10n.cardStatusToday),
      l10n.moodDiaryScore(e.score),
      periodLabel,
    );
  }

  static String? _anxietyLastValue(
    AnxietyAgitationEntryEntity? e,
    AppLocalizations l10n,
  ) {
    if (e == null) return null;
    return l10n.anxietyAgitationLast(e.anxietyScore, e.agitationScore);
  }

  static String? _sleepLastValue(SleepEntryEntity? e, AppLocalizations l10n) {
    if (e == null) return null;
    if (e.regularityScore != null) {
      return l10n.sleepLast(e.durationLabel, e.regularityScore!);
    }
    return e.durationLabel;
  }

  static String? _socialRhythmLastValue(
    SocialRhythmEntryEntity? e,
    AppLocalizations l10n,
  ) {
    if (e == null) return null;
    final socialH = (e.socialMin / 60).toStringAsFixed(0);
    final workH = (e.workMin / 60).toStringAsFixed(0);
    return l10n.socialRhythmLast(
      '${e.wakeTime.hour.toString().padLeft(2, '0')}:${e.wakeTime.minute.toString().padLeft(2, '0')}',
      int.parse(socialH),
      int.parse(workH),
    );
  }

  static String? _stressLastValue(
    StressEventEntity? e,
    AppLocalizations l10n,
  ) {
    if (e == null) return null;
    return l10n.stressEventLast(e.intensity);
  }

  static String? _treatmentLastValue(
    TreatmentEntryEntity? e,
    AppLocalizations l10n,
  ) {
    if (e == null) return null;
    return l10n.treatmentLast(e.treatmentType, e.description);
  }

  static String? _weightLastValue(
    WeightEntryEntity? e,
    AppLocalizations l10n,
  ) {
    if (e == null) return null;
    final kg = e.weightKg.toStringAsFixed(1);
    if (e.bmi != null) {
      return l10n.weightLast(kg, e.bmi!.toStringAsFixed(1));
    }
    return l10n.weightWeight(kg);
  }

  static String _periodShortLabel(String period, AppLocalizations l10n) {
    switch (period) {
      case MoodPeriod.morning:
        return l10n.periodMorning;
      case MoodPeriod.noon:
        return l10n.periodNoon;
      case MoodPeriod.evening:
        return l10n.periodEvening;
      case MoodPeriod.night:
        return l10n.periodNight;
      case MoodPeriod.unspecified:
        return l10n.periodUnspecified;
    }
    return '';
  }
}

/// 收藏区 (横向滚动卡片)
class _PinnedSection extends StatelessWidget {
  final List<DailyTrackingItemConfig> items;
  final String? Function(String id) getLastValue;

  const _PinnedSection({required this.items, required this.getLastValue});

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
                  lastValue: getLastValue(item.id),
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
