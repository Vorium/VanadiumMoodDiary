// v0.25 round 53a: ReportDao 抽离

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:drift/drift.dart';

class ReportDao {
  final AppDatabase _db;
  ReportDao(this._db);

  Stream<List<ReportHistory>> watchAll() {
    return (_db.select(_db.reportHistories)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.generatedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Future<int> insert(ReportHistoriesCompanion entry) =>
      _db.into(_db.reportHistories).insert(entry);

  Future<int> delete(int id) =>
      (_db.delete(_db.reportHistories)..where((t) => t.id.equals(id))).go();

  Future<int> clearAll() => _db.delete(_db.reportHistories).go();

  Future<List<ReportHistory>> getAll() => _db.select(_db.reportHistories).get();
}
