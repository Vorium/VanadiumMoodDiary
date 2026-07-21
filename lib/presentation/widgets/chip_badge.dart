// v0.22 round 34 (emil A2): 抽 [ChipBadge] 通用 widget
//
// 之前 6+ 处 `Container(padding, decoration: BoxDecoration(color: tintedXxx, borderRadius),
// child: Text(...))` 重复:
// - trend_calendar.dart (已打卡/未打卡 chip)
// - assessment_history_page.dart (评估分数 chip)
// - refill_manage_page.dart (续方状态 chip)
// - medications_list_widget.dart (用药状态 chip)
// - reminders_hub_page.dart (提醒类别 chip)
// - email_preview.dart (邮件标签)
//
// emil 原则 1 "cohesive experience" — padding/radius/字号 各写各的,违反 cohesion。
// 抽 1 个 widget 接 [ChipBadgeTone] enum,集中配色。
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// 小 chip 标签
///
/// 用法:
/// ```dart
/// ChipBadge(label: '已打卡', tone: ChipBadgeTone.success)
/// ```
class ChipBadge extends StatelessWidget {
  const ChipBadge({
    super.key,
    required this.label,
    this.tone = ChipBadgeTone.neutral,
    this.icon,
  });

  final String label;
  final ChipBadgeTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // v0.22 round 34: token 复用 — 暂用 tintedPrimarySoft 当 success / warning 兜底
    // (v0.22 round 39 集中清理时补 tintedSuccessSoft / tintedWarningSoft token)
    final (bg, fg) = switch (tone) {
      ChipBadgeTone.neutral => (
          AppTokens.tintedPrimarySoft(context),
          AppTokens.fgOnPrimary(context),
        ),
      ChipBadgeTone.success => (
          AppTokens.tintedPrimarySoft(context),
          AppTokens.fgOnPrimary(context),
        ),
      ChipBadgeTone.warning => (
          AppTokens.tintedPrimarySoft(context),
          AppTokens.fgOnPrimary(context),
        ),
      ChipBadgeTone.error => (
          AppTokens.tintedErrorSoft(context),
          AppTokens.fgOnError(context),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingSm,
        vertical: AppTokens.spacingXs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTokens.textStyleMicro(context).copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}

/// chip 调性 (背景色 + 前景色配对)
enum ChipBadgeTone { neutral, success, warning, error }
