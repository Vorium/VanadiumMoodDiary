import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:chroniccare/domain/repositories/notification_sender.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/medication/medication_times.dart';
import 'package:chroniccare/core/data/services/notification_navigation.dart';
import 'package:chroniccare/core/data/services/notification_payload.dart';
import 'package:chroniccare/core/data/services/snooze_manager.dart';

/// 本地通知服务
///
/// v0.7 升级：
/// - 每天 20:00 通用打卡提醒（保留）
/// - **每个 medication 的每个 time 配 zonedSchedule 推送**
/// - "漏 1 天"主动 push 安慰
class NotificationService implements NotificationSender {
  static const _channelId = 'chroniccare.medication';
  static const _channelName = '吃药提醒';
  static const _channelDesc = '到点提醒你吃药打卡';
  static const _defaultReminderId = 1001;
  // medication.time 推送的 id 起始基数（避免冲突）
  static const _medicationReminderBaseId = 2000;
  // 漏 1 天安慰 push 的 id
  static const _softReminderId = 3000;
  // 安全警报推送（v0.10 / Round 4）
  static const _safetyAlertId = 5000;
  // 续方提醒推送（v0.12 / Round 6），id 起始基数（6000-6999）
  static const _refillBaseId = 6000;
  // 心理评估周期提醒（v0.13 / Round 7 — Apple Health 思路）
  static const _assessmentReminderId = 7000;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  /// v0.18 round 18 (P1-28): Snooze 逻辑拆出到 SnoozeManager,主 service 委托
  /// 公共 API 保持不变（snoozeOnce / cancelSnoozeForMedication / cancelAllSnoozes）,
  /// 但真实实现移到 SnoozeManager,主 service 减肥 90+ 行。
  late final SnoozeManager _snoozeManager =
      SnoozeManager(plugin: _plugin);

  /// v0.11 (Round 5): 用户点通知的回调
  /// 默认调 [NotificationNavigation.handleTap]
  final void Function(String? payload) onNotificationTap;

  NotificationService({this.onNotificationTap = _defaultOnTap})
      : _plugin = FlutterLocalNotificationsPlugin();

  static void _defaultOnTap(String? payload) {
    NotificationNavigation.handleTap(payload);
  }

  /// 初始化（app 启动时调用）
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
      developer.log(
        '🚀 App 由通知拉起, payload=$payload',
        name: 'NotificationService',
      );
      NotificationNavigation.setLaunchPayload(payload);
    }

    // 初始化时区数据库（zonedSchedule 需要）
    try {
      tz_data.initializeTimeZones();
      final localTzName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTzName));
    } catch (e) {
      developer.log(
        '⚠️ 时区初始化失败（web 端不支持）: $e',
        name: 'NotificationService',
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
    developer.log(
      '👆 通知被点击, payload=${response.payload}',
      name: 'NotificationService',
    );
    _defaultOnTap(response.payload);
  }

  /// 设置每天 20:00 通用打卡提醒（fallback，没设药时用）
  Future<void> scheduleDailyReminder({
    int hour = 20,
    int minute = 0,
  }) async {
    await init();
    await _plugin.cancel(_defaultReminderId);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    try {
      // v0.11: payload = "chroniccare://check-in/today"
      const payload = 'chroniccare://check-in/today';
      await _zonedDaily(
        id: _defaultReminderId,
        title: '🌱 今天吃了药吗？',
        body: '点一下 = 打卡，让家人放心',
        hour: hour,
        minute: minute,
        details: details,
        payload: payload,
      );
      developer.log('✅ 设置每日 $hour:$minute 提醒', name: 'NotificationService');
    } catch (e) {
      developer.log('❌ 设置提醒失败: $e', name: 'NotificationService');
    }
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  /// 待发通知数量（用于 UI 自检展示）
  ///
  /// v0.16 round 20（OEM 后台引导）：让用户能在设置页直观看到
  /// "我设的提醒都在排队",如果显示 0 条说明没设上或被 OEM 杀掉
  /// 返回 -1 表示平台不支持（web / desktop）
  Future<int> get pendingCount async {
    await init();
    try {
      final list = await _plugin.pendingNotificationRequests();
      return list.length;
    } catch (e) {
      // web 平台 / 未实现 plugin: pendingNotificationRequests 抛 PlatformException
      developer.log(
        '⚠️ pendingCount 读取失败（可能 web 端）: $e',
        name: 'NotificationService',
      );
      return -1;
    }
  }

  /// 重排所有 medication 的推送
  ///
  /// 每次 medications 表变化（增/删/改）时调用。
  /// 用稳定 hash 生成 notification id（避免冲突 + 同一药同一时间复用 id）。
  Future<void> rescheduleMedicationReminders(
    List<Medication> medications,
  ) async {
    await init();

    // 先取消所有 medication 推送（保留 default + soft）
    // medication reminder id 公式：base + medId * 10 + i
    //   v0.16 round 19 fix: 之前 1000 范围太窄，medId >= 100 时 id 超过 3000 漏 cancel
    //   改成 200000 覆盖 medId <= 19999（远超实际用户量，且 int32 安全）
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= _medicationReminderBaseId &&
          p.id < _medicationReminderBaseId + 200000) {
        await _plugin.cancel(p.id);
      }
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    int scheduled = 0;
    for (final med in medications) {
      if (!med.isActive) continue;
      for (int i = 0; i < med.times.length; i++) {
        final t = med.times[i];
        final id =
            _medicationReminderBaseId + (med.id * 10) + i; // 同一药的同一时间点 id 稳定
        try {
          // v0.11: payload 携带 medId,点通知直达该药打卡
          final payload =
              NotificationDeepLink.medicationCheckIn(med.id).encode();
          await _zonedDaily(
            id: id,
            title: '💊 该吃药了：${med.name}',
            body: '${med.dosage}${med.dosageUnit} · 点一下 = 打卡',
            hour: t.hour,
            minute: t.minute,
            details: details,
            payload: payload,
          );
          scheduled++;
        } catch (e) {
          developer.log(
            '❌ 推送调度失败 med=${med.name} t=$t: $e',
            name: 'NotificationService',
          );
        }
      }
    }
    developer.log(
      '✅ 重新调度 $scheduled 个 medication 推送',
      name: 'NotificationService',
    );
  }

  /// 漏 1 天主动 push 安慰（不是通知紧急联系人）
  ///
  /// [hour] 通常是上午 10 点
  ///
  /// v0.18 (P1-11) @Deprecated: CareEngine 接管 secondDayMissed 推送,
  /// setup_page 不再调此方法。保留 API 是因为有些旧测试 / 未来合并 soft reminder
  /// 跟 CareEngine 时可能还要用。新代码请用 `CareEngine.evaluate` + `showNow`。
  @Deprecated('v0.18 P1-11: CareEngine 接管，新代码请用 CareEngine.evaluate + showNow')
  Future<void> scheduleSoftReminder({int hour = 10, int minute = 0}) async {
    await init();
    await _plugin.cancel(_softReminderId);

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

    try {
      // v0.11: payload = today check-in
      const payload = 'chroniccare://check-in/today';
      await _zonedDaily(
        id: _softReminderId,
        title: '🌿 你还好吗？',
        body: '少 1 次没关系——但记得吃药哦',
        hour: hour,
        minute: minute,
        details: details,
        payload: payload,
      );
      developer.log(
        '✅ 设置漏 1 天主动安慰 push（每天 $hour:$minute）',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log('❌ 软提醒调度失败: $e', name: 'NotificationService');
    }
  }

  /// 取消软提醒（用户打卡后调用）
  Future<void> cancelSoftReminder() async {
    await init();
    await _plugin.cancel(_softReminderId);
  }

  /// 立即显示一条通知（不调度，立即推）
  ///
  /// 用于 CareEngine 触发的主动 push（不是定时任务）
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

  // ============== Round 4: Snooze + Badge ==============
  //
  // v0.18 round 18 (P1-28): Snooze 3 个 method 拆到 SnoozeManager
  // 主 service 公共 API 保留，内部委托 _snoozeManager。
  // 这样:
  // - notification_service.dart 788 → 700 行 (-90)
  // - snooze 逻辑独立测试 (mock SnoozeManager 不用 mock 整个 notification)
  // - id 公式 + cancel 范围集中在一处
  //
  // 参考 Pill Reminder (Drugs.com iOS)：
  // - 通知来了用户点"Snooze 5min" → 5min 后再响一次
  // - App 图标角标显示当天还差几次没打卡

  /// 调度一个**一次性**延迟通知（snooze 用）
  ///
  /// v0.18 (P1-28): 委托 SnoozeManager,公共签名不变。
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

  /// 取消某个药物的所有 snooze（用户真打卡后调）
  ///
  /// v0.18 (P1-28): 委托 SnoozeManager
  Future<void> cancelSnoozeForMedication(int medicationId) async {
    await init();
    await _snoozeManager.cancelSnoozeForMedication(medicationId);
  }

  /// 取消所有 snooze（重排 medication reminders 时调）
  ///
  /// v0.18 (P1-28): 委托 SnoozeManager
  Future<void> cancelAllSnoozes() async {
    await init();
    await _snoozeManager.cancelAllSnoozes();
  }

  // ============== Round 6: 续方提醒 ==============
  //
  // 参考 Pill Reminder (Drugs.com iOS)：
  // - "你的 XXX 还剩 N 天就要断药了，去医院开药"
  // - 触发时机：refillAt - reminderDays 当天上午 9 点
  // - 一个药一条推送，id 稳定

  /// 续方提醒通知 id 范围：[refillBase, refillBase + 200000)
  /// 一个 medication 一条预留 id 槽（id = refillBase + medId），
  /// 同一药多次重排 = 覆盖，不会叠加。
  ///
  /// v0.16 round 19B: range 改 200000，配套 rescheduleRefillReminders
  ///   的 cancel 范围。修前 1000 范围，medId >= 1000 漏 cancel。
  @visibleForTesting
  static int refillNotificationId(int medicationId) {
    return _refillBaseId + medicationId;
  }

  /// 按"天"计算 refill 距今多少天（不直接用 Duration.inDays）
  ///
  /// 不直接用 Duration.inDays，因为：
  /// - 23.98h 会被报成 0 天
  /// - refill day 整天应该算"今天还有 X 天"，不能因时分秒而错
  static int _daysUntilRefill(DateTime refillAt, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final refillDay = DateTime(refillAt.year, refillAt.month, refillAt.day);
    return refillDay.difference(today).inDays;
  }

  /// 计算续方提醒的触发时间（refillAt - reminderDays 当天 9 点本地时间）
  ///
  /// 纯函数，方便测试。
  /// 返回 null 当且仅当 [refillAt] 本身为 null。
  /// [reminderDays] < 1 时抛 ArgumentError。
  @visibleForTesting
  static DateTime? computeRefillFireTime({
    required DateTime? refillAt,
    required int reminderDays,
  }) {
    if (refillAt == null) return null;
    if (reminderDays < 1) {
      throw ArgumentError('reminderDays 必须 >= 1, 实际: $reminderDays');
    }
    // 续方日期当天的 0 点，再 - reminderDays 天，再 + 9 小时
    final day = DateTime(refillAt.year, refillAt.month, refillAt.day);
    final triggerDay = day.subtract(Duration(days: reminderDays));
    return DateTime(
      triggerDay.year,
      triggerDay.month,
      triggerDay.day,
      9, // 上午 9 点
    );
  }

  /// 调度一个 medication 的续方提醒
  ///
  /// - [medication] 必须有非空 [Medication.refillAt]，否则函数静默 no-op
  /// - 触发时间：`refillAt - reminderDays` 当天 9:00
  /// - 同一 med 多次调用 = 覆盖前一次（id 稳定）
  /// - payload = medicationCheckIn(medId) — 点通知直达打卡
  Future<void> scheduleRefillReminder(Medication medication) async {
    final fireAt = computeRefillFireTime(
      refillAt: medication.refillAt,
      reminderDays: medication.refillReminderDays,
    );
    if (fireAt == null) {
      developer.log(
        '⏭️ scheduleRefillReminder: med=${medication.name} 无 refillAt, 跳过',
        name: 'NotificationService',
      );
      return;
    }

    // v0.16 round 19 fix: 之前 2 次 DateTime.now() 跨 midnight 时可能不一致
    // （fireAt 检查用 yesterday 23:59，daysLeft 计算用 today 00:00）
    final now = DateTime.now();
    // 已经过期的提醒不再调度（避免给历史数据"补响"）
    if (fireAt.isBefore(now)) {
      developer.log(
        '⏭️ scheduleRefillReminder: med=${medication.name} '
        'fireAt=$fireAt 已过, 跳过',
        name: 'NotificationService',
      );
      // 但仍要取消旧的，避免过期通知还挂着
      await cancelRefillReminder(medication.id);
      return;
    }

    await init();
    final id = refillNotificationId(medication.id);
    await _plugin.cancel(id); // 覆盖前一次

    final daysLeft = _daysUntilRefill(medication.refillAt!, now);
    final details = const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    final payload =
        NotificationDeepLink.medicationCheckIn(medication.id).encode();
    final fireTz = tz.TZDateTime.from(fireAt, tz.local);
    try {
      await _plugin.zonedSchedule(
        id,
        '💊 该续方了：${medication.name}',
        '还剩约 $daysLeft 天断药，记得去医院或线上开药',
        fireTz,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // 只触发一次（不加 matchDateTimeComponents）
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      developer.log(
        '✅ 续方提醒: med=${medication.name} '
        'fireAt=$fireAt daysLeft=$daysLeft',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log('❌ 续方提醒调度失败: $e', name: 'NotificationService', error: e);
    }
  }

  /// 取消一个 medication 的续方提醒
  Future<void> cancelRefillReminder(int medicationId) async {
    await init();
    await _plugin.cancel(refillNotificationId(medicationId));
  }

  /// 重排所有 medication 的续方提醒
  ///
  /// 在 medication 表变化（增/删/停药）时统一调。
  /// 一次性清空所有 refill 槽再重排。
  ///
  /// v0.16 round 19 fix: 之前 `_refillBaseId + 1000` 范围太窄，medId >= 1000 时
  /// id 超过 7000 漏 cancel。重排会留下"幽灵通知"。
  /// 改成 200000 覆盖 medId <= 199999（远超实际用户量，且 int32 安全）。
  Future<void> rescheduleRefillReminders(List<Medication> medications) async {
    await init();
    // 先清掉所有 refill 通知
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= _refillBaseId && p.id < _refillBaseId + 200000) {
        await _plugin.cancel(p.id);
      }
    }
    int scheduled = 0;
    for (final med in medications) {
      if (!med.isActive) continue;
      if (med.refillAt == null) continue;
      await scheduleRefillReminder(med);
      scheduled++;
    }
    developer.log(
      '✅ 重排 $scheduled 个 medication 的续方提醒',
      name: 'NotificationService',
    );
  }

  // ============== Round 7: 心理评估周期提醒 ==============
  //
  // 参考 Apple Health "Mindful Minutes" / WWDC '23 Health Reminders：
  // - 用户开"每 14 天提醒做 PHQ-9"
  // - 完成后下次从完成时间算起
  // - 单条推送，id 稳定；重排 = 覆盖

  /// 调度一条心理评估周期提醒
  ///
  /// - 单条推送，id 固定为 [_assessmentReminderId]
  /// - payload 携带 scaleId，点通知直达 PHQ-9
  /// - [fireAt] 已过 = 跳过（但取消旧的）
  Future<void> scheduleAssessmentReminder({
    required DateTime fireAt,
    String scaleId = 'phq9',
    int days = 14,
  }) async {
    await init();
    await _plugin.cancel(_assessmentReminderId);

    if (fireAt.isBefore(DateTime.now())) {
      developer.log(
        '⏭️ scheduleAssessmentReminder: fireAt=$fireAt 已过, 跳过',
        name: 'NotificationService',
      );
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    final payload = NotificationDeepLink.assessment(scaleId).encode();
    final fireTz = tz.TZDateTime.from(fireAt, tz.local);
    try {
      await _plugin.zonedSchedule(
        _assessmentReminderId,
        '🌿 心理评估时间到',
        '已经 $days 天没做 ${scaleId.toUpperCase()} 了，'
            '抽 2 分钟看看最近状态',
        fireTz,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      developer.log(
        '✅ 评估提醒: scale=$scaleId fireAt=$fireAt days=$days',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log('❌ 评估提醒调度失败: $e', name: 'NotificationService', error: e);
    }
  }

  /// 取消心理评估周期提醒
  Future<void> cancelAssessmentReminder() async {
    await init();
    await _plugin.cancel(_assessmentReminderId);
  }

  /// 推送"安全警报"通知（v0.10 / Round 4 — 死了么思路）
  ///
  /// 和普通 reminder 不同的 channel：高 importance + 震动 + 锁屏可见
  /// v0.11 (Round 5): payload 携带天数，点通知直达 home + 显示告警
  Future<void> showSafetyAlert({
    required String userName,
    required int daysWithoutCheckIn,
    required DateTime? lastCheckIn,
  }) async {
    await init();

    // 用单独的 channel id，让系统/用户能区分"安全警报"和"普通提醒"
    const safetyChannelId = 'chroniccare.safety';
    const safetyChannelName = '安全警报';
    const safetyChannelDesc = '长时间未打卡时提醒';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        safetyChannelId,
        safetyChannelName,
        channelDescription: safetyChannelDesc,
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
      _safetyAlertId,
      '⚠️ $userName 已 $daysWithoutCheckIn 天未打卡',
      '上次打卡：$lastStr。已自动通知紧急联系人，请确认安全。',
      details,
      payload: payload,
    );
  }

  /// 更新角标数字（iOS only — Android 留 TODO）
  ///
  /// v0.10 (Round 4) 参考 Pill Reminder (Drugs.com iOS)：
  /// "App 图标右上角小红点显示今天还差几次没打卡"
  ///
  /// 限制：flutter_local_notifications 17.x **没有** setBadgeCount 原生 API。
  /// 退而求其次：发一条**带 badgeNumber** 的"空"通知（iOS 自动更新角标）。
  /// - iOS：[DarwinNotificationDetails] 的 badgeNumber 字段是公开 API
  /// - Android：暂无稳定方案。v0.10+ TODO: 集成 flutter_app_badge_control 插件
  ///
  /// [count] 传 0 即清零
  Future<void> updateBadgeCount(int count) async {
    if (count < 0) count = 0;
    await init();
    try {
      // iOS 路径：发一条"空"通知带 badgeNumber
      // 用一个稳定的"虚拟"id 覆盖之前那条
      const virtualId = 9999;
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
          badgeNumber: count,
        ),
      );
      // 先取消旧的虚拟通知
      await _plugin.cancel(virtualId);
      await _plugin.show(
        virtualId,
        '',
        '',
        details,
      );
      developer.log('✅ 角标已更新 = $count', name: 'NotificationService');
    } catch (e) {
      developer.log(
        '⚠️ updateBadgeCount 失败（不影响功能）: $e',
        name: 'NotificationService',
      );
    }
  }

  /// 用 tz 包一层 zonedSchedule，web 上 catch 异常
  Future<void> _zonedDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required NotificationDetails details,
    String? payload,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // 每天重复
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }
}
