// v0.32 round 8 (R111 EM-14 fix): disabled 按钮不应有 press scale + haptic 假反馈
//
// 背景: PressFeedback 无 disabled 感知 — 禁用态按钮按下仍 scale 0.97 +
// haptic, 给用户"能点"的假反馈。修: `enabled` 参数 (默认 true),
// false 时不做任何反馈 (child 原样渲染, 不接 Listener / GestureDetector)。
// PrimaryButton / CheckInButton 把自身 disabled 态传给 PressFeedback。
import 'package:chroniccare/presentation/widgets/check_in_button.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap({required Widget child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('v0.32 round 8 (R111 EM-14) — PressFeedback.enabled', () {
    testWidgets('enabled=false → 无 AnimatedScale (按下无 scale 反馈)',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          child: const PressFeedback(
            enabled: false,
            child: SizedBox(width: 100, height: 50),
          ),
        ),
      );
      expect(find.byType(AnimatedScale), findsNothing);

      // 按下抬起不报错 (child 原样, 无事件监听)
      final gesture = await tester
          .startGesture(tester.getCenter(find.byType(PressFeedback)));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('enabled=true (默认) → 按下有 scale 反馈 (行为不变)', (tester) async {
      await tester.pumpWidget(
        wrap(
          child: const PressFeedback(
            child: SizedBox(width: 100, height: 50),
          ),
        ),
      );
      expect(find.byType(AnimatedScale), findsOneWidget);
    });

    testWidgets('enabled=false + onTap 非空 → 不触发 onTap (无假交互)', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        wrap(
          child: PressFeedback(
            enabled: false,
            onTap: () => tapCount++,
            child: const SizedBox(width: 100, height: 50),
          ),
        ),
      );
      await tester.tap(find.byType(PressFeedback), warnIfMissed: false);
      await tester.pump();
      expect(tapCount, 0);
    });
  });

  group('v0.32 round 8 (R111 EM-14) — PrimaryButton disabled', () {
    testWidgets('onPressed=null → 无 AnimatedScale', (tester) async {
      await tester.pumpWidget(
        wrap(
          child: const PrimaryButton(
            onPressed: null,
            child: Text('提交'),
          ),
        ),
      );
      expect(find.byType(AnimatedScale), findsNothing);
    });

    testWidgets('onPressed 非空 → 有 AnimatedScale', (tester) async {
      await tester.pumpWidget(
        wrap(
          child: PrimaryButton(
            onPressed: () {},
            child: const Text('提交'),
          ),
        ),
      );
      expect(find.byType(AnimatedScale), findsOneWidget);
    });
  });

  group('v0.32 round 8 (R111 EM-14) — CheckInButton 完成/加载态', () {
    testWidgets('isChecked=true → 无 AnimatedScale', (tester) async {
      await tester.pumpWidget(
        wrap(
          child: CheckInButton(
            isChecked: true,
            streakDays: 3,
            onPressed: () {},
          ),
        ),
      );
      expect(find.byType(AnimatedScale), findsNothing);
    });

    testWidgets('isLoading=true → 无 AnimatedScale', (tester) async {
      await tester.pumpWidget(
        wrap(
          child: CheckInButton(
            isChecked: false,
            streakDays: 0,
            isLoading: true,
            onPressed: () {},
          ),
        ),
      );
      expect(find.byType(AnimatedScale), findsNothing);
    });

    testWidgets('可打卡态 → 有 AnimatedScale', (tester) async {
      await tester.pumpWidget(
        wrap(
          child: CheckInButton(
            isChecked: false,
            streakDays: 0,
            onPressed: () {},
          ),
        ),
      );
      expect(find.byType(AnimatedScale), findsOneWidget);
    });
  });
}
