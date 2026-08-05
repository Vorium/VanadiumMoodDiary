// v0.30 round 91 (sub-spec 7 日常追踪): TreatmentDao

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:drift/drift.dart';

class TreatmentDao {
  final AppDatabase _db;
  TreatmentDao(this._db);

  /// 监听所有治疗记录 (按 timestamp DESC 倒序)
  Stream<List<TreatmentEntry>> watchAll() {
    return (_db.select(_db.treatmentEntries)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<int> insert(TreatmentEntriesCompanion entry) =>
      _db.into(_db.treatmentEntries).insert(entry);

  Future<int> delete(int id) =>
      (_db.delete(_db.treatmentEntries)..where((t) => t.id.equals(id))).go();
}
