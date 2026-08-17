// v1.1.0+172 R126 (R110 feature-first 阶段 2) — stress_event entity
// (R125 阶段 1 样板, R126 阶段 2 step 1 扩第 2 子表)
//
// 4 层架构: domain 0 flutter 0 drift, 跟 R110 阶段 1/2 设计一致。
// eventType 是 TextColumn 自由 (R60 模式), 用 String 不用 enum。

/// 生活事件/应激源 (领域实体, R126 阶段 2 step 1 迁移)
class StressEventEntity {
  final int id;
  final DateTime timestamp;
  final String eventType;

  /// 1-5 (1=轻微 5=极重)
  final int intensity;
  final String? note;
  final int? linkedMoodEntryId;

  const StressEventEntity({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.intensity,
    this.note,
    this.linkedMoodEntryId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StressEventEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          timestamp == other.timestamp &&
          eventType == other.eventType &&
          intensity == other.intensity &&
          note == other.note &&
          linkedMoodEntryId == other.linkedMoodEntryId;

  @override
  int get hashCode => Object.hash(
        id,
        timestamp,
        eventType,
        intensity,
        note,
        linkedMoodEntryId,
      );
}
