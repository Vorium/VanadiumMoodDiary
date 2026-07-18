/// v0.18 round 18 (P1-11) CareCopy 测试
///
/// 覆盖:
/// - forTrigger 4 个 CareTriggerType 都有非空 title + body
/// - none type 返回空字符串
/// - softReminder 跟 secondDayMissed 共享同一份文案
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/shared/care_copy.dart';
import 'package:chroniccare/domain/logic/care_engine.dart';

void main() {
  group('CareCopy.forTrigger', () {
    test('secondDayMissed: 漏 1 天文案', () {
      final copy = CareCopy.forTrigger(CareTriggerType.secondDayMissed);
      expect(copy.title, isNotEmpty);
      expect(copy.body, isNotEmpty);
      expect(copy.title, contains('你还好吗'));
    });

    test('lateCheckInHabit: 晚归文案', () {
      final copy = CareCopy.forTrigger(CareTriggerType.lateCheckInHabit);
      expect(copy.title, contains('早点休息'));
      expect(copy.body, contains('规律作息'));
    });

    test('weekendMissed: 周末漏打卡文案', () {
      final copy = CareCopy.forTrigger(CareTriggerType.weekendMissed);
      expect(copy.title, contains('周末'));
      expect(copy.body, contains('打卡'));
    });

    test('weekPerfect: 连续 7 天准时文案', () {
      final copy = CareCopy.forTrigger(CareTriggerType.weekPerfect);
      expect(copy.title, contains('一整周'));
      expect(copy.body, contains('真棒'));
    });

    test('none: 空字符串', () {
      final copy = CareCopy.forTrigger(CareTriggerType.none);
      expect(copy.title, '');
      expect(copy.body, '');
    });
  });

  group('CareCopy.softReminder', () {
    test('跟 secondDayMissed 共享同一份文案(防双推)', () {
      // v0.18 P1-11 fix: softReminder 跟 CareEngine secondDayMissed
      // 文案必须一致,因为 setup 不再调 scheduleSoftReminder,但旧测试
      // / 未来代码可能还会引到 softReminder 路径,确保文案统一。
      // ignore: deprecated_member_use_from_same_package
      final soft = CareCopy.softReminder();
      final missed = CareCopy.forTrigger(CareTriggerType.secondDayMissed);
      expect(soft.title, missed.title);
      expect(soft.body, missed.body);
    });
  });
}
