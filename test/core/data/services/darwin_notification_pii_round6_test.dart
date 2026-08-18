// v0.31.1 round 6 (P0-05 修 AppStore BUG-2 + emil P0-C) — 锁屏通知 PII 防护守门员
//
// 背景: 精神心理 / 慢性病患者用 App, 通知在 iOS / Android 锁屏横幅可见。
// 之前 3 个 DarwinNotificationDetails() 空构造缺关键 iOS 通知 metadata:
//   - categoryIdentifier → iOS UNNotificationCategory 未归类, 长按/管理通知分组失效
//   - interruptionLevel → 默认 active, 紧急通知不强提示, Do Not Disturb / Focus 模式下被吞
//
// 本守门员防止以后有人改回空构造:
//
//   [1/2] Source-level 静态扫: 3 个文件里 DarwinNotificationDetails(...) 调用
//         必须含 categoryIdentifier + interruptionLevel = timeSensitive
//   [2/2] Runtime 实测: ReminderDispatcher.buildChannelDetails() 构造的
//         DarwinNotificationDetails 实际字段值匹配
//
// 注: relevanceScore 是 iOS native UNNotificationContent 字段, 但
// flutter_local_notifications 17.2.4 / 22.3.0 都不暴露此参数 (查 pub.dev
// API 文档), 所以本守门员只校验 categoryIdentifier + interruptionLevel。
// 锁屏 PII 防护的真正开关是 iOS 系统 "Show Previews" 设置, app 端无法绕过。
// title/body 去 PII 已在 R108 P0-3 / P0-012 修过, 守门员脚本:
//   scripts/check_pii_in_title.py
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:chroniccare/core/platform/notification/reminder_dispatcher.dart';

/// 3 个待检查文件 (相对 worktree 根, v1.1.0+181 R128a 抽 core/platform/notification/)
const _kTargetFiles = <String>[
  'lib/core/platform/notification/notification_service.dart',
  'lib/core/platform/notification/reminder_dispatcher.dart',
  'lib/core/platform/notification/snooze_manager.dart',
];

/// 3 个文件期望的 categoryIdentifier
const _kExpectedCategoryIdentifier = <String, String>{
  'lib/core/platform/notification/notification_service.dart':
      'com.chroniccare.reminder',
  'lib/core/platform/notification/reminder_dispatcher.dart':
      'com.chroniccare.medication.reminder',
  'lib/core/platform/notification/snooze_manager.dart': 'com.chroniccare.snooze',
};

void main() {
  group('[1/2] Source-level 静态扫 (防以后退回空构造)', () {
    for (final relPath in _kTargetFiles) {
      test('$relPath 包含完整 iOS 通知 metadata', () {
        final file = File(relPath);
        expect(
          file.existsSync(),
          isTrue,
          reason: '文件不存在: $relPath (工作目录应在 worktree 根)',
        );
        final content = file.readAsStringSync();

        // 必须有 DarwinNotificationDetails(...) 构造 (至少 1 个)
        final darwinMatches = RegExp(r'DarwinNotificationDetails\s*\(')
            .allMatches(content)
            .toList();
        expect(
          darwinMatches,
          isNotEmpty,
          reason: '$relPath: 找不到任何 DarwinNotificationDetails('
              ') 构造调用, 可能已重构或文件改错',
        );

        // 必须有 categoryIdentifier
        expect(
          content,
          contains('categoryIdentifier:'),
          reason:
              '$relPath: 缺 categoryIdentifier (iOS UNNotificationCategory 归类)',
        );

        // 必须有 interruptionLevel: InterruptionLevel.timeSensitive
        expect(
          content,
          contains('interruptionLevel: InterruptionLevel.timeSensitive'),
          reason: '$relPath: 缺 interruptionLevel: timeSensitive '
              '(紧急通知穿透 Do Not Disturb / Focus)',
        );

        // 期望的 categoryIdentifier 值必须存在
        final expected = _kExpectedCategoryIdentifier[relPath]!;
        expect(
          content,
          contains("categoryIdentifier: '$expected'"),
          reason: '$relPath: categoryIdentifier 值不是期望的 '
              "'$expected' (reverse-DNS com.chroniccare.<feature> 规范)",
        );
      });
    }

    test('3 个 categoryIdentifier 互不重复 (避免 iOS 归类冲突)', () {
      final ids = _kExpectedCategoryIdentifier.values.toSet();
      expect(
        ids.length,
        _kExpectedCategoryIdentifier.length,
        reason: 'categoryIdentifier 命名重复 — iOS 长按通知分组会冲突',
      );
    });

    test('3 个 categoryIdentifier 遵循 com.chroniccare.<feature> reverse-DNS 规范',
        () {
      for (final entry in _kExpectedCategoryIdentifier.entries) {
        expect(
          entry.value,
          matches(RegExp(r'^com\.chroniccare\.[a-z.]+$')),
          reason: '${entry.key}: categoryIdentifier "${entry.value}" '
              '不遵循 reverse-DNS 规范 (应 com.chroniccare.<feature>)',
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

    test('iOS: categoryIdentifier = com.chroniccare.medication.reminder', () {
      final details = dispatcher.buildChannelDetails();
      expect(details.iOS, isA<DarwinNotificationDetails>());
      expect(
        details.iOS!.categoryIdentifier,
        'com.chroniccare.medication.reminder',
        reason: 'buildChannelDetails() 返回的 iOS categoryIdentifier '
            '跟 source-level 期望值不一致',
      );
    });

    test('iOS: interruptionLevel = InterruptionLevel.timeSensitive', () {
      final details = dispatcher.buildChannelDetails();
      expect(
        details.iOS!.interruptionLevel,
        InterruptionLevel.timeSensitive,
        reason: 'buildChannelDetails() 必须用 timeSensitive (穿透 Do Not Disturb)',
      );
    });

    test('high=false (被动 push) 同样带 iOS metadata (跟 high=true 行为一致)', () {
      final details = dispatcher.buildChannelDetails(high: false);
      expect(
        details.iOS!.categoryIdentifier,
        'com.chroniccare.medication.reminder',
      );
      expect(details.iOS!.interruptionLevel, InterruptionLevel.timeSensitive);
    });
  });
}
