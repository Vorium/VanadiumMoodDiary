// v1.1.0 round 12k (R120 P1-2 god class split): regression-protection test
// for the `notification_service.dart` facade split.
//
// Goal: if anyone re-merges the 30L `NotificationDetails` block back into
// `showNow` (undoing `_buildNotificationDetails()` extraction) or removes
// the `docs/architecture/NOTIFICATION_ID_BANDS.md` reference, this test
// fails. The split is a soft architectural choice (file size + readability),
// not a functional one — so the test asserts structural properties:
//
//   1. `_buildNotificationDetails()` private method exists
//   2. `showNow` is a 1-line delegation to `_plugin.show(..., _buildNotificationDetails(), ...)`
//   3. Cross-sub-service ID range doc moved to `docs/architecture/NOTIFICATION_ID_BANDS.md`
//   4. Facade file stays under 350L (god-class size guard, R120 target ~250L)
//   5. NOTIFICATION_ID_BANDS.md exists and has 6-row table
//
// The functional correctness of the notification scheduling itself is
// exercised by `test/core/data/services/notification_service_can_exact_round108_test.dart`
// (R108 P0#2 regression) + integration tests under `test/data/services/`.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R120 P1-2 — notification_service god class split', () {
    const mainPath = 'lib/core/data/services/notification_service.dart';
    const idBandsPath = 'docs/architecture/NOTIFICATION_ID_BANDS.md';

    test('main facade + NOTIFICATION_ID_BANDS.md both exist on disk', () {
      expect(File(mainPath).existsSync(), isTrue, reason: mainPath);
      expect(File(idBandsPath).existsSync(), isTrue, reason: idBandsPath);
    });

    test('_buildNotificationDetails() 私有方法存在', () {
      final main = File(mainPath).readAsStringSync();
      expect(
        main,
        contains('_buildNotificationDetails()'),
        reason:
            'showNow 30L NotificationDetails 块应抽到 _buildNotificationDetails() 私有方法',
      );
    });

    test('showNow 是 1-line 委托 (内联 NotificationDetails 不应有)', () {
      final main = File(mainPath).readAsStringSync();
      // 截取 showNow 方法体
      final showNowStart = main.indexOf('Future<void> showNow({');
      expect(showNowStart, greaterThan(0));
      final showNowEnd = main.indexOf('///', showNowStart);
      final showNowBlock = main.substring(
        showNowStart,
        showNowEnd > 0 ? showNowEnd : main.length,
      );
      expect(
        showNowBlock,
        contains('_buildNotificationDetails()'),
        reason: 'showNow 应调 _buildNotificationDetails()',
      );
      // 不应再内联 NotificationDetails(android: ..., iOS: ...) 块
      expect(
        showNowBlock,
        isNot(contains('AndroidNotificationDetails(')),
        reason: 'showNow 不应再内联 AndroidNotificationDetails',
      );
    });

    test('跨 sub-service ID range 文档已外移到 NOTIFICATION_ID_BANDS.md', () {
      final main = File(mainPath).readAsStringSync();
      // 类内应只剩 1 行引用, 不应有 6 类 ID 范围常量表
      final medBaseIdMatches = RegExp(
        r'MedicationNotifier\.defaultReminderId',
      ).allMatches(main);
      expect(
        medBaseIdMatches.length,
        lessThan(2),
        reason: 'ID 范围文档应外移, main 文件不应再列 6 类常量',
      );

      // 外移文件应有 ID 范围表
      final idBands = File(idBandsPath).readAsStringSync();
      expect(
        idBands,
        contains('| ID 范围'),
        reason: 'NOTIFICATION_ID_BANDS.md 应有 markdown 表格',
      );
      // 6 类 sub-service 都在
      for (final name in const [
        'MedicationNotifier',
        'RefillNotifier',
        'SnoozeManager',
        'AssessmentNotifier',
        'MoodReminderNotifier',
        'BadgeSyncService',
      ]) {
        expect(
          idBands,
          contains(name),
          reason: 'NOTIFICATION_ID_BANDS.md 应含 $name',
        );
      }
    });

    test('main facade 主壳 < 350L (R120 god-class size guard)', () {
      final lines = File(mainPath).readAsLinesSync().length;
      expect(
        lines,
        lessThan(350),
        reason:
            'notification_service.dart 主壳应保持精简 (R120 P1-2 拆后 252L), '
            '回归到 386+L 表示 NotificationDetails / ID 文档被回填',
      );
    });
  });
}
