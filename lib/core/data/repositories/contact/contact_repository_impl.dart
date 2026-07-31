// v0.14 (Round 12A) ContactRepositoryImpl — data 层 Drift 实现

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
    return _db.contactDao
        .watchActive()
        .map((rows) => rows.map((r) => r.toEntity()).toList(growable: false));
  }

  @override
  Future<int> add({
    required String name,
    required String phone,
    required ConsentArtifact consentArtifact,
    int sortOrder = 0,
  }) async {
    // v0.27 round 62 (P0-2 修复) + 63 (DB 落库收尾):
    // 写 consent audit log (PIPL §13 留痕要求, 兼 OS 可删 log 备份)
    // 留痕字段: kind / grantedAt / grantedBy / version, 不写 contactId
    // (因为 insertContact 还没返 id)。
    piiSafeLog(
      'ContactRepository.add',
      '📝 consent granted: kind=${consentArtifact.kind.name} '
          'grantedAt=${consentArtifact.grantedAt.toIso8601String()} '
          'grantedBy=${consentArtifact.grantedBy} '
          'version=${consentArtifact.version}',
    );
    // v0.27 round 63 (P0-2 收尾): 把 4 个 consent 字段写进 DB (R62
    // working tree 只写 log, 落库未做, 这步收尾)。
    // 关键: schemaVersion 15+ (本批 bump) 才有这 4 列, schemaVersion <= 14
    // 老用户走 migration onUpgrade 自动加列 (本批实现)。
    final id = await _db.contactDao.insert(
      ContactsCompanion.insert(
        name: name,
        phone: phone,
        sortOrder: Value(sortOrder),
        consentAt: Value(consentArtifact.grantedAt),
        consentKind: Value(consentArtifact.kind.name),
        consentBy: Value(consentArtifact.grantedBy),
        consentVersion: Value(consentArtifact.version),
      ),
    );
    return id;
  }

  @override
  Future<bool> update(ContactEntity contact) {
    // v0.27 round 63 (P0-2 收尾): update 走 toDriftRow() mapper,
    // 自动包含 4 个 consent 字段 (PIPL §13 留痕完整保留)。
    return _db.contactDao.update(contact.toDriftRow());
  }

  @override
  Future<int> delete(int id) => _db.contactDao.delete(id);

  @override
  Future<int> restore(ContactEntity contact) {
    // v0.21 Round 23 (P1-26): Dismissible Undo → 重新插入原内容
    // v0.27 round 62 (P0-2): restore 走 audit log, 不走新 consent 流程
    // (用户已经 Undo 一次, consent 历史已留痕)。
    // v0.27 round 63 (P0-2 收尾): 从 contact entity 复用 4 个 consent
    // 字段 (原 contact 是 schemaVersion 15+ 写入的, consent 信息完整)。
    piiSafeLog(
      'ContactRepository.restore',
      '🔄 restore contact id=${contact.id} (consent 历史已留痕, 复用)',
    );
    return _db.contactDao.insert(
      ContactsCompanion.insert(
        name: contact.name,
        phone: contact.phone,
        sortOrder: Value(contact.sortOrder),
        // 4 个 consent 字段从 contact entity 复用, 因为它是上次
        // schemaVersion 15+ 写入的, 必有值
        consentAt: Value(contact.consentAt),
        consentKind: Value(contact.consentKind?.name),
        consentBy: Value(contact.consentBy),
        consentVersion: Value(contact.consentVersion),
      ),
    );
  }
}
