// v0.14 (Round 12A) ContactRepositoryImpl — data 层 Drift 实现
library;

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/contact/contact_mapper.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/domain/repositories/contact_repository.dart';

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
    required ConsentArtifact consentArtifact,
    int sortOrder = 0,
  }) async {
    // v0.27 round 62 (P0-2 修复): 写 consent audit log (PIPL §13 留痕要求)
    // 留痕字段: kind / grantedAt / grantedBy / version, 不写 contactId
    // (因为 insertContact 还没返 id)。
    piiSafeLog(
      'ContactRepository.add',
      '📝 consent granted: kind=${consentArtifact.kind.name} '
      'grantedAt=${consentArtifact.grantedAt.toIso8601String()} '
      'grantedBy=${consentArtifact.grantedBy} '
      'version=${consentArtifact.version}',
    );
    final id = await _db.insertContact(
      ContactsCompanion.insert(
        name: name,
        phone: phone,
        sortOrder: Value(sortOrder),
      ),
    );
    return id;
  }

  @override
  Future<bool> update(ContactEntity contact) {
    return _db.updateContact(contact.toDriftRow());
  }

  @override
  Future<int> delete(int id) => _db.deleteContact(id);

  @override
  Future<int> restore(ContactEntity contact) {
    // v0.21 Round 23 (P1-26): Dismissible Undo → 重新插入原内容
    // v0.27 round 62 (P0-2): restore 走 audit log, 不走新 consent 流程
    // (用户已经 Undo 一次, consent 历史已留痕)。
    piiSafeLog(
      'ContactRepository.restore',
      '🔄 restore contact id=${contact.id} (consent 历史已留痕, 复用)',
    );
    return _db.insertContact(
      ContactsCompanion.insert(
        name: contact.name,
        phone: contact.phone,
        sortOrder: Value(contact.sortOrder),
      ),
    );
  }
}
