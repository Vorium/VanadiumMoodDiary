// v1.1.0+172 R126 (R110 feature-first 阶段 2) — stress_event mapper
// (R125 阶段 1 样板, R126 阶段 2 step 1 扩第 2 子表)
//
// row (drift 生成 StressEvent) ↔ entity (domain StressEventEntity) 翻译。

import 'package:chroniccare/features/daily_tracking/domain/entities/stress_event.dart';

/// stress_event row → entity 翻译 (R126 阶段 2 step 1 新增)
StressEventEntity stressEventRowToEntity(dynamic row) {
  return StressEventEntity(
    id: row.id as int,
    timestamp: row.timestamp as DateTime,
    eventType: row.eventType as String,
    intensity: row.intensity as int,
    note: row.note as String?,
    linkedMoodEntryId: row.linkedMoodEntryId as int?,
  );
}
