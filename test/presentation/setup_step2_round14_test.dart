// 验证 setup 第 2 步：药物列表（v0.6：多药物 + 剂量 + 时间）
//
// 1.1.0 round 4 (emotion-first refactor): 联系人表单整摘, 走下一步前
// 只填名字。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_page.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/core/data/services/notification_service.dart';

class _NoopNotificationService extends NotificationService {}

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
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('zh'),
            home: SetupPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // P0-6: 跳过 consent 步(法律同意)
      // v0.27 R83: consent step 加了第 4 个 checkbox (年龄严正声明)
      // v0.31.1 R103: 加第 5 个 (医学免责声明) + 1 全部同意 master = 6 total
      //   跳过 index 0 全部同意 master, 勾 1-5 单独
      for (var i = 1; i < 6; i++) {
        await tester.tap(find.byType(Checkbox).at(i));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.widgetWithText(FilledButton, '开始设置'));
      await tester.pumpAndSettle();

      // 走到第 2 步 (round 4: 联系人表单已摘, 只填名字)
      await tester.enterText(
        find.widgetWithText(TextField, '您的名字（选填）'),
        '小明',
      );
      await tester.pumpAndSettle();

      // 1.1.0 round 4: 联系人表单整摘, step 1 只剩姓名 TextField
      final step1Checkboxes = find.byType(Checkbox);
      expect(
        step1Checkboxes,
        findsNothing,
        reason: 'step 1 只有姓名输入, 无任何 Checkbox',
      );

      final nextFinder = find.widgetWithText(FilledButton, '下一步 →');
      expect(nextFinder, findsOneWidget);
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();

      // 验证 step 2 标题
      expect(
        find.text('您常吃什么药？'),
        findsOneWidget,
        reason: '应该看到药名问题的标题',
      );

      // 初始：应该有"+ 添加药物"按钮
      expect(
        find.text('+ 添加药物'),
        findsOneWidget,
        reason: '应该看到"+ 添加药物"按钮',
      );

      // 顶部标题 (P0-6:加 consent 步后是 4 步流程)
      // 用 textContaining 因为可能中文字符不完全一致
      // v0.26 round 57 spzh: 半角 / 改全角 ／ (中文标点规范化)
      expect(
        find.textContaining('步 ／ 共'),
        findsOneWidget,
        reason: '顶部应该显示"第 X 步 ／ 共 X 步" (P0-6 加 consent 步后是 4 步)',
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
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('zh'),
            home: SetupPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // P0-6: 跳过 consent 步(法律同意)
      // v0.27 R83: consent step 加了第 4 个 checkbox (年龄严正声明)
      // v0.31.1 R103: 加第 5 个 (医学免责声明) + 1 全部同意 master = 6 total
      //   跳过 index 0 全部同意 master, 勾 1-5 单独
      for (var i = 1; i < 6; i++) {
        await tester.tap(find.byType(Checkbox).at(i));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.widgetWithText(FilledButton, '开始设置'));
      await tester.pumpAndSettle();

      // 走到第 2 步 (round 4: 联系人表单已摘, 只填名字)
      await tester.enterText(
        find.widgetWithText(TextField, '您的名字（选填）'),
        '小明',
      );
      await tester.pumpAndSettle();
      // 1.1.0 round 4: 联系人表单整摘, step 1 只剩姓名 TextField
      final step1Checkboxes = find.byType(Checkbox);
      expect(
        step1Checkboxes,
        findsNothing,
        reason: 'step 1 只有姓名输入, 无任何 Checkbox',
      );
      await tester.tap(
        find.widgetWithText(FilledButton, '下一步 →'),
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
