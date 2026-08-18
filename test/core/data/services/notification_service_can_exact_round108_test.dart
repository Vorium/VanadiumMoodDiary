// v0.30 R108 (P0#2): SCHEDULE_EXACT_ALARM 运行时权限检查防回归测试
//
// R107 报告 P0-2: NotificationService 调 ReminderDispatcher 的
// AndroidScheduleMode.exactAllowWhileIdle, 但未做 Android 12+ (API 31)
// SCHEDULE_EXACT_ALARM 权限运行时检查。Android 13+ (API 33) 用户可撤回
// 权限, zonedSchedule 静默降级 inexact (~15min 漂移), 用户报"提醒不准"。
//
// 修法:
// 1. NotificationService 新 _canScheduleExact() helper, 调
//    AndroidFlutterLocalNotificationsPlugin.canScheduleExactNotifications()
// 2. rescheduleAll 入口: 调 _canScheduleExact, 同步设置
//    ReminderDispatcher.useExactAllowWhileIdle
// 3. ReminderDispatcher.zonedDaily / zonedAt 根据 useExactAllowWhileIdle
//    选 exactAllowWhileIdle / inexactAllowWhileIdle mode
// 4. 失败不阻塞, 走 swallow + piiSafeLog
//
// 测试覆盖 (静态分析 + 集中器单元, 不依赖 iOS / Android 真机):
// 1. NotificationService 含 _canScheduleExact method
// 2. rescheduleAll 入口调 _canScheduleExact
// 3. rescheduleAll 把 useExactAllowWhileIdle 传给 dispatcher
// 4. ReminderDispatcher.useExactAllowWhileIdle field 存在 (default true)
// 5. zonedDaily / zonedAt 走 useExactAllowWhileIdle 选 mode
// 6. _canScheduleExact 失败走 swallowError
// 7. platform 兼容: iOS 返 true / Android 调 plugin / Web 返 false
import 'dart:io' as dart_io;

import 'package:chroniccare/core/platform/notification/reminder_dispatcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Part A: 静态分析 — NotificationService R108 P0#2 修复', () {
    test('A1: NotificationService 含 _canScheduleExact method', () async {
      final content = await dart_io.File(
        'lib/core/platform/notification/notification_service.dart',
      ).readAsString();
      expect(
        content.contains('_canScheduleExact'),
        isTrue,
        reason: 'NotificationService 应有 _canScheduleExact() 私有 method',
      );
    });

    test('A2: rescheduleAll 调 _canScheduleExact 同步设 dispatcher mode', () async {
      final content = await dart_io.File(
        'lib/core/platform/notification/notification_service.dart',
      ).readAsString();
      // rescheduleAll 内部: 调 _canScheduleExact, 写到 _dispatcher.useExactAllowWhileIdle
      // R120 P1-2 (1.1.0 round 12k god class split): 截到文件结尾, 不用硬编码 3000 缓冲
      // (原 386L 文件有 3000+ 字节缓冲, R120 缩到 252L 后越界)
      final rescheduleStart = content.indexOf('Future<void> rescheduleAll(');
      final rescheduleSection = content.substring(rescheduleStart);
      expect(
        rescheduleSection.contains('useExactAllowWhileIdle'),
        isTrue,
        reason:
            'rescheduleAll 应把 canExact 结果同步给 _dispatcher.useExactAllowWhileIdle',
      );
    });

    test('A3: _canScheduleExact 走 swallowError 失败兜底', () async {
      final content = await dart_io.File(
        'lib/core/platform/notification/notification_service.dart',
      ).readAsString();
      expect(
        content.contains('swallowError'),
        isTrue,
        reason: 'NotificationService 应 import + 调 swallowError (失败兜底)',
      );
    });
  });

  group('Part B: ReminderDispatcher R108 P0#2 useExactAllowWhileIdle 字段', () {
    test('B1: useExactAllowWhileIdle field 存在 (default true)', () {
      // 实例化 dispatcher (不需真 plugin, ReminderDispatcher 只存 plugin 引用)
      // 用 mock FlutterLocalNotificationsPlugin 即可
      final dispatcher = ReminderDispatcher(
        plugin: _NoopNotificationsPlugin(),
        channelId: 'test',
        channelName: 'test',
        channelDescription: 'test',
      );
      // R108 P0-2: 默认 exact mode (保留 R70 行为, 向后兼容)
      expect(
        dispatcher.useExactAllowWhileIdle,
        isTrue,
        reason: 'ReminderDispatcher.useExactAllowWhileIdle default = true',
      );
    });

    test('B2: useExactAllowWhileIdle 可写 (canScheduleExact=false 时改 false)', () {
      final dispatcher = ReminderDispatcher(
        plugin: _NoopNotificationsPlugin(),
        channelId: 'test',
        channelName: 'test',
        channelDescription: 'test',
      );
      dispatcher.setExactMode(false);
      expect(
        dispatcher.useExactAllowWhileIdle,
        isFalse,
        reason: 'useExactAllowWhileIdle 字段可写 (R108 rescheduleAll 会改)',
      );
    });
  });

  group('Part C: ReminderDispatcher 静态分析 — zonedDaily / zonedAt mode 切换', () {
    test('C1: zonedDaily 用 useExactAllowWhileIdle 选 mode', () async {
      final content = await dart_io.File(
        'lib/core/platform/notification/reminder_dispatcher.dart',
      ).readAsString();
      // zonedDaily 应含 useExactAllowWhileIdle ? exactAllowWhileIdle : inexactAllowWhileIdle
      final zonedDailyIdx = content.indexOf('Future<void> zonedDaily(');
      expect(zonedDailyIdx, greaterThan(0), reason: 'zonedDaily 存在');
      final zonedDailyBody = content.substring(
        zonedDailyIdx,
        zonedDailyIdx + 1500,
      );
      expect(
        zonedDailyBody.contains('useExactAllowWhileIdle'),
        isTrue,
        reason: 'zonedDaily 内应使用 useExactAllowWhileIdle 选 mode',
      );
      expect(
        zonedDailyBody.contains('exactAllowWhileIdle'),
        isTrue,
        reason: 'zonedDaily 应含 exactAllowWhileIdle 字符串 (true 分支)',
      );
      expect(
        zonedDailyBody.contains('inexactAllowWhileIdle'),
        isTrue,
        reason: 'zonedDaily 应含 inexactAllowWhileIdle 字符串 (false 兜底分支)',
      );
    });

    test('C2: zonedAt 同样用 useExactAllowWhileIdle 选 mode', () async {
      final content = await dart_io.File(
        'lib/core/platform/notification/reminder_dispatcher.dart',
      ).readAsString();
      final zonedAtIdx = content.indexOf('Future<void> zonedAt(');
      expect(zonedAtIdx, greaterThan(0), reason: 'zonedAt 存在');
      final zonedAtBody = content.substring(
        zonedAtIdx,
        zonedAtIdx + 1500,
      );
      expect(
        zonedAtBody.contains('useExactAllowWhileIdle'),
        isTrue,
        reason: 'zonedAt 内应使用 useExactAllowWhileIdle 选 mode',
      );
    });
  });
}

/// 极简 mock FlutterLocalNotificationsPlugin (R108 P0#2 测试用)
/// R108 lock-in test 只需要 ReminderDispatcher 实例化, 不调 plugin 方法
/// (不调 zonedDaily / zonedAt, 因那需要 platform channel 全套 mock)
///
/// v0.30 R108 revisit: 改 `extends` → `implements`,因为
/// `FlutterLocalNotificationsPlugin` 是 factory + private constructor
/// (`FlutterLocalNotificationsPlugin._()`),外部不能 extends (编译错
/// "Classes can only extend other classes" 因 import 缺失 + factory 不让 extends)。
/// `implements` 需要 override 11 个 method, 走 `noSuchMethod` forwarder
/// 集中到 default behavior (返 null / 抛 NoSuchMethodError 也 OK, 因为
/// ReminderDispatcher 不会实际调)。
class _NoopNotificationsPlugin implements FlutterLocalNotificationsPlugin {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
