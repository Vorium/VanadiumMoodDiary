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
/// v0.23 round 41 (emil P3-32): 抽 widget, 跟 vent_list 右上角 "+" +
/// theme_toggle 体感一致
class PressFeedbackIconButton extends StatelessWidget {
  const PressFeedbackIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      child: IconButton(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
