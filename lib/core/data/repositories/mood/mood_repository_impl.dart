// v0.14 (Round 12A) MoodRepositoryImpl — data 层 Drift 实现
//
// v0.23 (Round 31) 语音录入: add() 加 3 个 audio 参数,纯文字模式老调用方
// 不传 = 行为完全不变(audioPath null = 不会写 audio 文件)。
//
// v0.24 round 48 (sp-en P1-14) add() 10 参 → MoodEntryDraft 参数对象
// v0.29 round 84 (fix) add() 透传 8 个 CBT 字段 (P0 production bug)

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/domain/entities/mood_entry_draft.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/repositories/mood_repository.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/mood/mood_entry_mapper.dart';
import 'package:chroniccare/core/shared/date_time_resolver.dart';
import 'package:chroniccare/core/shared/json_codec.dart';

/// Mood 仓库的 Drift 实现
class MoodRepositoryImpl implements MoodRepository {
  final AppDatabase _db;

  MoodRepositoryImpl(this._db);

  @override
  Stream<List<MoodEntryEntity>> watchAll() {
    return _db.moodDao
        .watchAll()
        .map((rows) => rows.map((r) => r.toEntity()).toList(growable: false));
  }

  @override
  Stream<List<MoodEntryEntity>> watchToday() {
    return _db.moodDao
        .watchToday()
        .map((rows) => rows.map((r) => r.toEntity()).toList(growable: false));
  }

  @override
  Stream<MoodEntryEntity?> watchLatest() {
    return _db.moodDao.watchLatest().map((row) => row?.toEntity());
  }

  @override
  Future<int> add({required MoodEntryDraft draft}) {
    return _db.moodDao.insert(
      MoodEntriesCompanion.insert(
        timestamp: DateTimeResolvers.at(draft.at),
        score: draft.score,
        energy: Value(draft.energy),
        sleep: Value(draft.sleep),
        anxiety: Value(draft.anxiety),
        tagsJson: Value(JsonCodec.encodeStringList(draft.tags)),
        note: Value(draft.note),
        audioPath: Value(draft.audioPath),
        audioTranscript: Value(draft.audioTranscript),
        audioDurationMs: Value(draft.audioDurationMs),
        situation: Value(draft.situation),
        automaticThought: Value(draft.automaticThought),
        evidenceFor: Value(draft.evidenceFor),
        evidenceAgainst: Value(draft.evidenceAgainst),
        alternativeThought: Value(draft.alternativeThought),
        reratedScore: Value(draft.reratedScore),
        coreBelief: Value(draft.coreBelief),
        behaviorResponse: Value(draft.behaviorResponse),
        period: Value(draft.period),
        influenceFactorsJson: Value(draft.influenceFactorsJson ?? '[]'),
        recordingMode: Value(draft.recordingMode),
      ),
    );
  }

  @override
  Future<int> delete(int id) => _db.moodDao.delete(id);
}
