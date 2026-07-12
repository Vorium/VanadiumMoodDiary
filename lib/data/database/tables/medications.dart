import 'package:drift/drift.dart';

/// 吃药信息表
/// 用户的常吃药信息（药名 + 每日次数 + 时间）
@DataClassName('Medication')
class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 药名（如"舍曲林"）
  TextColumn get name => text()();

  /// 每日次数（1/2/3）
  IntColumn get frequencyPerDay => integer().withDefault(const Constant(1))();

  /// 吃药时间（JSON 数组，如 ["08:00", "20:00"]）
  /// 用 String 存 JSON，方便 v1.0+ 灵活扩展
  TextColumn get timesJson => text().withDefault(const Constant('[]'))();

  /// 起始日期
  DateTimeColumn get startDate => dateTime()();

  /// 终止日期（可选，长期吃的药可空）
  DateTimeColumn get endDate => dateTime().nullable()();

  /// 是否启用（false 表示用户停了这个药）
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
