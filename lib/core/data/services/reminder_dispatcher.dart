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

import 'package:chroniccare/core/shared/swallow_error.dart';

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
        swallowError(
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
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: high ? Importance.high : Importance.defaultImportance,
        priority: high ? Priority.high : Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null, // 一次性不重复
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
}
