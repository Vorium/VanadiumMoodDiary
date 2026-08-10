// v0.30 R108 (P1 home_page_state 拆 3 controller): 防回归测试
//
// R107 报告 P1-3: home_page_state 597L god class 拆 3 controller
// (HomeDeepLinkHandler / HomeCareEngineDispatcher / HomeCelebrationController)
// (4 视角共识: emil + spen + architecture + bottom-up)。
//
// 测试覆盖 (不依赖 widget 渲染, 纯文本/静态分析):
// 1. 3 controller 文件存在
// 2. 3 controller API surface (class + public method 存在)
// 3. home_page_state.dart 行数 < 500 (R108 修后从 597 → ~475L)
// 4. state class 不再含 _handleDeepLink / _fireCareEngine / _celebrationFor
//    / _runAfterCheckIn / _autofireMedicationCheckIn 等已抽方法
// 5. R108 注释落地 (3 controller 拆 + controllers/ 子目录)
// 6. 保留 P0#5 stagger clamp 改动 (跟 stagger_clamp_round108_test 互不冲突)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('3 controller 文件存在 (R108 P1 home_page_state 拆)', () {
    test('case 1: controllers/ 子目录 3 文件存在', () async {
      final files = [
        'lib/presentation/pages/home/controllers/home_deep_link_handler.dart',
        'lib/presentation/pages/home/controllers/home_care_engine_dispatcher.dart',
        'lib/presentation/pages/home/controllers/home_celebration_controller.dart',
      ];
      for (final f in files) {
        final exists = await File(f).exists();
        expect(
          exists,
          isTrue,
          reason: 'R108 拆 3 controller, $f 应该存在',
        );
      }
    });
  });

  group('3 controller API surface (R108 P1 home_page_state 拆)', () {
    late String deepLinkContent;
    late String careEngineContent;
    late String celebrationContent;

    setUpAll(() async {
      deepLinkContent = await File(
        'lib/presentation/pages/home/controllers/home_deep_link_handler.dart',
      ).readAsString();
      careEngineContent = await File(
        'lib/presentation/pages/home/controllers/home_care_engine_dispatcher.dart',
      ).readAsString();
      celebrationContent = await File(
        'lib/presentation/pages/home/controllers/home_celebration_controller.dart',
      ).readAsString();
    });

    test('case 2: HomeDeepLinkHandler class 存在 + 关键 method', () {
      expect(
        RegExp(r'class\s+HomeDeepLinkHandler').hasMatch(deepLinkContent),
        isTrue,
        reason: 'R108 应抽 HomeDeepLinkHandler class',
      );
      // 关键 method: inspect / autofireMedicationCheckIn / showMedicationHint /
      // scheduleRaceTimer / dispose
      for (final method in [
        'inspect',
        'autofireMedicationCheckIn',
        'showMedicationHint',
        'scheduleRaceTimer',
        'dispose',
      ]) {
        expect(
          RegExp('void\\s+$method\\(|Future<\\w+>\\s+$method\\(|\\w+\\s+$method\\(')
              .hasMatch(deepLinkContent),
          isTrue,
          reason: 'HomeDeepLinkHandler 应有 $method method',
        );
      }
    });

    test('case 3: HomeCareEngineDispatcher class 存在 + 关键 method', () {
      expect(
        RegExp(r'class\s+HomeCareEngineDispatcher').hasMatch(careEngineContent),
        isTrue,
        reason: 'R108 应抽 HomeCareEngineDispatcher class',
      );
      // 关键 method: runAfterCheckIn / fireCareEngine
      expect(
        RegExp(r'Future<void>\s+runAfterCheckIn').hasMatch(careEngineContent),
        isTrue,
        reason: 'HomeCareEngineDispatcher 应有 runAfterCheckIn',
      );
      expect(
        RegExp(r'Future<void>\s+fireCareEngine').hasMatch(careEngineContent),
        isTrue,
        reason: 'HomeCareEngineDispatcher 应有 fireCareEngine',
      );
    });

    test('case 4: HomeCelebrationController class 存在 + 关键 method', () {
      expect(
        RegExp(r'class\s+HomeCelebrationController').hasMatch(celebrationContent),
        isTrue,
        reason: 'R108 应抽 HomeCelebrationController class',
      );
      // 关键 method: show / pickStreakMessage / dispose
      expect(
        RegExp(r'void\s+show').hasMatch(celebrationContent),
        isTrue,
        reason: 'HomeCelebrationController 应有 show',
      );
      expect(
        RegExp(r'String\s+pickStreakMessage').hasMatch(celebrationContent),
        isTrue,
        reason: 'HomeCelebrationController 应有 pickStreakMessage',
      );
      expect(
        RegExp(r'void\s+dispose').hasMatch(celebrationContent),
        isTrue,
        reason: 'HomeCelebrationController 应有 dispose (cancel Timer)',
      );
    });
  });

  group('home_page_state.dart 行数 + 残留方法 (R108 P1 拆 防回退)', () {
    late String homePageStateContent;
    late int lineCount;

    setUpAll(() async {
      homePageStateContent = await File(
        'lib/presentation/pages/home/home_page_state.dart',
      ).readAsString();
      lineCount = homePageStateContent.split('\n').length;
    });

    test('case 5: home_page_state.dart 行数 < 500 (R108 拆后 ~475L)', () {
      // 修前 597L, 修后目标 < 500L (保留 build 180L + comment 60L + 业务 235L)
      expect(
        lineCount,
        lessThan(500),
        reason: 'R108 修后 home_page_state.dart 应 < 500L, 实际 ${lineCount}L',
      );
    });

    test('case 6: 不再含已抽出的 _handleDeepLink 业务 (只留 wrapper)', () {
      // _handleDeepLink 现在只剩 ~30L wrapper (inspect + 路由 + autofire)
      // 验证不再含 _autofireMedicationCheckIn 业务 (已抽到 controller)
      expect(
        homePageStateContent.contains('_autofireMedicationCheckIn'),
        isFalse,
        reason: '_autofireMedicationCheckIn 已抽到 HomeDeepLinkHandler',
      );
      // 验证不再含 _showMedicationHint (已抽)
      expect(
        RegExp(r'void\s+_showMedicationHint').hasMatch(homePageStateContent),
        isFalse,
        reason: '_showMedicationHint 已抽到 HomeDeepLinkHandler',
      );
    });

    test('case 7: 不再含 _runAfterCheckIn (已抽到 HomeCareEngineDispatcher)', () {
      expect(
        RegExp(r'Future<void>\s+_runAfterCheckIn').hasMatch(homePageStateContent),
        isFalse,
        reason: '_runAfterCheckIn 已抽到 HomeCareEngineDispatcher',
      );
    });

    test('case 8: 不再含 _fireCareEngine 业务 (已抽到 HomeCareEngineDispatcher)', () {
      expect(
        RegExp(r'Future<void>\s+_fireCareEngine').hasMatch(homePageStateContent),
        isFalse,
        reason: '_fireCareEngine 已抽到 HomeCareEngineDispatcher',
      );
    });

    test('case 9: 不再含 _celebrationFor (已抽到 HomeCelebrationController)', () {
      expect(
        RegExp(r'String\s+_celebrationFor').hasMatch(homePageStateContent),
        isFalse,
        reason: '_celebrationFor 已抽到 HomeCelebrationController.pickStreakMessage',
      );
    });

    test('case 10: 不再含 _showCelebrationOverlay (已抽到 HomeCelebrationController)', () {
      expect(
        RegExp(r'void\s+_showCelebrationOverlay').hasMatch(homePageStateContent),
        isFalse,
        reason: '_showCelebrationOverlay 已抽到 HomeCelebrationController.show',
      );
    });
  });

  group('R108 注释 + 改动落地', () {
    late String homePageStateContent;

    setUpAll(() async {
      homePageStateContent = await File(
        'lib/presentation/pages/home/home_page_state.dart',
      ).readAsString();
    });

    test('case 11: home_page_state.dart 含 R108 拆 3 controller 注释', () {
      // 验证 R108 拆 controller 决策注释落地, 不只是删代码
      expect(
        homePageStateContent.contains('R108 (P1 home_page_state 拆'),
        isTrue,
        reason: 'R108 注释应提到"home_page_state 拆" 决策',
      );
      expect(
        homePageStateContent.contains('3 controller'),
        isTrue,
        reason: 'R108 注释应提到"3 controller" 拆分方案',
      );
    });

    test('case 12: home_page_state.dart 保留 P0#5 stagger clamp 改动', () {
      // 跟 stagger_clamp_round108_test 互不冲突: 验证 R108 P1 拆 controller
      // 没回退 R108 P0#5 stagger 改动 (3 层而非 8 层)
      // staggerStepMs 引用次数应 = 2 (summary + hero)
      final matches = RegExp(r'AppTokens\.staggerStepMs').allMatches(
        homePageStateContent,
      );
      expect(
        matches.length,
        2,
        reason: 'R108 P1 拆 controller 不应回退 P0#5 stagger 改动 (应保持 2 处)',
      );
    });
  });
}
