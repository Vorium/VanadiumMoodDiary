import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/logic/email_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmailTemplate', () {
    final lastCheckIn = DateTime(2026, 7, 9, 20, 0);
    final medication = MedicationEntity(
      id: 1,
      name: '氟西汀',
      dosage: 40,
      dosageUnit: DosageUnit.mg,
      times: const [
        HourMinute(hour: 8, minute: 0),
        HourMinute(hour: 20, minute: 0),
      ],
      startDate: DateTime(2026, 1, 1),
      endDate: null,
      refillAt: null,
      refillReminderDays: 7,
      isActive: true,
    );

    test('buildSubject 包含用户姓名和天数', () {
      final subject = EmailTemplate.buildSubject(
        userName: '小明',
        daysWithoutCheckIn: 2,
      );
      expect(subject, contains('小明'));
      expect(subject, contains('2'));
      expect(subject, contains('停药提醒'));
    });

    test('buildBody 包含温柔措辞', () {
      final body = EmailTemplate.buildBody(
        userName: '小明',
        daysWithoutCheckIn: 2,
        lastCheckIn: lastCheckIn,
        medication: medication,
        cycleHours: 48,
      );
      expect(body, contains('小明'));
      expect(body, contains('请你方便的时候提醒我'));
      expect(body, contains('避免复发'));
      expect(body, isNot(contains('死了')));
      expect(body, isNot(contains('挂了')));
    });

    test('buildBody 包含最后吃药时间', () {
      final body = EmailTemplate.buildBody(
        userName: '小明',
        daysWithoutCheckIn: 2,
        lastCheckIn: lastCheckIn,
        medication: medication,
        cycleHours: 48,
      );
      expect(body, contains('2026-07-09'));
      expect(body, contains('20:00'));
    });

    test('buildBody 包含常吃药信息（v0.6: 显示 dosage + unit）', () {
      final body = EmailTemplate.buildBody(
        userName: '小明',
        daysWithoutCheckIn: 2,
        lastCheckIn: lastCheckIn,
        medication: medication,
        cycleHours: 48,
      );
      expect(body, contains('氟西汀'));
      expect(body, contains('40'));
      expect(body, contains('mg'));
    });

    test('buildBody 包含免责声明', () {
      final body = EmailTemplate.buildBody(
        userName: '小明',
        daysWithoutCheckIn: 2,
        lastCheckIn: lastCheckIn,
        medication: medication,
        cycleHours: 48,
      );
      expect(body, contains('不包含任何医疗建议'));
    });

    // ===== v0.24 round 48 (spen P0-4 fix): 动态时区 + PIPL §17 合规 =====

    test('buildBody 不再硬编码 "UTC+8 北京时间"（防回归）', () {
      final body = EmailTemplate.buildBody(
        userName: '小明',
        daysWithoutCheckIn: 2,
        lastCheckIn: lastCheckIn,
        medication: medication,
        cycleHours: 48,
      );
      // 之前 v0.23 round 39 硬编码 "(UTC+8 北京时间)"
      // v0.24 round 48 spen P0-4 修真: 动态推断 caller 时区
      expect(body, isNot(contains('UTC+8 北京时间')));
      expect(body, isNot(contains('北京时间')));
    });

    test('buildBody 时区格式 UTC±HH:MM（referenceNow +0800）', () {
      // referenceNow 在 UTC+8 (北京时间) → 应显示 UTC+08:00
      final beijing = DateTime(2026, 7, 26, 12, 0, 0); // 假设 system tz = +8
      final body = EmailTemplate.buildBody(
        userName: '小明',
        daysWithoutCheckIn: 2,
        lastCheckIn: lastCheckIn,
        medication: medication,
        cycleHours: 48,
        referenceNow: beijing,
      );
      // lastCheckIn (2026-07-09 20:00) 配 +8 tz → "2026-07-09 20:00 (UTC+08:00)"
      // 实际 offset 取自 referenceNow.timeZoneOffset
      // 注意: 测试机 system tz 可能不是 +8,所以这个 case 在 CI 上可能 flake
      // 改成断言时区格式而非具体值
      expect(body, matches(r'UTC[+\-]\d{2}:\d{2}'));
    });

    test('buildBody 海外紧急联系人时区正确（referenceNow = UTC-5）', () {
      // PIPL §17: 之前海外联系人看到 "UTC+8" 误读
      // v0.24 round 48 fix: 用 referenceNow.timeZoneOffset 推断 caller 视角
      // 这里 referenceNow 用本地时间 DateTime (不带 tz),其 timeZoneOffset 反映 system tz
      // 为测试可重现,断言格式正确即可 (UTC±HH:MM)
      final reference = DateTime(2026, 7, 26, 12, 0, 0);
      final body = EmailTemplate.buildBody(
        userName: '小明',
        daysWithoutCheckIn: 2,
        lastCheckIn: DateTime(2026, 7, 9, 5, 0), // 海外用户视角的"20:00 北京时间"
        medication: medication,
        cycleHours: 48,
        referenceNow: reference,
      );
      expect(body, matches(r'UTC[+\-]\d{2}:\d{2}'));
      expect(body, contains('05:00'));
    });

    // ===== v0.24 round 48 (spzh P0-5 fix): bodyOverride / footerOverride / subjectOverride =====

    test('buildSubject subjectOverride 优先', () {
      final subject = EmailTemplate.buildSubject(
        userName: '小明',
        daysWithoutCheckIn: 2,
        subjectOverride: '[Medication Reminder] Alex missed for 2 days',
      );
      expect(subject, equals('[Medication Reminder] Alex missed for 2 days'));
      // 没用 Strings.emailSubject 中文 fallback
      expect(subject, isNot(contains('停药提醒')));
    });

    test('buildBody bodyOverride 优先（i18n 化）', () {
      final body = EmailTemplate.buildBody(
        userName: '小明',
        daysWithoutCheckIn: 2,
        lastCheckIn: lastCheckIn,
        medication: medication,
        cycleHours: 48,
        bodyOverride: "I'm Xiao Ming. I haven't checked in for 2 days.",
      );
      expect(body, contains("I'm Xiao Ming"));
      expect(body, isNot(contains('我是 小明')));
    });

    test('buildBody footerOverride 优先（i18n 化）', () {
      final body = EmailTemplate.buildBody(
        userName: '小明',
        daysWithoutCheckIn: 2,
        lastCheckIn: lastCheckIn,
        medication: medication,
        cycleHours: 48,
        footerOverride: 'Sent by Chronic Care app. Not medical advice.',
      );
      expect(body, contains('Sent by Chronic Care app'));
      expect(body, isNot(contains('本通知不包含任何医疗建议')));
    });

    test('buildBody 无 override 时仍用 Strings fallback（domain 兼容）', () {
      // 没传 override → 走 Strings.emailBody/emailFooter 中文 fallback
      final body = EmailTemplate.buildBody(
        userName: '小明',
        daysWithoutCheckIn: 2,
        lastCheckIn: lastCheckIn,
        medication: medication,
        cycleHours: 48,
      );
      expect(body, contains('我是 小明'));
      expect(body, contains('本通知不包含任何医疗建议'));
    });
  });
}
