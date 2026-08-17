// v1.1.0+174 R126 (R110 feature-first 阶段 2 step 3) — weight mapper
import 'package:chroniccare/features/daily_tracking/domain/entities/weight_entry.dart';

WeightEntryEntity weightRowToEntity(dynamic row) {
  return WeightEntryEntity(
    id: row.id as int,
    timestamp: row.timestamp as DateTime,
    weightKg: row.weightKg as double,
    bmi: row.bmi as double?,
    note: row.note as String?,
  );
}
