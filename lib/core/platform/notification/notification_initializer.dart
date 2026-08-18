// 规则 3 标记: CJK 字面量 = developer 日志/内部 note (非用户可见 UI 文案), 豁免 i18n 扫描
// v0.30 R108 revisit (P0-029): NotificationInitializer 抽自 NotificationService
//
// 拆前: NotificationService facade 482L (init + 5 sub-service 委派 +
//   静态 helper), init() 占 45L (lines 171-215) + _canScheduleExact() 24L
//   (lines 364-387) + timezone setup 11L, 都是"启动期"职责, 跟"日常调度
//   委派"无关。
// 拆后: NotificationService 150L (5 method + 3 const) + 本文件 80L (init +
//   permission + exact alarm + timezone), init/rescheduleAll 拆子类 = 目标
//   达成。
//
// 启动期职责 (本类):
// 1. _plugin.initialize (iOS / Android 平台 + tap 回调注册)
// 2. timezone 数据库初始化 (zonedSchedule 需要)
// 3. 通知 app launch 拉起 payload 解析
// 4. 权限请求 (init 时**不**弹 — R97-P1-6 修过, 由 caller 在 context 内调)
// 5. Android SCHEDULE_EXACT_ALARM 权限运行时检查 (R108 P0-2)
//
// 设计原则:
// - 0 状态 (除了 _initialized bool, 让 facade 保持 facade 本职)
// - 纯 async 函数, 不依赖 Riverpod / drift / domain
// - failure 走 swallowError 集中器 (PIPL §6 错误透明度, release 写 swallow.log)
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:chroniccare/core/platform/notification/notification_delegate.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/shared/error_sinks.dart';

/// v0.30 R108 revisit (P0-029): NotificationInitializer
///
/// 启动期职责: plugin init / timezone / launch payload / 权限 / exact alarm。
/// 跟 [NotificationService] (facade, 5 method 委派) + [NotificationDelegate]
/// (5 sub-service orchestrator) 1:1 平行。
class NotificationInitializer {
  NotificationInitializer({
    required FlutterLocalNotificationsPlugin plugin,
    required void Function(NotificationResponse response) onResponse,
    required NotificationDelegate delegate,
    void Function(String? payload)? onLaunchPayload,
  })  : _plugin = plugin,
        _onResponse = onResponse,
        _delegate = delegate,
        _onLaunchPayload = onLaunchPayload;

  final FlutterLocalNotificationsPlugin _plugin;
  final void Function(NotificationResponse response) _onResponse;
  // 用 NotificationDelegate 持有 [NotificationService] facade 状态 (只读),
  // 保持 facade 作为 SOLE source of truth (R108 revisit P0-031 同款原则)。
  // ignore: unused_field
  final NotificationDelegate _delegate;

  /// v0.32 R112 (R112-ARCH-02): app 被通知拉起的 payload 回调
  /// (生产 = NotificationNavigation.setLaunchPayload, app 层注入 —
  /// data 0 依赖 core/routing 传递 Flutter 依赖)。
  final void Function(String? payload)? _onLaunchPayload;

  bool _initialized = false;

  /// R97-P1-6 (2026-08-07): 权限请求从 init() 中移除。
  ///
  /// 修前 bug (App Store 5.1.1 / Google Play policy): init() 在 main.dart
  /// 启动时调, 立即弹通知权限请求 — 用户还没看到任何 UI, 不知道为什么
  /// 要授权 → 拒绝率高 + 违反"权限应在 context 内请求"指南。
  ///
  /// 修后: init() 只做 plugin 初始化 + 时区 + tap 回调注册, **不请求权限**。
  /// `DarwinInitializationSettings` 的 `request*Permission` 全设 false 避免
  /// iOS 自动弹。权限请求走 [requestPermission], 由 caller 在 context 内调
  /// (e.g. setup 流程配完药后 / 设置页开提醒时 / 测试通知按钮)。
  Future<void> init() async {
    if (_initialized) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      // R97-P1-6: 全 false, 避免初始化时 iOS 自动弹权限请求
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // v0.11 (Round 5): 注册 tap 回调
    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onResponse,
    );

    // v0.11 (Round 5): 处理"app 被杀着，通过通知拉起"的情况
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final payload = launchDetails?.notificationResponse?.payload;
      piiSafeLog(
        'NotificationInitializer',
        '🚀 App 由通知拉起, payload=$payload',
      );
      _onLaunchPayload?.call(payload);
    }

    // 初始化时区数据库 (zonedSchedule 需要)
    try {
      tz_data.initializeTimeZones();
      final localTzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTzName));
    } catch (e) {
      piiSafeLog(
        'NotificationInitializer',
        '⚠️ 时区初始化失败（web 端不支持）: $e',
      );
    }

    _initialized = true;
  }

  /// R97-P1-6 (2026-08-07): 请求通知权限 (在 context 内调)
  ///
  /// 走 iOS `requestPermissions(alert, badge, sound)` + Android
  /// `requestNotificationsPermission()`。caller 应在用户实际需要通知的
  /// 时机调:
  /// - setup 流程配完药准备调度提醒前 (setup_page_state.dart)
  /// - 设置页开提醒 / 改提醒时间 (reminders_hub_page)
  /// - "测试通知"按钮 (notification_status_card._fireTest)
  ///
  /// 返回 true = 用户授权, false = 拒绝 / 平台不支持 / web。
  /// caller 拿到 false 应走 UI 提示引导用户去系统设置开启。
  ///
  /// R113 (BUG 3): 修前 `(iosOk ?? true) || (androidOk ?? true)` 恒返 true —
  /// 跨平台 resolve 总有一个为 null, null 被 ?? true 吞掉 → 权限拒绝
  /// 引导永不触发。修后按"当前平台"分支: 只认自己平台的返回值,
  /// null 视作拒绝 (保守), 双平台都不可用 (web) 才返 true。
  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final iosOk = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    final androidOk = await android?.requestNotificationsPermission();
    if (ios != null) return iosOk ?? false;
    if (android != null) return androidOk ?? false;
    // 双平台都 null = 平台不支持 (web/other) → 视作 true (跟修前行为一致)
    return true;
  }

  /// R108 (P0#2): 检查 Android SCHEDULE_EXACT_ALARM 权限
  ///
  /// 返回 `true` 表示可使用 `exactAllowWhileIdle` mode,
  /// 返回 `false` 表示应降级到 `inexactAllowWhileIdle` (允许 ~15min 漂移)。
  ///
  /// 平台行为:
  /// - iOS: 永远 true (iOS 通知无 exact alarm 概念, 系统会按 schedule 显示)
  /// - Android: 调 `AndroidFlutterLocalNotificationsPlugin.canScheduleExactNotifications()`,
  ///   null / false 都视为不可用 (保守兜底, 走 inexact)
  /// - Web: 永远 false (web 不支持 schedule, 走 inexact 占位, 实际不会真触发)
  /// - 测试环境 (MissingPluginException): 走 false 兜底
  ///
  /// 失败不抛, 走 swallowError 集中器, dev 模式可见, release 写 swallow.log
  Future<bool> canScheduleExact() async {
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) {
        // iOS / Web / desktop: 不需要 exact alarm 概念
        return true;
      }
      final can = await android.canScheduleExactNotifications();
      // null = 平台不支持查询 (老 OS / 未实现), 保守返回 true
      // (走 exact mode, 失败时 zonedSchedule 会自行降级)
      return can ?? true;
    } catch (e, st) {
      // R108 P0-2: 失败不阻塞主流程, 走 inexact 兜底 + log
      // 跟 rescheduleAll 的 canExact=false 路径同, 行为一致
      notificationErrorSink(
        where: 'NotificationInitializer.canScheduleExact',
        error: e,
        stack: st,
        note: 'canScheduleExactNotifications() failed, falling back to inexact',
      );
      return false;
    }
  }
}
// rule3-whitelist: 98, 111
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
