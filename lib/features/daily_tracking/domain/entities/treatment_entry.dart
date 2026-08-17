// v1.1.0+174 R126 (R110 feature-first 阶段 2 step 3) — treatment entity
// (业务方法 isLinkedToMedication / linkedMedicationDisplay 跟旧版一致)

class TreatmentEntryEntity {
  final int id;
  final DateTime timestamp;

  /// 'medication' / 'consultation' / 'physiotherapy' / 'other'
  final String treatmentType;
  final String description;

  final int? linkedMedicationId;
  final String? linkedMedicationName;
  final String? note;

  const TreatmentEntryEntity({
    required this.id,
    required this.timestamp,
    required this.treatmentType,
    required this.description,
    this.linkedMedicationId,
    this.linkedMedicationName,
    this.note,
  });

  /// 是否关联到 medication
  bool get isLinkedToMedication => linkedMedicationId != null;

  /// 显示关联 medication 名 (优先 cache, fallback "无关联")
  String get linkedMedicationDisplay => linkedMedicationName ?? '无关联';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreatmentEntryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          timestamp == other.timestamp &&
          treatmentType == other.treatmentType &&
          description == other.description &&
          linkedMedicationId == other.linkedMedicationId &&
          linkedMedicationName == other.linkedMedicationName &&
          note == other.note;

  @override
  int get hashCode => Object.hash(
        id,
        timestamp,
        treatmentType,
        description,
        linkedMedicationId,
        linkedMedicationName,
        note,
      );
}
