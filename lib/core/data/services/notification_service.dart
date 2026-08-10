// v0.24 round 45 (Sprint #5b) — notification_service facade 瘦身
// v0.27 round 65 (Sprint #12) — showSafetyAlert 50 行委派到 SafetyAlertBuilder
// v0.30 R108 (P1 god class 拆 6 大 F - Fix #2) — 12 委派合 `delegate` namespace
//
// 拆解前: 629 行 facade god class
// 拆解后 (R24): 424 行 facade + 4 sub-service + 1 builder
// 拆解后 (R108): 308 行 facade (主体) + NotificationDelegate (160 行) + 4 sub-service + 1 builder
//
// facade 主体保留 (R108 Fix #2 后):
//   - init (60 行): plugin init + tz + 权限
//   - requestPermission (15 行): R97-P1-6 拆分
//   - showNow (20 行): CareEngine 主动 push, NotificationSender 接口
//   - cancelAll (4 行): pass-through 到 _plugin
//   - pendingCount (15 行): pass-through + web 兜底
//   - showSafetyAlert (28 行): 委派 SafetyAlertBuilder.buildFor + _plugin.show
//   - rescheduleAll (30 行): orchestrator + _canScheduleExact (R108 P0#2)
//   - 3 channel const + 1 safety id
//   - 2 visibleForTesting static (refillNotificationId / computeRefillFireTime)
//
// delegate 集中 (R108 新增, 12 method):
//   - MedicationNotifier: scheduleDailyReminder / rescheduleMedicationReminders
//   - MoodReminderNotifier: scheduleMoodReminder
//   - RefillNotifier: scheduleRefillReminder / cancelRefillReminder / rescheduleRefillReminders
//   - AssessmentNotifier: scheduleAssessmentReminder / cancelAssessmentReminder
//   - SnoozeManager: snoozeOnce / cancelSnoozeForMedication / cancelAllSnoozes
//   - BadgeSyncService: updateBadgeCount
//
// 6 类 ID 范围常量 (v0.16 round 19 文档化):
//   1001 (default) < 2000-21999 (med) < 5000 (safety) < 6000-206000 (refill)
//   < 7000 (assessment) < 9999 (badge) < 300000+ (snooze)

import 'package:chroniccare/core/data/services/notification_delegate.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chroniccare/core/data/services/assessment_notifier.dart';
import 'package:chroniccare/core/data/services/badge_sync_service.dart';
import 'package:chroniccare/core/data/services/medication_notifier.dart';
import 'package:chroniccare/core/data/services/mood_reminder_notifier.dart';
import 'package:chroniccare/core/data/services/notification_initializer.dart';
import 'package:chroniccare/core/data/services/notification_payload.dart';
import 'package:chroniccare/core/data/services/refill_notifier.dart';
import 'package:chroniccare/core/data/services/reminder_dispatcher.dart';
import 'package:chroniccare/core/data/services/safety_alert_builder.dart';
import 'package:chroniccare/core/data/services/sms_service.dart';
import 'package:chroniccare/core/data/services/snooze_manager.dart';
import 'package:chroniccare/core/routing/notification_navigation.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/repositories/notification_sender.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';

/// 本地通知服务 (facade god class 已拆 6 sub-service + 1 delegate namespace)
///
/// 6 类通知编排已拆 5 sub-service (SnoozeManager / BadgeSyncService /
/// ReminderDispatcher / MedicationNotifier / RefillNotifier / AssessmentNotifier) +
/// facade 保留 showSafetyAlert (独立 channel 不走 dispatcher)。
///
/// R108 (P1 god class 拆 6 大 F - Fix #2): 12 委派 method 抽到
/// [NotificationDelegate], facade 暴露 `delegate` 字段, caller 改走
/// `service.delegate.xxx(...)` 路径。facade 主体保留 6 method (init /
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

  // ===== 6 sub-service DI (R108 Fix #2 委派合 delegate namespace) =====
  late final ReminderDispatcher _dispatcher;
  late final SnoozeManager _snoozeManager;
  late final BadgeSyncService _badgeSync;
  late final MedicationNotifier _medicationNotifier;
  late final RefillNotifier _refillNotifier;
  late final AssessmentNotifier _assessmentNotifier;
  late final MoodReminderNotifier _moodReminderNotifier;
  // v0.30 R108 revisit (P0-029): 启动期职责抽到 NotificationInitializer
  late final NotificationInitializer _initializer;

  /// R108 (P1 god class 拆 6 大 F - Fix #2): 12 委派 method 集中
  ///
  /// 修前: facade 12 个 1-2 行委派 method 占 60+ 行 = facade 模板残留
  /// 修后: caller 走 `service.delegate.scheduleDailyReminder(...)` 等路径
  ///
  /// init() 在 sub-service 注入完成后立即构造, 跟 sub-service 同生命周期
  late final NotificationDelegate delegate;

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
    _moodReminderNotifier = MoodReminderNotifier(
      plugin: _plugin,
      dispatcher: _dispatcher,
      ensureInitialized: _ensureInitializedProxy,
    );
    // R108 Fix #2: 注入完成的 sub-service 包装成 delegate namespace
    delegate = NotificationDelegate(
      medicationNotifier: _medicationNotifier,
      moodReminderNotifier: _moodReminderNotifier,
      refillNotifier: _refillNotifier,
      assessmentNotifier: _assessmentNotifier,
      snoozeManager: _snoozeManager,
      badgeSync: _badgeSync,
    );
    // v0.30 R108 revisit (P0-029): 启动期职责抽到 NotificationInitializer
    _initializer = NotificationInitializer(
      plugin: _plugin,
      onResponse: _onResponse,
      delegate: delegate,
    );
  }

  static void _defaultOnTap(String? payload) {
    NotificationNavigation.handleTap(payload);
  }

  /// sub-service init 代理 — 委托到本类 init, 保证 sub-service 调用时主 service 已 init
  Future<void> _ensureInitializedProxy() => init();

  /// 初始化 (app 启动时调用)
  ///
  /// R97-P1-6 (2026-08-07): 权限请求从 init() 中移除。
  ///
  /// 修前 bug (App Store 5.1.1 / Google Play policy): init() 在 main.dart
  /// 启动时调, 立即弹通知权限请求 — 用户还没看到任何 UI, 不知道为什么
  /// 要授权 → 拒绝率高 + 违反"权限应在 context 内请求"指南。
  ///
  /// 修后: init() 只做 plugin 初始化 + 时区 + tap 回调注册, **不请求权限**。
  /// `DarwinInitializationSettings` 的 `request*Permission` 全设 false 避免
  /// iOS 自动弹。权限请求走新方法 [requestPermission], 由 caller 在
  /// context 内调 (e.g. setup 流程配完药后 / 设置页开提醒时 / 测试通知按钮)。
  Future<void> init() async {
    // v0.30 R108 revisit (P0-029): 启动期职责抽到 NotificationInitializer
    //   (plugin init / timezone / launch payload / 权限 / exact alarm, ~80L)
    if (_initialized) return;
    await _initializer.init();
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
  /// v0.30 R108 revisit (P0-029): 委派到 NotificationInitializer
  Future<bool> requestPermission() => _initializer.requestPermission();

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
    // v0.31.1 round 6 (P0-05 修 AppStore BUG-2 + emil P0-C): iOS 通知详情加固
    // - categoryIdentifier: iOS UNNotificationCategory 归类 (长按/管理通知分组)
    // - interruptionLevel: timeSensitive → 紧急通知穿透勿扰 + Focus 模式
    // 注: flutter_local_notifications 17.2.4 / 22.3.0 DarwinNotificationDetails
    //   都不暴露 relevanceScore (iOS native UNNotificationContent.relevanceScore),
    //   锁屏 PII 防护的真正开关是 iOS 系统 "Show Previews" 设置, app 端无法绕过。
    //   title/body 已经在 R108 P0-3 / P0-012 修过去 PII (PIPL §23 锁屏公示),
    //   此处只补 iOS 通知 metadata, 跟 safety_alert_builder.dart 模板对齐。
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: 'com.chroniccare.reminder',
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
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

  // ============== rescheduleAll orchestrator (R108 P0#2 + R70 续) ==============
  //
  // v0.27 R70 (R64+ 4 round 挂死的半成品 BootReceiver 简化实现):
  // 重排 medication + refill 推送 (assessment 需 fireAt 单独算, R71 补)。
  //
  // 调用场景: App 每次启动时 (含 BootReceiver 启动 MainActivity 触发的启动)
  // - 不依赖 Android side intent extra (避免 MethodChannel 跨进程集成)
  // - 不依赖 bootReceiverEnabled flag (每次启动 idempotent 重排)
  // - 调用方: main.dart runApp 之后 addPostFrameCallback, 传入从 DB 读的 meds
  //
  // 实现: 调 3 个 sub-notifier 的对应 reschedule。
  // 主流程: SafetyWatchService.onAppStart 已走 bootReceiverEnabled 守门,
  // 跟这里 rescheduleAll 互补 (一个管 safety 通知重排, 一个管全通知重排)。
  //
  // v0.30 R108 (P0#2): SCHEDULE_EXACT_ALARM 运行时权限检查
  //
  // 修前: ReminderDispatcher / SnoozeManager 用 `AndroidScheduleMode.exactAllowWhileIdle`
  // 但未做运行时检查。Android 12+ (API 31) 要求 SCHEDULE_EXACT_ALARM 权限,
  // 13+ (API 33) 用户可撤销。撤回后 zonedSchedule 静默降级 inexact (不 crash,
  // 但提醒延迟 ~15min), 用户报"提醒不准"找不到原因。
  //
  // 修后: rescheduleAll 入口调 [_canScheduleExact], false 时把 dispatcher 的
  // `useExactAllowWhileIdle` 设为 false (走 inexactAllowWhileIdle 兜底) +
  // piiSafeLog 警告, 引导用户去系统设置 (UI 层 NotificationStatusCard
  // 显示状态)。iOS / Web 走 true (iOS 无 exact alarm 概念, Web 不支持 schedule)。
  Future<void> rescheduleAll(List<MedicationEntity> medications) async {
    piiSafeLog('NotificationService', 'rescheduleAll start (R70 简化方案)');
    // R108 P0-2: 运行时检查 SCHEDULE_EXACT_ALARM 权限 (Android only)
    // false → 走 inexactAllowWhileIdle 兜底 (允许 ~15min 漂移, 不阻塞)
    final canExact = await _canScheduleExact();
    _dispatcher.setExactMode(canExact);
    if (!canExact) {
      piiSafeLog(
        'NotificationService',
        '⚠️ R108: SCHEDULE_EXACT_ALARM 不可用, 降级 inexactAllowWhileIdle. '
        'Android 13+ 用户可能从系统设置撤回了权限, 引导重新开启',
      );
    }
    // 1. 每日通用打卡提醒 (id=1001 fallback)
    await delegate.scheduleDailyReminder();
    // 2. medication 推送 (id=2000+medId*10+i)
    await delegate.rescheduleMedicationReminders(medications);
    // 3. refill 续方提醒 (id=6000+medId)
    await delegate.rescheduleRefillReminders(medications);
    piiSafeLog('NotificationService', 'rescheduleAll done');
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
  ///
  /// v0.30 R108 revisit (P0-029): 委派到 NotificationInitializer
  Future<bool> _canScheduleExact() => _initializer.canScheduleExact();

  // ============== SafetyAlert (facade 直实现, 不抽 sub-service) ==============
  //
  // v0.27 round 65 (spen P1-12 god class 拆分收尾):
  // 50 行 facade 委派到 SafetyAlertBuilder.buildFor (5 行),
  // facade 只负责调 _plugin.show, 文案/channel/3 态分流全部走 builder。
  //
  // 决策 (设计文档 §3.2): showSafetyAlert 1 个 method 50 行不值得 1 个 sub-service
  // 走独立 "chroniccare.safety" channel, 不用 ReminderDispatcher (因为是 _plugin.show)

  /// 推送"安全警报"通知 (v0.10 / Round 4 — 死了么思路)
  ///
  /// 和普通 reminder 不同的 channel: 高 importance + 震动 + 锁屏可见
  /// v0.11 (Round 5): payload 携带天数, 点通知直达 home + 显示告警
  /// v0.21 Round 23 (P1-24): userName 改 nullable
  /// 未填姓名时退化为 "您", 避免 "⚠️  已 3 天未打卡" 这种空
  ///
  /// v0.27 round 60 (P0-3 修正): 加 [SmsDispatchOutcome] 参数 + [l10n] 走
  /// i18n, 通知文案 3 态分流 (sent / mocked / failed)。之前 hardcode
  /// "已自动通知紧急联系人", 即使 SMS 没真发出去 (mock 模式 / send 失败)
  /// 也显示, 形成对精神心理患者的"谎言"。修正后:
  ///
  /// - `smsOk > 0` → "已自动通知紧急联系人" (`safetyAlertBodySent`)
  /// - `smsOk == 0 && smsMock > 0` → "失联检测已触发, 但当前为开发模式, 未实际通知" (`safetyAlertBodyMocked`)
  /// - `smsOk == 0 && smsFail > 0` → "失联检测已触发, 但通知发送失败" (`safetyAlertBodyFailed`)
  ///
  /// v0.27 round 65 (P1-12 god class 拆分收尾): title/body/details 构造委派
  /// 到 [SafetyAlertBuilder.buildFor] (纯函数), facade 仅负责调 `_plugin.show`。
  ///
  /// **注意**: 修正后**所有调用方必须传 [outcome] 和 [l10n]**, 用 `SafetyAlertDispatcher`
  /// 提供的 (smsOk, smsFail, smsMock) 计数 + `AppLocalizations.of(context)`。
  /// 直接 `showSafetyAlert(userName:..)` 调会编译失败 (required 参数)。
  Future<void> showSafetyAlert({
    String? userName,
    required int daysWithoutCheckIn,
    required DateTime? lastCheckIn,
    required SmsDispatchOutcome outcome,
    required AppLocalizations l10n,
  }) async {
    await init();
    final build = SafetyAlertBuilder.buildFor(
      userName: userName,
      daysWithoutCheckIn: daysWithoutCheckIn,
      lastCheckIn: lastCheckIn,
      outcome: outcome,
      l10n: l10n,
      channelId: _safetyChannelId,
      channelName: _safetyChannelName,
      channelDescription: _safetyChannelDesc,
    );
    final payload =
        NotificationDeepLink.safetyAlert(daysWithoutCheckIn).encode();
    await _plugin.show(
      safetyAlertId,
      build.title,
      build.body,
      build.details,
      payload: payload,
    );
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
  //
  // R108 Fix #2 修订: 12 委派 method 已抽到 [NotificationDelegate],
  // 上面"6 类常量"列表保持 (sub-service 单一职责)。

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
