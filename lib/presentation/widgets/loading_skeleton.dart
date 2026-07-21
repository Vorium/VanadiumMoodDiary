import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// 通用 loading 占位（v0.17 round 13 P0-4）
///
/// 情感患者 App：spinner 太"机械"易引发焦虑。用柔和的骨架屏
/// 让用户知道"在加载"但不刺眼。
///
/// 三种用法:
///
/// 1. 全屏 loading（页面级别）
/// ```dart
/// LoadingSkeleton.fullScreen(message: '正在加载...')
/// ```
///
/// 2. 卡片 loading（区块级别）
/// ```dart
/// LoadingSkeleton.card(child: SomeWidget())
/// ```
///
/// 3. 简单 spinner（按钮内/小区域）
/// ```dart
/// LoadingSpinner()  // 包装过的 CircularProgressIndicator, 统一 strokeWidth
/// ```
class LoadingSkeleton extends StatelessWidget {
  /// 全屏 loading（page level）
  final bool isFullScreen;
  final String? message;
  final Widget? child;

  const LoadingSkeleton({
    super.key,
    this.isFullScreen = false,
    this.message,
    this.child,
  }) : assert(
          isFullScreen || child != null,
          'Either isFullScreen=true or child must be provided',
        );

  /// 全屏 loading 工厂
  const LoadingSkeleton.fullScreen({super.key, this.message})
      : isFullScreen = true,
        child = null;

  /// 卡片骨架屏工厂
  const LoadingSkeleton.card({super.key, required this.child})
      : isFullScreen = false,
        message = null;

  @override
  Widget build(BuildContext context) {
    if (isFullScreen) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppTokens.primary),
            ),
            if (message != null) ...[
              const SizedBox(height: AppTokens.spacingMd),
              Text(
                message!,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeBody,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      );
    }
    // 卡片骨架：subtle shimmer placeholder
    return _Shimmer(child: child!);
  }
}

/// 简单 spinner 包装（统一 strokeWidth 和颜色）
class LoadingSpinner extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingSpinner({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppTokens.primary,
        ),
      ),
    );
  }
}

/// 简单 shimmer 动画的占位（用 AnimatedOpacity 模拟，无外部依赖）
class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    // v0.22 round 30 (emil P1-5): 不在 initState 启动 controller
    // 因为 initState 不能读 MediaQuery (context 还没绑)
    // → 之前 _maybeShimmer() 总是 _controller.repeat(reduce-motion 也启动)
    // 然后 didChangeDependencies 才停 → **首次 build 仍短暂动画**
    // 精神心理患者前庭敏感比例高,1.2s 永久循环 shimmer 不可接受
    // 现在留给 didChangeDependencies 同步根据 MediaQuery 决定
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 监听系统 reduce-motion 变化 + 首次 build 同步
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      if (_controller.isAnimating) _controller.stop();
      _controller.value = 1.0; // 跳到终态(满 opacity)
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
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
      builder: (context, child) {
        return Opacity(
          opacity: 0.4 + (_controller.value * 0.3),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
