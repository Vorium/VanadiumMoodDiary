// trend_event_row.dart — 趋势页日历 day-detail 单条事件行
//
// v0.30 round 95 (sub-spec 4 task 6): 从 trend_calendar.dart 抽出
//
// 职责: 显示 DayEvent (checkIn normal/temp / assessment / mood) 一行
// (时间 + icon + 标题 + subtitle), 跟 _kindVisuals 集中器逻辑
// (icon / color / time prefix) 一起。
//
// 跟原 _EventRow 1:1 行为不变, 仅移到独立文件 + 改名 public
// (`EventRow` for testability) — 原 R84 _EventRow 私有是测试无法 import 的
// 历史遗留, 现在拆出来后 import 测更顺。
import 'package:flutter/material.dart';

import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/domain/logic/day_detail.dart';

/// 单条事件行 (public, v0.30 round 95 拆出, 原 _EventRow 私有)
class EventRow extends StatelessWidget {
  final DayEvent event;
  const EventRow({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final (icon, color, timePrefix) = kindVisuals(event, context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            // v0.26 round 57 (emil C-10): 走 eventTimeColWidth 集中器
            // 替代 inline width: 36 magic (timeline event 时间列宽)
            width: AppTokens.eventTimeColWidth,
            child: Text(
              timePrefix,
              // v0.26 round 57 (emil B-10): 走 textStyleCaption 集中器
              // 替代内联 TextStyle(fontSizeCaption, w500, textHintColor)
              style: AppTokens.textStyleCaption(context).copyWith(
                fontWeight: FontWeight.w500,
                color: AppTokens.textHintColor(context),
              ),
            ),
          ),
          Icon(icon, size: AppTokens.iconSizeInline, color: color),
          const SizedBox(width: AppTokens.spacingXs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (event.subtitle != null && event.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: AppTokens.spacingXxxs),
                  Text(
                    event.subtitle!,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textSecondaryColor(context),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// v0.30 round 95 (sub-spec 4 task 6): 集中器 (icon / color / time prefix)
  /// 走 public 顶级 function, 便于 test 直接覆盖。
  /// 原 _EventRow._kindVisuals (private) 拆出。
  static (IconData, Color, String) kindVisuals(
    DayEvent e,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final time = '${e.time.hour.toString().padLeft(2, '0')}:'
        '${e.time.minute.toString().padLeft(2, '0')}';
    switch (e.kind) {
      case DayEventKind.checkInNormal:
        return (Icons.check_circle, AppTokens.primaryColor(context), time);
      case DayEventKind.checkInTemp:
        return (Icons.healing_outlined, AppTokens.warningColor(context), time);
      case DayEventKind.assessment:
        return (Icons.psychology_outlined, theme.colorScheme.tertiary, time);
      case DayEventKind.mood:
        return (
          Icons.mood_outlined,
          e.moodScore != null
              ? AppColors.moodScoreColor(e.moodScore!)
              : AppTokens.textSecondaryColor(context),
          time,
        );
    }
  }
}
