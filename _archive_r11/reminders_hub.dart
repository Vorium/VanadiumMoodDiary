// v0.13 (Round 11) Health Reminders Hub — 集中展示所有推送
//
// 设计：纯函数从 DB + settings state 算出"应该被调度的所有 reminder 列表"，
// 给 UI 一个统一的渲染入口。
//
// 涵盖 5 类 reminder：
// 1. daily       - 每日 20:00 通用打卡（兜底）
// 2. medication  - 每个 active med × 每个 time（服药提醒）
// 3. soft        - 漏 1 天 push（上午 10:00 安慰）
// 4. refill      - 续方提醒（refillAt - days 当天 9:00）
// 5. assessment  - 周期评估提醒（每 N 天 10:00）
//
// 不依赖 Flutter / Drift，纯函数。
library;

import '../../data/database/app_database.dart';
import '../../data/services/assessment_reminder_service.dart';
import '../../data/services/notification_service.dart' show NotificationService;
import 'assessment_comparison.dart';

/// Reminder 类型
enum ReminderKind {
  /// 每日通用打卡兜底（id 1001，固定 20:00）
  daily,

  /// 服药提醒（每个 active med × 每个 time）
  medication,

  /// 漏 1 天 push（id 3000，上午 10:00 安慰）
  soft,

  /// 续方提醒（每个 active med with refillAt）
  refill,

  /// 周期评估提醒（id 7000，每 N 天）
  assessment,
}

/// 一条 reminder 的展示信息
class ScheduledReminder {
  /// 类型
  final ReminderKind kind;

  /// 稳定 id（用作 list key / deep link / 单条操作）
  final String id;

  /// 主标题
  final String title;

  /// 副标题（详情）
  final String? description;

  /// 下次触发时间（null = 关闭 / 已过期 / 不该调度）
  final DateTime? nextFireAt;

  /// 是否启用
  final bool isEnabled;

  /// 关联 medication（仅 medication / refill）
  final int? medicationId;

  /// 关联 medication 名（仅 medication / refill）
  final String? medicationName;

  /// 跳转按钮文案（"去设置"/"去评估"/"查看"）
  final String? actionLabel;

  /// 跳转路径（settings 子页 / 评估页 / etc.）
  final String? actionRoute;

  const ScheduledReminder({
    required this.kind,
    required this.id,
    required this.title,
    this.description,
    this.nextFireAt,
    required this.isEnabled,
    this.medicationId,
    this.medicationName,
    this.actionLabel,
    this.actionRoute,
  });
}

/// Reminders Hub 纯计算
class RemindersHubCalculator {
  RemindersHubCalculator._();

  /// 计算所有 reminder（按 type 分组排序：daily → medication → soft → refill → assessment）
  static List<ScheduledReminder> compute({
    required List<Medication> medications,
    required List<CheckIn> checkIns,
    required int dailyReminderHour,
    required int dailyReminderMinute,
    required bool softEnabled,
    required bool assessmentEnabled,
    required int assessmentDays,
    required DateTime? lastAssessmentAt,
    required DateTime now,
  }) {
    final out = <ScheduledReminder>[];

    // 1. Daily fallback
    out.add(_buildDaily(now, dailyReminderHour, dailyReminderMinute));

    // 2. Medication time reminders（每个 active med × 每个 time）
    for (final med in medications) {
      if (!med.isActive) continue;
      for (final t in med.times) {
        out.add(_buildMedication(med, t, now));
      }
    }

    // 3. Soft reminder（漏 1 天）
    if (softEnabled) {
      out.add(_buildSoft(checkIns, now));
    }

    // 4. Refill reminders
    for (final med in medications) {
      if (!med.isActive) continue;
      if (med.refillAt == null) continue;
      out.add(_buildRefill(med, now));
    }

    // 5. Assessment reminder
    if (assessmentEnabled) {
      out.add(_buildAssessment(
        lastAssessmentAt: lastAssessmentAt,
        days: assessmentDays,
        now: now,
      ));
    }

    return out;
  }

  // ============== 各类 reminder 的构造 ==============

  static ScheduledReminder _buildDaily(
    DateTime now,
    int hour,
    int minute,
  ) {
    final next = _nextDailyTime(now, hour, minute);
    return ScheduledReminder(
      kind: ReminderKind.daily,
      id: 'daily',
      title: '每日打卡提醒',
      description: '每天 $hour:${minute.toString().padLeft(2, '0')} 提醒打卡',
      nextFireAt: next,
      isEnabled: true,
      actionLabel: '设置时间',
      actionRoute: '/settings',
    );
  }

  static ScheduledReminder _buildMedication(
    Medication med,
    TimeOfDay t,
    DateTime now,
  ) {
    final next = _nextDailyTime(now, t.hour, t.minute);
    final timeStr = '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
    return ScheduledReminder(
      kind: ReminderKind.medication,
      id: 'med-${med.id}-${t.hour}-${t.minute}',
      title: '${med.name} · ${med.dosage}${med.dosageUnit}',
      description: '每天 $timeStr 提醒服药',
      nextFireAt: next,
      isEnabled: true,
      medicationId: med.id,
      medicationName: med.name,
      actionLabel: '管理',
      actionRoute: '/settings',
    );
  }

  static ScheduledReminder _buildSoft(List<CheckIn> checkIns, DateTime now) {
    // 漏 1 天：今天/昨天都没打卡 → 触发
    final hasToday = checkIns.any((c) =>
        c.type == 'normal' && _isSameDay(c.timestamp, now));
    final yesterday = now.subtract(const Duration(days: 1));
    final hasYesterday = checkIns.any((c) =>
        c.type == 'normal' && _isSameDay(c.timestamp, yesterday));
    final shouldFire = !hasToday && !hasYesterday;

    // 触发时间：今天 10:00（已过则明天 10:00）
    final next = _nextDailyTime(now, 10, 0);

    return ScheduledReminder(
      kind: ReminderKind.soft,
      id: 'soft',
      title: '漏 1 天安慰',
      description: shouldFire
          ? '今天/昨天未打卡 → 10:00 推送安慰'
          : '今天/昨天已打卡 → 不触发',
      nextFireAt: shouldFire ? next : null,
      isEnabled: shouldFire,
    );
  }

  static ScheduledReminder _buildRefill(Medication med, DateTime now) {
    final fireAt = NotificationService.computeRefillFireTime(
      refillAt: med.refillAt,
      reminderDays: med.refillReminderDays,
    );
    // 已过 = 标 disabled
    final enabled = fireAt != null && !fireAt.isBefore(now);
    return ScheduledReminder(
      kind: ReminderKind.refill,
      id: 'refill-${med.id}',
      title: '${med.name} 续方提醒',
      description: med.refillAt == null
          ? '未设续方日期'
          : '续方 ${med.refillAt!.year}-${med.refillAt!.month.toString().padLeft(2, '0')}'
              '-${med.refillAt!.day.toString().padLeft(2, '0')} · 提前 ${med.refillReminderDays} 天',
      nextFireAt: fireAt,
      isEnabled: enabled,
      medicationId: med.id,
      medicationName: med.name,
      actionLabel: '编辑',
      actionRoute: '/settings',
    );
  }

  static ScheduledReminder _buildAssessment({
    required DateTime? lastAssessmentAt,
    required int days,
    required DateTime now,
  }) {
    final fireAt = AssessmentComparisonCalculator.computeNextFireTime(
      enabled: true,
      days: days,
      lastAssessmentAt: lastAssessmentAt,
      now: now,
    );
    return ScheduledReminder(
      kind: ReminderKind.assessment,
      id: 'assessment',
      title: '心理评估周期提醒',
      description: '每 $days 天提醒做一次心理评估（PHQ-9）',
      nextFireAt: fireAt,
      isEnabled: fireAt != null,
      actionLabel: '设置',
      actionRoute: '/settings',
    );
  }

  // ============== 工具方法 ==============

  /// 计算下次 "每天 hour:minute" 触发时间
  /// - 今天的 hour:minute 还没到 → 今天
  /// - 已过 → 明天
  static DateTime _nextDailyTime(DateTime now, int hour, int minute) {
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    if (today.isAfter(now)) return today;
    return today.add(const Duration(days: 1));
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 把 ScheduledReminder 按 ReminderKind 排序（稳定顺序）
  static List<ScheduledReminder> sortedByKind(
    List<ScheduledReminder> reminders,
  ) {
    const order = {
      ReminderKind.daily: 0,
      ReminderKind.medication: 1,
      ReminderKind.soft: 2,
      ReminderKind.refill: 3,
      ReminderKind.assessment: 4,
    };
    final copy = [...reminders];
    copy.sort((a, b) {
      final oa = order[a.kind] ?? 99;
      final ob = order[b.kind] ?? 99;
      if (oa != ob) return oa.compareTo(ob);
      // 同 kind 按 nextFireAt 升序
      final aNext = a.nextFireAt;
      final bNext = b.nextFireAt;
      if (aNext == null && bNext == null) return 0;
      if (aNext == null) return 1;
      if (bNext == null) return -1;
      return aNext.compareTo(bNext);
    });
    return copy;
  }
}
