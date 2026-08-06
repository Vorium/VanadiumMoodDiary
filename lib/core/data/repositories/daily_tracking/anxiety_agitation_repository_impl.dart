// v0.30 round 91 (sub-spec 7 日常追踪): AnxietyAgitationRepositoryImpl

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/domain/entities/anxiety_agitation_entry.dart';
import 'package:drift/drift.dart' show Value;

/// AnxietyAgitation 仓库的 Drift 实现
class AnxietyAgitationRepositoryImpl {
  final AppDatabase _db;

  AnxietyAgitationRepositoryImpl(this._db);

  Stream<List<AnxietyAgitationEntryEntity>> watchAll() {
    return _db.anxietyAgitationDao.watchAll().map(
          (rows) => rows
              .map(
                (r) => AnxietyAgitationEntryEntity(
                  id: r.id,
                  timestamp: r.timestamp,
                  anxietyScore: r.anxietyScore,
                  agitationScore: r.agitationScore,
                  note: r.note,
                ),
              )
              .toList(growable: false),
        );
  }

  Future<int> add({
    required DateTime timestamp,
    required int anxietyScore,
    required int agitationScore,
    String? note,
  }) {
    return _db.anxietyAgitationDao.insert(
      AnxietyAgitationEntriesCompanion.insert(
        timestamp: timestamp,
        anxietyScore: anxietyScore,
        agitationScore: agitationScore,
        note: Value(note),
      ),
    );
  }

  Future<int> delete(int id) => _db.anxietyAgitationDao.delete(id);
}
