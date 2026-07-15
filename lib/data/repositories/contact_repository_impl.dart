// v0.14 (Round 12A) ContactRepositoryImpl — data 层 Drift 实现
library;

import 'package:drift/drift.dart' show Value;

import '../../domain/entities/contact_entity.dart';
import '../../domain/repositories/contact_repository.dart';
import '../database/app_database.dart';
import '../database/contact_mapper.dart';

/// Contact 仓库的 Drift 实现
class ContactRepositoryImpl implements ContactRepository {
  final AppDatabase _db;

  ContactRepositoryImpl(this._db);

  @override
  Stream<List<ContactEntity>> watchAll() {
    return _db
        .watchContacts()
        .map((rows) => rows.map((r) => r.toEntity()).toList(growable: false));
  }

  @override
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

  @override
  Future<bool> update(ContactEntity contact) {
    return _db.updateContact(contact.toDriftRow());
  }

  @override
  Future<int> delete(int id) => _db.deleteContact(id);
}
