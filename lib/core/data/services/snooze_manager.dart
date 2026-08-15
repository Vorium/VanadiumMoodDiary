// 规则 3 标记: CJK 字面量 = developer 日志/内部 note (非用户可见 UI 文案), 豁免 i18n 扫描
// v0.18 round 18 (P1-28) SnoozeManager — 从 NotificationService 拆出
//
// 设计：facade pattern，NotificationService 公共 API 保持原签名,
// 内部委托给 SnoozeManager。这样:
// - NotificationService 主类减肥 90+ 行
// - Snooze 逻辑独立测试 (不用 mock 整个 notification service)
// - id 公式 + cancel 范围集中在一处
//
// 参考 Pill Reminder (Drugs.com iOS)：
// - 通知来了用户点"Snooze 5min" → 5min 后再响一次
// - 同一 (medId, minutes) 二次触发 = 覆盖原 snooze，不会叠加
// - 打卡后 cancel 该 med 的所有 snooze

import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/l10n/strings.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:chroniccare/core/data/services/notification_payload.dart';

/// Snooze 管理器
///
/// 依赖注入的 plugin（在 NotificationService init 之后才能用），
/// 所以通过 [init] 注入。
class SnoozeManager {
  final FlutterLocalNotificationsPlugin _plugin;

  /// snooze id 起始基数（300000+ 范围，远离 medication/reminder cancel range）
  final int snoozeBaseId;

  /// 每次 1 个 med 最多 1440 个不同 minutes
  final int minutesPerMedication;

  /// 跨 meds 的 cancel 范围（snoozeBaseId + 2000000 足够 medId 几万个）
  final int cancelRange;

  SnoozeManager({
    required FlutterLocalNotificationsPlugin plugin,
    // v0.23 (P0-1 H3 fix): snooze base 从 4000 挪到 300000, 避免被
    //   _dispatcher.cancelByIdRange(2000) [范围 2000..202000) 误杀
    //   旧公式 4000 + medId*1440 + minutes 范围 [5441, 6880] (medId=1) 落入
    //   medication cancel range
    // 新公式 300000 + medId*1440 + minutes 范围 [301441, ...] 远超所有
    //   medication/refill/assessment cancel range (200000 宽)
    this.snoozeBaseId = 300000,
    this.minutesPerMedication = 1440,
    this.cancelRange = 2000000,
  }) : _plugin = plugin;

  /// 调度一个**一次性**延迟通知（snooze 用）
  ///
  /// 设计：用稳定 hash 把 (medId, minutes) → unique id，
  /// 避免用户连续点 snooze 堆出 10 个通知。
  /// - [minutes] 范围 [1, 1440]（最多 24h 后）
  /// - 同一 (medId, minutes) 二次触发 = 覆盖原 snooze，不会叠加
  ///
  /// v0.11 (Round 5): payload 携带 medId,snooze 触发后点通知直达该药
  Future<void> snoozeOnce({
    required int medicationId,
    required int minutes,
    String? title,
    String? body,
  }) async {
    if (minutes <= 0 || minutes > minutesPerMedication) {
      piiSafeLog(
        'SnoozeManager',
        '⚠️ snoozeOnce: minutes=$minutes 越界（1..$minutesPerMedication）',
      );
      return;
    }

    // 稳定 id：snoozeBase + medId * 1440 + minutes
    // 1440 保证同一 med 不同 minutes 之间不冲突
    final id = snoozeBaseId + (medicationId * minutesPerMedication) + minutes;

    // 取消同 id 的旧 snooze（避免叠加）
    await _plugin.cancel(id);

    // v0.27 round 77 (R76-N1 修): channel name/desc 改走 l10n 化函数版
    // (Strings.notifChannelMedication*Text), en/zh_Hant 系统设置看本地化。
    // 老 const 字段 (Strings.notifChannelMedicationName) 仍保留作 fallback。
    // 注: AndroidNotificationDetails 是 const constructor, 但 channelName/desc
    // 现在是 runtime 函数调用, 所以 details 整块不 const — 实际是 Android
    // 平台每次 init channel 时拿到的是新值 (老 channel name 已注册不会被改,
    // 需 uninstall 重装)。
    // v0.31.1 round 6 (P0-05 修 AppStore BUG-2 + emil P0-C): iOS 通知详情加固
    // - categoryIdentifier: 贪睡类 (snooze 跟原 reminder 区分, 长按归类)
    // - interruptionLevel: timeSensitive → 贪睡通知穿透勿扰
    // v0.31.1 round 7 (P0-06 修 GooglePlay P0-006): Android 锁屏 PII 防护
    // - visibility: NotificationVisibility.secret → snooze 通知锁屏隐藏 (跟 reminder 一致)
    // 注: relevanceScore 17.2.4 不暴露, 见 notification_service.dart 同注释。
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'chroniccare.medication',
        Strings.notifChannelMedicationNameText(),
        channelDescription: Strings.notifChannelMedicationDescText(),
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.secret,
      ),
      iOS: const DarwinNotificationDetails(
        categoryIdentifier: 'com.chroniccare.snooze',
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    final fireAt = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
    final payload = medicationId == 0
        ? 'chroniccare://check-in/today'
        : NotificationDeepLink.medicationCheckIn(medicationId).encode();
    try {
      await _plugin.zonedSchedule(
        id,
        title ?? Strings.snoozeTitle,
        body ?? Strings.snoozeBody,
        fireAt,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // 不加 matchDateTimeComponents：只触发一次
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      piiSafeLog(
        'SnoozeManager',
        '✅ snooze ${minutes}min 后触发（med=$medicationId）',
      );
    } catch (e) {
      piiSafeLog('SnoozeManager', '❌ snooze 调度失败: $e');
    }
  }

  /// 取消某个药物的所有 snooze（用户真打卡后调）
  Future<void> cancelSnoozeForMedication(int medicationId) async {
    final pending = await _plugin.pendingNotificationRequests();
    final baseMin = snoozeBaseId + medicationId * minutesPerMedication;
    final baseMax = baseMin + minutesPerMedication;
    for (final p in pending) {
      if (p.id >= baseMin && p.id <= baseMax) {
        await _plugin.cancel(p.id);
      }
    }
  }

  /// 取消所有 snooze（重排 medication reminders 时调）
  ///
  /// snooze id 公式：snoozeBase + medId * 1440 + minutes
  ///   medId 上限：int32 安全 ~1.5M (medId <= 1000)，按当前用户量足够
  /// v0.16 round 19 fix: 之前用 `snoozeBaseId + 100000` 范围太窄，medId >= 72 时
  ///   id 超过 104000 漏 cancel（虽然 snooze 5min 自动清除，但重排时残留）
  Future<void> cancelAllSnoozes() async {
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= snoozeBaseId && p.id < snoozeBaseId + cancelRange) {
        await _plugin.cancel(p.id);
      }
    }
  }
}
