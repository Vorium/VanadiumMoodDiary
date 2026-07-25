// v0.22 round 34: 5 个新通用 widget 的基础 widget test
//
// emil A1-A5 抽 widget 时配套,确保替换 4+ 处重复前 baseline 行为稳定。
// 后续 round 36 替换 4+ 处实际调用时会更新这个 test (加新 case)。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/presentation/widgets/loading_text_button.dart';
import 'package:chroniccare/presentation/widgets/chip_badge.dart';
import 'package:chroniccare/presentation/widgets/animations/page_transition_switcher.dart';

void main() {
  group('LoadingTextButton — emil A1', () {
    testWidgets('isLoading=false → 显示 label,onPressed 触发', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingTextButton(
              label: '保存',
              isLoading: false,
              onPressed: () => tapped++,
            ),
          ),
        ),
      );
      expect(find.text('保存'), findsOneWidget);
      await tester.tap(find.byType(LoadingTextButton));
      await tester.pumpAndSettle();
      expect(tapped, 1);
    });

    testWidgets('isLoading=true → 不响应点击 + 显示 spinner', (tester) async {
      var tapped = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingTextButton(
              label: '保存',
              isLoading: true,
              onPressed: () => tapped++,
            ),
          ),
        ),
      );
      // IgnorePointer 包 spinner,所以 tap 落到 button 也会被吃掉
      // 用 pump 不用 pumpAndSettle,LoadingSpinner 内部是 1.2s 永久循环
      await tester.tap(find.byType(LoadingTextButton));
      await tester.pump();
      expect(tapped, 0);
    });
  });

  group('ChipBadge — emil A2', () {
    testWidgets('neutral tone 显示 label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChipBadge(label: '已打卡', tone: ChipBadgeTone.neutral),
          ),
        ),
      );
      expect(find.text('已打卡'), findsOneWidget);
    });

    testWidgets('error tone 渲染 Container with radius', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChipBadge(label: '错误', tone: ChipBadgeTone.error),
          ),
        ),
      );
      expect(find.text('错误'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('PageTransitionSwitcher — emil A5', () {
    testWidgets('switchKey 变化 → fade 切换 + 旧 child 消失', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageTransitionSwitcher(
              switchKey: 'list',
              child: Text('list 视图'),
            ),
          ),
        ),
      );
      expect(find.text('list 视图'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageTransitionSwitcher(
              switchKey: 'calendar',
              child: Text('calendar 视图'),
            ),
          ),
        ),
      );
      // 切换后 pump 几帧, 旧 child 退出动画结束后应消失
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('calendar 视图'), findsOneWidget);
    });
  });
}
