// v0.30 round 91 (sub-spec 7 日常追踪): SleepEntryEntity
//
// 4 层架构: domain 0 flutter 0 drift (跟 VentEntryEntity 一致)。
// 字段含义见 `lib/core/data/database/tables/daily_tracking/sleep_entries.dart`。

import 'package:chroniccare/core/shared/domain_value.dart';

/// 睡眠记录（领域实体）
class SleepEntryEntity {
  final int id;
  final DateTime date;
  final DateTime bedtime;
  final DateTime wakeTime;

  /// 自动算 (单位分钟, 跨午夜支持)
  final int durationMin;

  /// 1-5, nullable (1=最不规律 5=最规律, null = 未评分)
  final int? regularityScore;
  final String? note;

  const SleepEntryEntity({
    required this.id,
    required this.date,
    required this.bedtime,
    required this.wakeTime,
    required this.durationMin,
    this.regularityScore,
    this.note,
  });

  /// 时长小时分钟 (e.g. 510 min = 8h30min)
  String get durationLabel {
    final h = durationMin ~/ 60;
    final m = durationMin % 60;
    return '${h}h${m.toString().padLeft(2, '0')}min';
  }

  /// 是否有效 regularity 评分 (1-5)
  bool get hasRegularityScore =>
      regularityScore != null && regularityScore! >= 1 && regularityScore! <= 5;

  SleepEntryEntity copyWith({
    int? id,
    DateTime? date,
    DateTime? bedtime,
    DateTime? wakeTime,
    int? durationMin,
    DomainValue<int?>? regularityScore,
    DomainValue<String?>? note,
  }) {
    return SleepEntryEntity(
      id: id ?? this.id,
      date: date ?? this.date,
      bedtime: bedtime ?? this.bedtime,
      wakeTime: wakeTime ?? this.wakeTime,
      durationMin: durationMin ?? this.durationMin,
      regularityScore: regularityScore == null
          ? this.regularityScore
          : regularityScore.value,
      note: note == null ? this.note : note.value,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SleepEntryEntity &&
        other.id == id &&
        other.date == date &&
        other.bedtime == bedtime &&
        other.wakeTime == wakeTime &&
        other.durationMin == durationMin &&
        other.regularityScore == regularityScore &&
        other.note == note;
  }

  @override
  int get hashCode => Object.hash(
        id,
        date,
        bedtime,
        wakeTime,
        durationMin,
        regularityScore,
        note,
      );

  @override
  String toString() =>
      'SleepEntryEntity(id=$id, date=$date, duration=$durationLabel, regularity=$regularityScore)';
}
