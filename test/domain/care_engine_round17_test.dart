// v0.17 round 5 (B5): CareEngine 4 个核心规则 + fire 的边界 case
//
// 重点覆盖：
// - fire() trigger.shouldFire = false 时不调 notificationService
// - _isWeekendMissed 周六 18 点之前不该误报
// - _isLateCheckInHabit "22 点后" 跨午夜边界
// - _isWeekPerfect 7 天窗口之外的旧数据不污染判断
// - evaluate 排序在传入未排序数据时不出错
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/logic/care_engine.dart';
import 'package:chroniccare/domain/repositories/notification_sender.dart';
import 'package:flutter_test/flutter_test.dart';

CheckInEntity _checkIn(DateTime time, {String type = 'normal'}) =>
    CheckInEntity(
      id: time.millisecondsSinceEpoch,
      timestamp: time,
      type: CheckInType.fromWire(type),
      medicationId: null,
      note: null,
    );

void main() {
  // 固定"现在" = 2026-07-17 (周五) 14:00
  final now = DateTime(2026, 7, 17, 14, 0);

  group('CareEngine fire() (v0.17 round 5)', () {
    test('trigger.shouldFire = false → 不调 notificationService.showNow',
        () async {
      final fake = FakeNotificationSender();
      final trigger = const CareTrigger(
        type: CareTriggerType.none,
        title: '',
        body: '',
      );
      await CareEngine.fire(trigger, fake);
      expect(fake.showedNow, isFalse);
      expect(fake.showNowId, isNull);
    });

    test('trigger.shouldFire = true → 调 showNow + 标题+body+id', () async {
      final fake = FakeNotificationSender();
      final trigger = const CareTrigger(
        type: CareTriggerType.lateCheckInHabit,
        title: '记得早点休息',
        body: '你最近都晚睡',
      );
      await CareEngine.fire(trigger, fake);
      expect(fake.showedNow, isTrue);
      // id = 4000 + type.index
      expect(fake.showNowId, 4000 + CareTriggerType.lateCheckInHabit.index);
      expect(fake.showNowTitle, '记得早点休息');
      expect(fake.showNowBody, '你最近都晚睡');
    });

    test('showNow 抛异常 → 不崩 (try/catch 包了)', () async {
      final fake = _FailingNotificationSender();
      final trigger = const CareTrigger(
        type: CareTriggerType.weekPerfect,
        title: '真棒',
        body: '保持下去',
      );
      // 不应抛
      await CareEngine.fire(trigger, fake);
    });
  });

  group('CareEngine 边界 case', () {
    test('空 checkIns 列表 → none', () {
      final t = CareEngine.evaluate(checkIns: [], now: now);
      expect(t.type, CareTriggerType.none);
    });

    test('传入未排序数据也能正确取最近一条 (P2 隐式 sort 修复)', () {
      // 故意打乱顺序: 1 个 37h 前 (触发 secondDayMissed),其他 2 天前/3 天前
      // 排序前 .first 拿到 3 天前 → 错算 (修前 bug)
      // 排序后 .first 拿到 37h 前 → 正确触发 secondDayMissed
      final checkIns = [
        _checkIn(now.subtract(const Duration(days: 3))),
        _checkIn(now.subtract(const Duration(days: 2))),
        _checkIn(now.subtract(const Duration(hours: 37))),
      ];
      final t = CareEngine.evaluate(checkIns: checkIns, now: now);
      // 37h 前 + now.hour=14 >= 10 → secondDayMissed
      expect(t.type, CareTriggerType.secondDayMissed);
    });

    test('_isWeekendMissed: 周六 17:59 不应触发 (now.hour < 18)', () {
      // 周六 17:59,周末前半天
      final saturday = DateTime(2026, 7, 18, 17, 59);
      // 之前一周有打卡,但周六 18 点前没打卡 → 不应触发
      final checkIns = [
        _checkIn(saturday.subtract(const Duration(days: 1, hours: 12))),
        _checkIn(saturday.subtract(const Duration(days: 2, hours: 8))),
      ];
      final t = CareEngine.evaluate(checkIns: checkIns, now: saturday);
      expect(t.type, isNot(CareTriggerType.weekendMissed));
    });

    test('_isWeekendMissed: 周六 18:01 应触发', () {
      final saturdayEvening = DateTime(2026, 7, 18, 18, 1);
      // 周六 18:01: 之前 12h 周五 06:01 打卡 (22h 前,在 36h 内,不触发 secondDayMissed)
      // 周六 18:01 还没打卡 + hour >= 18 → 触发 weekendMissed
      final checkIns = [
        _checkIn(saturdayEvening.subtract(const Duration(hours: 12))),
      ];
      final t = CareEngine.evaluate(checkIns: checkIns, now: saturdayEvening);
      expect(t.type, CareTriggerType.weekendMissed);
    });

    test('_isWeekPerfect: 7 天前有 22 点后打卡,但最近 7 天 22 点前 → weekPerfect',
        () {
      // 8 天前 23 点打卡 (P3 fix 应该忽略)
      final longAgo = now.subtract(const Duration(days: 8, hours: -23 + 8));
      // 最近 7 天每天 21 点打卡
      final checkIns = <CheckInEntity>[
        _checkIn(longAgo), // 8 天前 23 点 → 被忽略
        for (int i = 0; i < 7; i++)
          _checkIn(DateTime(2026, 7, 17 - i, 21, 0)),
      ];
      final t = CareEngine.evaluate(checkIns: checkIns, now: now);
      expect(t.type, CareTriggerType.weekPerfect);
    });

    test('_isLateCheckInHabit: 22:00 整点打卡算 "22 点后"', () {
      // 最近 3 天都是 22:00 打卡
      final checkIns = [
        _checkIn(DateTime(2026, 7, 17, 22, 0)),
        _checkIn(DateTime(2026, 7, 16, 23, 30)),
        _checkIn(DateTime(2026, 7, 15, 22, 30)),
      ];
      final t = CareEngine.evaluate(checkIns: checkIns, now: now);
      expect(t.type, CareTriggerType.lateCheckInHabit);
    });

    test('secondDayMissed: 36h 内 (< 36) → 不触发', () {
      // 35.9 小时前打卡
      final t = CareEngine.evaluate(
        checkIns: [_checkIn(now.subtract(const Duration(hours: 35)))],
        now: now,
      );
      expect(t.type, isNot(CareTriggerType.secondDayMissed));
    });

    test('secondDayMissed: 36h 后 + now.hour >= 10 → 触发', () {
      // 36.5h 前打卡,现在 14:00
      final t = CareEngine.evaluate(
        checkIns: [_checkIn(now.subtract(const Duration(hours: 37)))],
        now: now,
      );
      expect(t.type, CareTriggerType.secondDayMissed);
    });

    test('secondDayMissed: 36h 后但 now.hour < 10 (早上 8 点) → 不触发',
        () {
      // 36h 前打卡,现在 8:00
      final morningNow = DateTime(2026, 7, 17, 8, 0);
      final t = CareEngine.evaluate(
        checkIns: [_checkIn(morningNow.subtract(const Duration(hours: 37)))],
        now: morningNow,
      );
      expect(t.type, isNot(CareTriggerType.secondDayMissed));
    });
  });
}

/// 每次调 showNow 必抛异常的 sender
class _FailingNotificationSender implements NotificationSender {
  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    throw StateError('intentional failure');
  }
}

/// Fake sender: 记录最近一次 showNow 调用
class FakeNotificationSender implements NotificationSender {
  bool showedNow = false;
  int? showNowId;
  String? showNowTitle;
  String? showNowBody;
  String? showNowPayload;

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    showedNow = true;
    showNowId = id;
    showNowTitle = title;
    showNowBody = body;
    showNowPayload = payload;
  }
}
