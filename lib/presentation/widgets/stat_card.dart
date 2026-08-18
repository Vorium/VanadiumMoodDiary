// v0.31 round 7a (Apple Health redesign · Phase 2 Task 2.3):
// StatCard 重写为 Apple Health ultralight 大数字 + 4 variant。
//
// 历史:
// - v0.27 round 67 (C-4 重构): StatCard 集中器
//   改前: 2 处 _Stat widget 散落 (trend_summary / refill_manage_page)
//   改后: 抽 StatCard 集中器, value 在上 (headline w600) + label 在下 (caption secondary)
// - v0.31 R7a (本轮):
//   数字改 w200 ultralight (Apple Health 标志性) + height tight 1.1
//   4 variant: default / large / xl / inline
//   数字递增 tween (仿 _StreakCounter 模式, 抽 private `_TweenNumber` widget)
//   保留 API: label / value / valueColor — 现有 7 个 caller 0 改动
// - v0.31.1 R32 (P1-13 superpowers-en): 删原 _TweenNumber (95% 重复),
//   改用公共 TweenNumber widget (animations/tween_number.dart).
//   原 String "5天" / "1.2kg" 走 static 逻辑保留: build() 入口 int.tryParse,
//   解析成功走 TweenNumber (int tween), 解析失败走静态 Text (raw string).
//
// 设计原则 (emil DRY for taste):
// - 4 variant 通过 enum 区分, default = metricLg 28 ultralight
// - value 数字自动尝试 int → 触发 tween, 非数字走 static (避免 "1.2kg" 抖动)
// - StatCardVariant 加字段但 default = defaultVariant → 老 caller 自动走新视觉
// Apple Health 风格 (spec §3.2.2 ultralight w200 大数字 + §3.4.4 zero shadow + tintedMetricSoft) [R32 集中器注释, 防后续误改为 Material 3 风格]

import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/presentation/widgets/animations/tween_number.dart';

/// 4 种 StatCard 视觉变体
///
/// 字号映射 (Apple Health ultralight 风格):
/// - [defaultVariant] → 28 / w200 / tight 1.1 (textStyleMetricLg)
/// - [large]          → 34 / w200 / tight 1.1 (textStyleMetricXl) — 最大
/// - [xl]             → 28 / w200 + letterSpacing -0.5 (textStyleTitle 改 w200)
///                       视觉跟 default 字号相同但带 title 风格 letterSpacing
/// - [inline]         → 22 / w200 / tight 1.1 (textStyleMetricMd) — 最小
enum StatCardVariant { defaultVariant, large, xl, inline }

/// 统计卡 (大数字 + 小标签)
///
/// 用法:
/// ```dart
/// StatCard(
///   label: l10n.trendStatCurrentStreak,
///   value: '5',
///   variant: StatCardVariant.large,  // optional, default = defaultVariant
///   // 可选: 强调色, 用于 "需要关注" 状态
///   valueColor: AppTokens.warningColor(context),
/// )
/// ```
///
/// 视觉: value 在上 (ultralight w200), label 在下 (caption hint)
///
/// **tween 行为**: 当 [value] 是 int 字符串 ("5" / "12") 时,
/// 数字递增会触发 tween (仿 _StreakCounter 模式); 非数字字符串 ("5天" / "1.2kg")
/// 走 static 直接渲染, 避免小数 / 后缀抖动。
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.variant = StatCardVariant.defaultVariant,
  });

  /// 标签 (通常是 "连续天数" / "已配置" 之类的小字)
  final String label;

  /// 数值 (大数字, ultralight 字号)
  ///
  /// 自动 tween: 传入 int 字符串时 (e.g. "5" / "12") 数字递增会触发 tween;
  /// 非 int 字符串 (e.g. "5天" / "1.2kg") 走 static 不动。
  final String value;

  /// 数值颜色, null = 默认 textPrimary
  /// 用于强调 (warning 表示"在窗口" / error 表示"已过期")
  final Color? valueColor;

  /// 视觉变体 (4 种 Apple Health 字号)
  ///
  /// 默认 = [StatCardVariant.defaultVariant] (28 ultralight),
  /// 老 caller 不传 = 走新默认视觉 (改前 headline 24 w600 → 现 metricLg 28 w200)
  final StatCardVariant variant;

  @override
  Widget build(BuildContext context) {
    final baseStyle = _baseStyleFor(context);
    final color = valueColor ?? AppTokens.textPrimaryColor(context);
    // R114 Wave B2 (B2-6, apple F-09): 大数字加 tabularFigures — 修前
    // 数字变化时比例数字 (1 vs 8) 宽度不同 → 字符宽度跳动; Apple Health
    // 大数字 (SF 等宽数字特性) 不抖。全 lib 此前仅 2 处 audio 计时器有。
    final numberStyle = baseStyle.copyWith(
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // v0.31.1 R32 (P1-13 superpowers-en): 用公共 TweenNumber widget,
    // 原 _TweenNumber 95% 重复代码删. 非 int 字符串 ("5天" / "1.2kg") 走
    // 静态 Text 不 tween (避免小数 / 后缀抖动). 跨 widget swap 场景
    // (int ↔ non-int) 两边都走 static 渲染或重新 init, 视觉无丢失.
    final parsedInt = int.tryParse(value);
    final Widget numberWidget = parsedInt != null
        ? TweenNumber(
            value: parsedInt,
            builder: (ctx, current) => Text(
              current.toString(),
              style: numberStyle,
            ),
          )
        : Text(
            value,
            style: numberStyle,
          );
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          numberWidget,
          const SizedBox(height: AppTokens.spacingXxs),
          Text(
            label,
            style: AppTokens.textStyleCaption(context).copyWith(
              color: AppTokens.textHintColor(context),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// variant → base TextStyle (color 在外层覆盖)
  TextStyle _baseStyleFor(BuildContext context) {
    switch (variant) {
      case StatCardVariant.defaultVariant:
        return AppTypography.textStyleMetricLg(context);
      case StatCardVariant.large:
        return AppTypography.textStyleMetricXl(context);
      case StatCardVariant.xl:
        return AppTypography.textStyleTitle(context).copyWith(
          fontWeight: AppTypography.fontWeightUltralight,
        );
      case StatCardVariant.inline:
        return AppTypography.textStyleMetricMd(context);
    }
  }
}
