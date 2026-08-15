// v0.30 round 93 (test): settings_page section 隐藏验证
//
// R93 阶段 2: "所有需要真接的内容先隐藏" 策略
// section 走 FeatureFlag gate, 业务暂停期间完全 hidden:
//
// 1. 5 厂商 OEM 引导 → FeatureFlags.fiveVendorPushEnabled
// 2. 邮件预览 → R95 task 10 整 widget 删, 永远 hidden
//
// v1.0.0+147: 删商业卡 case (永久免费定版, 原 case 2 删除)。
//
// 1.1.0 round 4 (emotion-first refactor): 联系人 section 整摘
// (ProfileGroup 不再渲染 ContactsListWidget, 原 case 2 删除)。
// 1.1.0 round 4b: emailServiceEnabled flag 随 EmailService 整摘,
// 原 case 3 (flag 翻 true 仍 hidden) 删除。
//
// 2 case:
//   - case 1: 2 flag 默认 false → section 全 hidden (verify by find)
//   - case 4: fiveVendorPushEnabled=true → OEM 引导 ExpansionTile 渲染
//
// 测试模式: 每个 case 调 `setXxxEnabledForTest(true)` 翻 flag, 验证 widget 渲染。
// tearDown resetForTest 恢复 prod 默认。
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/settings_page.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/notification_status_card.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences mockSp;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    mockSp = await SharedPreferences.getInstance();
    // 每个 case 跑前 reset prod 默认 (避免上一个 case 污染)
    FeatureFlags.resetForTest();
  });

  tearDown(FeatureFlags.resetForTest);

  // helper: 构造测试 widget
  Widget buildSettingsPage() {
    return ProviderScope(
      overrides: [
        medicationsProvider.overrideWith((ref) => Stream.value(const [])),
        sharedPreferencesProvider.overrideWithValue(mockSp),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: SettingsPage(),
      ),
    );
  }

  testWidgets('R93 case 1: 2 flag 默认 false → section 全 hidden', (tester) async {
    // v0.30 round 95 (sub-spec 8 task 17): 4 group 重构, NotificationStatusCard
    // 挪到 RemindersGroup 末尾, 维持 lazy load 体验, pumpAndSettle 仍可用。
    await tester.pumpWidget(buildSettingsPage());
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // 1. 5 厂商 OEM 引导 hidden (ExpansionTile 标题 "国产手机没收到通知？" 不应渲染)
    expect(find.text('国产手机没收到通知？'), findsNothing);

    // 2. 邮件预览 hidden (settingsEmailPreview = "预览停药通知邮件" 不应渲染)
    expect(find.text('预览停药通知邮件'), findsNothing);
  });

  // R95 case 3 (1.1.0 round 4b): emailServiceEnabled flag 随 EmailService
  // 整摘删除, 该 case 移除 (邮件预览 widget R95 task 10 已整删, 无 flag
  // 可翻, hidden 状态由 case 1 覆盖)。

  testWidgets(
      'R93 case 4: fiveVendorPushEnabled=true → OEM 引导 ExpansionTile 渲染',
      (tester) async {
    FeatureFlags.setFiveVendorPushEnabledForTest(true);
    // v0.30 round 95 (sub-spec 8 task 17): 同 case 1
    await tester.pumpWidget(buildSettingsPage());
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // OEM 引导: NotificationStatusCard 内 ExpansionTile 标题 "国产手机没收到通知？" 渲染
    await tester.scrollUntilVisible(
      find.byType(NotificationStatusCard),
      100,
    );
    expect(find.byType(NotificationStatusCard), findsOneWidget);
    expect(find.text('国产手机没收到通知？'), findsOneWidget);
  });
}
