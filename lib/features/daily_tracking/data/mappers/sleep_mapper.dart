// v1.1.0+173 R126 (R110 feature-first 阶段 2 step 2) — sleep mapper
// (R125 样板模式 + R126 step 1 stress_event mapper 同模式)

import 'package:chroniccare/features/daily_tracking/domain/entities/sleep_entry.dart';

/// sleep row → entity 翻译 (R126 阶段 2 step 2 新增)
SleepEntryEntity sleepRowToEntity(dynamic row) {
  return SleepEntryEntity(
    id: row.id as int,
    date: row.date as DateTime,
    bedtime: row.bedtime as DateTime,
    wakeTime: row.wakeTime as DateTime,
    durationMin: row.durationMin as int,
    regularityScore: row.regularityScore as int?,
    note: row.note as String?,
  );
}
