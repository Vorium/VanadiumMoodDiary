// v0.18 round 18 (P1-11) 关怀文案集中
//
// 之前 CareEngine 4 个 trigger 的 title/body 是 const string inline 在
// care_engine.dart 内。soft reminder (notification_service.scheduleSoftReminder)
// 也用相似文案"🌿 你还好吗?" — 实际双推 bug:用户每天 10 点会收到 2 条。
//
// 修:
// 1. 文案集中到 care_copy.dart (4 个 trigger + soft reminder 共用)
// 2. setup_page 不再调 scheduleSoftReminder — CareEngine 接管
// 3. notification_service.scheduleSoftReminder 标 @Deprecated 但保留
//    (未来 soft reminder 跟 CareEngine 合并时彻底删)
//
// shared/ 位置:domain 业务文案 + data notification 推送都要用,
// 不能只放 domain。放 core/shared/ 是 shared umbrella 的 utility。
library;

import 'package:chroniccare/domain/logic/care_engine.dart';

/// 关怀文案集中（CareEngine + 软提醒共用）
class CareCopy {
  CareCopy._();

  /// 按 trigger type 取文案
  ///
  /// 注意:返回 (title, body) pair,Call site 自己拼 push 文本。
  static ({String title, String body}) forTrigger(CareTriggerType type) {
    switch (type) {
      case CareTriggerType.lateCheckInHabit:
        return (
          title: '🛏️ 记得早点休息',
          body: '你这几天都 22 点后才打卡——规律作息对药效有影响',
        );
      case CareTriggerType.weekendMissed:
        return (
          title: '☀️ 周末也要记得',
          body: '周末容易忘记——现在打卡，让家人放心',
        );
      case CareTriggerType.secondDayMissed:
        return (
          title: '🌿 你还好吗？',
          body: '少 1 次没关系——但记得吃药哦',
        );
      case CareTriggerType.weekPerfect:
        return (
          title: '🌟 一整周都准时！',
          body: '你真棒——保持下去',
        );
      case CareTriggerType.none:
        return (title: '', body: '');
    }
  }

  /// 软提醒文案(setup 阶段兜底,跟 secondDayMissed 共用)
  ///
  /// v0.18 (P1-11): 跟 CareEngine.secondDayMissed 共享同一份文案。
  /// setup 不再调 scheduleSoftReminder(已删),此方法目前仅供
  /// notification_service scheduleSoftReminder @Deprecated 路径使用。
  @Deprecated('v0.18 P1-11: CareEngine 接管,setup_page 不再 scheduleSoftReminder')
  static ({String title, String body}) softReminder() => forTrigger(
        CareTriggerType.secondDayMissed,
      );
}
