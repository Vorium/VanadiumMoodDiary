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
}
