// v0.14 (Round 12A) MoodEntryEntity — 纯 Dart domain entity
//
// 4 层架构示范：domain 层不依赖 Drift。
// `tags` 暴露解析后的 `List<String>`（不再让 UI 调 `MoodRepository.decodeTags`）。
//
// 设计要点：
// - 不可变（所有 final 字段 + copyWith）
// - `tagsJson` 仍保留（与数据库 schema 对齐），但 UI 用 `tags` getter
// - `score` 用 int 1-5，含 `scoreEmoji` / `scoreLabel` 便捷方法（通过 MoodVisual）
library;

import 'package:chroniccare/core/shared/domain_value.dart';
import 'package:chroniccare/core/shared/json_codec.dart';

/// 情绪记录（领域实体）
///
/// 字段含义见 `lib/data/database/tables/mood_entries.dart`。
class MoodEntryEntity {
  final int id;
  final DateTime timestamp;

  /// 情绪分数 1-5（必填,1=很差 5=很好）
  final int score;

  /// 精力分数 1-5（v0.18 P1-15 新增,1=很低 5=充沛）
  /// 老数据为 null(单 score 模式)
  final int? energy;

  /// 睡眠分数 1-5（v0.18 P1-15 新增,1=很差 5=很好）
  final int? sleep;

  /// 焦虑分数 1-5（v0.18 P1-15 新增，反向:1=严重 5=平静）
  final int? anxiety;

  /// 标签 JSON 数组（数据库原值）
  ///
  /// UI / 业务代码应当使用 [tags] getter 拿解析后的 `List<String>`。
  final String tagsJson;

  /// 自由备注
  final String? note;

  const MoodEntryEntity({
    required this.id,
    required this.timestamp,
    required this.score,
    this.energy,
    this.sleep,
    this.anxiety,
    this.tagsJson = '[]',
    this.note,
  });

  // ===== 业务方法 =====

  /// 解析后的标签列表
  List<String> get tags => JsonCodec.decodeStringList(tagsJson);

  /// 分数是否在 1-5 范围内
  bool get isValidScore => score >= 1 && score <= 5;

  /// 是否 4 维度全填（v0.18 P1-15 新增）
  bool get isFull4D => energy != null && sleep != null && anxiety != null;

  MoodEntryEntity copyWith({
    int? id,
    DateTime? timestamp,
    int? score,
    int? energy,
    int? sleep,
    int? anxiety,
    String? tagsJson,
    DomainValue<String?>? note,
  }) {
    return MoodEntryEntity(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      score: score ?? this.score,
      energy: energy ?? this.energy,
      sleep: sleep ?? this.sleep,
      anxiety: anxiety ?? this.anxiety,
      tagsJson: tagsJson ?? this.tagsJson,
      note: note == null ? this.note : note.value,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MoodEntryEntity &&
        other.id == id &&
        other.timestamp == timestamp &&
        other.score == score &&
        other.energy == energy &&
        other.sleep == sleep &&
        other.anxiety == anxiety &&
        other.tagsJson == tagsJson &&
        other.note == note;
  }

  @override
  int get hashCode =>
      Object.hash(id, timestamp, score, energy, sleep, anxiety, tagsJson, note);

  @override
  String toString() => 'MoodEntryEntity('
      'id=$id, score=$score, energy=$energy, sleep=$sleep, anxiety=$anxiety, '
      'tagsJson=$tagsJson, at=$timestamp)';
}
