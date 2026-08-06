import 'dart:async';

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// v0.17 round 14 (P1-1 抽 animations/ 子目录): 通用 slide-up 入场动画
///
/// 从下方 16px 处 fade + slide in,适合全屏深页 (setup wizard, vent compose)
/// 或底部弹层首次出现。
///
/// 决策:emil 框架 → occasional 频度 (用户一天 1-2 次进 setup/compose)。
///
/// 用法:
/// ```dart
/// SlideUp(
///   delay: AppMotion.durFast,
///   child: MyPage(),
/// )
/// ```
class SlideUp extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double distance;

  const SlideUp({
    super.key,
    required this.child,
    this.duration = AppTokens.durSlow,
    this.delay = Duration.zero,
    this.curve = AppTokens.curveDecelerate,
    this.distance = 16.0,
  });

  @override
  State<SlideUp> createState() => _SlideUpState();
}

class _SlideUpState extends State<SlideUp> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _t;
  late final Animation<Offset> _offset;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _t = CurvedAnimation(parent: _controller, curve: widget.curve);
    _offset = Tween<Offset>(
      begin: Offset(0, widget.distance),
      end: Offset.zero,
    ).animate(_t);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      // Timer 而非 Future.delayed:dispose 时可 cancel,test 时 fake clock
      // 推进会被触发 (tester.pumpAndSettle 等到所有 Timer 跑完)
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // P0-7: 尊重系统 prefers-reduced-motion
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
    return SlideTransition(
      position: _offset,
      child: FadeTransition(
        opacity: _t,
        child: widget.child,
      ),
    );
  }
}
