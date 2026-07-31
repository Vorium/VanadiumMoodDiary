// v0.25 round 53a: VentDao 抽离 (树洞, 隐私边界严格执行:
// vent_entries 不进 trend / care engine / 通知 / 关怀)

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:drift/drift.dart';

class VentDao {
  final AppDatabase _db;
  VentDao(this._db);

  /// 监听所有树洞条目 (按时间倒序)
  Stream<List<VentEntry>> watchAll() {
    return (_db.select(_db.ventEntries)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.timestamp,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Future<int> insert(VentEntriesCompanion entry) =>
      _db.into(_db.ventEntries).insert(entry);

  Future<int> delete(int id) =>
      (_db.delete(_db.ventEntries)..where((t) => t.id.equals(id))).go();
}
