// v0.30 round 91 (sub-spec 7 日常追踪): TreatmentRepositoryImpl
//
// linkedMedicationName 是写时 snapshot 缓存, 避免 medication rename 后
// 历史 treatment 显示错名 (R55 R60 模式)。

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/domain/entities/treatment_entry.dart';
import 'package:drift/drift.dart' show Value;

/// Treatment 仓库的 Drift 实现
class TreatmentRepositoryImpl {
  final AppDatabase _db;

  TreatmentRepositoryImpl(this._db);

  Stream<List<TreatmentEntryEntity>> watchAll() {
    return _db.treatmentDao.watchAll().map(
          (rows) => rows
              .map(
                (r) => TreatmentEntryEntity(
                  id: r.id,
                  timestamp: r.timestamp,
                  treatmentType: r.treatmentType,
                  description: r.description,
                  linkedMedicationId: r.linkedMedicationId,
                  linkedMedicationName: r.linkedMedicationName,
                  note: r.note,
                ),
              )
              .toList(growable: false),
        );
  }

  Future<int> add({
    required DateTime timestamp,
    required String treatmentType,
    required String description,
    int? linkedMedicationId,
    String? linkedMedicationName,
    String? note,
  }) {
    return _db.treatmentDao.insert(
      TreatmentEntriesCompanion.insert(
        timestamp: timestamp,
        treatmentType: treatmentType,
        description: description,
        linkedMedicationId: Value(linkedMedicationId),
        linkedMedicationName: Value(linkedMedicationName),
        note: Value(note),
      ),
    );
  }

  Future<int> delete(int id) => _db.treatmentDao.delete(id);
}
