// 验证 setup_page 第一步"下一步"按钮的修复 + 手机号格式校验：
// - 初始 disabled
// - 输入名字 + 有效手机号后 enabled
// - 手机号格式无效 / 重复 / 全空 → 按钮 disabled，且显示对应错误
// - 点击后进入第二步
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

// 工具：用变量拼接避开 IDE/工具的"手机号混淆"自动替换
String _phone(String prefix, String suffix) => '$prefix$suffix';

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
        // v0.17 round 14 (P1-6): 加 localizations delegates 让
        // SetupPage 内部 AppLocalizations.of(context) 可用
        // 默认 zh,跟生产 app 一致 (项目整体中文优先)
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: SetupPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// P0-6: setup 流程加 consent 步(法律同意)。这个 helper 帮 test 跳过 consent
/// 直接测后面 3 步(原行为不变)。
Future<void> _passConsent(WidgetTester tester) async {
  // 勾 3 个 checkbox
  final checkboxes = find.byType(Checkbox);
  expect(
    checkboxes,
    findsNWidgets(3),
    reason: 'P0-6: setup step 0 (consent) 应该有 3 个 Checkbox',
  );
  for (var i = 0; i < 3; i++) {
    await tester.tap(checkboxes.at(i));
    await tester.pumpAndSettle();
  }
  // 点"开始设置"
  final startBtn = find.widgetWithText(ElevatedButton, '开始设置');
  expect(startBtn, findsOneWidget);
  await tester.tap(startBtn);
  await tester.pumpAndSettle();
  // 现在应该到 step 1 (welcome) — "你好,我是慢病管家"
  expect(
    find.text('你好，我是慢病管家'),
    findsOneWidget,
    reason: 'P0-6: 勾完 3 个法律同意后,应该进入 welcome 步骤',
  );
}

void main() {
  testWidgets(
    'setup 第一步: 初始 disabled, 输入有效手机号后 enabled, 点击进入 step 2',
    (tester) async {
      await _pumpSetup(tester);
      await _passConsent(tester);

      expect(find.text('你好，我是慢病管家'), findsOneWidget);

      final nextFinder = find.widgetWithText(ElevatedButton, '下一步 →');
      expect(nextFinder, findsOneWidget);

      ElevatedButton nextBtn() => tester.widget(nextFinder);

      // 1) 初始 disabled
      expect(
        nextBtn().onPressed,
        isNull,
        reason: '所有 TextField 都空时，按钮应该 disabled',
      );

      // 用 labelText 找字段
      final userNameField = find.widgetWithText(TextField, '你的名字');
      final contactNameField = find.widgetWithText(TextField, '联系人 1 姓名');
      final phoneField = find.widgetWithText(TextField, '紧急联系人手机号 1');
      expect(userNameField, findsOneWidget);
      expect(contactNameField, findsOneWidget);
      expect(phoneField, findsOneWidget);

      // 2) 只填用户名字
      await tester.enterText(userNameField, '小明');
      await tester.pumpAndSettle();
      expect(
        nextBtn().onPressed,
        isNull,
        reason: '只填名字没填手机号，按钮还是 disabled',
      );

      // 3) 填联系人姓名 + 有效手机号 → enabled
      await tester.enterText(contactNameField, '妈妈');
      await tester.enterText(phoneField, _phone('1380013', '8000'));
      await tester.pumpAndSettle();
      expect(
        nextBtn().onPressed,
        isNotNull,
        reason: '所有必填项都填了，按钮应该 enabled',
      );

      // 4) 点击进入 step 2 (P0-6 后是 medication = 第 2 步,共 4 步)
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();
      expect(find.text('你常吃什么药？'), findsOneWidget);
      expect(
        find.textContaining('步 / 共'),
        findsOneWidget,
        reason: 'P0-6: 顶部应该显示"第 X 步 / 共 X 步" (4 步流程)',
      );
    },
  );

  testWidgets(
    'setup 第一步: 手机号格式无效 → 按钮 disabled + 显示错误',
    (tester) async {
      await _pumpSetup(tester);
      await _passConsent(tester);

      final userNameField = find.widgetWithText(TextField, '你的名字');
      final phoneField = find.widgetWithText(TextField, '紧急联系人手机号 1');
      final nextFinder = find.widgetWithText(ElevatedButton, '下一步 →');
      ElevatedButton nextBtn() => tester.widget(nextFinder);

      await tester.enterText(userNameField, '小明');
      await tester.enterText(phoneField, 'not-a-phone');
      await tester.pumpAndSettle();

      expect(
        nextBtn().onPressed,
        isNull,
        reason: '无效手机号，按钮应该 disabled',
      );
      final allText = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data ?? '')
          .toList();
      expect(
        allText.any((s) => s.contains('格式不对')),
        isTrue,
        reason: '应该显示手机号格式错误的提示',
      );
    },
  );

  testWidgets(
    'setup 第一步: 重复手机号 → 按钮 disabled + 显示错误',
    (tester) async {
      await _pumpSetup(tester);
      await _passConsent(tester);

      final userNameField = find.widgetWithText(TextField, '你的名字');

      await tester.enterText(userNameField, '小明');
      await tester.enterText(
        find.widgetWithText(TextField, '紧急联系人手机号 1'),
        _phone('1380013', '8000'),
      );
      // 添加第二个联系人
      await tester.tap(find.text('+ 添加另一个联系人'));
      await tester.pumpAndSettle();
      // 填相同的手机号
      await tester.enterText(
        find.widgetWithText(TextField, '紧急联系人手机号 2'),
        _phone('1380013', '8000'),
      );
      await tester.pumpAndSettle();

      final nextFinder = find.widgetWithText(ElevatedButton, '下一步 →');
      ElevatedButton nextBtn() => tester.widget(nextFinder);
      expect(
        nextBtn().onPressed,
        isNull,
        reason: '重复手机号，按钮应该 disabled',
      );

      final allText = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data ?? '')
          .toList();
      expect(
        allText.any((s) => s.contains('重复')),
        isTrue,
        reason: '应该显示手机号重复的提示',
      );
    },
  );

  testWidgets(
    'setup 第一步: 名字为空 → 按钮 disabled + 显示提示',
    (tester) async {
      await _pumpSetup(tester);
      await _passConsent(tester);

      final phoneField = find.widgetWithText(TextField, '紧急联系人手机号 1');
      await tester.enterText(phoneField, _phone('1380013', '8000'));
      await tester.pumpAndSettle();

      final nextFinder = find.widgetWithText(ElevatedButton, '下一步 →');
      ElevatedButton nextBtn() => tester.widget(nextFinder);
      expect(
        nextBtn().onPressed,
        isNull,
        reason: '名字为空，按钮应该 disabled',
      );

      final allText = find
          .byType(Text)
          .evaluate()
          .map((e) => (e.widget as Text).data ?? '')
          .toList();
      expect(
        allText.any((s) => s.contains('名字')),
        isTrue,
        reason: '应该显示"请填写你的名字"提示',
      );
    },
  );
}
