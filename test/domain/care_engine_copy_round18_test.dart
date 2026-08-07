/// v0.18 round 18 (P1-11) 关怀文案一致性测试
///
/// R100 迁移: 原验证 CareEngine.evaluate 产出的 CareTrigger.title/body
/// 跟 CareCopy.forTrigger 一致。CareEngine.evaluate legacy API 已删,
/// 改测编排继任者 FireCareStrategyUseCase 的 title/body 跟 CareCopy 一致
/// (防文案改 CareCopy 但漏改 use case 装配)。
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/logic/care_copy.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/logic/care_engine.dart';
import 'package:chroniccare/domain/usecases/fire_care_strategy.dart';

CheckInEntity _checkIn(DateTime t) => CheckInEntity(
      id: 1,
      timestamp: t,
      type: CheckInType.normal,
    );

FireCareStrategyResult _eval(List<CheckInEntity> checkIns, DateTime now) =>
    const FireCareStrategyUseCase()(
      FireCareStrategyInput(checkIns: checkIns, now: now),
    );

void main() {
  group('use case 文案 ↔ CareCopy 一致性', () {
    test('secondDayMissed: 漏 1 天后第二天 10 点后', () {
      // 准备数据: 36h+ 前有 1 个打卡
      final now = DateTime(2026, 7, 18, 11, 0); // 周五 11 点
      final lastCheckIn = now.subtract(const Duration(hours: 40));
      final r = _eval([_checkIn(lastCheckIn)], now);

      expect(r.strategy, CareTriggerType.secondDayMissed);
      final expected = CareCopy.forTrigger(CareTriggerType.secondDayMissed);
      expect(r.title, expected.title);
      expect(r.body, expected.body);
    });

    test('lateCheckInHabit: 最近 3 天 22 点后打卡', () {
      final now = DateTime(2026, 7, 18, 23, 30);
      // 最近 3 天都是 23 点打卡
      final checkIns = [
        _checkIn(DateTime(2026, 7, 18, 23, 0)),
        _checkIn(DateTime(2026, 7, 17, 23, 30)),
        _checkIn(DateTime(2026, 7, 16, 22, 30)),
      ];
      final r = _eval(checkIns, now);

      expect(r.strategy, CareTriggerType.lateCheckInHabit);
      final expected = CareCopy.forTrigger(CareTriggerType.lateCheckInHabit);
      expect(r.title, expected.title);
      expect(r.body, expected.body);
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
      final r = _eval(checkIns, now);

      // 周末 (7/18 周六) 没打卡 → 触发 weekendMissed
      expect(r.strategy, CareTriggerType.weekendMissed);
      final expected = CareCopy.forTrigger(CareTriggerType.weekendMissed);
      expect(r.title, expected.title);
      expect(r.body, expected.body);
    });

    test('weekPerfect: 最近 7 天每天 22 点前都打卡', () {
      final now = DateTime(2026, 7, 18, 10, 0);
      // 7 天前到今天,每天 1 次 22 点前打卡
      final checkIns = [
        for (int i = 0; i < 7; i++) _checkIn(DateTime(2026, 7, 18 - i, 10, 0)),
      ];
      final r = _eval(checkIns, now);

      expect(r.strategy, CareTriggerType.weekPerfect);
      final expected = CareCopy.forTrigger(CareTriggerType.weekPerfect);
      expect(r.title, expected.title);
      expect(r.body, expected.body);
    });

    test('none: 空结果 (打卡列表空)', () {
      final r = _eval([], DateTime(2026, 7, 18, 10, 0));
      expect(r.strategy, CareTriggerType.none);
      expect(r.title, '');
      expect(r.body, '');
    });
  });
}
