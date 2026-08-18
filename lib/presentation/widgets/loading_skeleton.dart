import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';

/// 通用 loading 占位（v0.17 round 13 P0-4）

import 'dart:async';

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
            CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppTokens.primaryColor(context),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppTokens.spacingMd),
              Text(
                message!,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeBody,
                  color: AppTokens.textSecondaryColor(context),
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
          color ?? AppTokens.primaryColor(context),
        ),
      ),
    );
  }
}

/// 全屏遮罩 + 中央 Card(spinner + 文字) 集中器
/// 用于 long task modal (PDF 生成 / 数据导出 / 同步等 5s+ 任务)
///
/// v0.27 R70 (emil B-2 / R68 spec 报告 P0-10 重构):
/// - 抽 scrim + 中心 Card(spinner + 文字) 重复模式为集中器
/// - 自动包 AbsorbPointer 锁死底层 (R69 P0-2 修复的回归防御)
/// - scrim 0.54 (M3 Modal barrier 0.32 太浅, long task modal 需更深)
///
/// **使用模式**: 必须放在 Stack 内, 跟现有 Positioned.fill 模式一致
/// ```dart
/// Stack(
///   children: [
///     // ... 主内容
///     LoadingScrim(isLoading: _pdfLoading, message: 'PDF 生成中...'),
///   ],
/// )
/// ```
class LoadingScrim extends StatelessWidget {
  final bool isLoading;
  final String message;
  final double spinnerSize;

  const LoadingScrim({
    super.key,
    required this.isLoading,
    required this.message,
    this.spinnerSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();
    return Positioned.fill(
      child: AbsorbPointer(
        child: ColoredBox(
          color: Theme.of(context)
              .colorScheme
              .scrim
              .withValues(alpha: AppTokens.scrimAlpha),
          child: Center(
            child: Card(
              child: Padding(
                padding: AppTokens.edgeInsetsMd,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: spinnerSize,
                      height: spinnerSize,
                      child: LoadingSpinner(size: spinnerSize),
                    ),
                    const SizedBox(width: AppTokens.spacingSm),
                    Text(message),
                  ],
                ),
              ),
            ),
          ),
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
  bool _isBreathing = false;
  // v0.27 round 59 (emil EMIL-T21): 存 timer 字段, dispose 可 cancel,
  // 修正之前 Future.delayed 不可 cancel 导致的 race condition。
  Timer? _pauseTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppTokens.shimmerCycleMs),
    );
    // v0.24 round 48 (emil P1-6): 单次动画完成 → 暂停 600ms → 重播
    // 实现"呼吸"模式, 代替之前 repeat(reverse: true) 永久脉动
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isBreathing) {
        // v0.26 round 57 (emil C-10): 走 shimmerPauseMs 集中器
        // 替代 inline Duration(milliseconds: 600) magic
        // v0.27 round 59: 改 Timer (可 cancel) 替代 Future.delayed
        // dispose 取消 timer, 修正"dispose race → _controller 已 dispose
        // 但 callback 仍 fire → flutter assertion" 风险
        _pauseTimer?.cancel();
        _pauseTimer = Timer(
          const Duration(milliseconds: AppTokens.shimmerPauseMs),
          () {
            if (mounted && _isBreathing) {
              _controller.value = 0.0;
              _controller.forward();
            }
          },
        );
      }
    });
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
      _isBreathing = false;
    } else if (!_isBreathing) {
      // v0.24 round 48 (emil P1-6): "呼吸" 模式
      // 之前 _controller.repeat(reverse: true) 永久 0.4-0.7 脉动,精神心理 App 高刺激度
      // emil "loading should feel fast, not dance" 哲学
      // 现在: 单次 0.4→0.7 (1.2s) + 暂停 600ms + 重播 → 体感 "呼吸" 而非 "脉动"
      _isBreathing = true;
      _controller.value = 0.0;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _isBreathing = false; // 阻止 status listener 重启动画
    // v0.27 round 59 (emil EMIL-T21): cancel timer 防 race
    _pauseTimer?.cancel();
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
