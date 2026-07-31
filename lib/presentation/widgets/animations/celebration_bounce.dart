import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// 庆祝动画 — 短暂弹跳 + 淡入淡出
///
/// v0.24 round 48 (emil P1-2): 抽到 `animations/` 作为第 4 个集中 widget
/// 之前 v0.22 round 30 自研 5 段 TweenSequence (40+ 行) 在
/// `presentation/pages/home/widgets/celebration_overlay.dart` 唯一使用,
/// 体系外"野生动效"。现在抽到 `animations/celebration_bounce.dart`,
/// 跟 FadeIn / SlideUp / PageTransitionSwitcher 并列,token 化保留。
///
/// emil 决策框架:
/// - 频度: rare (1-2 次/周 用户答卷后庆祝) → MotionScheme.delight
/// - 曲线: scale 0→1.2→1.0 用 curveBackOut (过冲); opacity 用 curveStandard
/// - 时长: durSlow (500ms, 短促, 不要拖泥带水)
class CelebrationBounce extends StatefulWidget {
  final String message;
  final VoidCallback? onCompleted;

  const CelebrationBounce({
    super.key,
    required this.message,
    this.onCompleted,
  });

  @override
  State<CelebrationBounce> createState() => _CelebrationBounceState();
}

class _CelebrationBounceState extends State<CelebrationBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    // v0.23 round 40 (emil F2 fix): 改用 MotionScheme.delight token 显式标档位
    // v0.23 round 40 (P1-12 fix): emil "rare/delight 频度上限 1000ms", 之前 1500ms 偏长
    _controller = AnimationController(
      vsync: this,
      duration: MotionScheme.delight.duration,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: AppTokens.curveBackOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: AppTokens.curveStandard)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
    ]).animate(_controller);
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: AppTokens.curveStandard)),
        weight: 25,
      ),
    ]).animate(_controller);
    _controller.forward();
    if (widget.onCompleted != null) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onCompleted?.call();
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // P0-7: 尊重系统 prefers-reduced-motion。开了就直接跳到终态
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spacingLg,
          vertical: AppTokens.spacingSm,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          // v0.27 round 59 (emil EMIL-T29): 修正走 theme-aware shadowOverlayOf,
          // 防 R49 同款 silent bug (黑色阴影在 dark mode = 透明)。
          boxShadow: AppTokens.shadowOverlayOf(context),
        ),
        child: Text(
          widget.message,
          style: TextStyle(
            color: AppTokens.fgOnPrimary(context),
            fontSize: AppTokens.fontSizeBody,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
