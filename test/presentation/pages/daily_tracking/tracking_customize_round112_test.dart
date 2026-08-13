// v0.32 R112-05: 追踪项自定义页拖拽重排
//
// 背景: onReorder 已 deprecated (Flutter 3.41+ 用 onReorderItem, newIndex
// 自动补偿), 且 ReorderableDragStartListener index 用 config.sortOrder
// 而非 itemBuilder 位置 i — tile 没收到 i, 拖拽会把错误位置报给框架。
// 修复: 迁 onReorderItem + 把 i 传入 _TrackingItemTile。
//
// 覆盖:
// 1. computeReorderOrders 纯函数: 下移 / 上移 / 原位 4 case
// 2. widget 拖拽: 第 1 个 handle 向下拖 → provider 顺序变化
//    (mood 移到第 2 位, anxiety 升第 1)

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/tracking_customize_page.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/providers/tracking_config_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart' show kPressTimeout;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('computeReorderOrders 纯函数', () {
    test('1) 第 1 项下移 1 位 (0→1)', () {
      final orders = computeReorderOrders(length: 4, oldIndex: 0, newIndex: 1);
      expect(orders, [1, 0, 2, 3]);
    });

    test('2) 第 1 项移到末尾 (0→3)', () {
      final orders = computeReorderOrders(length: 4, oldIndex: 0, newIndex: 3);
      expect(orders, [3, 0, 1, 2]);
    });

    test('3) 末项移到首位 (3→0)', () {
      final orders = computeReorderOrders(length: 4, oldIndex: 3, newIndex: 0);
      expect(orders, [1, 2, 3, 0]);
    });

    test('4) 原位不动 (1→1)', () {
      final orders = computeReorderOrders(length: 4, oldIndex: 1, newIndex: 1);
      expect(orders, [0, 1, 2, 3]);
    });
  });

  group('TrackingCustomizePage 拖拽', () {
    late SharedPreferences sp;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      sp = await SharedPreferences.getInstance();
    });

    Widget wrap() {
      return ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sp),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('zh'),
          home: TrackingCustomizePage(),
        ),
      );
    }

    testWidgets('5) 拖第 1 个 handle 向下 → mood 与 anxiety 换位', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // 初始顺序: mood 第 1
      final container = ProviderScope.containerOf(
        tester.element(find.byType(TrackingCustomizePage)),
      );
      expect(container.read(trackingConfigProvider).allItems.first.id, 'mood');

      // ReorderableDragStartListener 是 immediate 手势: 跟 flutter SDK 自家
      // reorderable_list_test 同款 — pump kPressTimeout 让 arena 决出胜者,
      // 然后一步拖 2 个 item extent。
      // 几何要求: 被拖 item 顶边必须跨过下一个 item 的中线 (1.5 extent)
      // 才会触发 reorder, 拖 2 extent 稳定跨过且只移 1 位。
      final handle = find.byIcon(Icons.drag_handle).first;
      final firstTop = tester.getTopLeft(find.byType(Card).at(0)).dy;
      final secondTop = tester.getTopLeft(find.byType(Card).at(1)).dy;
      final extent = secondTop - firstTop;
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await tester.pump(kPressTimeout);
      await gesture.moveBy(Offset(0, extent * 2));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final after = container.read(trackingConfigProvider).allItems;
      expect(after[0].id, 'anxiety');
      expect(after[1].id, 'mood');
    });
  });
}
