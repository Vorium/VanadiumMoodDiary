// v0.30 round 91 (sub-spec 7 日常追踪 / Task 5 整合入口): 整合入口页
//
// 路径: `/daily-tracking`
// 7 卡片 grid (2 列): 情绪日记 + 5 子功能 + 1 治疗
// 顶部: 心境 4 段图 (Task 2 已做, 集成)
//
// 类比 R90 assessment_center_page 模式:
// - 1 page = 1 directory (本文件在 daily_tracking/, widget 在 widgets/)
// - 7 卡片 grid (2 列移动端)
// - 顶部 mini 趋势图 (Task 6 实施, 留 SizedBox 占位; 本 task 集成现有
//   MoodPeriodAggregatorChart 给 mood 段)
//
// 4 层架构: presentation/pages/daily_tracking/, 0 跨 page/ 引用。
// 只用 presentation/providers/ + core/ + domain/ + 同 page widget。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/anxiety_agitation_entry.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/domain/entities/social_rhythm_entry.dart';
import 'package:chroniccare/domain/entities/stress_event.dart';
import 'package:chroniccare/domain/entities/treatment_entry.dart';
import 'package:chroniccare/domain/entities/weight_entry.dart';
import 'package:chroniccare/domain/logic/mood_period_aggregator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/daily_tracking_card.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/mood_period_aggregator_chart.dart';
import 'package:chroniccare/presentation/providers/cbt_rerated_entries_provider.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/widgets/charts/daily_tracking_multi_chart.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// v0.30 R91 Task 5: 日常追踪整合入口页
///
/// 7 卡片 grid (1 情绪日记合并 + 5 子功能 + 1 治疗), 顶部心境 4 段图。
/// 类比 R90 `/assessment-center` 中心化入口页模式。
///
/// v0.30 R91 Task 7: title / 7 卡片 title / 7 lastValue / period short label
/// 全部走 l10n。
class DailyTrackingPage extends ConsumerWidget {
  const DailyTrackingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // 7 个 latestEntryProvider (跟 R90 latestEntryByScaleProvider 模式,
    // 但统一用 sync Provider<Entity?> 跟 mood 一致 — 见 daily_tracking_providers)
    final mood = ref.watch(latestMoodEntryProvider);
    final anxiety = ref.watch(latestAnxietyAgitationEntryProvider);
    final sleep = ref.watch(latestSleepEntryProvider);
    final socialRhythm = ref.watch(latestSocialRhythmEntryProvider);
    final stress = ref.watch(latestStressEventEntryProvider);
    final treatment = ref.watch(latestTreatmentEntryProvider);
    final weight = ref.watch(latestWeightEntryProvider);
    // 心境 4 段图 (Task 2): 走 moodEntriesProvider sync list
    final moodEntries = ref.watch(moodEntriesProvider);
    // v0.30 R91 Task 6: 多指标趋势图 4 指标 (体重/睡眠/心境/应激源)
    // 4 指标 entries 来自各自 StreamProvider (autoDispose), 30 天时间窗
    final weightEntries = ref.watch(weightEntriesProvider).value ?? const [];
    final sleepEntries = ref.watch(sleepEntriesProvider).value ?? const [];
    final stressEvents =
        ref.watch(stressEventEntriesProvider).value ?? const [];

    return PageScaffold(
      title: l10n.dailyTrackingTitle,
      child: ListView(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        children: [
          // v0.30 R91 Task 6: 顶部多指标 mini 趋势图 (4 指标 30 天)
          // 复用 R90 assessment_multi_line_chart 模式, 4 chip toggle + 4 line
          // 4 指标单位不同 → Y 归一化 0-1 (chart widget 内部做)
          DailyTrackingMultiChart(
            weights: weightEntries,
            sleepEntries: sleepEntries,
            moodEntries: moodEntries,
            stressEvents: stressEvents,
          ),
          const SizedBox(height: AppTokens.spacingMd),
          // 心境 4 段图 (Task 2 已做, 集成)
          if (moodEntries.isNotEmpty)
            MoodPeriodAggregatorChart(entries: moodEntries),
          if (moodEntries.isNotEmpty)
            const SizedBox(height: AppTokens.spacingMd),

          // 7 卡片 grid (2 列)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppTokens.spacingSm,
              mainAxisSpacing: AppTokens.spacingSm,
              childAspectRatio: 1.1,
            ),
            itemCount: 7,
            itemBuilder: (context, i) => _buildCard(
              context,
              i,
              mood: mood,
              anxiety: anxiety,
              sleep: sleep,
              socialRhythm: socialRhythm,
              stress: stress,
              treatment: treatment,
              weight: weight,
            ),
          ),
        ],
      ),
    );
  }

  /// 单张卡片 (按 i 派发到 7 子功能, 每张 format "上次 X" 摘要)
  Widget _buildCard(
    BuildContext context,
    int i, {
    required MoodEntryEntity? mood,
    required AnxietyAgitationEntryEntity? anxiety,
    required SleepEntryEntity? sleep,
    required SocialRhythmEntryEntity? socialRhythm,
    required StressEventEntity? stress,
    required TreatmentEntryEntity? treatment,
    required WeightEntryEntity? weight,
  }) {
    final l10n = AppLocalizations.of(context);
    // i 派发 7 子功能 (顺序固定, 跟 brief 1:1)
    switch (i) {
      case 0:
        return DailyTrackingCard(
          title: l10n.moodDiaryName,
          description: l10n.moodDiaryShortDesc,
          route: '/mood-diary',
          lastValue: _moodLastValue(mood, l10n),
        );
      case 1:
        return DailyTrackingCard(
          title: l10n.anxietyAgitationName,
          description: l10n.anxietyAgitationShortDesc,
          route: '/anxiety-agitation',
          lastValue: _anxietyLastValue(anxiety, l10n),
        );
      case 2:
        return DailyTrackingCard(
          title: l10n.sleepName,
          description: l10n.sleepShortDesc,
          route: '/sleep',
          lastValue: _sleepLastValue(sleep, l10n),
        );
      case 3:
        return DailyTrackingCard(
          title: l10n.socialRhythmName,
          description: l10n.socialRhythmShortDesc,
          route: '/social-rhythm',
          lastValue: _socialRhythmLastValue(socialRhythm, l10n),
        );
      case 4:
        return DailyTrackingCard(
          title: l10n.stressEventName,
          description: l10n.stressEventShortDesc,
          route: '/stress-events',
          lastValue: _stressLastValue(stress, l10n),
        );
      case 5:
        return DailyTrackingCard(
          title: l10n.treatmentName,
          description: l10n.treatmentShortDesc,
          route: '/treatment',
          lastValue: _treatmentLastValue(treatment, l10n),
        );
      case 6:
        return DailyTrackingCard(
          title: l10n.weightName,
          description: l10n.weightShortDesc,
          route: '/weight',
          lastValue: _weightLastValue(weight, l10n),
        );
    }
    return const SizedBox.shrink();
  }

  // ============== 7 子功能 lastValue format 辅助 ==============

  String? _moodLastValue(MoodEntryEntity? e, AppLocalizations l10n) {
    if (e == null) return null;
    // v0.30 R91 Task 7: 走 l10n.moodDiaryLast 完整摘要 (time + score + period)
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

  String? _anxietyLastValue(
      AnxietyAgitationEntryEntity? e, AppLocalizations l10n,) {
    if (e == null) return null;
    return l10n.anxietyAgitationLast(e.anxietyScore, e.agitationScore);
  }

  String? _sleepLastValue(SleepEntryEntity? e, AppLocalizations l10n) {
    if (e == null) return null;
    if (e.regularityScore != null) {
      return l10n.sleepLast(e.durationLabel, e.regularityScore!);
    }
    return e.durationLabel;
  }

  String? _socialRhythmLastValue(
      SocialRhythmEntryEntity? e, AppLocalizations l10n,) {
    if (e == null) return null;
    final socialH = (e.socialMin / 60).toStringAsFixed(0);
    final workH = (e.workMin / 60).toStringAsFixed(0);
    return l10n.socialRhythmLast(
      '${e.wakeTime.hour.toString().padLeft(2, '0')}:${e.wakeTime.minute.toString().padLeft(2, '0')}',
      int.parse(socialH),
      int.parse(workH),
    );
  }

  String? _stressLastValue(StressEventEntity? e, AppLocalizations l10n) {
    if (e == null) return null;
    return l10n.stressEventLast(e.intensity);
  }

  String? _treatmentLastValue(TreatmentEntryEntity? e, AppLocalizations l10n) {
    if (e == null) return null;
    return l10n.treatmentLast(e.treatmentType, e.description);
  }

  String? _weightLastValue(WeightEntryEntity? e, AppLocalizations l10n) {
    if (e == null) return null;
    final kg = e.weightKg.toStringAsFixed(1);
    if (e.bmi != null) {
      return l10n.weightLast(kg, e.bmi!.toStringAsFixed(1));
    }
    return l10n.weightWeight(kg);
  }

  /// period 短 label (走 l10n)
  String _periodShortLabel(String period, AppLocalizations l10n) {
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
