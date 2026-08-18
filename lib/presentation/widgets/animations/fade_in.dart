import 'dart:async';

import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';

/// v0.17 round 14 (P1-1 抽 animations/ 子目录): 通用 fade-in 入场动画
///
/// 把"opacity 0 → 1 + 可选 scale 0.92 → 1" 抽成 1 个 widget,代替到处
/// 写 TweenAnimationBuilder + Opacity + Transform.scale 三层嵌套。
///
/// 决策:emil 框架把入场分两档：
///   - 微入场: 纯 opacity 0→1, occasional 频度 (空态、列表项首次进入)
///   - 弹入场: opacity 0→1 + scale 0.92→1, rare 频度 (delight,
///     比如成就解锁、第一次进树洞空态)
///
/// 用法:
/// ```dart
/// FadeIn(
///   delay: Duration(milliseconds: 100),  // 可选，跟 stagger 配合
///   withScale: true,                      // rare 才开
///   child: Text('Hello'),
/// )
/// ```
///
/// 频度参考 (emil 决策框架):
/// - 100+/day:  无动画
/// - tens/day:  FadeIn (微入场, opacity only, withScale: false)
/// - occasional: FadeIn with curveStandard
/// - rare:      FadeIn with withScale: true + curveDelight
class FadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final bool withScale;

  const FadeIn({
    super.key,
    required this.child,
    this.duration = AppTokens.durSlow,
    this.delay = Duration.zero,
    this.curve = AppTokens.curveStandard,
    this.withScale = false,
  });

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _t = CurvedAnimation(parent: _controller, curve: widget.curve);
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // P0-7: 尊重系统 prefers-reduced-motion。
    // 1) 首次 initState 后立即触发(系统开了就直接跳到 1.0)
    // 2) 系统设置切换时再触发
    if (MediaQuery.of(context).disableAnimations && _controller.value < 1.0) {
      _controller.value = 1.0;
      _delayTimer?.cancel();
      _delayTimer = null;
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) {
        return Opacity(
          opacity: _t.value,
          child: widget.withScale
              ? Transform.scale(
                  scale: 0.92 + (0.08 * _t.value),
                  child: child,
                )
              : child!,
        );
      },
      child: widget.child,
    );
  }
}
