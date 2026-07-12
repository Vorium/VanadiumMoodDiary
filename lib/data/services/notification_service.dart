import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// 本地通知服务
///
/// 每天固定时间推送"今天吃了药吗？"提醒
class NotificationService {
  static const _channelId = 'chroniccare.daily';
  static const _channelName = '每日打卡提醒';
  static const _channelDesc = '每天提醒你打卡今天吃了药';
  static const _notificationId = 1001;

  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService()
      : _plugin = FlutterLocalNotificationsPlugin();

  /// 初始化（app 启动时调用）
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // 请求权限
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// 设置每天 20:00 提醒打卡
  ///
  /// [hour] 小时（0-23）
  /// [minute] 分钟（0-59）
  Future<void> scheduleDailyReminder({
    int hour = 20,
    int minute = 0,
  }) async {
    // 先取消旧的
    await _plugin.cancel(_notificationId);

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      // 注意：实际生产环境应该用 zonedSchedule（带时区）
      // MVP 阶段先实现 daily 模式
      await _plugin.periodicallyShow(
        _notificationId,
        '🌱 今天吃了药吗？',
        '点一下 = 打卡，让家人放心',
        RepeatInterval.daily,
        details,
      );

      developer.log('✅ 设置每日 $hour:$minute 提醒', name: 'NotificationService');
    } catch (e) {
      developer.log('❌ 设置提醒失败: $e', name: 'NotificationService');
    }
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
