// v0.25 round 53a: MedicationDao 抽离

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:drift/drift.dart';

class MedicationDao {
  final AppDatabase _db;
  MedicationDao(this._db);

  /// 监听所有 active 药物 (按 startDate 倒序)
  Stream<List<Medication>> watchActive() {
    return (_db.select(_db.medications)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.startDate, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// 监听所有药物 (含 inactive, 报告/历史用)
  Stream<List<Medication>> watchAllIncludingInactive() {
    return (_db.select(_db.medications)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.startDate, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<int> insert(MedicationsCompanion entry) =>
      _db.into(_db.medications).insert(entry);

  Future<bool> update(Medication medication) =>
      _db.update(_db.medications).replace(medication);

  Future<int> delete(int id) =>
      (_db.delete(_db.medications)..where((t) => t.id.equals(id))).go();
}
