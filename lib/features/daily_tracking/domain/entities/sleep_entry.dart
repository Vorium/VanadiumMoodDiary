// v1.1.0+173 R126 (R110 feature-first 阶段 2 step 2) — sleep entity
// (R125 样板模式 + R126 step 1 stress_event entity 同模式)
//
// 4 层架构: domain 0 flutter 0 drift, 跟 R110 阶段 1/2 设计一致。
// 字段含义见 `lib/features/daily_tracking/data/tables/sleep_entries.dart`。

/// 睡眠记录 (领域实体, R126 阶段 2 step 2 迁移)
class SleepEntryEntity {
  final int id;
  final DateTime date;
  final DateTime bedtime;
  final DateTime wakeTime;

  /// 自动算 (单位分钟, 跨午夜支持, 跟 SleepCalculator 配合)
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

  /// i18n-free duration label (跟旧版本兼容, 实际显示走 ARB key)
  String get durationLabel {
    final h = durationMin ~/ 60;
    final m = durationMin % 60;
    return '${h}h${m.toString().padLeft(2, '0')}min';
  }

  /// 是否有效 regularity 评分 (1-5)
  bool get hasRegularityScore =>
      regularityScore != null && regularityScore! >= 1 && regularityScore! <= 5;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepEntryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          bedtime == other.bedtime &&
          wakeTime == other.wakeTime &&
          durationMin == other.durationMin &&
          regularityScore == other.regularityScore &&
          note == other.note;

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
}
