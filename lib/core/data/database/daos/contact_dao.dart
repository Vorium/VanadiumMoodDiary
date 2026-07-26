// v0.25 round 53a: ContactDao 抽离

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:drift/drift.dart';

class ContactDao {
  final AppDatabase _db;
  ContactDao(this._db);

  /// 监听所有 active 联系人 (按 sortOrder 升序)
  Stream<List<Contact>> watchActive() {
    return (_db.select(_db.contacts)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
          ]))
        .watch();
  }

  Future<int> insert(ContactsCompanion entry) =>
      _db.into(_db.contacts).insert(entry);

  Future<bool> update(Contact contact) =>
      _db.update(_db.contacts).replace(contact);

  Future<int> delete(int id) =>
      (_db.delete(_db.contacts)..where((t) => t.id.equals(id))).go();
}
