// v0.12 (Round 6) NotificationService.computeRefillFireTime 纯计算测试
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationService.computeRefillFireTime', () {
    test('refillAt = null → null', () {
      expect(
        NotificationService.computeRefillFireTime(
          refillAt: null,
          reminderDays: 7,
        ),
        isNull,
      );
    });

    test('reminderDays = 7：触发时间 = 续方日期前 7 天 9 点', () {
      final result = NotificationService.computeRefillFireTime(
        refillAt: DateTime(2026, 7, 25),
        reminderDays: 7,
      );
      // 7-25 减 7 天 = 7-18
      expect(result, DateTime(2026, 7, 18, 9, 0));
    });

    test('reminderDays = 14：触发时间 = 续方日期前 14 天 9 点', () {
      final result = NotificationService.computeRefillFireTime(
        refillAt: DateTime(2026, 8, 1),
        reminderDays: 14,
      );
      expect(result, DateTime(2026, 7, 18, 9, 0));
    });

    test('reminderDays = 3：触发时间 = 续方日期前 3 天 9 点', () {
      final result = NotificationService.computeRefillFireTime(
        refillAt: DateTime(2026, 7, 25),
        reminderDays: 3,
      );
      expect(result, DateTime(2026, 7, 22, 9, 0));
    });

    test('跨月：refillAt 8/5, reminderDays=10 → 7/26', () {
      final result = NotificationService.computeRefillFireTime(
        refillAt: DateTime(2026, 8, 5),
        reminderDays: 10,
      );
      expect(result, DateTime(2026, 7, 26, 9, 0));
    });

    test('跨年：refillAt 2027-1-5, reminderDays=7 → 2026-12-29', () {
      final result = NotificationService.computeRefillFireTime(
        refillAt: DateTime(2027, 1, 5),
        reminderDays: 7,
      );
      expect(result, DateTime(2026, 12, 29, 9, 0));
    });

    test('触发时间永远是 9:00（无时分秒漂移）', () {
      // 续方时间带时分秒也应被截到 0 点
      final result = NotificationService.computeRefillFireTime(
        refillAt: DateTime(2026, 7, 25, 15, 30, 45),
        reminderDays: 7,
      );
      expect(result!.hour, 9);
      expect(result.minute, 0);
      expect(result.second, 0);
    });

    test('reminderDays = 0 抛 ArgumentError', () {
      expect(
        () => NotificationService.computeRefillFireTime(
          refillAt: DateTime(2026, 7, 25),
          reminderDays: 0,
        ),
        throwsArgumentError,
      );
    });

    test('reminderDays 负数抛 ArgumentError', () {
      expect(
        () => NotificationService.computeRefillFireTime(
          refillAt: DateTime(2026, 7, 25),
          reminderDays: -1,
        ),
        throwsArgumentError,
      );
    });

    test('触发时间在续方日期之前（不会同日触发）', () {
      // reminderDays = 1 → 续方前一天 9 点
      final result = NotificationService.computeRefillFireTime(
        refillAt: DateTime(2026, 7, 25),
        reminderDays: 1,
      );
      expect(result, DateTime(2026, 7, 24, 9, 0));
      expect(result!.isBefore(DateTime(2026, 7, 25)), isTrue);
    });
  });
}
