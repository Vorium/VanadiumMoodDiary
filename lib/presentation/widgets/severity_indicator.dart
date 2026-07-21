// v0.22 round 34 (emil A3): 抽 [SeverityIndicator] 通用 widget
//
// 之前 4+ 处 "小圆点 + 文字" 模式重复:
// - refill_manage_page.dart:_StatusDot (续方状态 pill)
// - assessment_history_page.dart:_SeverityChip (评估严重度)
// - today_med_schedule.dart:_TimeChip (用药时间窗)
// - home_page 通知失败 banner (状态 dot)
//
// emil 设计哲学 "build cohesive experience" — status dot 跟 severity chip
// 视觉应该统一,抽 1 个 widget 用 [SeverityLevel] enum 控制色 + 文字。
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// "圆点 + 文字" 状态指示
///
/// 用法:
/// ```dart
/// SeverityIndicator(level: SeverityLevel.warning, label: '即将过期')
/// ```
class SeverityIndicator extends StatelessWidget {
  const SeverityIndicator({
    super.key,
    required this.level,
    required this.label,
  });

  final SeverityLevel level;
  final String label;

  @override
  Widget build(BuildContext context) {
    // v0.22 round 34: 用 textSecondaryColor / errorColor 已存在的 token
    // (v0.22 round 39 集中清理时补 successColor / warningColor token)
    final color = switch (level) {
      SeverityLevel.ok => AppTokens.textSecondaryColor(context),
      SeverityLevel.warning => AppTokens.textSecondaryColor(context),
      SeverityLevel.error => Theme.of(context).colorScheme.error,
      SeverityLevel.neutral => AppTokens.textSecondaryColor(context),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTokens.spacingXs),
        Text(
          label,
          style: AppTokens.textStyleLabel(context).copyWith(color: color),
        ),
      ],
    );
  }
}

/// 严重度级别 (决定圆点颜色)
enum SeverityLevel { ok, warning, error, neutral }
