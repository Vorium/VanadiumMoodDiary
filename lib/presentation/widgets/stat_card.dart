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
//
// 设计原则 (emil DRY for taste):
// - 4 variant 通过 enum 区分, default = metricLg 28 ultralight
// - value 数字自动尝试 int → 触发 tween, 非数字走 static (避免 "1.2kg" 抖动)
// - StatCardVariant 加字段但 default = defaultVariant → 老 caller 自动走新视觉
// Apple Health 风格 (spec §3.2.2 ultralight w200 大数字 + §3.4.4 zero shadow + tintedMetricSoft) [R32 集中器注释, 防后续误改为 Material 3 风格]


import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/core/theme/app_typography.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _TweenNumber(
          value: value,
          baseStyle: _baseStyleFor(context),
          color: valueColor ?? AppTokens.textPrimaryColor(context),
        ),
        const SizedBox(height: AppTokens.spacingXxs),
        Text(
          label,
          style: AppTokens.textStyleCaption(context).copyWith(
            color: AppTokens.textHintColor(context),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// variant → base TextStyle (color 在 _TweenNumber 外面覆盖)
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

// ===== 内部: 数字递增 tween =====
//
// 仿 _StreakCounter (check_in_button.dart) 模式:
// - 当 value 是 int 字符串 ("5" / "12") → AnimationController tween 数字递增
// - 当 value 是非 int 字符串 ("5天" / "1.2kg" / "0.0") → 走 static 不动
//
// 设计选择 (emil 必备):
// - duration = durSlow (跟 _StreakCounter 一致, 500ms 视觉舒适)
// - reduce-motion → duration 0 (走 Motion.duration)
// - 整数 round 渲染 (跟 _StreakCounter 一致, 避免 "4.7" 半数字)
class _TweenNumber extends StatefulWidget {
  const _TweenNumber({
    required this.value,
    required this.baseStyle,
    required this.color,
  });

  final String value;
  final TextStyle baseStyle;
  final Color color;

  @override
  State<_TweenNumber> createState() => _TweenNumberState();
}

class _TweenNumberState extends State<_TweenNumber>
    with SingleTickerProviderStateMixin {
  late int _targetInt;
  late int _startInt;
  late AnimationController _controller;
  late double _currentAnimated;
  late final VoidCallback _tickListener;

  /// 解析 value 字符串为 int, 非整数 (含小数 / 后缀 / 空) 返 null
  static int? _tryParseInt(String s) {
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }

  @override
  void initState() {
    super.initState();
    final initial = _tryParseInt(widget.value) ?? 0;
    _targetInt = initial;
    _startInt = initial;
    _currentAnimated = initial.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: AppTokens.durSlow,
    );
    _tickListener = () {
      if (!mounted) return;
      setState(() {
        _currentAnimated =
            _startInt + (_targetInt - _startInt) * _controller.value;
      });
    };
    _controller.addListener(_tickListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = Motion.duration(context, AppTokens.durSlow);
  }

  @override
  void didUpdateWidget(covariant _TweenNumber old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    final newTarget = _tryParseInt(widget.value);
    final oldTarget = _tryParseInt(old.value);
    // 两者都能解析为 int 且数字变化 → tween; 否则 → 直接跳
    if (newTarget != null && oldTarget != null && newTarget != oldTarget) {
      _startInt = _currentAnimated.round();
      _targetInt = newTarget;
      _controller
        ..reset()
        ..forward();
    } else {
      // 非 int 字符串 / 空 → 走 static (直接渲染, 不动)
      if (mounted) {
        setState(() {
          _targetInt = newTarget ?? 0;
          _startInt = _targetInt;
          _currentAnimated = _targetInt.toDouble();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_tickListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _tryParseInt(widget.value);
    final display =
        parsed != null ? _currentAnimated.round().toString() : widget.value;
    return Text(
      display,
      style: widget.baseStyle.copyWith(color: widget.color),
    );
  }
}
