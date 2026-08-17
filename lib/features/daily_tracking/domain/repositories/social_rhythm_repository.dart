// v1.1.0+174 R126 (R110 feature-first 阶段 2 step 3) — social_rhythm abstract
import 'package:chroniccare/features/daily_tracking/domain/entities/social_rhythm_entry.dart';

abstract class SocialRhythmRepository {
  Stream<List<SocialRhythmEntryEntity>> watchAll();

  Future<int> add({
    required DateTime date,
    required DateTime wakeTime,
    required DateTime firstMealTime,
    required DateTime lastMealTime,
    int socialMin = 0,
    int workMin = 0,
    int exerciseMin = 0,
  });

  Future<int> delete(int id);
}
