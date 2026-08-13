// v0.23 round 41 (emil P3-32): 抽 [PressFeedbackIconButton] widget
//
// 之前 vent_list + theme_toggle 各自 inline `PressFeedback(child: IconButton(...))`,
// emil "cohesion" — 同一 App 两套写法。
// 抽 1 个 widget,集中 active scale + haptic + 一致 tooltip / icon 调用方式。
import 'package:flutter/material.dart';

import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// IconButton with PressFeedback wrapper
///
/// 用法:
/// ```dart
/// PressFeedbackIconButton(
///   icon: Icons.add,
///   tooltip: '写新树洞',
///   onPressed: () => ...,
/// )
/// ```
///
/// 如果需要 `PressFeedback` 接管 tap（child.onPressed 置 null），传 `onTap`:
/// ```dart
/// PressFeedbackIconButton(
///   icon: Icons.show_chart,
///   tooltip: '趋势',
///   onTap: () => context.push('/trend'),
/// )
/// ```
///
/// 如果需要自定义 icon 颜色 / 尺寸，传 `color` / `size`:
/// ```dart
/// PressFeedbackIconButton(
///   icon: Icons.delete_outline,
///   tooltip: '删除',
///   color: AppTokens.errorColor(context),
///   onPressed: () => ...,
/// )
/// ```
///
/// v0.23 round 41 (emil P3-32): 抽 widget, 跟 vent_list 右上角 "+" +
/// theme_toggle 体感一致
/// v0.24 round 43 (emil P1-01 H-01): 加 onTap 参数, 让 home_header
/// 3 个 PressFeedback(onTap) 模式也能直接用集中器
/// v0.26 round 57 (emil B-11): 加 color / size / padding / constraints 参数,
/// 替换 17 处未用集中器的 IconButton (含 delete / close / refresh 等动作)
class PressFeedbackIconButton extends StatelessWidget {
  const PressFeedbackIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.onTap,
    this.color,
    this.size,
    this.padding,
    this.constraints,
  }) : assert(
          (onPressed == null) ^ (onTap == null),
          '必须传 onPressed 或 onTap 其中之一 (二选一)',
        );

  final IconData icon;
  final String tooltip;

  /// IconButton 标准 onPressed（如果不传, 默认用 onTap 模式）
  final VoidCallback? onPressed;

  /// PressFeedback 接管 tap 的回调（onPressed 置 null, PressFeedback.onTap 触发）
  final VoidCallback? onTap;

  /// v0.26 round 57 (emil B-11): 可选 icon 颜色
  /// 缺省走 IconButton 默认 (current colorScheme.onSurface)
  final Color? color;

  /// v0.26 round 57 (emil B-11): 可选 icon 尺寸
  /// 缺省走 IconButton 默认 (24.0 / iconSize)
  final double? size;

  /// v0.26 round 57 (emil B-11): 可选 IconButton 内边距
  /// 用于 banner 紧凑布局 (EdgeInsets.zero 等)
  final EdgeInsetsGeometry? padding;

  /// v0.26 round 57 (emil B-11): 可选 IconButton 尺寸约束
  /// 用于强制最小 tap 区域 (BoxConstraints 等)
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    final iconWidget = size != null || color != null
        ? Icon(icon, color: color, size: size)
        : Icon(icon);
    if (onTap != null) {
      return PressFeedback(
        onTap: onTap,
        enabled: true,
        child: IconButton(
          icon: iconWidget,
          tooltip: tooltip,
          onPressed: null,
          padding: padding,
          constraints: constraints,
        ),
      );
    }
    // v0.32 round 8 (R112-09 emil): 模式 2 传 enabled — 构造 assert
    // `(onPressed == null) ^ (onTap == null)` 在 release build 被 strip,
    // 双 null 理论可达: IconButton 灰禁用但 PressFeedback Listener 仍
    // scale + haptic 假反馈。显式 enabled 让禁用态走原样渲染。
    return PressFeedback(
      enabled: onPressed != null,
      child: IconButton(
        icon: iconWidget,
        tooltip: tooltip,
        onPressed: onPressed,
        padding: padding,
        constraints: constraints,
      ),
    );
  }
}
