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
/// v0.30 R91 Task 7: title 走 l10n.dailyTrackingTitle (Task 7 一次性换 placeholder)。
class DailyTrackingPage extends ConsumerWidget {
  const DailyTrackingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      // TODO (Task 7 i18n): title 走 l10n.dailyTrackingTitle
      title: '日常追踪',
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
    // i 派发 7 子功能 (顺序固定, 跟 brief 1:1)
    switch (i) {
      case 0:
        return DailyTrackingCard(
          title: '情绪日记',
          route: '/mood-diary',
          lastValue: _moodLastValue(mood),
        );
      case 1:
        return DailyTrackingCard(
          title: '焦虑急躁',
          route: '/anxiety-agitation',
          lastValue: _anxietyLastValue(anxiety),
        );
      case 2:
        return DailyTrackingCard(
          title: '睡眠',
          route: '/sleep',
          lastValue: _sleepLastValue(sleep),
        );
      case 3:
        return DailyTrackingCard(
          title: '社会节律',
          route: '/social-rhythm',
          lastValue: _socialRhythmLastValue(socialRhythm),
        );
      case 4:
        return DailyTrackingCard(
          title: '应激源',
          route: '/stress-events',
          lastValue: _stressLastValue(stress),
        );
      case 5:
        return DailyTrackingCard(
          title: '治疗',
          route: '/treatment',
          lastValue: _treatmentLastValue(treatment),
        );
      case 6:
        return DailyTrackingCard(
          title: '体重',
          route: '/weight',
          lastValue: _weightLastValue(weight),
        );
    }
    return const SizedBox.shrink();
  }

  // ============== 7 子功能 lastValue format 辅助 ==============

  String? _moodLastValue(MoodEntryEntity? e) {
    if (e == null) return null;
    // period 短 label: 走 l10n.moodPeriodXxx (Task 2 已加)
    // period = null 当 unspecified
    final period = MoodPeriod.normalize(e.period);
    final periodLabel = _periodShortLabel(period);
    return '上次 ${e.score}/5${periodLabel.isNotEmpty ? ' ($periodLabel)' : ''}';
  }

  String? _anxietyLastValue(AnxietyAgitationEntryEntity? e) {
    if (e == null) return null;
    return '上次 焦虑 ${e.anxietyScore} / 急躁 ${e.agitationScore}';
  }

  String? _sleepLastValue(SleepEntryEntity? e) {
    if (e == null) return null;
    final reg = e.regularityScore != null ? ' · 规律 ${e.regularityScore}/5' : '';
    return '上次 ${e.durationLabel}$reg';
  }

  String? _socialRhythmLastValue(SocialRhythmEntryEntity? e) {
    if (e == null) return null;
    final socialH = (e.socialMin / 60).toStringAsFixed(0);
    final workH = (e.workMin / 60).toStringAsFixed(0);
    return '上次 社交 ${socialH}h · 工作 ${workH}h';
  }

  String? _stressLastValue(StressEventEntity? e) {
    if (e == null) return null;
    return '上次 强度 ${e.intensity}/5';
  }

  String? _treatmentLastValue(TreatmentEntryEntity? e) {
    if (e == null) return null;
    // R91 brief: 治疗类型 + 描述
    return '上次 ${e.treatmentType} · ${e.description}';
  }

  String? _weightLastValue(WeightEntryEntity? e) {
    if (e == null) return null;
    final bmi = e.bmi != null ? ' · BMI ${e.bmi!.toStringAsFixed(1)}' : '';
    return '上次 ${e.weightKg.toStringAsFixed(1)} kg$bmi';
  }

  /// period 短 label 兜底 (跟 mood_period_aggregator_chart.dart _periodShortLabel
  /// 1:1, 后续 Task 7 抽 l10n)
  String _periodShortLabel(String period) {
    // 暂用 const 中文 fallback (跟 chart 同款, 跨日由 AppRoot midnight timer
    // refresh 触发; Task 7 一次性 ARB 替换)
    switch (period) {
      case MoodPeriod.morning:
        return '早';
      case MoodPeriod.noon:
        return '中';
      case MoodPeriod.evening:
        return '晚';
      case MoodPeriod.night:
        return '夜';
    }
    return '';
  }
}
