// CareEngine rule-based 触发测试
// 验证四种触发规则 + none
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/logic/care_engine.dart';

CheckInEntity _ci(DateTime t) => CheckInEntity(
      id: t.millisecondsSinceEpoch,
      timestamp: t,
      type: CheckInType.normal,
      note: null,
      medicationId: null,
    );

void main() {
  final now = DateTime(2026, 7, 15, 14, 0); // 周三 14:00

  group('CareEngine.evaluate', () {
    test('空列表 → none', () {
      final t = CareEngine.evaluate(checkIns: [], now: now);
      expect(t.type, CareTriggerType.none);
    });

    test('漏 1 天后 14 点还没打卡 → secondDayMissed', () {
      // 2 天前 9 点打过卡
      final checkIns =
          [now.subtract(const Duration(hours: 53))].map(_ci).toList();
      final t = CareEngine.evaluate(checkIns: checkIns, now: now);
      expect(t.type, CareTriggerType.secondDayMissed);
    });

    test('最近 3 天都在 22 点后打卡 → lateCheckInHabit', () {
      final checkIns = [
        now.subtract(const Duration(days: 1)).copyWith(hour: 23),
        now.subtract(const Duration(days: 2)).copyWith(hour: 22, minute: 30),
        now.subtract(const Duration(days: 3)).copyWith(hour: 23),
      ].map(_ci).toList();
      final t = CareEngine.evaluate(checkIns: checkIns, now: now);
      expect(t.type, CareTriggerType.lateCheckInHabit);
    });

    test('最近 7 天每天 22 点前都打卡 → weekPerfect', () {
      // 构造最近 7 天每天 20 点的打卡
      final checkIns = [
        for (int i = 0; i < 7; i++)
          now.subtract(Duration(days: i, hours: now.hour - 20)),
      ].map(_ci).toList();
      final t = CareEngine.evaluate(checkIns: checkIns, now: now);
      expect(t.type, CareTriggerType.weekPerfect);
    });

    test('type!=normal 不参与评估', () {
      // 漏 1 天的 type=temp，不应触发 secondDayMissed
      final checkIns = [
        CheckInEntity(
          id: 1,
          timestamp: now.subtract(const Duration(hours: 50)),
          type: CheckInType.temp,
          note: 'temp',
          medicationId: null,
        ),
      ];
      final t = CareEngine.evaluate(checkIns: checkIns, now: now);
      expect(t.type, CareTriggerType.none);
    });
  });

  group('shouldFire', () {
    test('none → false', () {
      final t = const CareTrigger(
        type: CareTriggerType.none,
        title: '',
        body: '',
      );
      expect(t.shouldFire, isFalse);
    });

    test('其他类型 → true', () {
      final t = CareEngine.evaluate(
        checkIns: [now.subtract(const Duration(hours: 53))].map(_ci).toList(),
        now: now,
      );
      expect(t.shouldFire, isTrue);
    });
  });
}
