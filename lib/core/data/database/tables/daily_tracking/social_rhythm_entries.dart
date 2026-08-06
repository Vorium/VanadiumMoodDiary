import 'package:drift/drift.dart';

/// 社会节律表 (Social Rhythm Metric, SRM 简化版)
///
/// v0.30 round 91 (sub-spec 7 日常追踪): 1 天 1 条
/// - date: 记录当天
/// - wakeTime: 起床时间
/// - firstMealTime: 第一餐时间
/// - lastMealTime: 最后一餐时间
/// - socialMin: 社交时长 (分钟), 默认 0
/// - workMin: 工作时长 (分钟), 默认 0
/// - exerciseMin: 运动时长 (分钟), 默认 0
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
