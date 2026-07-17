// v0.14 (Round 12A) MoodRepositoryImpl — data 层 Drift 实现
library;

import 'package:drift/drift.dart' show Value;

import '../../domain/entities/mood_entry_entity.dart';
import '../../domain/repositories/mood_repository.dart';
import '../database/app_database.dart';
import '../database/mood_entry_mapper.dart';
import '../../shared/json_codec.dart';

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
  }) {
    return _db.insertMoodEntry(
      MoodEntriesCompanion.insert(
        timestamp: at ?? DateTime.now(),
        score: score,
        tagsJson: Value(JsonCodec.encodeStringList(tags)),
        note: Value(note),
      ),
    );
  }

  @override
  Future<int> delete(int id) => _db.deleteMoodEntry(id);
}
