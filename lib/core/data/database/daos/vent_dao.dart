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

  /// v0.28 R82.5 (法务 Q7b 必改): 物理删所有 vent 条目
  ///
  /// PIPL §47 删除权: 撤回 vent 同意时, 用户选"立即删除"走此路径。
  /// 删 vent_entries 表所有行 (drift `delete` 默认返受影响行数, 我们不
  /// 在 dao 层事务包, repository 层会包事务 + 删 audio 文件)。
  ///
  /// 返回删除行数 (供 UI 提示"已删 N 条")。
  Future<int> deleteAll() => _db.delete(_db.ventEntries).go();
}
