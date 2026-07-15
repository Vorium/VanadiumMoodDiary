import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/logic/reminder_scheduler.dart';

void main() {
  group('ReminderScheduler', () {
    final now = DateTime(2026, 7, 11, 20, 0);
    ContactEntity makeContact({int sortOrder = 0, bool isActive = true}) {
      return ContactEntity(
        id: sortOrder,
        name: 'Contact $sortOrder',
        phone: '1380013800$sortOrder',
        sortOrder: sortOrder,
        isActive: isActive,
      );
    }

    group('shouldSendAlert', () {
      test('没最后打卡 → false', () {
        expect(
          ReminderScheduler.shouldSendAlert(
            lastCheckIn: null,
            cycleHours: 48,
            now: now,
          ),
          false,
        );
      });

      test('24h 没打卡（< 48h）→ false', () {
        final lastCheckIn = now.subtract(const Duration(hours: 24));
        expect(
          ReminderScheduler.shouldSendAlert(
            lastCheckIn: lastCheckIn,
            cycleHours: 48,
            now: now,
          ),
          false,
        );
      });

      test('48h 没打卡 → true', () {
        final lastCheckIn = now.subtract(const Duration(hours: 48));
        expect(
          ReminderScheduler.shouldSendAlert(
            lastCheckIn: lastCheckIn,
            cycleHours: 48,
            now: now,
          ),
          true,
        );
      });

      test('72h 没打卡 → true', () {
        final lastCheckIn = now.subtract(const Duration(hours: 72));
        expect(
          ReminderScheduler.shouldSendAlert(
            lastCheckIn: lastCheckIn,
            cycleHours: 48,
            now: now,
          ),
          true,
        );
      });
    });

    group('selectFirstContact', () {
      test('空列表 → null', () {
        expect(ReminderScheduler.selectFirstContact([]), isNull);
      });

      test('只有禁用联系人 → null', () {
        final contacts = [makeContact(isActive: false)];
        expect(ReminderScheduler.selectFirstContact(contacts), isNull);
      });

      test('1 个联系人 → 返回该联系人', () {
        final contacts = [makeContact(sortOrder: 0)];
        final result = ReminderScheduler.selectFirstContact(contacts);
        expect(result, isNotNull);
        expect(result!.sortOrder, 0);
      });

      test('多个联系人 → 返回 sortOrder 最小', () {
        final contacts = [
          makeContact(sortOrder: 2),
          makeContact(sortOrder: 0),
          makeContact(sortOrder: 1),
        ];
        final result = ReminderScheduler.selectFirstContact(contacts);
        expect(result, isNotNull);
        expect(result!.sortOrder, 0);
      });

      test('多个联系人 + 禁用 → 跳过禁用返回第一个启用的', () {
        final contacts = [
          makeContact(sortOrder: 0, isActive: false),
          makeContact(sortOrder: 1, isActive: true),
        ];
        final result = ReminderScheduler.selectFirstContact(contacts);
        expect(result, isNotNull);
        expect(result!.sortOrder, 1);
      });
    });

    test('hoursSinceLastCheckIn - 没记录 → -1', () {
      expect(
        ReminderScheduler.hoursSinceLastCheckIn(
          lastCheckIn: null,
          now: now,
        ),
        -1,
      );
    });

    test('hoursSinceLastCheckIn - 24h 前 → 24', () {
      final lastCheckIn = now.subtract(const Duration(hours: 24));
      expect(
        ReminderScheduler.hoursSinceLastCheckIn(
          lastCheckIn: lastCheckIn,
          now: now,
        ),
        24,
      );
    });
  });
}
