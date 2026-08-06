// v0.30 round 91 (sub-spec 7 日常追踪): AnxietyAgitationEntryEntity
//
// 4 层架构: domain 0 flutter 0 drift。

import 'package:chroniccare/core/shared/domain_value.dart';

/// 焦虑急躁水平快速评估（领域实体）
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

  /// 总分 (anxiety + agitation, 范围 2-10)
  int get totalScore => anxietyScore + agitationScore;

  /// 是否高焦虑 (anxietyScore <= 2, 1=严重 2=较重)
  bool get isHighAnxiety => anxietyScore <= 2;

  /// 是否高急躁 (agitationScore >= 4)
  bool get isHighAgitation => agitationScore >= 4;

  AnxietyAgitationEntryEntity copyWith({
    int? id,
    DateTime? timestamp,
    int? anxietyScore,
    int? agitationScore,
    DomainValue<String?>? note,
  }) {
    return AnxietyAgitationEntryEntity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      anxietyScore: anxietyScore ?? this.anxietyScore,
      agitationScore: agitationScore ?? this.agitationScore,
      note: note == null ? this.note : note.value,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnxietyAgitationEntryEntity &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.anxietyScore == anxietyScore &&
        other.agitationScore == agitationScore &&
        other.note == note;
  }

  @override
  int get hashCode =>
      Object.hash(id, timestamp, anxietyScore, agitationScore, note);

  @override
  String toString() => 'AnxietyAgitationEntryEntity('
      'id=$id, anxiety=$anxietyScore, agitation=$agitationScore)';
}
