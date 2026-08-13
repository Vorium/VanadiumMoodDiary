// v0.27 round 65 (spen P1-12 god class 拆分收尾): SafetyAlertBuilder 抽离
//
// 之前 notification_service.showSafetyAlert 50 行 (line 360-417) 混合:
//   1. 构造 safety channel 的 NotificationDetails (iOS+Android 13 行)
//   2. 格式化 lastCheckIn 日期字符串 (3 行)
//   3. 3 态 l10n 文案分流 (_resolveSafetyAlertBody 14 行)
//   4. 调 _plugin.show 推本地通知 (6 行)
//
// 修法: 抽本文件 — 纯函数 SafetyAlertBuilder.buildFor, 接受所有 inputs
// (daysWithoutCheckIn + lastCheckIn + outcome + l10n + 3 channel const),
// 返 ({String title, String body, NotificationDetails details}) record。
// notification_service.showSafetyAlert 退化为 5 行委派。
//
// 设计原则:
// - **0 副作用, 纯函数**: 不调 _plugin, 不写 DB, 不读 plugin 状态。所有
//   inputs 由 caller 注入, 返值是纯数据结构。
// - **l10n 走 caller 注入**: 不 import 任何 l10n 静态 / 动态, 完全由 caller
//   传 AppLocalizations 实例, 让 builder 跟 locale 无关 / 易单测。
// - **channel 走参数注入**: 不直接 import Strings.notifChannelSafety*, 走
//   caller 传 channelId/Name/Description 3 string, 跟 ReminderDispatcher
//   风格一致 (DI 模式, testability)。
// - **不依赖 Flutter widget**: 只 import flutter_local_notifications
//   (用于 NotificationDetails 类型) + 0 flutter/material。
//
// 跟 SafetyAlertDispatcher 区别:
//   - SafetyAlertDispatcher 负责 **真发 SMS + 调 showSafetyAlert + 写 audit log**
//   - SafetyAlertBuilder 负责 **构造** showSafetyAlert 要用的 title/body/details
//   - 两个职责正交, builder 不发任何东西, dispatcher 也不构造文案
import 'package:chroniccare/core/data/services/sms_service.dart'
    show SmsDispatchOutcome;
import 'package:chroniccare/domain/repositories/safety_alert_sender.dart'
    show SafetyAlertL10nResolver;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// v0.27 round 65 (spen P1-12 god class 拆分收尾): SafetyAlert 通知内容构造器
///
/// 纯函数: 给定 inputs (daysWithoutCheckIn + lastCheckIn + outcome +
/// l10n + channel 三元) → 返完整可推的 [NotificationDetails] + title + body。
///
/// caller 模式:
/// ```dart
/// final build = SafetyAlertBuilder.buildFor(
///   daysWithoutCheckIn: daysSinceLast,
///   lastCheckIn: lastCheckIn,
///   outcome: outcome,
///   l10n: l10n,
///   channelId: 'chroniccare.safety',
///   channelName: Strings.notifChannelSafetyName,
///   channelDescription: Strings.notifChannelSafetyDesc,
/// );
/// await _plugin.show(safetyAlertId, build.title, build.body, build.details);
/// ```
class SafetyAlertBuilder {
  // v0.32 R109 (god class 拆 round 2): 暴露 public const constructor,
  // 让 service_providers.dart `Provider<SafetyAlertSender>` 工厂可
  // `SafetyAlertBuilder()` 实例化 (sender impl 接收 builder 注入).
  // 旧 `_()` private 已删, 改 public const, 仍 0 副作用 (只暴露
  // static buildFor 入口, 实例本身 0 状态).
  const SafetyAlertBuilder();

  /// 构造 SafetyAlert 通知的 (title, body, details) — 0 副作用
  ///
  /// v0.32 round 8 (R111 B1-5 fix): 删死 userName 参数 (R32 锁屏 PII 决策后
  /// title 有意不含名字, 参数只算完就丢 = 死代码)
  /// [daysWithoutCheckIn] 必填, 进 title 跟 body
  /// [lastCheckIn] nullable, null 时 body 走 "从未打卡", 否则走
  ///   "上次打卡: YYYY-MM-DD" (本地格式化, 不走 l10n 避免时区漂移)
  /// [outcome] 必填, 决定 body 走 3 态 sent / mocked / failed (P0-3 修正)
  /// [l10n] 必填, 3 态文案来源 (zh / en / zh_Hant)
  /// [channelId] [channelName] [channelDescription] 必填, Android channel 三元
  static ({String title, String body, NotificationDetails details}) buildFor({
    required int daysWithoutCheckIn,
    required DateTime? lastCheckIn,
    required SmsDispatchOutcome outcome,
    required SafetyAlertL10nResolver l10n,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        // v0.31.1 round 7 (P0-06 修 GooglePlay P0-006): Android 锁屏 PII 防护
        // - visibility: NotificationVisibility.public → safety alert 是紧急通知,
        //   失联 N 天需要用户/旁观者立即看到 (锁屏不解锁也能看到 "已 X 天未打卡"
        //   完整信息, 包括 userName 让旁观者协助判断)。
        //   注: 审计 P0-006 建议 `private` (redact userName), 但本 round 决策走
        //   `public` (紧急 UX 优先, userName 在 lock screen 直接显示 = 旁观者
        //   协助价值 > PII 泄露风险)。后续若法务 / 临床反馈要求 redact, 改
        //   NotificationVisibility.private 即可, 1 行改动。
        visibility: NotificationVisibility.public,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    final lastStr = _formatLastCheckIn(lastCheckIn, l10n: l10n);
    final body = _resolveBody(outcome: outcome, lastStr: lastStr, l10n: l10n);
    // v0.27 round 75 (R74-N7 修): title 改 l10n, 之前硬编码中文。
    // 紧急通知走 3 语言 zh / en / zh_Hant, 跟 body 一致。
    // R32 (P0-04 锁屏 PII 跨 3 视角共识): title 静态不含 name (锁屏可见, PII 风险)
    final title = l10n.titleFor(daysWithoutCheckIn);

    return (title: title, body: body, details: details);
  }

  /// 格式化 lastCheckIn → "YYYY-MM-DD" 或 l10n "从未打卡" / "No check-ins yet" / "從未打卡"
  ///
  /// v0.27 round 65: 抽 top-level 纯函数 + 集中 DateTime 三元组 (避免
  /// `DateTime.now().year` 等多次调用 race, spen 规约)
  /// v0.27 round 75 (R74-N8 修): "从未打卡" 走 l10n, 之前硬编码。
  static String _formatLastCheckIn(
    DateTime? lastCheckIn, {
    required SafetyAlertL10nResolver l10n,
  }) {
    if (lastCheckIn == null) return l10n.neverCheckIn();
    final y = lastCheckIn.year.toString();
    final m = lastCheckIn.month.toString().padLeft(2, '0');
    final d = lastCheckIn.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// v0.27 round 60 (P0-3 修正) 后续: 3 态文案分流
  ///
  /// 优先级 (R60 设计): ok > mock > fail
  /// - smsOk > 0     → sent (主通知已发出, 即便部分 fail 也以 sent 为主旨)
  /// - smsMock > 0   → mocked (dev 模式常态, "未实际通知" 警示最紧迫)
  /// - 其余 (全 0 / 全 fail / 部分 fail) → failed (兜底)
  static String _resolveBody({
    required SmsDispatchOutcome outcome,
    required String lastStr,
    required SafetyAlertL10nResolver l10n,
  }) {
    if (outcome.smsOk > 0) {
      return l10n.bodySent(lastStr);
    }
    if (outcome.smsMock > 0) {
      return l10n.bodyMocked(lastStr);
    }
    return l10n.bodyFailed(lastStr);
  }
}
