// v1.1.0+174 R126 (R110 feature-first 阶段 2 step 3) — treatment impl
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/features/daily_tracking/data/mappers/treatment_mapper.dart';
import 'package:chroniccare/features/daily_tracking/domain/entities/treatment_entry.dart';
import 'package:chroniccare/features/daily_tracking/domain/repositories/treatment_repository.dart';
import 'package:drift/drift.dart' show Value;

class TreatmentRepositoryImpl implements TreatmentRepository {
  final AppDatabase _db;

  TreatmentRepositoryImpl(this._db);

  @override
  Stream<List<TreatmentEntryEntity>> watchAll() {
    return _db.treatmentDao.watchAll().map(
          (rows) => rows.map(treatmentRowToEntity).toList(growable: false),
        );
  }

  @override
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

  @override
  Future<int> delete(int id) => _db.treatmentDao.delete(id);
}
