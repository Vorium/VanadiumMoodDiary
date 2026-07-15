import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/logic/care_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CheckInEntity ci(DateTime t, {String type = 'normal'}) =>
      CheckInEntity(
        id: t.millisecondsSinceEpoch,
        timestamp: t,
        type: CheckInType.fromWire(type),
      );

  group('CareEngine 第三轮审查 fix', () {
    test('P2 fix: 36.5h 触发 secondDayMissed (inMinutes 不用 inHours)', () {
      // 旧逻辑: inHours=36 → 36>36=false → 不触发
      // 新逻辑: inMinutes=36*60+30 → 触发
      final now = DateTime(2026, 7, 13, 10, 0);
      final lastCheckIn = now.subtract(const Duration(hours: 36, minutes: 30));
      final t = CareEngine.evaluate(
        checkIns: [ci(lastCheckIn)],
        now: now,
      );
      expect(t.type, CareTriggerType.secondDayMissed);
    });

    test('P2 fix: 35.5h 不触发 secondDayMissed', () {
      // 35.5h = 2130min < 36*60=2160min → secondDayMissed 不触发
      // 注意:不只检查 secondDayMissed,任何 trigger 都不该是 secondDayMissed
      // 这里只放 1 条 check-in,可能 weekendMissed/weekPerfect 也触发,
      // 所以我们用 has check-in 覆盖最近几天,排除其他 trigger
      final now = DateTime(2026, 7, 13, 10, 0);
      final lastCheckIn = now.subtract(const Duration(hours: 35, minutes: 30));
      // 加多个 check-in 覆盖最近 7 天,排除 weekPerfect/weekendMissed 触发
      // 35.5h 前 = 7-11 22:30 (Sat)。需要 7-6 到 7-13 都有打卡
      final checks = <CheckInEntity>[
        ci(lastCheckIn), // 7-11 22:30
        for (int d = 0; d < 7; d++)
          ci(DateTime(2026, 7, 6 + d, 8, 0)), // 7-6..7-12 各 8 点
      ];
      final t = CareEngine.evaluate(checkIns: checks, now: now);
      // 关键断言:不是 secondDayMissed
      expect(t.type, isNot(CareTriggerType.secondDayMissed));
    });

    test('P3 fix: 1 年前 1 次晚打卡,最近 7 天都 21 点准时 → 触发 weekPerfect', () {
      final now = DateTime(2026, 7, 13, 10, 0);
      final checks = <CheckInEntity>[
        // 1 年前晚打卡(应被忽略)
        ci(DateTime(2025, 7, 13, 23, 0)),
        // 最近 7 天都 21 点准时
        for (int d = 0; d < 7; d++)
          ci(DateTime(2026, 7, 7 + d, 21, 0)),
      ];
      final t = CareEngine.evaluate(checkIns: checks, now: now);
      expect(t.type, CareTriggerType.weekPerfect);
    });

    test('P3 fix: 最近 7 天内 1 次晚打卡 → 不触发 weekPerfect', () {
      final now = DateTime(2026, 7, 13, 10, 0);
      final checks = <CheckInEntity>[
        for (int d = 0; d < 6; d++)
          ci(DateTime(2026, 7, 7 + d, 21, 0)),
        ci(DateTime(2026, 7, 13, 23, 0)), // 今天 23 点晚打卡
      ];
      final t = CareEngine.evaluate(checkIns: checks, now: now);
      expect(t.type, CareTriggerType.none);
    });

    test('P7 fix: 周六 20 点还没打卡 → 触发 weekendMissed', () {
      // 周六 20 点,32h 内有最近打卡(周五) → 不触发 secondDayMissed
      // i=0 周六 7-11 没打卡,hour=20>=18 → return true
      final now = DateTime(2026, 7, 11, 20, 0);
      final checks = [ci(DateTime(2026, 7, 10, 12, 0))];
      final t = CareEngine.evaluate(checkIns: checks, now: now);
      expect(t.type, CareTriggerType.weekendMissed);
    });

    test('P7 fix: 周六 10 点,前一个周日打了卡 → 不触发 (今天没过 18 点)', () {
      // 关键:必须有 36h 内的最近打卡,否则 secondDayMissed 先触发
      // 周五 7-10 22:00 → 7-11 10:00 = 12h(在 36h 内)
      // 上周日 7-5 12:00 也打了
      final now = DateTime(2026, 7, 11, 10, 0);
      final checks = [
        ci(DateTime(2026, 7, 10, 22, 0)), // 周五 22:00(在 36h 内)
        ci(DateTime(2026, 7, 5, 12, 0)), // 上周日
      ];
      final t = CareEngine.evaluate(checkIns: checks, now: now);
      expect(t.type, CareTriggerType.none);
    });

    test('P7 fix: 周六 20 点,前一个周日打了卡 → 优先 secondDayMissed (36h+ 远间隔)', () {
      // 验证:secondDayMissed 比 weekendMissed 优先
      final now = DateTime(2026, 7, 11, 20, 0);
      final checks = [ci(DateTime(2026, 7, 5, 12, 0))];
      final t = CareEngine.evaluate(checkIns: checks, now: now);
      expect(t.type, CareTriggerType.secondDayMissed);
    });

    test('P7 fix: 周六 20 点,周日 7-5 没打卡(只周五 7-10) → weekendMissed', () {
      // 同上,32h 内 → secondDayMissed 不触发 → 走到 weekendMissed
      // 周六 7-11 hour=20>=18,no check → return true
      final now = DateTime(2026, 7, 11, 20, 0);
      final checks = [ci(DateTime(2026, 7, 10, 12, 0))];
      final t = CareEngine.evaluate(checkIns: checks, now: now);
      expect(t.type, CareTriggerType.weekendMissed);
    });
  });
}
