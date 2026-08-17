// v1.1.0+174 R126 (R110 feature-first 阶段 2 step 3) — social_rhythm entity
class SocialRhythmEntryEntity {
  final int id;
  final DateTime date;
  final DateTime wakeTime;
  final DateTime firstMealTime;
  final DateTime lastMealTime;
  final int socialMin;
  final int workMin;
  final int exerciseMin;

  const SocialRhythmEntryEntity({
    required this.id,
    required this.date,
    required this.wakeTime,
    required this.firstMealTime,
    required this.lastMealTime,
    this.socialMin = 0,
    this.workMin = 0,
    this.exerciseMin = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SocialRhythmEntryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          wakeTime == other.wakeTime &&
          firstMealTime == other.firstMealTime &&
          lastMealTime == other.lastMealTime &&
          socialMin == other.socialMin &&
          workMin == other.workMin &&
          exerciseMin == other.exerciseMin;

  @override
  int get hashCode => Object.hash(
        id,
        date,
        wakeTime,
        firstMealTime,
        lastMealTime,
        socialMin,
        workMin,
        exerciseMin,
      );
}
