import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/data/services/email_service.dart';
import 'package:chroniccare/data/database/app_database.dart';

void main() {
  group('EmailService (Mock 模式)', () {
    test('Mock 模式发送成功', () async {
      final service = EmailService(useMock: true);

      final success = await service.sendMedicationReminder(
        to: 'test@example.com',
        userName: '小明',
        daysWithoutCheckIn: 2,
        lastCheckIn: DateTime(2026, 7, 9, 20, 0),
        medication: Medication(
          id: 1,
          name: '舍曲林',
          frequencyPerDay: 1,
          timesJson: '["20:00"]',
          startDate: DateTime(2026, 1, 1),
          endDate: null,
          isActive: true,
        ),
        cycleHours: 48,
      );

      expect(success, true);
    });

    test('Mock 模式不需要 API Key 也能发送', () async {
      final service = EmailService(useMock: true, apiKey: null);
      final success = await service.sendMedicationReminder(
        to: 'test@example.com',
        userName: '用户',
        daysWithoutCheckIn: 1,
        lastCheckIn: null,
        medication: null,
        cycleHours: 48,
      );
      expect(success, true);
    });
  });
}
