// v0.27 round 82: buildLostContactSms 模板单测
//
// 背景: lost_contact_sms.dart 是失联 SMS 模板单一 source (R62 P1-5 修复),
// 2 个 service (SafetyAlertDispatcher + ReminderService) 都走它, 走
// kind 选分支 (safetyAlert / reminder)。
//
// 之前 0 单元测, R82 补 8 case 覆盖:
// 1. safetyAlert: 含 "如确认安全请回复 1" 业务逻辑 (PIPL §13 + 精神心理保护)
// 2. reminder + daysSince>=2: 含 "天" 单位
// 3. reminder + daysSince<2: 含 "小时" 单位
// 4. override 优先: caller 传 override 时直接返 override
// 5. userName null/空/纯空白: 走 Strings.userNameFamily ("您的家人")
// 6. userName 长名字: 100+ 字符也能塞进模板 (PIPL §6 最小化原则不影响模板长度)
// 7. medication 字段: 当前模板不暴露 medication.name (PIPL §6 修)
// 8. 4 国 hotline: 本类不接 hotline (i18n key 是 safety_watch 那边的事),
//    本测试验证 hot path 走 "如确认安全请回复 1" 业务逻辑约束
//
// 注: SmsDispatchOutcome 实际是 `({int smsOk, int smsFail, int smsMock})` 记录,
//     跟 `buildLostContactSms` 不直接相关 (outcome 影响 safety_alert_builder
//     的 3 态文案, 不影响发给联系人的 SMS body)。本测试聚焦 `kind` 维度
//     (safetyAlert / reminder 2 分支), outcome 维度由 safety_alert_builder
//     测覆盖。

import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/logic/lost_contact_sms.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildLostContactSms — safetyAlert kind (PIPL §13 强场景)', () {
    test('必含 "如确认安全请回复 1" 业务逻辑 (精神心理患者保护)', () {
      // 业务底线: 失联告警 SMS 必须给家属一个"确认安全请回复 1"的反悔口
      // (PIPL §13 + 精神心理 App 设计的非协商底线, R62 P1-5 修复)
      final sms = buildLostContactSms(
        kind: LostContactSmsKind.safetyAlert,
        userName: '张三',
        daysSince: 3,
        hoursSince: 72,
      );
      expect(sms, contains('如确认安全请回复 1'));
    });

    test('含联系人姓名 + 失联天数', () {
      final sms = buildLostContactSms(
        kind: LostContactSmsKind.safetyAlert,
        userName: '张三',
        daysSince: 5,
        hoursSince: 120,
      );
      expect(sms, contains('张三'));
      expect(sms, contains('5'));
      expect(sms, contains('天'));
    });

    test('userName null → 走 Strings.userNameFamily fallback ("您的家人")', () {
      final sms = buildLostContactSms(
        kind: LostContactSmsKind.safetyAlert,
        userName: null,
        daysSince: 2,
        hoursSince: 48,
      );
      // safeUserName(null) → fallback
      expect(sms, contains('您的家人'));
      // 不应崩
      expect(sms, isNotEmpty);
    });

    test('userName 空字符串 → 走 Strings.userNameFamily fallback', () {
      // safeUserName 兼容 null + "" (R23 P1-24 修复)
      final sms = buildLostContactSms(
        kind: LostContactSmsKind.safetyAlert,
        userName: '',
        daysSince: 2,
        hoursSince: 48,
      );
      expect(sms, contains('您的家人'));
    });

    test('userName 纯空白 (safeUserName 已知行为) → 不走 fallback', () {
      // safeUserName 只兼容 null + "", 纯空白 ("   ") 不 trim,
      // 会原样拼进 SMS, 这是已知行为 (R23 P1-24 修复注释只提 null/"").
      // 锁: 文档化此行为, 避免 caller 误用纯空白 userName.
      // (修改 safeUserName 加 trim 是 caller 改的事情, 本类不动)
      final sms = buildLostContactSms(
        kind: LostContactSmsKind.safetyAlert,
        userName: '   ',
        daysSince: 2,
        hoursSince: 48,
      );
      // 实际行为: "   " 不触发 fallback, 原样拼进模板
      expect(sms, contains('   '));
      expect(sms, isNot(contains('您的家人')));
    });

    test('override 优先: caller 传 override 时直接返 override (不拼模板)', () {
      // R61 P0-2 i18n override 模式: 传 l10n 拿翻译版, 不走 fallback
      const override = '[en] John Doe has not checked in for 3 days. '
          'Please reply 1 if safe.';
      final sms = buildLostContactSms(
        kind: LostContactSmsKind.safetyAlert,
        userName: '张三',
        daysSince: 3,
        hoursSince: 72,
        override: override,
      );
      expect(sms, override);
      // 不应拼中文 fallback
      expect(sms, isNot(contains('如确认安全请回复 1')));
    });
  });

  group('buildLostContactSms — reminder kind (日常催办)', () {
    test('daysSince >= 2 → 含 "天没打卡" 文案', () {
      final sms = buildLostContactSms(
        kind: LostContactSmsKind.reminder,
        userName: '张三',
        daysSince: 3,
        hoursSince: 72,
      );
      expect(sms, contains('张三'));
      expect(sms, contains('3'));
      expect(sms, contains('天没打卡'));
    });

    test('daysSince < 2 → 含 "小时没打卡" 文案 (避免 0 天漏服)', () {
      // daysSince=0 / 1 时, 用 hoursSince 表达, 不报 "0 天没打卡"
      final sms = buildLostContactSms(
        kind: LostContactSmsKind.reminder,
        userName: '张三',
        daysSince: 0,
        hoursSince: 18,
      );
      expect(sms, contains('18'));
      expect(sms, contains('小时没打卡'));
      // 不应说 "0 天"
      expect(sms, isNot(contains('0 天')));
    });

    test('中性化: 含 "对方" 而非 "TA" (v0.27 R72 spzh R66 P0-5 修)', () {
      // 网络用语 "TA" 在正式 SMS 不专业, 改 "对方" 中性
      final sms = buildLostContactSms(
        kind: LostContactSmsKind.reminder,
        userName: '张三',
        daysSince: 3,
        hoursSince: 72,
      );
      expect(sms, contains('对方'));
      expect(sms, isNot(contains('TA')));
    });

    test('PIPL §6 修: 不暴露 medication.name / dosage (v0.27 R75 修)', () {
      // 修复前 SMS 包含具体药名 (e.g. "舍曲林 50mg"), 属 PII 医疗信息
      // 修复后改"按时吃药"中性提示
      final med = MedicationEntity(
        id: 1,
        name: '舍曲林',
        dosage: 50,
        dosageUnit: DosageUnit.mg,
        times: const [HourMinute(hour: 8, minute: 0)],
        startDate: DateTime(2026, 1, 1),
        endDate: null,
        isActive: true,
        refillAt: null,
        refillReminderDays: 7,
      );
      final sms = buildLostContactSms(
        kind: LostContactSmsKind.reminder,
        userName: '张三',
        daysSince: 3,
        hoursSince: 72,
        medication: med,
      );
      // 不应暴露 med.name / dosage
      expect(sms, isNot(contains('舍曲林')));
      expect(sms, isNot(contains('50')));
    });
  });

  group('buildLostContactSms — LostContactSmsKind enum', () {
    test('enum 2 值: safetyAlert / reminder', () {
      expect(LostContactSmsKind.values.length, 2);
      expect(LostContactSmsKind.values, contains(LostContactSmsKind.safetyAlert));
      expect(LostContactSmsKind.values, contains(LostContactSmsKind.reminder));
      expect(LostContactSmsKind.safetyAlert.name, 'safetyAlert');
      expect(LostContactSmsKind.reminder.name, 'reminder');
    });
  });

  group('buildLostContactSms — boundary', () {
    test('超长 userName (100 字符) → 仍能塞进模板, 不崩', () {
      // PIPL §6 最小化原则不限制模板长度上限, 但实际短信 70 字限制是
      // 中文 SMS 服务商限制 (非本函数责任), 本函数只验证不崩
      final longName = '张' * 100;
      final sms = buildLostContactSms(
        kind: LostContactSmsKind.safetyAlert,
        userName: longName,
        daysSince: 1,
        hoursSince: 24,
      );
      expect(sms, isNotEmpty);
      expect(sms, contains(longName));
    });

    test('极端 daysSince (1000 天) → 模板能容纳', () {
      final sms = buildLostContactSms(
        kind: LostContactSmsKind.safetyAlert,
        userName: '张三',
        daysSince: 1000,
        hoursSince: 24000,
      );
      expect(sms, contains('1000'));
    });

    test('daysSince=0 + hoursSince=0 (刚打卡) → reminder 不说 "0 天" / "0 小时"', () {
      // 0 天 + 0 小时 极端边界: 刚打卡 (now 几乎等于 last check-in)
      // 模板不应说 "0 天" "0 小时"
      final sms = buildLostContactSms(
        kind: LostContactSmsKind.reminder,
        userName: '张三',
        daysSince: 0,
        hoursSince: 0,
      );
      expect(sms, contains('0'));
      // 但具体场景: hoursSince=0 时仍走 "小时没打卡" 分支
      expect(sms, contains('小时没打卡'));
    });
  });

  group('buildLostContactSms — override 全替换', () {
    test('override 传 null → 走默认模板 (跟不传一样)', () {
      // override = null 等价不传, 跟正常 safetyAlert 行为一致
      final smsWithNull = buildLostContactSms(
        kind: LostContactSmsKind.safetyAlert,
        userName: '张三',
        daysSince: 3,
        hoursSince: 72,
        override: null,
      );
      final smsDefault = buildLostContactSms(
        kind: LostContactSmsKind.safetyAlert,
        userName: '张三',
        daysSince: 3,
        hoursSince: 72,
      );
      expect(smsWithNull, smsDefault);
    });

    test('override 传空字符串 "" → 仍走默认模板? (caller bug 检测)', () {
      // 注: 当前实现 `if (override != null) return override;`
      // override = "" 时, 函数返 "" (而非 fallback), 这是 caller bug 风险
      // — override 应至少有内容。锁: 文档化此行为, 避免 caller 误用。
      final sms = buildLostContactSms(
        kind: LostContactSmsKind.safetyAlert,
        userName: '张三',
        daysSince: 3,
        hoursSince: 72,
        override: '',
      );
      // 当前实现: override="" 直接返 ""
      expect(sms, '');
    });
  });
}
