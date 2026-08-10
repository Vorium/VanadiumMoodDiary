// v0.31.1 round 10 (P0-08): Spring 物理模型 test
//
// 覆盖 spec §3.4.3 双轨制的 Spring 物理模型端 (curve token 端由
// motion_scheme_round14 + app_tokens_lock_in 覆盖):
// 1. Spring.standard: mass 1, stiffness 200, damping 20 — 临界阻尼 ~0.4s
// 2. Spring.gentle:   mass 1, stiffness 150, damping 18 — 0.5s (慢 + 轻阻尼)
// 3. Spring.bouncy:   mass 1, stiffness 200, damping 12 — 0.5s 轻弹 (庆祝)
// 4. Spring.of(context, type) factory: 3 类型各返正确实例 (testWidgets 拿 ctx)
// 5. Spring.toSimulation + toDescription: 返 SpringSimulation 物理形态正确
//
// 跨视角共识: emil P0-E + superpowers-en P1 + Apple Health P0-3
// (3 视角都指出 Spring 物理模型 0 caller 死代码, R10 接 _EntrySpring 后
// 必须有物理模型本身的 unit test 兜底)

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart' hide SpringType;
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/theme/spring.dart';

void main() {
  group('Spring 物理模型 (v0.31.1 round 10 P0-08 / spec §3.4.3)', () {
    test('Spring.standard: 临界阻尼 0.4s (mass 1 / stiffness 200 / damping 20)',
        () {
      // spec §3.4.3: 临界阻尼 0.4s — most common
      expect(Spring.standard.mass, 1.0);
      expect(Spring.standard.stiffness, 200.0);
      expect(Spring.standard.damping, 20.0);
    });

    test('Spring.gentle: 慢 + 轻阻尼 0.5s (stiffness 150 < standard 200)',
        () {
      // spec §3.4.3: 慢 + 轻阻尼 0.5s — modal 进出 / drawer
      expect(Spring.gentle.mass, 1.0);
      expect(Spring.gentle.stiffness, 150.0);
      expect(Spring.gentle.damping, 18.0);
      // 跟 standard 比: stiffness 150 < 200 (慢)
      expect(Spring.gentle.stiffness, lessThan(Spring.standard.stiffness));
    });

    test('Spring.bouncy: 临界 + 轻阻尼 0.5s 轻弹 (damping 12 < standard 20)',
        () {
      // spec §3.4.3: 0.5s 轻弹 — celebration / tile hover
      expect(Spring.bouncy.mass, 1.0);
      expect(Spring.bouncy.stiffness, 200.0);
      expect(Spring.bouncy.damping, 12.0);
      // 跟 standard 比: damping 12 < 20 (更弹, 多次震荡)
      expect(Spring.bouncy.damping, lessThan(Spring.standard.damping));
    });

    testWidgets('Spring.of(context, type) factory: 3 类型各返正确实例',
        (tester) async {
      // Spring.of 内部不读 ctx (R4b 留 ctx 为未来 reduced motion / theme 接入),
      // 仅按 type 分发. 测 3 case + ctx 不影响结果.
      late BuildContext capturedCtx;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                capturedCtx = ctx;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(capturedCtx, isA<BuildContext>());

      expect(Spring.of(capturedCtx, SpringType.standard), same(Spring.standard));
      expect(Spring.of(capturedCtx, SpringType.gentle), same(Spring.gentle));
      expect(Spring.of(capturedCtx, SpringType.bouncy), same(Spring.bouncy));
    });

    test(
        'Spring.standard.toSimulation + toDescription: 返 SpringSimulation 物理形态正确',
        () {
      // toDescription 走 flutter SpringDescription (mass / stiffness / damping)
      final desc = Spring.standard.toDescription();
      expect(desc, isA<SpringDescription>());
      expect(desc.mass, 1.0);
      expect(desc.stiffness, 200.0);
      expect(desc.damping, 20.0);

      // toSimulation 返 SpringSimulation, 起始 x = from, 终态 x = to
      // 0 velocity, 0 时刻精确 = from
      final sim = Spring.standard.toSimulation(
        from: 0.0,
        to: 1.0,
        velocity: 0.0,
      );
      expect(sim, isA<SpringSimulation>());
      expect(sim.x(0), 0.0); // t=0 时位置 = from (SpringSimulation.x 语义)
      // t → ∞ 时收敛到 to (= 1.0, 验证物理极限)
      // 用较大 t 验证 (不用 double.infinity 避免数值不稳)
      const tLarge = 10.0; // 物理 10s 后基本收敛
      expect(sim.x(tLarge), closeTo(1.0, 0.01));
      // 初速度 (velocity=0): 0 时刻一阶导 = 0
      expect(sim.dx(0), 0.0);

      // 测 velocity != 0 也走通: x(0) 仍 = from (瞬时位置不变)
      final sim2 = Spring.standard.toSimulation(
        from: 0.5,
        to: 1.0,
        velocity: 2.0,
      );
      expect(sim2.x(0), 0.5);
    });
  });
}
