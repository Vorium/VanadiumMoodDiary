// v0.13 (Round 7) 心理评估周期提醒服务
//
// 思路（参考 Apple Health / WWDC '23 Health Reminders）：
// - 用户在 settings 开启 "每 N 天提醒做心理评估"
// - 调度时间 = 上次评估时间 + N 天
// - 评估完成后，自动从"今天"重算下次
// - 一次只调度一条推送，id 稳定
//
// 设计取舍：
// - **默认关闭**（侵入性功能）
// - 配置存 SharedPreferences（不动 schema）
// - 评估 type='phq9' / 'gad7'（沿用 v0.8 设计）
// - 跨时区：fireAt 用本地时间（与 medication reminders 一致）
import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/domain/repositories/check_in_repository.dart';
import 'package:chroniccare/core/data/services/notification_service.dart';

/// 心理评估周期提醒服务
class AssessmentReminderService {
  static const _kEnabled = 'assessment_reminder_enabled';
  static const _kDays = 'assessment_reminder_days';
  static const _kLastAssessmentAt = 'assessment_reminder_last_at';

  /// 默认提醒间隔：14 天
  static const int defaultDays = 14;

  /// 允许的间隔选项（settings UI 用的也是这几个）
  static const List<int> allowedDays = [7, 14, 30, 60, 90];

  final CheckInRepository _checkInRepo;
  final NotificationService _notificationService;

  AssessmentReminderService({
    required CheckInRepository checkInRepo,
    required NotificationService notificationService,
  })  : _checkInRepo = checkInRepo,
        _notificationService = notificationService;

  // ============== 配置 API ==============

  /// 是否启用
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kEnabled) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, value);
  }

  /// 提醒间隔（天）
  Future<int> getDays() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getInt(_kDays) ?? defaultDays;
    if (!allowedDays.contains(v)) return defaultDays;
    return v;
  }

  Future<void> setDays(int days) async {
    if (!allowedDays.contains(days)) {
      throw ArgumentError(
        'assessment reminder interval must be one of $allowedDays; got: $days',
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDays, days);
  }

  /// 上次评估时间（用户设置后的"基准时间"）
  ///
  /// 注意：这里**只读** SharedPreferences。
  /// 真实评估时间应从 [CheckInRepository.watchAssessments] 拉，但那样
  /// 需要把 [CheckInRepository] 注入到纯函数。简化版：让 UI 在评估完成后
  /// 调 [onAssessmentCompleted] 显式写入。
  Future<DateTime?> getLastAssessmentAt() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_kLastAssessmentAt);
    if (s == null) return null;
    // v0.22 round 30 (sp-zh P1-1): setLastAssessmentAt 改用 toUtc 存
    // (避免 local 字符串跨时区漂移),get 时 tryParse 返回 UTC DateTime
    // → 转 local 让 service 内部 fireAt 计算 (DateTime(fire.year, ...))
    // 跟原 local-time 行为一致。
    return DateTime.tryParse(s)?.toLocal();
  }

  Future<void> setLastAssessmentAt(DateTime when) async {
    final prefs = await SharedPreferences.getInstance();
    // v0.22 round 30 (sp-zh P1-1): 显式 toUtc,跟 data_export_service 同款修复
    // 详见 safety_watch_service._setLastAlertAt 注释
    await prefs.setString(_kLastAssessmentAt, when.toUtc().toIso8601String());
  }

  // ============== 纯函数：下次触发时间 ==============

  /// 计算下次提醒的触发时间
  ///
  /// 规则：
  /// - [enabled] = false → null（不调度）
  /// - 没历史评估 → 现在 + days 天（首次装 app 后 +N 天提醒）
  /// - 有历史评估 → 上次评估 + days 天
  /// - 计算结果 < 现在 → 现在 + 1 小时（catch-up，避免一开机就立即响）
  ///
  /// [now] 默认 DateTime.now()，可注入方便测试。
  @visibleForTesting
  static DateTime? computeNextFireTime({
    required bool enabled,
    required int days,
    required DateTime? lastAssessmentAt,
    DateTime? now,
  }) {
    if (!enabled) return null;
    if (!allowedDays.contains(days)) {
      throw ArgumentError('days must be in $allowedDays; got: $days');
    }
    final n = now ?? DateTime.now();
    final base = lastAssessmentAt ?? n;
    var fire = base.add(Duration(days: days));
    // 把时分秒截到 10:00（用户普遍起床活跃时段）
    fire = DateTime(fire.year, fire.month, fire.day, 10, 0);
    if (fire.isBefore(n)) {
      // 已经过 → 推迟 1 小时（避免开机立即响）
      fire = n.add(const Duration(hours: 1));
    }
    return fire;
  }

  // ============== 触发入口 ==============

  /// App 启动时调用（main.dart 调）
  ///
  /// - enabled=false → 取消任何待响推送
  /// - enabled=true → 根据 lastAssessment 重排
  Future<void> onAppStart() async {
    final enabled = await isEnabled();
    if (!enabled) {
      await _notificationService.cancelAssessmentReminder();
      return;
    }
    final days = await getDays();
    final last = await getLastAssessmentAt();
    // P0 fix: DB 级查询最近评估时间戳，不再全表 reduce
    final realLast = await _checkInRepo.getLatestAssessmentTimestamp();
    if (realLast != null) {
      if (last == null || realLast.isAfter(last)) {
        await setLastAssessmentAt(realLast);
      }
    }
    final fireAt = computeNextFireTime(
      enabled: true,
      days: days,
      lastAssessmentAt: await getLastAssessmentAt(),
    );
    if (fireAt == null) return;
    await _notificationService.scheduleAssessmentReminder(
      fireAt: fireAt,
      scaleId: 'phq9',
      days: days,
    );
  }

  /// 评估完成后调用（assessment_page._submit 调）
  ///
  /// - 写 lastAssessmentAt = now
  /// - 重排下次提醒 = now + days 天
  Future<void> onAssessmentCompleted() async {
    final enabled = await isEnabled();
    if (!enabled) return;
    final now = DateTime.now();
    await setLastAssessmentAt(now);
    final days = await getDays();
    final fireAt = computeNextFireTime(
      enabled: true,
      days: days,
      lastAssessmentAt: now,
      now: now,
    );
    if (fireAt == null) return;
    await _notificationService.scheduleAssessmentReminder(
      fireAt: fireAt,
      scaleId: 'phq9',
      days: days,
    );
    piiSafeLog(
      'AssessmentReminderService',
      '✅ 评估完成, 下次提醒: $fireAt ($days天后)',
    );
  }

  /// 用户改设置后调用（settings 切换 enabled / days）
  ///
  /// 重新跑一次 onAppStart 逻辑（开关/天数变 → 立即生效）
  Future<void> onSettingsChanged() => onAppStart();
}
