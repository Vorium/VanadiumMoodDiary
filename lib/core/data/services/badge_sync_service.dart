// v0.22 round 30 (sp-en P2-1): 把 notification_service 的角标更新逻辑
// 抽到独立 BadgeSyncService 类。
//
// 原因：
// - 之前 notification_service 651 行 + 0 测试, 单一 god class
// - 角标逻辑(iOS DarwinNotificationDetails)跟 medication reminder 编排
//   完全独立, 拆出去更易单测
// - 单测补: BadgeSyncService 接受 plugin 参数, mock FlutterLocalNotificationsPlugin
//   验证 _badgeVirtualId / count clamp / catch 不抛 等
//
// 设计取舍：
// - 不依赖 NotificationSender 抽象 (避免引入新接口) — 直接接受 plugin
// - piiSafeLog 内部调用, 不暴露日志格式

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/l10n/strings.dart';

/// 角标同步 (iOS badge 数字)
class BadgeSyncService {
  final FlutterLocalNotificationsPlugin _plugin;

  /// 虚拟通知 id — 一个稳定的"空"通知携带 badgeNumber
  /// iOS 路径每次 show 之前 cancel 同一个 id, 所以固定即可
  /// 不跟 _defaultReminderId(1001) / _medicationReminderBaseId(2000-21999) /
  ///   _safetyAlertId(5000) / _refillBaseId(6000-7999) / _assessmentReminderId(7000) 冲突
  static const int badgeVirtualId = 9999;

  // 跟 notification_service 共用 channel (避免创建新 channel 浪费权限)
  // badge 用 importance.min (不弹不响), 共用 medication channel 没事
  static const String _channelId = 'chroniccare.medication';
  static const String _channelName = Strings.notifChannelMedicationName;
  static const String _channelDesc = Strings.notifChannelMedicationDesc;

  BadgeSyncService({required FlutterLocalNotificationsPlugin plugin})
      : _plugin = plugin;

  /// 更新角标数字
  ///
  /// [count] 传 0 即清零, 负数 clamp 到 0
  /// 限制: flutter_local_notifications 17.x 没有 setBadgeCount 原生 API
  /// 退而求其次: 发一条"带 badgeNumber"的"空"通知 (iOS 自动更新角标)
  /// - iOS: [DarwinNotificationDetails.badgeNumber] 是公开 API (已用)
  /// - Android: 暂无稳定方案 (各 ROM 支持不一: MIUI / EMUI / OneUI / Pixel 等
  ///   launcher app icon badge 实现差异大, 第三方插件 flutter_app_badge_control
  ///   覆盖不全, 误用反而漏显示)。
  ///
  /// v0.27 R70 决策: 删 "v0.10+ TODO 集成 flutter_app_badge_control" 挂 18+ 月 TODO,
  /// 走"iOS badge 真接 + Android 角标靠 launcher notification dot + 应用图标角标
  /// (Android 8+ 主流 launcher 都支持 unread count 显示)"。后者靠用户操作触发
  /// (点开 App 时角标自动清, 跟 flutter_local_notifications 集成) — 跟 v0.27 业务
  /// 模型 (本地存储 + 24h 周期打卡) 一致。
  Future<void> updateBadgeCount(int count) async {
    final safeCount = count < 0 ? 0 : count;
    try {
      final details = NotificationDetails(
        android: const AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.min, // 不弹不响
          priority: Priority.min,
          ongoing: true,
          autoCancel: false,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: true,
          presentSound: false,
          badgeNumber: safeCount,
        ),
      );
      // 先取消旧的虚拟通知
      await _plugin.cancel(badgeVirtualId);
      await _plugin.show(
        badgeVirtualId,
        '',
        '',
        details,
      );
      piiSafeLog('BadgeSyncService', '✅ 角标已更新 = $safeCount');
    } catch (e) {
      piiSafeLog(
        'BadgeSyncService',
        '⚠️ updateBadgeCount 失败（不影响功能）: $e',
      );
    }
  }
}
