import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// v0.18 round 14 (P0-8): 按钮按下时给 scale 反馈 (emil 必备)
///
/// emil 原则: 按钮被按下时**视觉必须变化**(scale 或 ripple),让用户感觉
/// "被听见"。M3 `InkWell` 给了 ripple,但没有 scale 反馈。
///
/// **v0.21 Round 22 (P0-9 修复)**: PressFeedback 改为只提供 scale 视觉
/// 反馈,**不**接管 child 的 onTap。
///
/// **两种用法**:
///
/// 1) **接管 tap** —— PressFeedback 自己处理 onTap:
/// ```dart
/// PressFeedback(
///   onTap: () => doSomething(),
///   child: SomeButton(),
/// )
/// ```
/// **注意**: 此时 child 不应有自己的 onTap (ListTile.onTap / InkWell.onTap),
/// 否则 tap 事件会被 PressFeedback 拦截,child 的 onTap 不会触发。
///
/// 2) **不接管 tap** —— onTap = null (默认),只做 scale 视觉,
///    child 的 onTap 正常工作 (ListTile / InkWell / 自带按钮):
/// ```dart
/// PressFeedback(
///   child: ListTile(
///     onTap: () => context.push('/foo'),
///     title: ...,
///   ),
/// )
/// ```
///
/// 设计选择:
/// - scale 0.97 (emil 标准,不是 0.9 / 0.95,大按钮也不变)
/// - duration 160ms (Material 3 ripple 同档)
///
/// **P0-7 fix**: 系统开了 prefers-reduced-motion → scale 反馈消失
/// (有 InkWell ripple 兜底)。
class PressFeedback extends StatefulWidget {
  final Widget child;

  /// **可选**: 如果传,PressFeedback 接管 tap 事件(此时 child.onTap 应为 null)
  /// 如果不传,PressFeedback 只提供 scale 视觉反馈,child.onTap 正常工作
  final VoidCallback? onTap;

  /// 按下时的 scale(默认 0.97 = emil 标准)
  final double pressedScale;

  /// 按下/抬起的动画时长
  final Duration duration;

  const PressFeedback({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.97,
    this.duration = const Duration(milliseconds: 160),
  });

  @override
  State<PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<PressFeedback> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // P0-7: 尊重系统 prefers-reduced-motion。
    final effectiveDuration = Motion.duration(context, widget.duration);
    final scale = _pressed ? widget.pressedScale : 1.0;

    final scaledChild = AnimatedScale(
      scale: scale,
      duration: effectiveDuration,
      // v0.22 round 29 (emil-13): 走 AppTokens.curveStandard token
      curve: AppTokens.curveStandard,
      child: widget.child,
    );

    // 模式 1: 接管 tap (旧 API) — onTap 非空
    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: scaledChild,
      );
    }

    // 模式 2: 不接管 tap — 只做 scale 视觉
    // 用 Listener 检测 pointer events 但不消费,事件继续传给 child
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: scaledChild,
    );
  }
}
