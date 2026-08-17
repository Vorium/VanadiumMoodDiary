// v1.1.0+172 R126 (R110 feature-first 阶段 2) — stress_event 子表
// (R125 阶段 1 anxiety_agitation 样板, R126 阶段 2 step 1 扩第 2 子表)
//
// 拆解动机 (R110 阶段 2):
// - R125 阶段 1 闭环 anxiety_agitation 1 子表 5 file 端到端, 验证 design 可行
// - R126 阶段 2 step 1: 同一 feature (daily_tracking) 第 2 子表 stress_event
//   5 file 端到端, 跟 R125 同模式
// - R126 阶段 2 step 2-5: 4 feature 完整迁移 (mood / vent / assessment /
//   medication) + daily_tracking 其他 4 子表 (sleep / weight / social_rhythm
//   / treatment) — 1-2 周真实工作, R126 续 / R127 阶段 3 拆 workspace 时一并
// - 旧路径 re-export 兼容 (跟 R125 模式一致)
//
// 跟 R125 anxiety_agitation 略不同:
// - 5 字段 (vs anxiety 4 字段)
// - 含 linkedMoodEntryId 弱 FK (R60 drift 不强制外键模式)
// - 0 跨 service 依赖 (跟 anxiety 一样)

import 'package:drift/drift.dart';

/// 生活事件/应激源表 (R126 阶段 2 step 1 迁移)
@DataClassName('StressEvent')
class StressEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get eventType => text()();
  IntColumn get intensity => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get linkedMoodEntryId => integer().nullable()();
}
