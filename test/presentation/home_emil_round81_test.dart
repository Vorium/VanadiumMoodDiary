// v0.28 R81 (emil design-6): SectionHeader chip + HomeFabToolbar 集成测
//
// 覆盖 R81-5 (SectionHeader chip 标签) + R81-3 (HomeFabToolbar
// 浮动工具栏) 的 5 case 集成测, 验证 widget 行为 + 用户交互。
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_fab_toolbar.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('SectionHeader chip 字段 (R81-5)', () {
    testWidgets('chip=null → 纯文字模式 (无 chip 显示)', (tester) async {
      await _pump(tester, const SectionHeader(title: '近 30 天'));
      expect(find.text('近 30 天'), findsOneWidget);
      // 无 chip 容器渲染
      expect(find.byType(Container), findsNothing,
          reason: 'chip=null 时不应该渲染 _ChipBadge 容器');
    });

    testWidgets('chip="近 30 天" → 标题 + chip 同时显示', (tester) async {
      await _pump(
        tester,
        const SectionHeader(title: '近 30 天', chip: '近 30 天'),
      );
      expect(find.text('近 30 天'), findsAtLeastNWidgets(2),
          reason: '标题 + chip 都包含 "近 30 天" 文本');
    });

    testWidgets('chip + leading + action 复合模式正常显示',
        (tester) async {
      await _pump(
        tester,
        SectionHeader(
          title: '心理评估',
          chip: '本周',
          leading: const Icon(Icons.psychology_outlined),
          action: TextButton(onPressed: () {}, child: const Text('设置')),
        ),
      );
      expect(find.text('心理评估'), findsOneWidget);
      expect(find.text('本周'), findsOneWidget);
      expect(find.byIcon(Icons.psychology_outlined), findsOneWidget);
      expect(find.text('设置'), findsOneWidget);
    });
  });

  group('HomeFabToolbar 浮动工具栏 (R81-3)', () {
    testWidgets('初始收起 → 1 个主 FAB (menu icon), 0 工具按钮可见',
        (tester) async {
      await _pump(tester, const HomeFabToolbar());
      // 收起状态: 4 工具按钮隐藏 (AnimatedSize 折叠), 只显示主 FAB
      expect(find.byIcon(Icons.menu), findsOneWidget,
          reason: '初始收起显示 menu icon');
      expect(find.byIcon(Icons.close), findsNothing,
          reason: '初始收起不应该显示 close icon');
      // 4 工具按钮 label 收起时不可见 (AnimatedSize 高度=0)
      expect(find.text('心情测试'), findsNothing,
          reason: '收起时 4 工具按钮隐藏');
      expect(find.text('心情树洞'), findsNothing);
      expect(find.text('紧急热线'), findsNothing);
      expect(find.text('回到顶端'), findsNothing);
    });

    testWidgets('点击主 FAB → 展开 4 工具按钮 + close icon',
        (tester) async {
      await _pump(tester, const HomeFabToolbar());
      // 点击主 FAB (menu icon 容器)
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      // 展开状态: 4 工具按钮可见
      expect(find.text('心情测试'), findsOneWidget,
          reason: '展开后心情测试工具按钮可见');
      expect(find.text('心情树洞'), findsOneWidget);
      expect(find.text('紧急热线'), findsOneWidget);
      expect(find.text('回到顶端'), findsOneWidget);
      // 主 FAB 变 close icon
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsNothing,
          reason: '展开后主 FAB 变 close icon');
    });

    testWidgets('再次点击 close FAB → 收回 4 工具按钮 + menu icon',
        (tester) async {
      await _pump(tester, const HomeFabToolbar());
      // 展开
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('心情测试'), findsOneWidget);
      // 收回
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('心情测试'), findsNothing,
          reason: '收回后 4 工具按钮隐藏');
      expect(find.byIcon(Icons.menu), findsOneWidget,
          reason: '收回后主 FAB 变 menu icon');
    });
  });
}
