// 验证 setup_page 第一步"下一步"按钮的修复:
// - 初始 disabled
// - 输入名字后 enabled
// - 名字为空 → 按钮 disabled, 且显示对应错误
// - 点击后进入第二步
//
// 1.1.0 round 4 (emotion-first refactor): 联系人表单整摘, 原手机号格式 /
// 重复校验 case 删除, 只留名字校验路径。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_page.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/core/data/services/notification_service.dart';

class _NoopNotificationService extends NotificationService {
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
///
/// v0.27 R83 (Q11a 律师审核 ⚠️ 修复): consent step 第 4 个 checkbox 是
/// `setupLegalAgeAttestation` (年龄严正声明).
/// v0.31.1 R103: 加第 5 个 (医学免责声明) + 1 全部同意 master = 6 total.
Future<void> _passConsent(WidgetTester tester) async {
  // 勾 5 单独 consent (R103 加医学免责后), 跳过 index 0 全部同意 master
  final checkboxes = find.byType(Checkbox);
  expect(
    checkboxes,
    findsNWidgets(6),
    reason: 'P0-6 + v0.31.1 R103: setup step 0 (consent) 应该有 6 个 Checkbox (1 全部同意 + 5 单独)',
  );
  for (var i = 1; i < 6; i++) {
    await tester.tap(checkboxes.at(i));
    await tester.pumpAndSettle();
  }
  // 点"开始设置"
  final startBtn = find.widgetWithText(FilledButton, '开始设置');
  expect(startBtn, findsOneWidget);
  await tester.tap(startBtn);
  await tester.pumpAndSettle();
  // 现在应该到 step 1 (welcome) — "您好,我是慢病管家"
  expect(
    find.text('您好，我是慢病管家'),
    findsOneWidget,
  );

  // 1.1.0 round 4: 联系人表单整摘, step 1 只剩姓名 TextField
  final step1Checkboxes = find.byType(Checkbox);
  expect(
    step1Checkboxes,
    findsNothing,
    reason: 'step 1 只有姓名输入, 无任何 Checkbox',
  );
}

void main() {
  testWidgets(
    'setup 第一步: 初始 disabled, 输入名字后 enabled, 点击进入 step 2',
    (tester) async {
      await _pumpSetup(tester);
      await _passConsent(tester);

      expect(find.text('您好，我是慢病管家'), findsOneWidget);

      final nextFinder = find.widgetWithText(FilledButton, '下一步 →');
      expect(nextFinder, findsOneWidget);

      FilledButton nextBtn() => tester.widget(nextFinder);

      // 1) 初始 disabled
      expect(
        nextBtn().onPressed,
        isNull,
        reason: '名字为空时，按钮应该 disabled',
      );

      // 用 labelText 找字段
      final userNameField = find.widgetWithText(TextField, '您的名字（选填）');
      expect(userNameField, findsOneWidget);

      // 2) 填用户名字 → 按钮 enabled
      await tester.enterText(userNameField, '小明');
      await tester.pumpAndSettle();
      expect(
        nextBtn().onPressed,
        isNotNull,
        reason: '填了名字后, 按钮 enabled',
      );

      // 3) 点击进入 step 2 (P0-6 后是 medication = 第 2 步,共 4 步)
      await tester.tap(nextFinder);
      await tester.pumpAndSettle();
      expect(find.text('您常吃什么药？'), findsOneWidget);
      expect(
        find.textContaining('步 ／ 共'),
        findsOneWidget,
        reason: 'P0-6: 顶部应该显示"第 X 步 ／ 共 X 步" (4 步流程, spzh v0.26 半角→全角规范化)',
      );
    },
  );

  testWidgets(
    'setup 第一步: 名字为空 → 按钮 disabled + 显示提示',
    (tester) async {
      await _pumpSetup(tester);
      await _passConsent(tester);

      final nextFinder = find.widgetWithText(FilledButton, '下一步 →');
      FilledButton nextBtn() => tester.widget(nextFinder);
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
        reason: '应该显示"请输入你的名字"提示',
      );
    },
  );
}
