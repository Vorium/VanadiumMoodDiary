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
// - 默认高度 ~110pt (tileHeight, v0.32 R109 round 6 从 88 升到 110 — R112-06 注释漂移修)
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

import 'package:chroniccare_theme/chroniccare_theme.dart';
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

  /// 默认高度 (110pt — icon 28 + label caption 13 + value metricLg 28 + spacing; v0.32 R109 round 6 从 88 升到 110)
  static const double tileHeight = 110;

  /// 默认 tile 宽度 (跟 height 配套, ListView 横滚 / Wrap 自适应)
  ///
  /// v0.32 R109 round 6 part 2 修: R31 加 AppleHealthTile 时没指定 width,
  /// 在 ListView 横滚 + unbounded parent 时 Row 内部 Expanded 抛
  /// "non-zero flex but incoming width constraints are unbounded" 错
  /// (medication_page_round101 / helpers_round108 / daily_tracking 等 widget
  /// test 跨期 fail). 加 140pt 固定 width, ListView 横滚能自然布局.
  /// 配套 height 88 → 110 (放 icon 28 + label caption 13 + value metricLg 28 + spacing).
  static const double tileWidth = 140;

  /// R114 Wave B2 (B2-6, apple F-07): 固定 110×140 容器的 Dynamic Type
  /// 上限 — label 13pt + value 28pt 在 textScaler 1.6+ 即溢出 110pt 高
  /// (2.0 时 label 26 + value 56 + padding 32 = 114 > 110)。140pt 宽 tile
  /// 物理上限 clamp 1.3 (label/value ellipsis 兜底); 全动态支持 (布局弹性)
  /// 留 v1.0 随 tile 尺寸 token 化一并评估。
  static const double maxTextScaler = 1.3;

  @override
  Widget build(BuildContext context) {
    final metricColor = AppColors.healthMetricsColorFor(metricId);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgAlpha = isDark ? 0.18 : 0.12;
    final bgColor = metricColor.withValues(alpha: bgAlpha);

    return PressFeedback(
      onTap: onTap,
      // B2-6: tile 内容 clamp textScaler, 防固定高容器挤压
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: maxTextScaler,
        child: Container(
          height: tileHeight,
          width: tileWidth,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTokens.radiusTile),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spacingMd,
            vertical: AppTokens.spacingMd,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 左: metric icon (28pt, metric 色)
              Icon(
                _iconFor(metricId),
                color: metricColor,
                size: 28,
              ),
              const SizedBox(width: AppTokens.spacingSm),
              // 中: label + value — FittedBox 让长 label 缩字不溢出
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: AppTypography.textStyleMetricLg(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
