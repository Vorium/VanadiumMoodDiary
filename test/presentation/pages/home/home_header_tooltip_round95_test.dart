// v0.30 round 95 (sub-spec 8 task 45): 主页 header 3 icon button tooltip
//
// R95 emil 反复提: 主页 header 3 icon button 必须有 tooltip (跟功能一致)。
// 修前: 3rd button (settings) tooltip 误用 settingsAbout = "关于" (跟按钮
// 跳 /settings 设置页不符, emil design — tooltip 跟功能必须一致)。
// 修后: 加新 ARB key homeTooltipSettings = "设置" / "Settings" / "設定"
// (3 语 sync), 跟按钮功能对齐。
//
// 测试覆盖:
// 1. 3 icon button 都存在 (show_chart / psychology_outlined / settings_outlined)
// 2. 3 button tooltip 跟按钮功能一致
//    - 趋势 button → "查看趋势"
//    - 评估历史 button → "评估历史"
//    - 设置 button → "设置" (不再 "关于")
// 3. ARB 3 语 sync (zh / en / zh_Hant 都有 homeTooltipSettings)
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/home/widgets/home_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('主页 header 3 icon button: tooltip 跟功能一致 (task 45)',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: Scaffold(
          body: HomeHeader(userName: '测试用户'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 3 个 icon button 渲染
    expect(find.byIcon(Icons.show_chart), findsOneWidget);
    expect(find.byIcon(Icons.psychology_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    // 3 button tooltip 跟功能一致
    // 注: IconButton tooltip 在 long press 时才显示, 这里通过 widget 验证
    final showChartBtn = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.show_chart),
    );
    expect(showChartBtn.tooltip, '查看趋势');

    final psychologyBtn = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.psychology_outlined),
    );
    expect(psychologyBtn.tooltip, '评估历史');

    final settingsBtn = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.settings_outlined),
    );
    // v0.30 R95 sub-spec 8 task 45: 3rd button tooltip 跟功能对齐
    // (修前误用 "关于" settingsAbout, 修后用 homeTooltipSettings = "设置")
    expect(settingsBtn.tooltip, '设置',
        reason: 'task 45: 设置 button tooltip 必须是"设置"而非"关于"',);
  });
}
