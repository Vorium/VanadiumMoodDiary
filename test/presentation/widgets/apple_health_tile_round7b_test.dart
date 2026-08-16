// v0.31 round 7b (Apple Health redesign · Phase 2 Task 2.3): AppleHealthTile 11 测试
//
// 验证:
// - 8 metric 各自渲染正确 icon + metric 色 (1 个 metric 1 test)
// - 1 dark mode (alpha 0.18)
// - 1 onTap callback 触发
// - 1 chevron 16pt textHint 渲染
//
// 设计原则:
// - 不用 Material 3 darkTheme (跟 R14 PressFeedback test 风格一致, 走 Theme wrapper)
// - icon 验证: find.byIcon(Icons.medication) 等
// - 颜色验证: 走 AppColors.healthMetricsColorFor 对照

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/apple_health_tile.dart';

void main() {
  Widget wrap(Widget child, {bool dark = false}) => MaterialApp(
        theme: dark ? ThemeData.dark(useMaterial3: true) : null,
        home: Scaffold(body: Center(child: child)),
      );

  // 找指定 metricId 的 Icon (靠 size 28 区分 chevron 16)
  Finder findMetricIcon(String metricId, IconData icon) =>
      find.byWidgetPredicate(
        (w) => w is Icon && w.icon == icon && w.size == 28,
      );

  group('AppleHealthTile (R7b 8 metric + dark + onTap + chevron)', () {
    // ===== 8 metric icon + color 测试 =====
    const metrics = <_MetricSpec>[
      _MetricSpec('medication', Icons.medication, Color(0xFFFF3B30)),
      _MetricSpec('mood', Icons.mood, Color(0xFFFF2D55)),
      _MetricSpec('vent', Icons.mic, Color(0xFFAF52DE)),
      _MetricSpec('assessment', Icons.assignment, Color(0xFF5856D6)),
      _MetricSpec('checkIn', Icons.check_circle, Color(0xFF34C759)),
      _MetricSpec('trend', Icons.show_chart, Color(0xFF007AFF)),
      _MetricSpec('contact', Icons.contact_phone, Color(0xFFFF9500)),
      _MetricSpec('sleep', Icons.bedtime, Color(0xFF5AC8FA)),
    ];

    for (var i = 0; i < metrics.length; i++) {
      final m = metrics[i];
      testWidgets(
          '${i + 1}. metric=${m.id} → icon=${m.icon} + color 0x${m.color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
          (tester) async {
        await tester.pumpWidget(
          wrap(
            AppleHealthTile(
              metricId: m.id,
              label: 'L-$i',
              value: 'V-$i',
            ),
          ),
        );

        // icon 28pt 渲染 (不是默认 24, R7b 视觉关键)
        final iconFinder = findMetricIcon(m.id, m.icon);
        expect(
          iconFinder,
          findsOneWidget,
          reason: 'metric=${m.id} 应该有 ${m.icon} 28pt',
        );

        final iconWidget = tester.widget<Icon>(iconFinder);
        expect(
          iconWidget.color,
          m.color,
          reason: 'metric=${m.id} icon color 应是 iOS system color',
        );

        // label / value 都渲染
        expect(find.text('L-$i'), findsOneWidget);
        expect(find.text('V-$i'), findsOneWidget);
      });
    }

    // ===== 9. dark mode: 背景 alpha 0.18 =====
    testWidgets('9. dark mode: 背景 alpha 0.18 (light 0.12 之外)', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppleHealthTile(
            metricId: 'medication',
            label: '用药',
            value: '5',
          ),
          dark: true,
        ),
        // 重启避免多 wrap 状态污染
      );
      // 找 Container (用我们的 box decoration)
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppleHealthTile),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;
      // dark mode: alpha 0.18
      expect(
        decoration.color!.a,
        closeTo(0.18, 0.001),
        reason: 'dark mode 背景 alpha = 0.18',
      );
    });

    // ===== 10. onTap 触发 =====
    testWidgets('10. onTap 触发 callback (走 PressFeedback 模式 1)', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        wrap(
          AppleHealthTile(
            metricId: 'mood',
            label: '心情',
            value: '4',
            onTap: () => tapCount++,
          ),
        ),
      );
      await tester.tap(find.byType(AppleHealthTile));
      await tester.pump();
      expect(tapCount, 1, reason: 'onTap 应该被调用 1 次');
    });

    // ===== 11. chevron 16pt textHint =====
    testWidgets('11. chevron 16pt + textHint color', (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppleHealthTile(
            metricId: 'trend',
            label: '趋势',
            value: '12',
          ),
        ),
      );
      // 找 chevron: Icons.chevron_right size 16
      final chevronFinder = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == Icons.chevron_right && w.size == 16,
      );
      expect(chevronFinder, findsOneWidget, reason: '右侧应该渲染 chevron 16pt');

      // chevron color = textHint
      final ctx = tester.element(find.byType(AppleHealthTile));
      final chevron = tester.widget<Icon>(chevronFinder);
      expect(
        chevron.color,
        AppTokens.textHintColor(ctx),
        reason: 'chevron 应该用 textHint color (弱视觉提示)',
      );
    });
  });
}

/// 测试辅助: 1 个 metric spec (id + icon + 期望 iOS system color)
class _MetricSpec {
  const _MetricSpec(this.id, this.icon, this.color);
  final String id;
  final IconData icon;
  final Color color;
}
