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

    // v0.16 round 19 regression: 之前依赖 caller 传已排序数据(Round 13 round 3 加 care_engine sort 之前的状态)
    // 现在 calculate + shouldShowStreakBroken 内部都 sort,unsorted 也得算对
    group('unsorted input（v0.16 round 19 fix）', () {
      test('calculate 接受 ASC 排序的输入,结果跟 DESC 一致', () {
        // 故意 ASC（旧 bug 状态：caller 传 unsorted 数据会算错）
        final checkIns = [
          makeCheckIn(daysAgo(2)),
          makeCheckIn(daysAgo(1)),
          makeCheckIn(now),
        ];
        // 重排：toReversed 不改变 list,我们这里直接传 ASC
        final result = StreakCalculator.calculate(checkIns: checkIns, now: now);
        expect(result, 3, reason: 'ASC 输入也应正确算出 3 天 streak');
      });

      test('calculate 接受乱序输入也能正确算', () {
        // 故意乱序：[昨天, 今天, 前天]
        final checkIns = [
          makeCheckIn(daysAgo(1)),
          makeCheckIn(now),
          makeCheckIn(daysAgo(2)),
        ];
        final result = StreakCalculator.calculate(checkIns: checkIns, now: now);
        expect(result, 3);
      });

      test('shouldShowStreakBroken 接受乱序输入也能正确判断', () {
        // 故意 [前天, 今天] 乱序
        final checkIns = [
          makeCheckIn(daysAgo(2)),
          makeCheckIn(now),
        ];
        expect(
          StreakCalculator.shouldShowStreakBroken(checkIns: checkIns, now: now),
          false,
          reason: '今天有打卡,即使是乱序输入也该返回 false',
        );
      });
    });
  });
}
