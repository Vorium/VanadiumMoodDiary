// v0.14 (Round 12A) CheckIn 映射层
//
// Drift row ↔ CheckInEntity 翻译官。
// `type` string → `CheckInType` 枚举在 toEntity 时完成，反向在 toCompanion 时
// 拿到枚举的 `wire` 字面量。

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/core/data/database/app_database.dart';

extension CheckInToEntity on CheckIn {
  /// Drift row → domain entity
  CheckInEntity toEntity() {
    return CheckInEntity(
      id: id,
      timestamp: timestamp,
      type: CheckInType.fromWire(type),
      medicationId: medicationId,
      note: note,
    );
  }
}

extension CheckInEntityToDrift on CheckInEntity {
  /// domain entity → Drift `CheckInsCompanion.insert`
  CheckInsCompanion toCompanion() {
    return CheckInsCompanion.insert(
      timestamp: timestamp,
      type: type.wire,
      medicationId: Value(medicationId),
      note: Value(note),
    );
  }
}
