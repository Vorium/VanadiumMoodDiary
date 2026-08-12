// v0.31.1 round 7 (P0-06 修 GooglePlay P0-006) — Android 锁屏通知 PII 防护守门员
//
// 背景: 精神心理 / 慢性病患者用 App, 通知在 Android 7+ (API 24+) 锁屏可见。
// 之前 4 个 AndroidNotificationDetails() 构造没设 `visibility`:
//   - Android 7+ 默认 VISIBILITY_PRIVATE (系统自动 redact 部分 PII), 但当
//     channel name 含 "ChronicCare · 服药提醒" 等 app 标识时, 仍会在锁屏显示
//     完整 title → "该吃药了 · 点一下 = 打卡" → 旁观者一眼看出是慢病/精神类 App。
//   - 1) 慢性病 + 精神心理 App 用户希望"完全不在锁屏显示" (有人偷看手机),
//     2) safety alert (失联通知) 紧急情况需要锁屏可见 + 旁观者协助判断。
//
// 本守门员防止以后有人改回无 visibility:
//
//   [1/2] Source-level 静态扫: 4 个文件里 AndroidNotificationDetails(...) 调用
//         必须含 `visibility: NotificationVisibility.<value>` 字段。
//         reminder / medication / snooze 期望 `secret`, safety alert 期望 `public`。
//   [2/2] Runtime 实测: ReminderDispatcher.buildChannelDetails() 构造的
//         AndroidNotificationDetails 实际 visibility 字段值匹配 secret,
//         SafetyAlertBuilder.buildFor() 构造的 visibility 匹配 public。
//
// 注: visibility 是 Android 平台特有 (iOS 锁屏 "Show Previews" 是系统设置, app 端
// 无法绕过)。所以本守门员只针对 AndroidNotificationDetails, 不动 DarwinNotificationDetails。
// title/body 去 PII 已在 R108 P0-3 / P0-012 修过, 守门员脚本:
//   scripts/check_pii_in_title.py
library;

import 'dart:io';

import 'package:chroniccare/core/data/services/reminder_dispatcher.dart';
import 'package:chroniccare/core/data/services/safety_alert_builder.dart';
import 'package:chroniccare/domain/repositories/safety_alert_sender.dart';
import 'package:chroniccare/l10n/app_localizations_en.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// R109 round 6 part 2: R109 round 2 改 SafetyAlertBuilder.buildFor
/// 接受 `SafetyAlertL10nResolver` (tear-off 闭包). test 跨期 R108 漏改
/// 还在传 `AppLocalizations` 实例 — 包成 resolver 即可 (闭包自然 capture).
SafetyAlertL10nResolver _wrapEnL10n(AppLocalizationsEn l) =>
    SafetyAlertL10nResolver(
      titleFor: l.safetyAlertTitle,
      bodySent: (Object date) => l.safetyAlertBodySent(date.toString()),
      bodyMocked: (Object date) => l.safetyAlertBodyMocked(date.toString()),
      bodyFailed: (Object date) => l.safetyAlertBodyFailed(date.toString()),
      neverCheckIn: () => l.safetyAlertNeverCheckIn,
    );

/// 4 个待检查文件 (相对 worktree 根)
const _kTargetFiles = <String>[
  'lib/core/data/services/notification_service.dart',
  'lib/core/data/services/reminder_dispatcher.dart',
  'lib/core/data/services/snooze_manager.dart',
  'lib/core/data/services/safety_alert_builder.dart',
];

/// 4 个文件期望的 visibility 值
const _kExpectedVisibility = <String, String>{
  'lib/core/data/services/notification_service.dart': 'secret',
  'lib/core/data/services/reminder_dispatcher.dart': 'secret',
  'lib/core/data/services/snooze_manager.dart': 'secret',
  // safety_alert 用 public (紧急 UX 优先, userName 在锁屏直接显示 = 旁观者协助
  // 价值 > PII 泄露风险)。审计 P0-006 建议 private (redact userName), 但本 round
  // 决策走 public, 后续法务/临床反馈要求 redact 时改 private 即可。
  'lib/core/data/services/safety_alert_builder.dart': 'public',
};

void main() {
  group('[1/2] Source-level 静态扫 (防以后退回无 visibility)', () {
    for (final relPath in _kTargetFiles) {
      test('$relPath 包含 AndroidNotificationDetails(... visibility: ...)', () {
        final file = File(relPath);
        expect(
          file.existsSync(),
          isTrue,
          reason: '文件不存在: $relPath (工作目录应在 worktree 根)',
        );
        final content = file.readAsStringSync();

        // 必须有 AndroidNotificationDetails(...) 构造 (至少 1 个)
        final androidMatches = RegExp(r'AndroidNotificationDetails\s*\(')
            .allMatches(content)
            .toList();
        expect(
          androidMatches,
          isNotEmpty,
          reason: '$relPath: 找不到任何 AndroidNotificationDetails('
              ') 构造调用, 可能已重构或文件改错',
        );

        // 必须有 visibility: NotificationVisibility.<value>
        expect(
          content,
          contains('visibility: NotificationVisibility.'),
          reason: '$relPath: 缺 visibility 字段 (Android 7+ 锁屏 PII 防护)',
        );

        // 期望的 visibility 值必须存在
        final expected = _kExpectedVisibility[relPath]!;
        expect(
          content,
          contains('visibility: NotificationVisibility.$expected,'),
          reason: '$relPath: visibility 值不是期望的 '
              'NotificationVisibility.$expected '
              '(reminder/snooze 应 secret, safety alert 应 public)',
        );
      });
    }

    test('3 个 reminder 类 visibility 全部 = secret (锁屏完全隐藏)', () {
      // 防止有人把 reminder 改成 public (锁屏泄露 PII) 或 private (锁屏部分
      // 仍显示, 不够安全)
      const reminderFiles = [
        'lib/core/data/services/notification_service.dart',
        'lib/core/data/services/reminder_dispatcher.dart',
        'lib/core/data/services/snooze_manager.dart',
      ];
      for (final relPath in reminderFiles) {
        final content = File(relPath).readAsStringSync();
        expect(
          content,
          contains('visibility: NotificationVisibility.secret,'),
          reason: '$relPath: reminder 类通知必须用 secret (锁屏完全不显示)',
        );
        // 必须不含 public (除注释外的实际代码行)
        expect(
          RegExp(r'visibility:\s*NotificationVisibility\.public[,)\s]')
              .hasMatch(content),
          isFalse,
          reason: '$relPath: reminder 类通知不能用 public (锁屏泄露 PII)',
        );
      }
    });

    test('safety_alert 单独走 public (紧急 UX 决策)', () {
      const relPath = 'lib/core/data/services/safety_alert_builder.dart';
      final content = File(relPath).readAsStringSync();
      expect(
        content,
        contains('visibility: NotificationVisibility.public,'),
        reason: 'safety_alert 必须用 public (紧急失联通知锁屏可见)',
      );
    });

    test('visibility 决策表自洽: 3 secret + 1 public = 4 文件', () {
      final secretCount = _kExpectedVisibility.values
          .where((v) => v == 'secret')
          .length;
      final publicCount = _kExpectedVisibility.values
          .where((v) => v == 'public')
          .length;
      expect(secretCount, 3, reason: 'reminder 类 3 个文件应都是 secret');
      expect(publicCount, 1, reason: 'safety_alert 1 个文件应 public');
    });
  });

  group('[2/2] Runtime 实测 ReminderDispatcher.buildChannelDetails()', () {
    late ReminderDispatcher dispatcher;

    setUp(() {
      dispatcher = ReminderDispatcher(
        plugin: FlutterLocalNotificationsPlugin(),
        channelId: 'test.channel',
        channelName: 'Test Channel',
        channelDescription: 'Test desc',
      );
    });

    test('Android: visibility = NotificationVisibility.secret', () {
      final details = dispatcher.buildChannelDetails();
      expect(details.android, isA<AndroidNotificationDetails>());
      expect(
        details.android!.visibility,
        NotificationVisibility.secret,
        reason: 'buildChannelDetails() 返回的 Android visibility '
            '必须 secret (锁屏完全隐藏 reminder 内容)',
      );
    });

    test('high=false (被动 push) 同样 visibility = secret (跟 high=true 一致)',
        () {
      final details = dispatcher.buildChannelDetails(high: false);
      expect(
        details.android!.visibility,
        NotificationVisibility.secret,
        reason: '被动 push 也要 secret, 不能因为 priority 低就泄露 PII',
      );
    });
  });

  group('[2/2] Runtime 实测 SafetyAlertBuilder.buildFor()', () {
    test('Android: visibility = NotificationVisibility.public (紧急通知)', () {
      // SafetyAlertBuilder 是纯函数类 (不可实例化), 走静态 buildFor()。
      // 用 en_US l10n 跑真实构造路径, 验证 visibility 字段。
      final build = SafetyAlertBuilder.buildFor(
        userName: 'Alice',
        daysWithoutCheckIn: 3,
        lastCheckIn: DateTime(2026, 7, 20),
        outcome: (smsOk: 1, smsFail: 0, smsMock: 0),
        l10n: _wrapEnL10n(AppLocalizationsEn()),
        channelId: 'chroniccare.safety',
        channelName: 'Safety Alert',
        channelDescription: 'Long-time no check-in',
      );

      expect(build.details.android, isA<AndroidNotificationDetails>());
      expect(
        build.details.android!.visibility,
        NotificationVisibility.public,
        reason: 'safety alert 必须用 public (紧急失联通知锁屏可见, '
            '让旁观者协助判断)',
      );
    });

    test('AndroidNotificationDetails visibility 字段类型正确', () {
      const secret = AndroidNotificationDetails(
        'a',
        'b',
        visibility: NotificationVisibility.secret,
      );
      const pub = AndroidNotificationDetails(
        'a',
        'b',
        visibility: NotificationVisibility.public,
      );
      const priv = AndroidNotificationDetails(
        'a',
        'b',
        visibility: NotificationVisibility.private,
      );
      expect(secret.visibility, NotificationVisibility.secret);
      expect(pub.visibility, NotificationVisibility.public);
      expect(priv.visibility, NotificationVisibility.private);
    });
  });

  group('NotificationVisibility 枚举完整性', () {
    test('枚举含 secret / private / public 3 值', () {
      // 防止 future pub package 改 enum 后漏处理。
      const all = NotificationVisibility.values;
      expect(all, contains(NotificationVisibility.secret));
      expect(all, contains(NotificationVisibility.private));
      expect(all, contains(NotificationVisibility.public));
    });
  });
}
