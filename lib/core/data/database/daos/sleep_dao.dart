// v0.30 round 91 (sub-spec 7 日常追踪): SleepDao
//
// 跟 R53a 抽 DAO 模式一致 — 不用 @DriftAccessor (避免 build_runner 重建),
// 用 _db.select(_db.sleepEntries) 访问 table。drift 生成的 getter 在
// _$AppDatabase 里。

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:drift/drift.dart';

class SleepDao {
  final AppDatabase _db;
  SleepDao(this._db);

  /// 监听所有 sleep 条目 (按 date DESC 倒序)
  Stream<List<SleepEntry>> watchAll() {
    return (_db.select(_db.sleepEntries)
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<int> insert(SleepEntriesCompanion entry) =>
      _db.into(_db.sleepEntries).insert(entry);

  Future<int> delete(int id) =>
      (_db.delete(_db.sleepEntries)..where((t) => t.id.equals(id))).go();
}
