// R113 (BUG 3): NotificationInitializer.requestPermission() 恒返 true — 回归测试
//
// 修前: `(iosOk ?? true) || (androidOk ?? true)` —
//   跨平台 resolve 总有一个为 null (iOS 上 android==null, Android 上 ios==null),
//   null 被 ?? true 吞掉 → 恒返 true → 权限拒绝引导 (设置页) 永不触发。
// 修后: 按当前平台分支 — 只认自己平台的返回值, null 视作拒绝。
//
// 测试方法: 替换 FlutterLocalNotificationsPlatform.instance 为 fake 平台实现
//   (真实实现走 MethodChannel, 测试环境无 native 端), 用
//   debugDefaultTargetPlatformOverride 切 iOS/Android。
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';

import 'package:chroniccare/core/data/services/assessment_notifier.dart';
import 'package:chroniccare/core/data/services/badge_sync_service.dart';
import 'package:chroniccare/core/data/services/medication_notifier.dart';
import 'package:chroniccare/core/data/services/mood_reminder_notifier.dart';
import 'package:chroniccare/core/platform/notification/notification_delegate.dart';
import 'package:chroniccare/core/platform/notification/notification_initializer.dart';
import 'package:chroniccare/core/data/services/refill_notifier.dart';
import 'package:chroniccare/core/platform/notification/reminder_dispatcher.dart';
import 'package:chroniccare/core/platform/notification/snooze_manager.dart';

/// Android fake: requestNotificationsPermission() 返回注入值
class _FakeAndroidPlugin extends AndroidFlutterLocalNotificationsPlugin {
  final bool? granted;
  _FakeAndroidPlugin(this.granted);

  @override
  Future<bool?> requestNotificationsPermission() async => granted;
}

/// iOS fake: requestPermissions() 返回注入值
class _FakeIosPlugin extends IOSFlutterLocalNotificationsPlugin {
  final bool? granted;
  _FakeIosPlugin(this.granted);

  @override
  Future<bool?> requestPermissions({
    bool sound = false,
    bool alert = false,
    bool badge = false,
    bool provisional = false,
    bool critical = false,
  }) async =>
      granted;
}

NotificationInitializer _buildInitializer(
    FlutterLocalNotificationsPlugin plugin) {
  final dispatcher = ReminderDispatcher(
    plugin: plugin,
    channelId: 'test_channel',
    channelName: 'test',
    channelDescription: 'test',
  );
  final delegate = NotificationDelegate(
    medicationNotifier: MedicationNotifier(
      plugin: plugin,
      dispatcher: dispatcher,
      ensureInitialized: () async {},
    ),
    moodReminderNotifier: MoodReminderNotifier(
      plugin: plugin,
      dispatcher: dispatcher,
      ensureInitialized: () async {},
    ),
    refillNotifier: RefillNotifier(
      plugin: plugin,
      dispatcher: dispatcher,
      ensureInitialized: () async {},
    ),
    assessmentNotifier: AssessmentNotifier(
      plugin: plugin,
      dispatcher: dispatcher,
      ensureInitialized: () async {},
    ),
    snoozeManager: SnoozeManager(plugin: plugin),
    badgeSync: BadgeSyncService(plugin: plugin),
  );
  return NotificationInitializer(
    plugin: plugin,
    onResponse: (_) {},
    delegate: delegate,
  );
}

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('R113 (BUG 3) requestPermission 平台分支', () {
    // 注意: 必须先创建 FlutterLocalNotificationsPlugin() (static _instance
    // 构造会按 defaultTargetPlatform 覆盖 FlutterLocalNotificationsPlatform.instance),
    // 再替换成 fake — 否则真实插件构造会把 fake 覆盖掉。
    NotificationInitializer build(TargetPlatform platform) {
      final plugin = FlutterLocalNotificationsPlugin();
      debugDefaultTargetPlatformOverride = platform;
      if (platform == TargetPlatform.iOS) {
        FlutterLocalNotificationsPlatform.instance = _FakeIosPlugin(false);
      } else {
        FlutterLocalNotificationsPlatform.instance = _FakeAndroidPlugin(false);
      }
      return _buildInitializer(plugin);
    }

    test('Android 拒绝 → false (修前恒 true)', () async {
      final initializer = build(TargetPlatform.android);

      final result = await initializer.requestPermission();
      expect(
        result,
        isFalse,
        reason: 'Android 用户拒绝 → 必须返 false, 引导用户去系统设置',
      );
    });

    test('Android 授权 → true', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final plugin = FlutterLocalNotificationsPlugin();
      FlutterLocalNotificationsPlatform.instance = _FakeAndroidPlugin(true);
      final initializer = _buildInitializer(plugin);

      final result = await initializer.requestPermission();
      expect(result, isTrue);
    });

    test('iOS 拒绝 → false (修前恒 true)', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final plugin = FlutterLocalNotificationsPlugin();
      FlutterLocalNotificationsPlatform.instance = _FakeIosPlugin(false);
      final initializer = _buildInitializer(plugin);

      final result = await initializer.requestPermission();
      expect(
        result,
        isFalse,
        reason: 'iOS 用户拒绝 → 必须返 false, 引导用户去系统设置',
      );
    });

    test('iOS 授权 → true', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final plugin = FlutterLocalNotificationsPlugin();
      FlutterLocalNotificationsPlatform.instance = _FakeIosPlugin(true);
      final initializer = _buildInitializer(plugin);

      final result = await initializer.requestPermission();
      expect(result, isTrue);
    });

    test('平台实现返回 null (模拟异常平台) → 保守返 false', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final plugin = FlutterLocalNotificationsPlugin();
      FlutterLocalNotificationsPlatform.instance = _FakeAndroidPlugin(null);
      final initializer = _buildInitializer(plugin);

      final result = await initializer.requestPermission();
      expect(
        result,
        isFalse,
        reason: 'null = 查询失败, 保守视作拒绝 (修前 ?? true 吞掉)',
      );
    });
  });
}
