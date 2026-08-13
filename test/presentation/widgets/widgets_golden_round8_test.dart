// v0.32 round 8 (FS P2-003): 3 个核心集中器 golden 测试
//
// PrimaryButton / StatCard / AppleListSection 是 Apple Health 重设计
// (v0.31) 的核心 widget, 视觉回归靠 widget test 的语义断言不够 (颜色 /
// 间距 / 圆角改坏不报错)。golden 锁像素。
//
// 约定 (本项目首批 golden, R112-06 起):
// - golden 基线文件跟测试同目录 (test/presentation/widgets/golden/)
// - 生成基线: flutter test --update-goldens test/presentation/widgets/golden/widgets_golden_round8_test.dart
// - 之后跑 flutter test 无 flag = 验证模式 (像素 diff 即 fail)
// - 稳定手段: 固定 view size + devicePixelRatio 1.0 + AppTheme.light()
//   真实主题 + zh locale (测试字体确定性渲染) + pumpAndSettle 让
//   TweenNumber / AnimatedScale 初始动画结束
// - 3 个 widget 无 InkSparkle press 状态 (golden 不按压 → 不触发
//   ink_sparkle.frag shader 资产依赖)

import 'package:chroniccare/core/theme/app_theme.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';
import 'package:chroniccare/presentation/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap({required Widget child}) {
    return MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 320, child: child),
        ),
      ),
    );
  }

  void setStableView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('golden: PrimaryButton primary pill (50pt 高, 14pt 圆角)',
      (tester) async {
    setStableView(tester);
    await tester.pumpWidget(
      wrap(
        child: PrimaryButton(
          onPressed: () {},
          child: const Text('完成设置'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(PrimaryButton),
      matchesGoldenFile('golden/primary_button_primary.png'),
    );
  });

  testWidgets('golden: StatCard ultralight 大数字 + label', (tester) async {
    setStableView(tester);
    await tester.pumpWidget(
      wrap(
        child: const StatCard(
          label: '连续打卡天数',
          value: '28',
          variant: StatCardVariant.defaultVariant,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(StatCard),
      matchesGoldenFile('golden/stat_card_default.png'),
    );
  });

  testWidgets('golden: AppleListSection title + chip + 2 cell + footer',
      (tester) async {
    setStableView(tester);
    await tester.pumpWidget(
      wrap(
        child: const AppleListSection(
          title: '今日用药',
          chip: '2',
          footer: '点击卡片查看详情',
          children: [
            ListTile(
              title: Text('舍曲林 50mg'),
              subtitle: Text('08:00 · 已服'),
              trailing: Icon(Icons.check_circle_outline),
            ),
            ListTile(
              title: Text('奥氮平 5mg'),
              subtitle: Text('20:00 · 未服'),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(AppleListSection),
      matchesGoldenFile('golden/apple_list_section_with_chip.png'),
    );
  });
}
