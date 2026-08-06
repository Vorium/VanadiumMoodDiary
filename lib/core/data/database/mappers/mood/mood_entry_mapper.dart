// v0.14 (Round 12A) MoodEntry 映射层
//
// Drift row ↔ MoodEntryEntity 翻译官。
//
// v0.23 (Round 31) 语音录入: 加 audioPath / audioTranscript / audioDurationMs
// 3 个字段的双向映射。
//
// v0.29 round 84 (CBT 思维记录): 加 situation / automaticThought /
// evidenceFor / evidenceAgainst / alternativeThought / reratedScore /
// coreBelief / behaviorResponse 8 个 CBT 字段的双向映射。

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/core/shared/json_codec.dart';
import 'package:chroniccare/core/data/database/app_database.dart';

extension MoodEntryToEntity on MoodEntry {
  /// Drift row → domain entity
  MoodEntryEntity toEntity() {
    return MoodEntryEntity(
      id: id,
      timestamp: timestamp,
      score: score,
      energy: energy,
      sleep: sleep,
      anxiety: anxiety,
      tagsJson: tagsJson,
      note: note,
      audioPath: audioPath,
      audioTranscript: audioTranscript,
      audioDurationMs: audioDurationMs,
      situation: situation,
      automaticThought: automaticThought,
      evidenceFor: evidenceFor,
      evidenceAgainst: evidenceAgainst,
      alternativeThought: alternativeThought,
      reratedScore: reratedScore,
      coreBelief: coreBelief,
      behaviorResponse: behaviorResponse,
      period: period,
    );
  }
}

extension MoodEntryEntityToDrift on MoodEntryEntity {
  /// domain entity → Drift `MoodEntriesCompanion.insert`
  MoodEntriesCompanion toCompanion() {
    return MoodEntriesCompanion.insert(
      timestamp: timestamp,
      score: score,
      energy: Value(energy),
      sleep: Value(sleep),
      anxiety: Value(anxiety),
      tagsJson: Value(tagsJson),
      note: Value(note),
      audioPath: Value(audioPath),
      audioTranscript: Value(audioTranscript),
      audioDurationMs: Value(audioDurationMs),
      situation: Value(situation),
      automaticThought: Value(automaticThought),
      evidenceFor: Value(evidenceFor),
      evidenceAgainst: Value(evidenceAgainst),
      alternativeThought: Value(alternativeThought),
      reratedScore: Value(reratedScore),
      coreBelief: Value(coreBelief),
      behaviorResponse: Value(behaviorResponse),
      period: Value(period),
    );
  }
}

/// 从原始 (score, tags, note) 构造 entity（无需先有 Drift row）
///
/// v0.18 (P1-15) 4 维: energy / sleep / anxiety 3 个 optional 参数,
/// 老调用方不传时返回单 score 模式 entity。
///
/// v0.23 (Round 31) 语音录入: audioPath / audioTranscript / audioDurationMs
/// 3 个 optional 参数,老调用方不传 = null(纯文字模式)。
///
/// v0.29 round 84 (CBT 思维记录): 8 个 CBT 字段 optional 参数,老调用方
/// 不传 = null(普通 3 栏模式)。
MoodEntryEntity buildMoodEntryEntity({
  required int id,
  required DateTime timestamp,
  required int score,
  required List<String> tags,
  String? note,
  int? energy,
  int? sleep,
  int? anxiety,
  String? audioPath,
  String? audioTranscript,
  int? audioDurationMs,
  String? situation,
  String? automaticThought,
  String? evidenceFor,
  String? evidenceAgainst,
  String? alternativeThought,
  int? reratedScore,
  String? coreBelief,
  String? behaviorResponse,
}) {
  return MoodEntryEntity(
    id: id,
    timestamp: timestamp,
    score: score,
    energy: energy,
    sleep: sleep,
    anxiety: anxiety,
    tagsJson: JsonCodec.encodeStringList(tags),
    note: note,
    audioPath: audioPath,
    audioTranscript: audioTranscript,
    audioDurationMs: audioDurationMs,
    situation: situation,
    automaticThought: automaticThought,
    evidenceFor: evidenceFor,
    evidenceAgainst: evidenceAgainst,
    alternativeThought: alternativeThought,
    reratedScore: reratedScore,
    coreBelief: coreBelief,
    behaviorResponse: behaviorResponse,
  );
}
