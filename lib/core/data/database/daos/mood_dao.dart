// v0.25 round 53a: MoodDao 抽离

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:drift/drift.dart';

class MoodDao {
  final AppDatabase _db;
  MoodDao(this._db);

  Stream<List<MoodEntry>> watchAll() {
    return (_db.select(_db.moodEntries)
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<MoodEntry>> getAll() => _db.select(_db.moodEntries).get();

  /// 监听今天的 mood entries (跨 midnight 单次 DateTime.now())
  Stream<List<MoodEntry>> watchToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (_db.select(_db.moodEntries)
          ..where((t) =>
              t.timestamp.isBiggerOrEqualValue(startOfDay) &
              t.timestamp.isSmallerThanValue(endOfDay))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<int> insert(MoodEntriesCompanion entry) =>
      _db.into(_db.moodEntries).insert(entry);

  Future<int> delete(int id) =>
      (_db.delete(_db.moodEntries)..where((t) => t.id.equals(id))).go();
}
