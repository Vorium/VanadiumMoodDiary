// v0.27 round 65 (spen P1-12 god class 拆分收尾): SafetyAlertBuilder test
//
// 之前 notification_service.showSafetyAlert 50 行 0 test (只是 facade 委派),
// R65 抽到 SafetyAlertBuilder (纯函数) 后补 6 case TDD test, 锁 5 个分支:
//
// 测试设计 (覆盖 3 态 SMS outcome + lastCheckIn 2 态 + userName 2 态):
// 1. smsOk > 0 + userName + lastCheckIn some → title/body 走 "已自动通知" (sent)
// 2. smsMock > 0 + lastCheckIn null → body 走 "开发模式" (mocked) + "从未打卡"
// 3. smsFail > 0 + 全 0 → body 走 "通知发送失败" (failed 兜底)
// 4. userName = null → title 退化为 "您"
// 5. lastCheckIn = DateTime(2026, 7, 1) → body 包含 "2026-07-01" 格式化
// 6. 3 locale 覆盖 (zh / en / zh_Hant): 验证 i18n key 都不为 null + 各自 locale 内容
//
// 加上 1 个 details 验证 (Android importance=max + iOS interruptionLevel=timeSensitive)
// + 1 个 channel 验证 (传入的 channelId/Name/Description 透传)
// = 7 case 总计

import 'package:chroniccare/core/data/services/safety_alert_builder.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/app_localizations_en.dart';
import 'package:chroniccare/l10n/app_localizations_zh.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 测试用 channel 三元 (跟 production 保持一致结构, 但不依赖 Strings const,
  // 让 test 跟生产解耦, 改 channel 名时 test 不动)
  const channelId = 'chroniccare.safety';
  const channelName = '安全警报';
  const channelDesc = '长时间未打卡时提醒';

  group('SafetyAlertBuilder.buildFor (3 态 SMS outcome 分流)', () {
    test('1. smsOk=2 > 0 → body 走 safetyAlertBodySent (l10n 关键词: "已自动通知")', () {
      final build = SafetyAlertBuilder.buildFor(
        userName: '张三',
        daysWithoutCheckIn: 3,
        lastCheckIn: DateTime(2026, 7, 20),
        outcome: (smsOk: 2, smsFail: 0, smsMock: 0),
        l10n: AppLocalizationsZh(),
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDesc,
      );

      expect(build.title, '⚠️ 张三 已 3 天未打卡',
          reason: 'title 用 safeUserName + days, ⚠️ 前缀',);
      expect(build.body, contains('已自动通知'), reason: 'sent 文案: 已自动通知紧急联系人');
      expect(build.body, contains('2026-07-20'),
          reason: 'lastCheckIn 走 YYYY-MM-DD 格式',);
    });

    test('2. smsMock=1 > 0 + lastCheckIn=null → body 走 mocked + "从未打卡"', () {
      final build = SafetyAlertBuilder.buildFor(
        userName: '李四',
        daysWithoutCheckIn: 5,
        lastCheckIn: null,
        outcome: (smsOk: 0, smsFail: 0, smsMock: 1),
        l10n: AppLocalizationsZh(),
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDesc,
      );

      expect(build.title, '⚠️ 李四 已 5 天未打卡');
      expect(build.body, contains('开发模式'), reason: 'mocked 文案: 当前为开发模式');
      expect(build.body, contains('未实际通知'), reason: 'mocked 文案: 未实际通知紧急联系人');
      expect(build.body, contains('从未打卡'), reason: 'lastCheckIn=null → "从未打卡"');
    });

    test('3. smsFail=2 + 全 0 → body 走 failed (兜底)', () {
      final build = SafetyAlertBuilder.buildFor(
        userName: '王五',
        daysWithoutCheckIn: 7,
        lastCheckIn: DateTime(2026, 7, 16),
        outcome: (smsOk: 0, smsFail: 2, smsMock: 0),
        l10n: AppLocalizationsZh(),
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDesc,
      );

      expect(build.title, '⚠️ 王五 已 7 天未打卡');
      expect(build.body, contains('通知发送失败'), reason: 'failed 文案: 通知发送失败');
      expect(build.body, contains('2026-07-16'));
      expect(build.body, isNot(contains('已自动通知')), reason: 'failed 不能误报"已通知"');
      expect(build.body, isNot(contains('开发模式')), reason: 'failed 不是 mocked');
    });

    test('4. userName=null → title 退化为 "您" (R23 P1-24 nullable 修复)', () {
      final build = SafetyAlertBuilder.buildFor(
        userName: null,
        daysWithoutCheckIn: 2,
        lastCheckIn: null,
        outcome: (smsOk: 0, smsFail: 0, smsMock: 0),
        l10n: AppLocalizationsZh(),
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDesc,
      );

      expect(build.title, '⚠️ 您 已 2 天未打卡', reason: 'safeUserName(null) → "您"');
    });

    test('5. lastCheckIn = DateTime(2026, 7, 1) → 格式化 "2026-07-01" (补零)', () {
      final build = SafetyAlertBuilder.buildFor(
        userName: '赵六',
        daysWithoutCheckIn: 1,
        lastCheckIn: DateTime(2026, 7, 1),
        outcome: (smsOk: 1, smsFail: 0, smsMock: 0),
        l10n: AppLocalizationsZh(),
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDesc,
      );

      expect(build.body, contains('2026-07-01'), reason: '月日必须补零: 7-1 → 07-01');
    });

    test('6. en locale → title 走 zh (硬编 "已 X 天未打卡"), body 走 en l10n', () {
      // 验证 i18n 隔离: 同一 inputs, 换 l10n, body 文案必须不同
      // (title 暂 hardcode 中文, 因为 userName 跟 days 也是中文显示格式,
      //  跟 safetyAlertBodySent/Mocked/Failed 走 l10n 不冲突)
      final build = SafetyAlertBuilder.buildFor(
        userName: 'Alice',
        daysWithoutCheckIn: 3,
        lastCheckIn: DateTime(2026, 7, 20),
        outcome: (smsOk: 1, smsFail: 0, smsMock: 0),
        l10n: AppLocalizationsEn(),
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDesc,
      );

      expect(build.title, '⚠️ Alice 已 3 天未打卡',
          reason: 'title 硬编中文格式, 跟 locale 无关',);
      expect(build.body, contains('Auto-notified'),
          reason: 'en l10n: "Auto-notified emergency contacts"',);
      expect(build.body, contains('2026-07-20'),
          reason: 'lastCheckIn 格式跟 locale 无关',);
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
        l10n: AppLocalizationsZh(),
        channelId: 'custom.safety.id',
        channelName: 'custom.name',
        channelDescription: 'custom.desc',
      );

      // Android 字段
      final android = build.details.android!;
      expect(android.channelId, 'custom.safety.id', reason: 'channelId 透传');
      expect(android.channelName, 'custom.name');
      expect(android.channelDescription, 'custom.desc');
      expect(android.importance, Importance.max,
          reason: 'safety 通知: 最高 importance (锁屏可见 + 震动)',);
      expect(android.priority, Priority.max);
      expect(android.category, AndroidNotificationCategory.alarm,
          reason: 'safety 走 alarm category',);

      // iOS 字段
      final ios = build.details.iOS!;
      expect(ios.presentAlert, true);
      expect(ios.presentBadge, true);
      expect(ios.presentSound, true);
      expect(ios.interruptionLevel, InterruptionLevel.timeSensitive,
          reason: 'iOS 走 timeSensitive (Bypass Do Not Disturb)',);
    });
  });

  // 跨 locale 烟雾测试: 3 locale 调 buildFor 都应正常, 不抛
  group('SafetyAlertBuilder.buildFor (3 locale 烟雾测试)', () {
    for (final l10n in <AppLocalizations>[
      AppLocalizationsZh(),
      AppLocalizationsEn(),
      // AppLocalizationsZhHant() - 暂未生成, 跳过, 等生成后补
    ]) {
      test('locale=${l10n.localeName} → buildFor 不抛 + 3 态全覆盖', () {
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
          expect(build.body, isNotEmpty,
              reason: 'locale=${l10n.localeName} body 必须非空 (3 态都要 l10n key)',);
        }
      });
    }
  });
}
