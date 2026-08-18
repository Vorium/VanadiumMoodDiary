// v0.30 R108 (P1 home_page_state 拆 3 controller): 防回归测试
//
// R107 报告 P1-3: home_page_state 597L god class 拆 3 controller
// (HomeDeepLinkHandler / HomeCareEngineDispatcher / HomeCelebrationController)
// (4 视角共识: emil + spen + architecture + bottom-up)。
//
// 1.1.0 round 4 (emotion-first refactor): HomeCareEngineDispatcher 整摘
// (safety + care engine 编排删除), 本文件改测剩余 2 controller。
//
// 测试覆盖 (不依赖 widget 渲染, 纯文本/静态分析):
// 1. 2 controller 文件存在 (care dispatcher 已摘)
// 2. 2 controller API surface (class + public method 存在)
// 3. home_page_state.dart 行数 < 500
// 4. state class 不再含已抽方法 (_autofireMedicationCheckIn /
//    _showMedicationHint / _runAfterCheckIn / _fireCareEngine / _runSafetyCheck
//    / _celebrationFor / _showCelebrationOverlay)
// 5. 保留 P0#5 stagger clamp 改动 (跟 stagger_clamp_round108_test 互不冲突)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('controller 文件存在 (R108 拆 + 1.1.0 round 4 摘 dispatcher)', () {
    test('case 1: controllers/ 子目录 2 文件存在 (dispatcher 已摘)', () async {
      final files = [
        'lib/features/home/presentation/pages/home/controllers/home_deep_link_handler.dart',
        'lib/features/home/presentation/pages/home/controllers/home_celebration_controller.dart',
      ];
      for (final f in files) {
        final exists = await File(f).exists();
        expect(
          exists,
          isTrue,
          reason: 'R108 拆 controller + round 4 摘 dispatcher, $f 应该存在',
        );
      }
      final removed = await File(
        'lib/features/home/presentation/pages/home/controllers/home_care_engine_dispatcher.dart',
      ).exists();
      expect(
        removed,
        isFalse,
        reason: '1.1.0 round 4: care engine dispatcher 应已删除',
      );
    });
  });

  group('2 controller API surface (R108 P1 home_page_state 拆)', () {
    late String deepLinkContent;
    late String celebrationContent;

    setUpAll(() async {
      deepLinkContent = await File(
        'lib/features/home/presentation/pages/home/controllers/home_deep_link_handler.dart',
      ).readAsString();
      celebrationContent = await File(
        'lib/features/home/presentation/pages/home/controllers/home_celebration_controller.dart',
      ).readAsString();
    });

    test('case 2: HomeDeepLinkHandler class 存在 + 关键 method', () {
      expect(
        RegExp(r'class\s+HomeDeepLinkHandler').hasMatch(deepLinkContent),
        isTrue,
        reason: 'R108 应抽 HomeDeepLinkHandler class',
      );
      // 关键 method: inspect / autofireMedicationCheckIn / showMedicationHint /
      // clearQuery (1.1.0 round 4: scheduleRaceTimer + dispose 已随 safety 摘)
      for (final method in [
        'inspect',
        'autofireMedicationCheckIn',
        'showMedicationHint',
        'clearQuery',
      ]) {
        expect(
          RegExp('void\\s+$method\\(|Future<\\w+>\\s+$method\\(|\\w+\\s+$method\\(')
              .hasMatch(deepLinkContent),
          isTrue,
          reason: 'HomeDeepLinkHandler 应有 $method method',
        );
      }
      // round 4: scheduleRaceTimer 应已删除
      expect(
        deepLinkContent.contains('scheduleRaceTimer'),
        isFalse,
        reason: '1.1.0 round 4: race timer 随 safety rerun 路径删除',
      );
    });

    test('case 4: HomeCelebrationController class 存在 + 关键 method', () {
      expect(
        RegExp(r'class\s+HomeCelebrationController')
            .hasMatch(celebrationContent),
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

  group('home_page_state.dart 行数 + 残留方法 (R108 拆 + round 4 摘 防回退)', () {
    late String homePageStateContent;
    late int lineCount;

    setUpAll(() async {
      homePageStateContent = await File(
        'lib/features/home/presentation/pages/home/home_page_state.dart',
      ).readAsString();
      lineCount = homePageStateContent.split('\n').length;
    });

    test('case 5: home_page_state.dart 行数 < 500 (R108 拆后 ~475L)', () {
      expect(
        lineCount,
        lessThan(500),
        reason: 'R108 修后 home_page_state.dart 应 < 500L, 实际 ${lineCount}L',
      );
    });

    test('case 6: 不再含已抽出的业务方法 (controller + round 4 摘)', () {
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
      // round 4: 不再含 safety check
      expect(
        RegExp(r'Future<void>\s+_runSafetyCheck')
            .hasMatch(homePageStateContent),
        isFalse,
        reason: '1.1.0 round 4: _runSafetyCheck 已整摘',
      );
    });

    test('case 7: 不再含 _runAfterCheckIn (已随 dispatcher 整摘)', () {
      expect(
        RegExp(r'Future<void>\s+_runAfterCheckIn')
            .hasMatch(homePageStateContent),
        isFalse,
        reason: '_runAfterCheckIn 已随 HomeCareEngineDispatcher 删除',
      );
    });

    test('case 8: 不再含 _fireCareEngine 业务 (已随 dispatcher 整摘)', () {
      expect(
        RegExp(r'Future<void>\s+_fireCareEngine')
            .hasMatch(homePageStateContent),
        isFalse,
        reason: '_fireCareEngine 已随 HomeCareEngineDispatcher 删除',
      );
    });

    test('case 9: 不再含 _celebrationFor (已抽到 HomeCelebrationController)', () {
      expect(
        RegExp(r'String\s+_celebrationFor').hasMatch(homePageStateContent),
        isFalse,
        reason:
            '_celebrationFor 已抽到 HomeCelebrationController.pickStreakMessage',
      );
    });

    test('case 10: 不再含 _showCelebrationOverlay (已抽到 HomeCelebrationController)',
        () {
      expect(
        RegExp(r'void\s+_showCelebrationOverlay')
            .hasMatch(homePageStateContent),
        isFalse,
        reason: '_showCelebrationOverlay 已抽到 HomeCelebrationController.show',
      );
    });
  });

  group('R108 注释 + 改动落地', () {
    late String homePageStateContent;

    setUpAll(() async {
      homePageStateContent = await File(
        'lib/features/home/presentation/pages/home/home_page_state.dart',
      ).readAsString();
    });

    test('case 11: home_page_state.dart 含 R108 拆 controller 注释', () {
      // 验证 R108 拆 controller 决策注释落地, 不只是删代码
      expect(
        homePageStateContent.contains('R108 (P1 home_page_state 拆'),
        isTrue,
        reason: 'R108 注释应提到"home_page_state 拆" 决策',
      );
      expect(
        homePageStateContent.contains('controller'),
        isTrue,
        reason: 'R108 注释应提到 controller 拆分方案',
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
