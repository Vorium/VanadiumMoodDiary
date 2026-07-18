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
      dosageUnit: 'mg',
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
  });
}
