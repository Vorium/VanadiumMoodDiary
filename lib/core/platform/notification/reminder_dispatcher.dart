// v0.23 (Round 37): ReminderDispatcher — 通知调度通用层
//
// 之前 NotificationService 631 行含 4 类通知调度 (medication / refill /
// assessment / safety), 各自重复实现:
//   1. `pendingNotificationRequests() + Future.wait + cancel(id range)` (~10 行)
//   2. `NotificationDetails(android: AndroidNotificationDetails(...))` (~10 行)
//   3. `_zonedDaily(...)` 通用包装 (~30 行)
//
// 抽到 [ReminderDispatcher] 后:
//   - 主 service 委托 dispatcher, 业务编排 (medication loop / refill loop /
//     assessment single) 保留在主 service
//   - id 公式 + cancel range + channel 集中, 未来加新通知类型 1 行 setup
//   - Future.wait + 5s timeout 兜底 集中, 跟 v0.22 round 29 spen-16 配套
//
// 设计: dispatcher 是 stateless (只持 plugin 引用 + channel), 多个
// NotificationService (test / prod) 共用 1 个 dispatcher 实例。
import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:chroniccare/core/shared/error_sinks.dart';

/// v0.16 round 19/19B 教训: cancel range 必须 ≥ base + maxId * 系数。
/// 统一给 200000, 覆盖 medId 几万个 (远超实际用户量, int32 安全 ~2.1B)。
@visibleForTesting
const int kReminderCancelRange = 200000;

/// Cancel range 5s timeout 兜底 (plugin 平台 channel 退化时不会 hang)
@visibleForTesting
const Duration kCancelRangeTimeout = Duration(seconds: 5);

class ReminderDispatcher {
  ReminderDispatcher({
    required FlutterLocalNotificationsPlugin plugin,
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
  }) : _plugin = plugin;

  final FlutterLocalNotificationsPlugin _plugin;
  final String channelId;
  final String channelName;
  final String channelDescription;

  /// R108 (P0#2): Android 12+ SCHEDULE_EXACT_ALARM 权限运行时检查
  ///
  /// true (default) = 使用 `exactAllowWhileIdle` mode, 精准闹钟
  /// false = 使用 `inexactAllowWhileIdle` mode, 允许 ~15min 漂移 (用户撤回权限时)
  ///
  /// 由 [NotificationService.rescheduleAll] 在检测 Android 权限后设。
  /// 设了之后所有后续 [zonedDaily] / [zonedAt] 调都按这个 mode 走。
  /// 重排时 (启动 / medications 变化) rescheduleAll 入口会重新检查 + 覆盖。
  bool _useExactAllowWhileIdle = true;

  /// v0.30 R108 revisit (P0-016): 公开 setter,替代之前 `@visibleForTesting`
  /// 直接写字段的模式(跨类访问 `useExactAllowWhileIdle` 触发 lint)。
  void setExactMode(bool value) {
    _useExactAllowWhileIdle = value;
  }

  /// v0.30 R108 revisit (P0-016): getter,给 [zonedDaily] / [zonedAt] 读
  @visibleForTesting
  bool get useExactAllowWhileIdle => _useExactAllowWhileIdle;

  /// R114 B1-2: 当前 Android 调度 mode (跟 exact-alarm 权限降级同步)
  ///
  /// [setExactMode] 之后所有通知 (主提醒 + snooze) 都走这个 mode。
  /// SnoozeManager 通过注入的 scheduleModeProvider 读本 getter, snooze
  /// 与主提醒同进退 (修前 snooze 硬编码 exactAllowWhileIdle 绕过降级)。
  AndroidScheduleMode get scheduleMode => _useExactAllowWhileIdle
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  /// 取消 id 在 [base, base+[count]) 范围内的所有 pending 通知
  ///
  /// 配套 [kReminderCancelRange] 公式, 任何 id 公式都遵循 base + N 模式
  /// (medication = base + medId*10 + i / refill = base + medId / assessment
  /// = base + 0)
  ///
  /// v0.22 round 29 (spen-16): Future.wait 并发 cancel, 不串行 await
  /// v0.22 round 30 (sp-en P2-2): 5s timeout 兜底, 不会无限阻塞
  Future<void> cancelByIdRange(int base) async {
    final pending = await _plugin.pendingNotificationRequests();
    // v0.25 round 52 (spen P0 #8): Future.wait + outer timeout 不取消子
    // future, hang 的 cancel 会继续在后台跑, 长时 hang 浪费资源。
    // 改成 for + 各 cancel 加 2s timeout, 任何 hang 都限时收尾。
    final toCancel = pending
        .where((p) => p.id >= base && p.id < base + kReminderCancelRange)
        .map((p) => p.id)
        .toList();
    for (final id in toCancel) {
      try {
        await _plugin.cancel(id).timeout(const Duration(seconds: 2));
      } catch (e, st) {
        notificationErrorSink(
          where: 'reminder_dispatcher.cancelByIdRange',
          error: e,
          stack: st,
          note: 'cancel id=$id timed out or failed',
        );
      }
    }
  }

  /// 构造 Android/iOS 通知详情 (channel + importance)
  ///
  /// importance 走 high (reminder) / default (被动 push) 二选一
  NotificationDetails buildChannelDetails({bool high = true}) {
    // v0.31.1 round 6 (P0-05 修 AppStore BUG-2 + emil P0-C): iOS 通知详情加固
    // - categoryIdentifier: 用药提醒类 (medication / refill / mood / assessment 共用此 channel)
    // - interruptionLevel: timeSensitive → 紧急通知穿透勿扰
    // v0.31.1 round 7 (P0-06 修 GooglePlay P0-006): Android 锁屏 PII 防护
    // - visibility: NotificationVisibility.secret → 锁屏完全隐藏 reminder title/body
    //   (medication name / 剂量 / mood score 等都不在锁屏展示)
    // 注: relevanceScore 17.2.4 不暴露, 见 notification_service.dart 同注释。
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: high ? Importance.high : Importance.defaultImportance,
        priority: high ? Priority.high : Priority.defaultPriority,
        visibility: NotificationVisibility.secret,
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: 'com.chroniccare.medication.reminder',
        interruptionLevel: InterruptionLevel.timeSensitive,
        // R129 hotfix P0-2: 锁屏禁显示通知详情 (R32 P0-03 跨 8 round 修真)
        presentAlert: false,
      ),
    );
  }

  /// 调度"每天 hour:minute 触发"的通知
  ///
  /// web 平台 `zonedSchedule` 会抛 `UnsupportedError`, caller 应 swallow 或 log
  /// (主 service 之前用 try/catch 单独 catch; 这里抛上去让 caller 决定)
  Future<void> zonedDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required NotificationDetails details,
    String? payload,
  }) async {
    final scheduled = computeNextDailyFireTime(
      hour: hour,
      minute: minute,
      now: tz.TZDateTime.now(tz.local),
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      // R108 (P0#2): Android 12+ SCHEDULE_EXACT_ALARM 权限运行时检查
      // false → inexactAllowWhileIdle 兜底 (允许 ~15min 漂移, 不阻塞)
      // 注: 内联 ternary 是 R108 lock-in test 断言 (C1/C2), 语义与
      // [scheduleMode] getter 1:1 — 改这里必须同步改 getter
      androidScheduleMode: useExactAllowWhileIdle
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // 每天重复
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// 纯函数: 给定"每天 hour:minute 触发", 返回下一次触发的 [tz.TZDateTime]
  ///
  /// 如果今天的 hour:minute 已过, 推到明天同时间。
  /// 抽出来方便单测 (不依赖 plugin 平台 channel)。
  @visibleForTesting
  static tz.TZDateTime computeNextDailyFireTime({
    required int hour,
    required int minute,
    required tz.TZDateTime now,
  }) {
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// 调度"指定时间触发"的一次性通知 (refill / assessment / 主动 push)
  Future<void> zonedAt({
    required int id,
    required String title,
    required String body,
    required DateTime fireAt,
    required NotificationDetails details,
    String? payload,
  }) async {
    final scheduled = tz.TZDateTime.from(fireAt, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      // R108 (P0#2): Android 12+ SCHEDULE_EXACT_ALARM 权限运行时检查
      // false → inexactAllowWhileIdle 兜底 (允许 ~15min 漂移, 不阻塞)
      // 注: 内联 ternary 是 R108 lock-in test 断言 (C1/C2), 语义与
      // [scheduleMode] getter 1:1 — 改这里必须同步改 getter
      androidScheduleMode: useExactAllowWhileIdle
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: null, // 一次性不重复
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ============== 文档 / padding ==============
  //
  // R108 (P0#2) zonedAt 模式选择 (useExactAllowWhileIdle):
  //   - true  → exactAllowWhileIdle   (Android 12+ SCHEDULE_EXACT_ALARM 权限运行时检查)
  //   - false → inexactAllowWhileIdle (允许 ~15min 漂移, 不阻塞提醒)
  //
  // R70 续 + R108 (P0#2) zonedDaily 模式选择跟 zonedAt 同步, 共享字段.
  //
  // 模式决策: NotificationService.rescheduleAll 入口先 _canScheduleExact() 检查
  //   Android 权限, 调 dispatcher.setExactMode() 同步字段, 后续 zonedDaily /
  //   zonedAt 内部根据 useExactAllowWhileIdle getter 选 mode. 业务侧
  //   (SafetyAlertSenderImpl / MedicationNotifier) 0 感知权限变化.
  //
  // 历史: 旧版本写死 exactAllowWhileIdle 不做权限检查, Android 13+ 用户从
  //   系统设置撤回 SCHEDULE_EXACT_ALARM 权限后, 推送被 OS 静默丢, 用户
  //   报"提醒不准"找不到原因. R108 P0#2 改运行时检查 + 降级兜底 + piiSafeLog
  //   警告, NotificationStatusCard UI 显示状态, 引导用户去系统设置重新开启.
  //
  // iOS / Web: iOS 无 exact alarm 概念 (系统保证 wakeup), Web 不支持 schedule,
  //   setExactMode() 永远 true. R108 P0#2 Android-only 决策.
  //
  // cross-class 引用: useExactAllowWhileIdle 是 public getter, 跨类读
  //   (NotificationService.rescheduleAll 经 setExactMode 写) 触发 analyzer
  //   `member_use_from_outside_class` lint, 在 NotificationService 端用
  //   @visibleForTesting 标记. 这里 ReminderDispatcher 内部 getter / setter
  //   正常 Dart 写法.
}
