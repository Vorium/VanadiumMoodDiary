// v0.22 round 34 (emil A5): 抽 [PageTransitionSwitcher] 通用 widget
//
// 之前 3+ 处 inline `AnimatedSwitcher` 散落:
// - setup_page.dart:96-129 (4 step onboarding 切换)
// - trend_page.dart list↔calendar 视图切换
// - assessment_page.dart quiz→result 切换
//
// emil "cohesion" — 切换应该统一 (默认 fade 100ms, 可配 curve / duration)。
// 抽 1 个 widget,默认 100ms + curveStandard, 调用方只传 key 跟 child。
//
// v0.23 round 40 (emil F7 fix): 加 transitionBuilder 参数,让 setup 4-step
// 等需要 vertical slide + fade 的场景也能用集中器,而不是 inline
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

/// 视图切换 (list/calendar, quiz/result, step1/step2...) 用 fade transition
///
/// 用法:
/// ```dart
/// PageTransitionSwitcher(
///   switchKey: currentView,  // 不同 key 触发 fade
///   child: currentView == 'list' ? listView : calendarView,
/// )
/// ```
///
/// v0.23 round 40 (emil F7 fix): 自定义 transitionBuilder 让 setup 4-step
/// 也能用集中器(默认 fade,可换 fade + slide)
class PageTransitionSwitcher extends StatelessWidget {
  const PageTransitionSwitcher({
    super.key,
    required this.switchKey,
    required this.child,
    this.duration = const Duration(milliseconds: 100),
    this.transitionBuilder,
  });

  /// 切换 trigger (一般是 enum / 状态值, child 的 Key)
  final Object switchKey;
  final Widget child;
  final Duration duration;
  /// 自定义 transition builder。默认 FadeTransition,setup 用 fade + slide
  final Widget Function(Widget child, Animation<double> animation)?
      transitionBuilder;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      // v0.22 round 34: 用 Motion.duration 走 reduce-motion
      switchInCurve: AppTokens.curveStandard,
      switchOutCurve: AppTokens.curveStandard,
      transitionBuilder: transitionBuilder ??
          (child, animation) =>
              FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(
        key: ValueKey(switchKey),
        child: child,
      ),
    );
  }
}
