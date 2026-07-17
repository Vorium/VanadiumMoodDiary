import 'package:chroniccare/data/services/email_service.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EmailService (Mock 模式)', () {
    test('Mock 模式发送成功', () async {
      final service = EmailService(useMock: true);

      final success = await service.sendMedicationReminder(
        to: '13800138000', // v0.6: phone 替代 email
        userName: '小明',
        daysWithoutCheckIn: 2,
        lastCheckIn: DateTime(2026, 7, 9, 20, 0),
        medication: MedicationEntity(
          id: 1,
          name: '氟西汀',
          dosage: 40,
          dosageUnit: 'mg',
          times: const [HourMinute(hour: 8, minute: 0)],
          startDate: DateTime(2026, 1, 1),
          endDate: null,
          isActive: true,
          refillAt: null,
          refillReminderDays: 7,
        ),
        cycleHours: 48,
      );

      expect(success, true);
    });

    test('Mock 模式不需要 API Key 也能发送', () async {
      final service = EmailService(useMock: true, apiKey: null);
      final success = await service.sendMedicationReminder(
        to: '13800138000',
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
