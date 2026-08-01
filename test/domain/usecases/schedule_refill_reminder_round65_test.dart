// v0.27 round 65 (spen 1.2.2 + alibaba 1.2 use case 层补):
// ScheduleRefillReminderUseCase 单元测试
//
// 5 case 覆盖:
// 1. medications 空 → schedules 空
// 2. medication 无 refillAt → fireAt=null (caller 跳过)
// 3. refillAt + reminderDays=7 → fireAt = refillAt - 7天 当天 9:00 (跟
//    RefillNotifier.computeRefillFireTime 1:1 行为)
// 4. reminderDays=0 → 抛 ArgumentError (跟 computeRefillFireTime 1:1)
// 5. fireAt < now → isExpired=true (caller 跳过调度, 走 cancel 路径)

import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/usecases/schedule_refill_reminder.dart';
import 'package:flutter_test/flutter_test.dart';

MedicationEntity _med({
  required int id,
  required bool isActive,
  DateTime? refillAt,
  int reminderDays = 7,
}) =>
    MedicationEntity(
      id: id,
      name: 'Med$id',
      isActive: isActive,
      times: const [],
      startDate: DateTime(2026, 1, 1),
      dosage: 1,
      dosageUnit: DosageUnit.tablet,
      refillAt: refillAt,
      refillReminderDays: reminderDays,
    );

void main() {
  group('ScheduleRefillReminderUseCase', () {
    const usecase = ScheduleRefillReminderUseCase();
    final now = DateTime(2026, 7, 15, 10, 0);

    test('medications 空 → schedules 空', () {
      final s = usecase(medications: const [], now: now);
      expect(s, isEmpty);
    });

    test('medication 无 refillAt → fireAt=null', () {
      final s = usecase(
        medications: [_med(id: 1, isActive: true, refillAt: null)],
        now: now,
      );
      expect(s.length, 1);
      expect(s.first.medicationId, 1);
      expect(s.first.fireAt, isNull);
      expect(s.first.isExpired, isFalse);
    });

    test('refillAt=7/20 + reminderDays=3 → fireAt=7/17 9:00 (未过期)', () {
      // 跟 RefillNotifier.computeRefillFireTime 1:1 行为:
      // fireAt = (refillAt - reminderDays 天) 当天 9:00
      // now=7/15 10:00 之后, fireAt=7/17 9:00 未过期
      final s = usecase(
        medications: [
          _med(
            id: 1,
            isActive: true,
            refillAt: DateTime(2026, 7, 20),
            reminderDays: 3,
          ),
        ],
        now: now,
      );
      expect(s.first.fireAt, DateTime(2026, 7, 17, 9, 0));
      expect(s.first.isExpired, isFalse);
    });

    test('reminderDays=0 → 抛 ArgumentError (跟 computeRefillFireTime 1:1)', () {
      expect(
        () => usecase(
          medications: [
            _med(
              id: 1,
              isActive: true,
              refillAt: DateTime(2026, 7, 20),
              reminderDays: 0,
            ),
          ],
          now: now,
        ),
        throwsArgumentError,
      );
    });

    test('fireAt < now → isExpired=true (跳过调度, 走 cancel)', () {
      // refillAt = 7/10, reminderDays = 7 → fireAt = 7/3 9:00 (已过)
      final s = usecase(
        medications: [
          _med(
            id: 1,
            isActive: true,
            refillAt: DateTime(2026, 7, 10),
            reminderDays: 7,
          ),
        ],
        now: now,
      );
      expect(s.first.fireAt, DateTime(2026, 7, 3, 9, 0));
      expect(s.first.isExpired, isTrue);
    });
  });
}
