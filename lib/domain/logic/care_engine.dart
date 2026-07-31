// AI 关怀提醒引擎（v0.7）
//
// 当前实现：rule-based（基于历史数据的规则触发）
// 长期目标：接入本地 MedGemma 1.5 / Llama 3 做更智能的上下文理解
//
// 触发规则：
// - 持续晚归（连续 3 天 22 点后打卡）→ 主动 push "记得早点休息"
// - 周末漏打卡 → 主动 push "周末也要记得吃药"
// - 漏 1 天后第二天 10 点还没打卡 → 主动 push "你还好吗？"（不是通知家人）
// - 连续 7 天准时 → 庆祝 push "你真棒！"
//
// v0.18 round 18 (P1-11) fix: 文案集中到 domain/logic/care_copy.dart,
// 不再 const string inline。trigger 4 个文案 + 软提醒共用一份 source of truth,
// 避免双推 (setup 软提醒 + CareEngine 立即 push 文案重复)。
//
// v0.23 round 41 (spen P3-34): 抽 4 规则到 care_strategies.dart
// care_engine 自身只负责 evaluate 装配 + fire 推送,策略独立可测可切换

import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/domain/logic/care_copy.dart';
import 'package:chroniccare/domain/logic/care_strategies.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/repositories/notification_sender.dart';

enum CareTriggerType {
  lateCheckInHabit, // 持续晚归
  weekendMissed, // 周末漏打卡
  secondDayMissed, // 漏 1 天后第二天还没打卡
  weekPerfect, // 连续 7 天准时
  none,
}

class CareTrigger {
  final CareTriggerType type;
  final String title;
  final String body;

  const CareTrigger({
    required this.type,
    required this.title,
    required this.body,
  });

  bool get shouldFire => type != CareTriggerType.none;
}

/// 关怀引擎
///
/// 用法：
/// ```dart
/// final trigger = CareEngine.evaluate(checkIns: ..., now: ...);
/// if (trigger.shouldFire) {
///   await notificationService.showNow(trigger.title, trigger.body);
/// }
/// ```
///
/// v0.23 round 41 (spen P3-34): evaluate 拆 4 策略调用 + 1 装配
class CareEngine {
  CareEngine._();

  /// 评估当前状态是否需要关怀
  ///
  /// 业务逻辑(每条独立 strategy, 调 [care_strategies.dart]):
  /// 1. 漏 1 天后第二天 10 点还没打卡 → secondDayMissed
  /// 2. 持续晚归(最近 3 天都在 22 点后) → lateCheckInHabit
  /// 3. 周末漏打卡 → weekendMissed
  /// 4. 最近 7 天每天 22 点前都打卡 → weekPerfect
  static CareTrigger evaluate({
    required List<CheckInEntity> checkIns,
    required DateTime now,
  }) {
    final normal = checkIns.where((c) => c.isNormal).toList();
    if (normal.isEmpty) {
      return const CareTrigger(
        type: CareTriggerType.none,
        title: '',
        body: '',
      );
    }

    // 按时间倒序 (各 strategy 都假设 sortedDesc)
    normal.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // 规则 1: 漏 1 天后第二天 10 点还没打卡
    if (isSecondDayMissed(normal, now)) {
      return _build(CareTriggerType.secondDayMissed);
    }

    // 规则 2: 持续晚归
    if (isLateCheckInHabit(normal, now)) {
      return _build(CareTriggerType.lateCheckInHabit);
    }

    // 规则 3: 周末漏打卡
    if (isWeekendMissed(normal, now)) {
      return _build(CareTriggerType.weekendMissed);
    }

    // 规则 4: 最近 7 天每天 22 点前都打卡
    if (isWeekPerfect(normal, now)) {
      return _build(CareTriggerType.weekPerfect);
    }

    return const CareTrigger(
      type: CareTriggerType.none,
      title: '',
      body: '',
    );
  }

  /// v0.23 round 41: 装配 helper, 4 规则共用一段 copy + trigger 构造
  static CareTrigger _build(CareTriggerType type) {
    final copy = CareCopy.forTrigger(type);
    return CareTrigger(type: type, title: copy.title, body: copy.body);
  }

  /// 触发关怀(实际推送)
  ///
  /// v0.27 round 67 (Sprint 1 上架前 P0, spzh C-P0-6):
  /// PIPL §14 撤回同意 → fire 直接 return, 不推通知。
  /// `isSafetyConsentWithdrawn` 是可选回调, 返 true = 撤回。
  /// 不传 / 返 false = 已同意 (默认行为, 跟 R67 前兼容)。
  ///
  /// caller 注入来源:
  /// - presentation 层 (home_page / setup 软提醒) 调时:
  ///   `(await ref.read(legalConsentStoreProvider).isWithdrawn(ConsentKind.safety))`
  /// - use case (FireCareStrategyUseCase, R65) 调时: 用 config.enabled
  static Future<void> fire(
    CareTrigger trigger,
    NotificationSender notificationService, {
    Future<bool> Function()? isSafetyConsentWithdrawn,
  }) async {
    if (!trigger.shouldFire) return;

    // v0.27 round 67: PIPL §14 撤回 safety 同意 → 不触发
    // 缺省 = 未撤回 (跟 R67 前兼容, 但 R67 后 home_page 应注入)
    if (isSafetyConsentWithdrawn != null && await isSafetyConsentWithdrawn()) {
      return;
    }
    // 关怀通知 id: 8000-8099 段, 避免和 snooze (300000+medId*1440+min) 冲突
    // (v0.23 P0-1 H3 fix: snooze base 4000 → 300000, 远离 medication cancel range)
    final id = 8000 + trigger.type.index;
    try {
      await notificationService.showNow(
        id: id,
        title: trigger.title,
        body: trigger.body,
      );
      swallowError(
        where: 'CareEngine.fire',
        error: '关怀触发: ${trigger.type.name}',
        note: 'success',
      );
    } catch (e, st) {
      swallowError(
        where: 'CareEngine.fire',
        error: e,
        stack: st,
        note: '关怀触发失败',
      );
    }
  }
}
