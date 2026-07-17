import 'package:drift/drift.dart';

/// 紧急联系人表
/// 失联通知按 sortOrder 顺序发送给所有启用联系人
/// v0.6：删 email 字段，改用 phone（中国大陆手机号 11 位）
@DataClassName('Contact')
class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 联系人姓名
  TextColumn get name => text()();

  /// 手机号（中国大陆 11 位，可选 +86 前缀）
  TextColumn get phone => text()();

  /// 发送顺序（数字越小越先发）
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 是否启用
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
