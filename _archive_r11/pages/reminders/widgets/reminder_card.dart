// v0.13 (Round 11) Reminder Card widget
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/logic/reminders_hub.dart';
import '../../../../theme/app_tokens.dart';

/// 单条 reminder 卡片
class ReminderCard extends ConsumerWidget {
  final ScheduledReminder reminder;
  const ReminderCard({super.key, required this.reminder});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final r = reminder;
    final (icon, color) = _kindVisuals(r.kind, theme);
    final enabledColor = r.isEnabled
        ? theme.colorScheme.onSurface
        : AppTokens.textHint;
    final fireLabel = _nextFireLabel(r.nextFireAt, r.isEnabled);
    final fireColor = r.isEnabled
        ? (r.kind == ReminderKind.refill
            ? AppTokens.warning
            : AppTokens.textSecondary)
        : AppTokens.textHint;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.title,
                        style: TextStyle(
                          fontSize: AppTokens.fontSizeBody,
                          fontWeight: FontWeight.w600,
                          color: enabledColor,
                          decoration: r.isEnabled
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                      if (r.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          r.description!,
                          style: TextStyle(
                            fontSize: AppTokens.fontSizeCaption,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // 启用 / 关闭 状态徽章
                if (!r.isEnabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.divider,
                      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                    ),
                    child: const Text(
                      '关闭',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTokens.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingSm),
            // 下次触发时间
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 14,
                  color: fireColor,
                ),
                const SizedBox(width: 4),
                Text(
                  fireLabel,
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: fireColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (r.actionLabel != null && r.actionRoute != null)
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.spacingSm,
                      ),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => context.push(r.actionRoute!),
                    child: Text(r.actionLabel!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 下次触发的可读标签
  String _nextFireLabel(DateTime? next, bool enabled) {
    if (next == null) {
      return '未调度';
    }
    if (!enabled) return '已关闭（不会响）';
    final now = DateTime.now();
    final diff = next.difference(now);
    if (diff.isNegative) {
      return '稍后（catch-up）';
    }
    if (diff.inMinutes < 60) {
      return '下次 ${diff.inMinutes} 分钟后';
    }
    if (diff.inHours < 24) {
      return '今天 ${next.hour.toString().padLeft(2, '0')}:'
          '${next.minute.toString().padLeft(2, '0')}（${diff.inHours} 小时后）';
    }
    if (diff.inDays == 1) {
      return '明天 ${next.hour.toString().padLeft(2, '0')}:'
          '${next.minute.toString().padLeft(2, '0')}';
    }
    return '${next.year}-${next.month.toString().padLeft(2, '0')}-'
        '${next.day.toString().padLeft(2, '0')} '
        '${next.hour.toString().padLeft(2, '0')}:'
        '${next.minute.toString().padLeft(2, '0')}';
  }

  (IconData, Color) _kindVisuals(ReminderKind kind, ThemeData theme) {
    switch (kind) {
      case ReminderKind.daily:
        return (Icons.alarm_on, theme.colorScheme.primary);
      case ReminderKind.medication:
        return (Icons.medication_outlined, theme.colorScheme.primary);
      case ReminderKind.soft:
        return (Icons.favorite_outline, AppTokens.warning);
      case ReminderKind.refill:
        return (Icons.event_available_outlined, AppTokens.warning);
      case ReminderKind.assessment:
        return (Icons.psychology_outlined, theme.colorScheme.tertiary);
    }
  }
}
