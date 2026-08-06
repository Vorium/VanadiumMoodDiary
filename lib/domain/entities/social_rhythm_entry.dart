// v0.30 round 91 (sub-spec 7 日常追踪): SocialRhythmEntryEntity
//
// 4 层架构: domain 0 flutter 0 drift。

/// 社会节律记录（领域实体）
class SocialRhythmEntryEntity {
  final int id;
  final DateTime date;
  final DateTime wakeTime;
  final DateTime firstMealTime;
  final DateTime lastMealTime;

  /// 社交时长 (分钟), 默认 0
  final int socialMin;

  /// 工作时长 (分钟), 默认 0
  final int workMin;

  /// 运动时长 (分钟), 默认 0
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

  /// 总活动时长 (social + work + exercise)
  int get totalActiveMin => socialMin + workMin + exerciseMin;

  SocialRhythmEntryEntity copyWith({
    int? id,
    DateTime? date,
    DateTime? wakeTime,
    DateTime? firstMealTime,
    DateTime? lastMealTime,
    int? socialMin,
    int? workMin,
    int? exerciseMin,
  }) {
    return SocialRhythmEntryEntity(
      id: id ?? this.id,
      date: date ?? this.date,
      wakeTime: wakeTime ?? this.wakeTime,
      firstMealTime: firstMealTime ?? this.firstMealTime,
      lastMealTime: lastMealTime ?? this.lastMealTime,
      socialMin: socialMin ?? this.socialMin,
      workMin: workMin ?? this.workMin,
      exerciseMin: exerciseMin ?? this.exerciseMin,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SocialRhythmEntryEntity &&
        other.id == id &&
        other.date == date &&
        other.wakeTime == wakeTime &&
        other.firstMealTime == firstMealTime &&
        other.lastMealTime == lastMealTime &&
        other.socialMin == socialMin &&
        other.workMin == workMin &&
        other.exerciseMin == exerciseMin;
  }

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

  @override
  String toString() => 'SocialRhythmEntryEntity('
      'id=$id, date=$date, social=${socialMin}min, work=${workMin}min, exercise=${exerciseMin}min)';
}
