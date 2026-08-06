// v0.30 round 91 (sub-spec 7 日常追踪): SocialRhythmDao

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:drift/drift.dart';

class SocialRhythmDao {
  final AppDatabase _db;
  SocialRhythmDao(this._db);

  /// 监听所有社会节律条目 (按 date DESC 倒序)
  Stream<List<SocialRhythmEntry>> watchAll() {
    return (_db.select(_db.socialRhythmEntries)
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<int> insert(SocialRhythmEntriesCompanion entry) =>
      _db.into(_db.socialRhythmEntries).insert(entry);

  Future<int> delete(int id) =>
      (_db.delete(_db.socialRhythmEntries)..where((t) => t.id.equals(id))).go();
}
