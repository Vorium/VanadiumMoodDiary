// v1.1.0+174 R126 (R110 feature-first 阶段 2 step 3) — social_rhythm mapper
import 'package:chroniccare/features/daily_tracking/domain/entities/social_rhythm_entry.dart';

SocialRhythmEntryEntity socialRhythmRowToEntity(dynamic row) {
  return SocialRhythmEntryEntity(
    id: row.id as int,
    date: row.date as DateTime,
    wakeTime: row.wakeTime as DateTime,
    firstMealTime: row.firstMealTime as DateTime,
    lastMealTime: row.lastMealTime as DateTime,
    socialMin: row.socialMin as int,
    workMin: row.workMin as int,
    exerciseMin: row.exerciseMin as int,
  );
}
