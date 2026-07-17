import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/logic/streak_calculator.dart';

void main() {
  group('StreakCalculator', () {
    // 固定测试时间
    final now = DateTime(2026, 7, 11, 20, 0);

    /// 生成 N 天前 20:00 的时间
    DateTime daysAgo(int days) => DateTime(2026, 7, 11 - days, 20, 0);

    CheckInEntity makeCheckIn(DateTime time, {String type = 'normal'}) {
      return CheckInEntity(
        id: time.millisecondsSinceEpoch,
        timestamp: time,
        type: CheckInType.fromWire(type),
        medicationId: null,
        note: null,
      );
    }

    test('空列表 → 0', () {
      expect(StreakCalculator.calculate(checkIns: [], now: now), 0);
    });

    test('只有临时吃药 → 0', () {
      final checkIns = [
        makeCheckIn(now, type: 'temp'),
        makeCheckIn(daysAgo(1), type: 'temp'),
      ];
      expect(StreakCalculator.calculate(checkIns: checkIns, now: now), 0);
    });

    test('今天打卡 → 1', () {
      final checkIns = [makeCheckIn(now)];
      expect(StreakCalculator.calculate(checkIns: checkIns, now: now), 1);
    });

    test('连续 3 天（24h 间隔）→ 3', () {
      final checkIns = [
        makeCheckIn(now),
        makeCheckIn(daysAgo(1)),
        makeCheckIn(daysAgo(2)),
      ];
      expect(StreakCalculator.calculate(checkIns: checkIns, now: now), 3);
    });

    test('连续 7 天 → 7', () {
      final checkIns = List.generate(7, (i) => makeCheckIn(daysAgo(i)));
      expect(StreakCalculator.calculate(checkIns: checkIns, now: now), 7);
    });

    test('今天 + 前天（漏昨天，gap 48h）→ 1（中断）', () {
      final checkIns = [
        makeCheckIn(now),
        makeCheckIn(daysAgo(2)),
      ];
      expect(StreakCalculator.calculate(checkIns: checkIns, now: now), 1);
    });

    test('今天 + 昨天 + 前天（漏 1 天）→ 2', () {
      // 今天 + 昨天 = 2（连续），前天 = 中断
      final checkIns = [
        makeCheckIn(now),
        makeCheckIn(daysAgo(1)),
        makeCheckIn(daysAgo(3)),
      ];
      expect(StreakCalculator.calculate(checkIns: checkIns, now: now), 2);
    });

    test('今天 + 3 天前（gap 72h+）→ 0', () {
      // 最新打卡就超过 36h，streak 算 0
      final checkIns = [
        makeCheckIn(daysAgo(3)),
        makeCheckIn(daysAgo(4)),
        makeCheckIn(daysAgo(5)),
      ];
      expect(StreakCalculator.calculate(checkIns: checkIns, now: now), 0);
    });

    test('同一天多次打卡 → 算 1 天', () {
      final checkIns = [
        makeCheckIn(DateTime(2026, 7, 11, 8, 0)),
        makeCheckIn(DateTime(2026, 7, 11, 12, 0)),
        makeCheckIn(DateTime(2026, 7, 11, 20, 0)),
      ];
      expect(StreakCalculator.calculate(checkIns: checkIns, now: now), 1);
    });

    test('24h 间隔刚好边界 → 连续', () {
      // 昨天 20:00 + 今天 20:00 = 24h gap → 算连续
      final checkIns = [
        makeCheckIn(now),
        makeCheckIn(now.subtract(const Duration(hours: 24))),
      ];
      expect(StreakCalculator.calculate(checkIns: checkIns, now: now), 2);
    });

    test('48h 间隔 → 中断', () {
      // 前天 20:00 + 今天 20:00 = 48h gap → 中断
      final checkIns = [
        makeCheckIn(now),
        makeCheckIn(now.subtract(const Duration(hours: 48))),
      ];
      expect(StreakCalculator.calculate(checkIns: checkIns, now: now), 1);
    });

    group('shouldShowStreakBroken', () {
      test('今天打卡了 → false', () {
        final checkIns = [makeCheckIn(now)];
        expect(
          StreakCalculator.shouldShowStreakBroken(checkIns: checkIns, now: now),
          false,
        );
      });

      test('昨天没打卡（gap 24h+）→ true', () {
        final checkIns = [makeCheckIn(daysAgo(1))];
        expect(
          StreakCalculator.shouldShowStreakBroken(checkIns: checkIns, now: now),
          true,
        );
      });
    });
  });
}
