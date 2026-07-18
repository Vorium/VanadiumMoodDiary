// v0.14 (Round 12A) MoodRepositoryImpl — data 层 Drift 实现
library;

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/repositories/mood_repository.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/mood/mood_entry_mapper.dart';
import 'package:chroniccare/core/shared/json_codec.dart';

/// Mood 仓库的 Drift 实现
class MoodRepositoryImpl implements MoodRepository {
  final AppDatabase _db;

  MoodRepositoryImpl(this._db);

  @override
  Stream<List<MoodEntryEntity>> watchAll() {
    return _db
        .watchMoodEntries()
        .map((rows) => rows.map((r) => r.toEntity()).toList(growable: false));
  }

  @override
  Stream<List<MoodEntryEntity>> watchToday() {
    return _db
        .watchTodayMoodEntries()
        .map((rows) => rows.map((r) => r.toEntity()).toList(growable: false));
  }

  @override
  Future<int> add({
    required int score,
    required List<String> tags,
    String? note,
    DateTime? at,
    int? energy,
    int? sleep,
    int? anxiety,
  }) {
    return _db.insertMoodEntry(
      MoodEntriesCompanion.insert(
        timestamp: at ?? DateTime.now(),
        score: score,
        energy: Value(energy),
        sleep: Value(sleep),
        anxiety: Value(anxiety),
        tagsJson: Value(JsonCodec.encodeStringList(tags)),
        note: Value(note),
      ),
    );
  }

  @override
  Future<int> delete(int id) => _db.deleteMoodEntry(id);
}
