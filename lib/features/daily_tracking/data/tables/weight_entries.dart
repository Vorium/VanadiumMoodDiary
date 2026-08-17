// v1.1.0+174 R126 (R110 feature-first 阶段 2 step 3) — weight 子表
// (R125 anxiety + R126 step 1 stress + R126 step 2 sleep 样板, R126 收官 3 子表之一)
//
// 拆解动机: 跟 R125/R126 step 1+2 同模式, daily_tracking 6 子表 收官 100%
// (anxiety_agitation + stress_event + sleep + weight + social_rhythm + treatment)。
//
// 跟 R126 step 2 sleep 不同:
// - 4 字段 (vs sleep 6 字段)
// - 含 BmiCalculator (BmiCalculator.compute, 实际 impl 不依赖, dartdoc 提)
// - 0 跨 service 依赖

import 'package:drift/drift.dart';

/// 体重记录表 (R126 阶段 2 step 3 迁移, 收官子表 1/3)
@DataClassName('WeightEntry')
class WeightEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  RealColumn get weightKg => real()();
  RealColumn get bmi => real().nullable()();
  TextColumn get note => text().nullable()();
}
