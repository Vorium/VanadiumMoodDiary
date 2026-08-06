// v0.30 round 93 (test): settings_page 4 section 隐藏验证
//
// R93 阶段 2: "所有需要真接的内容先隐藏" 策略
// 4 section 走 FeatureFlag gate, 业务暂停期间完全 hidden:
//
// 1. IAP 商业卡 → FeatureFlags.iapEnabled
// 2. 联系人 section → FeatureFlags.emergencyContactEnabled
// 3. 5 厂商 OEM 引导 → FeatureFlags.fiveVendorPushEnabled
// 4. 邮件预览 → FeatureFlags.emailServiceEnabled
//
// 4 case:
//   - case 1: 4 flag 默认 false → 4 section 全 hidden (verify by find)
//   - case 2: iapEnabled=true → IAP 商业卡渲染 (workspace_premium icon)
//   - case 3: emergencyContactEnabled=true → ContactsListWidget 渲染
//   - case 4: emailServiceEnabled=true → 邮件预览 Card 渲染
//   - case 5: fiveVendorPushEnabled=true → OEM 引导 ExpansionTile 渲染
//
// 测试模式: 每个 case 调 `setXxxEnabledForTest(true)` 翻 flag, 验证 widget 渲染。
// tearDown resetForTest 恢复 prod 默认。
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/contact/contacts_list_widget.dart';
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

  tearDown(() {
    FeatureFlags.resetForTest();
  });

  // helper: 构造测试 widget
  Widget buildSettingsPage() {
    return ProviderScope(
      overrides: [
        contactsProvider.overrideWith((ref) => Stream.value(const [])),
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

  testWidgets('R93 case 1: 4 flag 默认 false → 4 section 全 hidden', (tester) async {
    await tester.pumpWidget(buildSettingsPage());
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // 1. IAP 商业卡 hidden (workspace_premium icon 不应渲染)
    expect(find.byIcon(Icons.workspace_premium), findsNothing);

    // 2. 联系人 section hidden (ContactsListWidget 不应渲染)
    expect(find.byType(ContactsListWidget), findsNothing);

    // 3. 5 厂商 OEM 引导 hidden (ExpansionTile 标题 "国产手机没收到通知？" 不应渲染)
    expect(find.text('国产手机没收到通知？'), findsNothing);

    // 4. 邮件预览 hidden (settingsEmailPreview = "预览停药通知邮件" 不应渲染)
    expect(find.text('预览停药通知邮件'), findsNothing);
  });

  testWidgets('R93 case 2: iapEnabled=true → IAP 商业卡渲染',
      (tester) async {
    FeatureFlags.setIapEnabledForTest(true);
    await tester.pumpWidget(buildSettingsPage());
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // IAP 商业卡: workspace_premium icon + "升级到 Pro" title 渲染
    expect(find.byIcon(Icons.workspace_premium), findsAtLeast(1));
  });

  testWidgets('R93 case 3: emergencyContactEnabled=true → ContactsListWidget 渲染',
      (tester) async {
    // emergencyContactEnabled 没有 setEmergencyContactEnabledForTest setter (R66 兼容)
    // 用 enableForTest 翻 8 个全 true (含 emergencyContactEnabled), 验证联系人 section
    // 渲染。tearDown resetForTest 恢复 prod 默认。
    FeatureFlags.enableForTest();
    await tester.pumpWidget(buildSettingsPage());
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // 联系人 section 渲染: 滚动到底部找 ContactsListWidget
    await tester.scrollUntilVisible(find.byType(ContactsListWidget), 100);
    expect(find.byType(ContactsListWidget), findsOneWidget);
  });

  testWidgets('R93 case 4: emailServiceEnabled=true → 邮件预览 Card 渲染',
      (tester) async {
    FeatureFlags.setEmailServiceEnabledForTest(true);
    await tester.pumpWidget(buildSettingsPage());
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // 邮件预览 Card 渲染: 滚动到评估 section 找 "预览停药通知邮件" 文字
    await tester.scrollUntilVisible(find.text('预览停药通知邮件'), 100);
    expect(find.text('预览停药通知邮件'), findsOneWidget);
  });

  testWidgets('R93 case 5: fiveVendorPushEnabled=true → OEM 引导 ExpansionTile 渲染',
      (tester) async {
    FeatureFlags.setFiveVendorPushEnabledForTest(true);
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
