// 规则 3 标记: CJK 字面量 = developer 日志/内部 note (非用户可见 UI 文案), 豁免 i18n 扫描
// v0.24 round 45 (Sprint #5b) — AssessmentNotifier 抽类
//
// 心理评估周期提醒编排 (id=7000)。从 NotificationService 拆出, 单一职责:
//   - schedule: 单条推送, id 固定 7000, fireAt 一次性 (不重复)
//   - cancel: 取消同 id 的旧推送
// 委托 ReminderDispatcher.zonedAt, 保留 `DateTime.now()` 一次取防 midnight race
// (v0.16 round 19B fix) + fireAt 已过跳过调度。

import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/l10n/strings.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chroniccare/core/platform/notification/notification_payload.dart';
import 'package:chroniccare/core/platform/notification/reminder_dispatcher.dart';

/// 心理评估周期提醒编排 (id=7000, 单条推送)
///
/// 公开 2 个 method:
///   - [scheduleAssessmentReminder] 调度单条推送 (id 固定, 覆盖前一次)
///   - [cancelAssessmentReminder] 取消评估提醒
///
/// v0.24 round 45: 委托 ReminderDispatcher 处理 zonedAt。
class AssessmentNotifier {
  /// 心理评估周期提醒 id (单条推送, 稳定; 评估完成重排 = 覆盖)
  /// v0.32 R110 (B1-1): 原 7000 落入 medication/refill cancel 区间被误杀,
  /// 迁 5M+ 固定带
  static const int assessmentReminderId = 5000001;

  final FlutterLocalNotificationsPlugin _plugin;
  final ReminderDispatcher _dispatcher;

  /// facade 的 init() 包装, 保证 sub-service 调用时主 service 已 init
  final Future<void> Function() _ensureInitialized;

  AssessmentNotifier({
    required FlutterLocalNotificationsPlugin plugin,
    required ReminderDispatcher dispatcher,
    required Future<void> Function() ensureInitialized,
  })  : _plugin = plugin,
        _dispatcher = dispatcher,
        _ensureInitialized = ensureInitialized;

  /// 调度一条心理评估周期提醒
  ///
  /// - 单条推送, id 固定为 [assessmentReminderId]
  /// - payload 携带 scaleId, 点通知直达 PHQ-9
  /// - [fireAt] 已过 = 跳过 (但取消旧的)
  Future<void> scheduleAssessmentReminder({
    required DateTime fireAt,
    String scaleId = 'phq9',
    int days = 14,
  }) async {
    // v0.18 (P2-P0-4): 函数入口统一取 now, 避免多次 DateTime.now() 跨 midnight race
    final now = DateTime.now();
    await _ensureInitialized();
    await _plugin.cancel(assessmentReminderId);

    if (fireAt.isBefore(now)) {
      // v0.32 R110 round 6 (B1-7): 过去 fireAt **不再静默丢弃** — 改 catch-up
      // now+1h 重排 (跟 AssessmentReminderPolicy "计算结果 < 现在 → +1h"
      // 语义对齐)。修复前: 任何竞态/分歧 (policy now vs 调度 now, 或未来
      // caller 传错) → 评估提醒永不重发, 静默丢失。
      final catchUp = now.add(const Duration(hours: 1));
      piiSafeLog(
        'AssessmentNotifier',
        '⏭️ scheduleAssessmentReminder: fireAt=$fireAt 已过, catch-up '
            '重排到 $catchUp (不再静默丢弃, B1-7)',
      );
      try {
        await _dispatcher.zonedAt(
          id: assessmentReminderId,
          title: Strings.notifAssessmentTitle(),
          // R113 (BUG 8): 不含量表名 (锁屏 PII)
          body: Strings.notifAssessmentBody(days),
          fireAt: catchUp,
          details: _dispatcher.buildChannelDetails(),
          payload: NotificationDeepLink.assessment(scaleId).encode(),
        );
      } catch (e) {
        piiSafeLog(
          'AssessmentNotifier',
          '❌ 评估提醒 catch-up 调度失败: $e',
          error: e,
        );
      }
      return;
    }

    final details = _dispatcher.buildChannelDetails();
    final payload = NotificationDeepLink.assessment(scaleId).encode();
    try {
      await _dispatcher.zonedAt(
        id: assessmentReminderId,
        title: Strings.notifAssessmentTitle(),
        // R113 (BUG 8): 不含量表名 (锁屏 PII)
        body: Strings.notifAssessmentBody(days),
        fireAt: fireAt,
        details: details,
        payload: payload,
      );
      piiSafeLog(
        'AssessmentNotifier',
        '✅ 评估提醒: scale=$scaleId fireAt=$fireAt days=$days',
      );
    } catch (e) {
      piiSafeLog('AssessmentNotifier', '❌ 评估提醒调度失败: $e', error: e);
    }
  }

  /// 取消心理评估周期提醒
  Future<void> cancelAssessmentReminder() async {
    await _ensureInitialized();
    await _plugin.cancel(assessmentReminderId);
  }
}
// rule3-whitelist: 68-69, 84, 105, 108
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
