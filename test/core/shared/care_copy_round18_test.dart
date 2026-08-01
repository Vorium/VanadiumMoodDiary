/// v0.18 round 18 (P1-11) CareCopy 测试
///
/// 覆盖:
/// - forTrigger 4 个 CareTriggerType 都有非空 title + body
/// - none type 返回空字符串
/// - softReminder 跟 secondDayMissed 共享同一份文案
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/domain/logic/care_copy.dart';
import 'package:chroniccare/domain/logic/care_engine.dart';

void main() {
  group('CareCopy.forTrigger', () {
    test('secondDayMissed: 漏 1 天文案', () {
      final copy = CareCopy.forTrigger(CareTriggerType.secondDayMissed);
      expect(copy.title, isNotEmpty);
      expect(copy.body, isNotEmpty);
      // v0.27 R77 (R76-N7 续): '你还好吗' 改 '后续保持就好' (中性, 不催促)
      expect(copy.title, contains('后续保持就好'));
    });

    test('lateCheckInHabit: 晚归文案', () {
      final copy = CareCopy.forTrigger(CareTriggerType.lateCheckInHabit);
      // v0.27 R77 (R76-N7 续): '记得早点休息' 改 '提早一点更稳定' (中性, 不指责)
      expect(copy.title, contains('提早一点更稳定'));
      expect(copy.body, contains('规律作息'));
    });

    test('weekendMissed: 周末漏打卡文案', () {
      final copy = CareCopy.forTrigger(CareTriggerType.weekendMissed);
      expect(copy.title, contains('周末'));
      expect(copy.body, contains('打卡'));
      // v0.27 R77 (R76-N7 续): '容易忘记' 改 '容易错过' (中性, 不责怪)
      expect(copy.body, contains('容易错过'));
    });

    test('weekPerfect: 连续 7 天准时文案', () {
      final copy = CareCopy.forTrigger(CareTriggerType.weekPerfect);
      expect(copy.title, contains('一整周'));
      // v0.27 R72 (spzh R66 P0-4 续): 中性化, 不含 '真棒' 褒语
      expect(copy.body, contains('今周已全部准时'));
    });

    test('none: 空字符串', () {
      final copy = CareCopy.forTrigger(CareTriggerType.none);
      expect(copy.title, '');
      expect(copy.body, '');
    });
  });

  group('CareCopy.softReminder', () {
    // v0.18 (P2-P0-5): softReminder() 整段删除 (死代码,0 caller)
    // secondDayMissed 文案一致性改为 forTrigger() 单点测试覆盖
    test('secondDayMissed 文案存在且稳定', () {
      final missed = CareCopy.forTrigger(CareTriggerType.secondDayMissed);
      expect(missed.title, isNotEmpty);
      expect(missed.body, isNotEmpty);
    });
  });
}
