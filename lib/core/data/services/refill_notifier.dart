// 规则 3 标记: CJK 字面量 = developer 日志/内部 note (非用户可见 UI 文案), 豁免 i18n 扫描
// v0.24 round 45 (Sprint #5b) — RefillNotifier 抽类
//
// 续方提醒编排 (id=6000+medId)。从 NotificationService 拆出, 单一职责:
//   - 单个 medication 续方 schedule / cancel / 重排
//   - 2 个 helper (id 公式 + 触发时间委派 + days until refill 委派)
// 委托 ReminderDispatcher 处理 cancel/zonedSchedule, 保留 200000 cancel range
// (v0.16 round 19B) + `DateTime.now()` 一次取防 midnight race (v0.16 round 19B fix)。
//
// v0.27 round 82 (P0 架构修复): computeRefillFireTime / daysUntilRefill 抽到
// `lib/domain/logic/refill_scheduler.dart` 纯函数, 切断 domain layer 间接
// flutter plugin 依赖。本类保留 facade 委托 (backward compatible, 老 caller
// import `package:chroniccare/core/data/services/refill_notifier.dart` 不动),
// 内部 delegate 到 `RefillScheduler.computeRefillFireTime` / `daysUntilRefill`。

import 'package:chroniccare/core/data/database/app_database.dart'
    show Medication;
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/l10n/strings.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chroniccare/core/data/services/notification_payload.dart';
import 'package:chroniccare/core/data/services/reminder_dispatcher.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/logic/refill_scheduler.dart';
import 'package:chroniccare/domain/usecases/schedule_refill_reminder.dart';

/// 续方提醒编排 (per-medication refill 提醒)
///
/// 公开 3 个 method:
///   - [scheduleRefillReminder] 调度单个 medication 的续方提醒
///   - [cancelRefillReminder] 取消单个 medication 的续方提醒
///   - [rescheduleRefillReminders] 重排所有 medication 的续方提醒
///
/// 公开 2 个 static helper:
///   - [refillNotificationId] id 公式 (跟 snooze_id 等不冲突)
///   - [computeRefillFireTime] 触发时间 = (refillAt - reminderDays) 当天 9:00
///
/// v0.24 round 45: 委托 ReminderDispatcher 处理 cancel/zonedSchedule。
class RefillNotifier {
  /// 续方提醒 id 起始基数 (id = base + medId, 范围 6000-206000)
  static const int refillBaseId = 6000;

  final FlutterLocalNotificationsPlugin _plugin;
  final ReminderDispatcher _dispatcher;

  /// facade 的 init() 包装, 保证 sub-service 调用时主 service 已 init
  final Future<void> Function() _ensureInitialized;

  /// v0.32 R112 (AR-18): 续方排程计算接线 ScheduleRefillReminderUseCase
  /// (之前直接调 RefillScheduler.computeRefillFireTime 绕过 usecase = 死代码)。
  /// 可选注入便于测试, 默认 const 实现。
  final ScheduleRefillReminderUseCase _scheduleUseCase;

  RefillNotifier({
    required FlutterLocalNotificationsPlugin plugin,
    required ReminderDispatcher dispatcher,
    required Future<void> Function() ensureInitialized,
    ScheduleRefillReminderUseCase scheduleUseCase =
        const ScheduleRefillReminderUseCase(),
  })  : _plugin = plugin,
        _dispatcher = dispatcher,
        _ensureInitialized = ensureInitialized,
        _scheduleUseCase = scheduleUseCase;

  /// 续方提醒通知 id 公式：`refillBaseId + medicationId`
  ///
  /// 一个 medication 一条预留 id 槽（id = refillBase + medId），
  /// 同一药多次重排 = 覆盖，不会叠加。
  ///
  /// v0.16 round 19B: range 改 200000，配套 rescheduleRefillReminders
  /// 的 cancel 范围。修前 1000 范围，medId >= 1000 漏 cancel。
  ///
  /// 公开 API: facade `NotificationService.refillNotificationId` 委托本方法,
  /// 现有 test (round 9 / 19B) 直接调 facade 静态 method, 不需改 import。
  static int refillNotificationId(int medicationId) {
    return refillBaseId + medicationId;
  }

  /// 计算续方提醒的触发时间 (refillAt - reminderDays 当天 9 点本地时间)
  ///
  /// facade 委托到 [RefillScheduler.computeRefillFireTime] (v0.27 round 82 抽离)。
  /// 纯函数, 0 副作用, 0 Flutter 依赖。
  /// 返回 null 当且仅当 [refillAt] 本身为 null。
  /// [reminderDays] < 1 时抛 ArgumentError。
  ///
  /// 公开 API: facade `NotificationService.computeRefillFireTime` 委托本方法,
  /// 现有 test (round 9) 直接调 facade 静态 method, 不需改 import。
  static DateTime? computeRefillFireTime({
    required DateTime? refillAt,
    required int reminderDays,
  }) {
    return RefillScheduler.computeRefillFireTime(
      refillAt: refillAt,
      reminderDays: reminderDays,
    );
  }

  /// 按"天"计算 refill 距今多少天 (不直接用 Duration.inDays)
  ///
  /// facade 委托到 [RefillScheduler.daysUntilRefill] (v0.27 round 82 抽离)。
  /// 不直接用 Duration.inDays, 因为:
  /// - 23.98h 会被报成 0 天
  /// - refill day 整天应该算"今天还有 X 天", 不能因时分秒而错
  ///
  /// v0.27 round 82: 改 `static` (去掉 `_` 前缀), 允许外部 use case
  /// 复用同一实现, 避免本类跟 domain 重复造轮子。
  static int daysUntilRefill(DateTime refillAt, DateTime now) {
    return RefillScheduler.daysUntilRefill(refillAt, now);
  }

  /// 调度一个 medication 的续方提醒
  ///
  /// - [medication] 必须有非空 [Medication.refillAt], 否则函数静默 no-op
  /// - inactive 药物跳过 (跟 ScheduleRefillReminderUseCase 规则 1:1, R112 AR-18)
  /// - 触发时间：`refillAt - reminderDays` 当天 9:00
  /// - 同一 med 多次调用 = 覆盖前一次 (id 稳定)
  /// - payload = medicationCheckIn(medId) — 点通知直达打卡
  ///
  /// v0.32 R112 (AR-18): fire time / isExpired 计算走
  ///   ScheduleRefillReminderUseCase (use case 从死代码变活)。
  Future<void> scheduleRefillReminder(MedicationEntity medication) async {
    // v0.16 round 19 fix: 之前 2 次 DateTime.now() 跨 midnight 时可能不一致
    // (fireAt 检查用 yesterday 23:59, daysLeft 计算用 today 00:00)
    final now = DateTime.now();
    final schedules = _scheduleUseCase(
      medications: [medication],
      now: now,
    );
    if (schedules.isEmpty) {
      piiSafeLog(
        'RefillNotifier',
        '⏭️ scheduleRefillReminder: medId=${medication.id} '
            'inactive 或无 refillAt, 跳过',
      );
      return;
    }
    final schedule = schedules.single;
    final fireAt = schedule.fireAt;
    if (fireAt == null) {
      piiSafeLog(
        'RefillNotifier',
        '⏭️ scheduleRefillReminder: medId=${medication.id} 无 refillAt, 跳过',
      );
      return;
    }

    // 已经过期的提醒不再调度 (避免给历史数据"补响")
    if (schedule.isExpired) {
      piiSafeLog(
        'RefillNotifier',
        '⏭️ scheduleRefillReminder: medId=${medication.id} '
            'fireAt=$fireAt 已过, 跳过',
      );
      // 但仍要取消旧的, 避免过期通知还挂着
      // v0.23 round 40 (sp-en R7 fix): cancel 抛异常不破整个 schedule 流程
      // 之前 await cancelRefillReminder 抛 PlatformException → 整个
      // reschedule 退出, 导致其他 medication 漏排
      // v0.25 round 52 (spen P0 #10): med.name 是 PII, 改 medId
      try {
        await cancelRefillReminder(medication.id);
      } catch (e, st) {
        piiSafeLog(
          'RefillNotifier',
          '⚠️ cancelRefillReminder 失败 (medId=${medication.id}): $e',
          error: e,
          stackTrace: st,
        );
      }
      return;
    }

    await _ensureInitialized();
    final id = refillNotificationId(medication.id);
    await _plugin.cancel(id); // 覆盖前一次

    final daysLeft = daysUntilRefill(medication.refillAt!, now);
    final details = _dispatcher.buildChannelDetails();
    final payload =
        NotificationDeepLink.medicationCheckIn(medication.id).encode();
    try {
      // v0.30 R108 revisit (P0-012): 续方 title 也去药名 (跟 medication
      //   title 同步), 锁屏不泄漏 PII
      await _dispatcher.zonedAt(
        id: id,
        title: Strings.notifRefillTitle(),
        body: Strings.notifRefillBody(daysLeft),
        fireAt: fireAt,
        details: details,
        payload: payload,
      );
      // v0.25 round 52 (spen P0 #10): med.name 是 PII, 改 medId
      piiSafeLog(
        'RefillNotifier',
        '✅ 续方提醒: medId=${medication.id} '
            'fireAt=$fireAt daysLeft=$daysLeft',
      );
    } catch (e) {
      piiSafeLog('RefillNotifier', '❌ 续方提醒调度失败: $e', error: e);
    }
  }

  /// 取消一个 medication 的续方提醒
  Future<void> cancelRefillReminder(int medicationId) async {
    await _ensureInitialized();
    await _plugin.cancel(refillNotificationId(medicationId));
  }

  /// 重排所有 medication 的续方提醒
  ///
  /// 在 medication 表变化 (增/删/停药) 时统一调。
  /// 一次性清空所有 refill 槽再重排。
  ///
  /// v0.16 round 19 fix: 之前 `_refillBaseId + 1000` 范围太窄，medId >= 1000 时
  /// id 超过 7000 漏 cancel。重排会留下"幽灵通知"。
  /// 改成 200000 覆盖 medId <= 199999（远超实际用户量，且 int32 安全）。
  ///
  /// v0.18 (P2-P0-2): 接受 [MedicationEntity] (domain) 而非 [Medication] (Drift row)
  ///
  /// v0.32 R112 (AR-18): inactive / 无 refillAt / 已过期 的过滤 + fire time
  /// 计算走 ScheduleRefillReminderUseCase (use case 从死代码变活)。
  Future<void> rescheduleRefillReminders(
    List<MedicationEntity> medications,
  ) async {
    await _ensureInitialized();
    // v0.23 (Round 37): cancel 范围走 dispatcher 集中
    await _dispatcher.cancelByIdRange(refillBaseId);
    final now = DateTime.now();
    final schedules = _scheduleUseCase(medications: medications, now: now);
    int scheduled = 0;
    for (final schedule in schedules) {
      if (schedule.fireAt == null || schedule.isExpired) continue;
      final med = medications.firstWhere(
        (m) => m.id == schedule.medicationId,
      );
      await scheduleRefillReminder(med);
      scheduled++;
    }
    piiSafeLog(
      'RefillNotifier',
      '✅ 重排 $scheduled 个 medication 的续方提醒',
    );
  }
}
