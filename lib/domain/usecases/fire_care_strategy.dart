// v0.27 round 65 (spen 1.2.2 + alibaba 1.2 use case 层补):
// 抽 FireCareStrategyUseCase (CareEngine 4 strategy 业务编排)
//
// 之前 CareEngine.evaluate 在 lib/domain/logic/care_engine.dart:68-109 直接
// 做 4 strategy first-match-wins 编排 + 装配 CareTrigger, 业务编排跟 logic
// 混在一起, presentation 直接调 CareEngine 静态方法拿 CareTrigger。
//
// 本 use case 把"选哪个 strategy + 触发什么 delivery channel" 提到 domain 层
// 纯函数, presentation 调它决定"该不该触发 + 用什么方式", 然后再调
// notification service (fire) / sms / email (不在 use case 职责内)。
//
// 0 副作用: 不调 service, 不发通知, 不写 DB。
// 0 Flutter 依赖: 只用 domain entity + 已有 logic (care_strategies / care_copy)。

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/logic/care_copy.dart';
import 'package:chroniccare/domain/logic/care_engine.dart';
import 'package:chroniccare/domain/logic/care_strategies.dart';

/// 关怀投递渠道 (CareCopy 通知 / SMS / Email)
///
/// v1.0+ 准备扩展: 当前 default = careCopy (推本地通知), sms / email 占位
/// 待 R55+ 接入真实 SMS 跟邮件发送后, config 切换渠道即可走 use case 这条路
/// 实际发出去。
enum CareDeliveryChannel {
  /// 推本地通知 (CareCopy 文案) — 当前 default
  careCopy,

  /// 发 SMS 给紧急联系人 — v1.0+ 接入阿里云后
  sms,

  /// 发邮件给紧急联系人 — v1.0+ 接入 SendGrid 后
  email,
}

/// 关怀渠道配置 (FireCareStrategyInput 用)
///
/// v0.27 round 65: 之前 4 strategy 全是 fireCareCopy, 没必要传 config。
/// 抽 use case 时给个 config 让 v1.0+ 切 SMS / Email 走同一套路径, 不用再改
/// use case call site。
class CareChannelConfig {
  /// 是否启用关怀引擎
  final bool enabled;

  /// 命中 strategy 后用什么渠道投递
  final CareDeliveryChannel channel;

  const CareChannelConfig({
    required this.enabled,
    required this.channel,
  });

  /// Default: 启用 + 通知 (跟 CareEngine 现状 1:1)
  static const defaultConfig = CareChannelConfig(
    enabled: true,
    channel: CareDeliveryChannel.careCopy,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareChannelConfig &&
          other.enabled == enabled &&
          other.channel == channel;

  @override
  int get hashCode => Object.hash(enabled, channel);

  @override
  String toString() => 'CareChannelConfig(enabled=$enabled, channel=$channel)';
}

/// 关怀决策 (FireCareStrategyUseCase.call 返)
///
/// 5 值枚举:
/// - disabled:    关怀功能关闭
/// - fireCareCopy: 命中 strategy, 推本地通知 (CareCopy 文案)
/// - fireSms:     命中 strategy, 发 SMS
/// - fireEmail:   命中 strategy, 发邮件
/// - noAction:    4 strategy 全 false / 无 normal check-in
enum FireCareDecision {
  disabled,
  fireCareCopy,
  fireSms,
  fireEmail,
  noAction,
}

/// Use case 返值
///
/// 含 decision (5 选 1) + 命中的 strategy (无命中 = none) + 文案 (decision =
/// disabled / noAction 时空)。presentation 拿到这个后:
/// - decision == disabled / noAction: 跳过
/// - decision == fireCareCopy: 调 notification_service.showNow(title, body)
/// - decision == fireSms / fireEmail: v1.0+ 调 sms / email service
class FireCareStrategyResult {
  final FireCareDecision decision;
  final CareTriggerType strategy;
  final String title;
  final String body;

  const FireCareStrategyResult({
    required this.decision,
    required this.strategy,
    required this.title,
    required this.body,
  });

  /// 是否要 trigger 后续 action (fireCareCopy / fireSms / fireEmail)
  bool get shouldFire =>
      decision == FireCareDecision.fireCareCopy ||
      decision == FireCareDecision.fireSms ||
      decision == FireCareDecision.fireEmail;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FireCareStrategyResult &&
          other.decision == decision &&
          other.strategy == strategy &&
          other.title == title &&
          other.body == body;

  @override
  int get hashCode => Object.hash(decision, strategy, title, body);

  @override
  String toString() =>
      'FireCareStrategyResult(decision=$decision, strategy=$strategy, title="$title")';
}

/// Use case 输入
///
/// caller 注入 checkIns (从 CheckInRepository 拿) + now (DateTime.now()) +
/// userProfile / contacts (从 SafetyWatchService 已有 inputs 复用) + config
/// (渠道配置, 默认 careCopy)。
class FireCareStrategyInput {
  final List<CheckInEntity> checkIns;
  final DateTime now;
  final UserProfileEntity? userProfile;
  final List<ContactEntity> contacts;
  final CareChannelConfig config;

  const FireCareStrategyInput({
    required this.checkIns,
    required this.now,
    this.userProfile,
    this.contacts = const [],
    this.config = CareChannelConfig.defaultConfig,
  });
}

/// 抽 FireCareStrategy 业务编排
///
/// v0.27 round 65: presentation (home_page / setup_page) 之前直接调
/// CareEngine.evaluate(...) 拿 CareTrigger, 业务编排跟 UI 混在一起。
/// 本 use case 让 presentation 只调 1 个 use case, 内部 4 strategy 评分 +
/// 选 highest-priority + 装配 delivery channel decision。
///
/// 业务规则:
/// 1. config.enabled == false → disabled
/// 2. checkIns 无 normal (全评估 / 临时) → noAction (跟 CareEngine 现状 1:1)
/// 3. 4 strategy 评分: 命中 = 1, 不命中 = 0
/// 4. 选 priority 最高 (secondDayMissed 4 > lateCheckInHabit 3 > weekendMissed 2
///    > weekPerfect 1), 互斥 4 strategy 实际不冲突, first-match-wins 等价
///    priority-best
/// 5. 命中 strategy → 按 config.channel 决定 fireCareCopy / fireSms / fireEmail
/// 6. 4 strategy 全不命中 → noAction
///
/// 0 副作用: 不调 service, 不发通知, 不写 DB。caller 拿 result 自行 fire。
class FireCareStrategyUseCase {
  const FireCareStrategyUseCase();

  /// 4 strategy 评分 (priority, 数值越大越优先)
  ///
  /// 跟 care_strategies.dart 4 个 top-level function 1:1 对应,
  /// 数值即隐式优先级 — secondDayMissed (4) > lateCheckInHabit (3) >
  /// weekendMissed (2) > weekPerfect (1)
  static const _priorities = <CareTriggerType, int>{
    CareTriggerType.secondDayMissed: 4,
    CareTriggerType.lateCheckInHabit: 3,
    CareTriggerType.weekendMissed: 2,
    CareTriggerType.weekPerfect: 1,
  };

  FireCareStrategyResult call(FireCareStrategyInput input) {
    // 1. 关闭
    if (!input.config.enabled) {
      return const FireCareStrategyResult(
        decision: FireCareDecision.disabled,
        strategy: CareTriggerType.none,
        title: '',
        body: '',
      );
    }

    // 2. 过滤 normal check-ins (跟 CareEngine.evaluate 1:1)
    final normal = input.checkIns.where((c) => c.isNormal).toList();
    if (normal.isEmpty) {
      return const FireCareStrategyResult(
        decision: FireCareDecision.noAction,
        strategy: CareTriggerType.none,
        title: '',
        body: '',
      );
    }

    // 排序 (R19B 隐式排序防御: 各 strategy 假设 sortedDesc)
    normal.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 3. 评 4 strategy
    final hits = <CareTriggerType, bool>{
      CareTriggerType.secondDayMissed: isSecondDayMissed(normal, input.now),
      CareTriggerType.lateCheckInHabit: isLateCheckInHabit(normal, input.now),
      CareTriggerType.weekendMissed: isWeekendMissed(normal, input.now),
      CareTriggerType.weekPerfect: isWeekPerfect(normal, input.now),
    };

    // 4. 选 priority 最高 (互斥场景下等价 first-match-wins)
    CareTriggerType? best;
    var bestPriority = -1;
    for (final entry in hits.entries) {
      if (!entry.value) continue;
      final p = _priorities[entry.key] ?? 0;
      if (p > bestPriority) {
        best = entry.key;
        bestPriority = p;
      }
    }

    if (best == null) {
      return const FireCareStrategyResult(
        decision: FireCareDecision.noAction,
        strategy: CareTriggerType.none,
        title: '',
        body: '',
      );
    }

    // 5. 按 channel 决定 delivery decision
    final decision = switch (input.config.channel) {
      CareDeliveryChannel.careCopy => FireCareDecision.fireCareCopy,
      CareDeliveryChannel.sms => FireCareDecision.fireSms,
      CareDeliveryChannel.email => FireCareDecision.fireEmail,
    };

    // 6. 文案 (从 CareCopy 拿, 跟 CareEngine._build 1:1)
    final copy = CareCopy.forTrigger(best);
    return FireCareStrategyResult(
      decision: decision,
      strategy: best,
      title: copy.title,
      body: copy.body,
    );
  }
}
