import 'package:drift/drift.dart';

/// 睡眠记录表
///
/// v0.30 round 91 (sub-spec 7 日常追踪): 1 天 1 条 (跨午夜 bedtime 算 1 天)
/// - date: 入睡当天 (calendar day)
/// - bedtime: 入睡时间
/// - wakeTime: 起床时间
/// - durationMin: 自动算 (wakeTime - bedtime, 跨午夜, 单位分钟)
/// - regularityScore: 1-5 (nullable, 1=最不规律 5=最规律; null = 未评分)
///   算法在 [SleepCalculator.regularityScore] (7 天 bedtime 标准差)
/// - note: 自由备注
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
