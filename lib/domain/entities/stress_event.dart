// v0.30 round 91 (sub-spec 7 日常追踪): StressEventEntity
//
// 4 层架构: domain 0 flutter 0 drift。
// eventType 是 TextColumn 自由 (R60 模式), 用 String 不用 enum。

import 'package:chroniccare/core/shared/domain_value.dart';

/// 生活事件/应激源（领域实体）
class StressEventEntity {
  final int id;
  final DateTime timestamp;

  /// 'work' / 'relationship' / 'health' / 'financial' / 'other'
  final String eventType;

  /// 1-5 (1=轻微 5=极重)
  final int intensity;
  final String? note;

  /// 弱 FK mood_entries.id (nullable, 应用层维护)
  final int? linkedMoodEntryId;

  const StressEventEntity({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.intensity,
    this.note,
    this.linkedMoodEntryId,
  });

  bool get isLinkedToMood => linkedMoodEntryId != null;

  StressEventEntity copyWith({
    int? id,
    DateTime? timestamp,
    String? eventType,
    int? intensity,
    DomainValue<String?>? note,
    DomainValue<int?>? linkedMoodEntryId,
  }) {
    return StressEventEntity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      eventType: eventType ?? this.eventType,
      intensity: intensity ?? this.intensity,
      note: note == null ? this.note : note.value,
      linkedMoodEntryId: linkedMoodEntryId == null
          ? this.linkedMoodEntryId
          : linkedMoodEntryId.value,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StressEventEntity &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.eventType == eventType &&
        other.intensity == intensity &&
        other.note == note &&
        other.linkedMoodEntryId == linkedMoodEntryId;
  }

  @override
  int get hashCode =>
      Object.hash(id, timestamp, eventType, intensity, note, linkedMoodEntryId);

  @override
  String toString() => 'StressEventEntity('
      'id=$id, type=$eventType, intensity=$intensity, linkedMood=$linkedMoodEntryId)';
}
