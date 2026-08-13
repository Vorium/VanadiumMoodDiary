// v0.31 round 10 (Apple Health redesign · Phase 3 Task 3.2):
// SetupPage 4 步重设 集成 + 进度条 + section + 底部按钮 测试
//
// 目标 (spec §5.2):
// - 顶部 SetupProgressBar 4 段 hairline (currentStep 0-3 控制高亮)
// - 每个 step 顶部 SetupStepHeader 28pt 大标题 + 15pt 副标题
// - step 内容走 AppleListSection 风格 (圆角 16 容器 + hairline 分隔)
// - 底部按钮 PrimaryButton isFullWidth: true
//
// 测试 4 项:
// 1. 集成 (integration) — 4 step 状态机 完整走 0→1
// 2. 进度条 (progress bar) — SetupProgressBar 渲染 4 段, currentStep 控制高亮
// 3. section (section) — step 0 渲染 AppleListSection 容器
// 4. 底部按钮 (bottom button) — step 0 底部 PrimaryButton isFullWidth: true
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_page.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

// v0.32 round 8 (R112 卫生): 删 scheduleDailyReminder 死 fake override —
// R108 后该方法迁到 NotificationDelegate, 这里的 noop 不再 override 任何
// 基类成员 (漏网 0 用途死代码)。
class _NoopNotificationService extends NotificationService {}

/// 最小 GoRouter 包裹: PageScaffold 用 GoRouter.of(context).canPop() 决定
/// 是否显示返回按钮。测试只需在 context 里塞一个 GoRouter 实例即可。
Widget _routerWrap(Widget child) {
  final router = GoRouter(
    initialLocation: '/setup',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _DummyPage()),
      GoRoute(path: '/setup', builder: (_, __) => child),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

class _DummyPage extends StatelessWidget {
  const _DummyPage();
  @override
  Widget build(BuildContext context) => const Scaffold();
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
      child: _routerWrap(const SetupPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('SetupProgressBar (v0.31 R10)', () {
    testWidgets('currentStep=2 → 第 0/1/2 段走 activeColor, 第 3 段走 inactiveColor',
        (tester) async {
      late Color activeColor;
      late Color inactiveColor;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                activeColor = AppTokens.primaryColor(context);
                inactiveColor = AppTokens.borderColor(context);
                return const SetupProgressBar(currentStep: 2, totalSteps: 4);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 找所有 SetupProgressBar 下的 Container
      // 4 segment 容器 (BoxDecoration)
      final containerWidgets = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(SetupProgressBar),
              matching: find.byType(Container),
            ),
          )
          .toList();
      final segments = containerWidgets
          .where((c) => c.decoration is BoxDecoration)
          .toList();
      expect(segments.length, 4,
          reason: 'SetupProgressBar 渲染 4 segment 容器 (有 BoxDecoration)',);

      // currentStep=2 → i<=2 (3 个) 走 activeColor, 1 个走 inactiveColor
      final activeCount = segments
          .where((c) => (c.decoration as BoxDecoration).color == activeColor)
          .length;
      final inactiveCount = segments
          .where((c) => (c.decoration as BoxDecoration).color == inactiveColor)
          .length;
      expect(activeCount, 3, reason: 'currentStep=2 → 0/1/2 段 active');
      expect(inactiveCount, 1, reason: 'currentStep=2 → 3 段 inactive');
    });

    testWidgets('currentStep=0 → 仅第 0 段 active, 第 1/2/3 段 inactive',
        (tester) async {
      late Color activeColor;
      late Color inactiveColor;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                activeColor = AppTokens.primaryColor(context);
                inactiveColor = AppTokens.borderColor(context);
                return const SetupProgressBar(currentStep: 0, totalSteps: 4);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final containerWidgets = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(SetupProgressBar),
              matching: find.byType(Container),
            ),
          )
          .toList();
      final segments = containerWidgets
          .where((c) => c.decoration is BoxDecoration)
          .toList();
      expect(segments.length, 4);

      final activeCount = segments
          .where((c) => (c.decoration as BoxDecoration).color == activeColor)
          .length;
      final inactiveCount = segments
          .where((c) => (c.decoration as BoxDecoration).color == inactiveColor)
          .length;
      expect(activeCount, 1, reason: 'currentStep=0 → 仅第 0 段 active');
      expect(inactiveCount, 3, reason: 'currentStep=0 → 1/2/3 段 inactive');
    });
  });

  group('SetupPage 集成 + AppleListSection + 底部 PrimaryButton (v0.31 R10)',
      () {
    testWidgets('集成: 4 step 状态机 step 0 → step 1 (consent→welcome)',
        (tester) async {
      await _pumpSetup(tester);

      // ===== 初始 step 0 (consent) =====
      expect(find.byType(SetupProgressBar), findsOneWidget);
      // "开始设置" PrimaryButton 初始 disabled (5 个 checkbox 全 unchecked)
      final startBtnFinder = find.text('开始设置');
      expect(startBtnFinder, findsOneWidget);

      // 6 个 checkbox: 第 0 个是 R104 "全部同意" (一次勾选 5 个全部勾选状态)
      // 单独点第 0 个 = 一次全勾, 然后 1-5 已经是 true 不要再 tap (会反 toggle)
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(6));
      await tester.tap(checkboxes.at(0));
      await tester.pumpAndSettle();

      // 点 "开始设置" → step 1
      await tester.tap(startBtnFinder);
      await tester.pumpAndSettle();

      // ===== step 1 (welcome) =====
      // SetupStepHeader 标题 (大标题 28pt)
      expect(find.text('您好，我是慢病管家'), findsOneWidget,
          reason: 'spec §5.2: step 1 大标题 28pt',);
      // SetupStepHeader 副标题 15pt (走 setupIntro)
      expect(find.byType(SetupStepHeader), findsOneWidget,
          reason: 'spec §5.2: 顶部 SetupStepHeader',);
      // 进度条 currentStep=1
      final progressBar = tester.widget<SetupProgressBar>(
        find.byType(SetupProgressBar),
      );
      expect(progressBar.currentStep, 1);

      // step 1: 姓名 TextField + 至少 1 个 AppleListSection
      expect(find.byType(AppleListSection), findsAtLeastNWidgets(1));
    });

    testWidgets('section: step 0 顶部 SetupStepHeader (28pt + 15pt)',
        (tester) async {
      await _pumpSetup(tester);

      // step 0 consent: SetupStepHeader
      expect(find.byType(SetupStepHeader), findsOneWidget,
          reason: 'step 0 顶部 SetupStepHeader (大标题 28pt)',);
    });

    testWidgets('section: step 0 consent 渲染 AppleListSection 容器 (2 段)',
        (tester) async {
      await _pumpSetup(tester);

      // step 0: 全部同意 section + 单独同意 section = 2 个 AppleListSection
      expect(find.byType(AppleListSection), findsNWidgets(2),
          reason: 'step 0: "全部同意" + "单独同意" = 2 AppleListSection',);
    });

    testWidgets('底部按钮: step 0 底部 PrimaryButton isFullWidth: true',
        (tester) async {
      await _pumpSetup(tester);

      // 找 "开始设置" 文字 ancestor 的 PrimaryButton
      final startBtnFinder = find.text('开始设置');
      expect(startBtnFinder, findsOneWidget);

      // PrimaryButton.isFullWidth 默认 true (跟 spec 一致)
      final primaryBtn = tester.widget<PrimaryButton>(
        find.ancestor(
          of: startBtnFinder,
          matching: find.byType(PrimaryButton),
        ),
      );
      expect(primaryBtn.isFullWidth, isTrue,
          reason: 'spec §5.2: 底部 PrimaryButton isFullWidth: true',);
    });
  });
}
