// v0.30 round 91 (sub-spec 7 日常追踪): AnxietyAgitationDao

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:drift/drift.dart';

class AnxietyAgitationDao {
  final AppDatabase _db;
  AnxietyAgitationDao(this._db);

  /// 监听所有焦虑急躁条目 (按 timestamp DESC 倒序)
  Stream<List<AnxietyAgitationEntry>> watchAll() {
    return (_db.select(_db.anxietyAgitationEntries)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<int> insert(AnxietyAgitationEntriesCompanion entry) =>
      _db.into(_db.anxietyAgitationEntries).insert(entry);

  Future<int> delete(int id) =>
      (_db.delete(_db.anxietyAgitationEntries)..where((t) => t.id.equals(id)))
          .go();
}
