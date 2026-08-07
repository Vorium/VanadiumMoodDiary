// AI 关怀提醒引擎 — 触发类型定义（v0.7 起, R100 收敛）
//
// 当前实现：rule-based（基于历史数据的规则触发）
// 长期目标：接入本地 MedGemma 1.5 / Llama 3 做更智能的上下文理解
//
// 触发规则：
// - 持续晚归（连续 3 天 22 点后打卡）→ 主动 push (care_copy lateCheckInHabit 文案)
// - 周末漏打卡 → 主动 push (care_copy weekendMissed 文案)
// - 漏 1 天后第二天 10 点还没打卡 → 主动 push (care_copy secondDayMissed 文案, 不是通知家人)
// - 连续 7 天准时 → 庆祝 push (care_copy weekPerfect 文案, R72 spzh P0-4 中性化)
// 实际文案看 `lib/domain/logic/care_copy.dart` (R18 P1-11 集中, R72 中性化, R77 R76-N7 续改 3 处)
//
// v0.23 round 41 (spen P3-34): 抽 4 规则到 care_strategies.dart
// v0.27 round 65 (R65): 业务编排抽到 usecases/fire_care_strategy.dart
// (FireCareStrategyUseCase), presentation 只调 use case。
//
// R100 (F-4/N-2): 删 CareEngine.evaluate / fire legacy 静态 API —
// v0.28 起承诺删除 (docs/LEGACY_API_NOTES.md), 生产 0 调用方。
// 4 规则判定看 care_strategies.dart, 编排看 FireCareStrategyUseCase,
// 推送分发看 home_page_state._fireCareEngine (id = 8000 + strategy.index)。
// 本文件只剩 CareTriggerType 枚举 (care_copy / use case / strategies 共用)。

/// 关怀触发类型 (4 规则 + none)
enum CareTriggerType {
  lateCheckInHabit, // 持续晚归
  weekendMissed, // 周末漏打卡
  secondDayMissed, // 漏 1 天后第二天还没打卡
  weekPerfect, // 连续 7 天准时
  none,
}
