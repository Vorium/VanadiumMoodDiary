// v0.30 round 100: Apple Health 风格追踪项卡片
//
// 模块化设计: 每个追踪项 = 1 张统一风格的卡片
// - 左侧: 彩色圆形图标 + 名称 + 今日状态指示
// - 右侧: 上次记录摘要 + 记录按钮
// - 支持长按收藏/隐藏

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/tracking_item_config.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/tracking_item_config_ext.dart';

/// 追踪项卡片（模块化, Apple Health 风格）
class TrackingItemCard extends ConsumerWidget {
  final DailyTrackingItemConfig config;
  final String? lastValue;
  final VoidCallback? onRecord;
  final VoidCallback? onLongPress;

  const TrackingItemCard({
    super.key,
    required this.config,
    this.lastValue,
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
