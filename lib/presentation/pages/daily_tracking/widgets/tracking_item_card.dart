// v0.30 round 100: Apple Health 风格追踪项卡片
//
// 模块化设计: 每个追踪项 = 1 张统一风格的卡片
// - 左侧: 彩色圆形图标 + 名称 + 今日状态指示
// - 右侧: 上次记录摘要 + 记录按钮
// - 支持长按收藏/隐藏
//
// v0.32 R110 round 7a (FS-2): 卡片自行 watch 自己的 latest 流 —
// 删掉页面传 lastValue 的耦合, 任一 entry 写新值只重建本卡片。

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/tracking_item_config_ext.dart';
import 'package:chroniccare/presentation/providers/cbt_rerated_entries_provider.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';

/// 追踪项卡片（模块化, Apple Health 风格）
class TrackingItemCard extends ConsumerWidget {
  final DailyTrackingItemConfig config;
  final VoidCallback? onRecord;
  final VoidCallback? onLongPress;

  const TrackingItemCard({
    super.key,
    required this.config,
    this.onRecord,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // 获取本地化名称
    final name = _getLocalizedName(l10n, config.nameKey);
    final desc = _getLocalizedDesc(l10n, config.descKey);
    final lastValue = _lastValueFor(ref, config.id, l10n);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          side: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
        child: InkWell(
          onTap: onRecord,
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spacingSm),
            child: Row(
              children: [
                // 左侧: 图标 + 名称
                _buildIcon(context),
                const SizedBox(width: AppTokens.spacingSm),
                // 中间: 名称 + 状态
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (lastValue != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          lastValue!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color
                                ?.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTokens.textHintColor(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // 右侧: 记录按钮
                _buildRecordButton(context, l10n),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      ),
      child: Icon(
        config.icon,
        color: config.color,
        size: 22,
      ),
    );
  }

  Widget _buildRecordButton(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      height: 32,
      child: FilledButton(
        onPressed: onRecord,
        style: FilledButton.styleFrom(
          backgroundColor: config.color.withValues(alpha: 0.12),
          foregroundColor: config.color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacingSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
          ),
        ),
        child: Text(
          l10n.dailyTrackingRecord,
          style: const TextStyle(
            fontSize: AppTokens.fontSizeCaption,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getLocalizedName(AppLocalizations l10n, String key) {
    switch (key) {
      case 'moodDiaryName':
        return l10n.moodDiaryName;
      case 'anxietyAgitationName':
        return l10n.anxietyAgitationName;
      case 'sleepName':
        return l10n.sleepName;
      case 'weightName':
        return l10n.weightName;
      case 'socialRhythmName':
        return l10n.socialRhythmName;
      case 'stressEventName':
        return l10n.stressEventName;
      case 'treatmentName':
        return l10n.treatmentName;
      default:
        return key;
    }
  }

  String _getLocalizedDesc(AppLocalizations l10n, String key) {
    switch (key) {
      case 'moodDiaryShortDesc':
        return l10n.moodDiaryShortDesc;
      case 'anxietyAgitationShortDesc':
        return l10n.anxietyAgitationShortDesc;
      case 'sleepShortDesc':
        return l10n.sleepShortDesc;
      case 'weightShortDesc':
        return l10n.weightShortDesc;
      case 'socialRhythmShortDesc':
        return l10n.socialRhythmShortDesc;
      case 'stressEventShortDesc':
        return l10n.stressEventShortDesc;
      case 'treatmentShortDesc':
        return l10n.treatmentShortDesc;
      default:
        return '';
    }
  }

  // ============== 自 watch 自己的 latest 流 (FS-2) ==============

  /// 按 config.id 只 watch 对应的单个 latest provider
  static String? _lastValueFor(
    WidgetRef ref,
    String id,
    AppLocalizations l10n,
  ) {
    switch (id) {
      case 'mood':
        return _moodLastValue(ref.watch(latestMoodEntryProvider), l10n);
      case 'anxiety':
        return _anxietyLastValue(
          ref.watch(latestAnxietyAgitationEntryProvider),
          l10n,
        );
      case 'sleep':
        return _sleepLastValue(ref.watch(latestSleepEntryProvider), l10n);
      case 'social_rhythm':
        return _socialRhythmLastValue(
          ref.watch(latestSocialRhythmEntryProvider),
          l10n,
        );
      case 'stress':
        return _stressLastValue(ref.watch(latestStressEventEntryProvider), l10n);
      case 'treatment':
        return _treatmentLastValue(
          ref.watch(latestTreatmentEntryProvider),
          l10n,
        );
      case 'weight':
        return _weightLastValue(ref.watch(latestWeightEntryProvider), l10n);
    }
    return null;
  }

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

/// 分类标题
class TrackingCategoryHeader extends StatelessWidget {
  final TrackingCategory category;

  const TrackingCategoryHeader({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final label = _getCategoryLabel(l10n, category);

    return Padding(
      padding: const EdgeInsets.only(
        top: AppTokens.spacingMd,
        bottom: AppTokens.spacingXs,
        left: AppTokens.spacingXxs,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: AppTokens.textHintColor(context),
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getCategoryLabel(AppLocalizations l10n, TrackingCategory cat) {
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
}
