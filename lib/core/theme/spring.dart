// v0.31 round 4 (Apple Health redesign · Phase 1 Task 1.4): Spring 物理模型
//
// spec §3.4.3: 模仿 iOS spring 行为
// - mass: 质量 (惯量, iOS 默认 1)
// - stiffness: 弹簧刚度 (越大收敛越快)
// - damping: 阻尼 (越小越弹, 过大 = 过阻尼, 0 = 无阻尼振荡)
// 3 个静态实例:
//   · standard (mass 1, stiffness 200, damping 20) — 临界阻尼 0.4s
//   · gentle   (mass 1, stiffness 150, damping 18) — 0.5s
//   · bouncy   (mass 1, stiffness 200, damping 12) — 0.5s 轻弹
//
// 提供 SpringSimulation wrapper (走 flutter 内置 `package:flutter/physics.dart`)。
// 适用: AnimationController.animateWith(spring.toSimulation(from: 0, to: 1))
//
// Apple Health 全程用 spring 表达"物理" (PushTransition / scale 反馈 /
// celebration overlay / tile hover)。spec §3.4 step 11: 现有 MotionScheme 保留,
// spring 走双轨制 — 按场景选 (push 用 spring, fade 用 MotionScheme.standard)。
import 'package:flutter/material.dart' show BuildContext;
import 'package:flutter/physics.dart' show SpringDescription, SpringSimulation;

/// v0.31 R4 (Apple Health redesign · Task 1.4): Spring 类型枚举
///
/// Apple Health 通用 spring 档位 (apple-design §5, spec §3.4.3):
/// - [standard]: 临界阻尼 0.4s — 通用 push/hover/state change (最常用)
/// - [gentle]:   慢 + 轻阻尼 0.5s — modal 进出 / drawer / 大块元素位置切换
/// - [bouncy]:   临界 + 轻阻尼 0.5s — celebration / tile hover / 成就解锁
enum SpringType {
  /// 临界阻尼 — 0.4s
  /// 适用: 通用 push/hover/state change (最常用)
  standard,

  /// 慢 + 轻阻尼 — 0.5s
  /// 适用: modal 进出 / drawer / 大块元素位置切换
  gentle,

  /// 临界 + 轻阻尼 — 0.5s 轻弹
  /// 适用: celebration / tile hover / 成就解锁
  bouncy,
}

/// v0.31 R4 (Apple Health redesign · Task 1.4): iOS Spring 物理模型
///
/// 用 [mass] / [stiffness] / [damping] 描述一个临界/欠阻尼弹簧。
/// 走 flutter `SpringSimulation` 在 `AnimationController.animateWith` 里执行。
///
/// 用法:
/// ```dart
/// final spring = Spring.standard;  // 或 Spring.of(context, SpringType.standard)
/// controller.animateWith(spring.toSimulation(from: 0, to: 1));
/// ```
///
/// Apple Health 物理感 (跟 `curve` token 互补):
/// - 一次性 transition: 用 `curve` (e.g. `AppMotion.curveSpring` = cubic-bezier(0.23, 1, 0.32, 1))
/// - 物理 spring (push / drag / bounce): 用 `Spring` (本类)
class Spring {
  /// 质量 (惯量), iOS 默认 1
  final double mass;

  /// 弹簧刚度, 越大收敛越快
  final double stiffness;

  /// 阻尼, 越小越弹
  /// - critical damping: 过冲一次后归位 (不震荡)
  /// - underdamping:    多次震荡
  /// - overdamping:     缓慢归位
  final double damping;

  const Spring({
    required this.mass,
    required this.stiffness,
    required this.damping,
  });

  /// 临界阻尼 0.4s — most common (spec §3.4.3)
  ///
  /// 适用: 通用 push/hover/state change / page transition / modal 进出
  static const Spring standard = Spring(
    mass: 1,
    stiffness: 200,
    damping: 20,
  );

  /// 慢 + 轻阻尼 0.5s — spec §3.4.3
  ///
  /// 适用: drawer / 大块元素位置切换 / sheet 收起
  static const Spring gentle = Spring(
    mass: 1,
    stiffness: 150,
    damping: 18,
  );

  /// 临界 + 轻阻尼 0.5s 轻弹 — spec §3.4.3
  ///
  /// 适用: celebration overlay / tile hover / 成就解锁 (rare 频度)
  static const Spring bouncy = Spring(
    mass: 1,
    stiffness: 200,
    damping: 12,
  );

  /// 转 flutter [SpringDescription] (供 physics 自定义用)
  SpringDescription toDescription() => SpringDescription(
        mass: mass,
        stiffness: stiffness,
        damping: damping,
      );

  /// 包装 flutter [SpringSimulation]
  ///
  /// 用法:
  /// ```dart
  /// controller.animateWith(spring.toSimulation(
  ///   from: 0,
  ///   to: 1,
  /// ));
  /// ```
  SpringSimulation toSimulation({
    required double from,
    required double to,
    double velocity = 0,
  }) {
    return SpringSimulation(toDescription(), from, to, velocity);
  }

  /// `Spring.of(context, SpringType.standard)` 工厂方法 (spec §3.4.6)
  ///
  /// 当前直接走静态实例 (跟 context 无关)。
  /// 留 `BuildContext` 参数是为了未来接入:
  /// - user accessibility preference (e.g. reduced motion → 走更轻 spring)
  /// - user theme override (e.g. elderly 模式 → 慢速 spring)
  ///
  /// 现在忽略 context, 仅按 [type] 分发。
  static Spring of(BuildContext context, SpringType type) {
    // ignore: unused_local_variable
    final _ = context; // 占位避免 lint, 未来用
    switch (type) {
      case SpringType.standard:
        return standard;
      case SpringType.gentle:
        return gentle;
      case SpringType.bouncy:
        return bouncy;
    }
  }
}
