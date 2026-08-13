// v0.32 round 8 (R112 EM-14b fix): AppListTile 无 onTap 时 PressFeedback disabled
//
// 背景: R111 EM-14 修了 PressFeedback/PrimaryButton/CheckInButton 的 disabled
// 态 (无 scale + haptic 假反馈), 但 AppListTile 无论 onTap 有无都包
// PressFeedback 且不传 enabled → 不可点行 (settings 关于/免责声明行:
// assessment_section.dart:93/106) 按下仍有 scale + Haptics.light 假反馈
// (视觉上"能按"、行为上"没反应" = 假 affordance)。
//
// R112 EM-14b 修: `PressFeedback(enabled: onTap != null, ...)`。
//
// 测试 3 case:
// 1. onTap == null → PressFeedback.enabled == false (0 scale + 0 haptic)
// 2. onTap != null → PressFeedback.enabled == true + tap 触发回调
// 3. carded 模式无 onTap → 同样 enabled == false (2 个构造都走同一 build)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  group('AppListTile PressFeedback enabled (R112 EM-14b)', () {
    testWidgets('1. 无 onTap → PressFeedback.enabled = false (无假反馈)',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppListTile(
            leading: Icon(Icons.info_outline),
            title: Text('关于'),
            subtitle: Text('版本信息'),
          ),
        ),
      );

      final pressFeedback = tester.widget<PressFeedback>(
        find.descendant(
          of: find.byType(AppListTile),
          matching: find.byType(PressFeedback),
        ),
      );
      expect(
        pressFeedback.enabled,
        isFalse,
        reason: '无 onTap 的不可点行不应有 scale + haptic 假反馈',
      );

      // ListTile 自身 onTap 也应为 null (不可点)
      final listTile = tester.widget<ListTile>(find.byType(ListTile));
      expect(listTile.onTap, isNull, reason: '无 onTap 时 ListTile.onTap 恒 null');
    });

    testWidgets('2. 有 onTap → PressFeedback.enabled = true + tap 触发',
        (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        wrap(
          AppListTile(
            leading: const Icon(Icons.history),
            title: const Text('历史'),
            onTap: () => tapped++,
          ),
        ),
      );

      final pressFeedback = tester.widget<PressFeedback>(
        find.descendant(
          of: find.byType(AppListTile),
          matching: find.byType(PressFeedback),
        ),
      );
      expect(
        pressFeedback.enabled,
        isTrue,
        reason: '有 onTap 的可点行 PressFeedback 正常启用',
      );

      await tester.tap(find.text('历史'));
      await tester.pumpAndSettle();
      expect(tapped, 1, reason: '点行应触发 onTap');
    });

    testWidgets('3. carded 无 onTap → PressFeedback.enabled = false',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          const AppListTile.carded(
            leading: Icon(Icons.notifications),
            title: Text('通知状态'),
          ),
        ),
      );

      final pressFeedback = tester.widget<PressFeedback>(
        find.descendant(
          of: find.byType(AppListTile),
          matching: find.byType(PressFeedback),
        ),
      );
      expect(pressFeedback.enabled, isFalse, reason: 'carded 不可点行同样无假反馈');
    });
  });
}
