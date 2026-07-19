/// v0.18 round 18 (P1-11) CareEngine 抽 CareCopy 一致性测试
///
/// 验证:CareEngine.evaluate 4 个 trigger 产出的 CareTrigger.title/body
/// 跟 CareCopy.forTrigger 保持一致(防文案改 CareCopy 但漏改 CareEngine)。
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/logic/care_copy.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/logic/care_engine.dart';

CheckInEntity _checkIn(DateTime t) => CheckInEntity(
      id: 1,
      timestamp: t,
      type: CheckInType.normal,
    );

void main() {
  group('CareEngine 文案 ↔ CareCopy 一致性', () {
    test('secondDayMissed: 漏 1 天后第二天 10 点后', () {
      // 准备数据: 36h+ 前有 1 个打卡
      final now = DateTime(2026, 7, 18, 11, 0); // 周五 11 点
      final lastCheckIn = now.subtract(const Duration(hours: 40));
      final trigger = CareEngine.evaluate(
        checkIns: [_checkIn(lastCheckIn)],
        now: now,
      );

      expect(trigger.type, CareTriggerType.secondDayMissed);
      final expected = CareCopy.forTrigger(CareTriggerType.secondDayMissed);
      expect(trigger.title, expected.title);
      expect(trigger.body, expected.body);
    });

    test('lateCheckInHabit: 最近 3 天 22 点后打卡', () {
      final now = DateTime(2026, 7, 18, 23, 30);
      // 最近 3 天都是 23 点打卡
      final checkIns = [
        _checkIn(DateTime(2026, 7, 18, 23, 0)),
        _checkIn(DateTime(2026, 7, 17, 23, 30)),
        _checkIn(DateTime(2026, 7, 16, 22, 30)),
      ];
      final trigger = CareEngine.evaluate(
        checkIns: checkIns,
        now: now,
      );

      expect(trigger.type, CareTriggerType.lateCheckInHabit);
      final expected = CareCopy.forTrigger(CareTriggerType.lateCheckInHabit);
      expect(trigger.title, expected.title);
      expect(trigger.body, expected.body);
    });

    test('weekendMissed: 周末漏打卡', () {
      // 假设今天是周日 19 点,今天有打卡(避免 secondDayMissed 优先级)
      // 但周六没打卡 → 触发 weekendMissed
      // 7月19日是周日,7月18日是周六
      final now = DateTime(2026, 7, 19, 19, 0);
      // 今天早上打过卡 (10h 前,minutesSince < 36h,secondDayMissed 不触发)
      final checkIns = [
        _checkIn(DateTime(2026, 7, 19, 9, 0)),
      ];
      final trigger = CareEngine.evaluate(
        checkIns: checkIns,
        now: now,
      );

      // 周末 (7/18 周六) 没打卡 → 触发 weekendMissed
      expect(trigger.type, CareTriggerType.weekendMissed);
      final expected = CareCopy.forTrigger(CareTriggerType.weekendMissed);
      expect(trigger.title, expected.title);
      expect(trigger.body, expected.body);
    });

    test('weekPerfect: 最近 7 天每天 22 点前都打卡', () {
      final now = DateTime(2026, 7, 18, 10, 0);
      // 7 天前到今天,每天 1 次 22 点前打卡
      final checkIns = [
        for (int i = 0; i < 7; i++)
          _checkIn(DateTime(2026, 7, 18 - i, 10, 0)),
      ];
      final trigger = CareEngine.evaluate(
        checkIns: checkIns,
        now: now,
      );

      expect(trigger.type, CareTriggerType.weekPerfect);
      final expected = CareCopy.forTrigger(CareTriggerType.weekPerfect);
      expect(trigger.title, expected.title);
      expect(trigger.body, expected.body);
    });

    test('none: 空 trigger (打卡列表空)', () {
      final trigger = CareEngine.evaluate(
        checkIns: [],
        now: DateTime(2026, 7, 18, 10, 0),
      );
      expect(trigger.type, CareTriggerType.none);
      expect(trigger.title, '');
      expect(trigger.body, '');
    });
  });
}
