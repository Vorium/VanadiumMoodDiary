// v0.31.1 round 7 (P0-06 修 GooglePlay P0-006) — Android 锁屏通知 PII 防护守门员
//
// 背景: 精神心理 / 慢性病患者用 App, 通知在 Android 7+ (API 24+) 锁屏可见。
// 之前 3 个 AndroidNotificationDetails() 构造没设 `visibility`:
//   - Android 7+ 默认 VISIBILITY_PRIVATE (系统自动 redact 部分 PII), 但当
//     channel name 含 "ChronicCare · 服药提醒" 等 app 标识时, 仍会在锁屏显示
//     完整 title → "该吃药了 · 点一下 = 打卡" → 旁观者一眼看出是慢病/精神类 App。
//   - 慢性病 + 精神心理 App 用户希望"完全不在锁屏显示" (有人偷看手机)。
//
// 1.1.0 round 4b (emotion-first refactor): safety alert (失联通知) 随外联
// 服务整摘 — 之前它单独走 public (紧急场景锁屏可见), 本守门员删 safety
// 分支, 只剩 reminder 类 3 文件全 secret。
//
// 本守门员防止以后有人改回无 visibility:
//
//   [1/2] Source-level 静态扫: 3 个文件里 AndroidNotificationDetails(...) 调用
//         必须含 `visibility: NotificationVisibility.secret` 字段。
//   [2/2] Runtime 实测: ReminderDispatcher.buildChannelDetails() 构造的
//         AndroidNotificationDetails 实际 visibility 字段值匹配 secret。
//
// 注: visibility 是 Android 平台特有 (iOS 锁屏 "Show Previews" 是系统设置, app 端
// 无法绕过)。所以本守门员只针对 AndroidNotificationDetails, 不动 DarwinNotificationDetails。
// title/body 去 PII 已在 R108 P0-3 / P0-012 修过, 守门员脚本:
//   scripts/check_pii_in_title.py
library;

import 'dart:io';

import 'package:chroniccare/core/platform/notification/reminder_dispatcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// 3 个待检查文件 (相对 worktree 根, round 4b: safety_alert_builder 已摘,
/// v1.1.0+181 R128a 抽 core/platform/notification/)
const _kTargetFiles = <String>[
  'lib/core/platform/notification/notification_service.dart',
  'lib/core/platform/notification/reminder_dispatcher.dart',
  'lib/core/platform/notification/snooze_manager.dart',
];

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

        // 必须有 visibility: NotificationVisibility.secret
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
      });
    }

    test('3 个 reminder 类 visibility 全部 = secret (锁屏完全隐藏)', () {
      // 防止有人把 reminder 改成 public (锁屏泄露 PII) 或 private (锁屏部分
      // 仍显示, 不够安全)
      for (final relPath in _kTargetFiles) {
        final content = File(relPath).readAsStringSync();
        expect(
          content,
          contains('visibility: NotificationVisibility.secret,'),
          reason: '$relPath: reminder 类通知必须用 secret (锁屏完全不显示)',
        );
      }
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

    test('high=false (被动 push) 同样 visibility = secret (跟 high=true 一致)', () {
      final details = dispatcher.buildChannelDetails(high: false);
      expect(
        details.android!.visibility,
        NotificationVisibility.secret,
        reason: '被动 push 也要 secret, 不能因为 priority 低就泄露 PII',
      );
    });
  });

  group('AndroidNotificationDetails visibility 字段', () {
    test('visibility 字段类型正确', () {
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
