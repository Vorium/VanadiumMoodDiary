// v1.1.0+174 R126 (R110 feature-first 阶段 2 step 3) — social_rhythm 子表
// (R125 + R126 step 1+2 样板, R126 收官 3 子表之 2/3)

import 'package:drift/drift.dart';

/// 社会节律表 (R126 阶段 2 step 3 迁移, 收官子表 2/3)
@DataClassName('SocialRhythmEntry')
class SocialRhythmEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get wakeTime => dateTime()();
  DateTimeColumn get firstMealTime => dateTime()();
  DateTimeColumn get lastMealTime => dateTime()();
  IntColumn get socialMin => integer().withDefault(const Constant(0))();
  IntColumn get workMin => integer().withDefault(const Constant(0))();
  IntColumn get exerciseMin => integer().withDefault(const Constant(0))();
}
