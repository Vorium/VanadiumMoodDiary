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
//
// v0.32 round 8 (R112-03 fix): 删 `SpringType` enum + `Spring.of` factory
// 死代码 (0 caller, 内部 `final _ = context` 占位 hack 纯属摆设)。保留
// 3 个静态实例 (standard/gentle/bouncy) + toDescription/toSimulation 作为
// 物理模型公共 API — gentle/bouncy 当前也 0 caller, 但作为 spec §3.4.3
// 的完整模型面保留 (接真 caller 时直接用)。
import 'package:flutter/physics.dart' show SpringDescription, SpringSimulation;

/// v0.31 R4 (Apple Health redesign · Task 1.4): iOS Spring 物理模型
///
/// 用 [mass] / [stiffness] / [damping] 描述一个临界/欠阻尼弹簧。
/// 走 flutter `SpringSimulation` 在 `AnimationController.animateWith` 里执行。
///
/// 用法:
/// ```dart
/// final spring = Spring.standard;
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
}
