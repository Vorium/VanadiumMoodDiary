// v0.30 round 95 (sub-spec 2 task 10 A4): setup_step_medication
// PrimaryButton + Stack hack → PressFeedback + LoadingSpinner widget test
//
// **问题 (R92 emil P1-2.1.7)**: PrimaryButton 包在 110×44 narrow SizedBox +
// Stack (alignment: center) + IgnorePointer + LoadingSpinner 叠加 — hacky
// 视觉 hack, 数字 / 间距 / 对齐都不自然, 难维护。
//
// **修法 (R95 task 10 A4)**: 改 PressFeedback (接管 onTap) + PrimaryButton
// (onPressed: null) + saving 态时 PrimaryButton child 是 LoadingSpinner。
// 跟 R18 emil P0-8 (按钮必须有 :active scale 反馈) 模式一致 + R17 模式
// 不再需要 SizedBox 强制 + Stack alignment hack。
//
// 3 case widget test:
// 1. saving=false: PressFeedback(接管 onTap) > PrimaryButton > Text("下一步")
// 2. saving=true: PressFeedback > PrimaryButton > LoadingSpinner (无 Text)
// 3. PressFeedback.onTap 触发 onFinish callback (saving=false 时)
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_step_medication.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void _setBigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

Widget _wrap({
  required bool saving,
  required VoidCallback onFinish,
  required VoidCallback onBack,
  required VoidCallback onAddMed,
  required VoidCallback onShowPresets,
  required ValueChanged<int> onRemoveMed,
  List<MedDraft> meds = const [],
}) {
  return MaterialApp(
    theme: ThemeData.light(),
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SetupStepMedication(
        meds: meds,
        saving: saving,
        onAddMed: onAddMed,
        onShowPresets: onShowPresets,
        onRemoveMed: onRemoveMed,
        onBack: onBack,
        onFinish: onFinish,
      ),
    ),
  );
}

void main() {
  testWidgets('R95 A4 fix 1: saving=false → PressFeedback > PrimaryButton > Text("下一步")',
      (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap(
      saving: false,
      onFinish: () {},
      onBack: () {},
      onAddMed: () {},
      onShowPresets: () {},
      onRemoveMed: (_) {},
    ),);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 验证 PressFeedback 包 PrimaryButton (接管 onTap)
    expect(
      find.byType(PressFeedback),
      findsAtLeastNWidgets(1),
      reason: '应有 PressFeedback (saving 时包 PrimaryButton + 给 scale 反馈)',
    );
    expect(find.byType(PrimaryButton), findsAtLeastNWidgets(1));

    // saving=false: 应显示 "下一步 →" text, 不显示 LoadingSpinner
    expect(find.text('下一步 →'), findsOneWidget);
    expect(find.byType(LoadingSpinner), findsNothing);
  });

  testWidgets('R95 A4 fix 2: saving=true → LoadingSpinner 替代 Text', (tester) async {
    _setBigView(tester);
    await tester.pumpWidget(_wrap(
      saving: true,
      onFinish: () {},
      onBack: () {},
      onAddMed: () {},
      onShowPresets: () {},
      onRemoveMed: (_) {},
    ),);
    // 用 pump 而非 pumpAndSettle — LoadingSpinner 内部 Animation 持续运行
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // saving=true: 应显示 LoadingSpinner, 不显示 "下一步 →" text
    expect(find.byType(LoadingSpinner), findsAtLeastNWidgets(1));
    expect(find.text('下一步 →'), findsNothing);
  });

  testWidgets('R95 A4 fix 3: PressFeedback onTap 触发 onFinish', (tester) async {
    _setBigView(tester);
    var onFinishCalled = 0;
    await tester.pumpWidget(_wrap(
      saving: false,
      onFinish: () => onFinishCalled++,
      onBack: () {},
      onAddMed: () {},
      onShowPresets: () {},
      onRemoveMed: (_) {},
    ),);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 找 PressFeedback 包裹 PrimaryButton 的 widget, 点它
    final pressFeedbackFinder = find.byType(PressFeedback).last;
    expect(pressFeedbackFinder, findsOneWidget);
    await tester.tap(pressFeedbackFinder);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(
      onFinishCalled,
      1,
      reason: '点 PressFeedback 应触发 onFinish (R95 task 10 PressFeedback '
          '接管 onTap 替代 PrimaryButton 自带 onPressed)',
    );
  });
}
