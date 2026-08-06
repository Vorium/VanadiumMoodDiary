import 'package:drift/drift.dart';

/// 焦虑急躁水平快速评估表
///
/// v0.30 round 91 (sub-spec 7 日常追踪): 1 个时间点 = 1 条
/// (跟 mood_entries.anxiety 解耦, 独立"快速评估"用)
/// - timestamp: 评估时间
/// - anxietyScore: 1-5 (1=严重 5=平静)
/// - agitationScore: 1-5 (1=平静 5=极度急躁)
/// - note: 自由备注
@DataClassName('AnxietyAgitationEntry')
class AnxietyAgitationEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get anxietyScore => integer()();
  IntColumn get agitationScore => integer()();
  TextColumn get note => text().nullable()();
}
