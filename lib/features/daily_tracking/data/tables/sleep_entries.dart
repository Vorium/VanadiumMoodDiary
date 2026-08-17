// v1.1.0+173 R126 (R110 feature-first 阶段 2 step 2) — sleep 子表
// (R125 anxiety + R126 step 1 stress_event 样板, R126 step 2 扩第 3 子表)
//
// 拆解动机 (R110 阶段 2):
// - R125 + R126 step 1: anxiety_agitation + stress_event 2 子表 5 file 端到端
// - R126 step 2: 扩第 3 子表 sleep (6 字段含 regularityScore 1-5 跨日评分)
// - R126 step 3-5: daily_tracking 3 子表 (weight / social_rhythm / treatment) +
//   4 feature 完整迁移 (mood / vent / assessment / medication) — 1-1.5 周
// - 旧路径 re-export 兼容 (跟 R125/R126 step 1 模式一致)
//
// 跟 R126 step 1 stress_event 不同:
// - 6 字段 (vs stress 5 字段)
// - 含 regularityScore (1-5, nullable, 算法在 SleepCalculator.regularityScore)
// - 含 durationMin 自动算 (跨午夜, 单位分钟, 跟 SleepCalculator 配合)
// - 0 跨 service 依赖 (跟 anxiety / stress 一样, R97 P1-1 重构后)

import 'package:drift/drift.dart';

/// 睡眠记录表 (R126 阶段 2 step 2 迁移)
@DataClassName('SleepEntry')
class SleepEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get bedtime => dateTime()();
  DateTimeColumn get wakeTime => dateTime()();
  IntColumn get durationMin => integer()();
  IntColumn get regularityScore => integer().nullable()();
  TextColumn get note => text().nullable()();
}
