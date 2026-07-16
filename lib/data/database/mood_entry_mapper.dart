// v0.14 (Round 12A) MoodEntry 映射层
//
// Drift row ↔ MoodEntryEntity 翻译官。
library;

import 'package:drift/drift.dart' show Value;

import '../../domain/entities/mood_entry_entity.dart';
import '../../shared/json_codec.dart';
import 'app_database.dart';

extension MoodEntryToEntity on MoodEntry {
  /// Drift row → domain entity
  MoodEntryEntity toEntity() {
    return MoodEntryEntity(
      id: id,
      timestamp: timestamp,
      score: score,
      tagsJson: tagsJson,
      note: note,
    );
  }
}

extension MoodEntryEntityToDrift on MoodEntryEntity {
  /// domain entity → Drift `MoodEntriesCompanion.insert`
  MoodEntriesCompanion toCompanion() {
    return MoodEntriesCompanion.insert(
      timestamp: timestamp,
      score: score,
      tagsJson: Value(tagsJson),
      note: Value(note),
    );
  }
}

/// 从原始 (score, tags, note) 构造 entity（无需先有 Drift row）
MoodEntryEntity buildMoodEntryEntity({
  required int id,
  required DateTime timestamp,
  required int score,
  required List<String> tags,
  String? note,
}) {
  return MoodEntryEntity(
    id: id,
    timestamp: timestamp,
    score: score,
    tagsJson: JsonCodec.encodeStringList(tags),
    note: note,
  );
}
