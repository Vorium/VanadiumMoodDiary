// v0.24 round 45 (Sprint #5b) — notification_service facade 瘦身
//
// 拆解前: 629 行 facade god class
// 拆解后: 250 行 facade + 3 个新 sub-service
//   - MedicationNotifier  (153 行) — daily check-in + medication
//   - RefillNotifier      (204 行) — refill 编排
//   - AssessmentNotifier  (90 行)  — 评估周期提醒
//   - SnoozeManager       (90 行, 保留)
//   - BadgeSyncService    (40 行, 保留)
//   - ReminderDispatcher  (146 行, 保留, 共享给 3 new sub-service)
//
// 6 类 ID 范围常量 (v0.16 round 19 文档化):
//   1001 (default) < 2000-21999 (med) < 5000 (safety) < 6000-206000 (refill)
//   < 7000 (assessment) < 9999 (badge) < 300000+ (snooze)
//
// facade 保留:
//   - init (60 行): plugin init + tz + 权限
//   - showNow (NotificationSender 抽象方法)
//   - cancelAll / pendingCount (pass-through 到 _plugin)
//   - showSafetyAlert (50 行, 独立 channel, 跟 dispatcher 无关, 不抽 sub-service)
//   - 5 sub-service 委托 (30 行: snooze / badge / 3 orchestrator)
//   - safety alert id (5000) + channel 3 const

import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/core/shared/user_name_helper.dart';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:chroniccare/core/data/services/assessment_notifier.dart';
import 'package:chroniccare/core/data/services/badge_sync_service.dart';
import 'package:chroniccare/core/data/services/medication_notifier.dart';
import 'package:chroniccare/core/data/services/notification_payload.dart';
import 'package:chroniccare/core/data/services/refill_notifier.dart';
import 'package:chroniccare/core/data/services/reminder_dispatcher.dart';
import 'package:chroniccare/core/data/services/snooze_manager.dart';
import 'package:chroniccare/core/routing/notification_navigation.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/repositories/notification_sender.dart';

/// 本地通知服务 (facade god class 已拆 6 sub-service)
///
/// 6 类通知编排已拆 5 sub-service (SnoozeManager / BadgeSyncService /
/// ReminderDispatcher / MedicationNotifier / RefillNotifier / AssessmentNotifier) +
/// facade 保留 showSafetyAlert (独立 channel 不走 dispatcher)。
///
/// v0.7 升级保留:
/// - 每天 20:00 通用打卡提醒 (在 MedicationNotifier)
/// - 每个 medication 每个 time 配 zonedSchedule 推送 (在 MedicationNotifier)
/// - "漏 1 天" 主动 push 安慰 (在 facade showSafetyAlert)
class NotificationService implements NotificationSender {
  // ===== 3 channel const + 1 safety id (facade 直持) =====
  static const _channelId = 'chroniccare.medication';
  static const _channelName = Strings.notifChannelMedicationName;
  static const _channelDesc = Strings.notifChannelMedicationDesc;
  // safety channel (跟 medication channel 分开, 独立 importance=alarm)
  static const _safetyChannelId = 'chroniccare.safety';
  static const _safetyChannelName = Strings.notifChannelSafetyName;
  static const _safetyChannelDesc = Strings.notifChannelSafetyDesc;
  /// 安全警报 id (5000) — 跟 medication 2000+ / refill 6000+ / assessment 7000 / badge 9999 不冲突
  static const int safetyAlertId = 5000;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  // ===== 6 sub-service DI (emil 决策: constructor DI 模式, 跟 mood_dialog 拆解同) =====
  late final ReminderDispatcher _dispatcher;
  late final SnoozeManager _snoozeManager;
  late final BadgeSyncService _badgeSync;
  late final MedicationNotifier _medicationNotifier;
  late final RefillNotifier _refillNotifier;
  late final AssessmentNotifier _assessmentNotifier;

  /// v0.11 (Round 5): 用户点通知的回调
  /// 默认调 [NotificationNavigation.handleTap]
  final void Function(String? payload) onNotificationTap;

  NotificationService({this.onNotificationTap = _defaultOnTap})
      : _plugin = FlutterLocalNotificationsPlugin() {
    // 6 sub-service 在 constructor 注入 (DI 模式, emil 推荐 testability)
    // ReminderDispatcher 是 SnoozeManager / MedicationNotifier / RefillNotifier / AssessmentNotifier 的共享底层
    _dispatcher = ReminderDispatcher(
      plugin: _plugin,
      channelId: _channelId,
      channelName: _channelName,
      channelDescription: _channelDesc,
    );
    _snoozeManager = SnoozeManager(plugin: _plugin);
    _badgeSync = BadgeSyncService(plugin: _plugin);
    _medicationNotifier = MedicationNotifier(
      plugin: _plugin,
      dispatcher: _dispatcher,
      ensureInitialized: _ensureInitializedProxy,
    );
    _refillNotifier = RefillNotifier(
      plugin: _plugin,
      dispatcher: _dispatcher,
      ensureInitialized: _ensureInitializedProxy,
    );
    _assessmentNotifier = AssessmentNotifier(
      plugin: _plugin,
      dispatcher: _dispatcher,
      ensureInitialized: _ensureInitializedProxy,
    );
  }

  static void _defaultOnTap(String? payload) {
    NotificationNavigation.handleTap(payload);
  }

  /// sub-service init 代理 — 委托到本类 init, 保证 sub-service 调用时主 service 已 init
  Future<void> _ensureInitializedProxy() => init();

  /// 初始化 (app 启动时调用)
  Future<void> init() async {
    if (_initialized) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
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
        'NotificationService',
        '🚀 App 由通知拉起, payload=$payload',
      );
      NotificationNavigation.setLaunchPayload(payload);
    }

    // 初始化时区数据库 (zonedSchedule 需要)
    try {
      tz_data.initializeTimeZones();
      final localTzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTzName));
    } catch (e) {
      piiSafeLog(
        'NotificationService',
        '⚠️ 时区初始化失败（web 端不支持）: $e',
      );
    }

    // 请求权限
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// flutter_local_notifications 回调
  static void _onResponse(NotificationResponse response) {
    piiSafeLog(
      'NotificationService',
      '👆 通知被点击, payload=${response.payload}',
    );
    _defaultOnTap(response.payload);
  }

  /// 立即显示一条通知 (不调度, 立即推)
  ///
  /// 用于 CareEngine 触发的主动 push (不是定时任务)
  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// 待发通知数量 (用于 UI 自检展示)
  ///
  /// v0.16 round 20 (OEM 后台引导): 让用户能在设置页直观看到
  /// "我设的提醒都在排队", 如果显示 0 条说明没设上或被 OEM 杀掉
  /// 返回 -1 表示平台不支持 (web / desktop)
  Future<int> get pendingCount async {
    await init();
    try {
      final list = await _plugin.pendingNotificationRequests();
      return list.length;
    } catch (e) {
      // web 平台 / 未实现 plugin: pendingNotificationRequests 抛 PlatformException
      piiSafeLog(
        'NotificationService',
        '⚠️ pendingCount 读取失败 (可能 web 端): $e',
      );
      return -1;
    }
  }

  // ============== MedicationNotifier 委托 ==============

  /// 设置每天 hour:minute 通用打卡提醒 (id=1001, fallback)
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) =>
      _medicationNotifier.scheduleDailyReminder(hour: hour, minute: minute);

  /// 重排所有 medication 的推送 (id=2000+medId*10+i)
  Future<void> rescheduleMedicationReminders(
    List<MedicationEntity> medications,
  ) =>
      _medicationNotifier.rescheduleMedicationReminders(medications);

  // ============== RefillNotifier 委托 ==============

  /// 调度一个 medication 的续方提醒
  Future<void> scheduleRefillReminder(MedicationEntity medication) =>
      _refillNotifier.scheduleRefillReminder(medication);

  /// 取消一个 medication 的续方提醒
  Future<void> cancelRefillReminder(int medicationId) =>
      _refillNotifier.cancelRefillReminder(medicationId);

  /// 重排所有 medication 的续方提醒
  Future<void> rescheduleRefillReminders(
    List<MedicationEntity> medications,
  ) =>
      _refillNotifier.rescheduleRefillReminders(medications);

  // ============== AssessmentNotifier 委托 ==============

  /// 调度一条心理评估周期提醒
  Future<void> scheduleAssessmentReminder({
    required DateTime fireAt,
    String scaleId = 'phq9',
    int days = 14,
  }) =>
      _assessmentNotifier.scheduleAssessmentReminder(
        fireAt: fireAt,
        scaleId: scaleId,
        days: days,
      );

  /// 取消心理评估周期提醒
  Future<void> cancelAssessmentReminder() =>
      _assessmentNotifier.cancelAssessmentReminder();

  // ============== SnoozeManager 委托 ==============
  //
  // v0.18 round 18 (P1-28): Snooze 3 个 method 拆到 SnoozeManager
  // 主 service 公共 API 保留, 内部委托 _snoozeManager。
  // 这样:
  // - notification_service.dart 主类减肥 90+ 行
  // - snooze 逻辑独立测试 (mock SnoozeManager 不用 mock 整个 notification)
  // - id 公式 + cancel 范围集中在一处

  /// 调度一个一次性延迟通知 (snooze 用)
  Future<void> snoozeOnce({
    required int medicationId,
    required int minutes,
    String? title,
    String? body,
  }) async {
    await init();
    await _snoozeManager.snoozeOnce(
      medicationId: medicationId,
      minutes: minutes,
      title: title,
      body: body,
    );
  }

  /// 取消某个药物的所有 snooze (用户真打卡后调)
  Future<void> cancelSnoozeForMedication(int medicationId) async {
    await init();
    await _snoozeManager.cancelSnoozeForMedication(medicationId);
  }

  /// 取消所有 snooze (重排 medication reminders 时调)
  Future<void> cancelAllSnoozes() async {
    await init();
    await _snoozeManager.cancelAllSnoozes();
  }

  // ============== SafetyAlert (facade 直实现, 不抽 sub-service) ==============
  //
  // 决策 (设计文档 §3.2): showSafetyAlert 1 个 method 50 行不值得 1 个 sub-service
  // 走独立 "chroniccare.safety" channel, 不用 ReminderDispatcher (因为是 _plugin.show)

  /// 推送"安全警报"通知 (v0.10 / Round 4 — 死了么思路)
  ///
  /// 和普通 reminder 不同的 channel: 高 importance + 震动 + 锁屏可见
  /// v0.11 (Round 5): payload 携带天数, 点通知直达 home + 显示告警
  /// v0.21 Round 23 (P1-24): userName 改 nullable
  /// 未填姓名时退化为 "您", 避免 "⚠️  已 3 天未打卡" 这种空
  Future<void> showSafetyAlert({
    String? userName,
    required int daysWithoutCheckIn,
    required DateTime? lastCheckIn,
  }) async {
    await init();

    final name = safeUserName(userName);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _safetyChannelId,
        _safetyChannelName,
        channelDescription: _safetyChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    final lastStr = lastCheckIn == null
        ? '从未打卡'
        : '${lastCheckIn.year}-${lastCheckIn.month.toString().padLeft(2, '0')}-${lastCheckIn.day.toString().padLeft(2, '0')}';

    final payload =
        NotificationDeepLink.safetyAlert(daysWithoutCheckIn).encode();
    await _plugin.show(
      safetyAlertId,
      '⚠️ $name 已 $daysWithoutCheckIn 天未打卡',
      '上次打卡: $lastStr。已自动通知紧急联系人，请确认安全。',
      details,
      payload: payload,
    );
  }

  // ============== BadgeSyncService 委托 ==============
  //
  // v0.22 round 30 (sp-en P2-1): 角标逻辑拆到 BadgeSyncService
  // 主 service 仅保留委托 (向后兼容 NotificationSender 抽象)。

  /// 更新角标数字 (iOS only — Android 留 TODO)
  ///
  /// 限制: flutter_local_notifications 17.x **没有** setBadgeCount 原生 API。
  /// - iOS: [DarwinNotificationDetails] 的 badgeNumber 字段是公开 API
  /// - Android: 暂无稳定方案。v0.10+ TODO: 集成 flutter_app_badge_control 插件
  ///
  /// [count] 传 0 即清零
  Future<void> updateBadgeCount(int count) async {
    await init();
    await _badgeSync.updateBadgeCount(count);
  }

  // ============== ID 范围常量 (跨 sub-service 文档化) ==============
  //
  // 6 类常量散落到 6 sub-service (单一职责), 这里留文档化列表:
  //   - MedicationNotifier.defaultReminderId       = 1001
  //   - MedicationNotifier.medicationReminderBaseId = 2000
  //   - safetyAlertId                              = 5000
  //   - RefillNotifier.refillBaseId                = 6000
  //   - AssessmentNotifier.assessmentReminderId    = 7000
  //   - BadgeSyncService.badgeVirtualId            = 9999
  //   - SnoozeManager.snoozeBaseId                 = 300000
  // 顺序保证 cancel range 不冲突 (每个 base 间隔 200000+ 远).

  /// v0.16 round 19B: 通知 id 公式兼容访问 (供现有 test 引用)
  ///
  /// 新代码请用 `RefillNotifier.refillNotificationId(medId)`。
  /// 保留 facade 公开 alias 是为了让旧 test (round 9) 不用改太多。
  @visibleForTesting
  static int refillNotificationId(int medicationId) =>
      RefillNotifier.refillNotificationId(medicationId);

  /// v0.16 round 19B: 续方触发时间公式兼容访问
  @visibleForTesting
  static DateTime? computeRefillFireTime({
    required DateTime? refillAt,
    required int reminderDays,
  }) =>
      RefillNotifier.computeRefillFireTime(
        refillAt: refillAt,
        reminderDays: reminderDays,
      );
}
