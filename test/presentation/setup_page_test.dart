// 验证 setup_page 第一步"下一步"按钮的修复 + 手机号格式校验：
// - 初始 disabled
// - 输入名字 + 有效手机号后 enabled
// - 手机号格式无效 / 重复 / 全空 → 按钮 disabled，且显示对应错误
// - 点击后进入第二步
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/l10n/strings.dart';
import 'package:chroniccare/presentation/pages/setup/setup_page.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/data/services/notification_service.dart';

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
      child: const MaterialApp(home: SetupPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'setup 第一步: 初始 disabled, 输入有效手机号后 enabled, 点击进入 step 2',
    (tester) async {
      await _pumpSetup(tester);

      expect(find.text(Strings.setupHello), findsOneWidget);

      final nextFinder = find.widgetWithText(ElevatedButton, Strings.setupNext);
      expect(nextFinder, findsOneWidget);

      ElevatedButton nextBtn() => tester.widget(nextFinder);

      // 1) 初始 disabled
      expect(
        nextBtn().onPressed,
        isNull,
        reason: '所有 TextField 都空时，按钮应该 disabled',
      );

      // 用 labelText 找字段
      final userNameField = find.widgetWithText(TextField, Strings.setupName);
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

      // 4) 点击进入 step 2
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();
      expect(find.text('你常吃什么药？'), findsOneWidget);
      expect(find.text(Strings.setupStep(2, 3)), findsOneWidget);
    },
  );

  testWidgets(
    'setup 第一步: 手机号格式无效 → 按钮 disabled + 显示错误',
    (tester) async {
      await _pumpSetup(tester);

      final userNameField = find.widgetWithText(TextField, Strings.setupName);
      final phoneField = find.widgetWithText(TextField, '紧急联系人手机号 1');
      final nextFinder = find.widgetWithText(ElevatedButton, Strings.setupNext);
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

      final userNameField = find.widgetWithText(TextField, Strings.setupName);

      await tester.enterText(userNameField, '小明');
      await tester.enterText(
        find.widgetWithText(TextField, '紧急联系人手机号 1'),
        _phone('1380013', '8000'),
      );
      // 添加第二个联系人
      await tester.tap(find.text(Strings.setupAddContact));
      await tester.pumpAndSettle();
      // 填相同的手机号
      await tester.enterText(
        find.widgetWithText(TextField, '紧急联系人手机号 2'),
        _phone('1380013', '8000'),
      );
      await tester.pumpAndSettle();

      final nextFinder = find.widgetWithText(ElevatedButton, Strings.setupNext);
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

      final phoneField = find.widgetWithText(TextField, '紧急联系人手机号 1');
      await tester.enterText(phoneField, _phone('1380013', '8000'));
      await tester.pumpAndSettle();

      final nextFinder = find.widgetWithText(ElevatedButton, Strings.setupNext);
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
