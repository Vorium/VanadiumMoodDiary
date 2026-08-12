// v0.27 round 65 (spen P1-12 god class 拆分收尾): SafetyAlertBuilder test
//
// 之前 notification_service.showSafetyAlert 50 行 0 test (只是 facade 委派),
// R65 抽到 SafetyAlertBuilder (纯函数) 后补 6 case TDD test, 锁 5 个分支:
//
// 测试设计 (覆盖 3 态 SMS outcome + lastCheckIn 2 态 + userName 2 态):
// 1. smsOk > 0 + userName + lastCheckIn some → title/body 走 "已自动通知" (sent)
// 2. smsMock > 0 + lastCheckIn null → body 走 "中性化 mocked" (已触发失联提醒) + "从未打卡"
// 3. smsFail > 0 + 全 0 → body 走 "通知发送失败" (failed 兜底)
// 4. userName = null → title 退化为 "您"
// 5. lastCheckIn = DateTime(2026, 7, 1) → body 包含 "2026-07-01" 格式化
// 6. 3 locale 覆盖 (zh / en / zh_Hant): 验证 i18n key 都不为 null + 各自 locale 内容
//
// 加上 1 个 details 验证 (Android importance=max + iOS interruptionLevel=timeSensitive)
// + 1 个 channel 验证 (传入的 channelId/Name/Description 透传)
// = 7 case 总计

import 'package:chroniccare/core/data/services/safety_alert_builder.dart';
import 'package:chroniccare/domain/repositories/safety_alert_sender.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/app_localizations_en.dart';
import 'package:chroniccare/l10n/app_localizations_zh.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// R109 round 6 part 2 适配: R109 round 2 改 builder 接受
/// `SafetyAlertL10nResolver` (tear-off 闭包), `AppLocalizations` 直接
/// 包成 resolver 即可 (闭包自然 capture this).
SafetyAlertL10nResolver _wrapL10n(AppLocalizations l) => SafetyAlertL10nResolver(
      titleFor: l.safetyAlertTitle,
      bodySent: (Object date) => l.safetyAlertBodySent(date.toString()),
      bodyMocked: (Object date) => l.safetyAlertBodyMocked(date.toString()),
      bodyFailed: (Object date) => l.safetyAlertBodyFailed(date.toString()),
      neverCheckIn: () => l.safetyAlertNeverCheckIn,
    );

void main() {
  // 测试用 channel 三元 (跟 production 保持一致结构, 但不依赖 Strings const,
  // 让 test 跟生产解耦, 改 channel 名时 test 不动)
  const channelId = 'chroniccare.safety';
  const channelName = '安全警报';
  const channelDesc = '长时间未打卡时提醒';

  group('SafetyAlertBuilder.buildFor (3 态 SMS outcome 分流)', () {
    test('1. smsOk=2 > 0 → body 走 safetyAlertBodySent (l10n 关键词: "已自动通知")', () {
      // v0.31.1 R32 (P0-04 锁屏 PII 跨 3 视角共识): title 改静态不含 name
      // (锁屏可见, userName 是 PII 风险, R108 修了 body 但漏 title).
      // title 走 l10n.titleFor(days) 拿 "⚠️ 已 N 天未打卡" 模板, userName
      // 参数保留 (兼容旧 caller 签名) 但 builder 内部不用.
      final build = SafetyAlertBuilder.buildFor(
        userName: '张三',
        daysWithoutCheckIn: 3,
        lastCheckIn: DateTime(2026, 7, 20),
        outcome: (smsOk: 2, smsFail: 0, smsMock: 0),
        l10n: _wrapL10n(AppLocalizationsZh()),
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDesc,
      );

      expect(
        build.title,
        '⚠️ 已 3 天未打卡',
        reason: 'R32 改: title 走 l10n 静态模板, 不含 userName (锁屏 PII)',
      );
      expect(build.body, contains('已自动通知'), reason: 'sent 文案: 已自动通知紧急联系人');
      expect(
        build.body,
        contains('2026-07-20'),
        reason: 'lastCheckIn 走 YYYY-MM-DD 格式',
      );
    });

    test('2. smsMock=1 > 0 + lastCheckIn=null → body 走 mocked + "从未打卡"', () {
      final build = SafetyAlertBuilder.buildFor(
        userName: '李四',
        daysWithoutCheckIn: 5,
        lastCheckIn: null,
        outcome: (smsOk: 0, smsFail: 0, smsMock: 1),
        l10n: _wrapL10n(AppLocalizationsZh()),
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDesc,
      );

      expect(build.title, '⚠️ 已 5 天未打卡', reason: 'R32 改: title 不含 name');
      expect(build.body, contains('已触发失联提醒'), reason: 'mocked 文案: R110 round 3 中性化后走 "已触发失联提醒"');
      expect(build.body, isNot(contains('开发模式')), reason: 'R110 round 3: 中性化后不再出现开发模式字样');
      expect(build.body, contains('从未打卡'), reason: 'lastCheckIn=null → "从未打卡"');
    });

    test('3. smsFail=2 + 全 0 → body 走 failed (兜底)', () {
      final build = SafetyAlertBuilder.buildFor(
        userName: '王五',
        daysWithoutCheckIn: 7,
        lastCheckIn: DateTime(2026, 7, 16),
        outcome: (smsOk: 0, smsFail: 2, smsMock: 0),
        l10n: _wrapL10n(AppLocalizationsZh()),
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDesc,
      );

      expect(build.title, '⚠️ 已 7 天未打卡', reason: 'R32 改: title 不含 name');
      expect(build.body, contains('通知发送失败'), reason: 'failed 文案: 通知发送失败');
      expect(build.body, contains('2026-07-16'));
      expect(build.body, isNot(contains('已自动通知')), reason: 'failed 不能误报"已通知"');
      expect(build.body, isNot(contains('开发模式')), reason: 'failed 不是 mocked');
    });

    test('4. userName=null → title 跟 userName=非空 一致 (R32 锁屏 PII)', () {
      // v0.31.1 R32 (P0-04 锁屏 PII): title 走 l10n 静态模板, 不含 name.
      // 因此 userName=null 跟 userName=非空 title 完全一致.
      final build = SafetyAlertBuilder.buildFor(
        userName: null,
        daysWithoutCheckIn: 2,
        lastCheckIn: null,
        outcome: (smsOk: 0, smsFail: 0, smsMock: 0),
        l10n: _wrapL10n(AppLocalizationsZh()),
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDesc,
      );

      expect(build.title, '⚠️ 已 2 天未打卡', reason: 'R32: title 走 l10n, userName 不影响');
    });

    test('5. lastCheckIn = DateTime(2026, 7, 1) → 格式化 "2026-07-01" (补零)', () {
      final build = SafetyAlertBuilder.buildFor(
        userName: '赵六',
        daysWithoutCheckIn: 1,
        lastCheckIn: DateTime(2026, 7, 1),
        outcome: (smsOk: 1, smsFail: 0, smsMock: 0),
        l10n: _wrapL10n(AppLocalizationsZh()),
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDesc,
      );

      expect(build.body, contains('2026-07-01'), reason: '月日必须补零: 7-1 → 07-01');
    });

    test('6. en locale → title 走 en l10n, body 走 en l10n (R75 改: title 走 l10n)',
        () {
      // v0.27 round 75 (R74-N7 修): title 改 l10n, 之前硬编码中文。
      // en locale 走 en l10n → "⚠️ No check-in for 3 days" (R32 锁屏 PII 改
      //   后 en 文案也不含 userName).
      final build = SafetyAlertBuilder.buildFor(
        userName: 'Alice',
        daysWithoutCheckIn: 3,
        lastCheckIn: DateTime(2026, 7, 20),
        outcome: (smsOk: 1, smsFail: 0, smsMock: 0),
        l10n: _wrapL10n(AppLocalizationsEn()),
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDesc,
      );

      expect(
        build.title,
        '⚠️ No check-in for 3 days',
        reason: 'R32 改: title 走 l10n 静态模板, en 文案不含 userName (锁屏 PII)',
      );
      expect(
        build.body,
        contains('Auto-notified'),
        reason: 'en l10n: "Auto-notified emergency contacts"',
      );
      expect(
        build.body,
        contains('2026-07-20'),
        reason: 'lastCheckIn 格式跟 locale 无关',
      );
    });

    test(
        '7. details: Android importance=max + iOS timeSensitive + channel 三元透传',
        () {
      // 验证 NotificationDetails 字段正确 (R65 重构不丢任何属性)
      final build = SafetyAlertBuilder.buildFor(
        userName: '张三',
        daysWithoutCheckIn: 3,
        lastCheckIn: DateTime(2026, 7, 20),
        outcome: (smsOk: 1, smsFail: 0, smsMock: 0),
        l10n: _wrapL10n(AppLocalizationsZh()),
        channelId: 'custom.safety.id',
        channelName: 'custom.name',
        channelDescription: 'custom.desc',
      );

      // Android 字段
      final android = build.details.android!;
      expect(android.channelId, 'custom.safety.id', reason: 'channelId 透传');
      expect(android.channelName, 'custom.name');
      expect(android.channelDescription, 'custom.desc');
      expect(
        android.importance,
        Importance.max,
        reason: 'safety 通知: 最高 importance (锁屏可见 + 震动)',
      );
      expect(android.priority, Priority.max);
      expect(
        android.category,
        AndroidNotificationCategory.alarm,
        reason: 'safety 走 alarm category',
      );

      // iOS 字段
      final ios = build.details.iOS!;
      expect(ios.presentAlert, true);
      expect(ios.presentBadge, true);
      expect(ios.presentSound, true);
      expect(
        ios.interruptionLevel,
        InterruptionLevel.timeSensitive,
        reason: 'iOS 走 timeSensitive (Bypass Do Not Disturb)',
      );
    });
  });

  // 跨 locale 烟雾测试: 3 locale 调 buildFor 都应正常, 不抛
  group('SafetyAlertBuilder.buildFor (3 locale 烟雾测试)', () {
    for (final l10n in <SafetyAlertL10nResolver>[
      _wrapL10n(AppLocalizationsZh()),
      _wrapL10n(AppLocalizationsEn()),
      // AppLocalizationsZhHant() - 暂未生成, 跳过, 等生成后补
    ]) {
      test('locale=${'zh'} → buildFor 不抛 + 3 态全覆盖', () {
        // 3 态各调一次, 确保 l10n key 在 3 locale 都非空
        for (final outcome in const [
          (smsOk: 1, smsFail: 0, smsMock: 0),
          (smsOk: 0, smsFail: 0, smsMock: 1),
          (smsOk: 0, smsFail: 1, smsMock: 0),
        ]) {
          final build = SafetyAlertBuilder.buildFor(
            userName: 'Test',
            daysWithoutCheckIn: 3,
            lastCheckIn: DateTime(2026, 7, 20),
            outcome: outcome,
            l10n: l10n,
            channelId: channelId,
            channelName: channelName,
            channelDescription: channelDesc,
          );
          expect(build.title, isNotEmpty);
          expect(
            build.body,
            isNotEmpty,
            reason: 'locale=${'zh'} body 必须非空 (3 态都要 l10n key)',
          );
        }
      });
    }
  });
}
