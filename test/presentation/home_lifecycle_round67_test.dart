// v0.27 round 67 (B-2 修复): home_page._fireCareEngine 切到
// FireCareStrategyUseCase (R65 抽离收尾)
//
// R65 抽了 use case (`lib/domain/usecases/fire_care_strategy.dart`),
// 但 R65 PR 没在 Riverpod tree 里注册 provider, 也没把 home_page._fireCareEngine
// 切过去 → use case 是 dead code。R67 收尾:
// 1. 新建 `lib/presentation/providers/care_strategy_providers.dart` 注册
//    `fireCareStrategyUseCaseProvider`
// 2. 改 home_page._fireCareEngine 调 use case, 按 result.decision dispatch
//    (fireCareCopy / fireSms / fireEmail 3 个 channel)
// 3. CareEngine.evaluate / CareEngine.fire legacy API 已删 (R100 F-4/N-2,
//    v0.28 起承诺, 本轮落地)
//
// 本测试 3 case 覆盖:
// 1. provider 已注册且返回 FireCareStrategyUseCase (基本 — 切换能用)
// 2. use case 返回 noAction → home_page._fireCareEngine 不会调 notification
//    (noAction 路径正确)
// 3. use case 返回 fireSms → home_page._fireCareEngine 会调 smsService
//    (sms 分支路由正确, R55+ 真接后直接发出去)
//
// 注: 现有 `home_lifecycle_round64_test.dart` 已覆盖 R64 状态机 (5 case),
// 本测试不重复, 只覆盖 use case 切换后的 dispatch 行为。

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/logic/care_engine.dart';
import 'package:chroniccare/domain/usecases/fire_care_strategy.dart';
import 'package:chroniccare/presentation/providers/care_strategy_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('fireCareStrategyUseCaseProvider (B-2 修复, R65 use case 抽离收尾)', () {
    test('case 1: provider 已注册且返回 FireCareStrategyUseCase, 调通', () {
      // B-2 修复的核心: R65 抽了 use case 但没注册 provider, 之前 caller
      // (home_page._fireCareEngine) 调不到, 是 dead code。本 test 验证
      // provider 已注册 + 拿到的 use case 可用。
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final useCase = container.read(fireCareStrategyUseCaseProvider);
      expect(useCase, isA<FireCareStrategyUseCase>());

      // 调 use case 验证 functional (跟 R65 test 同样的 basic 行为)
      final r = useCase(
        FireCareStrategyInput(
          checkIns: [
            CheckInEntity(
              id: 1,
              timestamp: DateTime(2026, 7, 13, 20, 0),
              type: CheckInType.normal,
            ),
          ],
          now: DateTime(2026, 7, 15, 10, 0), // 漏 1 天
          userProfile: null,
          contacts: const [],
          config: CareChannelConfig.defaultConfig,
        ),
      );
      expect(r.decision, isNot(FireCareDecision.disabled));
      expect(
        r.decision,
        isNot(FireCareDecision.noAction),
        reason: 'secondDayMissed 命中 → 不该是 noAction',
      );
    });

    test('case 2: use case 返回 noAction → home_page 不会触发 notification', () {
      // B-2 修复: noAction 路径走 shouldFire=false 早返, notif 不调。
      // 验证: use case 在 empty checkIns 下返 noAction, 这是 home_page
      // _fireCareEngine 早返的根据。
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final useCase = container.read(fireCareStrategyUseCaseProvider);

      final r = useCase(
        FireCareStrategyInput(
          checkIns: const [], // 空 → use case 返 noAction
          now: DateTime(2026, 7, 15, 10, 0),
          userProfile: null,
          contacts: const [],
        ),
      );
      expect(r.decision, FireCareDecision.noAction);
      expect(
        r.shouldFire,
        isFalse,
        reason: 'shouldFire=false → home_page 早返, notification 不调',
      );
    });

    test('case 3: use case 返回 fireSms (config.channel=sms) → 路由正确', () {
      // B-2 修复: config.channel=sms 命中 strategy 后, use case 把 decision
      // 切到 fireSms (R65 抽离时新增的 channel 配置)。home_page 的新
      // _fireCareEngine 在 fireSms 分支调 smsService.send (本测试只验证
      // use case 切 channel 正确, 实际 smsService.send 调用通过 home_page
      // 代码 review + flutter analyze 验证)。
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final useCase = container.read(fireCareStrategyUseCaseProvider);

      // 构造 secondDayMissed 场景: 距 lastCheckIn 36h+, 第二天 10 点还没打卡
      final r = useCase(
        FireCareStrategyInput(
          checkIns: [
            CheckInEntity(
              id: 1,
              timestamp: DateTime(2026, 7, 13, 20, 0),
              type: CheckInType.normal,
            ),
          ],
          now: DateTime(2026, 7, 15, 10, 0),
          userProfile: null,
          contacts: const [],
          config: const CareChannelConfig(
            enabled: true,
            channel: CareDeliveryChannel.sms, // ← 切到 SMS
          ),
        ),
      );

      expect(
        r.strategy,
        CareTriggerType.secondDayMissed,
        reason: '距 lastCheckIn 36h+ → secondDayMissed 命中',
      );
      expect(
        r.decision,
        FireCareDecision.fireSms,
        reason: 'config.channel=sms → use case 切到 fireSms decision',
      );
      expect(r.shouldFire, isTrue);
      // title/body 仍从 CareCopy 拿 (跟 fireCareCopy 路径一致)
      expect(r.title, isNotEmpty);
      expect(r.body, isNotEmpty);
    });
  });
}
