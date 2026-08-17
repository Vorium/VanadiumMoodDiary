// v1.1.0+174 R126 (R110 feature-first 阶段 2 step 3) — social_rhythm impl
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/features/daily_tracking/data/mappers/social_rhythm_mapper.dart';
import 'package:chroniccare/features/daily_tracking/domain/entities/social_rhythm_entry.dart';
import 'package:chroniccare/features/daily_tracking/domain/repositories/social_rhythm_repository.dart';
import 'package:drift/drift.dart' show Value;

class SocialRhythmRepositoryImpl implements SocialRhythmRepository {
  final AppDatabase _db;

  SocialRhythmRepositoryImpl(this._db);

  @override
  Stream<List<SocialRhythmEntryEntity>> watchAll() {
    return _db.socialRhythmDao.watchAll().map(
          (rows) => rows.map(socialRhythmRowToEntity).toList(growable: false),
        );
  }

  @override
  Future<int> add({
    required DateTime date,
    required DateTime wakeTime,
    required DateTime firstMealTime,
    required DateTime lastMealTime,
    int socialMin = 0,
    int workMin = 0,
    int exerciseMin = 0,
  }) {
    return _db.socialRhythmDao.insert(
      SocialRhythmEntriesCompanion.insert(
        date: date,
        wakeTime: wakeTime,
        firstMealTime: firstMealTime,
        lastMealTime: lastMealTime,
        socialMin: Value(socialMin),
        workMin: Value(workMin),
        exerciseMin: Value(exerciseMin),
      ),
    );
  }

  @override
  Future<int> delete(int id) => _db.socialRhythmDao.delete(id);
}
