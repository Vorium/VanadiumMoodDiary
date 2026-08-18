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

import 'package:chroniccare_theme/chroniccare_theme.dart';

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
    // v0.23 round 40 (emil F1 fix): 4 tone 配色独立
    // 之前 success / warning 跟 neutral 配色完全一样 = 抽类目标失败
    // (emil "good defaults" — 调用方写 success 视觉零区别 → 退化成 neutral)
    final (bg, fg) = switch (tone) {
      // v0.32 round 8 (R112 EM-09b regression fix): neutral fg 用 primary
      // 色而非 fgOnPrimary — tintedPrimarySoft 是浅底, 白字对比度 ~1.1:1
      // 不可读 (v0.31 私有 _ChipBadge 副本用的是 colorScheme.primary)
      ChipBadgeTone.neutral => (
          AppTokens.tintedPrimarySoft(context),
          AppTokens.primaryColor(context),
        ),
      ChipBadgeTone.success => (
          AppTokens.tintedSuccessSoft(context),
          AppTokens.fgOnSuccess,
        ),
      ChipBadgeTone.warning => (
          AppTokens.tintedWarningSoft(context),
          AppTokens.fgOnWarning,
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
            // v0.23 round 40 (emil F6/F12 fix): icon size 走 token
            Icon(icon, size: AppTokens.iconSizeMicro, color: fg),
            // v0.23 round 40 (emil F6 fix): chip icon-text gap 走 token
            const SizedBox(width: AppTokens.spacingChipGapInline),
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
