// v0.30 round 91 (sub-spec 7 日常追踪): SocialRhythmRepositoryImpl

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/domain/entities/social_rhythm_entry.dart';
import 'package:chroniccare/domain/repositories/social_rhythm_repository.dart';
import 'package:drift/drift.dart' show Value;

/// SocialRhythm 仓库的 Drift 实现
///
/// R97-P1-1 (2026-08-07): implements [SocialRhythmRepository] domain 接口
/// (跟 sleep_repository_impl.dart 同模式, 详见该文件注释)。
class SocialRhythmRepositoryImpl implements SocialRhythmRepository {
  final AppDatabase _db;

  SocialRhythmRepositoryImpl(this._db);

  @override
  Stream<List<SocialRhythmEntryEntity>> watchAll() {
    return _db.socialRhythmDao.watchAll().map(
          (rows) => rows
              .map(
                (r) => SocialRhythmEntryEntity(
                  id: r.id,
                  date: r.date,
                  wakeTime: r.wakeTime,
                  firstMealTime: r.firstMealTime,
                  lastMealTime: r.lastMealTime,
                  socialMin: r.socialMin,
                  workMin: r.workMin,
                  exerciseMin: r.exerciseMin,
                ),
              )
              .toList(growable: false),
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
