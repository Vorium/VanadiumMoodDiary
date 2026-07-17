import 'package:drift/drift.dart';

/// 吃药信息表
/// v0.6：删 frequencyPerDay，加 dosage + dosageUnit；timesJson 含义改为
///       存 `List<TimeOfDay>` 序列化的 JSON，例如 `[{"h":8,"m":0},{"h":20,"m":0}]`
@DataClassName('Medication')
class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 药名（如"氟西汀"）
  TextColumn get name => text()();

  /// 剂量数值（如 40）
  RealColumn get dosage => real()();

  /// 剂量单位（"mg" 或 "片"）
  TextColumn get dosageUnit => text()();

  /// 吃药时间列表（JSON 数组：[{h:8,m:0},{h:20,m:0}]）
  /// 用 String 存 JSON，方便灵活扩展
  TextColumn get timesJson => text().withDefault(const Constant('[]'))();

  /// 起始日期
  DateTimeColumn get startDate => dateTime()();

  /// 终止日期（可选，长期吃的药可空）
  DateTimeColumn get endDate => dateTime().nullable()();

  /// 是否启用（false 表示用户停了这个药）
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// v0.12 (Round 6) 续方提醒字段

  /// 续方日期 = 用户预计这个药用完的那一天
  /// 为 null = 没设过续方提醒
  DateTimeColumn get refillAt => dateTime().nullable()();

  /// 提前多少天提醒（默认 7 天）
  IntColumn get refillReminderDays =>
      integer().withDefault(const Constant(7))();
}
