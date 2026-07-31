// v0.27 round 65 (spen 1.2.2 + alibaba 1.2 use case 层补):
// FireCareStrategyUseCase 单元测试
//
// 5 case 覆盖:
// 1. config.enabled=false → disabled (跳过 strategy 评估)
// 2. checkIns 空 → noAction
// 3. 只有 phq9 评估无 normal → noAction (跟 CareEngine 现状 1:1)
// 4. secondDayMissed + lateCheckInHabit 同时命中 → 选 priority 最高的
//    (secondDayMissed=4 > lateCheckInHabit=3)
// 5. config.channel=sms → decision=fireSms (策略命中后切渠道)

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/logic/care_engine.dart';
import 'package:chroniccare/domain/usecases/fire_care_strategy.dart';
import 'package:flutter_test/flutter_test.dart';

CheckInEntity _ck(DateTime t, {CheckInType type = CheckInType.normal}) {
  return CheckInEntity(
    id: t.millisecondsSinceEpoch,
    timestamp: t,
    type: type,
  );
}

void main() {
  group('FireCareStrategyUseCase', () {
    const usecase = FireCareStrategyUseCase();

    test('config.enabled=false → disabled, 不评 strategy', () {
      final r = usecase(
        FireCareStrategyInput(
          checkIns: const [],
          now: DateTime(2026, 7, 15, 10, 0),
          userProfile: null,
          contacts: const [],
          config: const CareChannelConfig(
            enabled: false,
            channel: CareDeliveryChannel.careCopy,
          ),
        ),
      );
      expect(r.decision, FireCareDecision.disabled);
      expect(r.strategy, CareTriggerType.none);
      expect(r.title, '');
      expect(r.body, '');
      expect(r.shouldFire, isFalse);
    });

    test('checkIns 空 → noAction', () {
      final r = usecase(
        FireCareStrategyInput(
          checkIns: const [],
          now: DateTime(2026, 7, 15, 10, 0),
          userProfile: null,
          contacts: const [],
        ),
      );
      expect(r.decision, FireCareDecision.noAction);
      expect(r.strategy, CareTriggerType.none);
      expect(r.shouldFire, isFalse);
    });

    test('只有 phq9 评估,无 normal → noAction (跟 CareEngine 现状 1:1)', () {
      final r = usecase(
        FireCareStrategyInput(
          checkIns: [
            _ck(DateTime(2026, 7, 15, 9, 0), type: CheckInType.phq9),
          ],
          now: DateTime(2026, 7, 15, 10, 0),
          userProfile: null,
          contacts: const [],
        ),
      );
      expect(r.decision, FireCareDecision.noAction);
      expect(r.strategy, CareTriggerType.none);
    });

    test('secondDayMissed + weekendMissed 同命中 → 选 priority 最高 '
        '(secondDayMissed=4)', () {
      // 距 lastCheckIn 36h+ (secondDayMissed TRUE, priority 4)
      // 周六 7/11 没打卡 (weekendMissed TRUE, priority 2)
      // → priority 4 > 2, 选 secondDayMissed
      // 注: 4 strategy 实际互斥 (weekendMissed 跟 weekPerfect 矛盾等),
      // 这里 secondDayMissed 跟 weekendMissed 偶然同命中, 用来验证 priority-best
      final r = usecase(
        FireCareStrategyInput(
          checkIns: [
            _ck(DateTime(2026, 7, 14, 23, 0)),
            _ck(DateTime(2026, 7, 12, 22, 0)), // 周日打卡, 不影响 weekendMissed
          ],
          now: DateTime(2026, 7, 16, 11, 0),
          userProfile: null,
          contacts: const [],
        ),
      );
      expect(r.strategy, CareTriggerType.secondDayMissed);
      expect(r.decision, FireCareDecision.fireCareCopy);
      expect(r.shouldFire, isTrue);
      expect(r.title, isNotEmpty);
      expect(r.body, isNotEmpty);
    });

    test('config.channel=sms → decision=fireSms (命中后切渠道)', () {
      // 命中 lateCheckInHabit (priority 3, 3 个 22 后在 0-2 天内)
      // weekendMissed 不命中 (周末 7/11 + 7/12 都打了)
      // secondDayMissed 不命中 (lastCheckIn 距 now 30min)
      final r = usecase(
        FireCareStrategyInput(
          checkIns: [
            _ck(DateTime(2026, 7, 16, 22, 0)), // 今天 22 点 (距 now 30min)
            _ck(DateTime(2026, 7, 15, 22, 0)),
            _ck(DateTime(2026, 7, 14, 22, 0)),
            _ck(DateTime(2026, 7, 12, 22, 0)), // 周日 22 点, 阻止 weekendMissed
            _ck(DateTime(2026, 7, 11, 22, 0)), // 周六 22 点, 阻止 weekendMissed
          ],
          now: DateTime(2026, 7, 16, 22, 30),
          userProfile: null,
          contacts: const [],
          config: const CareChannelConfig(
            enabled: true,
            channel: CareDeliveryChannel.sms,
          ),
        ),
      );
      expect(r.strategy, CareTriggerType.lateCheckInHabit);
      expect(r.decision, FireCareDecision.fireSms);
      expect(r.shouldFire, isTrue);
    });
  });
}
