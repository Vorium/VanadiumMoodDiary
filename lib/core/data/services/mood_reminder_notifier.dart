// 规则 3 标记: CJK 字面量 = developer 日志/内部 note (非用户可见 UI 文案), 豁免 i18n 扫描
// v0.30 R101: 情绪记录提醒通知编排
//
// 参照 MedicationNotifier 模式:
// - 每天固定时间 (默认 20:00) 发通知提醒记录心情
// - 委托 ReminderDispatcher 处理 cancel/zonedSchedule
// - 公开 1 个 method + 1 个 const ID
//
// 设计决策:
// - 默认 20:00: 精神心理患者晚间反思最合适
// - 单条通知 (非 per-entry): 用户只需要一次提醒
// - payload = "chroniccare://mood-diary": 点通知直达情绪记录

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/data/services/reminder_dispatcher.dart';
import 'package:chroniccare/core/l10n/strings.dart';

/// 情绪记录提醒通知编排
///
/// 公开 1 个 method:
///   - [scheduleMoodReminder] 每天 hour:minute 提醒记录心情 (id=5000002, v0.32 R110 B1-1 迁 5M+ 带)
///
/// 参照 MedicationNotifier 模式，委托 ReminderDispatcher。
class MoodReminderNotifier {
  /// 情绪记录提醒 id — v0.32 R110 (B1-1): 原 8000 落入 medication/refill
  /// cancel 区间被误杀, 迁 5M+ 固定带
  static const int moodReminderId = 5000002;

  final FlutterLocalNotificationsPlugin _plugin;
  final ReminderDispatcher _dispatcher;
  final Future<void> Function() _ensureInitialized;

  MoodReminderNotifier({
    required FlutterLocalNotificationsPlugin plugin,
    required ReminderDispatcher dispatcher,
    required Future<void> Function() ensureInitialized,
  })  : _plugin = plugin,
        _dispatcher = dispatcher,
        _ensureInitialized = ensureInitialized;

  /// 设置每天 hour:minute 情绪记录提醒
  ///
  /// [enabled] = false 时取消已有通知
  /// web 平台 zonedSchedule 会抛 UnsupportedError, 这里吞掉
  Future<void> scheduleMoodReminder({
    required bool enabled,
    int hour = 20,
    int minute = 0,
  }) async {
    await _ensureInitialized();
    await _plugin.cancel(moodReminderId);

    if (!enabled) {
      piiSafeLog('MoodReminderNotifier', '✅ 情绪记录提醒已关闭');
      return;
    }

    final details = _dispatcher.buildChannelDetails();

    try {
      await _dispatcher.zonedDaily(
        id: moodReminderId,
        title: Strings.notifMoodReminderTitle,
        body: Strings.notifMoodReminderBody,
        hour: hour,
        minute: minute,
        details: details,
        payload: 'chroniccare://mood-diary',
      );
      piiSafeLog(
        'MoodReminderNotifier',
        '✅ 设置情绪记录提醒 $hour:$minute',
      );
    } catch (e) {
      piiSafeLog('MoodReminderNotifier', '❌ 设置情绪记录提醒失败: $e');
    }
  }
}
