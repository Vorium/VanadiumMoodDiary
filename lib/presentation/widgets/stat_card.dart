// v0.27 round 67 (C-4 重构): StatCard 集中器
//
// 背景: 2 处 `_Stat` widget 同款 (Column 文字 + 数字, 都是 stats 展示):
//       - trend_summary.dart:43            value 在上 (headline w600), label 在下
//       - refill_manage_page.dart:355     label 在上 (caption w400), value 在下
//       视觉差异只是顺序不同, 抽到 StatCard 集中器统一成 "value 在上 / label 在下"
//       (跟 trend_summary 一致), refill_manage 4 个 caller 改为新顺序。
//
// emil "DRY for taste" 原则: 同款视觉 = 同一 widget, value 颜色可选 (warning
// 表示"在窗口" / error 表示"已过期")。

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// 统计卡 (大数字 + 小标签)
///
/// 用法:
/// ```dart
/// StatCard(
///   label: l10n.trendStatCurrentStreak,
///   value: '5',
///   // 可选: 强调色, 用于 "需要关注" 状态
///   valueColor: AppTokens.warningColor(context),
/// )
/// ```
///
/// 视觉: value 在上 (headline w600), label 在下 (caption secondary)
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  /// 标签 (通常是 "连续天数" / "已配置" 之类的小字)
  final String label;

  /// 数值 (大数字, headline 字号)
  final String value;

  /// 数值颜色, null = 默认 textPrimary
  /// 用于强调 (warning 表示"在窗口" / error 表示"已过期")
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTokens.textStyleHeadline(context).copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTokens.textPrimaryColor(context),
          ),
        ),
        const SizedBox(height: AppTokens.spacingXxs),
        Text(
          label,
          style: AppTokens.textStyleCaption(context).copyWith(
            color: AppTokens.textSecondaryColor(context),
          ),
        ),
      ],
    );
  }
}
