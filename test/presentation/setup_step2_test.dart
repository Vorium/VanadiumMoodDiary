// 验证 setup 第 2 步：药物列表（v0.6：多药物 + 剂量 + 时间）
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

String _phone(String p, String s) => '$p$s';

void main() {
  testWidgets(
    'setup 第 2 步: 显示药物列表（可添加、可配时间）',
    (tester) async {
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

      // 走到第 2 步
      await tester.enterText(
        find.widgetWithText(TextField, Strings.setupName),
        '小明',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '联系人 1 姓名'),
        '妈妈',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '紧急联系人手机号 1'),
        _phone('1380013', '8000'),
      );
      await tester.pumpAndSettle();

      final nextFinder = find.widgetWithText(ElevatedButton, Strings.setupNext);
      expect(nextFinder, findsOneWidget);
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();

      // 验证 step 2 标题
      expect(
        find.text('你常吃什么药？'),
        findsOneWidget,
        reason: '应该看到药名问题的标题',
      );

      // 初始：应该有"+ 添加药物"按钮
      expect(
        find.text('+ 添加药物'),
        findsOneWidget,
        reason: '应该看到"+ 添加药物"按钮',
      );

      // 顶部标题
      expect(
        find.text(Strings.setupStep(2, 3)),
        findsOneWidget,
        reason: '顶部应该显示"第 2 步 / 共 3 步"',
      );

      // 上一步按钮
      expect(find.text('← 上一步'), findsOneWidget);
    },
  );

  testWidgets(
    'setup 第 2 步: 添加药物后能看到药物卡片',
    (tester) async {
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

      // 走到第 2 步
      await tester.enterText(
        find.widgetWithText(TextField, Strings.setupName),
        '小明',
      );
      await tester.enterText(
        find.widgetWithText(TextField, '紧急联系人手机号 1'),
        _phone('1380013', '8000'),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(ElevatedButton, Strings.setupNext),
      );
      await tester.pumpAndSettle();

      // 添加一个药物
      await tester.tap(find.text('+ 添加药物'));
      await tester.pumpAndSettle();

      // 应该看到 "药物 1" 标签
      expect(
        find.text('药物 1'),
        findsOneWidget,
        reason: '添加药物后应该看到药物编号',
      );

      // 应该有药名 TextField
      expect(
        find.widgetWithText(TextField, '药名'),
        findsOneWidget,
      );

      // 应该有剂量 TextField
      expect(
        find.widgetWithText(TextField, '剂量'),
        findsOneWidget,
      );

      // 应该有时间 chip 区域
      expect(
        find.text('加时间'),
        findsOneWidget,
        reason: '应该看到"加时间"按钮',
      );
    },
  );
}
