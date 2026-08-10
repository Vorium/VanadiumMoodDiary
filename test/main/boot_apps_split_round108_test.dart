// v0.30 R108 (P1 god class 拆 #1): main.dart 488L → 246L 拆 main lock-in
//
// 拆前: lib/main.dart 488L (实际 ~539L, R107 报告数 488)
// 拆后: lib/main.dart 246L + lib/main/boot_apps.dart 261L
//
// 锁住:
// 1. main.dart 行数显著减少 (488 → 246)
// 2. boot_apps.dart 存在
// 3. 4 占位 widget 全部 export (public API, 去掉下划线前缀)
// 4. _showMigrationConfirmDialog 已 export
// 5. main.dart 仍用 3 处 developer.log 守卫 (R108 P0#12 不破坏)
//
// 不真正运行 main() / _bootstrap() (启动流程涉及 DB / 通知, 测试用文件级 grep
// 即可, 跟 R95 sub-spec 4 task 17 模式一致)。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R108 Fix: main.dart god class 拆', () {
    test('main.dart 行数 < 300 (从 ~539L 显著缩减)', () {
      // 488L → 246L, 减约 54%. 4 占位 widget + dialog 全部到 boot_apps.dart.
      // 阈值 < 300 留 buffer 防止后续微调破, 不卡 < 100 (R62 / R67 / R108 P0#1
      // 注释不可删, 写代码注释共 ~80 行).
      final mainDart = File('lib/main.dart');
      expect(mainDart.existsSync(), isTrue);
      final lineCount = mainDart.readAsLinesSync().length;
      expect(
        lineCount,
        lessThan(300),
        reason: 'main.dart 行数应 < 300 (拆前 539L), 实际 $lineCount',
      );
    });

    test('lib/main/boot_apps.dart 存在 (4 占位 widget + dialog 抽到这里)', () {
      final bootApps = File('lib/main/boot_apps.dart');
      expect(
        bootApps.existsSync(),
        isTrue,
        reason: 'lib/main/boot_apps.dart 必须存在 (R108 拆出的新文件)',
      );
    });

    test('boot_apps.dart 行数 > 200 (4 widget + dialog 体量)', () {
      // 4 widget + dialog ≈ 250-280 行, 阈值 > 200 防止未来退化
      final bootApps = File('lib/main/boot_apps.dart');
      final lineCount = bootApps.readAsLinesSync().length;
      expect(
        lineCount,
        greaterThan(200),
        reason:
            'boot_apps.dart 行数应 > 200 (4 widget + dialog 体量), 实际 $lineCount',
      );
    });

    test('main.dart 不再含 _MigrationFailedApp / _MigrationAbortedApp / _MigrationPromptApp / _EarlyLoadingApp', () {
      // 4 占位 widget 全部移到 boot_apps.dart, main.dart 不应再定义
      final mainDart = File('lib/main.dart');
      final content = mainDart.readAsLinesSync().join('\n');
      for (final widget in [
        '_MigrationFailedApp',
        '_MigrationAbortedApp',
        '_MigrationPromptApp',
        '_EarlyLoadingApp',
      ]) {
        expect(
          content.contains(widget),
          isFalse,
          reason: 'main.dart 不应再含 private $widget (已移到 boot_apps.dart)',
        );
      }
    });

    test('main.dart 不再含 _showMigrationConfirmDialog (已 export)', () {
      final mainDart = File('lib/main.dart');
      final content = mainDart.readAsLinesSync().join('\n');
      expect(
        content.contains('_showMigrationConfirmDialog'),
        isFalse,
        reason: 'main.dart 不应再含 _showMigrationConfirmDialog (已移到 boot_apps.dart)',
      );
    });

    test('main.dart 不再含 _MigrationPromptController (已 export)', () {
      final mainDart = File('lib/main.dart');
      final content = mainDart.readAsLinesSync().join('\n');
      expect(
        content.contains('_MigrationPromptController'),
        isFalse,
        reason: 'main.dart 不应再含 _MigrationPromptController (已移到 boot_apps.dart)',
      );
    });

    test('boot_apps.dart 含 4 个 public 占位 widget (export 公开)', () {
      final bootApps = File('lib/main/boot_apps.dart');
      final content = bootApps.readAsLinesSync().join('\n');
      for (final widget in [
        'MigrationFailedApp',
        'MigrationAbortedApp',
        'MigrationPromptApp',
        'EarlyLoadingApp',
      ]) {
        // 检查 class 定义 (with extends), 排除注释/import
        final hasClass = content.contains('class $widget ');
        expect(
          hasClass,
          isTrue,
          reason: 'boot_apps.dart 应 export public $widget class',
        );
      }
    });

    test('boot_apps.dart 含 public MigrationPromptController + showMigrationConfirmDialog', () {
      final bootApps = File('lib/main/boot_apps.dart');
      final content = bootApps.readAsLinesSync().join('\n');
      expect(
        content.contains('class MigrationPromptController '),
        isTrue,
        reason: 'boot_apps.dart 应 export public MigrationPromptController',
      );
      expect(
        content.contains('Future<bool?> showMigrationConfirmDialog('),
        isTrue,
        reason: 'boot_apps.dart 应 export public showMigrationConfirmDialog',
      );
    });

    test('main.dart 仍 import boot_apps.dart', () {
      final mainDart = File('lib/main.dart');
      final content = mainDart.readAsLinesSync().join('\n');
      expect(
        content.contains("import 'package:chroniccare/main/boot_apps.dart';"),
        isTrue,
        reason: 'main.dart 必须 import boot_apps.dart 才能用 4 public widget',
      );
    });

    test('main.dart 调用的 widget 名是 public 版本 (无下划线前缀)', () {
      // 检查 main.dart 里使用的 widget / 函数名, 应是 public 版本
      final mainDart = File('lib/main.dart');
      final content = mainDart.readAsLinesSync().join('\n');
      // 应该出现
      expect(content.contains('runApp(const EarlyLoadingApp()'), isTrue,
          reason: 'main.dart 应 runApp(EarlyLoadingApp())');
      expect(content.contains('runApp(MigrationPromptApp(controller:'), isTrue,
          reason: 'main.dart 应 runApp(MigrationPromptApp(...))');
      expect(content.contains('runApp(MigrationAbortedApp(onRetry:'), isTrue,
          reason: 'main.dart 应 runApp(MigrationAbortedApp(...))');
      expect(content.contains('runApp(MigrationFailedApp(errorMessage:'), isTrue,
          reason: 'main.dart 应 runApp(MigrationFailedApp(...))');
      expect(content.contains('await showMigrationConfirmDialog('), isTrue,
          reason: 'main.dart 应调 showMigrationConfirmDialog');
      expect(content.contains('MigrationPromptController()'), isTrue,
          reason: 'main.dart 应 new MigrationPromptController()');
    });

    test('R108 P0#12 守卫未破坏: main.dart developer.log 总数 = 3', () {
      // P0#12: developer.log 必须仍 3 处 (R108 报告 P0 #1-5 范围内已有 lock-in)
      // 防御: 未来 refactor 误删任一处守卫 → 测试 fail
      final mainDart = File('lib/main.dart');
      final content = mainDart.readAsStringSync();
      final matches = RegExp(r'developer\.log\s*\(').allMatches(content);
      expect(
        matches.length,
        equals(3),
        reason: 'main.dart developer.log 应仍 3 处 (R108 P0#12), 实际 ${matches.length}',
      );
    });

    test('R108 P0#12 守卫未破坏: kReleaseMode 引用 ≥ 2 处', () {
      // 2 处守卫 (FlutterError.onError + runZonedGuarded onError), lock-in
      final mainDart = File('lib/main.dart');
      final content = mainDart.readAsStringSync();
      final matches = RegExp(r'!kReleaseMode').allMatches(content);
      expect(
        matches.length,
        greaterThanOrEqualTo(2),
        reason: 'main.dart 至少 2 处 !kReleaseMode 守卫, 实际 ${matches.length}',
      );
    });

    test('boot_apps.dart 不引入 flutter/foundation (不需要 kReleaseMode 守卫)', () {
      // boot_apps.dart 4 widget 都不调 developer.log, 不需要 foundation
      // 防御: 未来误在 boot_apps.dart 加裸 developer.log → 测试 fail
      final bootApps = File('lib/main/boot_apps.dart');
      final content = bootApps.readAsStringSync();
      expect(
        content.contains("import 'package:flutter/foundation.dart';"),
        isFalse,
        reason:
            'boot_apps.dart 不应 import flutter/foundation (不需要 kReleaseMode 守卫)',
      );
      // 检查实际 developer.log( 调用 (含空格 + 左括号), 排除注释里的提及
      // regex: `developer.log\s*(` (跟 R108 P0#12 lock-in test 同款)
      final callMatches = RegExp(r'developer\.log\s*\(').allMatches(content);
      expect(
        callMatches.length,
        equals(0),
        reason:
            'boot_apps.dart 不应有 developer.log( 调用 (4 widget 都不需要), 实际 ${callMatches.length} 处',
      );
    });
  });
}
