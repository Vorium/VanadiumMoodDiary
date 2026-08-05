// v0.18 round 14 (P0-6) Setup consent 步测试
//
// 验证:
// 1. 初始 step 0 = consent,有 4 个 Checkbox,4 文本 label
// 2. 没勾任一 checkbox → "开始设置"按钮 disabled
// 3. 勾 1 个 → 仍 disabled
// 4. 勾 4 个 → enabled
// 5. 勾完点"开始设置" → 进入 step 1 (welcome)
//
// v0.27 R83 (Q11a 律师审核 ⚠️ 修复): 第 4 个 checkbox 是
// `setupLegalAgeAttestation` (年龄严正声明). 依据《未成年人保护法》§44
// 与《个人信息保护法》§31,14-18 周岁用户需监护人代为签署同意.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_page.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/core/data/services/notification_service.dart';

class _NoopNotificationService extends NotificationService {
  @override
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {}
}

Future<void> _pumpSetup(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(
          _NoopNotificationService(),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: SetupPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('P0-6: step 0 显示 4 个 Checkbox + 4 个法律 label', (tester) async {
    await _pumpSetup(tester);

    // v0.27 R83: 第 4 个 checkbox 是年龄严正声明 (setupLegalAgeAttestation)
    expect(find.byType(Checkbox), findsNWidgets(4));
    expect(find.text('我已阅读并同意《用户协议》'), findsOneWidget);
    expect(find.text('我已阅读并同意《隐私政策》'), findsOneWidget);
    expect(
      find.text('我已阅读并同意《敏感个人信息处理同意书》'),
      findsOneWidget,
    );
    expect(
      find.textContaining('本人郑重承诺'),
      findsOneWidget,
      reason: 'v0.27 R83: 第 4 个 checkbox label = setupLegalAgeAttestation '
          '开头是 "本人郑重承诺"',
    );
  });

  testWidgets('P0-6: 初始 4 checkbox 全 unchecked → 开始设置按钮 disabled',
      (tester) async {
    await _pumpSetup(tester);

    for (final c in find.byType(Checkbox).evaluate()) {
      final cb = c.widget as Checkbox;
      expect(cb.value, isFalse);
    }

    // v0.27 round 65 (flutter L10): ElevatedButton → FilledButton (via PrimaryButton)
    final btn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '开始设置'),
    );
    expect(
      btn.onPressed,
      isNull,
      reason: '4 个法律勾选都没勾,开始设置按钮必须 disabled',
    );
  });

  testWidgets('P0-6: 勾任 1 / 2 / 3 个 → 开始设置仍 disabled', (tester) async {
    await _pumpSetup(tester);

    // 勾第一个
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pumpAndSettle();
    final btn1 = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '开始设置'),
    );
    expect(btn1.onPressed, isNull, reason: '只勾 1 个,仍 disabled');

    // 再勾第二个
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    final btn2 = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '开始设置'),
    );
    expect(btn2.onPressed, isNull, reason: '只勾 2 个,仍 disabled');

    // 再勾第三个 (v0.27 R83: 加了第 4 个 checkbox, 勾 3 个仍 disabled)
    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pumpAndSettle();
    final btn3 = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '开始设置'),
    );
    expect(btn3.onPressed, isNull, reason: '只勾 3 个 (含年龄声明), 仍 disabled');
  });

  testWidgets('P0-6: 勾 4 个 → 开始设置 enabled', (tester) async {
    await _pumpSetup(tester);

    // v0.27 R83: 4 个 checkbox 全勾才能 enabled
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byType(Checkbox).at(i));
      await tester.pumpAndSettle();
    }

    final btn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '开始设置'),
    );
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('P0-6: 勾完 4 个点开始设置 → 进入 step 1 (welcome)', (tester) async {
    await _pumpSetup(tester);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byType(Checkbox).at(i));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.widgetWithText(FilledButton, '开始设置'));
    await tester.pumpAndSettle();

    expect(
      find.text('您好，我是慢病管家'),
      findsOneWidget,
      reason: 'P0-6: 勾完 4 个法律同意后,应进入 welcome step',
    );
  });
}
