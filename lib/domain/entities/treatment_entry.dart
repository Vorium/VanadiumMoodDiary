// 规则 3 标记: linkedMedicationDisplay 中文 fallback — v1.0+ i18n (显示层走 ARB)
// v0.30 round 91 (sub-spec 7 日常追踪): TreatmentEntryEntity
//
// 4 层架构: domain 0 flutter 0 drift。
// treatmentType 是 TextColumn 自由 (R60 模式), 用 String 不用 enum。

import 'package:chroniccare/core/shared/domain_value.dart';

/// 治疗记录（领域实体）
class TreatmentEntryEntity {
  final int id;
  final DateTime timestamp;

  /// 'medication' / 'consultation' / 'physiotherapy' / 'other'
  final String treatmentType;
  final String description;

  /// 关联 medication id (nullable, R60 不强制外键)
  final int? linkedMedicationId;

  /// 关联 medication name 缓存 (写时 snapshot, 避免 medication rename 影响历史)
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

  TreatmentEntryEntity copyWith({
    int? id,
    DateTime? timestamp,
    String? treatmentType,
    String? description,
    DomainValue<int?>? linkedMedicationId,
    DomainValue<String?>? linkedMedicationName,
    DomainValue<String?>? note,
  }) {
    return TreatmentEntryEntity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      treatmentType: treatmentType ?? this.treatmentType,
      description: description ?? this.description,
      linkedMedicationId: linkedMedicationId == null
          ? this.linkedMedicationId
          : linkedMedicationId.value,
      linkedMedicationName: linkedMedicationName == null
          ? this.linkedMedicationName
          : linkedMedicationName.value,
      note: note == null ? this.note : note.value,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TreatmentEntryEntity &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.treatmentType == treatmentType &&
        other.description == description &&
        other.linkedMedicationId == linkedMedicationId &&
        other.linkedMedicationName == linkedMedicationName &&
        other.note == note;
  }

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

  @override
  String toString() => 'TreatmentEntryEntity('
      'id=$id, type=$treatmentType, linkedMed=$linkedMedicationId)';
}
