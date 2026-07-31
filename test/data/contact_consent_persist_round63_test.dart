// v0.27 round 63 (P0-2 修复续): PIPL §13 DB 落库验证
//
// 背景: R62 修过 API 层 (ConsentArtifact + ConsentDialog + ConsentMissingError)
// + piiSafeLog 留痕, 但**留痕只 log, 没写表** — spzh 视角 P0-2 标记为
// "半修"。R63 收尾: 加 4 个 consent 字段 (consentAt / consentKind /
// consentBy / consentVersion) 到 contacts 表, schemaVersion 14 → 15,
// ContactRepositoryImpl.add/restore 把 consent 写进 ContactsCompanion。
//
// 本测试验证 5 个关键场景:
// 1. ContactEntity 4 consent 字段 nullable (默认值 null)
// 2. ContactMapper drift → entity 4 字段直传
// 3. ContactMapper entity → drift 4 字段直传
// 4. ContactRepositoryImpl.add() 写 4 字段到 DB (内存 DB round-trip)
// 5. ContactRepositoryImpl.restore() 从 entity 复用 4 字段
//
// 老数据 (schemaVersion <= 14) 兼容性: drift 升级到 15 时 4 字段
// 自动 addColumn nullable, 老 row 4 字段 = null (R63 onUpgrade 实现)。

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/contact/contact_mapper.dart';
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/core/data/repositories/contact/contact_repository_impl.dart';

void main() {
  group('v0.27 round 63 (P0-2) — ContactEntity 4 consent 字段 nullable', () {
    test('ContactEntity 不传 consent 4 字段 → 全 null (老数据兼容)', () {
      const entity = ContactEntity(id: 1, name: '张三', phone: '13800138000');
      expect(entity.consentAt, isNull);
      expect(entity.consentKind, isNull);
      expect(entity.consentBy, isNull);
      expect(entity.consentVersion, isNull);
    });

    test('ContactEntity 传 consent 4 字段 → 字段正确', () {
      final grantedAt = DateTime(2026, 7, 31, 12, 0, 0);
      final entity = ContactEntity(
        id: 1,
        name: '张三',
        phone: '13800138000',
        consentAt: grantedAt,
        consentKind: ConsentKind.emergencyContactSharing,
        consentBy: 'user',
        consentVersion: 'v1',
      );
      expect(entity.consentAt, grantedAt);
      expect(entity.consentKind, ConsentKind.emergencyContactSharing);
      expect(entity.consentBy, 'user');
      expect(entity.consentVersion, 'v1');
    });
  });

  group('v0.27 round 63 (P0-2) — ContactMapper round-trip 4 consent 字段', () {
    test('drift row → entity 4 consent 字段直传', () {
      final grantedAt = DateTime(2026, 7, 31, 12, 0, 0);
      final row = Contact(
        id: 1,
        name: '张三',
        phone: '13800138000',
        sortOrder: 0,
        isActive: true,
        consentAt: grantedAt,
        consentKind: 'emergencyContactSharing',
        consentBy: 'user',
        consentVersion: 'v1',
      );
      final entity = row.toEntity();
      expect(entity.consentAt, grantedAt);
      expect(entity.consentKind, ConsentKind.emergencyContactSharing);
      expect(entity.consentBy, 'user');
      expect(entity.consentVersion, 'v1');
    });

    test('entity → drift row 4 consent 字段直传', () {
      final grantedAt = DateTime(2026, 7, 31, 12, 0, 0);
      const entity = ContactEntity(
        id: 1,
        name: '张三',
        phone: '13800138000',
        consentAt: null, // 占位
        consentKind: ConsentKind.dataExport,
        consentBy: 'user',
        consentVersion: 'v1',
      );
      // 用 nullable field 重新构造
      final e = entity.copyWith(consentAt: grantedAt);
      final row = e.toDriftRow();
      expect(row.consentAt, grantedAt);
      expect(row.consentKind, 'dataExport');
      expect(row.consentBy, 'user');
      expect(row.consentVersion, 'v1');
    });
  });

  group('v0.27 round 63 (P0-2) — ContactRepositoryImpl.add 写 4 字段', () {
    late AppDatabase db;
    late ContactRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = ContactRepositoryImpl(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('add() 写 4 consent 字段到 DB (round-trip 验证)', () async {
      final grantedAt = DateTime(2026, 7, 31, 12, 0, 0);
      final consent = ConsentArtifact(
        kind: ConsentKind.emergencyContactSharing,
        grantedAt: grantedAt,
        grantedBy: 'user',
        version: 'v1',
      );
      final id = await repo.add(
        name: '张三',
        phone: '13800138000',
        consentArtifact: consent,
      );
      expect(id, greaterThan(0));

      // 重新读
      final row = await (db.select(db.contacts)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(row.consentAt, grantedAt);
      expect(row.consentKind, 'emergencyContactSharing');
      expect(row.consentBy, 'user');
      expect(row.consentVersion, 'v1');
    });

    test('add() 5 个 ConsentKind 全部 round-trip 成功', () async {
      for (final kind in ConsentKind.values) {
        final consent = ConsentArtifact(
          kind: kind,
          grantedAt: DateTime(2026, 7, 31),
          grantedBy: 'user',
          version: 'v1',
        );
        final id = await repo.add(
          name: 'contact_${kind.name}',
          phone: '13800138000',
          consentArtifact: consent,
        );
        final row = await (db.select(db.contacts)..where((t) => t.id.equals(id)))
            .getSingle();
        expect(row.consentKind, kind.name, reason: 'kind=${kind.name}');
      }
    });
  });

  group('v0.27 round 63 (P0-2) — ContactRepositoryImpl.restore 复用 4 字段', () {
    late AppDatabase db;
    late ContactRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = ContactRepositoryImpl(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('restore() 从 entity 复用 4 consent 字段', () async {
      final grantedAt = DateTime(2026, 7, 31, 12, 0, 0);
      // 1. 先 add 一个 contact
      final consent = ConsentArtifact(
        kind: ConsentKind.emergencyContactSharing,
        grantedAt: grantedAt,
        grantedBy: 'user',
        version: 'v1',
      );
      final originalId = await repo.add(
        name: '李四',
        phone: '13800138001',
        consentArtifact: consent,
      );
      final original = await (db.select(db.contacts)
            ..where((t) => t.id.equals(originalId)))
          .getSingle();
      final originalEntity = original.toEntity();

      // 2. delete 它
      await repo.delete(originalId);

      // 3. restore (Dismissible Undo 流程)
      final restoredId = await repo.restore(originalEntity);
      expect(restoredId, isNot(originalId)); // 新 id

      // 4. 验证 consent 4 字段被复用
      final restored = await (db.select(db.contacts)
            ..where((t) => t.id.equals(restoredId)))
          .getSingle();
      expect(restored.consentAt, grantedAt);
      expect(restored.consentKind, 'emergencyContactSharing');
      expect(restored.consentBy, 'user');
      expect(restored.consentVersion, 'v1');
    });
  });
}