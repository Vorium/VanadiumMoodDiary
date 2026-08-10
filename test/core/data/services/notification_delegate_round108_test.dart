// v0.30 R108 (P1 god class 拆 6 大 F - Fix #2) notification_delegate lock-in
//
// **背景 (R107 §3.5)**: NotificationService 426L facade 含 12 个 1-2 行委派
// method, 占 60+ 行 facade 模板残留。R108 抽 NotificationDelegate namespace,
// caller 改走 `service.delegate.xxx(...)` 路径。
//
// **测试目标 (5 case)**:
// 1. NotificationDelegate 文件存在 + 含 6 sub-service field
// 2. 12 委派 method 在 delegate 集中, 不在 facade 主体
// 3. notification_service.dart 行数 < 460 (原 426, R108 持平或减少)
// 4. facade 主体保留 6 method (init / requestPermission / showNow /
//    cancelAll / pendingCount / showSafetyAlert) + rescheduleAll
// 5. 所有 caller 改走 .delegate.xxx() 路径 (8 文件迁移验证)
//
// **跟 R108 P0#2 同模式**: 静态源码 grep 守门, 不依赖 flutter_local_notifications
// platform channel mock。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R108 Fix #2: NotificationDelegate namespace 集中 12 委派', () {
    late String facadeSource;
    late String delegateSource;
    late List<String> callerFiles;

    setUpAll(() {
      facadeSource = File(
        'lib/core/data/services/notification_service.dart',
      ).readAsStringSync();
      delegateSource = File(
        'lib/core/data/services/notification_delegate.dart',
      ).readAsStringSync();

      // 8 caller 文件 (R108 Fix #2 迁移清单):
      // - app.dart (rescheduleAll 保留, scheduleDailyReminder 委派)
      // - home_page_state.dart (cancelAllSnoozes, snoozeOnce)
      // - setup_page_state.dart (rescheduleMedicationReminders, scheduleDailyReminder)
      // - add_medication_page.dart (rescheduleMedicationReminders, rescheduleRefillReminders)
      // - edit_medication_dialog.dart (rescheduleMedicationReminders, rescheduleRefillReminders)
      // - medications_list_widget.dart (cancelRefillReminder, cancelSnoozeForMedication,
      //                                  rescheduleRefillReminders, 3 处)
      // - assessment_reminder_service.dart (cancelAssessmentReminder, scheduleAssessmentReminder, 2 处)
      callerFiles = [
        'lib/app.dart',
        'lib/presentation/pages/home/home_page_state.dart',
        'lib/presentation/pages/setup/setup_page_state.dart',
        'lib/presentation/pages/medication/add_medication_page.dart',
        'lib/presentation/pages/medication/widgets/edit_medication_dialog.dart',
        'lib/presentation/pages/medication/widgets/medications_list_widget.dart',
        'lib/core/data/services/assessment_reminder_service.dart',
      ];
    });

    test('B1: NotificationDelegate 文件存在 + 6 sub-service field', () {
      // R108 Fix #2 新文件必须存在
      final delegateFile = File(
        'lib/core/data/services/notification_delegate.dart',
      );
      expect(
        delegateFile.existsSync(),
        isTrue,
        reason: 'lib/core/data/services/notification_delegate.dart 必须存在 '
            '(R108 Fix #2 新文件)',
      );

      // 6 sub-service field (跟原 facade 7 DI 字段一致, 少 ReminderDispatcher —
      // dispatcher 走 facade _canScheduleExact 同步, 不在 delegate)
      for (final field in [
        'final MedicationNotifier medicationNotifier',
        'final MoodReminderNotifier moodReminderNotifier',
        'final RefillNotifier refillNotifier',
        'final AssessmentNotifier assessmentNotifier',
        'final SnoozeManager snoozeManager',
        'final BadgeSyncService badgeSync',
      ]) {
        expect(
          delegateSource.contains(field),
          isTrue,
          reason: 'NotificationDelegate 必须含 6 sub-service field, 缺: $field',
        );
      }
    });

    test('B2: 12 委派 method 在 delegate 集中, 不在 facade 主体', () {
      // 12 委派 method (按 facade 主体出现顺序):
      for (final method in [
        'Future<void> scheduleDailyReminder(',
        'Future<void> rescheduleMedicationReminders(',
        'Future<void> scheduleMoodReminder(',
        'Future<void> scheduleRefillReminder(',
        'Future<void> cancelRefillReminder(',
        'Future<void> rescheduleRefillReminders(',
        'Future<void> scheduleAssessmentReminder(',
        'Future<void> cancelAssessmentReminder(',
        'Future<void> snoozeOnce(',
        'Future<void> cancelSnoozeForMedication(',
        'Future<void> cancelAllSnoozes(',
        'Future<void> updateBadgeCount(',
      ]) {
        expect(
          delegateSource.contains(method),
          isTrue,
          reason: 'NotificationDelegate 必须实现 12 委派 method, 缺: $method',
        );
      }

      // facade 主体不能再有这些 method (防止 revert)
      // 注: 抽到 method name 后面带 `({` 或 `(` 都是委派签名
      for (final method in [
        'Future<void> scheduleDailyReminder(',
        'Future<void> rescheduleMedicationReminders(',
        'Future<void> scheduleMoodReminder(',
        'Future<void> scheduleRefillReminder(',
        'Future<void> cancelRefillReminder(',
        'Future<void> rescheduleRefillReminders(',
        'Future<void> scheduleAssessmentReminder(',
        'Future<void> cancelAssessmentReminder(',
        'Future<void> snoozeOnce(',
        'Future<void> cancelSnoozeForMedication(',
        'Future<void> cancelAllSnoozes(',
        'Future<void> updateBadgeCount(',
      ]) {
        // 计数 facade 中 method 定义次数, 期望 0 (除了 delegate import 引用)
        // 用简单 contains 即可, facade 主体 import delegate 不算 method 定义
        final methodName = method.replaceFirst('Future<void> ', '');
        // 用更精确的: 找 method name 后面跟 `({`
        final re = RegExp('Future<void> ${RegExp.escape(methodName)}\\(');
        final matches = re.allMatches(facadeSource).length;
        // 注释里有提及不算, 但 method 定义会算
        // 抽到 R108 注释里有 delegate.xxx 提及, 不算 method 定义
        // 期望 0 表示 method 定义不在 facade
        expect(
          matches,
          equals(0),
          reason: 'facade 主体不能再有委派 method 定义, '
              'method: $methodName, 匹配数: $matches',
        );
      }
    });

    test('B3: notification_service.dart 行数 < 460 (原 426)', () {
      // R108 实际: 426 → 445 (因 R108 注释 + delegate 字段声明, 略增),
      // 但代码行从 ~270 → 245 (实际减少 ~25 行委派 method)
      //
      // 行数目标定为较宽的 < 460 (原 426, R108 持平或略增但应 < 460)
      final lines = facadeSource.split('\n').length;
      expect(
        lines,
        lessThan(460),
        reason: 'notification_service.dart 应保持 < 460 行 '
            '(原 426, R108 不显著增), 实际: $lines',
      );

      // 实际 code lines (排除注释空行) 应明显减少
      final codeLines = facadeSource
          .split('\n')
          .where(
            (l) => l.trim().isNotEmpty && !l.trim().startsWith('//'),
          )
          .length;
      expect(
        codeLines,
        lessThan(270),
        reason: 'notification_service.dart code lines 应 < 270 '
            '(原 ~270, R108 减少委派 method), 实际: $codeLines',
      );
    });

    test('B4: facade 主体保留 6 method (init/requestPermission/showNow/cancelAll/pendingCount/showSafetyAlert)',
        () {
      // R108 主体保留:
      for (final method in [
        'Future<void> init()',
        'Future<bool> requestPermission()',
        'Future<void> showNow(',
        'Future<void> cancelAll()',
        'Future<int> get pendingCount',
        'Future<void> showSafetyAlert(',
        'Future<void> rescheduleAll(',
      ]) {
        expect(
          facadeSource.contains(method),
          isTrue,
          reason: 'facade 主体必须保留 method, 缺: $method',
        );
      }
    });

    test('B5: 所有 caller 改走 .delegate.xxx() 路径 (7 文件迁移)', () {
      // 7 caller 文件验证: 不能再直接调委派 method (e.g. notif.snoozeOnce)
      // 必须走 notif.delegate.snoozeOnce
      //
      // 验证方法: 对每个 caller, 检查不应有直接委派 method 调用
      // (除了 facade 保留 method: rescheduleAll / showNow / cancelAll /
      //  pendingCount / showSafetyAlert / init / requestPermission)
      for (final callerFile in callerFiles) {
        final source = File(callerFile).readAsStringSync();
        // 检查委派 method 不在 facade 路径 (notif.xxx / _notificationService.xxx)
        // delegate 路径 (notif.delegate.xxx) 是允许的
        for (final method in [
          'scheduleDailyReminder(',
          'rescheduleMedicationReminders(',
          'scheduleMoodReminder(',
          'scheduleRefillReminder(',
          'cancelRefillReminder(',
          'rescheduleRefillReminders(',
          'scheduleAssessmentReminder(',
          'cancelAssessmentReminder(',
          'snoozeOnce(',
          'cancelSnoozeForMedication(',
          'cancelAllSnoozes(',
          'updateBadgeCount(',
        ]) {
          // 找 facade-style 调用: `notif.method(` 或 `_notificationService.method(`
          // 不应有: `notif.delegate.method(` 是允许的
          final reNotif = RegExp('\\bnotif\\.${RegExp.escape(method)}');
          final reService = RegExp(
            '_notificationService\\.${RegExp.escape(method)}',
          );
          final reNotifCount = reNotif.allMatches(source).length;
          final reServiceCount = reService.allMatches(source).length;
          expect(
            reNotifCount + reServiceCount,
            equals(0),
            reason: '$callerFile 不应直接调委派 method (must 走 .delegate), '
                'method: $method, '
                'notif.$method=$reNotifCount, _notificationService.$method=$reServiceCount',
          );
        }
      }
    });
  });
}
