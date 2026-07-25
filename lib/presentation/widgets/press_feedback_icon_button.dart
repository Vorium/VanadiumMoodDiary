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
/// v0.23 round 41 (emil P3-32): 抽 widget, 跟 vent_list 右上角 "+" +
/// theme_toggle 体感一致
/// v0.24 round 43 (emil P1-01 H-01): 加 onTap 参数, 让 home_header
/// 3 个 PressFeedback(onTap) 模式也能直接用集中器
class PressFeedbackIconButton extends StatelessWidget {
  const PressFeedbackIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onPressed,
    this.onTap,
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

  @override
  Widget build(BuildContext context) {
    if (onTap != null) {
      return PressFeedback(
        onTap: onTap,
        child: IconButton(
          icon: Icon(icon),
          tooltip: tooltip,
          onPressed: null,
        ),
      );
    }
    return PressFeedback(
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
