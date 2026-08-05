// v0.30 round 91 (sub-spec 7 日常追踪): StressEventDao

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:drift/drift.dart';

class StressEventDao {
  final AppDatabase _db;
  StressEventDao(this._db);

  /// 监听所有应激源条目 (按 timestamp DESC 倒序)
  Stream<List<StressEvent>> watchAll() {
    return (_db.select(_db.stressEvents)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<int> insert(StressEventsCompanion entry) =>
      _db.into(_db.stressEvents).insert(entry);

  Future<int> delete(int id) =>
      (_db.delete(_db.stressEvents)..where((t) => t.id.equals(id))).go();
}
