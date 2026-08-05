import 'package:drift/drift.dart';

/// 生活事件/应激源 表
///
/// v0.30 round 91 (sub-spec 7 日常追踪): 1 次事件 = 1 条
/// - timestamp: 事件发生时间
/// - eventType: 'work' / 'relationship' / 'health' / 'financial' / 'other'
///   (R60 模式: TextColumn 自由, 不开 enum 列, 应用层校验)
/// - intensity: 1-5 (1=轻微 5=极重)
/// - note: 自由描述
/// - linkedMoodEntryId: 弱 FK mood_entries.id (nullable)
///   R60 drift 不强制外键, 应用层维护
@DataClassName('StressEvent')
class StressEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get timestamp => dateTime()();
  TextColumn get eventType => text()();
  IntColumn get intensity => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get linkedMoodEntryId => integer().nullable()();
}
