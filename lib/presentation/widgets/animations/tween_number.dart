// v0.31 R32 (P1-13 superpowers-en): 抽公共 _TweenNumber widget
//
// 之前 2 个 private widget 95% 重复 (R31 P1-12 跨期 0 闭环):
// - check_in_button.dart:273 _StreakCounter (接受 int value, 用 l10n.homeStreak(n) 渲染)
// - stat_card.dart:132 _TweenNumber (接受 String value, 渲染 raw text)
//
// 重复: SingleTickerProviderStateMixin + AnimationController(durSlow) +
//        _tickListener setState + didChangeDependencies Motion.duration +
//        didUpdateWidget reset+forward + dispose removeListener+dispose
//        5 个方法 × 2 处 ~ 50 行重复.
//
// 抽公共 widget 接受泛型 T (int 或 String 解析), 渲染回调让 caller 自由格式化.

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_motion.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';

/// 公共 tween number widget (P1-13 superpowers-en)
/// 接受 int value + 渲染回调, 数字变化时自动 tween 平滑过渡.
class TweenNumber extends StatefulWidget {
  /// 目标数字 (int, 跨期 _StreakCounter 接受 int / _TweenNumber 接受 String 但 parseInt)
  final int value;

  /// 数字 tween 渲染回调 (接 current animated double, 返 Widget 渲染)
  final Widget Function(BuildContext context, int current) builder;

  /// 动画时长 (默认 AppTokens.durSlow)
  final Duration duration;

  /// 是否启用 reduce-motion 适配 (默认 true, 跟 Motion.duration 行为一致)
  final bool respectMotion;

  const TweenNumber({
    super.key,
    required this.value,
    required this.builder,
    this.duration = AppTokens.durSlow,
    this.respectMotion = true,
  });

  @override
  State<TweenNumber> createState() => _TweenNumberState();
}

class _TweenNumberState extends State<TweenNumber>
    with SingleTickerProviderStateMixin {
  late int _startValue;
  late int _targetValue;
  late AnimationController _controller;
  late double _currentAnimated;
  late final VoidCallback _tickListener;

  @override
  void initState() {
    super.initState();
    _targetValue = widget.value;
    _startValue = widget.value;
    _currentAnimated = widget.value.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _tickListener = () {
      if (!mounted) return;
      setState(() {
        _currentAnimated =
            _startValue + (_targetValue - _startValue) * _controller.value;
      });
    };
    _controller.addListener(_tickListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.respectMotion) {
      _controller.duration = Motion.duration(context, widget.duration);
    }
  }

  @override
  void didUpdateWidget(covariant TweenNumber old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    _startValue = _currentAnimated.round();
    _targetValue = widget.value;
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.removeListener(_tickListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _currentAnimated.round());
  }
}
