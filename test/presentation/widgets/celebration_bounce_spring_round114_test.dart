// R114 Wave B2: CelebrationBounce scale(0) 入场 + Spring.bouncy 接线 (B2-9 后半)
//
// emil F11: 修前 Tween(begin: 0.0, end: 1.2) — 庆祝气泡从 scale 0 迸出,
// 违反 emil "nothing appears from nothing" (对照 fade_in.dart 0.92 样板)。
// 修法: begin 0.5 (可见的"瘪气形状"再膨胀)。
//
// emil F10 + apple F-10 裁决: gentle/bouncy 2 年 0 caller — 接 bouncy 到
// celebration (物理模型第 2 个真 caller, 第 1 个 = CheckInButton 的
// Spring.standard): scale 曲线用 Spring.bouncy.toSimulation(from: 0.5,
// to: 1.0) 替代 curveBackOut TweenSequence (欠阻尼 0.42 自然过冲 ~1.12
// 后收敛 1.0); opacity 保留 TweenSequence 淡入淡出 (独立 controller)。

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/widgets/animations/celebration_bounce.dart';

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: Center(child: CelebrationBounce(message: 'hi'))),
    ),
  );
}

/// CelebrationBounce 内 Transform.scale 的 scale (读 entry(0,0))
double _scaleAt(WidgetTester tester) {
  final t = tester.widget<Transform>(
    find
        .descendant(
          of: find.byType(CelebrationBounce),
          matching: find.byType(Transform),
        )
        .first,
  );
  return t.transform.entry(0, 0);
}

void main() {
  testWidgets('首帧 scale 0.5 (不从虚空迸出)', (tester) async {
    await _pump(tester);

    expect(
      _scaleAt(tester),
      closeTo(0.5, 0.001),
      reason: '修前 begin 0.0 — 从 scale 0 迸出违反 "nothing appears from nothing"',
    );
  });

  testWidgets('Spring.bouncy: 过冲 > 1.0 后收敛到 1.0', (tester) async {
    await _pump(tester);

    // bouncy (damping ratio 0.42, 周期 ~0.44s) 峰值 ≈ 0.22s — 采样
    // 100~400ms 各帧取最大值, 断言出现过冲 (弹簧物理形态)
    var peak = 0.0;
    for (var t = 0; t <= 400; t += 50) {
      await tester.pump(const Duration(milliseconds: 50));
      final s = _scaleAt(tester);
      if (s > peak) peak = s;
    }
    expect(
      peak,
      greaterThan(1.0),
      reason: '欠阻尼弹簧应过冲 (bouncy 物理形态, 替代 curveBackOut 曲线模拟)',
    );

    await tester.pumpAndSettle();
    expect(
      _scaleAt(tester),
      closeTo(1.0, 0.01),
      reason: '弹簧收敛到终态 1.0',
    );
  });

  test('lock-in: celebration_bounce.dart 用 Spring.bouncy (真 caller)', () async {
    final src = await File(
      'lib/presentation/widgets/animations/celebration_bounce.dart',
    ).readAsString();
    expect(
      src.contains('Spring.bouncy'),
      isTrue,
      reason: 'Spring.bouncy 应有 runtime caller (死代码 → 真 caller)',
    );
  });
}
