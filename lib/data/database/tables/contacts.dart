import 'package:drift/drift.dart';

/// 紧急联系人表
/// 失联通知会按 sortOrder 顺序发送邮件给所有启用联系人
@DataClassName('Contact')
class Contacts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 联系人姓名
  TextColumn get name => text()();

  /// 邮箱地址
  TextColumn get email => text()();

  /// 发送顺序（数字越小越先发）
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 是否启用
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
