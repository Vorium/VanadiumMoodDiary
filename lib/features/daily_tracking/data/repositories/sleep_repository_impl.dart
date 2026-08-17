// v1.1.0+173 R126 (R110 feature-first 阶段 2 step 2) — sleep impl
// (R125 样板模式 + R126 step 1 stress_event impl 同模式)

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/features/daily_tracking/data/mappers/sleep_mapper.dart';
import 'package:chroniccare/features/daily_tracking/domain/entities/sleep_entry.dart';
import 'package:chroniccare/features/daily_tracking/domain/repositories/sleep_repository.dart';
import 'package:drift/drift.dart' show Value;

/// Sleep 仓库的 Drift 实现 (R126 阶段 2 step 2 迁移)
class SleepRepositoryImpl implements SleepRepository {
  final AppDatabase _db;

  SleepRepositoryImpl(this._db);

  @override
  Stream<List<SleepEntryEntity>> watchAll() {
    return _db.sleepDao.watchAll().map(
          (rows) => rows.map(sleepRowToEntity).toList(growable: false),
        );
  }

  @override
  Future<int> add({
    required DateTime date,
    required DateTime bedtime,
    required DateTime wakeTime,
    required int durationMin,
    int? regularityScore,
    String? note,
  }) {
    return _db.sleepDao.insert(
      SleepEntriesCompanion.insert(
        date: date,
        bedtime: bedtime,
        wakeTime: wakeTime,
        durationMin: durationMin,
        regularityScore: Value(regularityScore),
        note: Value(note),
      ),
    );
  }

  @override
  Future<int> delete(int id) => _db.sleepDao.delete(id);
}
