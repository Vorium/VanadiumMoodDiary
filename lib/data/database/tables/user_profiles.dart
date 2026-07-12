import 'package:drift/drift.dart';

/// 用户档案表
/// 全局单条记录（id 永远是 1）
@DataClassName('UserProfile')
class UserProfiles extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  /// 用户姓名（用于邮件中"我是 XXX"）
  TextColumn get userName => text()();

  /// 失联判定周期（小时），默认 48
  IntColumn get checkInCycleHours => integer().withDefault(const Constant(48))();

  /// 首次启动时间
  DateTimeColumn get firstLaunchAt => dateTime()();

  /// 最后打卡时间（冗余字段，方便查询）
  DateTimeColumn get lastCheckInAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
