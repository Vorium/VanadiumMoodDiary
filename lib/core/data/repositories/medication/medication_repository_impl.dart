// v0.13 (Round 11) MedicationRepositoryImpl — Drift 实现
//
// 这是 4 层架构中 "data" 层的实现：
// - 实现 `domain/repositories/medication_repository.dart` 的 abstract
// - 通过 `data/database/medication_mapper.dart` 在 Drift row 和
//   `MedicationEntity` 之间翻译
// - UI 永远只看到 entity，不直接看到 Drift
//
// v0.16 (Round 19): `times` 参数从 `List<TimeOfDay>` 改为 `List<HourMinute>`，
// 消除 data → flutter/material 依赖。

import 'package:chroniccare/domain/entities/medication_draft.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/repositories/medication_repository.dart';
import 'package:chroniccare/core/shared/date_time_resolver.dart';
import 'package:chroniccare/core/shared/domain_value.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/medication/medication_mapper.dart';

/// MedicationRepository 的 Drift 实现
class MedicationRepositoryImpl implements MedicationRepository {
  final AppDatabase _db;

  MedicationRepositoryImpl(this._db);

  @override
  Stream<List<MedicationEntity>> watchAll() {
    return _db.medicationDao.watchActive().map(
          (rows) => rows.map((r) => r.toEntity()).toList(growable: false),
        );
  }

  @override
  Stream<List<MedicationEntity>> watchAllIncludingInactive() {
    return _db.medicationDao.watchAllIncludingInactive().map(
          (rows) => rows.map((r) => r.toEntity()).toList(growable: false),
        );
  }

  @override
  Future<int> add(MedicationDraft draft) async {
    // v0.25 R60: 用 MedicationDraft value object 替代 9 字段参数
    // 构造临时 entity (id=0 表示新记录), 用 toCompanion 走统一通道
    final entity = MedicationEntity(
      id: 0,
      name: draft.name,
      dosage: draft.dosage,
      dosageUnit: draft.dosageUnit,
      times: draft.times,
      startDate: DateTimeResolvers.at(draft.startDate),
      endDate: draft.endDate,
      isActive: draft.isActive,
      refillAt: draft.refillAt,
      refillReminderDays: draft.refillReminderDays,
    );
    return _db.medicationDao.insert(entity.toCompanion());
  }

  @override
  Future<bool> update(MedicationEntity medication) {
    return _db.medicationDao.update(medication.toDriftRow());
  }

  @override
  Future<bool> setActive({
    required int medicationId,
    required bool isActive,
  }) async {
    return _db.transaction(() async {
      final row = await (_db.select(_db.medications)
            ..where((t) => t.id.equals(medicationId)))
          .getSingleOrNull();
      if (row == null) return false;
      final updated = row.toEntity().copyWith(
            isActive: isActive,
            endDate: DomainValue<DateTime?>(isActive ? null : DateTime.now()),
          );
      return _db.medicationDao.update(updated.toDriftRow());
    });
  }

  @override
  Future<int> delete(int id) => _db.medicationDao.delete(id);

  @override
  Future<bool> updateRefill({
    required int medicationId,
    required DateTime? refillAt,
    int? reminderDays,
  }) async {
    return _db.transaction(() async {
      final row = await (_db.select(_db.medications)
            ..where((t) => t.id.equals(medicationId)))
          .getSingleOrNull();
      if (row == null) return false;
      final updated = row.toEntity().copyWith(
            refillAt: DomainValue<DateTime?>(refillAt),
            refillReminderDays: reminderDays ?? row.refillReminderDays,
          );
      return _db.medicationDao.update(updated.toDriftRow());
    });
  }
}
