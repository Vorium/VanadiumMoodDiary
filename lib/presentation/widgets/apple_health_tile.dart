// v0.31 round 7b (Apple Health redesign · Phase 2 Task 2.3): AppleHealthTile 新增
//
// Apple Health "favorites" 风格彩色 metric 模块。
//
// 设计 (spec §4.4):
// - 8 metric: medication / mood / vent / assessment / checkIn / trend / contact / sleep
// - 圆角 12 (radiusTile) 容器
// - 背景: metric 色 @ alpha 0.12 (light) / 0.18 (dark)
// - Row[左 icon 28pt metric 色, 中 Column[label caption 13/w500, 4 gap, value metricLg
//   28 ultralight], 右 chevron 16pt textHint]
// - PressFeedback 包整体 (scale 0.97)
// - 暗色模式: alpha 0.18, 文字色走 theme
// - 默认高度 ~88pt
//
// 用法:
// ```dart
// AppleHealthTile(
//   metricId: 'medication',
//   label: l10n.medsTotal,
//   value: '5',
//   onTap: () => context.push('/medication'),
// )
// ```
//
// 决策:
// - icon 映射 hard-coded switch (8 个 iOS system color metric 是固定枚举,
//   跟 AppColors.healthMetricsIds 1:1, 不放 dynamic lookup 是因为 icon 是设计 token
//   而非运行时常量, 集中在本文件便于设计 review)
// - 背景 alpha 跟 dark mode 调档 (light 0.12 / dark 0.18, 跟 iOS Health favorites
//   在 OLED 黑底下需要更强对比一致)
// Apple Health 风格 (spec §3.1.3 8 metric palette + §4.4 tile (12pt radius, 28pt icon, metricLg ultralight)) [R32 集中器注释, 防后续误改为 Material 3 风格]


import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/core/theme/app_typography.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// Apple Health "favorites" 风格彩色 metric 模块
///
/// API: [metricId] (8 选 1) / [label] / [value] / [onTap] (可选)。
/// 整体被 [PressFeedback] 包裹, 提供 scale 0.97 按下视觉。
class AppleHealthTile extends StatelessWidget {
  const AppleHealthTile({
    super.key,
    required this.metricId,
    required this.label,
    required this.value,
    this.onTap,
  });

  /// 8 metric 选 1 (跟 AppColors.healthMetricsIds 1:1)
  /// medication / mood / vent / assessment / checkIn / trend / contact / sleep
  final String metricId;

  /// metric 名 (e.g. "用药" / "心情")
  ///
  /// 走 caption 13/w500 + textSecondary
  final String label;

  /// 当前值 (e.g. "5" / "80%")
  ///
  /// 走 textStyleMetricLg (28 ultralight) + textPrimary
  final String value;

  /// 点击回调 (可选)
  final VoidCallback? onTap;

  /// 默认高度 (88pt — 16 padding * 2 + ~56 content)
  static const double tileHeight = 88;

  @override
  Widget build(BuildContext context) {
    final metricColor = AppColors.healthMetricsColorFor(metricId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgAlpha = isDark ? 0.18 : 0.12;
    final bgColor = metricColor.withValues(alpha: bgAlpha);

    return PressFeedback(
      onTap: onTap,
      child: Container(
        height: tileHeight,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTokens.radiusTile),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingMd,
          vertical: AppTokens.spacingMd,
        ),
        child: Row(
          children: [
            // 左: metric icon (28pt, metric 色)
            Icon(
              _iconFor(metricId),
              color: metricColor,
              size: 28,
            ),
            const SizedBox(width: AppTokens.spacingSm),
            // 中: label + value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTokens.textStyleCaption(context).copyWith(
                      color: AppTokens.textSecondaryColor(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTypography.textStyleMetricLg(context),
                  ),
                ],
              ),
            ),
            // 右: chevron (16pt, textHint)
            Icon(
              Icons.chevron_right,
              color: AppTokens.textHintColor(context),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// 8 metric → iOS-style icon 映射
  ///
  /// switch 而非 map 是为了 IDE 跳转 + exhaustive 检查 (新 metric 必须显式加 case)
  static IconData _iconFor(String metricId) {
    switch (metricId) {
      case 'medication':
        return Icons.medication;
      case 'mood':
        return Icons.mood;
      case 'vent':
        return Icons.mic;
      case 'assessment':
        return Icons.assignment;
      case 'checkIn':
        return Icons.check_circle;
      case 'trend':
        return Icons.show_chart;
      case 'contact':
        return Icons.contact_phone;
      case 'sleep':
        return Icons.bedtime;
      default:
        return Icons.help_outline; // 兜底: 未知 metricId 不崩
    }
  }
}
