// v1.1.0+174 R126 (R110 feature-first 阶段 2 step 3) — treatment mapper
import 'package:chroniccare/features/daily_tracking/domain/entities/treatment_entry.dart';

TreatmentEntryEntity treatmentRowToEntity(dynamic row) {
  return TreatmentEntryEntity(
    id: row.id as int,
    timestamp: row.timestamp as DateTime,
    treatmentType: row.treatmentType as String,
    description: row.description as String,
    linkedMedicationId: row.linkedMedicationId as int?,
    linkedMedicationName: row.linkedMedicationName as String?,
    note: row.note as String?,
  );
}
