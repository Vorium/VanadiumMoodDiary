import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// 紧急联系人仓库
class ContactRepository {
  final AppDatabase _db;

  ContactRepository(this._db);

  /// 监听所有启用的联系人（按 sortOrder 排序）
  Stream<List<Contact>> watchAll() => _db.watchContacts();

  /// 添加联系人
  Future<int> add({
    required String name,
    required String phone,
    int sortOrder = 0,
  }) {
    return _db.insertContact(
      ContactsCompanion.insert(
        name: name,
        phone: phone,
        sortOrder: Value(sortOrder),
      ),
    );
  }

  /// 更新
  Future<bool> update(Contact contact) => _db.updateContact(contact);

  /// 删除（软删除）
  Future<int> delete(int id) => _db.deleteContact(id);
}
