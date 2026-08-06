// v0.30 round 91 (sub-spec 7 日常追踪): WeightDao

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:drift/drift.dart';

class WeightDao {
  final AppDatabase _db;
  WeightDao(this._db);

  /// 监听所有体重记录 (按 timestamp DESC 倒序)
  Stream<List<WeightEntry>> watchAll() {
    return (_db.select(_db.weightEntries)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<int> insert(WeightEntriesCompanion entry) =>
      _db.into(_db.weightEntries).insert(entry);

  Future<int> delete(int id) =>
      (_db.delete(_db.weightEntries)..where((t) => t.id.equals(id))).go();
}
