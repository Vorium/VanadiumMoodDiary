// v0.14 (Round 12A) Contact 映射层
//
// Drift row ↔ ContactEntity 翻译官。
//
// v0.27 round 63 (P0-2 修复): 4 个 consent 字段 (PIPL §13 留痕) 同步
// - consentKind: drift row 存 String (enum.name), entity 用 ConsentKind? nullable
// - 其他 3 字段直接映射
// - 老数据 (schemaVersion <= 14) 4 字段全 null
// - v1.0+ 加新 ConsentKind 值时, 旧数据若存了不识别的 name, 走 null (宽容)

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/core/data/database/app_database.dart';

extension ContactToEntity on Contact {
  /// Drift row → domain entity
  ContactEntity toEntity() {
    return ContactEntity(
      id: id,
      name: name,
      phone: phone,
      sortOrder: sortOrder,
      isActive: isActive,
      consentAt: consentAt,
      consentKind: _kindFromString(consentKind),
      consentBy: consentBy,
      consentVersion: consentVersion,
    );
  }
}

extension ContactEntityToDrift on ContactEntity {
  /// domain entity → Drift `ContactsCompanion.insert`
  ContactsCompanion toCompanion() {
    return ContactsCompanion.insert(
      name: name,
      phone: phone,
      sortOrder: Value(sortOrder),
      isActive: Value(isActive),
      consentAt: Value(consentAt),
      consentKind: Value(consentKind?.name),
      consentBy: Value(consentBy),
      consentVersion: Value(consentVersion),
    );
  }

  /// domain entity → Drift row（用于 update 等需要完整 row 的方法）
  Contact toDriftRow() {
    return Contact(
      id: id,
      name: name,
      phone: phone,
      sortOrder: sortOrder,
      isActive: isActive,
      consentAt: consentAt,
      consentKind: consentKind?.name,
      consentBy: consentBy,
      consentVersion: consentVersion,
    );
  }
}

/// Drift row String (enum.name) → ConsentKind?
///
/// 老数据 (schemaVersion <= 14) consentKind 字段是 null (DB 缺这列),
/// 走 null (entity 4 字段全 null)。
/// v1.0+ 加新 ConsentKind 值时, 旧数据若存了不识别的 name, 走 null (宽容),
/// audit log 即可 — 不要 crash。
ConsentKind? _kindFromString(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  for (final kind in ConsentKind.values) {
    if (kind.name == raw) return kind;
  }
  return null;
}
