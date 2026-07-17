import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/logic/streak_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CheckInEntity ci(DateTime t, {String type = 'normal'}) => CheckInEntity(
        id: t.millisecondsSinceEpoch,
        timestamp: t,
        type: CheckInType.fromWire(type),
      );

  group('P1 fix: streak_calculator 36h 边界 (inMinutes vs inHours)', () {
    test('36.5h 前最后一次打卡 → streak = 0 (旧逻辑会误判为非零)', () {
      // 旧逻辑: inHours=36 → 36>36=false → streak 不归 0 → bug
      // 新逻辑: inMinutes=36*60+30 → 36*60*60 >= 36*60*60 → 归 0
      final now = DateTime(2026, 7, 13, 14, 0);
      final lastCheckIn = now.subtract(const Duration(hours: 36, minutes: 30));
      final checks = [ci(lastCheckIn)];
      final streak = StreakCalculator.calculate(checkIns: checks, now: now);
      expect(streak, 0);
    });

    test('35.5h 前最后一次打卡 → streak = 1 (35.5h 内, 连续 1 天)', () {
      final now = DateTime(2026, 7, 13, 14, 0);
      final lastCheckIn = now.subtract(const Duration(hours: 35, minutes: 30));
      final checks = [ci(lastCheckIn)];
      final streak = StreakCalculator.calculate(checkIns: checks, now: now);
      expect(streak, 1);
    });

    test('完全连续 3 天:36h 边界之上仍能算连续 3 天', () {
      final now = DateTime(2026, 7, 13, 12, 0);
      // 10/11/12/13 都打了卡（现在距 13 号 12:00 = 0h）
      // 注意:streak_calculator 依赖 `checkIns.first` 是最新的,
      // 真实数据流 (watchAllCheckIns) 保证倒序。测试要按倒序构造。
      final checks = [
        for (int d = 3; d >= 0; d--) ci(DateTime(2026, 7, 10 + d, 12, 0)),
      ];
      final streak = StreakCalculator.calculate(checkIns: checks, now: now);
      expect(streak, 4);
    });
  });
}
