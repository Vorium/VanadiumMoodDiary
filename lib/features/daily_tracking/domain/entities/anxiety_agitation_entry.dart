// v1.1.0+171 R125 (R110 feature-first 阶段 1) — AnxietyAgitationEntryEntity
// (样板: 从 lib/domain/entities/anxiety_agitation_entry.dart 迁)
//
// 4 层架构: domain 0 flutter 0 drift, 跟 R110 阶段 1 设计一致。

/// 焦虑急躁水平快速评估 (领域实体, R125 阶段 1 样板迁移)
class AnxietyAgitationEntryEntity {
  final int id;
  final DateTime timestamp;

  /// 焦虑分数 1-5 (1=严重 5=平静, 反向计分)
  final int anxietyScore;

  /// 急躁分数 1-5 (1=平静 5=极度急躁)
  final int agitationScore;
  final String? note;

  const AnxietyAgitationEntryEntity({
    required this.id,
    required this.timestamp,
    required this.anxietyScore,
    required this.agitationScore,
    this.note,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnxietyAgitationEntryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          timestamp == other.timestamp &&
          anxietyScore == other.anxietyScore &&
          agitationScore == other.agitationScore &&
          note == other.note;

  @override
  int get hashCode => Object.hash(
        id,
        timestamp,
        anxietyScore,
        agitationScore,
        note,
      );
}
