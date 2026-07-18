import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// v0.18 round 14 (P0-8): 按钮按下时给 scale 反馈 (emil 必备)
///
/// emil 原则: 按钮被按下时**视觉必须变化**(scale 或 ripple),让用户感觉
/// "被听见"。M3 `InkWell` 给了 ripple,但没有 scale 反馈。
///
/// 用法:
/// ```dart
/// PressFeedback(
///   onTap: () => doSomething(),
///   child: SomeButton(),
/// )
/// ```
///
/// 也可以包 `InkWell` 让 ripple + scale 都有:
/// ```dart
/// PressFeedback(
///   onTap: () => doSomething(),
///   child: InkWell(
///     onTap: null,  // 由 PressFeedback 处理
///     child: ...,
///   ),
/// )
/// ```
///
/// 设计选择:
/// - scale 0.97 (emil 标准，不是 0.9 / 0.95,大按钮也不变)
/// - duration 160ms (Material 3 ripple 同档)
///
/// **P0-7 fix**: 系统开了 prefers-reduced-motion → scale 反馈消失
/// (有 InkWell ripple 兜底)。
class PressFeedback extends StatefulWidget {
  final Widget child;
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

    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: scale,
        duration: effectiveDuration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
