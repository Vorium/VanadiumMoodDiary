// v0.18 round 14 (P0-8) PressFeedback wrapper 测试
//
// 验证:
// 1. 默认 scale = 1.0 (未按下)
// 2. 按下 → AnimatedScale scale 变成 0.97
// 3. 抬起 → 回到 1.0
// 4. onTap 触发回调
// 5. prefers-reduced-motion 时 scale 反馈消失(duration=0)
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap({required Widget child, bool reduced = false}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('默认 scale = 1.0', (tester) async {
    await tester.pumpWidget(
      wrap(
        child: const PressFeedback(
          child: SizedBox(width: 100, height: 50, key: ValueKey('btn')),
        ),
      ),
    );
    final scale = tester.widget<AnimatedScale>(
      find.descendant(
        of: find.byType(PressFeedback),
        matching: find.byType(AnimatedScale),
      ),
    );
    expect(scale.scale, 1.0);
  });

  testWidgets('P0-8: 按下 → scale 变 0.97', (tester) async {
    int tapCount = 0;
    await tester.pumpWidget(
      wrap(
        child: PressFeedback(
          onTap: () => tapCount++,
          child: const SizedBox(width: 100, height: 50),
        ),
      ),
    );

    // 按下
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(PressFeedback)));
    await tester.pump(const Duration(milliseconds: 50));

    final scale = tester.widget<AnimatedScale>(
      find.descendant(
        of: find.byType(PressFeedback),
        matching: find.byType(AnimatedScale),
      ),
    );
    expect(scale.scale, 0.97);

    // 抬起
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 50));

    final scaleAfter = tester.widget<AnimatedScale>(
      find.descendant(
        of: find.byType(PressFeedback),
        matching: find.byType(AnimatedScale),
      ),
    );
    expect(scaleAfter.scale, 1.0);
    expect(tapCount, 1, reason: 'onTap 应该被调用 1 次');
  });

  testWidgets('P0-8: tap → onTap 触发', (tester) async {
    int tapCount = 0;
    await tester.pumpWidget(
      wrap(
        child: PressFeedback(
          onTap: () => tapCount++,
          child: const Text('press me'),
        ),
      ),
    );
    await tester.tap(find.byType(PressFeedback));
    await tester.pump();
    expect(tapCount, 1);
  });

  testWidgets('P0-7 + P0-8: reduce motion → tap 仍然 work,duration 0',
      (tester) async {
    int tapCount = 0;
    await tester.pumpWidget(
      wrap(
        child: PressFeedback(
          onTap: () => tapCount++,
          child: const SizedBox(width: 100, height: 50),
        ),
        reduced: true,
      ),
    );

    // reduce motion 模式下,scale 反馈瞬时完成,onTap 仍正常
    final scale = tester.widget<AnimatedScale>(
      find.descendant(
        of: find.byType(PressFeedback),
        matching: find.byType(AnimatedScale),
      ),
    );
    // duration 是 0 (Motion.duration 在 reduce motion 时返 Duration.zero)
    expect(scale.duration, Duration.zero);

    await tester.tap(find.byType(PressFeedback));
    await tester.pump();
    expect(tapCount, 1);
  });

  testWidgets('onTap = null → 按下不报错', (tester) async {
    await tester.pumpWidget(
      wrap(
        child: const PressFeedback(
          child: SizedBox(width: 100, height: 50),
        ),
      ),
    );
    // 单纯按下抬起,不触发 onTap,不报错
    final gesture =
        await tester.startGesture(tester.getCenter(find.byType(PressFeedback)));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
