// v0.24 round 45 → v0.27 round 65 → v0.30 R108 (Fix #2) →
// 1.1.0 round 4b (safety 整摘) → 1.1.0 round 12k (R120 P1-2 facade 收紧)
//
// 1.1.0 round 12k (R120 P1-2 god class split): 386L → ~190L
//   1) 30L NotificationDetails 抽 _buildNotificationDetails() 私有方法
//   2) 40L 跨 sub-service ID range 文档 → docs/architecture/NOTIFICATION_ID_BANDS.md
//   3) 32L 历史注释压缩到 12L 摘要
//
// 5 大 facade method 责任 (R120 后主 facade 只剩 5 个 1-line 委派 + 1 个
// orchestrator + 1 个 sendNow + 2 个 visibleForTesting 兼容 alias):
//   - init / requestPermission: 启动期 (委派到 NotificationInitializer)
//   - showNow: 主动 push (含 NotificationDetails 构建)
//   - cancelAll / pendingCount: 平台 pass-through
//   - rescheduleAll: orchestrator (R70 简化方案 + R108 P0-2 exact alarm 检查)
// 7 sub-service + 1 delegate + 1 initializer 仍由 facade 持有, 不变。
import 'package:chroniccare/core/data/services/notification_delegate.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/l10n/strings.dart';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chroniccare/core/data/services/assessment_notifier.dart';
import 'package:chroniccare/core/data/services/badge_sync_service.dart';
import 'package:chroniccare/core/data/services/medication_notifier.dart';
import 'package:chroniccare/core/data/services/mood_reminder_notifier.dart';
import 'package:chroniccare/core/data/services/notification_initializer.dart';
import 'package:chroniccare/core/data/services/refill_notifier.dart';
import 'package:chroniccare/core/data/services/reminder_dispatcher.dart';
import 'package:chroniccare/core/data/services/snooze_manager.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/repositories/notification_sender.dart';

/// 本地通知 facade — 7 sub-service + 1 delegate + 1 initializer 编排
///
/// 1.1.0 round 12k (R120 P1-2): 主 facade 已收窄到 5 大方法 + 1 orchestrator
/// + 1 sendNow + 2 兼容 alias + DI 构造。所有跨 sub-service 的 ID band 编排
/// 文档化在 [docs/architecture/NOTIFICATION_ID_BANDS.md](docs/architecture/NOTIFICATION_ID_BANDS.md)。
///
/// 1.1.0 round 4b: showSafetyAlert (失联安全警报) 随外联服务整摘删除。
class NotificationService implements NotificationSender {
  // ===== 2 channel const (facade 直持, medication channel 走 ReminderDispatcher) =====
  static const _channelId = 'chroniccare.medication';
  static const _channelName = Strings.notifChannelMedicationName;
  static const _channelDesc = Strings.notifChannelMedicationDesc;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  // ===== 7 sub-service DI =====
  late final ReminderDispatcher _dispatcher;
  late final SnoozeManager _snoozeManager;
  late final BadgeSyncService _badgeSync;
  late final MedicationNotifier _medicationNotifier;
  late final RefillNotifier _refillNotifier;
  late final AssessmentNotifier _assessmentNotifier;
  late final MoodReminderNotifier _moodReminderNotifier;
  late final NotificationInitializer _initializer;

  /// R108 Fix #2: 12 委派 method 集中。caller 走 `service.delegate.xxx(...)` 路径
  late final NotificationDelegate delegate;

  /// R112-ARCH-02: 用户点通知回调。app 层注入 `NotificationNavigation.handleTap`。
  final void Function(String? payload)? onNotificationTap;

  /// R112-ARCH-02: app 被通知拉起的 payload 回调
  final void Function(String? payload)? onLaunchPayload;

  NotificationService({this.onNotificationTap, this.onLaunchPayload})
      : _plugin = FlutterLocalNotificationsPlugin() {
    // DI 注入 (emil 推荐 testability 模式)
    _dispatcher = ReminderDispatcher(
      plugin: _plugin,
      channelId: _channelId,
      channelName: _channelName,
      channelDescription: _channelDesc,
    );
    // R114 B1-2: snooze 接 dispatcher.scheduleMode — 与主提醒同进退
    _snoozeManager = SnoozeManager(
      plugin: _plugin,
      scheduleModeProvider: () => _dispatcher.scheduleMode,
    );
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
    delegate = NotificationDelegate(
      medicationNotifier: _medicationNotifier,
      moodReminderNotifier: _moodReminderNotifier,
      refillNotifier: _refillNotifier,
      assessmentNotifier: _assessmentNotifier,
      snoozeManager: _snoozeManager,
      badgeSync: _badgeSync,
    );
    _initializer = NotificationInitializer(
      plugin: _plugin,
      onResponse: _onResponse,
      delegate: delegate,
      onLaunchPayload: onLaunchPayload,
    );
  }

  /// sub-service init 代理 — 委托到本类 init, 保证 sub-service 调用时主 service 已 init
  Future<void> _ensureInitializedProxy() => init();

  /// 初始化 (app 启动时调用)。R97-P1-6: **不请求权限**, 走 [requestPermission] 单独调
  Future<void> init() async {
    if (_initialized) return;
    await _initializer.init();
    _initialized = true;
  }

  /// R97-P1-6: 请求通知权限 (在 context 内调, 不在 init 里)
  Future<bool> requestPermission() => _initializer.requestPermission();

  /// flutter_local_notifications 回调 (R112-ARCH-02: 改 instance method)
  void _onResponse(NotificationResponse response) {
    piiSafeLog(
      'NotificationService',
      '👆 通知被点击, payload=${response.payload}',
    );
    onNotificationTap?.call(response.payload);
  }

  /// 立即显示一条通知 (不调度, 立即推) — 用于主动 push
  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await init();
    await _plugin.show(id, title, body, _buildNotificationDetails(), payload: payload);
  }

  /// R120 P1-2 抽出: 通知详情构建 (Android 锁屏 PII secret + iOS timeSensitive)
  ///
  /// v0.31.1 round 6 (P0-05 修 AppStore BUG-2 + emil P0-C): iOS 通知详情加固
  /// - categoryIdentifier: iOS UNNotificationCategory 归类
  /// - interruptionLevel: timeSensitive → 紧急通知穿透勿扰 + Focus 模式
  /// v0.31.1 round 7 (P0-06 修 GooglePlay P0-006): Android 锁屏 PII 防护
  /// - visibility: NotificationVisibility.secret → Android 7+ 锁屏完全不显示
  ///   title/body (仅显示 "ChronicCare"), 防止偷看手机时推断精神心理 / 慢病
  /// 1.1.0 round 4b: 原 safety_alert_builder.dart 模板已随外联服务整摘。
  NotificationDetails _buildNotificationDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          visibility: NotificationVisibility.secret,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'com.chroniccare.reminder',
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

  /// 取消所有通知
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// 待发通知数量 (UI 自检)。返回 -1 表示平台不支持 (web / desktop)
  Future<int> get pendingCount async {
    await init();
    try {
      final list = await _plugin.pendingNotificationRequests();
      return list.length;
    } catch (e) {
      piiSafeLog(
        'NotificationService',
        '⚠️ pendingCount 读取失败 (可能 web 端): $e',
      );
      return -1;
    }
  }

  // ============== rescheduleAll orchestrator ==============
  //
  // v0.27 R70: 重排 medication + refill 推送 (assessment R71 补)。
  // 1.1.0 round 4b: SafetyWatchService.onAppStart 整摘, rescheduleAll 管全通知。
  // v0.30 R108 (P0#2): SCHEDULE_EXACT_ALARM 运行时检查
  //   - 修前: Android 13+ 用户撤回权限后 zonedSchedule 静默降级 inexact (~15min 漂移)
  //   - 修后: rescheduleAll 入口调 [_canScheduleExact], false 走 inexactAllowWhileIdle
  Future<void> rescheduleAll(List<MedicationEntity> medications) async {
    piiSafeLog('NotificationService', 'rescheduleAll start (R70 简化方案)');
    final canExact = await _canScheduleExact();
    // R108 P0#2: 把 canExact 同步到 dispatcher.useExactAllowWhileIdle
    // (true → exactAllowWhileIdle, false → inexactAllowWhileIdle 兜底)
    _dispatcher.setExactMode(canExact);
    if (!canExact) {
      piiSafeLog(
        'NotificationService',
        '⚠️ R108: SCHEDULE_EXACT_ALARM 不可用, 降级 inexactAllowWhileIdle. '
            'Android 13+ 用户可能从系统设置撤回了权限, 引导重新开启',
      );
    }
    await delegate.scheduleDailyReminder();
    await delegate.rescheduleMedicationReminders(medications);
    await delegate.rescheduleRefillReminders(medications);
    piiSafeLog('NotificationService', 'rescheduleAll done');
  }

  /// R108 P0#2: 检查 Android SCHEDULE_EXACT_ALARM 权限 (委派到 NotificationInitializer)
  ///
  /// 返回 `true` = 可 exact, `false` = 走 inexactAllowWhileIdle
  /// - iOS: 永远 true
  /// - Android: 调 `canScheduleExactNotifications()`, null/false 走 inexact
  /// - Web: 永远 false
  /// - 测试环境 (MissingPluginException): false 兜底
  /// 失败不抛, 走 swallowError 集中器, dev 模式可见, release 写 swallow.log
  Future<bool> _canScheduleExact() => _initializer.canScheduleExact();

  /// v0.16 round 19B: 通知 id 公式兼容访问 (供现有 test 引用)。
  /// 新代码请用 `RefillNotifier.refillNotificationId(medId)`。
  ///
  /// v1.1.0+160 R121 P1-3 (emil 维度): 加 @Deprecated 标记, 提示 caller 主动迁移
  /// 到 RefillNotifier 静态方法。此 facade 静态方法将在 v1.1 移除
  /// (refill_notification_id_band_round110 回归测试覆盖, 不破坏 test 链)
  @Deprecated(
    '新代码请用 RefillNotifier.refillNotificationId(medId); '
    '此 facade 静态 alias 将在 v1.1 移除',
  )
  @visibleForTesting
  static int refillNotificationId(int medicationId) =>
      RefillNotifier.refillNotificationId(medicationId);

  /// v0.16 round 19B: 续方触发时间公式兼容访问
  ///
  /// v1.1.0+160 R121 P1-3 (emil 维度): 加 @Deprecated 标记
  @Deprecated(
    '新代码请用 RefillNotifier.computeRefillFireTime; '
    '此 facade 静态 alias 将在 v1.1 移除',
  )
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
// 跨 sub-service ID range 编排: docs/architecture/NOTIFICATION_ID_BANDS.md
// rule3-whitelist: 137, 193, 207, 215-216
//   R120 P1-2 (1.1.0 round 12k): 行号随 facade 收紧 (386L→252L) 重新计位
//   原行号 205, 271, 303, 312-313 (R114 B1-2/B1-3 + R113 BUG A 历史 baseline)
//   新行号对应同样 4 处 piiSafeLog CJK 字面量 (developer log, 非用户 UI)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
