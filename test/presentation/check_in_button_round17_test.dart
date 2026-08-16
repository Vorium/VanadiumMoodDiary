// v0.17 round 1 (emil 动效) test
//
// 覆盖：
// 1. AppTokens 动画 token（duration + curve 4 个）存在
// 2. CheckInButton 状态切换时背景色 + 文字过渡（AnimatedContainer + AnimatedSwitcher）
// 3. streak 数字 tween 递增（TweenAnimationBuilder）
// 4. vent 空态有 fade + scale 入场动画
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/domain/repositories/vent_repository.dart';
import 'package:chroniccare/presentation/widgets/check_in_button.dart';
import 'package:chroniccare/presentation/pages/vent/vent_list_page.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _EmptyVentRepo implements VentRepository {
  @override
  Stream<List<VentEntryEntity>> watchAll() => Stream.value(const []);

  @override
  Future<VentEntryEntity?> getById(int id) async => null;

  @override
  Future<int> add({
    String? text,
    String? audioPath,
    int? audioDurationSec,
    int? audioSizeBytes,
    String? tagsJson,
    DateTime? at,
  }) async =>
      0;

  @override
  Future<bool> delete(int id) async => true;

  @override
  Future<int> restore(VentEntryEntity entry) async => 0;

  // v0.28 R82.5 (法务 Q7b 必改, PIPL §47)
  @override
  Future<int> deleteAll() async => 0;
}

Widget _wrapButton({
  required bool isChecked,
  required int streakDays,
  VoidCallback? onPressed,
}) {
  return MaterialApp(
    theme: ThemeData.light(),
    // v0.17 round 14 (P2-12): 加 localizations delegates 让
    // homeStreak ARB 在 test 里可用
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('zh'),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 400,
          child: CheckInButton(
            isChecked: isChecked,
            streakDays: streakDays,
            isLoading: false,
            onPressed: onPressed ?? () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('AppTokens 动画 token（v0.17 round 1 / A1）', () {
    test('durFast / durNormal / durSlow 存在且 ms 正确', () {
      expect(AppTokens.durFast.inMilliseconds, 200);
      // v0.31 R4 (Apple Health redesign · Task 1.4): Apple 紧凑调档
      // durNormal 300→250, durSlow 500→400 (durPress 160→100 见 lock-in)
      expect(AppTokens.durNormal.inMilliseconds, 250);
      expect(AppTokens.durSlow.inMilliseconds, 400);
    });

    test(
        'curveStandard / curveDecelerate / curveAccelerate / curveDelight 都是 Curve',
        () {
      expect(AppTokens.curveStandard, isA<Curve>());
      expect(AppTokens.curveDecelerate, isA<Curve>());
      expect(AppTokens.curveAccelerate, isA<Curve>());
      expect(AppTokens.curveDelight, isA<Curve>());
    });
  });

  group('CheckInButton 状态过渡（v0.17 round 1 / A3）', () {
    testWidgets('未打卡 → 已打卡 文字切换（AnimatedSwitcher）', (tester) async {
      await tester.pumpWidget(_wrapButton(isChecked: false, streakDays: 5));
      await tester.pumpAndSettle();
      expect(find.text('我今天吃了药'), findsOneWidget);

      // 切到 checked
      await tester.pumpWidget(_wrapButton(isChecked: true, streakDays: 6));
      await tester.pump(); // 启动动画
      // 动画过程是 2 个 widget 共存,所以 find at any frame
      // 等动画结束
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('今天已打卡 ✓'), findsOneWidget);
      expect(find.text('我今天吃了药'), findsNothing);
    });

    testWidgets('文字 + 颜色同时存在（不闪烁）', (tester) async {
      await tester.pumpWidget(_wrapButton(isChecked: false, streakDays: 1));
      await tester.pumpAndSettle();
      // 初始 + 切换后都应该能 find text
      expect(find.text('我今天吃了药'), findsOneWidget);
    });
  });

  group('streak 数字 TweenAnimationBuilder（v0.17 round 1 / A6）', () {
    testWidgets('streak = 0 → 7 数字平滑递增', (tester) async {
      await tester.pumpWidget(_wrapButton(isChecked: false, streakDays: 0));
      await tester.pumpAndSettle();
      // tween 0 → 0,数字 = 0
      expect(find.text('已坚持 0 天'), findsOneWidget);

      // 切到 7 (TweenAnimationBuilder 重新触发)
      await tester.pumpWidget(_wrapButton(isChecked: false, streakDays: 7));
      // 让 tween 跑完
      await tester.pumpAndSettle(const Duration(seconds: 1));
      // 终态 = 7
      expect(find.text('已坚持 7 天'), findsOneWidget);
    });

    testWidgets('streak 从大到小 tween 不会变成负数', (tester) async {
      await tester.pumpWidget(_wrapButton(isChecked: false, streakDays: 30));
      await tester.pumpAndSettle();
      expect(find.text('已坚持 30 天'), findsOneWidget);

      await tester.pumpWidget(_wrapButton(isChecked: false, streakDays: 5));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('已坚持 5 天'), findsOneWidget);
    });
  });

  group('vent 空态入场动画（v0.17 round 1 / A8）', () {
    testWidgets('空态显示"TweenAnimationBuilder fade + scale"', (tester) async {
      // 单独测 _EmptyState: 通过 vent_list_page 注入 empty repo
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ventRepositoryProvider.overrideWith((ref) => _EmptyVentRepo()),
          ],
          child: MaterialApp(
            theme: ThemeData.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            home: const VentListPage(),
          ),
        ),
      );
      await tester.pump(); // 启动 TweenAnimationBuilder
      // 早期帧 opacity < 1 (tween 还没到 1)
      // 但 pumpAndSettle 后 opacity = 1
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('树洞还是空的'), findsOneWidget);
      expect(find.text('写第一句'), findsOneWidget);
    });
  });

  // v0.31 round 6 (Apple Health redesign · Phase 2 Task 2.2): CheckInButton 重写
  // 3 个新 test 覆盖 Apple Health 巨型 pill:
  // - 完成态切到 check icon + spring curve 庆祝
  // - 高度 64 (buttonHeight 50 + 14)
  // - 圆角 32 (硬编码全圆角)
  group('CheckInButton Apple Health pill (v0.31 R6 Task 2.2)', () {
    testWidgets('完成态切到 check icon + spring curve 庆祝', (tester) async {
      await tester.pumpWidget(_wrapButton(isChecked: false, streakDays: 0));
      await tester.pumpAndSettle();
      // 未打卡 = medicine icon, 不显示 check
      expect(find.byIcon(Icons.medication_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      // 切到已打卡
      await tester.pumpWidget(_wrapButton(isChecked: true, streakDays: 1));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      // 已打卡 = check icon, medicine icon 隐藏
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.medication_rounded), findsNothing);
      expect(find.text('今天已打卡 ✓'), findsOneWidget);

      // 验证完成态切用 spring curve (庆祝 scale 0.95→1)
      // 在 test 环境无 prefers-reduced-motion, Motion.curve 直接返 base
      final switcher =
          tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
      expect(switcher.switchInCurve, AppTokens.curveSpring);
    });

    testWidgets('高度 64 (buttonHeight 50 + 14, Apple Health pill)',
        (tester) async {
      await tester.pumpWidget(_wrapButton(isChecked: false, streakDays: 0));
      await tester.pumpAndSettle();
      // v0.31 R6: 64 = buttonHeight 50 + 14 (硬编码 + 注释, 跟 buttonHeight 50 不同档)
      final size = tester.getSize(find.byType(CheckInButton));
      expect(size.height, 64);
    });

    testWidgets('圆角 32 (硬编码全圆角, Apple Health pill)', (tester) async {
      await tester.pumpWidget(_wrapButton(isChecked: false, streakDays: 0));
      await tester.pumpAndSettle();
      // v0.31 R6: 32 = 硬编码全圆角 (跟 radiusLargeButton 22 / radiusButton 14 不同档)
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(32));
    });
  });

  // R113 (BUG 6): _EntrySpring 是全 lib 唯一绕过 Motion wrapper 的动画
  // (spring 物理模型进场无条件跑)。修后: prefers-reduced-motion →
  // didChangeDependencies 直接把 controller 跳到终态 (scale 1.0 / opacity 1.0)。
  group('R113 (BUG 6) _EntrySpring prefers-reduced-motion', () {
    Widget wrap({required bool reduced}) {
      return MaterialApp(
        theme: ThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: CheckInButton(
                  isChecked: false,
                  streakDays: 0,
                  isLoading: false,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('reduce motion → 首帧即终态 (scale 1.0 / opacity 1.0)',
        (tester) async {
      await tester.pumpWidget(wrap(reduced: true));
      await tester.pump();

      final transform = tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(CheckInButton),
              matching: find.byType(Transform),
            )
            .first,
      );
      // Matrix4 storage[0] = m00 = x-scale (getMaxScaleOnAxis 在
      // diagonal matrix 上实测误报 1.0, 直接读矩阵元素)
      expect(
        transform.transform.storage[0],
        1.0,
        reason: '修前 spring 从 0.95 起步, reduce-motion 用户仍看到弹跳进场',
      );
      final opacity = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byType(CheckInButton),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 1.0);
    });

    testWidgets('无 reduce motion → 进场从 0.95 起步 (回归守卫)', (tester) async {
      await tester.pumpWidget(wrap(reduced: false));
      await tester.pump();

      final transform = tester.widget<Transform>(
        find
            .descendant(
              of: find.byType(CheckInButton),
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(
        transform.transform.storage[0],
        lessThan(1.0),
        reason: '正常模式 spring 从 0.95 起步渐进 1.0 (防过度修复)',
      );
    });
  });
}
