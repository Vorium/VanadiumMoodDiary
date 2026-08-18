import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/scheduler.dart' show Ticker;

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart' show Spring;

/// 庆祝动画 — 短暂弹跳 + 淡入淡出
///
/// v0.24 round 48 (emil P1-2): 抽到 `animations/` 作为第 4 个集中 widget
/// 之前 v0.22 round 30 自研 5 段 TweenSequence (40+ 行) 在
/// `presentation/pages/home/widgets/celebration_overlay.dart` 唯一使用,
/// 体系外"野生动效"。现在抽到 `animations/celebration_bounce.dart`,
/// 跟 FadeIn / PageTransitionSwitcher 并列,token 化保留。
///
/// emil 决策框架:
/// - 频度: rare (1-2 次/周 用户答卷后庆祝) → MotionScheme.delight
/// - R114 Wave B2 (B2-9, emil F10/F11):
///   scale 用 Spring.bouncy.toSimulation(from: 0.5, to: 1.0) 替代
///   curveBackOut TweenSequence — 物理模型第 2 个真 caller (第 1 个 =
///   CheckInButton 的 Spring.standard), 欠阻尼 0.42 自然过冲 ~1.12
///   后收敛 1.0; from 0.5 = "可见的瘪气形状"再膨胀 (修前 0 = 从虚空迸出)
/// - 实现注: AnimationController.animateWith 会 clamp 值到 [0,1] (过冲被
///   削平), 所以 scale 用裸 Ticker 直接采样 SpringSimulation (不过冲的
///   弹簧就不是弹簧)。opacity 保留 TweenSequence 淡入淡出 (独立 controller)。
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
    with TickerProviderStateMixin {
  /// opacity 淡入淡出 (delight 时长, onCompleted 挂它)
  late final AnimationController _opacityController;

  late final Animation<double> _opacity;

  /// scale 弹簧模拟 + 裸 Ticker (AnimationController.animateWith 会 clamp
  /// 过冲到 1.0, 无法表达 bouncy 的 >1.0 形态)
  late final SpringSimulation _scaleSimulation;
  late final Ticker _scaleTicker;

  /// 当前 scale (ticker 驱动, isDone 后定格 1.0)
  double _scaleValue = 0.5;

  @override
  void initState() {
    super.initState();
    // v0.23 round 40 (emil F2 fix): 改用 MotionScheme.delight token 显式标档位
    // v0.23 round 40 (P1-12 fix): emil "rare/delight 频度上限 1000ms", 之前 1500ms 偏长
    _opacityController = AnimationController(
      vsync: this,
      duration: MotionScheme.delight.duration,
    );
    // R114 Wave B2 (B2-9, emil F10/F11): Spring.bouncy 物理过冲替代
    // curveBackOut TweenSequence; from 0.5 = 不从虚空迸出
    _scaleSimulation = Spring.bouncy.toSimulation(from: 0.5, to: 1.0);
    _scaleTicker = createTicker(_onScaleTick)..start();
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: AppTokens.curveStandard)),
        weight: 25,
      ),
    ]).animate(_opacityController);
    _opacityController.forward();
    if (widget.onCompleted != null) {
      _opacityController.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onCompleted?.call();
        }
      });
    }
  }

  /// 裸 Ticker 采样弹簧 (不 clamp — 保留过冲形态)
  void _onScaleTick(Duration elapsed) {
    if (!mounted) return;
    final t = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    if (_scaleSimulation.isDone(t)) {
      _scaleTicker.stop();
      setState(() => _scaleValue = 1.0);
    } else {
      setState(() => _scaleValue = _scaleSimulation.x(t));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // P0-7: 尊重系统 prefers-reduced-motion。开了就直接跳到终态
    if (MediaQuery.of(context).disableAnimations) {
      _scaleTicker.stop();
      _scaleValue = 1.0;
      if (_opacityController.value < 1.0) _opacityController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _opacityController.dispose();
    _scaleTicker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // v0.27 R71 (P5.4 性能): 加 RepaintBoundary
    // celebration 动画 1.8s 期间每秒 60 帧, 包 RepaintBoundary
    // 让父 widget 重建不重 paint 庆祝气泡
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _opacityController,
        builder: (ctx, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scaleValue,
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
      ),
    );
  }
}
