// v1.1.0+174 R126 (R110 feature-first 阶段 2 step 3) — treatment abstract
import 'package:chroniccare/features/daily_tracking/domain/entities/treatment_entry.dart';

abstract class TreatmentRepository {
  Stream<List<TreatmentEntryEntity>> watchAll();

  Future<int> add({
    required DateTime timestamp,
    required String treatmentType,
    required String description,
    int? linkedMedicationId,
    String? linkedMedicationName,
    String? note,
  });

  Future<int> delete(int id);
}
