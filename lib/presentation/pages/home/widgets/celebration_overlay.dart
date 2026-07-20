import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// 打卡成功的短暂庆祝动画
class AnimatedCelebration extends StatefulWidget {
  final String message;
  const AnimatedCelebration({super.key, required this.message});

  @override
  State<AnimatedCelebration> createState() => _AnimatedCelebrationState();
}

class _AnimatedCelebrationState extends State<AnimatedCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // P1-7 fix: 改用 MotionScheme.delight token 显式标档位 (rare 庆祝频度)
    // P1-12 fix: emil "rare/delight 频度上限 1000ms",之前 1500ms 偏长
    _controller = AnimationController(
      vsync: this,
      duration: MotionScheme.delight.duration,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
      TweenSequenceItem(
        // P0-9 fix: easeIn 反 emil 原则("ease-in 延迟用户最关注的入场瞬间")。
        // 改 easeOutCubic 跟项目 AppTokens.curveStandard 一致，弹跳收尾感觉"快到慢",
        // 跟前面 0→1.2 的 easeOutBack 衔接顺。
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 50,
      ),
    ]).animate(_controller);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(_controller);
    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // P0-7: 尊重系统 prefers-reduced-motion。开了就直接跳到终态
    // (opacity 会瞬时变 1.0,但 celebration overlay 通常 1.5s 后就消失，用户感知不到)
    if (MediaQuery.of(context).disableAnimations && _controller.value < 1.0) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (ctx, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          // v0.21 (P1-10 fix): 改用 token (radiusButton = 24.0)
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppTokens.shadowCardDark.first.color
                  : AppTokens.shadowCard.first.color,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          widget.message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
