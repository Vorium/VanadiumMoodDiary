import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/logic/email_template.dart';
import 'package:chroniccare/data/database/app_database.dart';

void main() {
  group('EmailTemplate', () {
    final lastCheckIn = DateTime(2026, 7, 9, 20, 0);
    final medication = Medication(
      id: 1,
      name: '舍曲林',
      frequencyPerDay: 1,
      timesJson: '["20:00"]',
      startDate: DateTime(2026, 1, 1),
      endDate: null,
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
      // 不能有"死了""挂了""没了"等恐吓词
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

    test('buildBody 包含常吃药信息', () {
      final body = EmailTemplate.buildBody(
        userName: '小明',
        daysWithoutCheckIn: 2,
        lastCheckIn: lastCheckIn,
        medication: medication,
        cycleHours: 48,
      );
      expect(body, contains('舍曲林'));
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

    test('buildHtml 是有效的 HTML 结构', () {
      final html = EmailTemplate.buildHtml(
        userName: '小明',
        daysWithoutCheckIn: 2,
        lastCheckIn: lastCheckIn,
        medication: medication,
        cycleHours: 48,
      );
      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('<html>'));
      expect(html, contains('</html>'));
      expect(html, contains('慢病管家'));
      expect(html, contains('🌱'));
    });
  });
}
