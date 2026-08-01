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
// P1 fix: 从 core/shared/ 移入 domain/logic/（仅 domain 层使用，不满足 shared 2+ 层规则）

import 'package:chroniccare/domain/logic/care_engine.dart';

/// 关怀文案集中（CareEngine + 软提醒共用）
class CareCopy {
  CareCopy._();

  /// 按 trigger type 取文案
  ///
  /// 注意：返回 (title, body) pair,Call site 自己拼 push 文本。
  ///
  /// v0.27 round 77 (R76-N7 修): 3 处轻度督促 / 责怪 / 催促中性化
  /// (R72 R66 P0-4 续, R72 漏扫 ARB 鼓励 / care_copy 这块):
  /// - L29: "你这几天都" 隐含指责 → 改"21 点后打卡比例偏高"
  /// - L36: "容易忘记" 责怪语气 → 改"周末容易错过" (中性)
  /// - L41: "但记得吃药哦" 软催促 → 改"后续保持就好" (中性)
  static ({String title, String body}) forTrigger(CareTriggerType type) {
    switch (type) {
      case CareTriggerType.lateCheckInHabit:
        return (
          title: '🛏️ 提早一点更稳定',
          body: '21 点后打卡比例偏高 — 规律作息对药效有影响',
        );
      case CareTriggerType.weekendMissed:
        return (
          title: '☀️ 周末保持节律',
          // v0.27 R72 (spzh R66 P0-4 续): 中性化, 不提 '家人' (避免病耻感)
          // 原: '周末容易忘记——现在打卡，让家人放心'
          // v0.27 R77 (R76-N7 续): '容易忘记' 改 '容易错过' (中性, 不责怪)
          body: '周末容易错过——现在打卡，多一点坚持',
        );
      case CareTriggerType.secondDayMissed:
        return (
          title: '🌿 后续保持就好',
          // v0.27 R77 (R76-N7 续): '但记得吃药哦' 软催促 → 删
          body: '少 1 次没关系——后续保持就好',
        );
      case CareTriggerType.weekPerfect:
        return (
          title: '🌟 一整周都准时！',
          // v0.27 R72 (spzh R66 P0-4 续): 中性化, 仅事实描述 (避免 '你真棒' 褒语)
          // 原: '你真棒——保持下去'
          body: '今周已全部准时',
        );
      case CareTriggerType.none:
        return (title: '', body: '');
    }
  }
}
