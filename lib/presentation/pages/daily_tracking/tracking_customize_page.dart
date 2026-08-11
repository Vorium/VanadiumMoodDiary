// v0.30 round 100: 追踪项自定义页
//
// Apple Health 风格: ReorderableListView 拖拽排序
// 每项: 开关(隐藏/显示) + 收藏图标 + 拖拽手柄

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/tracking_item_config.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/tracking_item_config_ext.dart';
import 'package:chroniccare/presentation/providers/tracking_config_provider.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

/// 追踪项自定义页 (排序/隐藏/收藏)
class TrackingCustomizePage extends ConsumerWidget {
  const TrackingCustomizePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final configState = ref.watch(trackingConfigProvider);
    final items = configState.allItems;
    final theme = Theme.of(context);

    return PageScaffold(
      title: l10n.trackingCustomize,
      child: ReorderableListView.builder(
        padding: AppTokens.edgeInsetsMd,
        itemCount: items.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex--;
          // 更新所有项的 sortOrder
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            int newOrder;
            if (i == oldIndex) {
              newOrder = newIndex;
            } else if (oldIndex < newIndex &&
                i > oldIndex &&
                i <= newIndex) {
              newOrder = i - 1;
            } else if (oldIndex > newIndex &&
                i >= newIndex &&
                i < oldIndex) {
              newOrder = i + 1;
            } else {
              newOrder = i;
            }
            if (item.sortOrder != newOrder) {
              ref
                  .read(trackingConfigProvider.notifier)
                  .reorder(item.id, newOrder);
            }
          }
        },
        itemBuilder: (context, i) {
          final item = items[i];
          return _TrackingItemTile(
            key: ValueKey(item.id),
            config: item,
            theme: theme,
            l10n: l10n,
            onToggleHide: () {
              ref.read(trackingConfigProvider.notifier).toggleHide(item.id);
            },
            onTogglePin: () {
              ref.read(trackingConfigProvider.notifier).togglePin(item.id);
            },
          );
        },
      ),
    );
  }
}

class _TrackingItemTile extends StatelessWidget {
  final DailyTrackingItemConfig config;
  final ThemeData theme;
  final AppLocalizations l10n;
  final VoidCallback onToggleHide;
  final VoidCallback onTogglePin;

  const _TrackingItemTile({
    super.key,
    required this.config,
    required this.theme,
    required this.l10n,
    required this.onToggleHide,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final name = _getLocalizedName(l10n, config.nameKey);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppTokens.spacingXs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: config.isHidden
                ? theme.dividerColor.withValues(alpha: 0.3)
                : config.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
          ),
          child: Icon(
            config.icon,
            color: config.isHidden
                ? AppTokens.textHintColor(context)
                : config.color,
            size: 22,
          ),
        ),
        title: Text(
          name,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: config.isHidden
                ? AppTokens.textHintColor(context)
                : null,
          ),
        ),
        subtitle: Text(
          _getCategoryLabel(l10n, config.category),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTokens.textHintColor(context),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 收藏按钮
            // v0.31.1 round 8 (emil P0-C + R108 P1-001 漏修): 改用
            // PressFeedbackIconButton 集中器。color / size 提到顶层参数
            // (集中器 build 内部会构 Icon)。
            PressFeedbackIconButton(
              icon: config.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: config.isPinned
                  ? AppTokens.primaryColor(context)
                  : AppTokens.textHintColor(context),
              size: 20,
              tooltip: config.isPinned ? l10n.trackingUnpin : l10n.trackingPin,
              onPressed: onTogglePin,
            ),
            // 隐藏开关
            Switch(
              value: !config.isHidden,
              onChanged: (_) => onToggleHide(),
              activeThumbColor: AppTokens.primaryColor(context),
            ),
            // 拖拽手柄
            ReorderableDragStartListener(
              index: config.sortOrder,
              child: Icon(
                Icons.drag_handle,
                color: AppTokens.textHintColor(context),
              ),
            ),
          ],
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
